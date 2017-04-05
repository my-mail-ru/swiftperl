import CPerl

/// Provides a safe wrapper for Perl scalar (`SV`).
/// Performs reference counting on initialization and deinitialization.
///
/// Can contain any scalar SV with `SvTYPE(sv) < SVt_PVAV` such as:
/// undefined values, integers (`IV`), numbers (`NV`), strings (`PV`),
/// references (`RV`), objects and others.
/// Objects as exception have their own type `PerlObject` which
/// provides more specific methods to work with them. Nevertheless
/// objects are compatible with and can be represented as `PerlScalar`.
///
/// ## Cheat Sheet
///
/// ### Creation of various scalars
///
/// ```perl
/// my $int = 10;
/// my $str = "Строченька";
/// my $intref = \10;
/// my $arrayref = [200, "OK"];
/// my $hashref = { type => "string", value => 10 };
/// ```
///
/// ```swift
/// let int: PerlScalar = 10
/// let str: PerlScalar = "Строченька"
/// let intref = PerlScalar(referenceTo: PerlScalar(10))
/// let arrayref: PerlScalar = [200, "OK"];
/// let hashref: PerlScalar = ["type": "string", "value": 10]
/// ```
public final class PerlScalar : PerlValue, PerlDerived {
	public typealias UnsafeValue = UnsafeSV

	/// Creates a `SV` containing an undefined value.
	public convenience init() { self.init(perl: UnsafeInterpreter.current) } // default bellow doesn't work...

	convenience init(copyUnchecked sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) {
		self.init(noincUnchecked: perl.pointee.newSV(stealing: sv), perl: perl)
	}

	convenience init(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		guard sv.pointee.type == UnsafeValue.type else {
			throw PerlError.unexpectedSvType(fromUnsafeSvPointer(inc: sv, perl: perl), want: UnsafeValue.type)
		}
		self.init(copyUnchecked: sv, perl: perl)
	}

