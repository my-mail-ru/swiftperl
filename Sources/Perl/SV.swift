import CPerl

protocol PerlSVProtocol {
	associatedtype Struct
	typealias Pointer = UnsafeMutablePointer<Struct>

	var pointer: Pointer { get }

	init(_: Pointer)

	var refcnt: UInt32 { get }
	mutating func refcntInc()
	mutating func refcntDec()
}

extension PerlSVProtocol {
	var refcnt: UInt32 { return SvREFCNT(PerlSV.Pointer(pointer)) }

	func refcntInc() {
		SvREFCNT_inc(PerlSV.Pointer(pointer))
	}

	func refcntDec() {
		SvREFCNT_dec(PerlSV.Pointer(pointer))
	}
}

final class PerlSV : PerlSVProtocol {
	typealias Struct = sv
	typealias Pointer = UnsafeMutablePointer<Struct>
	let pointer: Pointer

	internal init (noinc p: Pointer) {
		pointer = p
	}

	init (_ p: Pointer) {
		pointer = p
		refcntInc()
	}

	deinit {
		refcntDec()
	}

	var type: svtype { return SvTYPE(pointer) }
}

// Undef
extension PerlSV {
	convenience init() {
		self.init(noinc: newSV(0))
	}

	var defined: Bool { return SvOK(pointer) }
}

// Bool
extension PerlSV {
	convenience init(_ value: Bool) {
		self.init(noinc: newSVbv(value))
	}
}

// Int
extension PerlSV {
	convenience init(_ value: Int) {
		self.init(noinc: newSViv(value))
	}

	var isInt: Bool { return SvIOK(pointer) }
}

// String and Buffer
extension PerlSV {
	convenience init (_ string: String) {
		let sv = string.withCStringWithLength {
			newSVpvn_utf8($0, $1, true)!
		}
		self.init(noinc: sv)
	}

	convenience init (_ buffer: [UInt8]) {
		let sv = buffer.withUnsafeBufferPointer {
			newSVpvn_utf8(UnsafePointer<Int8>($0.baseAddress), $0.count, false)!
		}
		self.init(noinc: sv)
	}

	var isString: Bool { return SvPOK(pointer) }

	var string: String {
		get {
			var clen = 0
			let cstr = SvPV(pointer, &clen)!
			return String(cString: cstr, withLength: clen)
		}
		set {
			newValue.withCStringWithLength {
				sv_setpvn(pointer, $0, $1) // FIXME set UTF8 flag
			}
		}
	}

	var buffer: [UInt8] {
		get {
			return withUnsafeBufferPointer { [UInt8]($0) }
		}
		set {
			newValue.withUnsafeBufferPointer {
				sv_setpvn(pointer, UnsafePointer<Int8>($0.baseAddress), $0.count) // FIXME drop UTF8 flag
			}
		}
	}

	func withUnsafeBufferPointer<R>(_ body: @noescape (UnsafeBufferPointer<UInt8>) throws -> R) rethrows -> R {
		var len = 0
		let str = SvPV(pointer, &len)
		let buffer = UnsafeBufferPointer(start: UnsafePointer<UInt8>(str), count: len)
		return try body(buffer)
	}

	func value() -> String { return string }
	func value() -> [UInt8] { return buffer }
}

// RV
extension PerlSV {
	convenience init(referenceTo sv: Pointer) {
		self.init(noinc: newRV_inc(sv))
	}

	convenience init<T: PerlSVProtocol>(referenceTo sv: T) {
		self.init(referenceTo: Pointer(sv.pointer))
	}

	var isRef: Bool { return SvROK(pointer) }

	var ref: PerlSV? { return isRef ? PerlSV(SvRV(pointer)) : nil }
}

// AV, HV, CV
extension PerlSV {
	convenience init(_ av: PerlAV) {
		self.init(referenceTo: av)
	}

	convenience init(_ hv: PerlHV) {
		self.init(referenceTo: hv)
	}

	convenience init(_ cv: PerlCV) {
		self.init(referenceTo: cv)
	}
}

// Object
extension PerlSV {
	// TODO perl object init
	convenience init (_ object: PerlMappedClass) {
		let addr = unsafeAddress(of: object)
		let iv = unsafeBitCast(addr, to: Int.self)
		self.init(noinc: sv_setref_iv(newSV(0), "Swift::\(object.self)", iv)!)
		objects[iv] = object
	}
}

extension PerlSV : NilLiteralConvertible {
	convenience init(nilLiteral: ()) {
		self.init()
	}
}

extension PerlSV: BooleanLiteralConvertible {
	convenience init(booleanLiteral value: Bool) {
		self.init(value)
	}
}

extension PerlSV : IntegerLiteralConvertible {
	convenience init(integerLiteral value: Int) {
		self.init(value)
	}
}

