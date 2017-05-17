import XCTest
@testable import Perl

class CallTests : EmbeddedTestCase {
	static var allTests = [
		("testContext", testContext),
	]

	func testContext() throws {
		try perl.eval("sub list1 { return qw/a b c/ }")
		let s1: String = try perl.call(sub: "list1")
		XCTAssertEqual(s1, "c")
		let l1: String = try perl.call(sub: "list1", context: .array)
		XCTAssertEqual(l1, "a")
		let a1 = try perl.call(sub: "list1", context: .array)
		XCTAssertEqual(try a1.map { try String($0) }, ["a", "b", "c"])

		try perl.eval("sub list2 { my @l = qw/a b c/; return @l }")
		let s2: String = try perl.call(sub: "list2")
		XCTAssertEqual(s2, "3")
		let l2: String = try perl.call(sub: "list2", context: .array)
		XCTAssertEqual(l2, "a")
		let a2 = try perl.call(sub: "list2", context: .array)
		XCTAssertEqual(try a2.map { try String($0) }, ["a", "b", "c"])

		let sub3 = PerlSub(name: "list3") { () -> (String, String) in
			return ("a", "b")
		}
		let s3: String = try sub3.call()
		XCTAssertEqual(s3, "b")
		let l3: String = try perl.call(sub: "list3", context: .array)
		XCTAssertEqual(l3, "a")
		let a3 = try perl.call(sub: "list3", context: .array)
		XCTAssertEqual(try a3.map { try String($0) }, ["a", "b"])
	}
}
