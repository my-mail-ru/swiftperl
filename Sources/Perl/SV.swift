protocol PerlSVProtocol {
	associatedtype Struct

	var pointer: UnsafeMutablePointer<Struct> { get }
	var perl: UnsafeInterpreterPointer { get }

	init(_: UnsafeMutablePointer<Struct>, perl: UnsafeInterpreterPointer)
}

final class PerlSV : PerlSVProtocol {
	typealias Struct = UnsafeSV
	typealias Pointer = UnsafeSvPointer
	let pointer: Pointer
	let perl: UnsafeInterpreterPointer

	init(_ p: Pointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = p.pointee.refcntInc()
	}

	convenience init() { self.init(perl: UnsafeInterpreter.current) } // default bellow doesn't work...

	init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = perl.pointee.newSV()
	}

	init(_ v: Bool, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = perl.pointee.newSV(v)
	}

	init(_ v: Int, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = perl.pointee.newSV(v)
	}

	init(_ v: String, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = perl.pointee.newSV(v)
	}

	init<T: PerlSVProtocol>(referenceTo sv: T) {
		perl = sv.perl
		pointer = perl.pointee.newRV(inc: Pointer(sv.pointer))
	}

	convenience init(_ av: PerlAV) {
		self.init(referenceTo: av)
	}

	convenience init(_ hv: PerlHV) {
		self.init(referenceTo: hv)
	}

	convenience init(_ cv: PerlCV) {
		self.init(referenceTo: cv)
	}

	init(_ v: PerlMappedClass, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = perl.pointee.newSV(v)
	}

	deinit {
		pointer.pointee.refcntDec(perl: perl)
	}

	var type: SvType { return pointer.pointee.type }
	var defined: Bool { return pointer.pointee.defined }
	var isInt: Bool { return pointer.pointee.isInt }
	var isString: Bool { return pointer.pointee.isString }
	var isRef: Bool { return pointer.pointee.isRef }
	var isObject: Bool { return pointer.pointee.isObject(perl: perl) }

	var refValue: PerlSV? {
		guard let sv = pointer.pointee.refValue else { return nil }
		return PerlSV(sv)
	}

	func value() -> Bool { return pointer.pointee.value(perl: perl) }
	func value() -> Int { return pointer.pointee.value(perl: perl) }
	func value() -> String { return pointer.pointee.value(perl: perl) }

	func value() throws -> PerlAV { return try pointer.pointee.value() }
	func value() throws -> PerlHV { return try pointer.pointee.value() }
	func value() throws -> PerlCV { return try pointer.pointee.value() }

	func value<T: PerlMappedClass>() throws -> T { return try pointer.pointee.value(perl: perl) }
	func value<T: PerlObjectType>() throws -> T { return try pointer.pointee.value(perl: perl) }

	func value<T: PerlSVConvertible>() throws -> [T] { return try (value() as PerlAV).value() } // FIXME use unsafeAv
	func value<T: PerlSVConvertible>() throws -> [String: T] { return try (value() as PerlHV).value() } // FIXME use unsafeHv
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
