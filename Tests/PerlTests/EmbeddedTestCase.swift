import XCTest
import Perl

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
