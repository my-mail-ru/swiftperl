import var CPerl.GV_ADD

/// Provides a safe wrapper for Perl array (`AV`).
/// Performs reference counting on initialization and deinitialization.
///
/// ## Cheat Sheet
///
/// ### Array of strings
///
/// ```perl
/// my @list = ("one", "two", "three");
/// ```
///
/// ```swift
/// let list: PerlArray = ["one", "two", "three"]
/// ```
///
/// ### Array of mixed type data (PSGI response)
///
/// ```perl
/// my @response = (200, ["Content-Type" => "application/json"], ["{}"]);
/// ```
///
/// ```swift
/// let response: PerlArray = [200, ["Content-Type", "application/json"], ["{}"]]
/// ```
///
/// ### Accessing elements of the array
///
/// ```perl
/// my @list;
/// $list[0] = 10
/// push @list, 20;
/// my $first = shift @list;
/// my $second = $list[0]
/// ```
///
/// ```swift
/// let list: PerlArray = []
/// list[0] = 10
/// list.append(20)
/// let first = list.removeFirst()
/// let second = list[0]
/// ```
public final class PerlArray : PerlValue, PerlDerived {
	public typealias UnsafeValue = UnsafeAV

	convenience init(noinc avc: UnsafeAvContext) {
		self.init(noincUnchecked: UnsafeSvContext(rebind: avc))
	}

	convenience init(inc avc: UnsafeAvContext) {
		self.init(incUnchecked: UnsafeSvContext(rebind: avc))
	}

	/// Creates an empty Perl array.
	public convenience init() {
		self.init(perl: .current)
	}

	/// Creates an empty Perl array.
	public convenience init(perl: PerlInterpreter = .current) {
		self.init(noinc: UnsafeAvContext.new(perl: perl))
	}

	/// Initializes Perl array with elements of collection `c`.
	public convenience init<C : Collection>(_ c: C, perl: PerlInterpreter = .current)
		where C.Iterator.Element : PerlSvConvertible {
		self.init(perl: perl)
		reserveCapacity(numericCast(c.count))
		for (i, v) in c.enumerated() {
			self[i] = v as? PerlScalar ?? PerlScalar(v, perl: perl)
		}
	}

	/// Returns the specified Perl global or package array with the given name (so it won't work on lexical variables).
	/// If the variable does not exist then `nil` is returned.
	public convenience init?(get name: String, perl: PerlInterpreter = .current) {
		guard let av = perl.getAV(name) else { return nil }
		self.init(inc: UnsafeAvContext(av: av, perl: perl))
	}

	/// Returns the specified Perl global or package array with the given name (so it won't work on lexical variables).
	/// If the variable does not exist then it will be created.
	public convenience init(getCreating name: String, perl: PerlInterpreter = .current) {
		let av = perl.getAV(name, flags: GV_ADD)!
		self.init(inc: UnsafeAvContext(av: av, perl: perl))
	}

	func withUnsafeAvContext<R>(_ body: (UnsafeAvContext) throws -> R) rethrows -> R {
		defer { _fixLifetime(self) }
		return try unsafeSvContext.sv.withMemoryRebound(to: UnsafeAV.self, capacity: 1) {
			return try body(UnsafeAvContext(av: $0, perl: unsafeSvContext.perl))
		}
	}

	/// A textual representation of the AV, suitable for debugging.
	public override var debugDescription: String {
		let values = withUnsafeAvContext { c in
			c.map { $0.map { try! PerlScalar(inc: $0).debugDescription } ?? "nil" }
				.joined(separator: ", ")
		}
		return "PerlArray([\(values)])"
	}
}

extension PerlArray {
	/// Fetches the element at the specified position.
	///
	/// - Parameter index: The position of the element to fetch.
	/// - Returns: `nil` if the element not exists or is undefined.
	///
	/// - Complexity: O(1).
	public func fetch<T : PerlSvConvertible>(_ index: Int) throws -> T? {
		return try withUnsafeAvContext { c in
			try c.fetch(index).flatMap {
				try T?(_fromUnsafeSvContextInc: $0)
			}
		}
	}

	/// Stores the element at the specified position.
	///
	/// - Parameter index: The position of the element to fetch.
	/// - Parameter value: The value to store in the array.
	///
	/// - Complexity: O(1).
	public func store<T : PerlSvConvertible>(_ index: Int, value: T) {
		withUnsafeAvContext {
			$0.store(index, value: value._toUnsafeSvPointer(perl: $0.perl))
		}
	}

	/// Deletes the element at the specified position.
	///
	/// - Parameter index: The position of the element to fetch.
	/// - Returns: Deleted element or `nil` if the element not exists or is undefined.
	public func delete<T : PerlSvConvertible>(_ index: Int) throws -> T? {
		return try withUnsafeAvContext { c in
			try c.delete(index).flatMap {
				try T?(_fromUnsafeSvContextInc: $0)
			}
		}
	}

	/// Deletes the element at the specified position.
	public func delete(_ index: Int) {
		withUnsafeAvContext { $0.delete(discarding: index) }
	}

	/// Returns true if the element at the specified position is initialized.
	public func exists(_ index: Int) -> Bool {
		return withUnsafeAvContext { $0.exists(index) }
	}

	/// Frees the all the elements of an array, leaving it empty.
	public func clear() {
		withUnsafeAvContext { $0.clear() }
	}
}

