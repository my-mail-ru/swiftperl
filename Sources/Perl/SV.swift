/// Provides a safe wrapper for Perl scalar (`SV`).
/// Performs reference counting on initialization and deinitialization.
///
/// Can contain any scalar SV with `SvTYPE(sv) < SVt_PVAV` such as:
/// undefined values, integers (`IV`), numbers (`NV`), strings (`PV`),
/// references (`RV`), objects and others.
/// Objects as exception have their own type `PerlObject` which
/// provides more specific methods to work with them. Nevertheless
/// objects are compatible with and can be represented as `PerlSV`.
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
/// let int: PerlSV = 10
/// let str: PerlSV = "Строченька"
/// let intref = PerlSV(referenceTo: PerlSV(10))
/// let arrayref: PerlSV = [200, "OK"];
/// let hashref: PerlSV = ["type": "string", "value": 10]
/// ```
public final class PerlSV : PerlValue, PerlDerived {
	public typealias UnsafeValue = UnsafeSV

	/// Creates a `SV` containing an undefined value.
	public convenience init() { self.init(perl: UnsafeInterpreter.current) } // default bellow doesn't work...

	convenience init(copy sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(noinc: perl.pointee.newSV(sv), perl: perl)
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
		self.init(noincUnchecked: v.toUnsafeSvPointer(perl: perl), perl: perl)
	}

	/// Creates a `RV` pointing to a `sv`.
	public convenience init<T : PerlValue>(referenceTo sv: T) {
		let rv = sv.withUnsafeSvPointer { sv, perl in
			perl.pointee.newRV(inc: sv)!
		}
		self.init(noincUnchecked: rv, perl: sv.perl)
	}

	/// Creates a `RV` pointing to a `sv`.
	public convenience init<T : PerlValue>(_ sv: T) where T : PerlDerived, T.UnsafeValue : UnsafeSvCastable {
		self.init(referenceTo: sv)
	}

	/// Creates a `RV` pointing to a `AV` which contains `SV`s with elements of an `array`.
	public convenience init<T : PerlSvConvertible>(_ array: [T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: array.toUnsafeSvPointer(perl: perl), perl: perl)
	}

	/// Creates a `RV` pointing to a `HV` which contains `SV`s with elements of a `dict`.
	public convenience init<T : PerlSvConvertible>(_ dict: [String: T], perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.init(noincUnchecked: dict.toUnsafeSvPointer(perl: perl), perl: perl)
	}

	/// Creates a `SV` containig an unwrapped value of a `v` if `v != nil` or an `undef` in other case.
	public convenience init<T : PerlSvConvertible>(_ v: T?, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		if let v = v {
			self.init(v, perl: perl)
		} else {
			self.init(perl: perl)
		}
	}

	/// A boolean value indicating whether the `SV` is defined.
	public var defined: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.defined }
	}

	/// A boolean value indicating whether the `SV` contains an integer.
	public var isInt: Bool {
		return withUnsafeSvPointer { sv, _ in sv.pointee.isInt }
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

	/// A textual representation of the SV, suitable for debugging.
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
	/// Creates an instance which contains `undef`.
	///
	/// Do not call this initializer directly. It is used by the compiler when
	/// you initialize an `PerlSV` instance with a `nil` literal. For example:
	///
	/// ```swift
	/// let sv: PerlSV = nil
	/// ```
	public convenience init(nilLiteral: ()) {
		self.init()
	}
}

