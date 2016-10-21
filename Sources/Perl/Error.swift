public enum PerlError : Error {
	case died(_: PerlSV)
	case unexpectedUndef(_: AnyPerl)
	case unexpectedSvType(_: AnyPerl, want: SvType)
	case notObject(_: AnyPerl)
	case notSwiftObject(_: AnyPerl)
	case unexpectedObjectType(_: AnyPerl, want: AnyPerl.Type)
}
