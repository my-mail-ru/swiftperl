import CPerl

protocol PerlSVConvertible {
	static func cast(from sv: UnsafeSvPointer) throws -> Self
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) -> UnsafeSvPointer
}

extension PerlSVConvertible {
	init?(_ sv: UnsafeSvPointer) throws {
		guard sv.pointee.defined else { return nil }
		self = try Self.cast(from: sv)
	}

	init(nonNil sv: UnsafeSvPointer) throws {
		self = try Self.cast(from: sv)
	}
}

protocol PerlSVConvertibleThrowing : PerlSVConvertible {}

protocol PerlSVConvertibleNonThrowing : PerlSVConvertible {
	static func cast(from sv: UnsafeSvPointer) -> Self
}

protocol PerlSVConvertibleByInit : PerlSVConvertibleThrowing {
	init(_: PerlSV) throws
}

extension PerlSVConvertibleByInit {
	init(_ sv: UnsafeSvPointer) throws { self = try Self.cast(from: sv) }
}

protocol PerlSVConvertibleNonThrowingByInit : PerlSVConvertibleNonThrowing {
	init(_: PerlSV)
}

extension PerlSVConvertibleNonThrowingByInit {
	init(_ sv: UnsafeSvPointer) { self = Self.cast(from: sv) }
}

extension Bool : PerlSVConvertibleNonThrowingByInit {
	static func cast(from sv: UnsafeSvPointer) -> Bool { return sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
	init(_ sv: PerlSV) { self = sv.value() }
}

extension Int : PerlSVConvertibleNonThrowingByInit {
	static func cast(from sv: UnsafeSvPointer) -> Int { return sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
	init(_ sv: PerlSV) { self = sv.value() }
}

extension String : PerlSVConvertibleNonThrowingByInit {
	static func cast(from sv: UnsafeSvPointer) -> String { return sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
	init(_ sv: PerlSV) { self = sv.value() }
}

extension PerlSV : PerlSVConvertibleNonThrowing {
	static func cast(from sv: UnsafeSvPointer) -> PerlSV { return sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return self.pointer.pointee.refcntInc() }
}

extension PerlAV : PerlSVConvertibleByInit {
	static func cast(from sv: UnsafeSvPointer) throws -> PerlAV { return try sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newRV(inc: self.pointer) }
	convenience init(_ sv: PerlSV) throws { self.init(try sv.pointer.pointee.value() as UnsafeAvPointer) }
}

extension PerlHV : PerlSVConvertibleByInit {
	static func cast(from sv: UnsafeSvPointer) throws -> PerlHV { return try sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newRV(inc: self.pointer) }
	convenience init(_ sv: PerlSV) throws { self.init(try sv.pointer.pointee.value() as UnsafeHvPointer) }
}

extension PerlCV : PerlSVConvertibleByInit {
	static func cast(from sv: UnsafeSvPointer) throws -> PerlCV { return try sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newRV(inc: self.pointer) }
	convenience init(_ sv: PerlSV) throws { self.init(try sv.pointer.pointee.value() as UnsafeCvPointer) }
}

protocol PerlMappedClass : class, PerlSVConvertibleThrowing {
	static var perlClassName: String { get }
}

extension PerlMappedClass {
	static func cast(from sv: UnsafeSvPointer) throws -> Self { return try sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }

	static func tCast<T>(from sv: UnsafeSvPointer) throws -> T {
		let url: Self = try sv.pointee.value()
		return url as! T
	}
}

extension PerlObjectType {
	static func cast(from sv: UnsafeSvPointer) throws -> Self { return try sv.pointee.value() }
	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return self.sv.pointer.pointee.refcntInc() }
}

extension Optional where Wrapped : PerlSVConvertible {
	static func cast(from sv: UnsafeSvPointer) throws -> Optional<Wrapped> {
		return sv.pointee.defined ? try Wrapped.cast(from: sv) : nil
	}

	func newUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		switch self {
			case .some(let value):
				return value.newUnsafeSvPointer(perl: perl)
			case .none:
				return perl.pointee.newSV()
		}
	}
}

extension RangeReplaceableCollection where Iterator.Element == UnsafeSvPointer, IndexDistance == Int {
	init<C : Collection>(_ c: C, perl: UnsafeInterpreterPointer) where C.Iterator.Element == PerlSVConvertible? {
		func transform(_ v: PerlSVConvertible?) -> UnsafeSvPointer {
			return v?.newUnsafeSvPointer(perl: perl) ?? perl.pointee.newSV()
		}
		self.init()
		let initialCapacity = c.underestimatedCount
		self.reserveCapacity(initialCapacity)

		var iterator = c.makeIterator()

		// Add elements up to the initial capacity without checking for regrowth.
		for _ in 0..<initialCapacity {
			self.append(transform(iterator.next()!))
		}
		// Add remaining elements, if any.
		while let element = iterator.next() {
			self.append(transform(element))
		}
	}

	// FIXME remove it
	init<C : Collection>(_ c: C, perl: UnsafeInterpreterPointer) where C.Iterator.Element : PerlSVConvertible {
		func transform(_ v: PerlSVConvertible) -> UnsafeSvPointer {
			return v.newUnsafeSvPointer(perl: perl)
		}
		self.init()
		let initialCapacity = c.underestimatedCount
		self.reserveCapacity(initialCapacity)

		var iterator = c.makeIterator()

		// Add elements up to the initial capacity without checking for regrowth.
		for _ in 0..<initialCapacity {
			self.append(transform(iterator.next()!))
		}
		// Add remaining elements, if any.
		while let element = iterator.next() {
			self.append(transform(element))
		}
	}
}

extension RangeReplaceableCollection where Iterator.Element : PerlSVConvertible, IndexDistance == Int {
	init<C : Collection>(_ c: C, perl: UnsafeInterpreterPointer) throws where C.Iterator.Element == UnsafeSvPointer {
		func transform(_ v: UnsafeSvPointer) throws -> Iterator.Element {
			return try Iterator.Element.cast(from: v)
		}
		self.init()
		let initialCapacity = c.underestimatedCount
		self.reserveCapacity(initialCapacity)

		var iterator = c.makeIterator()

		// Add elements up to the initial capacity without checking for regrowth.
		for _ in 0..<initialCapacity {
			self.append(try transform(iterator.next()!))
		}
		// Add remaining elements, if any.
		while let element = iterator.next() {
			self.append(try transform(element))
		}
	}
}
