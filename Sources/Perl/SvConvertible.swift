public protocol PerlSvConvertible {
	static func fromUnsafeSvPointer(inc: UnsafeSvPointer, perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) throws -> Self
	static func fromUnsafeSvPointer(copy: UnsafeSvPointer, perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) throws -> Self
	func toUnsafeSvPointer(perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current */) -> UnsafeSvPointer
}

extension PerlSvConvertible {
	public static func fromUnsafeSvPointer(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try Self.fromUnsafeSvPointer(inc: sv, perl: perl)
	}
}

extension Bool : PerlSvConvertible {
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> Bool { return Bool(sv, perl: perl) }
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension Int : PerlSvConvertible {
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Int { return try Int(sv, perl: perl) }
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension Double : PerlSvConvertible {
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Double { return try Double(sv, perl: perl) }
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension String : PerlSvConvertible {
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> String { return try String(sv, perl: perl) }
	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer { return perl.pointee.newSV(self) }
}

extension PerlScalar : PerlSvConvertible {
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> PerlScalar {
		return try PerlScalar(inc: sv, perl: perl)
	}

	public static func fromUnsafeSvPointer(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> PerlScalar {
		return try PerlScalar(copy: sv, perl: perl)
	}

	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, _ in sv.pointee.refcntInc() }
	}
}

extension PerlDerived where Self : PerlValue, UnsafeValue : UnsafeSvCastable {
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		guard let unsafe = try UnsafeMutablePointer<UnsafeValue>(autoDeref: sv, perl: perl) else { throw PerlError.unexpectedUndef(Perl.fromUnsafeSvPointer(inc: sv, perl: perl)) }
		return self.init(inc: unsafe, perl: perl)
	}

	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, perl in perl.pointee.newRV(inc: sv) }
	}
}

extension PerlBridgedObject {
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
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
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try _fromUnsafeSvPointerNonFinalClassWorkaround(inc: sv, perl: perl)
	}

	public static func fromUnsafeSvPointer(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try _fromUnsafeSvPointerNonFinalClassWorkaround(copy: sv, perl: perl)
	}

	public func toUnsafeSvPointer(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) -> UnsafeSvPointer {
		return withUnsafeSvPointer { sv, _ in sv.pointee.refcntInc() }
	}

	private static func _fromUnsafeSvPointerNonFinalClassWorkaround<T : PerlObject>(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		guard let classname = sv.pointee.classname(perl: perl) else {
			throw PerlError.notObject(Perl.fromUnsafeSvPointer(noinc: sv, perl: perl))
		}
		if let nc = T.self as? PerlNamedClass.Type, nc.perlClassName == classname {
			return T(noincUnchecked: sv, perl: perl)
		}
		let base = PerlObject.derivedClass(for: classname).init(noincUnchecked: sv, perl: perl)
		guard let obj = base as? T else {
			throw PerlError.unexpectedObjectType(Perl.fromUnsafeSvPointer(noinc: sv, perl: perl), want: self)
		}
		return obj
	}

	public static func _fromUnsafeSvPointerNonFinalClassWorkaround<T : PerlObject>(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		return try _fromUnsafeSvPointerNonFinalClassWorkaround(noinc: sv.pointee.refcntInc(), perl: perl)
	}

	public static func _fromUnsafeSvPointerNonFinalClassWorkaround<T : PerlObject>(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> T {
		let csv = perl.pointee.newSV()!
		perl.pointee.sv_setsv(csv, sv)
		return try _fromUnsafeSvPointerNonFinalClassWorkaround(noinc: csv, perl: perl)
	}
}

extension Optional where Wrapped : PerlSvConvertible {
	public static func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Optional<Wrapped> {
		return sv.pointee.defined ? try Wrapped.fromUnsafeSvPointer(inc: sv, perl: perl) : nil
	}

	public static func fromUnsafeSvPointer(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Optional<Wrapped> {
		return sv.pointee.defined ? try Wrapped.fromUnsafeSvPointer(copy: sv, perl: perl) : nil
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
