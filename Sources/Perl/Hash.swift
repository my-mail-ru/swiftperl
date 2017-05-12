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

	convenience init(noinc hvc: UnsafeHvContext) {
		self.init(noincUnchecked: UnsafeSvContext(rebind: hvc))
	}

	convenience init(inc hvc: UnsafeHvContext) {
		self.init(incUnchecked: UnsafeSvContext(rebind: hvc))
	}

	/// Creates an empty Perl hash.
	public convenience init() {
		self.init(perl: .current)
	}

	/// Creates an empty Perl hash.
	public convenience init(perl: PerlInterpreter = .current) {
		self.init(noinc: UnsafeHvContext.new(perl: perl))
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
	public convenience init?(get name: String, perl: PerlInterpreter = .current) {
		guard let hv = perl.getHV(name) else { return nil }
		self.init(inc: UnsafeHvContext(hv: hv, perl: perl))
	}

	/// Returns the specified Perl global or package hash with the given name (so it won't work on lexical variables).
	/// If the variable does not exist then it will be created.
	public convenience init(getCreating name: String, perl: PerlInterpreter = .current) {
		let hv = perl.getHV(name, flags: GV_ADD)!
		self.init(inc: UnsafeHvContext(hv: hv, perl: perl))
	}

	func withUnsafeHvContext<R>(_ body: (UnsafeHvContext) throws -> R) rethrows -> R {
		defer { _fixLifetime(self) }
		return try unsafeSvContext.sv.withMemoryRebound(to: UnsafeHV.self, capacity: 1) {
			return try body(UnsafeHvContext(hv: $0, perl: unsafeSvContext.perl))
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
		return try withUnsafeHvContext { c in
			try c.fetch(key).flatMap { try T?(_fromUnsafeSvContextInc: $0) }
		}
	}

	/// Stores the value in the hash for the given key.
	///
	/// - Parameter key: The key to associate with `value`.
	/// - Parameter value: The value to store in the hash.
	public func store<T : PerlSvConvertible>(key: String, value: T) {
		withUnsafeHvContext { c in
			c.store(key, value: value._toUnsafeSvPointer(perl: c.perl))
		}
	}

	/// Deletes the given key and its associated value from the hash.
	///
	/// - Parameter key: The key to remove along with its associated value.
	/// - Returns: The value that was removed, or `nil` if the key was not found in the hash.
	public func delete<T : PerlSvConvertible>(_ key: String) throws -> T? {
		return try withUnsafeHvContext { c in
			try c.delete(key).flatMap { try T?(_fromUnsafeSvContextInc: $0) }
		}
	}

	/// Deletes the given key and its associated value from the hash.
	public func delete(_ key: String) {
		withUnsafeHvContext { $0.delete(discarding: key) }
	}

	/// Returns a boolean indicating whether the specified hash key exists.
	public func exists(_ key: String) -> Bool {
		return withUnsafeHvContext { $0.exists(key) }
	}

	/// Fetches the value associated with the given key.
	///
	/// - Parameter key: The key to find in the hash.
	/// - Returns: The value associated with `key` if `key` is in the hash;
	///   otherwise, `nil`.
	public func fetch<T : PerlSvConvertible>(_ key: PerlScalar) throws -> T? {
		return try withUnsafeHvContext { c in
			try key.withUnsafeSvContext {
				try c.fetch($0.sv).flatMap { try T?(_fromUnsafeSvContextInc: $0) }
			}
		}
	}

	/// Stores the value in the hash for the given key.
	///
	/// - Parameter key: The key to associate with `value`.
	/// - Parameter value: The value to store in the hash.
	public func store<T : PerlSvConvertible>(key: PerlScalar, value: T) {
		withUnsafeHvContext { c in
			key.withUnsafeSvContext {
				c.store($0.sv, value: value._toUnsafeSvPointer(perl: c.perl))
			}
		}
	}

	/// Deletes the given key and its associated value from the hash.
	///
	/// - Parameter key: The key to remove along with its associated value.
	/// - Returns: The value that was removed, or `nil` if the key was not found in the hash.
	public func delete<T : PerlSvConvertible>(_ key: PerlScalar) throws -> T? {
		return try withUnsafeHvContext { c in
			try key.withUnsafeSvContext {
				try c.delete($0.sv).flatMap { try T?(_fromUnsafeSvContextInc: $0) }
			}
		}
	}

	/// Deletes the given key and its associated value from the hash.
	public func delete(_ key: PerlScalar) {
		withUnsafeHvContext { c in key.withUnsafeSvContext { c.delete(discarding: $0.sv) } }
	}

	/// Returns a boolean indicating whether the specified hash key exists.
	public func exists(_ key: PerlScalar) -> Bool {
		return withUnsafeHvContext { c in key.withUnsafeSvContext { c.exists($0.sv) } }
	}

	/// Frees the all the elements of a hash, leaving it empty.
	public func clear() {
		withUnsafeHvContext { $0.clear() }
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
		withUnsafeHvContext { _ = $0.makeIterator() }
		return self
	}

	/// Advances to the next element and returns it, or `nil` if no next element
	/// exists.
	///
	/// Once `nil` has been returned, all subsequent calls return `nil`.
	///
	/// - SeeAlso: `IteratorProtocol`
	public func next() -> Element? {
		return withUnsafeHvContext {
			guard let u = $0.next() else { return nil }
			return (key: u.key, value: try! PerlScalar(inc: u.value))
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
			return withUnsafeHvContext {
				guard let svc = $0.fetch(key) else { return nil }
				return try! PerlScalar(inc: svc)
			}
		}
		set {
			withUnsafeHvContext { c in
				if let value = newValue {
					value.withUnsafeSvContext {
						$0.refcntInc()
						c.store(key, value: $0.sv)
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
			return withUnsafeHvContext { c in
				guard let svc = key.withUnsafeSvContext({ c.fetch($0.sv) }) else { return nil }
				return try! PerlScalar(inc: svc)
			}
		}
		set {
			withUnsafeHvContext { c in
				key.withUnsafeSvContext { key in
					if let value = newValue {
						value.withUnsafeSvContext {
							$0.refcntInc()
							c.store(key.sv, value: $0.sv)
						}
					} else {
						c.delete(discarding: key.sv)
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
	/// Creates a dictionary from the Perl hash.
	///
	/// - Parameter hv: The Perl hash with the values compatible with `Value`.
	/// - Throws: If some of the values cannot be converted to `Value`.
	///
	/// - Complexity: O(*n*), where *n* is the count of the hash.
	public init(_ hv: PerlHash) throws {
		self.init()
		try hv.withUnsafeHvContext {
			for (k, v) in $0 {
				self[k as! Key] = try Value(_fromUnsafeSvContextInc: v)
			}
		}
	}

	/// Creates a dictionary from the reference to the Perl hash.
	///
	/// - Parameter ref: The reference to the Perl hash with the values
	///   compatible with `Value`.
	/// - Throws: If `ref` is not a reference to a Perl hash or
	///   some of the values cannot be converted to `Value`.
	///
	/// - Complexity: O(*n*), where *n* is the count of the hash.
	public init(_ ref: PerlScalar) throws {
		self.init()
		try ref.withReferentUnsafeSvContext(type: .hash) { svc in
			try svc.sv.withMemoryRebound(to: UnsafeHV.self, capacity: 1) { hv in
				for (k, v) in UnsafeHvContext(hv: hv, perl: svc.perl) {
					self[k as! Key] = try Value(_fromUnsafeSvContextInc: v)
				}
			}
		}
	}
}
