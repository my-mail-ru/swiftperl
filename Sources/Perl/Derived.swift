public protocol PerlDerived : PerlSvConvertible {
	associatedtype UnsafeValue : UnsafeSvProtocol
}

extension PerlDerived where Self : PerlValue {
	init(_noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		guard sv.pointee.type == UnsafeValue.type else {
			throw PerlError.unexpectedSvType(fromUnsafeSvPointer(noinc: sv, perl: perl), want: UnsafeValue.type)
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

	public init(_ ref: PerlScalar) throws {
		defer { _fixLifetime(ref) }
		let (sv, perl) = try ref.withReferentUnsafeSvPointer(type: UnsafeValue.type) { $0 }
		self.init(incUnchecked: sv, perl: perl)
	}
}
