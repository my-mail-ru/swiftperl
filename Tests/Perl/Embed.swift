import XCTest
@testable import Perl

class EmbedTests: XCTestCase {
	func testEmbedding() throws {
		let perl = PerlInterpreter()
		UnsafeInterpreter.current = perl.pointer
		let ok: String = try perl.eval("'OK'")
		XCTAssertEqual(ok, "OK")
	}
}

extension EmbedTests {
	static var allTests: [(String, (EmbedTests) -> () throws -> Void)] {
		return [
			("testEmbedding", testEmbedding)
		]
	}
}
