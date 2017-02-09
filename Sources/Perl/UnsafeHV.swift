import CPerl

public typealias UnsafeHV = CPerl.HV
public typealias UnsafeHvPointer = UnsafeMutablePointer<UnsafeHV>

extension UnsafeHV {
	mutating func collection(perl: UnsafeInterpreterPointer/* = UnsafeInterpreter.current*/) -> UnsafeHvCollection {
		return UnsafeHvCollection(hv: &self, perl: perl)
	}
}

struct UnsafeHvCollection: Sequence, IteratorProtocol {
	typealias Key = String
	typealias Value = UnsafeSvPointer
	typealias Element = (key: Key, value: Value)

	let hv: UnsafeHvPointer
	let perl: UnsafeInterpreterPointer

	func makeIterator() -> UnsafeHvCollection {
		perl.pointee.hv_iterinit(hv)
		return self
	}

	func next() -> Element? {
		guard let he = perl.pointee.hv_iternext(hv) else { return nil }
		var klen = 0
		let ckey = perl.pointee.HePV(he, &klen)!
		let key = String(cString: ckey, withLength: klen)
		let value = HeVAL(he)
		return (key: key, value: value)
	}

	func fetch(_ key: Key, lval: Bool = false) -> Value? {
		let lval: Int32 = lval ? 1 : 0
		return key.withCStringWithLength { perl.pointee.hv_fetch(hv, $0, -Int32($1), lval) }?.pointee
	}

	func store(_ key: Key, newValue: Value) -> Value? {
		return key.withCStringWithLength { perl.pointee.hv_store(hv, $0, -Int32($1), newValue, 0) }?.pointee
	}

	func delete(_ key: Key) -> Value? {
		return key.withCStringWithLength { perl.pointee.hv_delete(hv, $0, -Int32($1), 0) }
	}

	func delete(discarding key: Key) {
		key.withCStringWithLength { _ = perl.pointee.hv_delete(hv, $0, -Int32($1), G_DISCARD) }
	}

	func exists(_ key: Key) -> Bool {
		return key.withCStringWithLength { perl.pointee.hv_exists(hv, $0, -Int32($1)) }
	}

	subscript(key: Key) -> Value? {
		get { return fetch(key) }
		set {
			if let value = newValue {
				_ = store(key, newValue: value)
			} else {
				delete(discarding: key)
			}
		}
	}

	func fetch(_ key: UnsafeSvPointer, lval: Bool = false) -> Value? {
		return perl.pointee.hv_fetch_ent(hv, key, lval ? 1 : 0, 0).map(HeVAL)
	}

	func store(_ key: UnsafeSvPointer, newValue: Value) -> Value? {
		return perl.pointee.hv_store_ent(hv, key, newValue, 0).map(HeVAL)
	}

	func delete(_ key: UnsafeSvPointer) -> Value? {
		return perl.pointee.hv_delete_ent(hv, key, 0, 0)
	}

	func delete(discarding key: UnsafeSvPointer) {
		perl.pointee.hv_delete_ent(hv, key, G_DISCARD, 0)
	}

	func exists(_ key: UnsafeSvPointer) -> Bool {
		return perl.pointee.hv_exists_ent(hv, key, 0)
	}

	subscript(key: UnsafeSvPointer) -> Value? {
		get { return fetch(key) }
		set {
			if let value = newValue {
				_ = store(key, newValue: value)
			} else {
				delete(discarding: key)
			}
		}
	}

	func clear() {
		perl.pointee.hv_clear(hv)
	}
}
