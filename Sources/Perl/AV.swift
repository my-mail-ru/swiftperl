final class PerlAV : PerlSvCastable {
	typealias Struct = UnsafeAV
	typealias Pointer = UnsafeAvPointer
	let unsafeCollection: UnsafeAvCollection

	var pointer: Pointer { return unsafeCollection.av }
	var perl: UnsafeInterpreterPointer { return unsafeCollection.perl }

	convenience init() {
		self.init(perl: UnsafeInterpreter.current)
	}

	init(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		unsafeCollection = perl.pointee.newAV().pointee.collection(perl: perl)
	}

	init(_ p: Pointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		unsafeCollection = p.pointee.collection(perl: perl)
		pointer.pointee.refcntInc()
	}

	deinit {
		pointer.pointee.refcntDec(perl: perl)
	}

	convenience init?(_ sv: PerlSV) throws {
		guard let av = try UnsafeAvPointer(sv.pointer, perl: sv.perl) else { return nil }
		self.init(av, perl: sv.perl)
	}

	convenience init<C : Collection>(_ c: C, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current)
		where C.Iterator.Element : PerlSVConvertible {
		self.init(perl: perl)
		reserveCapacity(numericCast(c.count))
		for (i, v) in c.enumerated() {
			self[i] = v as? PerlSV ?? PerlSV(v, perl: perl)
		}
	}

	func value<T : PerlSVConvertible>() throws -> [T] {
		return try map { try T.promoteFromUnsafeSV($0.pointer, perl: $0.perl) }
	}
}

//struct PerlAV: MutableCollection {
extension PerlAV : RandomAccessCollection {
	typealias Element = PerlSV
	typealias Index = Int
	typealias Iterator = IndexingIterator<PerlAV>
	typealias Indices = CountableRange<Int>

	var startIndex: Int { return 0 }
	var endIndex: Int { return unsafeCollection.endIndex }

	subscript (i: Int) -> PerlSV {
		get { return PerlSV(unsafeCollection[i], perl: unsafeCollection.perl) }
		set { unsafeCollection.store(i, newValue: newValue.pointer)?.pointee.refcntInc() }
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
		unsafeCollection.extend(to: count)
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
		unsafeCollection.append(sv.pointer) // FIXME refcnt?
	}

	func removeFirst() -> Element {
		return PerlSV(unsafeCollection.removeFirst()) // FIXME refcnt?
	}
}

extension PerlAV: ExpressibleByArrayLiteral {
	convenience init (arrayLiteral elements: Element...) {
		self.init(elements)
	}
}

extension Array where Element : PerlSVProbablyConvertible {
	init(_ av: PerlAV) throws {
		self = try av.unsafeCollection.map { try Element.promoteFromUnsafeSV($0, perl: av.perl) }
	}
}

extension Array where Element : PerlSVDefinitelyConvertible {
	init(_ av: PerlAV) {
		self = av.unsafeCollection.map { Element.promoteFromUnsafeSV($0, perl: av.perl) }
	}
}

extension Array where Element : PerlSVConvertible {
	init?(_ sv: PerlSV) throws {
		guard let av = try UnsafeAvPointer(sv.pointer, perl: sv.perl) else { return nil }
		self = try av.pointee.collection(perl: sv.perl).map { try Element.promoteFromUnsafeSV($0, perl: sv.perl) }
	}
}