	/// Creates a `SV` containing an undefined value.
	public convenience init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: perl.pointee.newSV(), perl: perl)
	}

	convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(_noinc: sv, perl: perl)
	}

	/// Creates a `SV` containig a `v`.
	public convenience init<T : PerlSvConvertible>(_ v: T, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: v._toUnsafeSvPointer(perl: perl), perl: perl)
	}

	/// Semantics of a Perl string data.
	public enum StringUnits {
		/// A string contains bytes (octets) and interpreted as a binary buffer.
		case bytes
		/// A string contains characters and interpreted as a text.
		case characters
	}

	/// Creates a Perl string containing a copy of bytes or characters from `v`.
	public convenience init(_ v: UnsafeRawBufferPointer, containing: StringUnits = .bytes, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: perl.pointee.newSV(v, utf8: containing == .characters), perl: perl)
	}

	/// Creates a new SV which is an exact duplicate of the original SV.
	public convenience init(copy scalar: PerlScalar) {
		let sv = scalar.withUnsafeSvPointer { sv, perl in perl.pointee.newSVsv(sv)! }
		self.init(noincUnchecked: sv, perl: scalar.perl)
	}

	/// Creates a `RV` pointing to a `sv`.
	public convenience init<T : PerlValue>(referenceTo sv: T) {
		let rv = sv.withUnsafeSvPointer { sv, perl in
			perl.pointee.newRV_inc(sv)!
		}
		self.init(noincUnchecked: rv, perl: sv.perl)
	}

	/// Creates a `RV` pointing to a `sv`.
	public convenience init<T : PerlValue>(_ sv: T) where T : PerlDerived, T.UnsafeValue : UnsafeSvCastable {
		self.init(referenceTo: sv)
	}

	/// Creates a `RV` pointing to a `AV` which contains `SV`s with elements of an `array`.
	public convenience init<T : PerlSvConvertible>(_ array: [T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: array._toUnsafeSvPointer(perl: perl), perl: perl)
	}

	/// Creates a `RV` pointing to a `HV` which contains `SV`s with elements of a `dict`.
	public convenience init<T : PerlSvConvertible>(_ dict: [String: T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: dict._toUnsafeSvPointer(perl: perl), perl: perl)
	}

	/// Creates a `SV` containig an unwrapped value of a `v` if `v != nil` or an `undef` in other case.
	public convenience init<T : PerlSvConvertible>(_ v: T?, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		if let v = v {
			self.init(v, perl: perl)
		} else {
			self.init(perl: perl)
		}
	}

	/// Returns the specified Perl global or package scalar with the given name (so it won't work on lexical variables).
	/// If the variable does not exist then `nil` is returned.
	public convenience init?(get name: String, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		guard let sv = perl.pointee.getSV(name) else { return nil }
		self.init(incUnchecked: sv, perl: perl)
	}

	/// Returns the specified Perl global or package scalar with the given name (so it won't work on lexical variables).
	/// If the variable does not exist then it will be created.
	public convenience init(getCreating name: String, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		let sv = perl.pointee.getSV(name, flags: GV_ADD)!
		self.init(incUnchecked: sv, perl: perl)
	}

	/// A boolean value indicating whether the `SV` is defined.
	public var defined: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.defined }
	}

	/// A boolean value indicating whether the `SV` contains an integer (signed or unsigned).
	public var isInteger: Bool {
		return withUnsafeSvPointer { sv, _ in SvIOK(sv) }
	}

	@available(*, deprecated, renamed: "isInteger")
	public var isInt: Bool { return isInteger }

	/// A boolean value indicating whether the `SV` contains a double.
	public var isDouble: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isDouble }
	}

	/// A boolean value indicating whether the `SV` contains a character string.
	public var isString: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isString }
	}

	/// A boolean value indicating whether the `SV` is a reference.
	public var isRef: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isRef }
	}

	/// A boolean value indicating whether the `SV` is an object.
	public var isObject: Bool {
		return withUnsafeSvPointer { sv, perl in sv.pointee.isObject(perl: perl) }
	}

	/// Dereferences the `SV` if it is a reference. Returns `nil` if not.
	public var referent: AnyPerl? {
		return withUnsafeSvPointer { rv, perl in
			guard let sv = rv.pointee.referent else { return nil }
			return fromUnsafeSvPointer(inc: sv, perl: perl)
		}
	}

	/// Calls the closure with `UnsafeRawBufferPointer` to the string in the SV,
	/// or a stringified form of the SV if the SV does not contain a string.
	public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
		return try withUnsafeSvPointer { sv, perl in try sv.pointee.withUnsafeBytes(perl: perl, body: body)}
	}

	/// Evaluates the given closure when this `PerlScalar` instance is defined,
	/// passing `self` as a parameter.
	///
	/// Use the `map` method with a closure that returns a nonoptional value.
	///
	/// - Parameter transform: A closure that takes `self`.
	/// - Returns: The result of the given closure. If this instance is undefined,
	///   returns `nil`.
	public func map<R>(_ transform: (PerlScalar) throws -> R) rethrows -> R? {
		return defined ? try transform(self) : nil
	}

	/// Evaluates the given closure when this `PerlScalar` instance is defined,
	/// passing `self` as a parameter.
	///
	/// Use the `flatMap` method with a closure that returns an optional value.
	///
	/// - Parameter transform: A closure that takes `self`.
	/// - Returns: The result of the given closure. If this instance is undefined,
	///   returns `nil`.
	public func flatMap<R>(_ transform: (PerlScalar) throws -> R?) rethrows -> R? {
		return defined ? try transform(self) : nil
	}

	/// Performs an undef-coalescing operation, returning `self` when it is defined,
	/// or a default value.
	public static func ??(scalar: PerlScalar, defaultValue: @autoclosure () throws -> PerlScalar) rethrows -> PerlScalar {
		return scalar.defined ? scalar : try defaultValue()
	}

	/// Copies the contents of the source SV `value` into the destination SV `self`.
	/// Does not handle 'set' magic on destination SV. Calls 'get' magic on source SV.
	/// Loosely speaking, it performs a copy-by-value, obliterating any previous content of the destination.
	public func set(_ value: PerlScalar) {
		value.withUnsafeSvPointer { ssv, _ in
			withUnsafeSvPointer { dsv, perl in
				perl.pointee.sv_setsv(dsv, ssv)
			}
		}
	}

	/// Copies a boolean into `self`.
	/// Does not handle 'set' magic.
	public func set(_ value: Bool) {
		withUnsafeSvPointer { sv, perl in perl.pointee.sv_setsv(sv, perl.pointee.boolSV(value)) }
	}

	/// Copies a signed integer into `self`, upgrading first if necessary.
	/// Does not handle 'set' magic.
	public func set(_ value: Int) {
		withUnsafeSvPointer { sv, perl in perl.pointee.sv_setiv(sv, value) }
	}

	/// Copies an unsigned integer into `self`, upgrading first if necessary.
	/// Does not handle 'set' magic.
	public func set(_ value: UInt) {
		withUnsafeSvPointer { sv, perl in perl.pointee.sv_setuv(sv, value) }
	}

	/// Copies a double into `self`, upgrading first if necessary.
	/// Does not handle 'set' magic.
	public func set(_ value: Double) {
		withUnsafeSvPointer { sv, perl in perl.pointee.sv_setnv(sv, value) }
	}

	/// Copies a string (possibly containing embedded `NUL` characters) into `self`.
	/// Does not handle 'set' magic.
	public func set(_ value: String) {
		withUnsafeSvPointer { sv, perl in
			value.withCStringWithLength { perl.pointee.sv_setpvn(sv, $0, $1) }
			if value._core.isASCII {
				SvUTF8_off(sv)
			} else {
				SvUTF8_on(sv)
			}
		}
	}

	/// Copies bytes or characters from `value` into `self`.
	/// Does not handle 'set' magic.
	public func set(_ value: UnsafeRawBufferPointer, containing: StringUnits = .bytes) {
		withUnsafeSvPointer { sv, perl in
			SvUTF8_off(sv)
			perl.pointee.sv_setpvn(sv, value.baseAddress?.assumingMemoryBound(to: CChar.self), value.count)
			if containing == .characters {
				perl.pointee.sv_utf8_decode(sv)
			}
		}
	}

	/// Dumps the contents of the underlying SV to the "STDERR" filehandle.
	public func dump() {
		withUnsafeSvPointer { sv, perl in perl.pointee.sv_dump(sv) }
	}

	/// A textual representation of the SV, suitable for debugging.
	public override var debugDescription: String {
		var values = [String]()
		if defined {
			if isInteger {
				if withUnsafeSvPointer({ sv, _ in SvIsUV(sv) }) {
					values.append("uv: \(UInt(unchecked: self))")
				} else {
					values.append("iv: \(Int(unchecked: self))")
				}
			}
			if isDouble {
				values.append("nv: \(Double(unchecked: self).debugDescription)")
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
		return "PerlScalar(\(values.joined(separator: ", ")))"
	}

	func withReferentUnsafeSvPointer<R>(type: SvType, body: (UnsafeSvPointer, UnsafeInterpreterPointer) throws -> R) throws -> R {
		return try withUnsafeSvPointer { rv, perl in
			guard let sv = rv.pointee.referent else {
				throw PerlError.notReference(fromUnsafeSvPointer(inc: rv, perl: perl))
			}
			guard sv.pointee.type == type else {
				throw PerlError.unexpectedSvType(fromUnsafeSvPointer(inc: sv, perl: perl), want: type)
			}
			return try body(sv, perl)
		}
	}
}

extension PerlScalar : Equatable, Hashable {
	/// The hash value of the stringified form of the scalar.
	///
	/// Hash values are not guaranteed to be equal across different executions of
	/// your program. Do not save hash values to use during a future execution.
	public var hashValue: Int {
		return withUnsafeSvPointer { sv, perl in Int(perl.pointee.SvHASH(sv)) }
	}

	/// Returns a Boolean value indicating whether two scalars stringify to identical strings.
	public static func == (lhs: PerlScalar, rhs: PerlScalar) -> Bool {
		return rhs.withUnsafeSvPointer { sv2, _ in
			lhs.withUnsafeSvPointer { sv1, perl in
				perl.pointee.sv_eq(sv1, sv2)
			}
		}
	}
}

extension PerlScalar : ExpressibleByNilLiteral {
	/// Creates an instance which contains `undef`.
	///
	/// Do not call this initializer directly. It is used by the compiler when
	/// you initialize an `PerlScalar` instance with a `nil` literal. For example:
	///
	/// ```swift
	/// let sv: PerlScalar = nil
	/// ```
	public convenience init(nilLiteral: ()) {
		self.init()
	}
}

extension PerlScalar: ExpressibleByBooleanLiteral {
	/// Creates an instance initialized to the specified boolean literal.
	///
	/// Do not call this initializer directly. It is used by the compiler when
	/// you use a boolean literal. Instead, create a new `PerlScalar` instance by
	/// using one of the boolean literals `true` and `false`.
	///
	/// ```swift
	/// let sv: PerlScalar = true
	/// ```
	///
	/// - Parameter value: The value of the new instance.
	public convenience init(booleanLiteral value: Bool) {
		self.init(value)
	}
}

extension PerlScalar : ExpressibleByIntegerLiteral {
	/// Creates an instance from the given integer literal.
	///
	/// Do not call this initializer directly. It is used by the compiler when
	/// you create a new `PerlScalar` instance by using an integer literal.
	/// Instead, create a new value by using a literal:
	///
	/// ```swift
	/// let x: PerlScalar = 100
	/// ```
	///
	/// - Parameter value: The new value.
	public convenience init(integerLiteral value: Int) {
		self.init(value)
	}
}

extension PerlScalar : ExpressibleByFloatLiteral {
	/// Creates an instance from the given floating-point literal.
	///
	/// Do not call this initializer directly. It is used by the compiler when
	/// you create a new `PerlScalar` instance by using a floating-point literal.
	/// Instead, create a new value by using a literal:
	///
	/// ```swift
	/// let x: PerlScalar = 1.1
	/// ```
	///
	/// - Parameter value: The new value.
	public convenience init(floatLiteral value: Double) {
		self.init(value)
	}
}

extension PerlScalar : ExpressibleByUnicodeScalarLiteral {
	/// Creates an instance initialized to the given Unicode scalar value.
	///
	/// Don't call this initializer directly. It may be used by the compiler when
	/// you initialize a `PerlScalar` using a string literal that contains a single
	/// Unicode scalar value.
	public convenience init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
}

extension PerlScalar : ExpressibleByExtendedGraphemeClusterLiteral {
	/// Creates an instance initialized to the given extended grapheme cluster
	/// literal.
	///
	/// Don't call this initializer directly. It may be used by the compiler when
	/// you initialize a `PerlScalar` using a string literal containing a single
	/// extended grapheme cluster.
	public convenience init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
}

extension PerlScalar : ExpressibleByStringLiteral {
	/// Creates an instance initialized to the given string value.
	///
	/// Don't call this initializer directly. It is used by the compiler when you
	/// initialize a `PerlScalar` using a string literal. For example:
	///
	/// ```swift
	/// let sv: PerlScalar = "My World"
	/// ```
	///
	/// This assignment to the `sv` calls this string literal
	/// initializer behind the scenes.
	public convenience init(stringLiteral value: String) {
		self.init(value)
	}
}

extension PerlScalar: ExpressibleByArrayLiteral {
	/// Creates a reference to array from the given array literal.
	///
	/// Do not call this initializer directly. It is used by the compiler
	/// when you use an array literal. Instead, create a new `PerlScalar` by using an
	/// array literal as its value. To do this, enclose a comma-separated list of
	/// values in square brackets. For example:
	///
	///	```swift
	/// let mix: PerlScalar = [nil, 100, "use perl or die"]
	/// ```
	///
	/// - Parameter elements: A variadic list of elements of the new array.
	public convenience init (arrayLiteral elements: PerlScalar...) {
		self.init(PerlArray(elements))
	}
}

extension PerlScalar : ExpressibleByDictionaryLiteral {
	/// Creates a reference to hash initialized with a dictionary literal.
	///
	/// Do not call this initializer directly. It is called by the compiler to
	/// handle dictionary literals. To use a dictionary literal as the initial
	/// value of a `PerlScalar`, enclose a comma-separated list of key-value pairs
	/// in square brackets. For example:
	///
	/// ```swift
	/// let header: PerlScalar = [
	///		"Content-Length": 320,
	///		"Content-Type": "application/json",
	/// ]
	/// ```
	///
	/// - Parameter elements: The key-value pairs that will make up the new
	///   dictionary. Each key in `elements` must be unique.
	public convenience init(dictionaryLiteral elements: (String, PerlScalar)...) {
		self.init(PerlHash(elements))
	}
}

extension Bool {
	/// Creates a boolean from `PerlScalar` using Perl macros `SvTRUE`.
	///
	/// False in Perl is any value that would look like `""` or `"0"` if evaluated
	/// in a string context. Since undefined values evaluate to `""`, all undefined
	/// values are false, but not all false values are undefined.
	///
	/// ```swift
	/// let b = Bool(PerlScalar())        // b == false
	/// let b = Bool(PerlScalar(0))       // b == false
	/// let b = Bool(PerlScalar(""))      // b == false
	/// let b = Bool(PerlScalar("0"))     // b == false
	/// let b = Bool(PerlScalar(1))       // b == true
	/// let b = Bool(PerlScalar(100))     // b == true
	/// let b = Bool(PerlScalar("100"))   // b == true
	/// let b = Bool(PerlScalar("000"))   // b == true
	/// let b = Bool(PerlScalar("any"))   // b == true
	/// let b = Bool(PerlScalar("false")) // b == true
	///	```
	public init(_ sv: PerlScalar) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(usv, perl: perl)
	}
}

