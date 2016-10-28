import XCTest
import Perl
import PerlCoro

class EmbeddedTestCase : XCTestCase {
	var perl: PerlInterpreter!

	override func setUp() {
		perl = PerlInterpreter()
		perl.withUnsafeInterpreterPointer {
			UnsafeInterpreter.current = $0
		}
	}

	override func tearDown() {
		perl = nil
	}
}

class PerlCoroTests : EmbeddedTestCase {
	static var allTests: [(String, (PerlCoroTests) -> () throws -> Void)] {
		return [
			("testCoro", testCoro),
		]
	}

	func testCoro() throws {
		perl.withUnsafeInterpreterPointer {
			UnsafeInterpreter.main = $0
		}
		try PerlCoro.initialize()
		var result = [Int]()
		let c1 = PerlCoro(PerlSub {
			(a: Int, b: Int) -> Int in
			result.append(1)
			PerlCoro.cede()
			result.append(3)
			return a + b
		}, args: 10, 15)
		c1.ready()
		let c2 = PerlCoro(PerlSub {
			(a: Int, b: Int) -> Int in
			result.append(2)
			PerlCoro.cede()
			result.append(4)
			return a + b
		}, args: 18, 42)
		c2.ready()
		let r1: Int? = c1.join()
		let r2: Int? = c2.join()
		XCTAssertEqual(r1, 25)
		XCTAssertEqual(r2, 60)
		XCTAssertEqual(result, [1, 2, 3, 4])
	}
}
