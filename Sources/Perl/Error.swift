enum PerlError : Error {
	case died(_: PerlSV)
	case notRV(_: PerlSV)
	case notAV(_: PerlSV)
	case notHV(_: PerlSV)
	case notCV(_: PerlSV)
	case notObject(_: PerlSV)
	case notSwiftObject(_: PerlSV)
	case unexpectedSwiftObject(_: PerlSV)
	case unsupportedPerlClass(_: PerlSV)
	case unexpectedPerlClass(_: PerlSV)
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
