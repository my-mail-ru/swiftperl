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
	var endIndex: Index { return S_av_top_index(perl, av) + 1 }

	func fetch(_ i: Index, lval: Bool = false) -> Element? {
		return Perl_av_fetch(perl, av, i, lval ? 1 : 0)?.pointee
	}

	func store(_ i: Index, newValue: Element) -> Element? {
		return Perl_av_store(perl, av, i, newValue)?.pointee
	}

	subscript (i: Index) -> Element { // FIXME maybe -> Element? or maybe not
		get { return fetch(i)! }
		set { _ = store(i, newValue: newValue) }
	}

	func extend(to count: Int) {
		Perl_av_extend(perl, av, count - 1)
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
		return UnsafeAvPointer(Perl_newSV_type(&self, SVt_PVAV))
	}
}
