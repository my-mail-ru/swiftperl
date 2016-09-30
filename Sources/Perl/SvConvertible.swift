import CPerl

protocol PerlSVConvertible {
	static func promoteFromUnsafeSV(_: UnsafeSvPointer) throws -> Self
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) -> UnsafeSvPointer
}

extension PerlSVConvertible {
	init?(_ sv: UnsafeSvPointer) throws {
		guard sv.pointee.defined else { return nil }
		self = try Self.promoteFromUnsafeSV(sv)
	}

	init(nonNil sv: UnsafeSvPointer) throws {
		self = try Self.promoteFromUnsafeSV(sv)
	}
}

protocol PerlSVConvertibleThrowing : PerlSVConvertible {}

protocol PerlSVConvertibleNonThrowing : PerlSVConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) -> Self
}

protocol PerlSVConvertibleByInit : PerlSVConvertibleThrowing {
	init(_: PerlSV) throws
}

extension PerlSVConvertibleByInit {
	init(_ sv: UnsafeSvPointer) throws { self = try Self.promoteFromUnsafeSV(sv) }
}

protocol PerlSVConvertibleNonThrowingByInit : PerlSVConvertibleNonThrowing {
	init(_: PerlSV)
}

extension PerlSVConvertibleNonThrowingByInit {
	init(_ sv: UnsafeSvPointer) { self = Self.promoteFromUnsafeSV(sv) }
}

extension Bool : PerlSVConvertibleNonThrowingByInit {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) -> Bool { return sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
	init(_ sv: PerlSV) { self = sv.value() }
}

extension Int : PerlSVConvertibleNonThrowingByInit {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) -> Int { return sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
	init(_ sv: PerlSV) { self = sv.value() }
}

extension String : PerlSVConvertibleNonThrowingByInit {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) -> String { return sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
	init(_ sv: PerlSV) { self = sv.value() }
}

extension PerlSV : PerlSVConvertibleNonThrowing {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) -> PerlSV { return sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return self.pointer.pointee.refcntInc() }
}

extension PerlAV : PerlSVConvertibleByInit {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) throws -> PerlAV { return try sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newRV(inc: self.pointer) }
	convenience init(_ sv: PerlSV) throws { self.init(try sv.pointer.pointee.value() as UnsafeAvPointer) }
}

extension PerlHV : PerlSVConvertibleByInit {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) throws -> PerlHV { return try sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newRV(inc: self.pointer) }
	convenience init(_ sv: PerlSV) throws { self.init(try sv.pointer.pointee.value() as UnsafeHvPointer) }
}

extension PerlCV : PerlSVConvertibleByInit {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) throws -> PerlCV { return try sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newRV(inc: self.pointer) }
	convenience init(_ sv: PerlSV) throws { self.init(try sv.pointer.pointee.value() as UnsafeCvPointer) }
}

protocol PerlMappedClass : class, PerlSVConvertibleThrowing {
	static var perlClassName: String { get }
}

extension PerlMappedClass {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) throws -> Self { return try sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }

	static func _promoteFromUnsafeSvNonFinalClassWorkaround<T>(_ sv: UnsafeSvPointer) throws -> T {
		let base: Self = try sv.pointee.value()
		guard let obj = base as? T else { throw PerlError.unexpectedSwiftObject(sv.pointee.value()) }
		return obj
	}
}

extension PerlObjectType {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) throws -> Self { return try sv.pointee.value() }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return self.sv.pointer.pointee.refcntInc() }
}

extension Optional where Wrapped : PerlSVConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer) throws -> Optional<Wrapped> {
		return sv.pointee.defined ? try Wrapped.promoteFromUnsafeSV(sv) : nil
	}

	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		switch self {
			case .some(let value):
				return value.promoteToUnsafeSV(perl: perl)
			case .none:
				return perl.pointee.newSV()
		}
	}
}

extension Collection where Iterator.Element : PerlSVConvertible {
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		let av = perl.pointee.newAV()!
		var c = av.pointee.collection(perl: perl)
		c.reserveCapacity(numericCast(count))
		for (i, v) in enumerated() {
			c[i] = v.promoteToUnsafeSV(perl: perl)
		}
		return perl.pointee.newRV(noinc: av)
	}
}

// where Key == String, but it is unsupported
extension Dictionary where Value : PerlSVConvertible {
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		let hv = perl.pointee.newHV()!
		var c = hv.pointee.collection(perl: perl)
		for (k, v) in self {
			c[k as! String] = v.promoteToUnsafeSV(perl: perl)
		}
		return perl.pointee.newRV(noinc: hv)
	}
}
