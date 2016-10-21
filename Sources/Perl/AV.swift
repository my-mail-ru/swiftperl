final class PerlAV : PerlValue, PerlDerived {
	typealias UnsafeValue = UnsafeAV

	convenience init() {
		self.init(perl: UnsafeInterpreter.current)
	}

	convenience init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		let av = perl.pointee.newAV()!
		self.init(noinc: av, perl: perl)
	}

	convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(_noinc: sv, perl: perl)
	}

	convenience init<C : Collection>(_ c: C, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current)
		where C.Iterator.Element : PerlSvConvertible {
		self.init(perl: perl)
		reserveCapacity(numericCast(c.count))
		for (i, v) in c.enumerated() {
			self[i] = v as? PerlSV ?? PerlSV(v, perl: perl)
		}
	}

	func withUnsafeAvPointer<R>(_ body: (UnsafeAvPointer, UnsafeInterpreterPointer) throws -> R) rethrows -> R {
		return try withUnsafeSvPointer { sv, perl in
			return try sv.withMemoryRebound(to: UnsafeAV.self, capacity: 1) {
				return try body($0, perl)
			}
		}
	}

	func withUnsafeCollection<R>(_ body: (UnsafeAvCollection) throws -> R) rethrows -> R {
		return try withUnsafeAvPointer {
			return try body($0.pointee.collection(perl: $1))
		}
	}

	override var debugDescription: String {
		let values = map { $0.debugDescription } .joined(separator: ", ")
		return "PerlAV([\(values)])"
	}
}

//struct PerlAV: MutableCollection {
extension PerlAV : RandomAccessCollection {
	typealias Element = PerlSV
	typealias Index = Int
	typealias Iterator = IndexingIterator<PerlAV>
	typealias Indices = CountableRange<Int>

	var startIndex: Int { return 0 }
	var endIndex: Int { return withUnsafeCollection { $0.endIndex } }

	subscript (i: Int) -> PerlSV {
		get { return withUnsafeCollection { try! PerlSV(inc: $0[i], perl: $0.perl) } }
		set {
			withUnsafeCollection { c in
				newValue.withUnsafeSvPointer { sv, _ in
					_ = c.store(i, newValue: sv)?.pointee.refcntInc()
				}
			}
		}
	}
}

extension PerlAV {
	convenience init(_ array: [Element]) {
		self.init()
		for (i, v) in array.enumerated() {
			self[i] = v
		}
	}
}

extension PerlAV : RangeReplaceableCollection {
	func extend(to count: Int) {
		withUnsafeCollection { $0.extend(to: count) }
	}

	func extend(by count: Int) {
		extend(to: self.count + count)
	}

	func reserveCapacity(_ capacity: Int) {
		extend(to: capacity)
	}

	func replaceSubrange<C: Collection>(_ subRange: Range<Index>, with newElements: C)
		where C.Iterator.Element == Element {
/*		precondition(subRange.lowerBound >= 0, "replace: subRange start is negative")
		precondition(subRange.upperBound <= endIndex, "replace: subRange extends past the end")
		let newCount = numericCast(newElements.count) as Int
		let growth = newCount - subRange.count
		let moveRange = subRange.lowerBound..<self.endIndex
		if growth > 0 {
			extend(by: growth)
			for i in moveRange.reversed() {
				self[i] = self[i + growth]
			}
		} else {
			for i in moveRange {
				self[i] = self[i + growth]
			}
		}
		sx += growth
		var i = subRange.lowerBound
		var j = newElements.startIndex
		for _ in 0..<newCount {
			self[i] = newElements[j]
			formIndex(after: &i)
			newElements.formIndex(after: &j)
		}
		putBack()*/
	}

	func append(_ sv: Element) {
		withUnsafeCollection { c in
			sv.withUnsafeSvPointer { sv, _ in
				c.append(sv.pointee.refcntInc())
			}
		}
	}

	func removeFirst() -> Element {
		return withUnsafeCollection { try! PerlSV(noinc: $0.removeFirst(), perl: $0.perl) }
	}
}

extension PerlAV: ExpressibleByArrayLiteral {
	convenience init (arrayLiteral elements: Element...) {
		self.init(elements)
	}
}

extension Array where Element : PerlSvConvertible {
	init(_ av: PerlAV) throws {
		self = try av.withUnsafeCollection { uc in
			try uc.map { try Element.fromUnsafeSvPointer($0, perl: uc.perl) }
		}
	}

	init?(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		guard let av = try UnsafeAvPointer(autoDeref: usv, perl: perl) else { return nil }
		self = try av.pointee.collection(perl: perl).map { try Element.fromUnsafeSvPointer($0, perl: perl) }
	}
}
