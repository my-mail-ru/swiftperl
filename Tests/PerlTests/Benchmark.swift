import XCTest
import Perl

class BenchmarkTests : EmbeddedTestCase {
	static var allTests: [(String, (BenchmarkTests) -> () throws -> Void)] {
		return [
			("testBenchmarkPerlOnly", testBenchmarkPerlOnly),
			("testBenchmarkCallPerl", testBenchmarkCallPerl),
			("testBenchmarkCallFromPerl", testBenchmarkCallFromPerl),
		]
	}

	func testBenchmarkPerlOnly() throws {
		_ = try perl.eval("sub test { my ($c, $d) = @_; return $c + $d }")
		let sv: PerlSV = try perl.eval("my $s; for (1..100000) { $s = test(10, 15) } $s")
		XCTAssertEqual(try Int(sv), 25)
	}

	func testBenchmarkCallPerl() throws {
		let sv: PerlSV = try perl.eval("sub test { my ($c, $d) = @_; return $c + $d } \\&test")
		let cv: PerlCV = try PerlCV(sv)!
		var s: Int?
		for _ in 1...100000 {
			s = try cv.call(10, 15)
		}
		XCTAssertEqual(s, 25)
	}

	func testBenchmarkCallFromPerl() throws {
		_ = PerlCV(name: "test") {
			(c: Int, d: Int) -> Int in
			return c + d
		}
		let sv: PerlSV = try perl.eval("my $s; for (1..100000) { $s = test(10, 15) } $s")
		XCTAssertEqual(try Int(sv), 25)
	}
/*
	func testBenchmarkPerlOnly() {
		_ = perl.eval("sub test { my ($f, $c, $d) = @_; return $f . ($c + $d) }")
		let sv = perl.eval("my $str; for (1..100000) { $str = test('value: ', 10, 15) } $str")
		XCTAssertEqual(String(sv), "value: 25")
	}

	func testBenchmarkCallPerl() throws {
//		_ = perl.eval("sub test { my ($f, $c, $d) = @_; return $f . ($c + $d) }")
		let sv = perl.eval("sub test { my ($f, $c, $d) = @_; return $f . ($c + $d) } \\&test")
		let cv: PerlCV = try sv.value()
		var str: String?
		for _ in 1...100000 {
//			str = try PerlInterpreter.call(sub: "test", args: "value: ", 10, 15)
			str = try cv.call("value: ", 10, 15)
		}
		XCTAssertEqual(str, "value: 25")
	}

	func testBenchmarkCallFromPerl() {
		_ = PerlCV(name: "test") {
			(f: String, c: Int, d: Int) -> String in
			return f + String(c + d)
		}
		let sv = perl.eval("my $str; for (1..100000) { $str = test('value: ', 10, 15) } $str")
		XCTAssertEqual(String(sv), "value: 25")
	}

	func testBenchmarkPerlOnly() {
		_ = perl.eval("sub test { return }")
		_ = perl.eval("for (1..1000000) { test() }")
	}

	func testBenchmarkCallPerl() throws {
//		_ = perl.eval("sub test { return }")
		let sv = perl.eval("sub test { return }; \\&test")
		let cv: PerlCV = try sv.value()
		for _ in 1...1000000 {
//			try PerlInterpreter.call(sub: "test") as Void
			try cv.call()
		}
	}

	func testBenchmarkCallFromPerl() {
		_ = PerlCV(name: "test") {
			() throws -> () in ()
		}
		_ = perl.eval("for (1..1000000) { test() }")
	}
*/
}
