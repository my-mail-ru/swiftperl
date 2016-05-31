import CPerl

//struct PerlStack: Collection, MutableCollection, RangeReplaceableCollection {
struct PerlStack: RandomAccessCollection, RangeReplaceableCollection {
	typealias Pointer = UnsafeMutablePointer<PerlSV.Pointer>

	var ax: Int
	var sx: Int
	var sp: UnsafeMutablePointer<PerlSV.Pointer?> { return PL_stack_base.advanced(by: sx) }

	typealias Index = Int
	typealias Iterator = IndexingIterator<PerlStack>
	typealias Indices = CountableRange<Int>

	var startIndex: Int { return 0 }
	var endIndex: Int { return sx - ax + 1 }

	init() {
		ax = Int(TOPMARK) + 1
		sx = PL_stack_base.distance(to: PL_stack_sp)
	}

	subscript (i: Int) -> PerlSV {
		get { return PerlSV(PL_stack_base![ax + i]!) }
		set {
			PL_stack_base![ax + i] = newValue.pointer
			newValue.refcntInc() // FIXME is it?
		}
	}

	internal subscript (pointerFor i: Int) -> PerlSV.Pointer {
		get { return PL_stack_base![ax + i]! }
		set { PL_stack_base![ax + i] = newValue }
	}

	mutating func replaceSubrange<C: Collection where C.Iterator.Element == Iterator.Element> (_ subRange: Range<Int>, with newElements: C) {
		precondition(subRange.lowerBound >= 0, "replace: subRange start is negative")
		precondition(subRange.upperBound <= endIndex, "replace: subRange extends past the end")
		let newCount = numericCast(newElements.count) as Int
		let growth = newCount - subRange.count
		let moveRange = subRange.upperBound..<self.endIndex
		if growth > 0 {
			extend(by: growth)
			for i in moveRange.reversed() {
				self[pointerFor: i + growth] = self[pointerFor: i]
			}
		} else {
			for i in moveRange {
				self[pointerFor: i + growth] = self[pointerFor: i]
			}
		}
		sx += growth
		var i = subRange.lowerBound
		var j = newElements.startIndex
		for _ in 0..<newCount {
			self[i] = newElements[j].perlSV
			formIndex(after: &i)
			newElements.formIndex(after: &j)
		}
		putBack()
	}

	func extend (by count: Int) {
		EXTEND(sp, count)
	}

	mutating func pushMark () {
		PUSHMARK(sp)
		ax = Int(TOPMARK) + 1
	}

	mutating func popMark () {
		ax = Int(POPMARK()) + 1
	}

	func putBack () {
		PL_stack_sp = sp
	}

	mutating func spAgain () {
		sx = PL_stack_base.distance(to: PL_stack_sp)
	}

	func mortalize() {
		for i in startIndex..<endIndex {
			sv_2mortal(self[pointerFor: i])
		}
	}

	mutating func wrapXSub (_ cb: (PerlStack) throws -> [PerlSV]) rethrows {
		popMark()
		let result = try cb(self)
		self.replaceSubrange(startIndex..<endIndex, with: result)
		self.mortalize()
	}

	mutating func wrapCall<T: PerlSVConvertible>(_ args: [PerlSVConvertible], _ closure: @noescape () -> Int32) throws -> [T] {
		pushMark()
		self.replaceSubrange(startIndex..<endIndex, with: args.map { $0.perlSV })
		self.mortalize()
		putBack()
		let count = closure()
		spAgain()
		let err = PerlSV(ERRSV)
		if err.value() as Bool {
			throw PerlError.died(err)
		}
		precondition(Int(count) == self.count, "\(Int(count)) != \(self.count)")
		let result = try self.map { try T.fromPerlSV($0) }
		self.removeAll(keepingCapacity: true)
		return result
	}
}
