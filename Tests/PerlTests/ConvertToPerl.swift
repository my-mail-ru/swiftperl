import XCTest
import Perl

class ConvertToPerlTests : EmbeddedTestCase {
	static var allTests: [(String, (ConvertToPerlTests) -> () throws -> Void)] {
		return [
			("testUndef", testUndef),
			("testInt", testInt),
			("testString", testString),
			("testScalarRef", testScalarRef),
			("testArrayRef", testArrayRef),
			("testHashRef", testHashRef),
		]
	}

	func testUndef() throws {
		let v = PerlSV()
		XCTAssert(!v.defined)
		try perl.eval("sub is_defined { return defined $_[0] }")
		XCTAssert(try !perl.call(sub: "is_defined", v))
	}

	func testInt() throws {
		let v = PerlSV(10)
		XCTAssert(v.isInt)
		try perl.eval("sub is_10 { return $_[0] == 10 }")
		XCTAssert(try perl.call(sub: "is_10", v))
	}

	func testString() throws {
		let a = PerlSV("ascii string")
		XCTAssert(a.isString)
		try perl.eval("sub is_ascii_string { return $_[0] eq 'ascii string' }")
		XCTAssert(try perl.call(sub: "is_ascii_string", a))
		let u = PerlSV("строченька")
		XCTAssert(u.isString)
		try perl.eval("sub is_utf8_string { return $_[0] eq 'строченька' }")
		XCTAssert(try perl.call(sub: "is_utf8_string", u))
	}

	func testScalarRef() throws {
		let v = PerlSV(referenceTo: PerlSV(10 as Int))
		XCTAssert(v.isRef)
		try perl.eval("sub is_ref_10 { return ${$_[0]} == 10 }")
		XCTAssert(try perl.call(sub: "is_ref_10", v))
	}

	func testArrayRef() throws {
		let array = [10, 20]
		let v = PerlSV(referenceTo: PerlAV(array))
		XCTAssert(v.isRef)
		try perl.eval("sub is_array { return @{$_[0]} == 2 && $_[0][0] == 10 && $_[0][1] == 20 }")
		XCTAssert(try perl.call(sub: "is_array", v))
		let v2 = PerlSV(PerlAV(array))
		XCTAssert(try perl.call(sub: "is_array", v2))
		let v3 = PerlSV(array)
		XCTAssert(try perl.call(sub: "is_array", v3))
	}

	func testHashRef() throws {
		let dict = ["a": 10, "b": 20]
		let v = PerlSV(referenceTo: PerlHV(dict))
		XCTAssert(v.isRef)
		try perl.eval("sub is_hash { return keys(%{$_[0]}) == 2 && $_[0]{a} == 10 && $_[0]{b} == 20 }")
		XCTAssert(try perl.call(sub: "is_hash", v))
		let v2 = PerlSV(PerlHV(dict))
		XCTAssert(try perl.call(sub: "is_hash", v2))
		let v3 = PerlSV(dict)
		XCTAssert(try perl.call(sub: "is_hash", v3))
	}
}
