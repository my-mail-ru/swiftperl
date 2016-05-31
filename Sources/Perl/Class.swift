struct PerlClass {
	let name: String

	init<T: PerlMappedClass>(_ name: String, swiftClass: T.Type) {
		self.name = name
		createXSub("DESTROY") {
			(slf: T) in
			print("DESTROY!!!!!!!")
			let addr = unsafeAddress(of: slf)
			objects[unsafeBitCast(addr, to: Int.self)] = nil
		}
	}

	func createXSub(_ method: String, file: String = #file, body: (PerlStack) -> [PerlSV]) {
		_ = PerlCV(name: name + "::" + method, file: file, body: body)
	}

	func createXSub<T: PerlSVConvertible>(_ method: String, file: String = #file, body: (T) throws -> Void) {
		_ = PerlCV(name: name + "::" + method, file: file, body: body)
	}

	func createXSub<T: PerlSVConvertible, R: PerlSVConvertible>(_ method: String, file: String = #file, body: (T) throws -> R) {
		_ = PerlCV(name: name + "::" + method, file: file, body: body)
	}

	func createXSub<T1: PerlSVConvertible, T2: PerlSVConvertible, R: PerlSVConvertible>(_ method: String, file: String = #file, body: (T1, T2) throws -> R) {
		_ = PerlCV(name: name + "::" + method, file: file, body: body)
	}

	func createXSub<T1: PerlSVConvertible, T2: PerlSVConvertible, T3: PerlSVConvertible, R: PerlSVConvertible>(_ method: String, file: String = #file, body: (T1, T2, T3) throws -> R) {
		_ = PerlCV(name: name + "::" + method, file: file, body: body)
	}
}