extension Int {
	/// Creates a signed integer from `PerlScalar`.
	/// Throws if `sv` does not contain a signed integer.
	///
	/// ```swift
	/// let i = try Int(PerlScalar(100))                     // i == 100
	/// let i = try Int(PerlScalar("100"))                   // i == 100
	/// let i = try Int(PerlScalar(42.5))                    // i == 42
	/// let i = try Int(PerlScalar())                        // throws
	/// let i = try Int(PerlScalar(""))                      // throws
	/// let i = try Int(PerlScalar("any"))                   // throws
	/// let i = try Int(PerlScalar("50sec"))                 // throws
	/// let i = try Int(PerlScalar("10000000000000000000"))  // throws
	/// let i = try Int(PerlScalar("20000000000000000000"))  // throws
	/// let i = try Int(PerlScalar("-10"))                   // i == -10
	/// let i = try Int(PerlScalar("-20000000000000000000")) // throws
	/// ```
	public init(_ sv: PerlScalar) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	/// Creates a signed integer from `PerlScalar` using Perl macros `SvIV`.
	/// Performs no additional checks.
	///
	/// ```swift
	/// let i = Int(unchecked: PerlScalar(100))                       // i == 100
	/// let i = Int(unchecked: PerlScalar("100"))                     // i == 100
	/// let i = Int(unchecked: PerlScalar(42.5))                      // i == 42
	/// let i = Int(unchecked: PerlScalar())                          // i == 0
	/// let i = Int(unchecked: PerlScalar(""))                        // i == 0
	/// let i = Int(unchecked: PerlScalar("any"))                     // i == 0
	/// let i = Int(unchecked: PerlScalar("50sec"))                   // i == 50
	/// let i = Int(unchecked: PerlScalar("10000000000000000000"))    // i == Int(bitPattern: 10000000000000000000)
	/// let i = Int(unchecked: PerlScalar("20000000000000000000"))    // i == Int(bitPattern: UInt.max)
	/// let i = Int(unchecked: PerlScalar("-10"))                     // i == -10
	/// let i = Int(unchecked: PerlScalar("-20000000000000000000"))   // i == Int.min
	/// ```
	public init(unchecked sv: PerlScalar) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}

