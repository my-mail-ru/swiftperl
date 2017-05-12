import XCTest
import Perl

class EmbedTests: XCTestCase {
	func testEmbedding() throws {
		let perl = PerlInterpreter.new()
		defer { perl.destroy() }
		PerlInterpreter.current = perl
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
