public protocol PerlDerived : PerlSvConvertible {
	associatedtype UnsafeValue : UnsafeSvProtocol
}

extension PerlDerived where Self : PerlValue, UnsafeValue : UnsafeSvCastable {
	public init(_ ref: PerlScalar) throws {
		defer { _fixLifetime(ref) }
		let svc = try ref.withReferentUnsafeSvContext(type: UnsafeValue.type) { $0 }
		self.init(incUnchecked: svc)
	}
}
