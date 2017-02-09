import var CPerl.GV_ADD

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
/// let hash: PerlHash = [
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
/// let age = hash["age"] ?? PerlScalar()
/// hash["age"] = nil
/// let hasAge = hash["age"] != nil
/// hash["age"] = PerlScalar()
/// ```
///
/// The difference between Perl and Swift hash element access APIs is the result of
/// Swiftification. It was done to make subscript behavior match behavior of
/// subscripts in `Dictionary`. So, when a key does not exist subscript returns
/// `nil` not an undefined SV as a Perl programmer could expect.
public final class PerlHash : PerlValue, PerlDerived {
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
	/// let hv = PerlHash(dict) // my %hv = (one => 1, two => 2, three => 3);
	/// ```
	///
	/// More then that arrays, dictionaries, references and objects are also possible:
	///
	/// ```swift
	/// let dict = ["odd": [1, 3], "even": [2, 4]]
	/// let hv = PerlHash(dict) // my %hv = (odd => [1, 3], even => [2, 4]);
	/// ```
	///
	/// - Parameter dict: a dictionary with `String` keys and values
	///   convertible to Perl scalars (conforming to `PerlSvConvertible`).
	public convenience init<T : PerlSvConvertible>(_ dict: [String: T]) {
		self.init()
		for (k, v) in dict {
			self[k] = v as? PerlScalar ?? PerlScalar(v)
		}
	}

	/// Returns the specified Perl global or package hash with the given name (so it won't work on lexical variables).
	/// If the variable does not exist then `nil` is returned.
	public convenience init?(get name: String, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		guard let hv = perl.pointee.getHV(name) else { return nil }
		self.init(inc: hv, perl: perl)
	}

	/// Returns the specified Perl global or package hash with the given name (so it won't work on lexical variables).
	/// If the variable does not exist then it will be created.
	public convenience init(getCreating name: String, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		let hv = perl.pointee.getHV(name, flags: GV_ADD)!
		self.init(inc: hv, perl: perl)
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
		return "PerlHash([\(values)])"
	}
}

extension PerlHash {
	/// Fetches the value associated with the given key.
	///
	/// - Parameter key: The key to find in the hash.
	/// - Returns: The value associated with `key` if `key` is in the hash;
	///   otherwise, `nil`.
	public func fetch<T : PerlSvConvertible>(_ key: String) throws -> T? {
		return try withUnsafeCollection { c in
			try c.fetch(key).flatMap { try T?.fromUnsafeSvPointer($0, perl: c.perl) }
		}
	}

	/// Stores the value in the hash for the given key.
	///
	/// - Parameter key: The key to associate with `value`.
	/// - Parameter value: The value to store in the hash.
	public func store<T : PerlSvConvertible>(key: String, value: T) {
		withUnsafeCollection { c in
			let v = value.toUnsafeSvPointer(perl: c.perl)
			guard c.store(key, newValue: v) != nil else {
				v.pointee.refcntDec(perl: perl)
				return
			}
		}
	}

	/// Deletes the given key and its associated value from the hash.
	///
	/// - Parameter key: The key to remove along with its associated value.
	/// - Returns: The value that was removed, or `nil` if the key was not found in the hash.
	public func delete<T : PerlSvConvertible>(_ key: String) throws -> T? {
		return try withUnsafeCollection { c in
			try c.delete(key).flatMap { try T?.fromUnsafeSvPointer($0, perl: c.perl) }
		}
	}

	/// Deletes the given key and its associated value from the hash.
	public func delete(_ key: String) {
		withUnsafeCollection { $0.delete(discarding: key) }
	}

	/// Returns a boolean indicating whether the specified hash key exists.
	public func exists(_ key: String) -> Bool {
		return withUnsafeCollection { $0.exists(key) }
	}

	/// Fetches the value associated with the given key.
	///
	/// - Parameter key: The key to find in the hash.
	/// - Returns: The value associated with `key` if `key` is in the hash;
	///   otherwise, `nil`.
	public func fetch<T : PerlSvConvertible>(_ key: PerlScalar) throws -> T? {
		return try withUnsafeCollection { c in
			try key.withUnsafeSvPointer { keysv, _ in
				try c.fetch(keysv).flatMap { try T?.fromUnsafeSvPointer($0, perl: c.perl) }
			}
		}
	}

