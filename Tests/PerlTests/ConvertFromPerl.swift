import XCTest
import Perl

class ConvertFromPerlTests : EmbeddedTestCase {
	static var allTests: [(String, (ConvertFromPerlTests) -> () throws -> Void)] {
		return [
			("testUndef", testUndef),
			("testBool", testBool),
			("testInt", testInt),
			("testDouble", testDouble),
			("testString", testString),
			("testScalarRef", testScalarRef),
			("testArrayRef", testArrayRef),
			("testHashRef", testHashRef),
			("testCodeRef", testCodeRef),
			("testInterpreterMisc", testInterpreterMisc),
		]
	}

	func testUndef() throws {
		let v: PerlScalar = try perl.eval("undef")
		XCTAssert(!v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(!v.isDouble)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertNil(try Int(nilable: v))
		XCTAssertNil(try Double(nilable: v))
		XCTAssertNil(try String(nilable: v))
		XCTAssertEqual(Int(unchecked: v), 0)
		XCTAssertEqual(Double(unchecked: v), 0)
		XCTAssertEqual(String(unchecked: v), "")
	}

	func testBool() throws {
		// Conversion directly from UnsafeSvPointer
		XCTAssertFalse(try perl.eval("undef"))
		XCTAssertFalse(try perl.eval("0"))
		XCTAssertFalse(try perl.eval("''"))
		XCTAssertFalse(try perl.eval("'0'"))
		XCTAssertTrue(try perl.eval("1"))
		XCTAssertTrue(try perl.eval("'1'"))
		XCTAssertTrue(try perl.eval("100"))
		XCTAssertTrue(try perl.eval("'100'"))
		XCTAssertTrue(try perl.eval("'000'"))
		XCTAssertTrue(try perl.eval("'anything'"))
		// Convertion from PerlScalar
		XCTAssertFalse(Bool(try perl.eval("undef") as PerlScalar))
		XCTAssertFalse(Bool(try perl.eval("0") as PerlScalar))
		XCTAssertFalse(Bool(try perl.eval("''") as PerlScalar))
		XCTAssertFalse(Bool(try perl.eval("'0'") as PerlScalar))
		XCTAssertTrue(Bool(try perl.eval("1") as PerlScalar))
		XCTAssertTrue(Bool(try perl.eval("'1'") as PerlScalar))
		XCTAssertTrue(Bool(try perl.eval("100") as PerlScalar))
		XCTAssertTrue(Bool(try perl.eval("'100'") as PerlScalar))
		XCTAssertTrue(Bool(try perl.eval("'000'") as PerlScalar))
		XCTAssertTrue(Bool(try perl.eval("'anything'") as PerlScalar))
	}

	func testInt() throws {
		let v: PerlScalar = try perl.eval("42")
		XCTAssert(v.defined)
		XCTAssert(v.isInt)
		XCTAssert(!v.isDouble)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(try Int(v), 42)
		XCTAssertEqual(try String(v), "42")
		// Implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("42") as Int, 42)
		XCTAssertEqual(try perl.eval("'42'") as Int, 42)
		XCTAssertEqual(try perl.eval("42.5") as Int, 42)
		XCTAssertThrowsError(try perl.eval("undef") as Int)
		XCTAssertThrowsError(try perl.eval("''") as Int)
		XCTAssertThrowsError(try perl.eval("'ololo'") as Int)
		XCTAssertThrowsError(try perl.eval("'50sec'") as Int)
		// Nilable implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("42") as Int?, 42)
		XCTAssertEqual(try perl.eval("'42'") as Int?, 42)
		XCTAssertEqual(try perl.eval("42.5") as Int?, 42)
		XCTAssertNil(try perl.eval("undef") as Int?)
		XCTAssertThrowsError(try perl.eval("''") as Int?)
		XCTAssertThrowsError(try perl.eval("'ololo'") as Int?)
		XCTAssertThrowsError(try perl.eval("'50sec'") as Int?)
		// Conversion from PerlScalar
		XCTAssertEqual(try Int(try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(try Int(try perl.eval("'42'") as PerlScalar), 42)
		XCTAssertEqual(try Int(try perl.eval("42.5") as PerlScalar), 42)
		XCTAssertThrowsError(try Int(try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try Int(try perl.eval("''") as PerlScalar))
		XCTAssertThrowsError(try Int(try perl.eval("'ololo'") as PerlScalar))
		XCTAssertThrowsError(try Int(try perl.eval("'50sec'") as PerlScalar))
		// Nilable conversion from PerlScalar
		XCTAssertEqual(try Int(nilable: try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(try Int(nilable: try perl.eval("'42'") as PerlScalar), 42)
		XCTAssertEqual(try Int(nilable: try perl.eval("42.5") as PerlScalar), 42)
		XCTAssertNil(try Int(nilable: try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try Int(nilable: try perl.eval("''") as PerlScalar))
		XCTAssertThrowsError(try Int(nilable: try perl.eval("'ololo'") as PerlScalar))
		XCTAssertThrowsError(try Int(nilable: try perl.eval("'50sec'") as PerlScalar))
		// Unchecked conversion from PerlScalar
		XCTAssertEqual(Int(unchecked: try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(Int(unchecked: try perl.eval("'42'") as PerlScalar), 42)
		XCTAssertEqual(Int(unchecked: try perl.eval("42.5") as PerlScalar), 42)
		XCTAssertEqual(Int(unchecked: try perl.eval("undef") as PerlScalar), 0)
		XCTAssertEqual(Int(unchecked: try perl.eval("''") as PerlScalar), 0)
		XCTAssertEqual(Int(unchecked: try perl.eval("'ololo'") as PerlScalar), 0)
		XCTAssertEqual(Int(unchecked: try perl.eval("'50sec'") as PerlScalar), 50)
	}

	func testDouble() throws {
		let v: PerlScalar = try perl.eval("42.3")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(v.isDouble)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(try Double(v), 42.3)
		XCTAssertEqual(try String(v), "42.3")
		// Implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("42.3") as Double, 42.3)
		XCTAssertEqual(try perl.eval("'42.3'") as Double, 42.3)
		XCTAssertEqual(try perl.eval("42") as Double, 42)
		XCTAssertThrowsError(try perl.eval("undef") as Double)
		XCTAssertThrowsError(try perl.eval("''") as Double)
		XCTAssertThrowsError(try perl.eval("'ololo'") as Double)
		XCTAssertThrowsError(try perl.eval("'50sec'") as Double)
		// Nilable implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("42.3") as Double?, 42.3)
		XCTAssertEqual(try perl.eval("'42.3'") as Double?, 42.3)
		XCTAssertEqual(try perl.eval("42") as Double?, 42)
		XCTAssertNil(try perl.eval("undef") as Double?)
		XCTAssertThrowsError(try perl.eval("''") as Double?)
		XCTAssertThrowsError(try perl.eval("'ololo'") as Double?)
		XCTAssertThrowsError(try perl.eval("'50sec'") as Double?)
		// Conversion from PerlScalar
		XCTAssertEqual(try Double(try perl.eval("42.3") as PerlScalar), 42.3)
		XCTAssertEqual(try Double(try perl.eval("'42.3'") as PerlScalar), 42.3)
		XCTAssertEqual(try Double(try perl.eval("42") as PerlScalar), 42)
		XCTAssertThrowsError(try Double(try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try Double(try perl.eval("''") as PerlScalar))
		XCTAssertThrowsError(try Double(try perl.eval("'ololo'") as PerlScalar))
		XCTAssertThrowsError(try Double(try perl.eval("'50sec'") as PerlScalar))
		// Nilable conversion from PerlScalar
		XCTAssertEqual(try Double(nilable: try perl.eval("42.3") as PerlScalar), 42.3)
		XCTAssertEqual(try Double(nilable: try perl.eval("'42.3'") as PerlScalar), 42.3)
		XCTAssertEqual(try Double(nilable: try perl.eval("42") as PerlScalar), 42)
		XCTAssertNil(try Double(nilable: try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try Double(nilable: try perl.eval("''") as PerlScalar))
		XCTAssertThrowsError(try Double(nilable: try perl.eval("'ololo'") as PerlScalar))
		XCTAssertThrowsError(try Double(nilable: try perl.eval("'50sec'") as PerlScalar))
		// Unchecked conversion from PerlScalar
		XCTAssertEqual(Double(unchecked: try perl.eval("42.3") as PerlScalar), 42.3)
		XCTAssertEqual(Double(unchecked: try perl.eval("'42.3'") as PerlScalar), 42.3)
		XCTAssertEqual(Double(unchecked: try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(Double(unchecked: try perl.eval("undef") as PerlScalar), 0)
		XCTAssertEqual(Double(unchecked: try perl.eval("''") as PerlScalar), 0)
		XCTAssertEqual(Double(unchecked: try perl.eval("'ololo'") as PerlScalar), 0)
		XCTAssertEqual(Double(unchecked: try perl.eval("'50sec'") as PerlScalar), 50)
		XCTAssertEqual(Double(unchecked: try perl.eval("'50.3sec'") as PerlScalar), 50.3)
	}

	func testString() throws {
		let v: PerlScalar = try perl.eval("'test'")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(!v.isDouble)
		XCTAssert(v.isString)
		XCTAssert(!v.isRef)
		XCTAssertThrowsError(try Int(v))
		XCTAssertThrowsError(try Double(v))
		XCTAssertEqual(try String(v), "test")
		XCTAssertEqual(try String(v), "test")
		let u: PerlScalar = try perl.eval("'строченька'")
		XCTAssertEqual(try String(u), "строченька")
		let n: PerlScalar = try perl.eval("'null' . chr(0) . 'sepparated'")
		XCTAssertEqual(try String(n), "null\0sepparated")
		// Implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("'anything'") as String, "anything")
		XCTAssertEqual(try perl.eval("42") as String, "42")
		XCTAssertEqual(try perl.eval("42.5") as String, "42.5")
		XCTAssertThrowsError(try perl.eval("undef") as String)
		XCTAssertThrowsError(try perl.eval("\\10") as String)
		// Nilable implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("'anything'") as String?, "anything")
		XCTAssertEqual(try perl.eval("42") as String?, "42")
		XCTAssertEqual(try perl.eval("42.5") as String?, "42.5")
		XCTAssertNil(try perl.eval("undef") as String?)
		XCTAssertThrowsError(try perl.eval("\\10") as String?)
		// Conversion from PerlScalar
		XCTAssertEqual(try String(try perl.eval("'anything'") as PerlScalar), "anything")
		XCTAssertEqual(try String(try perl.eval("42") as PerlScalar), "42")
		XCTAssertEqual(try String(try perl.eval("42.5") as PerlScalar), "42.5")
		XCTAssertThrowsError(try String(try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try String(try perl.eval("\\10") as PerlScalar))
		// Nilable conversion from PerlScalar
		XCTAssertEqual(try String(nilable: try perl.eval("'anything'") as PerlScalar), "anything")
		XCTAssertEqual(try String(nilable: try perl.eval("42") as PerlScalar), "42")
		XCTAssertEqual(try String(nilable: try perl.eval("42.5") as PerlScalar), "42.5")
		XCTAssertNil(try String(nilable: try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try String(nilable: try perl.eval("\\10") as PerlScalar))
		// Unchecked conversion from PerlScalar
		XCTAssertEqual(String(unchecked: try perl.eval("'anything'") as PerlScalar), "anything")
		XCTAssertEqual(String(unchecked: try perl.eval("42") as PerlScalar), "42")
		XCTAssertEqual(String(unchecked: try perl.eval("42.5") as PerlScalar), "42.5")
		XCTAssertEqual(String(unchecked: try perl.eval("undef") as PerlScalar), "")
		XCTAssert(String(unchecked: try perl.eval("\\10") as PerlScalar).hasPrefix("SCALAR"))
	}

	func testScalarRef() throws {
		let v: PerlScalar = try perl.eval("\\42")
		XCTAssert(v.defined)
		XCTAssert(!v.isInt)
		XCTAssert(!v.isDouble)
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
		XCTAssert(!sv.isDouble)
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
		XCTAssert(!sv.isDouble)
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
		XCTAssert(!sv.isDouble)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let cv: PerlSub = try PerlSub(sv)!
		XCTAssertEqual(try cv.call(10, 15) as Int?, 25)
//		XCTAssertEqual(try sv.call(10, 15) as Int, 25)
	}

	func testInterpreterMisc() throws {
		try perl.eval("use utf8; $тест = 'OK'")
		let sv = PerlScalar(get: "тест")
		XCTAssertNotNil(sv)
		XCTAssertEqual(try String(sv!), "OK")
	}
}