extension UInt {
	/// Creates an unsigned integer from `PerlScalar`.
	/// Throws if `sv` does not contain an unsigned integer.
	///
	/// ```swift
	/// let u = try UInt(PerlScalar(100))                       // u == 100
	/// let u = try UInt(PerlScalar("100"))                     // u == 100
	/// let u = try UInt(PerlScalar(42.5))                      // u == 42
	/// let u = try UInt(PerlScalar())                          // throws
	/// let u = try UInt(PerlScalar(""))                        // throws
	/// let u = try UInt(PerlScalar("any"))                     // throws
	/// let u = try UInt(PerlScalar("50sec"))                   // throws
	/// let u = try UInt(PerlScalar("10000000000000000000"))    // u == 10000000000000000000
	/// let u = try UInt(PerlScalar("20000000000000000000"))    // throws
	/// let u = try UInt(PerlScalar("-10"))                     // throws
	/// let u = try UInt(PerlScalar("-20000000000000000000"))   // throws
	/// ```
	public init(_ sv: PerlScalar) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	/// Creates an unsigned integer from `PerlScalar` using Perl macros `SvUV`.
	/// Performs no additional checks.
	///
	/// ```swift
	/// let u = UInt(unchecked: PerlScalar(100))        // u == 100
	/// let u = UInt(unchecked: PerlScalar("100"))      // u == 100
	/// let u = UInt(unchecked: PerlScalar(42.5))       // u == 42
	/// let u = UInt(unchecked: PerlScalar())           // u == 0
	/// let u = UInt(unchecked: PerlScalar(""))         // u == 0
	/// let u = UInt(unchecked: PerlScalar("any"))      // u == 0
	/// let u = UInt(unchecked: PerlScalar("50sec"))    // u == 50
	/// let u = UInt(unchecked: PerlScalar("10000000000000000000"))    // u == 10000000000000000000
	/// let u = UInt(unchecked: PerlScalar("20000000000000000000"))    // u == UInt.max
	/// let u = UInt(unchecked: PerlScalar("-10"))                     // u == UInt(bitPattern: -10)
	/// let u = UInt(unchecked: PerlScalar("-20000000000000000000"))   // u == UInt(bitPattern: Int.min)
	/// ```
	public init(unchecked sv: PerlScalar) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}

