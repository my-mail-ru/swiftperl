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

public struct UnsafeSvContext {
	public let sv: UnsafeSvPointer
	public let perl: PerlInterpreter

	public init(sv: UnsafeSvPointer, perl: PerlInterpreter) {
		self.sv = sv
		self.perl = perl
	}

	@discardableResult
	func refcntInc() -> UnsafeSvPointer {
		return SvREFCNT_inc_NN(sv)
	}

	func refcntDec() {
		perl.pointee.SvREFCNT_dec_NN(sv)
	}

	@discardableResult
	func mortal() -> UnsafeSvPointer {
		return perl.pointee.sv_2mortal(sv)!
	}

	var type: SvType { return SvType(SvTYPE(sv)) }
	var defined: Bool { return SvOK(sv) }
	var isInteger: Bool { return SvIOK(sv) }
	var isDouble: Bool { return SvNOK(sv) }
	var isString: Bool { return SvPOK(sv) }
	var isRef: Bool { return SvROK(sv) }

	var referent: UnsafeSvContext? {
		return SvROK(sv) ? UnsafeSvContext(sv: SvRV(sv)!, perl: perl) : nil
	}

	func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
		var clen = 0
		let cstr = perl.pointee.SvPV(sv, &clen)!
		let bytes = UnsafeRawBufferPointer(start: cstr, count: clen)
		return try body(bytes)
	}

	var isObject: Bool { return perl.pointee.sv_isobject(sv) }

	func isDerived(from: String) -> Bool {
		return from.withCString { perl.pointee.sv_derived_from(sv, $0) }
	}

	var classname: String? {
		guard isObject else { return nil }
		return String(cString: perl.pointee.sv_reftype(SvRV(sv)!, true))
	}

	private var hasSwiftObjectMagic: Bool {
		return SvTYPE(sv) == SVt_PVMG && perl.pointee.mg_findext(sv, PERL_MAGIC_ext, &objectMgvtbl) != nil
	}

	var swiftObject: PerlBridgedObject? {
		guard isObject else { return nil }
		let rvc = UnsafeSvContext(sv: SvRV(sv)!, perl: perl)
		guard rvc.hasSwiftObjectMagic else { return nil }
		let iv = perl.pointee.SvIV(rvc.sv)
		let u = Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(bitPattern: iv)!)
		return (u.takeUnretainedValue() as! PerlBridgedObject)
	}

	static func new(perl: PerlInterpreter) -> UnsafeSvContext {
		return UnsafeSvContext(sv: perl.pointee.newSV(0), perl: perl)
	}

	static func new(copy src: UnsafeSvContext) -> UnsafeSvContext {
		return UnsafeSvContext(sv: src.perl.pointee.newSVsv(src.sv)!, perl: src.perl)
	}

	// newSV() and sv_setsv() are used instead of newSVsv() to allow
	// stealing temporary buffers and enable COW-optimizations.
	static func new(stealingCopy src: UnsafeSvContext) -> UnsafeSvContext {
		let dst = UnsafeSvContext.new(perl: src.perl)
		dst.set(src.sv)
		return dst
	}

	static func new(rvInc svc: UnsafeSvContext) -> UnsafeSvContext {
		return UnsafeSvContext(sv: svc.perl.pointee.newRV_inc(svc.sv), perl: svc.perl)
	}

	static func new(_ v: UnsafeRawBufferPointer, utf8: Bool = false, mortal: Bool = false, perl: PerlInterpreter) -> UnsafeSvContext {
		let sv = perl.pointee.newSVpvn_flags(v.baseAddress?.assumingMemoryBound(to: CChar.self), v.count, UInt32(mortal ? SVs_TEMP : 0))
		if utf8 {
			perl.pointee.sv_utf8_decode(sv)
		}
		return UnsafeSvContext(sv: sv, perl: perl)
	}

	func set(_ ssv: UnsafeSvPointer) {
		perl.pointee.sv_setsv(sv, ssv)
	}

	func set(_ value: Bool) {
		set(perl.pointee.boolSV(value))
	}

	func set(_ value: Int) {
		perl.pointee.sv_setiv(sv, value)
	}

	func set(_ value: UInt) {
		perl.pointee.sv_setuv(sv, value)
	}

	func set(_ value: Double) {
		perl.pointee.sv_setnv(sv, value)
	}

	func set(_ value: String) {
		value.withCStringWithLength { perl.pointee.sv_setpvn(sv, $0, $1) }
		if value._core.isASCII {
			SvUTF8_off(sv)
		} else {
			SvUTF8_on(sv)
		}
	}

	func set(_ value: UnsafeRawBufferPointer, containing: PerlScalar.StringUnits = .bytes) {
		SvUTF8_off(sv)
		perl.pointee.sv_setpvn(sv, value.baseAddress?.assumingMemoryBound(to: CChar.self), value.count)
		if containing == .characters {
			perl.pointee.sv_utf8_decode(sv)
		}
	}

	var hash: UInt32 {
		return perl.pointee.SvHASH(sv)
	}

	func dump() {
		perl.pointee.sv_dump(sv)
	}

	static func eq(_ lhs: UnsafeSvContext, _ rhs: UnsafeSvContext) -> Bool {
		return lhs.perl.pointee.sv_eq(lhs.sv, rhs.sv)
	}
}

