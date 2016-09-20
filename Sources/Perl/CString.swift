extension String {
	init(cString: UnsafePointer<CChar>, withLength length: Int) {
//		self = String.decodeCString(UnsafePointer(cString), withLength: length, as: UTF8.self, repairingInvalidCodeUnits: true)!.result
		self = cString.withMemoryRebound(to: UInt8.self, capacity: length) {
			String._fromWellFormedCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: $0, count: length))
		}
	}

/*	@_specialize(UTF8)
	@warn_unused_result
	static func decodeCString<Encoding: UnicodeCodec>(
		_ cString: UnsafePointer<Encoding.CodeUnit>?, withLength length: Int,
		as encoding: Encoding.Type, repairingInvalidCodeUnits isRepairing: Bool = true)
		-> (result: String, repairsMode: Bool)? {

		guard let cString = cString else { return nil }
		let buffer = UnsafeBufferPointer<Encoding.CodeUnit>(start: cString, count: length)

		var string = String()
		var enc = Encoding.init()
		var iter = buffer.makeIterator()
		var hadError = false
		while true {
			let res = enc.decode(&iter)
			switch res {
				case .scalarValue(let us):
					string.append(us)
				case .emptyInput:
					return (result: string, repairsMode: hadError)
				case .error:
					string.append(UnicodeScalar(0xfffd))
					hadError = true
			}
		}
	}*/

	func withCStringWithLength<Result>(_ body: (UnsafePointer<CChar>, Int) throws -> Result) rethrows -> Result {
		let array = ContiguousArray<UTF8.CodeUnit>(self.utf8)
		return try array.withUnsafeBufferPointer { buf in
			try buf.baseAddress!.withMemoryRebound(to: CChar.self, capacity: buf.count) {
				try body($0, buf.count)
			}
		}
	}
}
