import CPerl

public typealias UnsafeAvPointer = UnsafeMutablePointer<AV>

struct UnsafeAvContext {
	let av: UnsafeAvPointer
	let perl: PerlInterpreter

	static func new(perl: PerlInterpreter) -> UnsafeAvContext {
		return UnsafeAvContext(av: perl.pointee.newAV(), perl: perl)
	}

	func fetch(_ i: Index, lval: Bool = false) -> UnsafeSvContext? {
		return perl.pointee.av_fetch(av, i, lval)
			.flatMap { $0.pointee.map { UnsafeSvContext(sv: $0, perl: perl) } }
	}

	func store(_ i: Index, value: UnsafeSvPointer) {
		if perl.pointee.av_store(av, i, value) == nil {
			UnsafeSvContext(sv: value, perl: perl).refcntDec()
		}
	}

	func delete(_ i: Index) -> UnsafeSvContext? {
		return perl.pointee.av_delete(av, i, 0)
			.map { UnsafeSvContext(sv: $0, perl: perl) }
	}

	func delete(discarding i: Index) {
		perl.pointee.av_delete(av, i, G_DISCARD)
	}

	func exists(_ i: Index) -> Bool {
		return perl.pointee.av_exists(av, i)
	}

	func clear() {
		perl.pointee.av_clear(av)
	}

	func extend(to count: Int) {
		perl.pointee.av_extend(av, count - 1)
	}

	func extend(by count: Int) {
		extend(to: self.count + count)
	}
}

extension UnsafeAvContext {
	init(dereference svc: UnsafeSvContext) throws {
		guard let rvc = svc.referent, rvc.type == SVt_PVAV else {
			throw PerlError.unexpectedValueType(fromUnsafeSvContext(inc: svc), want: PerlArray.self)
		}
		self.init(rebind: rvc)
	}

	init(rebind svc: UnsafeSvContext) {
		let av = UnsafeMutableRawPointer(svc.sv).bindMemory(to: AV.self, capacity: 1)
		self.init(av: av, perl: svc.perl)
	}
}

extension UnsafeAvContext : RandomAccessCollection {
	typealias Element = UnsafeSvContext?
	typealias Index = Int
	typealias Indices = CountableRange<Int>

	var startIndex: Index { return 0 }
	var endIndex: Index { return perl.pointee.av_len(av) + 1 }

	subscript(i: Index) -> UnsafeSvContext? {
		get {
			return fetch(i)
		}
		set {
			if let newValue = newValue {
				store(i, value: newValue.sv)
			} else {
				delete(discarding: i)
			}
		}
	}

	func reserveCapacity(_ capacity: Int) {
		extend(to: capacity)
	}

	func append(_ svc: UnsafeSvContext) {
		perl.pointee.av_push(av, svc.sv)
	}

	func removeFirst() -> UnsafeSvContext {
		return UnsafeSvContext(sv: perl.pointee.av_shift(av), perl: perl)
	}
}