extension PerlSV : UnicodeScalarLiteralConvertible {
	convenience init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExtendedGraphemeClusterLiteralConvertible {
	convenience init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : StringLiteralConvertible {
	convenience init(stringLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV: ArrayLiteralConvertible {
	convenience init (arrayLiteral elements: PerlSV...) {
		self.init(PerlAV(elements))
	}
}

extension PerlSV : DictionaryLiteralConvertible {
	convenience init(dictionaryLiteral elements: (String, PerlSV)...) {
		self.init(PerlHV(elements))
	}
}

protocol PerlSVConvertible {
	static func fromPerlSV(_: PerlSV) throws -> Self
	var perlSV: PerlSV { get }
}

protocol PerlSVConvertibleThrowing : PerlSVConvertible {}

protocol PerlSVConvertibleNonThrowing : PerlSVConvertible {
	static func fromPerlSV(_: PerlSV) -> Self
}

protocol PerlSVConvertibleByInit : PerlSVConvertibleThrowing {
	init(_: PerlSV) throws
}

extension PerlSVConvertibleByInit {
	static func fromPerlSV(_ sv: PerlSV) throws -> Self {
		return try self.init(sv)
	}
}

protocol PerlSVConvertibleNonThrowingByInit : PerlSVConvertibleNonThrowing {
	init(_: PerlSV)
}

extension PerlSVConvertibleNonThrowingByInit {
	static func fromPerlSV(_ sv: PerlSV) -> Self {
		return self.init(sv)
	}
}

extension Bool : PerlSVConvertibleNonThrowingByInit {
	init(_ sv: PerlSV) { self = SvTRUE(sv.pointer) }
	var perlSV: PerlSV { return PerlSV(self) }
}

extension Int : PerlSVConvertibleNonThrowingByInit {
	init(_ sv: PerlSV) { self = SvIV(sv.pointer) }
	var perlSV: PerlSV { return PerlSV(self) }
}

extension String : PerlSVConvertibleNonThrowingByInit {
	init(_ sv: PerlSV) { self = sv.string }
	var perlSV: PerlSV { return PerlSV(self) }
}

extension PerlAV : PerlSVConvertibleByInit {
	convenience init(_ sv: PerlSV) throws {
		guard let r = sv.ref else { throw PerlError.notRV(sv) }
		guard r.type == SVt_PVAV else { throw PerlError.notAV(r) }
		self.init(Pointer(r.pointer))
	}
	var perlSV: PerlSV { return PerlSV(self) }
}

extension PerlHV : PerlSVConvertibleByInit {
	convenience init(_ sv: PerlSV) throws {
		guard let r = sv.ref else { throw PerlError.notRV(sv) }
		guard r.type == SVt_PVHV else { throw PerlError.notHV(r) }
		self.init(Pointer(r.pointer))
	}
	var perlSV: PerlSV { return PerlSV(self) }
}

extension PerlCV : PerlSVConvertibleByInit {
	convenience init(_ sv: PerlSV) throws {
		guard let r = sv.ref else { throw PerlError.notRV(sv) }
		guard r.type == SVt_PVCV else { throw PerlError.notCV(r) }
		self.init(Pointer(r.pointer))
	}
	var perlSV: PerlSV { return PerlSV(self) }
}

protocol PerlMappedClass : class, PerlSVConvertibleThrowing {}

extension PerlMappedClass {
	static func fromPerlSV(_ sv: PerlSV) throws -> Self {
		guard sv_isobject(sv.pointer) else { throw PerlError.notObject(sv) }
		let iv = SvIV(SvRV(sv.pointer))
		guard let object = objects[iv] else { throw PerlError.notSwiftObject(sv) }
		guard let obj = object as? Self else { throw PerlError.unexpectedSwiftObject(sv) }
		return obj
	}
	var perlSV: PerlSV { return PerlSV(self) }
}

extension PerlObjectType {
	static func fromPerlSV(_ sv: PerlSV) throws -> Self {
		guard sv_isobject(sv.pointer) else { throw PerlError.notObject(sv) }
		let classname = String(cString: sv_reftype(SvRV(sv.pointer), true))
		guard let perlClass = PerlInterpreter.classMapping[classname] else { throw PerlError.unsupportedPerlClass(sv) }
		guard let obj = perlClass.init(sv) as? Self else { throw PerlError.unexpectedPerlClass(sv) }
		return obj
	}
	var perlSV: PerlSV { return sv }
}

extension PerlSV : PerlSVConvertibleNonThrowing {
	static func fromPerlSV(_ sv: PerlSV) -> PerlSV { return sv }
	var perlSV: PerlSV { return self }
}

extension PerlSV {
	func value<T: PerlSVConvertibleThrowing>() throws -> T {
		return try T.fromPerlSV(self)
	}
	func value<T: PerlSVConvertibleNonThrowing>() -> T {
		return T.fromPerlSV(self)
	}

/*	func value<T: PerlSVConvertible>() throws -> T? {
		return self.defined ? try T.fromPerlSV(self) : nil
	}*/
}
