public protocol PerlSvConvertible {
	static func fromUnsafeSvPointer(_: UnsafeSvPointer, perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) throws -> Self
	func toUnsafeSvPointer(perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) -> UnsafeSvPointer
}

extension Bool : PerlSvConvertible {
	public static func fromUnsafeSvPointer(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Bool { return Bool(sv, perl: perl) }
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension Int : PerlSvConvertible {
	public static func fromUnsafeSvPointer(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Int { return try Int(sv, perl: perl) }
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension String : PerlSvConvertible {
	public static func fromUnsafeSvPointer(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> String { return try String(sv, perl: perl) }
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension PerlScalar : PerlSvConvertible {
	public static func fromUnsafeSvPointer(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> PerlScalar {
		return try PerlScalar(inc: sv, perl: perl)
	}

	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, _ in sv.pointee.refcntInc() }
	}
}

extension PerlDerived where Self : PerlValue, UnsafeValue : UnsafeSvCastable {
	public static func fromUnsafeSvPointer(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		guard let unsafe = try UnsafeMutablePointer<UnsafeValue>(autoDeref: sv, perl: perl) else { throw PerlError.unexpectedUndef(Perl.fromUnsafeSvPointer(inc: sv, perl: perl)) }
		return self.init(inc: unsafe, perl: perl)
	}

	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, perl in perl.pointee.newRV(inc: sv) }
	}
}

extension PerlBridgedObject {
	public static func fromUnsafeSvPointer(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try _fromUnsafeSvPointerNonFinalClassWorkaround(sv, perl: perl)
	}

	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return perl.pointee.newSV(self)
	}

	public static func _fromUnsafeSvPointerNonFinalClassWorkaround<T>(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		guard let base = sv.pointee.swiftObject(perl: perl) else {
			throw PerlError.notSwiftObject(Perl.fromUnsafeSvPointer(inc: sv, perl: perl))
		}
		guard let obj = base as? T else {
			throw PerlError.unexpectedObjectType(Perl.fromUnsafeSvPointer(inc: sv, perl: perl), want:  self)
		}
		return obj
	}
}

extension PerlObject {
	public static func fromUnsafeSvPointer(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try _fromUnsafeSvPointerNonFinalClassWorkaround(sv, perl: perl)
	}

	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, _ in sv.pointee.refcntInc() }
	}

	public static func _fromUnsafeSvPointerNonFinalClassWorkaround<T : PerlObject>(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		guard let classname = sv.pointee.classname(perl: perl) else {
			throw PerlError.notObject(Perl.fromUnsafeSvPointer(inc: sv, perl: perl))
		}
		if let nc = T.self as? PerlNamedClass.Type, nc.perlClassName == classname {
			return T(incUnchecked: sv, perl: perl)
		}
		let base = PerlObject.derivedClass(for: classname).init(incUnchecked: sv, perl: perl)
		guard let obj = base as? T else {
			throw PerlError.unexpectedObjectType(Perl.fromUnsafeSvPointer(inc: sv, perl: perl), want: self)
		}
		return obj
	}
}

extension Optional where Wrapped : PerlSvConvertible {
	public static func fromUnsafeSvPointer(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Optional<Wrapped> {
		return sv.pointee.defined ? try Wrapped.fromUnsafeSvPointer(sv, perl: perl) : nil
	}

	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		switch self {
			case .some(let value):
				return value.toUnsafeSvPointer(perl: perl)
			case .none:
				return perl.pointee.newSV()
		}
	}
}

extension Array where Element : PerlSvConvertible {
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		let av = perl.pointee.newAV()!
		var c = av.pointee.collection(perl: perl)
		c.reserveCapacity(numericCast(count))
		for (i, v) in enumerated() {
			c[i] = v.toUnsafeSvPointer(perl: perl)
		}
		return perl.pointee.newRV(noinc: av)
	}
}

// where Key == String, but it is unsupported
extension Dictionary where Value : PerlSvConvertible {
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		let hv = perl.pointee.newHV()!
		var c = hv.pointee.collection(perl: perl)
		for (k, v) in self {
			c[k as! String] = v.toUnsafeSvPointer(perl: perl)
		}
		return perl.pointee.newRV(noinc: hv)
	}
}
