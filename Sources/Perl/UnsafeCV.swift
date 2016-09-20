import CPerl

typealias UnsafeCV = CPerl.CV
typealias UnsafeCvPointer = UnsafeMutablePointer<UnsafeCV>

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

extension UnsafeInterpreter {
	mutating func newCV(name: String? = nil, file: StaticString = #file, body: @escaping CvBody) -> UnsafeCvPointer {
		let newXS = { (name) in
			file.description.withCString { Perl_newXS_flags(&self, name, cvResolver, $0, nil, UInt32(XS_DYNAMIC_FILENAME))! }
		}
		let cv: UnsafeCvPointer = name != nil ? name!.withCString(newXS) : newXS(nil)
		cv.withMemoryRebound(to: UnsafeSV.self, capacity: 1) {
			_ = Perl_sv_magicext(&self, $0, nil, PERL_MAGIC_ext, &UnsafeCV.mgvtbl, nil, 0)
		}
		let bodyPointer = UnsafeCvBodyPointer.allocate(capacity: 1)
		bodyPointer.initialize(to: body)
		cv.pointee.bodyPointer = bodyPointer
		return cv
	}
}

let PERL_MAGIC_ext = Int32(UnicodeScalar("~").value) // mg_vtable.h

private func cvResolver(perl: UnsafeInterpreterPointer?, cv: UnsafeCvPointer?) -> Void {
	do {
		let stack = UnsafeXSubStack(perl: perl!)
		try cv!.pointee.body(stack)
	} catch PerlError.died(let sv) {
		Perl_croak_sv(perl, sv.pointer) // FIXME no one leak
	} catch {
		Perl_croak_sv(perl, perl!.pointee.newSV("Exception: \(error)")) // FIXME no one leak
	}
}