//struct PerlArray: MutableCollection {
extension PerlArray : RandomAccessCollection {
	public typealias Element = PerlScalar
	public typealias Index = Int
	public typealias Iterator = IndexingIterator<PerlArray>
	public typealias Indices = CountableRange<Int>

	/// The position of the first element in a nonempty array.
	/// It is always 0 and does not respect Perl variable `$[`.
	///
	/// If the array is empty, `startIndex` is equal to `endIndex`.
	public var startIndex: Int { return 0 }

	/// The array's "past the end" position---that is, the position one greater
	/// than the last valid subscript argument.
	///
	/// If the array is empty, `endIndex` is equal to `startIndex`.
	public var endIndex: Int { return withUnsafeAvContext { $0.endIndex } }

	/// Accesses the element at the specified position.
	///
	/// - Parameter index: The position of the element to access.
	///
	///   If the element not exists then an undefined scalar is returned.
	///   Setting a value to the nonexistent element creates that element.
	///
	/// - Complexity: Reading an element from an array is O(1). Writing is O(1), too.
	public subscript(index: Int) -> PerlScalar {
		get {
			return withUnsafeAvContext { c in
				c.fetch(index).map { try! PerlScalar(inc: $0) } ?? PerlScalar(perl: c.perl)
			}
		}
		set {
			withUnsafeAvContext { c in
				newValue.withUnsafeSvContext {
					$0.refcntInc()
					c.store(index, value: $0.sv)
				}
			}
		}
	}
}

extension PerlArray {
	/// Creates a Perl array from a Swift array of `PerlScalar`s.
	public convenience init(_ array: [Element]) {
		self.init()
		for (i, v) in array.enumerated() {
			self[i] = v
		}
	}
}

extension PerlArray {
	func extend(to count: Int) {
		withUnsafeAvContext { $0.extend(to: count) }
	}

	func extend(by count: Int) {
		extend(to: self.count + count)
	}

	/// Reserves enough space to store the specified number of elements.
	///
	/// If you are adding a known number of elements to an array, use this method
	/// to avoid multiple reallocations. For performance reasons, the newly allocated
	/// storage may be larger than the requested capacity.
	///
	/// - Parameter minimumCapacity: The requested number of elements to store.
	///
	/// - Complexity: O(*n*), where *n* is the count of the array.
	public func reserveCapacity(_ minimumCapacity: Int) {
		extend(to: minimumCapacity)
	}

	/// Adds a new element at the end of the array.
	///
	/// Use this method to append a single element to the end of an array.
	///
	/// Because arrays increase their allocated capacity using an exponential
	/// strategy, appending a single element to an array is an O(1) operation
	/// when averaged over many calls to the `append(_:)` method. When an array
	/// has additional capacity, appending an element is O(1). When an array
	/// needs to reallocate storage before appending, appending is O(*n*),
	/// where *n* is the length of the array.
	///
	/// - Parameter sv: The element to append to the array.
	///
	/// - Complexity: Amortized O(1) over many additions.
	public func append(_ sv: Element) {
		withUnsafeAvContext { c in
			sv.withUnsafeSvContext {
				$0.refcntInc()
				c.append($0)
			}
		}
	}

	// TODO - SeeAlso: `popFirst()`
	/// Removes and returns the first element of the array.
	///
	/// The array can be empty. In this case undefined `PerlScalar` is returned.
	///
	/// - Returns: The first element of the array.
	///
	/// - Complexity: O(1)
	public func removeFirst() -> Element {
		return withUnsafeAvContext { try! PerlScalar(noinc: $0.removeFirst()) }
	}
}

extension PerlArray: ExpressibleByArrayLiteral {
	/// Creates Perl array from the given array literal.
	///
	/// Do not call this initializer directly. It is used by the compiler
	/// when you use an array literal. Instead, create a new array by using an
	/// array literal as its value. To do this, enclose a comma-separated list of
	/// values in square brackets. For example:
	///
	/// ```swift
	/// let array: PerlArray = [200, "OK"]
	/// ```
	///
	/// - Parameter elements: A variadic list of elements of the new array.
	public convenience init (arrayLiteral elements: Element...) {
		self.init(elements)
	}
}

extension Array where Element : PerlSvConvertible {
	/// Creates an array from the Perl array.
	///
	/// - Parameter av: The Perl array with the elements compatible with `Element`.
	/// - Throws: If some of the elements not exist or cannot be converted to `Element`.
	///
	/// - Complexity: O(*n*), where *n* is the count of the array.
	public init(_ av: PerlArray) throws {
		self = try av.withUnsafeAvContext { uc in
			try uc.enumerated().map {
				guard let svc = $1 else { throw PerlError.elementNotExists(av, at: $0) }
				return try Element(_fromUnsafeSvContextInc: svc)
			}
		}
	}

	/// Creates an array from the reference to the Perl array.
	///
	/// - Parameter ref: The reference to the Perl array with the elements
	///   compatible with `Element`.
	/// - Throws: If `ref` is not a reference to a Perl array or
	///   some of the elements not exist or cannot be converted to `Element`.
	///
	/// - Complexity: O(*n*), where *n* is the count of the array.
	public init(_ ref: PerlScalar) throws {
		self = try ref.withReferentUnsafeSvContext(type: .array) { svc in
			try svc.withUnsafeAvContext { avc in
				try avc.enumerated().map {
					guard let svc = $1 else { throw PerlError.elementNotExists(PerlArray(inc: avc), at: $0) }
					return try Element(_fromUnsafeSvContextInc: svc)
				}
			}
		}
	}
}
