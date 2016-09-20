import XCTest
@testable import Perl

class EmbeddedTestCase : XCTestCase {
	var perl: PerlInterpreter!

	override func setUp() {
		perl = PerlInterpreter()
		UnsafeInterpreter.current = perl.pointer
	}

	override func tearDown() {
		perl = nil
	}
}
