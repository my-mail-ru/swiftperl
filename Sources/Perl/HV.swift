import CPerl

final class PerlHV : PerlSVProtocol {
	typealias Struct = CPerl.hv
	typealias Pointer = UnsafeMutablePointer<Struct>
	let pointer: Pointer

	init (_ p: Pointer) {
		pointer = p
		refcntInc()
	}

	init() {
		pointer = newHV()
	}

	deinit {
		refcntDec()
	}
}

extension PerlHV: Sequence {
	typealias Key = String
	typealias Value = PerlSV
	typealias Element = (key: Key, value: Value)

	func makeIterator () -> Iterator {
		return Iterator(pointer)
	}

	struct Iterator: IteratorProtocol {
		let hv: PerlHV.Pointer

		init (_ hv: PerlHV.Pointer) {
			hv_iterinit(hv)
			self.hv = hv
		}

		func next () -> Element? {
			guard let he = hv_iternext(hv) else {
				return nil
			}
			var klen = 0
			let ckey = HePV(he, &klen)!
			let key = String(cString: ckey, withLength: klen)
			let value = PerlSV(HeVAL(he))
			return (key: key, value: value)
		}
	}

	subscript (key: String) -> PerlSV? {
		get {
			let ret = key.withCStringWithLength {
				hv_fetch(pointer, $0, UInt32($1), 0)
			}
			return ret != nil ? PerlSV(ret!.pointee!) : nil
		}
		set {
			if let value = newValue {
				key.withCStringWithLength {
					if hv_store(pointer, $0, UInt32($1), value.pointer, 0) != nil {
						value.refcntInc()
					}
				}
			} else {
				key.withCStringWithLength { hv_delete(pointer, $0, UInt32($1), G_DISCARD) }
			}
		}
	}
}

extension PerlHV {
	convenience init(_ dict: [Key: Value]) {
		self.init()
		for (k, v) in dict {
			self[k] = v
		}
	}

	convenience init(_ elements: [(Key, Value)]) {
		self.init()
		for (k, v) in elements {
			self[k] = v
		}
	}
}

extension PerlHV : DictionaryLiteralConvertible {
	convenience init(dictionaryLiteral elements: (Key, Value)...) {
		self.init(elements)
	}
}
