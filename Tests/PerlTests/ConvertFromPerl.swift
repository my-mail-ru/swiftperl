import XCTest
@testable import Perl

class ConvertFromPerlTests : EmbeddedTestCase {
	static var allTests: [(String, (ConvertFromPerlTests) -> () throws -> Void)] {
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
		XCTAssertNil(Int(v))
		XCTAssertNil(String(v))
		XCTAssertEqual(Int(forcing: v), 0)
		XCTAssertEqual(String(forcing: v), "")
	}

	func testInt() throws {
		let v: PerlSV = try perl.eval("42")
		XCTAssert(v.defined)
		XCTAssert(v.isInt)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(Int(v), 42)
		XCTAssertEqual(String(v), "42")
	}

	func testString() throws {
		let v: PerlSV = try perl.eval("'test'")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(Int(v), 0)
		XCTAssertEqual(String(v), "test")
		XCTAssertEqual(String(v), "test")
		let u: PerlSV = try perl.eval("'строченька'")
		XCTAssertEqual(String(u), "строченька")
		let n: PerlSV = try perl.eval("'null' . chr(0) . 'sepparated'")
		XCTAssertEqual(String(n), "null\0sepparated")
	}

	func testScalarRef() throws {
		let v: PerlSV = try perl.eval("\\42")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(!v.isString)
		XCTAssert(v.isRef)
		XCTAssertNotNil(v.referent)
		let r: PerlSV = v.referent!
		XCTAssert(r.isInt)
		XCTAssertEqual(Int(r), 42)
	}

	func testArrayRef() throws {
		let sv: PerlSV = try perl.eval("[42, 'str']")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let av: PerlAV = try PerlAV(sv)!
		XCTAssertEqual(av.count, 2)
		XCTAssertEqual(Int(av[0]), 42)
		XCTAssertEqual(String(av[1]), "str")
		let strs: [String] = try [String](sv)!
		XCTAssertEqual(strs, ["42", "str"])
		XCTAssertEqual([String](av), ["42", "str"])
		XCTAssertEqual(try [String](sv)!, ["42", "str"])

		let i: PerlSV = try perl.eval("[42, 15, 10]")
		let ints: [Int] = try [Int](i)!
		XCTAssertEqual(ints, [42, 15, 10])

		let s: PerlSV = try perl.eval("[qw/one two three/]")
		let strings: [String] = try [String](s)!
		XCTAssertEqual(strings, ["one", "two", "three"])
	}

	func testHashRef() throws {
		let sv: PerlSV = try perl.eval("{ one => 1, two => 2 }")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let hv: PerlHV = try PerlHV(sv)!
//		XCTAssertEqual(hv.count, 2)
		XCTAssertEqual(Int(hv["one"]!), 1)
		XCTAssertEqual(Int(hv["two"]!), 2)
//		let hd: [String: Int] = try [String: Int](hv)
//		XCTAssertEqual(hd, ["one": 1, "two": 2])
		let sd: [String: Int] = try [String: Int](sv)!
		XCTAssertEqual(sd, ["one": 1, "two": 2])
		XCTAssertEqual(sd, ["one": 1, "two": 2])
		XCTAssertEqual([String: Int](hv), ["one": 1, "two": 2])
		XCTAssertEqual(try [String: Int](sv)!, ["one": 1, "two": 2])
	}

	func testCodeRef() throws {
		let sv: PerlSV = try perl.eval("sub { my ($c, $d) = @_; return $c + $d }")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let cv: PerlCV = try PerlCV(sv)!
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
		XCTAssertEqual(String(sv!), "OK")
//		perl.pointer.pointee.loadModule("Nothing")
	}
}