extension UnsafeSvContext {
	func withUnsafeAvContext<R>(_ body: (UnsafeAvContext) throws -> R) rethrows -> R {
		return try sv.withMemoryRebound(to: UnsafeAV.self, capacity: 1) { av in
			try body(UnsafeAvContext(av: av, perl: perl))
		}
	}

	func withUnsafeHvContext<R>(_ body: (UnsafeHvContext) throws -> R) rethrows -> R {
		return try sv.withMemoryRebound(to: UnsafeHV.self, capacity: 1) { hv in
			try body(UnsafeHvContext(hv: hv, perl: perl))
		}
	}

	func withUnsafeCvContext<R>(_ body: (UnsafeCvContext) throws -> R) rethrows -> R {
		return try sv.withMemoryRebound(to: UnsafeCV.self, capacity: 1) { cv in
			try body(UnsafeCvContext(cv: cv, perl: perl))
		}
	}

	init(rebind avc: UnsafeAvContext) {
		let sv = UnsafeMutableRawPointer(avc.av).bindMemory(to: UnsafeSV.self, capacity: 1)
		self.init(sv: sv, perl: avc.perl)
	}

	init(rebind hvc: UnsafeHvContext) {
		let sv = UnsafeMutableRawPointer(hvc.hv).bindMemory(to: UnsafeSV.self, capacity: 1)
		self.init(sv: sv, perl: hvc.perl)
	}

	init(rebind cvc: UnsafeCvContext) {
		let sv = UnsafeMutableRawPointer(cvc.cv).bindMemory(to: UnsafeSV.self, capacity: 1)
		self.init(sv: sv, perl: cvc.perl)
	}
}

extension PerlInterpreter {
	func newSV(_ v: Bool) -> UnsafeSvPointer {
		return pointee.newSVsv(pointee.boolSV(v))!
	}

	func newSV(_ v: String, mortal: Bool = false) -> UnsafeSvPointer {
		let flags = (v._core.isASCII ? 0 : SVf_UTF8) | (mortal ? SVs_TEMP : 0)
		return v.withCStringWithLength { pointee.newSVpvn_flags($0, $1, UInt32(flags)) }
	}

	func newRV<T: UnsafeSvCastable>(inc v: UnsafeMutablePointer<T>) -> UnsafeSvPointer {
		return v.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { pointee.newRV_inc($0) }
	}

	func newRV<T: UnsafeSvCastable>(noinc v: UnsafeMutablePointer<T>) -> UnsafeSvPointer {
		return v.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { pointee.newRV_noinc($0) }
	}

	func newSV(_ v: AnyObject, isa: String) -> UnsafeSvPointer {
		let u = Unmanaged<AnyObject>.passRetained(v)
		let iv = unsafeBitCast(u, to: Int.self)
		let sv = pointee.sv_setref_iv(pointee.newSV(0), isa, iv)
		pointee.sv_magicext(SvRV(sv)!, nil, PERL_MAGIC_ext, &objectMgvtbl, nil, 0)
		return sv
	}

	func newSV(_ v: PerlBridgedObject) -> UnsafeSvPointer {
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
	public init(_ svc: UnsafeSvContext) {
		self = svc.perl.pointee.SvTRUE(svc.sv)
	}
}

extension Int {
	public init(_ svc: UnsafeSvContext) throws {
		self.init(unchecked: svc)
		guard SvIOK(svc.sv) && (!SvIsUV(svc.sv) || UInt(bitPattern: self) <= UInt(Int.max))
			|| SvNOK(svc.sv) && (!SvIsUV(svc.sv) && self != Int.min || UInt(bitPattern: self) <= UInt(Int.max)) else {
			throw PerlError.notNumber(fromUnsafeSvContext(inc: svc), want: Int.self)
		}
	}

	public init(unchecked svc: UnsafeSvContext) {
		self = svc.perl.pointee.SvIV(svc.sv)
	}
}

extension UInt {
	public init(_ svc: UnsafeSvContext) throws {
		self.init(unchecked: svc)
		guard SvIOK(svc.sv) && (SvIsUV(svc.sv) || Int(bitPattern: self) >= Int(UInt.min))
			|| SvNOK(svc.sv) && (SvIsUV(svc.sv) && self != UInt.max || Int(bitPattern: self) >= Int(UInt.min)) else {
			throw PerlError.notNumber(fromUnsafeSvContext(inc: svc), want: UInt.self)
		}
	}

	public init(unchecked svc: UnsafeSvContext) {
		self = svc.perl.pointee.SvUV(svc.sv)
	}
}

extension Double {
	public init(_ svc: UnsafeSvContext) throws {
		self.init(unchecked: svc)
		guard SvNIOK(svc.sv) else {
			throw PerlError.notNumber(fromUnsafeSvContext(inc: svc), want: Double.self)
		}
	}

	public init(unchecked svc: UnsafeSvContext) {
		self = svc.perl.pointee.SvNV(svc.sv)
	}
}

extension String {
	public init(_ svc: UnsafeSvContext) throws {
		self.init(unchecked: svc)
		guard SvPOK(svc.sv) || SvNOK(svc.sv) else {
			throw PerlError.notStringOrNumber(fromUnsafeSvContext(inc: svc))
		}
	}

	public init(unchecked svc: UnsafeSvContext) {
		var clen = 0
		let cstr = svc.perl.pointee.SvPV(svc.sv, &clen)!
		self = String(cString: cstr, withLength: clen)
	}
}
