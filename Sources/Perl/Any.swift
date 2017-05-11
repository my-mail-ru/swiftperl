/// A type that represents any Perl variable.
///
/// There are two major cases when some class conforms to this protocol:
///
/// - An instance of a class contains a native Perl variable (some `SV`).
///   In this case it is derived from `PerlObject`.
/// - A class conforms to `PerlBridgedObject` and its instance contains
///   a native Swift object which can be passed to Perl.
///
/// Making your own custom types conforming to `AnyPerl` protocol is undesirable.
public protocol AnyPerl : class {}

func fromUnsafeSvContext(inc svc: UnsafeSvContext) -> AnyPerl {
	return svc.swiftObject ?? PerlValue.initDerived(inc: svc)
}

func fromUnsafeSvContext(noinc svc: UnsafeSvContext) -> AnyPerl {
	if let obj = svc.swiftObject {
		svc.refcntDec()
		return obj
	} else {
		return PerlValue.initDerived(noinc: svc)
	}
}
