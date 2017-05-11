import XCTest
@testable import Perl

class ConvertFromPerlTests : EmbeddedTestCase {
	static var allTests: [(String, (ConvertFromPerlTests) -> () throws -> Void)] {
		return [
			("testUndef", testUndef),
			("testBool", testBool),
			("testInt", testInt),
			("testUInt", testUInt),
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
		XCTAssert(!v.isInteger)
		XCTAssert(!v.isDouble)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertNil(v.map { $0 })
		XCTAssertNil(v.flatMap { $0 })
		XCTAssertEqual(try Int(v ?? 10), 10)
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
		XCTAssert(v.isInteger)
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
		XCTAssertThrowsError(try perl.eval("10000000000000000000") as Int)
		XCTAssertThrowsError(try perl.eval("20000000000000000000") as Int)
		XCTAssertEqual(try perl.eval("-10") as Int, -10)
		XCTAssertThrowsError(try perl.eval("-20000000000000000000") as Int)
		XCTAssertEqual(try perl.eval("\(Int.min)") as Int, Int.min)
		XCTAssertEqual(try perl.eval("\(Int.max)") as Int, Int.max)
		// Nilable implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("42") as Int?, 42)
		XCTAssertEqual(try perl.eval("'42'") as Int?, 42)
		XCTAssertEqual(try perl.eval("42.0") as Int?, 42)
		XCTAssertEqual(try perl.eval("42.5") as Int?, 42)
		XCTAssertNil(try perl.eval("undef") as Int?)
		XCTAssertThrowsError(try perl.eval("''") as Int?)
		XCTAssertThrowsError(try perl.eval("'ololo'") as Int?)
		XCTAssertThrowsError(try perl.eval("'50sec'") as Int?)
		XCTAssertThrowsError(try perl.eval("10000000000000000000") as Int?)
		XCTAssertThrowsError(try perl.eval("20000000000000000000") as Int?)
		XCTAssertEqual(try perl.eval("-10") as Int?, -10)
		XCTAssertThrowsError(try perl.eval("-20000000000000000000") as Int?)
		// Conversion from PerlScalar
		XCTAssertEqual(try Int(try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(try Int(try perl.eval("'42'") as PerlScalar), 42)
		XCTAssertEqual(try Int(try perl.eval("42.5") as PerlScalar), 42)
		XCTAssertThrowsError(try Int(try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try Int(try perl.eval("''") as PerlScalar))
		XCTAssertThrowsError(try Int(try perl.eval("'ololo'") as PerlScalar))
		XCTAssertThrowsError(try Int(try perl.eval("'50sec'") as PerlScalar))
		XCTAssertThrowsError(try Int(try perl.eval("10000000000000000000") as PerlScalar))
		XCTAssertThrowsError(try Int(try perl.eval("20000000000000000000") as PerlScalar))
		XCTAssertEqual(try Int(try perl.eval("-10") as PerlScalar), -10)
		XCTAssertThrowsError(try Int(try perl.eval("-20000000000000000000") as PerlScalar))
		// Nilable conversion from PerlScalar
		XCTAssertEqual(try (perl.eval("42") as PerlScalar).map { try Int($0) }, 42)
		XCTAssertEqual(try (perl.eval("'42'") as PerlScalar).map { try Int($0) }, 42)
		XCTAssertEqual(try (perl.eval("42.5") as PerlScalar).map { try Int($0) }, 42)
		XCTAssertNil(try (perl.eval("undef") as PerlScalar).map { try Int($0) })
		XCTAssertThrowsError(try (perl.eval("''") as PerlScalar).map { try Int($0) })
		XCTAssertThrowsError(try (perl.eval("'ololo'") as PerlScalar).map { try Int($0) })
		XCTAssertThrowsError(try (perl.eval("'50sec'") as PerlScalar).map { try Int($0) })
		XCTAssertThrowsError(try (perl.eval("10000000000000000000") as PerlScalar).map { try Int($0) })
		XCTAssertThrowsError(try (perl.eval("20000000000000000000") as PerlScalar).map { try Int($0) })
		XCTAssertEqual(try (perl.eval("-10") as PerlScalar).map { try Int($0) }, -10)
		XCTAssertThrowsError(try (perl.eval("-20000000000000000000") as PerlScalar).map { try Int($0) })
		// Unchecked conversion from PerlScalar
		XCTAssertEqual(Int(unchecked: try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(Int(unchecked: try perl.eval("'42'") as PerlScalar), 42)
		XCTAssertEqual(Int(unchecked: try perl.eval("42.5") as PerlScalar), 42)
		XCTAssertEqual(Int(unchecked: try perl.eval("undef") as PerlScalar), 0)
		XCTAssertEqual(Int(unchecked: try perl.eval("''") as PerlScalar), 0)
		XCTAssertEqual(Int(unchecked: try perl.eval("'ololo'") as PerlScalar), 0)
		XCTAssertEqual(Int(unchecked: try perl.eval("'50sec'") as PerlScalar), 50)
		XCTAssertEqual(Int(unchecked: try perl.eval("10000000000000000000") as PerlScalar), Int(bitPattern: 10000000000000000000))
		XCTAssertEqual(Int(unchecked: try perl.eval("20000000000000000000") as PerlScalar), Int(bitPattern: UInt.max))
		XCTAssertEqual(Int(unchecked: try perl.eval("-10") as PerlScalar), -10)
		XCTAssertEqual(Int(unchecked: try perl.eval("-20000000000000000000") as PerlScalar), Int.min)
	}

	func testUInt() throws {
		let v: PerlScalar = try perl.eval("42")
		XCTAssert(v.defined)
		XCTAssert(v.isInteger)
		XCTAssert(!v.isDouble)
		XCTAssert(!v.isString)
		XCTAssert(!v.isRef)
		XCTAssertEqual(try UInt(v), 42)
		XCTAssertEqual(try String(v), "42")
		// Implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("42") as UInt, 42)
		XCTAssertEqual(try perl.eval("'42'") as UInt, 42)
		XCTAssertEqual(try perl.eval("42.5") as UInt, 42)
		XCTAssertThrowsError(try perl.eval("undef") as UInt)
		XCTAssertThrowsError(try perl.eval("''") as UInt)
		XCTAssertThrowsError(try perl.eval("'ololo'") as UInt)
		XCTAssertThrowsError(try perl.eval("'50sec'") as UInt)
		XCTAssertEqual(try perl.eval("10000000000000000000") as UInt, 10000000000000000000)
		XCTAssertThrowsError(try perl.eval("20000000000000000000") as UInt)
		XCTAssertThrowsError(try perl.eval("-10") as UInt)
		XCTAssertThrowsError(try perl.eval("-20000000000000000000") as UInt)
		XCTAssertEqual(try perl.eval("\(UInt.min)") as UInt, UInt.min)
		XCTAssertEqual(try perl.eval("\(UInt.max)") as UInt, UInt.max)
		// Nilable implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("42") as UInt?, 42)
		XCTAssertEqual(try perl.eval("'42'") as UInt?, 42)
		XCTAssertEqual(try perl.eval("42.5") as UInt?, 42)
		XCTAssertNil(try perl.eval("undef") as UInt?)
		XCTAssertThrowsError(try perl.eval("''") as UInt?)
		XCTAssertThrowsError(try perl.eval("'ololo'") as UInt?)
		XCTAssertThrowsError(try perl.eval("'50sec'") as UInt?)
		XCTAssertEqual(try perl.eval("10000000000000000000") as UInt?, 10000000000000000000)
		XCTAssertThrowsError(try perl.eval("20000000000000000000") as UInt?)
		XCTAssertThrowsError(try perl.eval("-10") as UInt?)
		XCTAssertThrowsError(try perl.eval("-20000000000000000000") as UInt?)
		// Conversion from PerlScalar
		XCTAssertEqual(try UInt(try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(try UInt(try perl.eval("'42'") as PerlScalar), 42)
		XCTAssertEqual(try UInt(try perl.eval("42.5") as PerlScalar), 42)
		XCTAssertThrowsError(try UInt(try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try UInt(try perl.eval("''") as PerlScalar))
		XCTAssertThrowsError(try UInt(try perl.eval("'ololo'") as PerlScalar))
		XCTAssertThrowsError(try UInt(try perl.eval("'50sec'") as PerlScalar))
		XCTAssertEqual(try UInt(try perl.eval("10000000000000000000") as PerlScalar), 10000000000000000000)
		XCTAssertThrowsError(try UInt(try perl.eval("20000000000000000000") as PerlScalar))
		XCTAssertThrowsError(try UInt(try perl.eval("-10") as PerlScalar))
		XCTAssertThrowsError(try UInt(try perl.eval("-20000000000000000000") as PerlScalar))
		// Nilable conversion from PerlScalar
		XCTAssertEqual(try (perl.eval("42") as PerlScalar).map { try UInt($0) }, 42)
		XCTAssertEqual(try (perl.eval("'42'") as PerlScalar).map { try UInt($0) }, 42)
		XCTAssertEqual(try (perl.eval("42.5") as PerlScalar).map { try UInt($0) }, 42)
		XCTAssertNil(try (perl.eval("undef") as PerlScalar).map { try UInt($0) })
		XCTAssertThrowsError(try (perl.eval("''") as PerlScalar).map { try UInt($0) })
		XCTAssertThrowsError(try (perl.eval("'ololo'") as PerlScalar).map { try UInt($0) })
		XCTAssertThrowsError(try (perl.eval("'50sec'") as PerlScalar).map { try UInt($0) })
		XCTAssertEqual(try (perl.eval("10000000000000000000") as PerlScalar).map { try UInt($0) }, 10000000000000000000)
		XCTAssertThrowsError(try (perl.eval("20000000000000000000") as PerlScalar).map { try UInt($0) })
		XCTAssertThrowsError(try (perl.eval("-10") as PerlScalar).map { try UInt($0) })
		XCTAssertThrowsError(try (perl.eval("-20000000000000000000") as PerlScalar).map { try UInt($0) })
		// Unchecked conversion from PerlScalar
		XCTAssertEqual(UInt(unchecked: try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(UInt(unchecked: try perl.eval("'42'") as PerlScalar), 42)
		XCTAssertEqual(UInt(unchecked: try perl.eval("42.5") as PerlScalar), 42)
		XCTAssertEqual(UInt(unchecked: try perl.eval("undef") as PerlScalar), 0)
		XCTAssertEqual(UInt(unchecked: try perl.eval("''") as PerlScalar), 0)
		XCTAssertEqual(UInt(unchecked: try perl.eval("'ololo'") as PerlScalar), 0)
		XCTAssertEqual(UInt(unchecked: try perl.eval("'50sec'") as PerlScalar), 50)
		XCTAssertEqual(UInt(unchecked: try perl.eval("10000000000000000000") as PerlScalar), 10000000000000000000)
		XCTAssertEqual(UInt(unchecked: try perl.eval("20000000000000000000") as PerlScalar), UInt.max)
		XCTAssertEqual(UInt(unchecked: try perl.eval("-10") as PerlScalar), UInt(bitPattern: -10))
		XCTAssertEqual(UInt(unchecked: try perl.eval("-20000000000000000000") as PerlScalar), UInt(bitPattern: Int.min))
	}

	func testDouble() throws {
		let v: PerlScalar = try perl.eval("42.3")
		XCTAssert(v.defined)
		XCTAssert(!v.isInteger)
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
		XCTAssertEqual(try perl.eval("10000000000000000001") as Double, 1e19)
		XCTAssertEqual(try perl.eval("'10000000000000000001'") as Double, 1e19)
		// Nilable implicit conversion from UnsafeSvPointer
		XCTAssertEqual(try perl.eval("42.3") as Double?, 42.3)
		XCTAssertEqual(try perl.eval("'42.3'") as Double?, 42.3)
		XCTAssertEqual(try perl.eval("42") as Double?, 42)
		XCTAssertNil(try perl.eval("undef") as Double?)
		XCTAssertThrowsError(try perl.eval("''") as Double?)
		XCTAssertThrowsError(try perl.eval("'ololo'") as Double?)
		XCTAssertThrowsError(try perl.eval("'50sec'") as Double?)
		XCTAssertEqual(try perl.eval("10000000000000000001") as Double?, 1e19)
		XCTAssertEqual(try perl.eval("'10000000000000000001'") as Double?, 1e19)
		// Conversion from PerlScalar
		XCTAssertEqual(try Double(try perl.eval("42.3") as PerlScalar), 42.3)
		XCTAssertEqual(try Double(try perl.eval("'42.3'") as PerlScalar), 42.3)
		XCTAssertEqual(try Double(try perl.eval("42") as PerlScalar), 42)
		XCTAssertThrowsError(try Double(try perl.eval("undef") as PerlScalar))
		XCTAssertThrowsError(try Double(try perl.eval("''") as PerlScalar))
		XCTAssertThrowsError(try Double(try perl.eval("'ololo'") as PerlScalar))
		XCTAssertThrowsError(try Double(try perl.eval("'50sec'") as PerlScalar))
		XCTAssertEqual(try Double(try perl.eval("10000000000000000001") as PerlScalar), 1e19)
		XCTAssertEqual(try Double(try perl.eval("'10000000000000000001'") as PerlScalar), 1e19)
		// Nilable conversion from PerlScalar
		XCTAssertEqual(try (perl.eval("42.3") as PerlScalar).map { try Double($0) }, 42.3)
		XCTAssertEqual(try (perl.eval("'42.3'") as PerlScalar).map { try Double($0) }, 42.3)
		XCTAssertEqual(try (perl.eval("42") as PerlScalar).map { try Double($0) }, 42)
		XCTAssertNil(try (perl.eval("undef") as PerlScalar).map { try Double($0) })
		XCTAssertThrowsError(try (perl.eval("''") as PerlScalar).map { try Double($0) })
		XCTAssertThrowsError(try (perl.eval("'ololo'") as PerlScalar).map { try Double($0) })
		XCTAssertThrowsError(try (perl.eval("'50sec'") as PerlScalar).map { try Double($0) })
		XCTAssertEqual(try (perl.eval("10000000000000000001") as PerlScalar).map { try Double($0) }, 1e19)
		XCTAssertEqual(try (perl.eval("'10000000000000000001'") as PerlScalar).map { try Double($0) }, 1e19)
		// Unchecked conversion from PerlScalar
		XCTAssertEqual(Double(unchecked: try perl.eval("42.3") as PerlScalar), 42.3)
		XCTAssertEqual(Double(unchecked: try perl.eval("'42.3'") as PerlScalar), 42.3)
		XCTAssertEqual(Double(unchecked: try perl.eval("42") as PerlScalar), 42)
		XCTAssertEqual(Double(unchecked: try perl.eval("undef") as PerlScalar), 0)
		XCTAssertEqual(Double(unchecked: try perl.eval("''") as PerlScalar), 0)
		XCTAssertEqual(Double(unchecked: try perl.eval("'ololo'") as PerlScalar), 0)
		XCTAssertEqual(Double(unchecked: try perl.eval("'50sec'") as PerlScalar), 50)
		XCTAssertEqual(Double(unchecked: try perl.eval("'50.3sec'") as PerlScalar), 50.3)
		XCTAssertEqual(Double(unchecked: try perl.eval("10000000000000000001") as PerlScalar), 1e19)
		XCTAssertEqual(Double(unchecked: try perl.eval("'10000000000000000001'") as PerlScalar), 1e19)
	}

	func testString() throws {
		let v: PerlScalar = try perl.eval("'test'")
		XCTAssert(v.defined)
		XCTAssert(!v.isInteger)
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
		XCTAssertEqual(try (perl.eval("'anything'") as PerlScalar).map { try String($0) }, "anything")
		XCTAssertEqual(try (perl.eval("42") as PerlScalar).map { try String($0) }, "42")
		XCTAssertEqual(try (perl.eval("42.5") as PerlScalar).map { try String($0) }, "42.5")
		XCTAssertNil(try (perl.eval("undef") as PerlScalar).map { try String($0) })
		XCTAssertThrowsError(try (perl.eval("\\10") as PerlScalar).map { try String($0) })
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
		XCTAssert(!v.isInteger)
		XCTAssert(!v.isDouble)
		XCTAssert(!v.isString)
		XCTAssert(v.isRef)
		XCTAssertNotNil(v.referent)
		let r = v.referent! as! PerlScalar
		XCTAssert(r.isInteger)
		XCTAssertEqual(try Int(r), 42)
	}

	func testArrayRef() throws {
		let sv: PerlScalar = try perl.eval("[42, 'str']")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInteger)
		XCTAssert(!sv.isDouble)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let av: PerlArray = try PerlArray(sv)
		XCTAssertEqual(av.count, 2)
		XCTAssertEqual(try Int(av[0]), 42)
		XCTAssertEqual(try String(av[1]), "str")
		XCTAssertEqual(try av.fetch(0), 42)
		XCTAssertEqual(try av.fetch(1), "str")
		XCTAssertNil(try av.fetch(5) as Int?)
		XCTAssertFalse(av[7].defined)
		let strs: [String] = try [String](sv)
		XCTAssertEqual(strs, ["42", "str"])
		XCTAssertEqual(try [String](av), ["42", "str"])
		XCTAssertEqual(try [String](sv), ["42", "str"])

		av[9] = 100
		XCTAssertEqual(try Int(av[9]), 100)
		av.store(11, value: 200)
		XCTAssertEqual(try av.fetch(11), 200)
		av.delete(11)
		XCTAssertNil(try av.fetch(11) as Int?)
		av.store(11, value: 200)
		XCTAssertEqual(try av.delete(11), 200)
		XCTAssertNil(try av.fetch(11) as Int?)

		let i: PerlScalar = try perl.eval("[42, 15, 10]")
		let ints: [Int] = try [Int](i)
		XCTAssertEqual(ints, [42, 15, 10])

		let s: PerlScalar = try perl.eval("[qw/one two three/]")
		let strings: [String] = try [String](s)
		XCTAssertEqual(strings, ["one", "two", "three"])
	}

	func testHashRef() throws {
		let sv: PerlScalar = try perl.eval("{ one => 1, two => 2, три => 3 }")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInteger)
		XCTAssert(!sv.isDouble)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let hv: PerlHash = try PerlHash(sv)
//		XCTAssertEqual(hv.count, 2)
		XCTAssertEqual(try Int(hv["one"]!), 1)
		XCTAssertEqual(try Int(hv["two"]!), 2)
		XCTAssertEqual(try Int(hv["три"]!), 3)
//		let hd: [String: Int] = try [String: Int](hv)
//		XCTAssertEqual(hd, ["one": 1, "two": 2])
		let sd: [String: Int] = try [String: Int](sv)
		XCTAssertEqual(sd, ["one": 1, "two": 2, "три": 3])
		XCTAssertEqual(sd, ["one": 1, "two": 2, "три": 3])
		XCTAssertEqual(try [String: Int](hv), ["one": 1, "two": 2, "три": 3])
		XCTAssertEqual(try [String: Int](sv), ["one": 1, "two": 2, "три": 3])
	}

	func testCodeRef() throws {
		let sv: PerlScalar = try perl.eval("sub { my ($c, $d) = @_; return $c + $d }")
		XCTAssert(sv.defined)
		XCTAssert(!sv.isInteger)
		XCTAssert(!sv.isDouble)
		XCTAssert(!sv.isString)
		XCTAssert(sv.isRef)
		XCTAssertNotNil(sv.referent)
		let cv: PerlSub = try PerlSub(sv)
		XCTAssertEqual(try cv.call(10, 15) as Int?, 25)
//		XCTAssertEqual(try sv.call(10, 15) as Int, 25)

		let sub: PerlSub = try perl.eval("my $stored = 40; sub { $_[0] = 20; return $stored }")
		let arg: PerlScalar = 10
		let r1: PerlScalar = try sub.call(arg)
		XCTAssertEqual(try Int(arg), 20)
		XCTAssertEqual(try Int(r1), 40)
		r1.set(50)
		let r2: PerlScalar = try sub.call(arg)
		XCTAssertEqual(try Int(r2), 40)

		var origsv: UnsafeSvPointer?
		var origptr: UnsafeRawPointer?
		let ret: PerlScalar = try PerlSub { () -> PerlScalar in
			let s = PerlScalar("ololo")
			s.withUnsafeSvContext { origsv = $0.sv }
			s.withUnsafeBytes { origptr = $0.baseAddress }
			return s
		}.call()
		ret.withUnsafeSvContext { XCTAssertNotEqual($0.sv, origsv, "Returned SV is not copied") }
		ret.withUnsafeBytes { XCTAssertEqual($0.baseAddress, origptr, "String of returned SV is not stealed") }
	}

	func testInterpreterMisc() throws {
		try perl.eval("use utf8; $тест = 'OK'")
		let sv = PerlScalar(get: "тест")
		XCTAssertNotNil(sv)
		XCTAssertEqual(try String(sv!), "OK")
	}
}
