/// Provides a safe wrapper for Perl hash (`HV`).
/// Performs reference counting on initialization and deinitialization.
///
/// ## Cheat Sheet
///
/// ### Creating of a hash
///
/// ```perl
/// my %hash = (
///		id => 42,
///		name => "Иван",
///		aliases => ["Ваня", "John"],
/// );
/// ```
///
/// ```swift
/// let hash: PerlHV = [
///		"id": 42,
///		"name": "Иван",
///		"aliases": ["Ваня", "John"],
/// ]
/// ```
///
/// ### Accessing a hash
///
/// ```perl
/// $hash{age} = 10;
/// my $age = $hash{age};
/// delete $hash{age};
/// my $has_age = exists $hash{age};
/// $hash{age} = undef;
/// ```
///
/// ```swift
/// hash["age"] = 10
/// let age = hash["age"] ?? PerlSV()
/// hash["age"] = nil
/// let hasAge = hash["age"] != nil
/// hash["age"] = PerlSV()
/// ```
///
/// The difference between Perl and Swift hash element access APIs is the result of
/// Swiftification. It was done to make subscript behavior match behavior of
/// subscripts in `Dictionary`. So, when a key does not exist subscript returns
/// `nil` not an undefined SV as a Perl programmer could expect.
public final class PerlHV : PerlValue, PerlDerived {
	public typealias UnsafeValue = UnsafeHV

	/// Creates an empty Perl hash.
	public convenience init() {
		self.init(perl: UnsafeInterpreter.current)
	}

	/// Creates an empty Perl hash.
	public convenience init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		let hv = perl.pointee.newHV()!
		self.init(noinc: hv, perl: perl)
	}

	convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(_noinc: sv, perl: perl)
	}

	/// Initializes a new Perl hash with elements of dictionary `dict`,
	/// recursively converting them to Perl scalars.
	///
	/// Values can be simple scalars:
	///
	/// ```swift
	/// let dict = ["one": 1, "two": 2, "three": 3]
	/// let hv = PerlHV(dict) // my %hv = (one => 1, two => 2, three => 3);
	/// ```
	///
	/// More then that arrays, dictionaries, references and objects are also possible:
	///
	/// ```swift
	/// let dict = ["odd": [1, 3], "even": [2, 4]]
	/// let hv = PerlHV(dict) // my %hv = (odd => [1, 3], even => [2, 4]);
	/// ```
	///
	/// - Parameter dict: a dictionary with `String` keys and values
	///   convertible to Perl scalars (conforming to `PerlSvConvertible`).
	public convenience init<T : PerlSvConvertible>(_ dict: [String: T]) {
		self.init()
		for (k, v) in dict {
			self[k] = v as? PerlSV ?? PerlSV(v)
		}
	}

	func withUnsafeHvPointer<R>(_ body: (UnsafeHvPointer, UnsafeInterpreterPointer) throws -> R) rethrows -> R {
		return try withUnsafeSvPointer { sv, perl in
			return try sv.withMemoryRebound(to: UnsafeHV.self, capacity: 1) {
				return try body($0, perl)
			}
		}
	}

	func withUnsafeCollection<R>(_ body: (UnsafeHvCollection) throws -> R) rethrows -> R {
		return try withUnsafeHvPointer {
			return try body($0.pointee.collection(perl: $1))
		}
	}

	/// A textual representation of the HV, suitable for debugging.
	public override var debugDescription: String {
		let values = map { "\($0.key.debugDescription): \($0.value.debugDescription)" } .joined(separator: ", ")
		return "PerlHV([\(values)])"
	}
}

extension PerlHV: Sequence, IteratorProtocol {
	public typealias Key = String
	public typealias Value = PerlSV
	public typealias Element = (key: Key, value: Value)

	/// Returns an iterator over the elements of this hash.
	///
	/// `PerlHV` conforms to `IteratorProtocol` itself. So a returned value
	/// is always `self`. Behind the scenes it calls Perl macro `hv_iterinit`
	/// and prepares a starting point to traverse the hash table.
	///
	/// - Returns: `self`
	/// - Attention: Only one iterator is possible at any time.
	/// - SeeAlso: `Sequence`
	public func makeIterator() -> PerlHV {
		withUnsafeCollection { _ = $0.makeIterator() }
		return self
	}

	/// Advances to the next element and returns it, or `nil` if no next element
	/// exists.
	///
	/// Once `nil` has been returned, all subsequent calls return `nil`.
	///
	/// - SeeAlso: `IteratorProtocol`
	public func next() -> Element? {
		return withUnsafeCollection {
			guard let u = $0.next() else { return nil }
			return (key: u.key, value: try! PerlSV(inc: u.value, perl: $0.perl))
		}
	}

	/// Accesses the value associated with the given key for reading and writing.
	///
	/// This *key-based* subscript returns the value for the given key if the key
	/// is found in the hash, or `nil` if the key is not found.
	///
	/// When you assign a value for a key and that key already exists, the
	/// hash overwrites the existing value. If the hash doesn't
	/// contain the key, the key and value are added as a new key-value pair.
	///
	/// If you assign `nil` as the value for the given key, the hash
	/// removes that key and its associated value.
	///
	/// - Parameter key: The key to find in the hash.
	/// - Returns: The value associated with `key` if `key` is in the hash;
	///   otherwise, `nil`.
	///
	/// - SeeAlso: `Dictionary`
	public subscript(key: Key) -> PerlSV? {
		get {
			return withUnsafeCollection {
				guard let sv = $0[key] else { return nil }
				return try! PerlSV(inc: sv, perl: $0.perl)
			}
		}
		set {
			withUnsafeCollection { c in
				if let value = newValue {
					value.withUnsafeSvPointer { sv, _ in
						_ = c.store(key, newValue: sv)?.pointee.refcntInc()
					}
				} else {
					c.delete(key)
				}
			}
		}
	}
}

extension PerlHV {
	public convenience init(_ dict: [Key: Value]) {
		self.init()
		for (k, v) in dict {
			self[k] = v
		}
	}

	public convenience init(_ elements: [(Key, Value)]) {
		self.init()
		for (k, v) in elements {
			self[k] = v
		}
	}
}

extension PerlHV : ExpressibleByDictionaryLiteral {
	/// Creates a Perl hash initialized with a dictionary literal.
	///
	/// Do not call this initializer directly. It is called by the compiler to
	/// handle dictionary literals. To use a dictionary literal as the initial
	/// value of a hash, enclose a comma-separated list of key-value pairs
	/// in square brackets. For example:
	///
	/// ```swift
	/// let header: PerlHV = [
	///     "Content-Length": 320,
	///     "Content-Type": "application/json"
	/// ]
	/// ```
	///
	/// - Parameter elements: The key-value pairs that will make up the new
	///   dictionary. Each key in `elements` must be unique.
	///
	/// - SeeAlso: `ExpressibleByDictionaryLiteral`
	public convenience init(dictionaryLiteral elements: (Key, Value)...) {
		self.init(elements)
	}
}

// where Key == String, but it is unsupported
extension Dictionary where Value : PerlSvConvertible {
	public init(_ hv: PerlHV) throws {
		self.init()
		try hv.withUnsafeCollection {
			for (k, v) in $0 {
				self[k as! Key] = try Value.fromUnsafeSvPointer(v, perl: $0.perl)
			}
		}
	}

	public init?(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		guard let hv = try UnsafeHvPointer(autoDeref: usv, perl: perl) else { return nil }
		self.init()
		for (k, v) in hv.pointee.collection(perl: perl) {
			self[k as! Key] = try Value.fromUnsafeSvPointer(v, perl: perl)
		}
	}
}
