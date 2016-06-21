final class URI : PerlObjectType {
	static let perlClassName = "URI"
	let sv: PerlSV
	init(_ sv: PerlSV) { self.sv = sv }

	convenience init(_ str: String) throws {
		self.init(try URI.call(method: "new", str) as PerlSV)
	}

	convenience init(_ str: String, scheme: String) throws {
		self.init(try URI.call(method: "new", str, scheme) as PerlSV)
	}

	convenience init(copyOf uri: URI) {
		self.init(try! uri.call(method: "clone") as PerlSV)
	}

	var scheme: String? { return try! call(method: "scheme") }
	func scheme(_ scheme: String) throws -> String? { return try call(method: "scheme", scheme) }

	var path: String {
		get { return try! call(method: "path") }
		set { try! call(method: "path", newValue) as Void }
	}

	var asString: String { return try! call(method: "as_string") }

	func abs(base: String) -> String { return try! call(method: "abs", base) }
	func rel(base: String) -> String { return try! call(method: "rel", base) }

	var secure: Bool { return try! call(method: "secure") }
}
