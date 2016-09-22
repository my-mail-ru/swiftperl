import CPerl

typealias UnsafeAV = CPerl.AV
typealias UnsafeAvPointer = UnsafeMutablePointer<UnsafeAV>

extension UnsafeAV {
	mutating func collection(perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current*/) -> UnsafeAvCollection {
		return UnsafeAvCollection(av: &self, perl: perl)
	}
}

struct UnsafeAvCollection : RandomAccessCollection {
	typealias Element = UnsafeSvPointer
	typealias Index = Int
	typealias Indices = CountableRange<Int>

	let av: UnsafeAvPointer
	let perl: UnsafeInterpreterPointer

	var startIndex: Index { return 0 }
	var endIndex: Index { return perl.pointee.av_top_index(av) + 1 }

	func fetch(_ i: Index, lval: Bool = false) -> Element? {
		return perl.pointee.av_fetch(av, i, lval ? 1 : 0)?.pointee
	}

	func store(_ i: Index, newValue: Element) -> Element? {
		return perl.pointee.av_store(av, i, newValue)?.pointee
	}

	subscript (i: Index) -> Element { // FIXME maybe -> Element? or maybe not
		get { return fetch(i)! }
		set { _ = store(i, newValue: newValue) }
	}

	func extend(to count: Int) {
		perl.pointee.av_extend(av, count - 1)
	}

	func extend(by count: Int) {
		extend(to: self.count + count)
	}

	func append(_ sv: Element) {
		Perl_av_push(perl, av, sv)
	}

	func removeFirst() -> Element {
		return Perl_av_shift(perl, av)
	}
}

extension UnsafeInterpreter {
	mutating func newAV() -> UnsafeAvPointer {
		return UnsafeMutableRawPointer(Perl_newSV_type(&self, SVt_PVAV)).bindMemory(to: UnsafeAV.self, capacity: 1)
	}
}
