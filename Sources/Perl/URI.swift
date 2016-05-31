final class URI : PerlObjectType {
	static let perlClassName = "URI"
	let sv: PerlSV
	init(_ sv: PerlSV) { self.sv = sv }

	convenience init(_ str: String) throws {
		self.init(try URI.call(method: "new", args: str) as PerlSV)
	}

	convenience init(_ str: String, scheme: String) throws {
		self.init(try URI.call(method: "new", args: str, scheme) as PerlSV)
	}

	convenience init(copyOf uri: URI) {
		self.init(try! uri.call(method: "clone") as PerlSV)
	}

	var scheme: String? { return try! call(method: "scheme") }
	func scheme(_ scheme: String) throws -> String? { return try call(method: "scheme", args: scheme) }

	var path: String {
		get { return try! call(method: "path") }
		set { try! call(method: "path", args: newValue) as Void }
	}

	var asString: String { return try! call(method: "as_string") }

	func abs(base: String) -> String { return try! call(method: "abs", args: base) }
	func rel(base: String) -> String { return try! call(method: "rel", args: base) }

	var secure: Bool { return try! call(method: "secure") }
}
