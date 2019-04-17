extension String {
	init(cString: UnsafePointer<CChar>, withLength length: Int) {
		let utf8buffer = UnsafeBufferPointer(start: UnsafeRawPointer(cString).assumingMemoryBound(to: UInt8.self), count: length)
		self = String(decoding: utf8buffer, as: UTF8.self)
	}

	func withCStringWithLength<Result>(_ body: (UnsafePointer<CChar>, Int) throws -> Result) rethrows -> Result {
		let length = utf8.count
		return try withCString { try body($0, length) }
	}
}
