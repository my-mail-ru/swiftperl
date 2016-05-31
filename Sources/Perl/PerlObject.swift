import CPerl

protocol PerlObjectType : PerlSVConvertibleThrowing {
	var sv: PerlSV { get }
	static var perlClassName: String { get }
	init(_: PerlSV)
}

extension PerlObjectType {
	static func loadModule() {
		PerlInterpreter.loadModule(perlClassName)
	}
}

// type variants of call(...)
extension PerlObjectType {
	static func call(method: String, args: [PerlSVConvertible]) throws {
		return try PerlInterpreter.call(method: method, args: [perlClassName] + args)
	}

	static func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> T {
		return try PerlInterpreter.call(method: method, args: [perlClassName] + args)
	}

	static func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> [T] {
		return try PerlInterpreter.call(method: method, args: [perlClassName] + args)
	}


	static func call(method: String, args: PerlSVConvertible...) throws {
		return try call(method: method, args: args)
	}

	static func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> T {
		return try call(method: method, args: args)
	}

	static func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> [T] {
		return try call(method: method, args: args)
	}


	static func call<T1: PerlSVConvertible, T2: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> (T1, T2) {
		let result: [PerlSV] = try call(method: method, args: args)
		return try (T1.fromPerlSV(result[0]), T2.fromPerlSV(result[1]))
	}

	static func call<T1: PerlSVConvertible, T2: PerlSVConvertible, T3: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> (T1, T2, T3) {
		let result: [PerlSV] = try call(method: method, args: args)
		return try (T1.fromPerlSV(result[0]), T2.fromPerlSV(result[1]), T3.fromPerlSV(result[2]))
	}
}

// instance variants of call(...)
extension PerlObjectType {
	func call(method: String, args: [PerlSVConvertible]) throws {
		return try PerlInterpreter.call(method: method, args: [sv] + args)
	}

	func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> T {
		return try PerlInterpreter.call(method: method, args: [sv] + args)
	}

	func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> T? {
		return try PerlInterpreter.call(method: method, args: [sv] + args)
	}

	func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> [T] {
		return try PerlInterpreter.call(method: method, args: [sv] + args)
	}

	func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> [T?] {
		return try PerlInterpreter.call(method: method, args: [sv] + args)
	}


	func call(method: String, args: PerlSVConvertible...) throws {
		return try call(method: method, args: args)
	}

	func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> T {
		return try call(method: method, args: args)
	}

	func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> T? {
		return try call(method: method, args: args)
	}

	func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> [T] {
		return try call(method: method, args: args)
	}

	func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> [T?] {
		return try call(method: method, args: args)
	}


	func call<T1: PerlSVConvertible, T2: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> (T1, T2) {
		let result: [PerlSV] = try call(method: method, args: args)
		return try (T1.fromPerlSV(result[0]), T2.fromPerlSV(result[1]))
	}

	func call<T1: PerlSVConvertible, T2: PerlSVConvertible, T3: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> (T1, T2, T3) {
		let result: [PerlSV] = try call(method: method, args: args)
		return try (T1.fromPerlSV(result[0]), T2.fromPerlSV(result[1]), T3.fromPerlSV(result[2]))
	}
}
