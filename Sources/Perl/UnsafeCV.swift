import CPerl

public typealias UnsafeCV = CPerl.CV
public typealias UnsafeCvPointer = UnsafeMutablePointer<UnsafeCV>

typealias CvBody = (UnsafeXSubStack) throws -> Void
typealias UnsafeCvBodyPointer = UnsafeMutablePointer<CvBody>

extension UnsafeCV {
	var body: CvBody {
		mutating get { return bodyPointer.pointee }
		mutating set {
			bodyPointer.deinitialize()
			bodyPointer.initialize(to: newValue)
		}
	}

	fileprivate var bodyPointer: UnsafeCvBodyPointer {
		mutating get { return CvXSUBANY(&self).pointee.any_ptr.assumingMemoryBound(to: CvBody.self) }
		mutating set { CvXSUBANY(&self).pointee.any_ptr = UnsafeMutableRawPointer(newValue) }
	}

	fileprivate static var mgvtbl = MGVTBL(
		svt_get: nil,
		svt_set: nil,
		svt_len: nil,
		svt_clear: nil,
		svt_free: {
			(perl, sv, magic) in
			let bodyPointer = UnsafeMutableRawPointer(sv!).assumingMemoryBound(to: UnsafeCV.self).pointee.bodyPointer
			bodyPointer.deinitialize()
			bodyPointer.deallocate(capacity: 1)
			return 0
		},
		svt_copy: nil,
		svt_dup: nil,
		svt_local: nil
	)

	var name: String {
		mutating get { return String(cString: GvNAME(CvGV(&self))) }
	}

	var fullname: String {
		mutating get { return "\(String(cString: HvNAME(GvSTASH(CvGV(&self)))))::\(name)" }
	}

	var file: String {
		mutating get { return String(cString: CvFILE(&self)) }
	}
}

extension UnsafeInterpreter {
	mutating func newCV(name: String? = nil, file: StaticString = #file, body: @escaping CvBody) -> UnsafeCvPointer {
		func newXS(_ name: UnsafePointer<CChar>?) -> UnsafeCvPointer {
			return newXS_flags(name, cvResolver, file.description, nil, UInt32(XS_DYNAMIC_FILENAME))!
		}
		let cv = name?.withCString(newXS) ?? newXS(nil)
		cv.withMemoryRebound(to: UnsafeSV.self, capacity: 1) {
			_ = sv_magicext($0, nil, PERL_MAGIC_ext, &UnsafeCV.mgvtbl, nil, 0)
		}
		let bodyPointer = UnsafeCvBodyPointer.allocate(capacity: 1)
		bodyPointer.initialize(to: body)
		cv.pointee.bodyPointer = bodyPointer
		return cv
	}
}

let PERL_MAGIC_ext = Int32(UnicodeScalar("~").value) // mg_vtable.h

private func cvResolver(perl: UnsafeInterpreterPointer, cv: UnsafeCvPointer) -> Void {
	let errsv: UnsafeSvPointer?
	do {
		let stack = UnsafeXSubStack(perl: perl)
		try cv.pointee.body(stack)
		errsv = nil
	} catch PerlError.died(let sv) {
		let usv = sv.withUnsafeSvPointer { sv, perl in perl.pointee.newSV(sv)! }
		errsv = perl.pointee.sv_2mortal(usv)
	} catch let error as PerlSvConvertible {
		let usv = error._toUnsafeSvPointer(perl: perl)
		errsv = perl.pointee.sv_2mortal(usv)
	} catch {
		errsv = "\(error)".withCString { error in
			cv.pointee.fullname.withCString { name in
				withVaList([name, error]) { perl.pointee.vmess("Exception in %s: %s", $0) }
			}
		}
	}
	if let e = errsv {
		perl.pointee.croak_sv(e)
		// croak_sv() function never returns. It unwinds stack instead.
		// No memory managment SIL operations should exist after it.
		// Check it using --emit-sil if modification of this function required.
	}
}
