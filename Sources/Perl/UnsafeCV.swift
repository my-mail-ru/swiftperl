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
}

struct UnsafeCvContext {
	let cv: UnsafeCvPointer
	let perl: PerlInterpreter

	static func new(name: String? = nil, file: StaticString = #file, body: @escaping CvBody, perl: PerlInterpreter) -> UnsafeCvContext {
		func newXS(_ name: UnsafePointer<CChar>?) -> UnsafeCvPointer {
			return perl.pointee.newXS_flags(name, cvResolver, file.description, nil, UInt32(XS_DYNAMIC_FILENAME))!
		}
		let cv = name?.withCString(newXS) ?? newXS(nil)
		cv.withMemoryRebound(to: UnsafeSV.self, capacity: 1) {
			_ = perl.pointee.sv_magicext($0, nil, PERL_MAGIC_ext, &UnsafeCV.mgvtbl, nil, 0)
		}
		let bodyPointer = UnsafeCvBodyPointer.allocate(capacity: 1)
		bodyPointer.initialize(to: body)
		cv.pointee.bodyPointer = bodyPointer
		return UnsafeCvContext(cv: cv, perl: perl)
	}

	var name: String {
		return String(cString: GvNAME(perl.pointee.CvGV(cv)))
	}

	var fullname: String {
		return "\(String(cString: HvNAME(GvSTASH(perl.pointee.CvGV(cv)))))::\(name)"
	}

	var file: String {
		return String(cString: CvFILE(cv))
	}
}

extension UnsafeCvContext {
	init(dereference svc: UnsafeSvContext) throws {
		guard let rvc = svc.referent, rvc.type == .code else {
			throw PerlError.unexpectedSvType(fromUnsafeSvContext(inc: svc), want: .code)
		}
		self.init(rebind: rvc)
	}

	init(rebind svc: UnsafeSvContext) {
		let cv = UnsafeMutableRawPointer(svc.sv).bindMemory(to: UnsafeCV.self, capacity: 1)
		self.init(cv: cv, perl: svc.perl)
	}
}

let PERL_MAGIC_ext = Int32(UnicodeScalar("~").value) // mg_vtable.h

private func cvResolver(perl: PerlInterpreter.Pointer, cv: UnsafeCvPointer) -> Void {
	let perl = PerlInterpreter(perl)
	let errsv: UnsafeSvPointer?
	do {
		let stack = UnsafeXSubStack(perl: perl)
		try cv.pointee.body(stack)
		errsv = nil
	} catch PerlError.died(let scalar) {
		errsv = scalar.withUnsafeSvContext { UnsafeSvContext.new(copy: $0).mortal() }
	} catch let error as PerlSvConvertible {
		let usv = error._toUnsafeSvPointer(perl: perl)
		errsv = perl.pointee.sv_2mortal(usv)
	} catch {
		errsv = "\(error)".withCString { error in
			UnsafeCvContext(cv: cv, perl: perl).fullname.withCString { name in
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
