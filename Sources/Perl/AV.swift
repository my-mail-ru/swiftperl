import CPerl

final class PerlAV : PerlSVProtocol {
	typealias Struct = av
	typealias Pointer = UnsafeMutablePointer<av>
	let pointer: Pointer

	internal init (noinc p: Pointer) {
		pointer = p
	}

	init (_ p: Pointer) {
		pointer = p
		refcntInc()
	}

	deinit {
		refcntDec()
	}
}

//struct PerlAV: MutableCollection {
extension PerlAV : RandomAccessCollection {
	typealias Element = PerlSV
	typealias Index = Int
	typealias Iterator = IndexingIterator<PerlAV>
	typealias Indices = CountableRange<Int>

	var startIndex: Int { return 0 }
	var endIndex: Int { return av_top_index(pointer) + 1 }

	subscript (i: Int) -> PerlSV {
		get { return PerlSV(av_fetch(pointer, i, 0)!.pointee!) }
		set {
			if av_store(pointer, i, newValue.pointer) != nil {
				newValue.refcntInc()
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
	convenience init() {
		self.init(noinc: newAV())
	}

	func extend(to count: Int) {
		av_extend(pointer, count - 1)
	}

	func extend(by count: Int) {
		extend(to: self.count + count)
	}

	func replaceSubrange<C: Collection where C.Iterator.Element == Element> (_ subRange: Range<Index>, with newElements: C) {
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

	func append(_ x: Iterator.Element) {
		av_push(pointer, x.pointer)
	}

	func removeFirst() -> Iterator.Element {
		return PerlSV(av_shift(pointer))
	}
}

extension PerlAV: ArrayLiteralConvertible {
	convenience init (arrayLiteral elements: Element...) {
		self.init(elements)
	}
}

extension Array where Element : PerlSVConvertible {
	init(_ av: PerlAV) throws {
		self = try av.map { try Element.fromPerlSV($0) }
	}
}

extension Array where Element : PerlSVConvertibleNonThrowing {
	init(_ av: PerlAV) {
		self = av.map { Element.fromPerlSV($0) }
	}
}
