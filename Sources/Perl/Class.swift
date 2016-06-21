extension PerlMappedClass {
	static func createPerlMethod<T: PerlSVConvertible>(_ method: String, file: StaticString = #file, body: (T) throws -> Void) {
		PerlCV(name: perlClassName + "::" + method, file: file, body: body)
	}

	static func createPerlMethod<T: PerlSVConvertible, R: PerlSVConvertible>(_ method: String, file: StaticString = #file, body: (T) throws -> R) {
		PerlCV(name: perlClassName + "::" + method, file: file, body: body)
	}

	static func createPerlMethod<T1: PerlSVConvertible, T2: PerlSVConvertible, R: PerlSVConvertible>(_ method: String, file: StaticString = #file, body: (T1, T2) throws -> R) {
		PerlCV(name: perlClassName + "::" + method, file: file, body: body)
	}

	static func createPerlMethod<T1: PerlSVConvertible, T2: PerlSVConvertible, T3: PerlSVConvertible, R: PerlSVConvertible>(_ method: String, file: StaticString = #file, body: (T1, T2, T3) throws -> R) {
		PerlCV(name: perlClassName + "::" + method, file: file, body: body)
	}

	static func createPerlMethod<R: Collection where R.Iterator.Element == PerlSV>
		(_ method: String, file: StaticString = #file, body: (ContiguousArray<PerlSV>) throws -> R) {
		PerlCV(name: perlClassName + "::" + method, file: file, body: body)
	}
}
