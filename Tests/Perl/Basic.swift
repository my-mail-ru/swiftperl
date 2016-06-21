import XCTest
@testable import Perl

class BasicTests : EmbeddedTestCase {
	static var allTests: [(String, (BasicTests) -> () throws -> Void)] {
		return [
			("testUndef", testUndef),
			("testInt", testInt),
			("testString", testString),
			("testScalarRef", testScalarRef),
			("testArrayRef", testArrayRef),
			("testHashRef", testHashRef),
			("testCodeRef", testCodeRef),
			("testXSub", testXSub),
			("testInterpreterMisc", testInterpreterMisc),
		]
	}

	func testUndef() throws {
		let v: PerlSV = try perl.eval("undef")
		XCTAssert(!v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(v.value() as Int, 0)
		XCTAssertEqual(v.value() as String, "")
	}

	func testInt() throws {
		let v: PerlSV = try perl.eval("42")
		XCTAssert(v.defined)
		XCTAssert(v.isInt)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(v.value() as Int, 42)
		XCTAssertEqual(v.value() as String, "42")
		XCTAssertEqual(Int(v), 42)
	}

	func testString() throws {
		let v: PerlSV = try perl.eval("'test'")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(v.value() as Int, 0)
		XCTAssertEqual(v.value() as String, "test")
		XCTAssertEqual(String(v), "test")
		let u: PerlSV = try perl.eval("'строченька'")
		XCTAssertEqual(u.value() as String, "строченька")
		let n: PerlSV = try perl.eval("'null' . chr(0) . 'sepparated'")
		XCTAssertEqual(n.value() as String, "null\0sepparated")
	}

	func testScalarRef() throws {
		let v: PerlSV = try perl.eval("\\42")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(!v.isString)
		XCTAssert(v.isRef)
		XCTAssertNotNil(v.refValue)
		let r: PerlSV = v.refValue!
		XCTAssert(r.isInt)
		XCTAssertEqual(r.value() as Int, 42)
	}

	func testArrayRef() throws {
		let sv: PerlSV = try perl.eval("[42, 'str']")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.refValue)
		let av: PerlAV = try sv.value()
		XCTAssertEqual(av.count, 2)
		XCTAssertEqual(av[0].value() as Int, 42)
		XCTAssertEqual(av[1].value() as String, "str")
		let strs: [String] = try sv.value()
		XCTAssertEqual(strs, ["42", "str"])
		XCTAssertEqual([String](av), ["42", "str"])
		XCTAssertEqual(try [String](sv), ["42", "str"])

		let i: PerlSV = try perl.eval("[42, 15, 10]")
		let ints: [Int] = try i.value()
		XCTAssertEqual(ints, [42, 15, 10])

		let s: PerlSV = try perl.eval("[qw/one two three/]")
		let strings: [String] = try s.value()
		XCTAssertEqual(strings, ["one", "two", "three"])
	}

	func testHashRef() throws {
		let sv: PerlSV = try perl.eval("{ one => 1, two => 2 }")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.refValue)
		let hv: PerlHV = try sv.value()
//		XCTAssertEqual(hv.count, 2)
		XCTAssertEqual(hv["one"]!.value() as Int, 1)
		XCTAssertEqual(hv["two"]!.value() as Int, 2)
//		let hd: [String: Int] = try hv.value()
//		XCTAssertEqual(hd, ["one": 1, "two": 2])
		let sd: [String: Int] = try sv.value()
		XCTAssertEqual(sd, ["one": 1, "two": 2])
		XCTAssertEqual(sd, ["one": 1, "two": 2])
		XCTAssertEqual([String: Int](hv), ["one": 1, "two": 2])
		XCTAssertEqual(try [String: Int](sv), ["one": 1, "two": 2])
	}

	func testCodeRef() throws {
		let sv: PerlSV = try perl.eval("sub { my ($c, $d) = @_; return $c + $d }")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.refValue)
		let cv: PerlCV = try sv.value()
		XCTAssertEqual(try cv.call(10, 15) as Int?, 25)
//		XCTAssertEqual(try sv.call(10, 15) as Int, 25)
	}

	func testXSub() throws {
		PerlCV(name: "testxsub") {
			(a: Int, b: Int) -> Int in
			return a + b
		}
		let ok: String? = try perl.eval("testxsub(10, 15) == 25 ? 'OK' : 'FAIL'")
		XCTAssertEqual(ok, "OK")
	}

	func testInterpreterMisc() throws {
		try perl.eval("use utf8; $тест = 'OK'")
		let sv = perl.pointer.pointee.getSV("тест")
		XCTAssertNotNil(sv)
		XCTAssertEqual(try String(sv!), "OK") // FIXME try ????
//		perl.pointer.pointee.loadModule("Nothing")
	}
}
