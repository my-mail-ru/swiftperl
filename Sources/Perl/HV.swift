public final class PerlHV : PerlValue, PerlDerived {
	public typealias UnsafeValue = UnsafeHV

	public convenience init() {
		self.init(perl: UnsafeInterpreter.current)
	}

	public convenience init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		let hv = perl.pointee.newHV()!
		self.init(noinc: hv, perl: perl)
	}

	convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(_noinc: sv, perl: perl)
	}

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

	public override var debugDescription: String {
		let values = map { "\($0.key.debugDescription): \($0.value.debugDescription)" } .joined(separator: ", ")
		return "PerlHV([\(values)])"
	}
}

extension PerlHV: Sequence, IteratorProtocol {
	public typealias Key = String
	public typealias Value = PerlSV
	public typealias Element = (key: Key, value: Value)

	public func makeIterator () -> PerlHV {
		withUnsafeCollection { _ = $0.makeIterator() }
		return self
	}

	public func next() -> Element? {
		return withUnsafeCollection {
			guard let u = $0.next() else { return nil }
			return (key: u.key, value: try! PerlSV(inc: u.value, perl: $0.perl))
		}
	}

	public subscript (key: Key) -> PerlSV? {
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
