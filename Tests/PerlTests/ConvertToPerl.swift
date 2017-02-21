import XCTest
import Perl

class ConvertToPerlTests : EmbeddedTestCase {
	static var allTests: [(String, (ConvertToPerlTests) -> () throws -> Void)] {
		return [
			("testUndef", testUndef),
			("testBool", testBool),
			("testInt", testInt),
			("testDouble", testDouble),
			("testString", testString),
			("testScalarRef", testScalarRef),
			("testArrayRef", testArrayRef),
			("testHashRef", testHashRef),
			("testXSub", testXSub),
		]
	}

	func testUndef() throws {
		let v = PerlScalar()
		XCTAssert(!v.defined)
		try perl.eval("sub is_defined { return defined $_[0] }")
		XCTAssert(try !perl.call(sub: "is_defined", v))
		let s = PerlScalar(10)
		s.set(nil)
		XCTAssert(try !perl.call(sub: "is_defined", s))
	}

	func testBool() throws {
		try perl.eval("sub is_true { return $_[0] eq '1' }")
		try perl.eval("sub is_false { return $_[0] eq '' }")
		XCTAssert(try perl.call(sub: "is_true", PerlScalar(true)))
		XCTAssert(try perl.call(sub: "is_false", PerlScalar(false)))
		let s = PerlScalar()
		s.set(true)
		XCTAssert(try perl.call(sub: "is_true", s))
		s.set(false)
		XCTAssert(try perl.call(sub: "is_false", s))
	}

	func testInt() throws {
		let v = PerlScalar(10)
		XCTAssert(v.isInt)
		try perl.eval("sub is_10 { return $_[0] == 10 }")
		XCTAssert(try perl.call(sub: "is_10", v))
		let s = PerlScalar()
		s.set(10)
		XCTAssert(try perl.call(sub: "is_10", s))
	}

	func testDouble() throws {
		let v = PerlScalar(10.3)
		XCTAssert(v.isDouble)
		try perl.eval("sub is_10dot3 { return $_[0] == 10.3 }")
		XCTAssert(try perl.call(sub: "is_10dot3", v))
		let s = PerlScalar()
		s.set(10.3)
		XCTAssert(try perl.call(sub: "is_10dot3", s))
	}

	func testString() throws {
		let a = PerlScalar("ascii string")
		XCTAssert(a.isString)
		try perl.eval("sub is_ascii_string { return $_[0] eq 'ascii string' }")
		XCTAssert(try perl.call(sub: "is_ascii_string", a))
		let u = PerlScalar("строченька")
		XCTAssert(u.isString)
		try perl.eval("sub is_utf8_string { return $_[0] eq 'строченька' }")
		XCTAssert(try perl.call(sub: "is_utf8_string", u))
		try perl.eval("sub is_byte_string { return $_[0] eq pack('C256', 0..255) }")
		let b = [UInt8](0...255).withUnsafeBytes { PerlScalar($0) }
		XCTAssert(try perl.call(sub: "is_byte_string", b))
		let c = [UInt8]("строченька".utf8).withUnsafeBytes { PerlScalar($0, containing: .characters) }
		XCTAssert(try perl.call(sub: "is_utf8_string", c))
		let s = PerlScalar()
		s.set("строченька")
		XCTAssert(try perl.call(sub: "is_utf8_string", s))
		[UInt8](0...255).withUnsafeBytes { s.set($0) }
		XCTAssert(try perl.call(sub: "is_byte_string", s))
	}

	func testScalarRef() throws {
		let v = PerlScalar(referenceTo: PerlScalar(10 as Int))
		XCTAssert(v.isRef)
		try perl.eval("sub is_ref_10 { return ${$_[0]} == 10 }")
		XCTAssert(try perl.call(sub: "is_ref_10", v))
	}

	func testArrayRef() throws {
		let array = [10, 20]
		let v = PerlScalar(referenceTo: PerlArray(array))
		XCTAssert(v.isRef)
		try perl.eval("sub is_array { return @{$_[0]} == 2 && $_[0][0] == 10 && $_[0][1] == 20 }")
		XCTAssert(try perl.call(sub: "is_array", v))
		let v2 = PerlScalar(PerlArray(array))
		XCTAssert(try perl.call(sub: "is_array", v2))
		let v3 = PerlScalar(array)
		XCTAssert(try perl.call(sub: "is_array", v3))
	}

