import CPerl

public typealias UnsafeCvPointer = UnsafeMutablePointer<CV>

typealias CvBody = (UnsafeXSubStack) throws -> Void
typealias UnsafeCvBodyPointer = UnsafeMutablePointer<CvBody>

extension CV {
	fileprivate var bodyPointer: UnsafeCvBodyPointer {
		mutating get { return CvXSUBANY(&self).pointee.any_ptr.assumingMemoryBound(to: CvBody.self) }
		mutating set { CvXSUBANY(&self).pointee.any_ptr = UnsafeMutableRawPointer(newValue) }
	}
}

struct UnsafeCvContext {
	let cv: UnsafeCvPointer
	let perl: PerlInterpreter

	private static var mgvtbl = MGVTBL(
		svt_get: nil,
		svt_set: nil,
		svt_len: nil,
		svt_clear: nil,
		svt_free: {
			(perl, sv, magic) in
			let bodyPointer = UnsafeMutableRawPointer(sv!).assumingMemoryBound(to: CV.self).pointee.bodyPointer
			bodyPointer.deinitialize()
			bodyPointer.deallocate(capacity: 1)
			return 0
		},
		svt_copy: nil,
		svt_dup: nil,
		svt_local: nil
	)

	static func new(name: String? = nil, file: StaticString = #file, body: @escaping CvBody, perl: PerlInterpreter) -> UnsafeCvContext {
		func newXS(_ name: UnsafePointer<CChar>?) -> UnsafeCvPointer {
			return perl.pointee.newXS_flags(name, cvResolver, file.description, nil, UInt32(XS_DYNAMIC_FILENAME))
		}
		let cv = name?.withCString(newXS) ?? newXS(nil)
		cv.withMemoryRebound(to: SV.self, capacity: 1) {
			_ = perl.pointee.sv_magicext($0, nil, PERL_MAGIC_ext, &mgvtbl, nil, 0)
		}
		let bodyPointer = UnsafeCvBodyPointer.allocate(capacity: 1)
		bodyPointer.initialize(to: body)
		cv.pointee.bodyPointer = bodyPointer
		return UnsafeCvContext(cv: cv, perl: perl)
	}

	var name: String? {
		guard let gv = perl.pointee.CvGV(cv) else { return nil }
		return String(cString: GvNAME(gv))
	}

	var fullname: String? {
		guard let name = name else { return nil }
		guard let gv = perl.pointee.CvGV(cv), let stash = GvSTASH(gv), let hvn = HvNAME(stash) else { return name }
		return "\(String(cString: hvn))::\(name)"
	}

	var file: String? {
		return CvFILE(cv).map { String(cString: $0) }
	}
}

extension UnsafeCvContext {
	init(dereference svc: UnsafeSvContext) throws {
		guard let rvc = svc.referent, rvc.type == SVt_PVCV else {
			throw PerlError.unexpectedValueType(fromUnsafeSvContext(inc: svc), want: PerlSub.self)
		}
		self.init(rebind: rvc)
	}

	init(rebind svc: UnsafeSvContext) {
		let cv = UnsafeMutableRawPointer(svc.sv).bindMemory(to: CV.self, capacity: 1)
		self.init(cv: cv, perl: svc.perl)
	}
}

let PERL_MAGIC_ext = Int32(UnicodeScalar("~").value) // mg_vtable.h

private func cvResolver(perl: PerlInterpreter.Pointer, cv: UnsafeCvPointer) -> Void {
	let perl = PerlInterpreter(perl)
	let errsv: UnsafeSvPointer?
	do {
		let stack = UnsafeXSubStack(perl: perl)
		try cv.pointee.bodyPointer.pointee(stack)
		errsv = nil
	} catch PerlError.died(let scalar) {
		errsv = scalar.withUnsafeSvContext { UnsafeSvContext.new(copy: $0).mortal() }
	} catch let error as PerlSvConvertible {
		let usv = error._toUnsafeSvPointer(perl: perl)
		errsv = perl.pointee.sv_2mortal(usv)
	} catch {
		errsv = "\(error)".withCString { error in
			let name = UnsafeCvContext(cv: cv, perl: perl).fullname ?? "__ANON__"
			return name.withCString { name in
				withVaList([name, error]) { perl.pointee.vmess("Exception in %s: %s", unsafeBitCast($0, to: UnsafeMutablePointer.self)) }
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
