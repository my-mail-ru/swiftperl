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

func fromUnsafeSvPointer(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) -> AnyPerl {
	return sv.pointee.swiftObject(perl: perl) ?? PerlValue.initDerived(inc: sv, perl: perl)
}

func fromUnsafeSvPointer(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) -> AnyPerl {
	if let obj = sv.pointee.swiftObject(perl: perl) {
		sv.pointee.refcntDec(perl: perl)
		return obj
	} else {
		return PerlValue.initDerived(noinc: sv, perl: perl)
	}
}
