import XCTest
import Perl

class EmbeddedTestCase : XCTestCase {
	var perl: PerlInterpreter!

	override func setUp() {
		perl = PerlInterpreter.new()
		PerlInterpreter.current = perl
	}

	override func tearDown() {
		perl.destroy()
	}
}
