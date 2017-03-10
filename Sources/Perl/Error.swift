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

	/// SV is not a number (integer or double) of appropriate range.
	case notNumber(_: AnyPerl, want: Any.Type)

	/// SV is not a string or a number (integer or double).
	case notStringOrNumber(_: AnyPerl)

	/// SV is not a reference.
	case notReference(_: AnyPerl)

	/// SV is not an object, but we suppose it to be.
	case notObject(_: AnyPerl)

	/// SV is not a wrapped Swift object, but we suppose it to be.
	case notSwiftObject(_: AnyPerl)

	/// SV bridges to an object of an unexpected type.
	case unexpectedObjectType(_: AnyPerl, want: AnyPerl.Type)

	/// Element with the index `at` not exists in the array.
	case elementNotExists(_: PerlArray, at: Int)

	/// Odd number of elements in hash assignment.
	case oddElementsHash
}
