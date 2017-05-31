protocol UnsafeValueContext {
	func withUnsafeSvContext<R>(_ body: (UnsafeSvContext) throws -> R) rethrows -> R
}

extension UnsafeSvContext : UnsafeValueContext {
	func withUnsafeSvContext<R>(_ body: (UnsafeSvContext) throws -> R) rethrows -> R {
		return try body(self)
	}
}

extension UnsafeAvContext : UnsafeValueContext {
	func withUnsafeSvContext<R>(_ body: (UnsafeSvContext) throws -> R) rethrows -> R {
		return try av.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { sv in
			try body(UnsafeSvContext(sv: sv, perl: perl))
		}
	}
}

extension UnsafeHvContext : UnsafeValueContext {
	func withUnsafeSvContext<R>(_ body: (UnsafeSvContext) throws -> R) rethrows -> R {
		return try hv.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { sv in
			try body(UnsafeSvContext(sv: sv, perl: perl))
		}
	}
}

extension UnsafeCvContext : UnsafeValueContext {
	func withUnsafeSvContext<R>(_ body: (UnsafeSvContext) throws -> R) rethrows -> R {
		return try cv.withMemoryRebound(to: UnsafeSV.self, capacity: 1) { sv in
			try body(UnsafeSvContext(sv: sv, perl: perl))
		}
	}
}
