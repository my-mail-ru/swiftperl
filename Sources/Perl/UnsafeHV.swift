import CPerl

public typealias UnsafeHV = CPerl.HV
public typealias UnsafeHvPointer = UnsafeMutablePointer<UnsafeHV>

struct UnsafeHvContext {
	let hv: UnsafeHvPointer
	let perl: PerlInterpreter

	static func new(perl: PerlInterpreter) -> UnsafeHvContext {
		return UnsafeHvContext(hv: perl.pointee.newHV(), perl: perl)
	}

	func fetch(_ key: String, lval: Bool = false) -> UnsafeSvContext? {
		return key.withCStringWithLength { perl.pointee.hv_fetch(hv, $0, -Int32($1), lval) }
			.flatMap { $0.pointee.map { UnsafeSvContext(sv: $0, perl: perl) } }
	}

	func store(_ key: String, value: UnsafeSvPointer) {
		if key.withCStringWithLength({ perl.pointee.hv_store(hv, $0, -Int32($1), value, 0) }) == nil {
			UnsafeSvContext(sv: value, perl: perl).refcntDec()
		}
	}

	func delete(_ key: String) -> UnsafeSvContext? {
		return key.withCStringWithLength { perl.pointee.hv_delete(hv, $0, -Int32($1), 0) }
			.map { UnsafeSvContext(sv: $0, perl: perl) }
	}

	func delete(discarding key: String) {
		key.withCStringWithLength { _ = perl.pointee.hv_delete(hv, $0, -Int32($1), G_DISCARD) }
	}

	func exists(_ key: String) -> Bool {
		return key.withCStringWithLength { perl.pointee.hv_exists(hv, $0, -Int32($1)) }
	}

	func fetch(_ key: UnsafeSvPointer, lval: Bool = false) -> UnsafeSvContext? {
		return perl.pointee.hv_fetch_ent(hv, key, lval, 0)
			.map(HeVAL).map { UnsafeSvContext(sv: $0, perl: perl) }
	}

	func store(_ key: UnsafeSvPointer, value: UnsafeSvPointer) {
		if perl.pointee.hv_store_ent(hv, key, value, 0) == nil {
			UnsafeSvContext(sv: value, perl: perl).refcntDec()
		}
	}

	func delete(_ key: UnsafeSvPointer) -> UnsafeSvContext? {
		return perl.pointee.hv_delete_ent(hv, key, 0, 0)
			.map { UnsafeSvContext(sv: $0, perl: perl) }
	}

	func delete(discarding key: UnsafeSvPointer) {
		perl.pointee.hv_delete_ent(hv, key, G_DISCARD, 0)
	}

	func exists(_ key: UnsafeSvPointer) -> Bool {
		return perl.pointee.hv_exists_ent(hv, key, 0)
	}

	func clear() {
		perl.pointee.hv_clear(hv)
	}
}

extension UnsafeHvContext {
	init(dereference svc: UnsafeSvContext) throws {
		guard let rvc = svc.referent, rvc.type == .hash else {
			throw PerlError.unexpectedSvType(fromUnsafeSvContext(inc: svc), want: .hash)
		}
		self.init(rebind: rvc)
	}

	init(rebind svc: UnsafeSvContext) {
		let hv = UnsafeMutableRawPointer(svc.sv).bindMemory(to: UnsafeHV.self, capacity: 1)
		self.init(hv: hv, perl: svc.perl)
	}
}

extension UnsafeHvContext: Sequence, IteratorProtocol {
	typealias Key = String
	typealias Value = UnsafeSvContext
	typealias Element = (key: Key, value: Value)

	func makeIterator() -> UnsafeHvContext {
		perl.pointee.hv_iterinit(hv)
		return self
	}

	func next() -> Element? {
		guard let he = perl.pointee.hv_iternext(hv) else { return nil }
		var klen = 0
		let ckey = perl.pointee.HePV(he, &klen)
		let key = String(cString: ckey, withLength: klen)
		let value = UnsafeSvContext(sv: HeVAL(he), perl: perl)
		return (key: key, value: value)
	}

	subscript(key: Key) -> Value? {
		get { return fetch(key) }
		set {
			if let value = newValue {
				store(key, value: value.sv)
			} else {
				delete(discarding: key)
			}
		}
	}

	subscript(key: UnsafeSvPointer) -> Value? {
		get { return fetch(key) }
		set {
			if let value = newValue {
				store(key, value: value.sv)
			} else {
				delete(discarding: key)
			}
		}
	}
}