	func testHashRef() throws {
		let dict = ["a": 10, "b": 20]
		let v = PerlScalar(referenceTo: PerlHash(dict))
		XCTAssert(v.isRef)
		try perl.eval("sub is_hash { return keys(%{$_[0]}) == 2 && $_[0]{a} == 10 && $_[0]{b} == 20 }")
		XCTAssert(try perl.call(sub: "is_hash", v))
		let v2 = PerlScalar(PerlHash(dict))
		XCTAssert(try perl.call(sub: "is_hash", v2))
		let v3 = PerlScalar(dict)
		XCTAssert(try perl.call(sub: "is_hash", v3))
	}

	func testXSub() throws {
		PerlSub(name: "testxsub") {
			(a: Int, b: Int) -> Int in
			XCTAssertEqual(a, 10)
			XCTAssertEqual(b, 15)
			return a + b
		}
		XCTAssertEqual(try perl.eval("testxsub(10, 15) == 25 ? 'OK' : 'FAIL'"), "OK")
		PerlSub(name: "testxsub2") {
			(a: Int?, b: Int?) -> Int in
			XCTAssertEqual(a, 10)
			XCTAssertNil(b)
			return a! + (b ?? 15)
		}
		XCTAssertEqual(try perl.eval("testxsub2(10, undef) == 25 ? 'OK' : 'FAIL'"), "OK")

		PerlSub(name: "testarraytail") {
			(a: Int, b: Int, extra: [String]) -> Int in
			XCTAssertEqual(a, 10)
			XCTAssertEqual(b, 15)
			XCTAssertEqual(extra, ["uno", "dos", "tres"])
			return a + b
		}
		XCTAssertEqual(try perl.eval("testarraytail(10, 15, qw/uno dos tres/) == 25 ? 'OK' : 'FAIL'"), "OK")

		PerlSub(name: "testhashtail") {
			(a: Int, b: Int, options: [String: String]) -> Int in
			XCTAssertEqual(a, 10)
			XCTAssertEqual(b, 15)
			XCTAssertEqual(options, ["from": "master", "timeout": "10"])
			return a + b
		}
		XCTAssertEqual(try perl.eval("testhashtail(10, 15, from => 'master', timeout => 10) == 25 ? 'OK' : 'FAIL'"), "OK")

		PerlSub(name: "testplain") {
			(args: [PerlScalar]) -> Int in
			XCTAssertEqual(try Int(args[0]), 10)
			XCTAssertEqual(try Int(args[1]), 15)
			XCTAssertEqual(try String(args[2]), "extra")
			return try Int(args[0]) + Int(args[1])
		}
		XCTAssertEqual(try perl.eval("testplain(10, 15, 'extra') == 25 ? 'OK' : 'FAIL'"), "OK")

		PerlSub(name: "testlast") {
			(args: [PerlScalar], perl: UnsafeInterpreterPointer) -> [PerlScalar] in
			XCTAssertEqual(try Int(args[0]), 10)
			XCTAssertEqual(try Int(args[1]), 15)
			XCTAssertEqual(try String(args[2]), "extra")
			return [PerlScalar(try Int(args[0]) + Int(args[1]))]
		}
		XCTAssertEqual(try perl.eval("testlast(10, 15, 'extra') == 25 ? 'OK' : 'FAIL'"), "OK")

		PerlSub(name: "testnoarg") {
			(a: Int, b: PerlScalar) -> Int in
			XCTAssertEqual(a, 10)
			XCTAssertTrue(!b.defined)
			return 25
		}
		XCTAssertEqual(try perl.eval("testnoarg(10) == 25 ? 'OK' : 'FAIL'"), "OK")

		let orig = PerlScalar("ololo")
		let origsv = orig.withUnsafeSvPointer { sv, _ in sv }
		try PerlSub { (arg: PerlScalar) -> Void in
			arg.withUnsafeSvPointer { sv, _ in XCTAssertNotEqual(sv, origsv, "Argument SV is not copied") }
		}.call(orig)

		var storedIn: PerlScalar?
		let storedOut: PerlScalar = 40
		PerlSub(name: "teststored") {
			(arg: PerlScalar) -> PerlScalar in
			storedIn = arg
			return storedOut
		}
		try perl.eval("my $si = 10; my $so = teststored($si); $si = 20; $so = 50")
		XCTAssertEqual(try Int(storedIn!), 10)
		XCTAssertEqual(try Int(storedOut), 40)
	}
}
