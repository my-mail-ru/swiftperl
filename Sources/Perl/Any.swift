protocol AnyPerl : class {}

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