extension Double {
	/// Creates a double from `PerlScalar`.
	/// Throws if `sv` contains something that not looks like a number.
	///
	/// ```swift
	/// let i = try Double(PerlScalar(42.3))     // i == 42.3
	/// let i = try Double(PerlScalar("42.3"))   // i == 42.3
	/// let i = try Double(PerlScalar())         // throws
	/// let i = try Double(PerlScalar(""))       // throws
	/// let i = try Double(PerlScalar("any"))    // throws
	/// let i = try Double(PerlScalar("50sec"))  // throws
	/// ```
	public init(_ sv: PerlScalar) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	/// Creates a double from `PerlScalar` using Perl macros `SvNV`.
	/// Performs no additional checks.
	///
	/// ```swift
	/// let i = Double(unchecked: PerlScalar(42.3))        // i == 42.3
	/// let i = Double(unchecked: PerlScalar("42.3"))      // i == 42.3
	/// let i = Double(unchecked: PerlScalar())            // i == 0
	/// let i = Double(unchecked: PerlScalar(""))          // i == 0
	/// let i = Double(unchecked: PerlScalar("any"))       // i == 0
	/// let i = Double(unchecked: PerlScalar("50sec"))     // i == 50
	/// let i = Double(unchecked: PerlScalar("50.3sec"))   // i == 50.3
	/// ```
	public init(unchecked sv: PerlScalar) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}

extension String {
	/// Creates a string from `PerlScalar`.
	/// Throws if `sv` does not contain a string or a number.
	///
	/// ```swift
	/// let s = try String(PerlScalar())                             // throws
	/// let s = try String(PerlScalar(200))                          // s == "200"
	/// let s = try String(PerlScalar("OK"))                         // s == "OK"
	/// let s = try String(PerlScalar(referenceTo: PerlScalar(10)))  // throws
	/// ```
	public init(_ sv: PerlScalar) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	/// Creates a string from `PerlScalar` using Perl macros `SvPV`.
	/// Performs no additional checks.
	///
	/// ```swift
	/// let s = String(PerlScalar())                             // s == ""
	/// let s = String(PerlScalar(200))                          // s == "200"
	/// let s = String(PerlScalar("OK"))                         // s == "OK"
	/// let s = String(PerlScalar(referenceTo: PerlScalar(10)))  // s == "SCALAR(0x12345678)"
	/// ```
	public init(unchecked sv: PerlScalar) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}
