import CPerl

protocol PerlSVConvertible {
	static func promoteFromUnsafeSV(_: UnsafeSvPointer, perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) throws -> Self
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) -> UnsafeSvPointer
}

protocol PerlSVProbablyConvertible : PerlSVConvertible {}

protocol PerlSVDefinitelyConvertible : PerlSVConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) -> Self
}

extension Bool : PerlSVDefinitelyConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Bool { return Bool(sv, perl: perl) }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension Int : PerlSVDefinitelyConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Int { return Int(forcing: sv, perl: perl) }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension String : PerlSVDefinitelyConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> String { return String(forcing: sv, perl: perl) }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension PerlSV : PerlSVDefinitelyConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> PerlSV { return PerlSV(sv, perl: perl) }
	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return self.pointer.pointee.refcntInc() }
}

extension PerlSvCastable {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		guard let unsafe = try UnsafeMutablePointer<Struct>(sv, perl: perl) else { throw PerlError.unexpectedUndef(PerlSV(sv, perl: perl)) }
		return self.init(unsafe, perl: perl)
	}

	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return perl.pointee.newRV(inc: self.pointer)
	}
}

protocol PerlMappedClass : class, PerlSVProbablyConvertible {
	static var perlClassName: String { get }
}

extension PerlMappedClass {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try _promoteFromUnsafeSvNonFinalClassWorkaround(sv, perl: perl)
	}

	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return perl.pointee.newSV(self)
	}

	static func _promoteFromUnsafeSvNonFinalClassWorkaround<T>(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		let base = try sv.pointee.swiftObject(perl: perl)
		guard let obj = base as? T else { throw PerlError.unexpectedObjectType(PerlSV(sv, perl: perl)) }
		return obj
	}
}

extension PerlObjectType {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		guard let obj = try sv.pointee.swiftObject(perl: perl) as? Self else {
			throw PerlError.unexpectedObjectType(PerlSV(sv, perl: perl))
		}
		return obj
	}

	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return self.sv.pointer.pointee.refcntInc()
	}
}

extension Optional where Wrapped : PerlSVConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Optional<Wrapped> {
		return sv.pointee.defined ? try Wrapped.promoteFromUnsafeSV(sv, perl: perl) : nil
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

extension Array where Element : PerlSVConvertible {
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