extension PerlSV: ExpressibleByBooleanLiteral {
	/// Creates an instance initialized to the specified boolean literal.
	///
	/// Do not call this initializer directly. It is used by the compiler when
	/// you use a boolean literal. Instead, create a new `PerlSV` instance by
	/// using one of the boolean literals `true` and `false`.
	///
	/// ```swift
	/// let sv: PerlSV = true
	/// ```
	///
	/// - Parameter value: The value of the new instance.
	public convenience init(booleanLiteral value: Bool) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByIntegerLiteral {
	/// Creates an instance from the given integer literal.
	///
	/// Do not call this initializer directly. It is used by the compiler when
	/// you create a new `PerlSV` instance by using an integer literal.
	/// Instead, create a new value by using a literal:
	///
	/// ```swift
	/// let x: PerlSV = 100
	/// ```
	///
	/// - Parameter value: The new value.
	public convenience init(integerLiteral value: Int) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByUnicodeScalarLiteral {
	/// Creates an instance initialized to the given Unicode scalar value.
	///
	/// Don't call this initializer directly. It may be used by the compiler when
	/// you initialize a `PerlSV` using a string literal that contains a single
	/// Unicode scalar value.
	public convenience init(unicodeScalarLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByExtendedGraphemeClusterLiteral {
	/// Creates an instance initialized to the given extended grapheme cluster
	/// literal.
	///
	/// Don't call this initializer directly. It may be used by the compiler when
	/// you initialize a `PerlSV` using a string literal containing a single
	/// extended grapheme cluster.
	public convenience init(extendedGraphemeClusterLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV : ExpressibleByStringLiteral {
	/// Creates an instance initialized to the given string value.
	///
	/// Don't call this initializer directly. It is used by the compiler when you
	/// initialize a `PerlSV` using a string literal. For example:
	///
	/// ```swift
	/// let sv: PerlSV = "My World"
	/// ```
	///
	/// This assignment to the `sv` calls this string literal
	/// initializer behind the scenes.
	public convenience init(stringLiteral value: String) {
		self.init(value)
	}
}

extension PerlSV: ExpressibleByArrayLiteral {
	/// Creates a reference to array from the given array literal.
	///
	/// Do not call this initializer directly. It is used by the compiler
	/// when you use an array literal. Instead, create a new `PerlSV` by using an
	/// array literal as its value. To do this, enclose a comma-separated list of
	/// values in square brackets. For example:
	///
	///	```swift
	/// let mix: PerlSV = [nil, 100, "use perl or die"]
	/// ```
	///
	/// - Parameter elements: A variadic list of elements of the new array.
	public convenience init (arrayLiteral elements: PerlSV...) {
		self.init(PerlAV(elements))
	}
}

extension PerlSV : ExpressibleByDictionaryLiteral {
	/// Creates a reference to hash initialized with a dictionary literal.
	///
	/// Do not call this initializer directly. It is called by the compiler to
	/// handle dictionary literals. To use a dictionary literal as the initial
	/// value of a `PerlSV`, enclose a comma-separated list of key-value pairs
	/// in square brackets. For example:
	///
	/// ```swift
	/// let header: PerlSV = [
	///		"Content-Length": 320,
	///		"Content-Type": "application/json",
	/// ]
	/// ```
	///
	/// - Parameter elements: The key-value pairs that will make up the new
	///   dictionary. Each key in `elements` must be unique.
	public convenience init(dictionaryLiteral elements: (String, PerlSV)...) {
		self.init(PerlHV(elements))
	}
}

extension Bool {
	/// Creates a boolean from `PerlSV` using Perl macros `SvTRUE`.
	///
	/// False in Perl is any value that would look like `""` or `"0"` if evaluated
	/// in a string context. Since undefined values evaluate to `""`, all undefined
	/// values are false, but not all false values are undefined.
	///
	/// ```swift
	/// let b = Bool(PerlSV())        // b == false
	/// let b = Bool(PerlSV(0))       // b == false
	/// let b = Bool(PerlSV(""))      // b == false
	/// let b = Bool(PerlSV("0"))     // b == false
	/// let b = Bool(PerlSV(1))       // b == true
	/// let b = Bool(PerlSV(100))     // b == true
	/// let b = Bool(PerlSV("100"))   // b == true
	/// let b = Bool(PerlSV("000"))   // b == true
	/// let b = Bool(PerlSV("any"))   // b == true
	/// let b = Bool(PerlSV("false")) // b == true
	///	```
	public init(_ sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(usv, perl: perl)
	}
}

extension Int {
	// TODO think about throwing if !looks_like_number()
	/// Creates an integer from `PerlSV` using Perl macros `SvIV`.
	/// Throws if `sv` contains `undef`.
	///
	/// ```swift
	/// let i = Int(PerlSV(100))      // i == 100
	/// let i = Int(PerlSV("100"))    // i == 100
	/// let i = Int(PerlSV(""))       // i == 0
	/// let i = Int(PerlSV("string")) // i == 0
	/// ```
	public init(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	// TODO think about throwing if !looks_like_number()
	/// Creates an integer from `PerlSV` using Perl macros `SvIV`.
	/// Returns `nil` if `sv` contains `undef`.
	///
	/// ```swift
	/// let i = Int(nilable: PerlSV(100))   // i == .some(100)
	/// let i = Int(nilable: PerlSV("100")) // i == .some(100)
	/// let i = Int(nilable: PerlSV())      // i == nil
	/// ```
	public init?(nilable sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(nilable: usv, perl: perl)
	}

	/// Creates an integer from `PerlSV` using Perl macros `SvIV`.
	/// Performs no additional checks.
	///
	/// ```swift
	/// let i = Int(unchecked: PerlSV(100))        // i == 100
	/// let i = Int(unchecked: PerlSV("100"))      // i == 100
	/// let i = Int(unchecked: PerlSV())           // i == 0
	/// let i = Int(unchecked: PerlSV(""))         // i == 0
	/// let i = Int(unchecked: PerlSV("100picot")) // i == 100
	/// let i = Int(unchecked: PerlSV("picot"))    // i == 0
	/// ```
	public init(unchecked sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}

extension String {
	// TODO think about throwing if it's RV
	/// Creates a string from `PerlSV` using Perl macros `SvPV`.
	/// Throws if `sv` contains `undef`.
	///
	/// ```swift
	/// let s = String(PerlSV())     // throws
	/// let s = String(PerlSV(200))  // s == "200"
	/// let s = String(PerlSV("OK")) // s == "OK"
	/// ```
	public init(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		try self.init(usv, perl: perl)
	}

	// TODO think about throwing if it's RV
	/// Creates a string from `PerlSV` using Perl macros `SvPV`.
	/// Returns `nil` if `sv` contains `undef`.
	///
	/// ```swift
	/// let s = String(PerlSV())     // s == nil
	/// let s = String(PerlSV(200))  // s == .some("200")
	/// let s = String(PerlSV("OK")) // s == .some("OK")
	/// ```
	public init?(nilable sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(nilable: usv, perl: perl)
	}

	/// Creates a string from `PerlSV` using Perl macros `SvPV`.
	/// Performs no additional checks.
	///
	/// ```swift
	/// let s = String(PerlSV())     // s == ""
	/// let s = String(PerlSV(200))  // s == "200"
	/// let s = String(PerlSV("OK")) // s == "OK"
	/// ```
	public init(unchecked sv: PerlSV) {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		self.init(unchecked: usv, perl: perl)
	}
}
