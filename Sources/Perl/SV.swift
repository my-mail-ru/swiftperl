final class PerlSV : PerlValue, PerlDerived {
	typealias UnsafeValue = UnsafeSV

	convenience init() { self.init(perl: UnsafeInterpreter.current) } // default bellow doesn't work...

	convenience init(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(noinc: perl.pointee.newSV(sv), perl: perl)
	}

	convenience init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: perl.pointee.newSV(), perl: perl)
	}

	convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(_noinc: sv, perl: perl)
	}

	convenience init<T : PerlSVConvertible>(_ v: T, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: v.promoteToUnsafeSV(perl: perl), perl: perl)
	}

	convenience init<T : PerlValue>(referenceTo sv: T) {
		let rv = sv.withUnsafeSvPointer { sv, perl in
			perl.pointee.newRV(inc: sv)!
		}
		self.init(noincUnchecked: rv, perl: sv.perl)
	}

	convenience init<T : PerlValue>(_ sv: T) where T : PerlDerived, T.UnsafeValue : UnsafeSvCastable {
		self.init(referenceTo: sv)
	}

	convenience init<T : PerlSVConvertible>(_ array: [T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: array.promoteToUnsafeSV(perl: perl), perl: perl)
	}

	convenience init<T : PerlSVConvertible>(_ dict: [String: T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: dict.promoteToUnsafeSV(perl: perl), perl: perl)
	}

	convenience init<T : PerlSVConvertible>(_ v: T?, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		if let v = v {
			self.init(v, perl: perl)
		} else {
			self.init(perl: perl)
		}
	}

	var defined: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.defined }
	}

	var isInt: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isInt }
	}

	var isString: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isString }
	}

	var isRef: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isRef }
	}

	var isObject: Bool {
		return withUnsafeSvPointer { sv, perl in sv.pointee.isObject(perl: perl) }
	}

	var referent: AnyPerl? {
		return withUnsafeSvPointer { rv, perl in
			guard let sv = rv.pointee.referent else { return nil }
			return promoteFromUnsafeSV(inc: sv, perl: perl)
		}
	}

	override var debugDescription: String {
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
	convenience init(nilLiteral: ()) {
		self.init()
	}
}

extension PerlSV: ExpressibleByBooleanLiteral {
	convenience init(booleanLiteral value: Bool) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByIntegerLiteral {
	convenience init(integerLiteral value: Int) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByUnicodeScalarLiteral {
	convenience init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByExtendedGraphemeClusterLiteral {
	convenience init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByStringLiteral {
	convenience init(stringLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV: ExpressibleByArrayLiteral {
	convenience init (arrayLiteral elements: PerlSV...) {
		self.init(PerlAV(elements))
	}
}

extension PerlSV : ExpressibleByDictionaryLiteral {
	convenience init(dictionaryLiteral elements: (String, PerlSV)...) {
		self.init(PerlHV(elements))
	}
}

extension Bool {
	init(_ sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(usv, perl: perl)
	}
}

extension Int {
	init(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	init?(nilable sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(nilable: usv, perl: perl)
	}

	init(unchecked sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}

extension String {
	init(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	init?(nilable sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(nilable: usv, perl: perl)
	}

	init(unchecked sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}
