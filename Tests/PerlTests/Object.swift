import XCTest
import Foundation
@testable import Perl

class ObjectTests : EmbeddedTestCase {
	static var allTests: [(String, (ObjectTests) -> () throws -> Void)] {
		return [
			("testPerlObject", testPerlObject),
			("testSwiftObject", testSwiftObject),
			("testRefCnt", testRefCnt),
		]
	}

	func testPerlObject() throws {
		URI.loadModule()
		let uri = try URI("https://my.mail.ru/music")
		XCTAssertEqual(uri.path, "/music")
		uri.path = "/video"
		XCTAssertEqual(uri.asString, "https://my.mail.ru/video")
	}

	func testSwiftObject() throws {
		let url = NSURL(string: "https://my.mail.ru/music")!
		XCTAssertEqual(url.host, "my.mail.ru")
		NSURL.createPerlMethod("new") {
			(cname: String, str: String) -> NSURL in
			return NSURL(string: str)!
		}
		NSURL.createPerlMethod("host") {
			(obj: NSURL) -> String in
			return obj.host!
		}
		let host: String = try perl.eval("my $url = NSURL->new('https://my.mail.ru/music'); $url->host()")
		XCTAssertEqual(host, "my.mail.ru")
	}

	func testRefCnt() throws {
		TestRefCnt.createPerlMethod("new") { (cname: String) -> TestRefCnt in return TestRefCnt() }
		try perl.eval("TestRefCnt->new(); undef")
		XCTAssertEqual(TestRefCnt.refcnt, 0)
	}
}

final class URI : PerlObjectType {
	static let perlClassName = "URI"
	let sv: PerlSV
	init(_ sv: PerlSV) { self.sv = sv }

	convenience init(_ str: String) throws {
		self.init(try URI.call(method: "new", str) as PerlSV)
	}

	convenience init(_ str: String, scheme: String) throws {
		self.init(try URI.call(method: "new", str, scheme) as PerlSV)
	}

	convenience init(copyOf uri: URI) {
		self.init(try! uri.call(method: "clone") as PerlSV)
	}

	var scheme: String? { return try! call(method: "scheme") }
	func scheme(_ scheme: String) throws -> String? { return try call(method: "scheme", scheme) }

	var path: String {
		get { return try! call(method: "path") }
		set { try! call(method: "path", newValue) as Void }
	}

	var asString: String { return try! call(method: "as_string") }

	func abs(base: String) -> String { return try! call(method: "abs", base) }
	func rel(base: String) -> String { return try! call(method: "rel", base) }

	var secure: Bool { return try! call(method: "secure") }
}

extension NSURL : PerlMappedClass {
	public static let perlClassName = "NSURL"
	public static func promoteFromUnsafeSV(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws -> Self {
		return try NSURL._promoteFromUnsafeSvNonFinalClassWorkaround(sv, perl: perl)
	}
}

final class TestRefCnt : PerlMappedClass {
	static let perlClassName = "TestRefCnt"
	static var refcnt = 0
	init() { TestRefCnt.refcnt += 1 }
	deinit { TestRefCnt.refcnt -= 1 }
}
