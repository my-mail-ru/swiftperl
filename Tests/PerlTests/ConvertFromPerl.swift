import XCTest
import Perl

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
		let v: PerlScalar = try perl.eval("undef")
		XCTAssert(!v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertNil(Int(nilable: v))
		XCTAssertNil(String(nilable: v))
		XCTAssertEqual(Int(unchecked: v), 0)
		XCTAssertEqual(String(unchecked: v), "")
	}

	func testInt() throws {
		let v: PerlScalar = try perl.eval("42")
		XCTAssert(v.defined)
		XCTAssert(v.isInt)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(try Int(v), 42)
		XCTAssertEqual(try String(v), "42")
	}

	func testString() throws {
		let v: PerlScalar = try perl.eval("'test'")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(try Int(v), 0)
		XCTAssertEqual(try String(v), "test")
		XCTAssertEqual(try String(v), "test")
		let u: PerlScalar = try perl.eval("'строченька'")
		XCTAssertEqual(try String(u), "строченька")
		let n: PerlScalar = try perl.eval("'null' . chr(0) . 'sepparated'")
		XCTAssertEqual(try String(n), "null\0sepparated")
	}

	func testScalarRef() throws {
		let v: PerlScalar = try perl.eval("\\42")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(!v.isString)
		XCTAssert(v.isRef)
		XCTAssertNotNil(v.referent)
		let r = v.referent! as! PerlScalar
		XCTAssert(r.isInt)
		XCTAssertEqual(try Int(r), 42)
	}

	func testArrayRef() throws {
		let sv: PerlScalar = try perl.eval("[42, 'str']")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let av: PerlArray = try PerlArray(sv)!
		XCTAssertEqual(av.count, 2)
		XCTAssertEqual(try Int(av[0]), 42)
		XCTAssertEqual(try String(av[1]), "str")
		let strs: [String] = try [String](sv)!
		XCTAssertEqual(strs, ["42", "str"])
		XCTAssertEqual(try [String](av), ["42", "str"])
		XCTAssertEqual(try [String](sv)!, ["42", "str"])

		let i: PerlScalar = try perl.eval("[42, 15, 10]")
		let ints: [Int] = try [Int](i)!
		XCTAssertEqual(ints, [42, 15, 10])

		let s: PerlScalar = try perl.eval("[qw/one two three/]")
		let strings: [String] = try [String](s)!
		XCTAssertEqual(strings, ["one", "two", "three"])
	}

	func testHashRef() throws {
		let sv: PerlScalar = try perl.eval("{ one => 1, two => 2 }")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let hv: PerlHash = try PerlHash(sv)!
//		XCTAssertEqual(hv.count, 2)
		XCTAssertEqual(try Int(hv["one"]!), 1)
		XCTAssertEqual(try Int(hv["two"]!), 2)
//		let hd: [String: Int] = try [String: Int](hv)
//		XCTAssertEqual(hd, ["one": 1, "two": 2])
		let sd: [String: Int] = try [String: Int](sv)!
		XCTAssertEqual(sd, ["one": 1, "two": 2])
		XCTAssertEqual(sd, ["one": 1, "two": 2])
		XCTAssertEqual(try [String: Int](hv), ["one": 1, "two": 2])
		XCTAssertEqual(try [String: Int](sv)!, ["one": 1, "two": 2])
	}

	func testCodeRef() throws {
		let sv: PerlScalar = try perl.eval("sub { my ($c, $d) = @_; return $c + $d }")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInt)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let cv: PerlSub = try PerlSub(sv)!
		XCTAssertEqual(try cv.call(10, 15) as Int?, 25)
//		XCTAssertEqual(try sv.call(10, 15) as Int, 25)
	}

	func testXSub() throws {
		PerlSub(name: "testxsub") {
			(a: Int, b: Int) -> Int in
			return a + b
		}
		let ok: String? = try perl.eval("testxsub(10, 15) == 25 ? 'OK' : 'FAIL'")
		XCTAssertEqual(ok, "OK")
	}

	func testInterpreterMisc() throws {
		try perl.eval("use utf8; $тест = 'OK'")
		let sv = perl.getSV("тест")
		XCTAssertNotNil(sv)
		XCTAssertEqual(try String(sv!), "OK")
//		perl.pointer.pointee.loadModule("Nothing")
	}
}
