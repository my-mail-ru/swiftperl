import XCTest
@testable import Perl

class InternalTests : EmbeddedTestCase {
	static let allTests = [
		("testSubclass", testSubclass),
	]

	func testSubclass() {
		XCTAssertFalse(isStrictSubclass(A.self, of: A.self))
		XCTAssertTrue(isStrictSubclass(B.self, of: A.self))
		XCTAssertTrue(isStrictSubclass(C.self, of: A.self))
		XCTAssertTrue(isStrictSubclass(C.self, of: B.self))
		XCTAssertFalse(isStrictSubclass(C.self, of: C.self))
		XCTAssertFalse(isStrictSubclass(D.self, of: C.self))
		XCTAssertFalse(isStrictSubclass(A.self, of: B.self))
		XCTAssertFalse(isStrictSubclass(E.self, of: A.self))
		XCTAssertFalse(isStrictSubclass(F.self, of: A.self))
	}
}

class A {}
class B : A {}
class C : B {}
class D : B {}

class E {}
class F : E {}
