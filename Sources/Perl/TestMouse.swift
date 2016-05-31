final class PerlTestMouse: PerlObjectType {
	static let perlClassName = "TestMouse"
	let sv: PerlSV
	init(_ sv: PerlSV) { self.sv = sv }

	var `attr_ro`: Int {
		get { return try! call(method: "attr_ro") }
	}
	var `attr_rw`: String {
		get { return try! call(method: "attr_rw") }
		set { try! call(method: "attr_rw", args: newValue) as Void }
	}
	var `maybe`: Int? {
		get { return try! call(method: "maybe") }
	}
	var `class`: String {
		get { return try! call(method: "class") }
	}
	var `maybe_class`: String? {
		get { return try! call(method: "maybe_class") }
	}
	var `list`: PerlAV {
		get { return try! call(method: "list") }
	}
	var `hash`: PerlHV {
		get { return try! call(method: "hash") }
	}
}

extension PerlTestMouse {
	func doSomething(_ v1: Int, _ v2: String) throws -> String {
		return try call(method: "do_something", args: v1, v2)
	}
	var `listOfStrings`: [String] {
		get { return try! call(method: "list") }
	}
}
