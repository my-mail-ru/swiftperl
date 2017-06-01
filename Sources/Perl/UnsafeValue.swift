import CPerl

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
		return try av.withMemoryRebound(to: SV.self, capacity: 1) { sv in
			try body(UnsafeSvContext(sv: sv, perl: perl))
		}
	}
}

extension UnsafeHvContext : UnsafeValueContext {
	func withUnsafeSvContext<R>(_ body: (UnsafeSvContext) throws -> R) rethrows -> R {
		return try hv.withMemoryRebound(to: SV.self, capacity: 1) { sv in
			try body(UnsafeSvContext(sv: sv, perl: perl))
		}
	}
}

extension UnsafeCvContext : UnsafeValueContext {
	func withUnsafeSvContext<R>(_ body: (UnsafeSvContext) throws -> R) rethrows -> R {
		return try cv.withMemoryRebound(to: SV.self, capacity: 1) { sv in
			try body(UnsafeSvContext(sv: sv, perl: perl))
		}
	}
}

extension UnsafeSvContext {
	func withUnsafeAvContext<R>(_ body: (UnsafeAvContext) throws -> R) throws -> R {
		guard type == SVt_PVAV else {
			throw PerlError.unexpectedValueType(fromUnsafeSvContext(inc: self), want: PerlArray.self)
		}
		return try sv.withMemoryRebound(to: AV.self, capacity: 1) { av in
			try body(UnsafeAvContext(av: av, perl: perl))
		}
	}

	func withUnsafeHvContext<R>(_ body: (UnsafeHvContext) throws -> R) throws -> R {
		guard type == SVt_PVHV else {
			throw PerlError.unexpectedValueType(fromUnsafeSvContext(inc: self), want: PerlHash.self)
		}
		return try sv.withMemoryRebound(to: HV.self, capacity: 1) { hv in
			try body(UnsafeHvContext(hv: hv, perl: perl))
		}
	}

	func withUnsafeCvContext<R>(_ body: (UnsafeCvContext) throws -> R) throws -> R {
		guard type == SVt_PVCV else {
			throw PerlError.unexpectedValueType(fromUnsafeSvContext(inc: self), want: PerlSub.self)
		}
		return try sv.withMemoryRebound(to: CV.self, capacity: 1) { cv in
			try body(UnsafeCvContext(cv: cv, perl: perl))
		}
	}

	init(rebind avc: UnsafeAvContext) {
		let sv = UnsafeMutableRawPointer(avc.av).bindMemory(to: SV.self, capacity: 1)
		self.init(sv: sv, perl: avc.perl)
	}

	init(rebind hvc: UnsafeHvContext) {
		let sv = UnsafeMutableRawPointer(hvc.hv).bindMemory(to: SV.self, capacity: 1)
		self.init(sv: sv, perl: hvc.perl)
	}

	init(rebind cvc: UnsafeCvContext) {
		let sv = UnsafeMutableRawPointer(cvc.cv).bindMemory(to: SV.self, capacity: 1)
		self.init(sv: sv, perl: cvc.perl)
	}
}
