protocol PerlDerived : PerlSVConvertible {
	associatedtype UnsafeValue : UnsafeSvProtocol
}

extension PerlDerived where Self : PerlValue {
	init(_noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		guard sv.pointee.type == UnsafeValue.type else {
			throw PerlError.unexpectedSvType(promoteFromUnsafeSV(noinc: sv, perl: perl), want: UnsafeValue.type)
		}
		self.init(noincUnchecked: sv, perl: perl)
	}
}

extension PerlDerived where Self : PerlValue, UnsafeValue : UnsafeSvCastable {
	init(inc xv: UnsafeMutablePointer<UnsafeValue>, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		let sv = UnsafeMutableRawPointer(xv).bindMemory(to: UnsafeSV.self, capacity: 1)
		self.init(incUnchecked: sv, perl: perl)
	}

	init(noinc xv: UnsafeMutablePointer<UnsafeValue>, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		let sv = UnsafeMutableRawPointer(xv).bindMemory(to: UnsafeSV.self, capacity: 1)
		self.init(noincUnchecked: sv, perl: perl)
	}

	init?(_ sv: PerlSV) throws {
		defer { _fixLifetime(sv) }
		let (usv, perl) = sv.withUnsafeSvPointer { $0 }
		guard let uxv = try UnsafeMutablePointer<UnsafeValue>(autoDeref: usv, perl: perl) else { return nil }
		self.init(inc: uxv, perl: perl)
	}
}
