import XCTest
import Perl

class EmbedTests: XCTestCase {
	func testEmbedding() throws {
		let perl = PerlInterpreter()
		perl.withUnsafeInterpreterPointer {
			UnsafeInterpreter.current = $0
		}
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
