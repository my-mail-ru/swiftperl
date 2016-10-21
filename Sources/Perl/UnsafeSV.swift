import CPerl

public enum SvType {
	case scalar, array, hash, code, format, io

	init(_ t: svtype) {
		switch t {
			case SVt_PVAV:
				self = .array
			case SVt_PVHV:
				self = .hash
			case SVt_PVCV:
				self = .code
			case SVt_PVFM:
				self = .format
			case SVt_PVIO:
				self = .io
			default:
				self = .scalar
		}
	}
}

public typealias UnsafeSV = CPerl.SV
public typealias UnsafeSvPointer = UnsafeMutablePointer<UnsafeSV>

extension UnsafeSV {
	@discardableResult
	mutating func refcntInc() -> UnsafeSvPointer {
		return SvREFCNT_inc(&self)
	}

	mutating func refcntDec(perl: UnsafeInterpreterPointer) {
		SvREFCNT_dec(perl, &self)
	}

	var type: SvType { mutating get { return SvType(SvTYPE(&self)) } }
	var defined: Bool { mutating get { return SvOK(&self) } }
	var isInt: Bool { mutating get { return SvIOK(&self) } }
	var isString: Bool { mutating get { return SvPOK(&self) } }
	var isRef: Bool { mutating get { return SvROK(&self) } }

	var referent: UnsafeSvPointer? {
		mutating get { return SvROK(&self) ? SvRV(&self) : nil }
	}

	mutating func isObject(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Bool {
		return perl.pointee.sv_isobject(&self)
	}

	mutating func isDerived(from: String, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Bool {
		return from.withCString { perl.pointee.sv_derived_from(&self, $0) }
	}

	mutating func classname(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> String? {
		guard isObject(perl: perl) else { return nil }
		return String(cString: perl.pointee.sv_reftype(SvRV(&self), true))
	}

	mutating func hasSwiftObjectMagic(perl: UnsafeInterpreterPointer) -> Bool {
		return SvTYPE(&self) == SVt_PVMG && perl.pointee.mg_findext(&self, PERL_MAGIC_ext, &objectMgvtbl) != nil
	}

	mutating func swiftObject(perl: UnsafeInterpreterPointer) -> PerlBridgedObject? {
		guard isObject(perl: perl) else { return nil }
		let sv = SvRV(&self)!
		guard sv.pointee.hasSwiftObjectMagic(perl: perl) else { return nil }
		let iv = perl.pointee.SvIV(sv)
		let u = Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(bitPattern: iv)!)
		return (u.takeUnretainedValue() as! PerlBridgedObject)
	}
}

extension UnsafeInterpreter {
	mutating func newSV(_ v: Bool) -> UnsafeSvPointer {
		return newSV(boolSV(v))
	}

	mutating func newSV(_ v: String, mortal: Bool = false) -> UnsafeSvPointer {
		let flags = mortal ? SVf_UTF8|SVs_TEMP : SVf_UTF8
		return v.withCStringWithLength { newSVpvn_flags($0, $1, UInt32(flags)) }
	}

	mutating func newRV<T: UnsafeSvCastable>(inc v: UnsafeMutablePointer<T>) -> UnsafeSvPointer {
		return v.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { newRV(inc: $0) }
	}

	mutating func newRV<T: UnsafeSvCastable>(noinc v: UnsafeMutablePointer<T>) -> UnsafeSvPointer {
		return v.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { newRV(noinc: $0) }
	}

	mutating func newSV(_ v: AnyObject, isa: String) -> UnsafeSvPointer {
		let u = Unmanaged<AnyObject>.passRetained(v)
		let iv = unsafeBitCast(u, to: Int.self)
		let sv = sv_setref_iv(newSV(), isa, iv)
		sv_magicext(SvRV(sv), nil, PERL_MAGIC_ext, &objectMgvtbl, nil, 0)
		return sv
	}

	mutating func newSV(_ v: PerlBridgedObject) -> UnsafeSvPointer {
		return newSV(v, isa: type(of: v).perlClassName)
	}
}

private var objectMgvtbl = MGVTBL(
	svt_get: nil,
	svt_set: nil,
	svt_len: nil,
	svt_clear: nil,
	svt_free: {
		(perl, sv, magic) in
		let iv = perl.unsafelyUnwrapped.pointee.SvIV(sv.unsafelyUnwrapped)
		let u = Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(bitPattern: iv)!)
		u.release()
		return 0
	},
	svt_copy: nil,
	svt_dup: nil,
	svt_local: nil
)

extension Bool {
	public init(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self = perl.pointee.SvTRUE(sv)
	}

	public init?(nilable sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		guard SvOK(sv) else { return nil }
		self = perl.pointee.SvTRUE(sv)
	}
}

extension Int {
	public init(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		guard sv.pointee.type == .scalar else {
			throw PerlError.unexpectedSvType(fromUnsafeSvPointer(inc: sv, perl: perl), want: .scalar)
		}
		guard SvOK(sv) else {
			throw PerlError.unexpectedUndef(fromUnsafeSvPointer(inc: sv, perl: perl))
		}
		self.init(unchecked: sv, perl: perl)
	}

	public init?(nilable sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		guard SvOK(sv) else { return nil }
		self.init(unchecked: sv, perl: perl)
	}

	public init(unchecked sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self = perl.pointee.SvIV(sv)
	}
}

extension String {
	public init(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		guard sv.pointee.type == .scalar else {
			throw PerlError.unexpectedSvType(fromUnsafeSvPointer(inc: sv, perl: perl), want: .scalar)
		}
		guard SvOK(sv) else {
			throw PerlError.unexpectedUndef(fromUnsafeSvPointer(inc: sv, perl: perl))
		}
		self.init(unchecked: sv, perl: perl)
	}

	public init?(nilable sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		guard SvOK(sv) else { return nil }
		self.init(unchecked: sv, perl: perl)
	}

	public init(unchecked sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		var clen = 0
		let cstr = perl.pointee.SvPV(sv, &clen)!
		self = String(cString: cstr, withLength: clen)
	}
}