	/// Stores the value in the hash for the given key.
	///
	/// - Parameter key: The key to associate with `value`.
	/// - Parameter value: The value to store in the hash.
	public func store<T : PerlSvConvertible>(key: PerlScalar, value: T) {
		withUnsafeCollection { c in
			key.withUnsafeSvPointer { keysv, _ in
				let v = value.toUnsafeSvPointer(perl: c.perl)
				guard c.store(keysv, newValue: v) != nil else {
					v.pointee.refcntDec(perl: perl)
					return
				}
			}
		}
	}

	/// Deletes the given key and its associated value from the hash.
	///
	/// - Parameter key: The key to remove along with its associated value.
	/// - Returns: The value that was removed, or `nil` if the key was not found in the hash.
	public func delete<T : PerlSvConvertible>(_ key: PerlScalar) throws -> T? {
		return try withUnsafeCollection { c in
			try key.withUnsafeSvPointer { keysv, _ in
				try c.delete(keysv).flatMap { try T?.fromUnsafeSvPointer($0, perl: c.perl) }
			}
		}
	}

	/// Deletes the given key and its associated value from the hash.
	public func delete(_ key: PerlScalar) {
		withUnsafeCollection { c in key.withUnsafeSvPointer { keysv, _ in c.delete(discarding: keysv) } }
	}

	/// Returns a boolean indicating whether the specified hash key exists.
	public func exists(_ key: PerlScalar) -> Bool {
		return withUnsafeCollection { c in key.withUnsafeSvPointer { keysv, _ in c.exists(keysv) } }
	}

	/// Frees the all the elements of a hash, leaving it empty.
	public func clear() {
		withUnsafeCollection { $0.clear() }
	}
}

extension PerlHash: Sequence, IteratorProtocol {
	public typealias Key = String
	public typealias Value = PerlScalar
	public typealias Element = (key: Key, value: Value)

	/// Returns an iterator over the elements of this hash.
	///
	/// `PerlHash` conforms to `IteratorProtocol` itself. So a returned value
	/// is always `self`. Behind the scenes it calls Perl macro `hv_iterinit`
	/// and prepares a starting point to traverse the hash table.
	///
	/// - Returns: `self`
	/// - Attention: Only one iterator is possible at any time.
	/// - SeeAlso: `Sequence`
	public func makeIterator() -> PerlHash {
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
			return (key: u.key, value: try! PerlScalar(inc: u.value, perl: $0.perl))
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
	public subscript(key: Key) -> PerlScalar? {
		get {
			return withUnsafeCollection {
				guard let sv = $0.fetch(key) else { return nil }
				return try! PerlScalar(inc: sv, perl: $0.perl)
			}
		}
		set {
			withUnsafeCollection { c in
				if let value = newValue {
					value.withUnsafeSvPointer { sv, _ in
						_ = c.store(key, newValue: sv)?.pointee.refcntInc()
					}
				} else {
					c.delete(discarding: key)
				}
			}
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
	public subscript(key: PerlScalar) -> PerlScalar? {
		get {
			return withUnsafeCollection { c in
				guard let sv = key.withUnsafeSvPointer({ c.fetch($0.0) }) else { return nil }
				return try! PerlScalar(inc: sv, perl: c.perl)
			}
		}
		set {
			withUnsafeCollection { c in
				key.withUnsafeSvPointer { keysv, _ in
					if let value = newValue {
						value.withUnsafeSvPointer { sv, _ in
							_ = c.store(keysv, newValue: sv)?.pointee.refcntInc()
						}
					} else {
						c.delete(discarding: keysv)
					}
				}
			}
		}
	}
}

extension PerlHash {
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

extension PerlHash : ExpressibleByDictionaryLiteral {
	/// Creates a Perl hash initialized with a dictionary literal.
	///
	/// Do not call this initializer directly. It is called by the compiler to
	/// handle dictionary literals. To use a dictionary literal as the initial
	/// value of a hash, enclose a comma-separated list of key-value pairs
	/// in square brackets. For example:
	///
	/// ```swift
	/// let header: PerlHash = [
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
	public init(_ hv: PerlHash) throws {
		self.init()
		try hv.withUnsafeCollection {
			for (k, v) in $0 {
				self[k as! Key] = try Value.fromUnsafeSvPointer(v, perl: $0.perl)
			}
		}
	}

	public init?(_ sv: PerlScalar) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		guard let hv = try UnsafeHvPointer(autoDeref: usv, perl: perl) else { return nil }
		self.init()
		for (k, v) in hv.pointee.collection(perl: perl) {
			self[k as! Key] = try Value.fromUnsafeSvPointer(v, perl: perl)
		}
	}
}
