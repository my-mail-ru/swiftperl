enum PerlError : Error {
	case died(_: PerlSV)
	case unexpectedUndef(_: PerlSV)
	case unexpectedType(_: PerlSV, want: SvType)
	case notObject(_: PerlSV)
	case notSwiftObject(_: PerlSV)
	case unsupportedPerlClass(_: PerlSV)
	case unexpectedObjectType(_: PerlSV)
}

extension PerlError : CustomDebugStringConvertible {
	var debugDescription: String {
		switch self {
			case .died(let sv):
				return "PerlError: \(String(sv))"
			default:
				return "\(self)"
		}
	}
}
