public final class PerlSV : PerlValue, PerlDerived {
	public typealias UnsafeValue = UnsafeSV

	public convenience init() { self.init(perl: UnsafeInterpreter.current) } // default bellow doesn't work...

	convenience init(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(noinc: perl.pointee.newSV(sv), perl: perl)
	}

	public convenience init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: perl.pointee.newSV(), perl: perl)
	}

	convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(_noinc: sv, perl: perl)
	}

	public convenience init<T : PerlSvConvertible>(_ v: T, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: v.toUnsafeSvPointer(perl: perl), perl: perl)
	}

	public convenience init<T : PerlValue>(referenceTo sv: T) {
		let rv = sv.withUnsafeSvPointer { sv, perl in
			perl.pointee.newRV(inc: sv)!
		}
		self.init(noincUnchecked: rv, perl: sv.perl)
	}

	public convenience init<T : PerlValue>(_ sv: T) where T : PerlDerived, T.UnsafeValue : UnsafeSvCastable {
		self.init(referenceTo: sv)
	}

	public convenience init<T : PerlSvConvertible>(_ array: [T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: array.toUnsafeSvPointer(perl: perl), perl: perl)
	}

	public convenience init<T : PerlSvConvertible>(_ dict: [String: T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: dict.toUnsafeSvPointer(perl: perl), perl: perl)
	}

	public convenience init<T : PerlSvConvertible>(_ v: T?, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		if let v = v {
			self.init(v, perl: perl)
		} else {
			self.init(perl: perl)
		}
	}

	public var defined: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.defined }
	}

	public var isInt: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isInt }
	}

	public var isString: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isString }
	}

	public var isRef: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isRef }
	}

	public var isObject: Bool {
		return withUnsafeSvPointer { sv, perl in sv.pointee.isObject(perl: perl) }
	}

	public var referent: AnyPerl? {
		return withUnsafeSvPointer { rv, perl in
			guard let sv = rv.pointee.referent else { return nil }
			return fromUnsafeSvPointer(inc: sv, perl: perl)
		}
	}

	public override var debugDescription: String {
		var values = [String]()
		if defined {
			if isInt {
				values.append("iv: \(Int(unchecked: self))")
			}
			if isString {
				values.append("pv: \(String(unchecked: self).debugDescription)")
			}
			if let ref = referent {
				var str = "rv: "
				debugPrint(ref, terminator: "", to: &str)
				values.append(str)
			}
		} else {
			values.append("undef")
		}
		return "PerlSV(\(values.joined(separator: ", ")))"
	}
}

extension PerlSV : ExpressibleByNilLiteral {
	public convenience init(nilLiteral: ()) {
		self.init()
	}
}

extension PerlSV: ExpressibleByBooleanLiteral {
	public convenience init(booleanLiteral value: Bool) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByIntegerLiteral {
	public convenience init(integerLiteral value: Int) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByUnicodeScalarLiteral {
	public convenience init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByExtendedGraphemeClusterLiteral {
	public convenience init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByStringLiteral {
	public convenience init(stringLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV: ExpressibleByArrayLiteral {
	public convenience init (arrayLiteral elements: PerlSV...) {
		self.init(PerlAV(elements))
	}
}

extension PerlSV : ExpressibleByDictionaryLiteral {
	public convenience init(dictionaryLiteral elements: (String, PerlSV)...) {
		self.init(PerlHV(elements))
	}
}

extension Bool {
	public init(_ sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(usv, perl: perl)
	}
}

extension Int {
	public init(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	public init?(nilable sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(nilable: usv, perl: perl)
	}

	public init(unchecked sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}

extension String {
	public init(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	public init?(nilable sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(nilable: usv, perl: perl)
	}

	public init(unchecked sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}
