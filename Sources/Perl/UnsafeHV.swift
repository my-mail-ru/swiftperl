import CPerl

typealias UnsafeHV = CPerl.HV
typealias UnsafeHvPointer = UnsafeMutablePointer<UnsafeHV>

extension UnsafeHV {
	mutating func collection(perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current*/) -> UnsafeHvCollection {
		return UnsafeHvCollection(hv: &self, perl: perl)
	}
}

struct UnsafeHvCollection: Sequence {
	typealias Key = String
	typealias Value = UnsafeSvPointer
	typealias Element = (key: Key, value: Value)

	let hv: UnsafeHvPointer
	let perl: UnsafeInterpreterPointer

	func makeIterator() -> Iterator {
		return Iterator(self)
	}

	struct Iterator: IteratorProtocol {
		let c: UnsafeHvCollection

		init(_ c: UnsafeHvCollection) {
			self.c = c
			c.perl.pointee.hv_iterinit( c.hv)
		}

		func next() -> Element? {
			guard let he = c.perl.pointee.hv_iternext(c.hv) else { return nil }
			var klen = 0
			let ckey = c.perl.pointee.HePV(he, &klen)!
			let key = String(cString: ckey, withLength: klen)
			let value = HeVAL(he)!
			return (key: key, value: value)
		}
	}

	func fetch(_ key: Key, lval: Bool = false) -> Value? {
		let lval: Int32 = lval ? 1 : 0
		return key.withCStringWithLength { perl.pointee.hv_fetch(hv, $0, UInt32($1), lval) }?.pointee
	}

	func store(_ key: Key, newValue: Value) -> Value? {
		return key.withCStringWithLength { perl.pointee.hv_store(hv, $0, UInt32($1), newValue, 0) }?.pointee
	}

	@discardableResult
	func delete(_ key: Key, discard: Bool = true) -> Value? {
		let flags: Int32 = discard ? G_DISCARD : 0
		return key.withCStringWithLength { perl.pointee.hv_delete(hv, $0, UInt32($1), flags) }
	}

	subscript (key: Key) -> Value? {
		get { return fetch(key) }
		set {
			if let value = newValue {
				_ = store(key, newValue: value)
			} else {
				delete(key)
			}
		}
	}
}
