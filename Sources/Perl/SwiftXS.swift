import CPerl

var objects = [Int: PerlMappedClass]()
var perlInterpreter: PerlInterpreter!

@_cdecl("boot_SwiftXS")
func boot(_ p: PerlInterpreter.Pointer) {
	print("OK")
	_ = PerlCV(name: "Swift::test") {
		(args) in
		print("args: \(args.map(String.init))")
		return [PerlSV(MyTest())]
	}
	let myTestClass = PerlClass("Swift::Perl.MyTest", swiftClass: MyTest.self)
	myTestClass.createXSub("test") {
		(args) in
//		let slf: MyTest = try! args[0].value()
//		slf.test(value: args[1].value())
//		slf.test2(value: try! args[2].value() as PerlTestMouse)
//		let bInt: PerlSV = 99
//		let bTrue: PerlSV = true
//		let arr: PerlAV = [1, 2, 3, 4, 5]
		return [101, "Строченька", nil, true, false, [8, [], "string"], ["key": "value", "k2": 34]]
//		return [[[1]]]
	}
	myTestClass.createXSub("test2") {
		(str: String) throws -> Int in
		throw PerlError.died(PerlSV("Throwing from Swift"))
	}
	URI.loadModule()
	myTestClass.createXSub("test3") {
		(self: MyTest, str: String, ptm: PerlTestMouse) throws -> Int in
		print("\(self): \(ptm)")
		let uri = try URI("/test/uri")
		print("uri: \(uri.asString), \(uri.abs(base: "http://base.url")), \(uri.secure), \(URI(copyOf: uri))")
		return 88
	}
	_ = PerlCV(name: "Swift::test_die") {
		(args) in
		do {
			try PerlInterpreter.call(sub: "main::die_now")
		} catch PerlError.died(let err) {
			print("Perl died: \(err.string)")
		} catch {
			print("Other error")
		}
		print("DONE")
		return []
	}
	PerlInterpreter.register(PerlTestMouse)
}

final class MyTest : PerlMappedClass {
	var property = 15
	static var staticProperty = 500

	init () {
		print("##### INIT #####");
	}

	deinit {
		print("##### DEINIT #####");
	}

	func test(value: Int) {
		print("Method was called, property is \(property), value is \(value)")
//		let t = PerlTestMouse()
//		print("~~~~~~~~~ \(t.attr_ro)")
	}

	func test2 (value: PerlTestMouse) {
		print("test2: \(value.attr_rw) - \(value.attr_ro)")
		value.attr_rw = "Строка"
		print("array: \(value.list.count)")
		for v in value.list {
			print("value: \(v.string)")
		}
		for (k, v) in value.hash {
			print("key: \(k), value: \(v.string)")
		}
		print("key3: \(value.hash["key3"]!.string)")
		print("do_something: \(try! value.doSomething(15, "more + "))")
		print("list: \(value.list)")
		print("listOfStrings: \(value.listOfStrings)")
//		try! value.call(method: "unknown", args: 1, 2, "String")
	}
}
