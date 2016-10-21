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

extension PerlSV : PerlSVConvertible {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> PerlSV {
		return try PerlSV(inc: sv, perl: perl)
	}

	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, _ in sv.pointee.refcntInc() }
	}
}

extension PerlDerived where Self : PerlValue, UnsafeValue : UnsafeSvCastable {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		guard let unsafe = try UnsafeMutablePointer<UnsafeValue>(autoDeref: sv, perl: perl) else { throw PerlError.unexpectedUndef(Perl.promoteFromUnsafeSV(inc: sv, perl: perl)) }
		return self.init(inc: unsafe, perl: perl)
	}

	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, perl in perl.pointee.newRV(inc: sv) }
	}
}

extension PerlBridgedObject {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try _promoteFromUnsafeSvNonFinalClassWorkaround(sv, perl: perl)
	}

	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return perl.pointee.newSV(self)
	}

	static func _promoteFromUnsafeSvNonFinalClassWorkaround<T>(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		guard let base = sv.pointee.swiftObject(perl: perl) else {
			throw PerlError.notSwiftObject(Perl.promoteFromUnsafeSV(inc: sv, perl: perl))
		}
		guard let obj = base as? T else {
			throw PerlError.unexpectedObjectType(Perl.promoteFromUnsafeSV(inc: sv, perl: perl), want:  self)
		}
		return obj
	}
}

extension PerlObject {
	static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try _promoteFromUnsafeSvNonFinalClassWorkaround(sv, perl: perl)
	}

	func promoteToUnsafeSV(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, _ in sv.pointee.refcntInc() }
	}

	static func _promoteFromUnsafeSvNonFinalClassWorkaround<T>(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		guard let classname = sv.pointee.classname(perl: perl) else {
			throw PerlError.notObject(Perl.promoteFromUnsafeSV(inc: sv, perl: perl))
		}
		let base = PerlObject.derivedClass(for: classname).init(incUnchecked: sv, perl: perl)
		guard let obj = base as? T else {
			throw PerlError.unexpectedObjectType(Perl.promoteFromUnsafeSV(inc: sv, perl: perl), want: self)
		}
		return obj
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
