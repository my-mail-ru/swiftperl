/// Enumeration of the possible errors.
public enum PerlError : Error {
	/// A `die` occurred in Perl. Text of the error or a SV die was called with
	/// will be in an associated value.
	case died(_: PerlScalar)

	/// A stack count is lower then an `at`.
	case noArgumentOnStack(at: Int)

	/// An undefined value was received in place not supposed to.
	case unexpectedUndef(_: AnyPerl)

	/// SV of an unexpected type was recevied.
	case unexpectedSvType(_: AnyPerl, want: SvType)

	/// SV is not a number, but we suppose it to be.
	case notNumber(_: AnyPerl)

	/// SV is not a string or a number, but we suppose it to be.
	case notStringOrNumber(_: AnyPerl)

	/// SV is not an object, but we suppose it to be.
	case notObject(_: AnyPerl)

	/// SV is not a wrapped Swift object, but we suppose it to be.
	case notSwiftObject(_: AnyPerl)

	/// SV bridges to an object of an unexpected type.
	case unexpectedObjectType(_: AnyPerl, want: AnyPerl.Type)

	/// Odd number of elements in hash assignment.
	case oddElementsHash
}
