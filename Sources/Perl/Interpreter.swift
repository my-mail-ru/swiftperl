import CPerl

struct PerlInterpreter {
	typealias Pointer = UnsafeMutablePointer<CPerl.PerlInterpreter>

	static var classMapping = [String: PerlObjectType.Type ]()

	static func register(_ swiftClass: PerlObjectType.Type) {
		classMapping[swiftClass.perlClassName] = swiftClass
	}

	static func loadModule(_ module: String) {
		let sv = PerlSV(module)
		sv.refcntInc() // load_module() decrements refcnt for each passed SV*
		load_module_noargs(0, sv.pointer, nil)
	}

	static func withNewScope<R> (_ closure: @noescape () throws -> R) rethrows -> R {
		ENTER()
		SAVETMPS()
		let result = try closure()
		FREETMPS()
		LEAVE()
		return result
	}
}

extension PerlInterpreter {
	internal static func call<T: PerlSVConvertible>(sub: String, args: [PerlSVConvertible], context: Int32) throws -> [T] {
		return try withNewScope {
			var stack = PerlStack()
			return try stack.wrapCall(args) { call_pv(sub, G_EVAL|context) }
		}
	}

	static func call(sub: String, args: [PerlSVConvertible]) throws {
		try call(sub: sub, args: args, context: G_VOID) as [PerlSV]
	}

	static func call<T: PerlSVConvertible>(sub: String, args: [PerlSVConvertible]) throws -> T {
		return try (call(sub: sub, args: args, context: G_SCALAR) as [T])[0]
	}

	static func call<T: PerlSVConvertible>(sub: String, args: [PerlSVConvertible]) throws -> T? {
		let sv = try (call(sub: sub, args: args, context: G_SCALAR) as [PerlSV])[0]
		return sv.defined ? try T.fromPerlSV(sv) : nil
	}

	static func call<T: PerlSVConvertible>(sub: String, args: [PerlSVConvertible]) throws -> [T] {
		return try call(sub: sub, args: args, context: G_ARRAY)
	}

	static func call<T: PerlSVConvertible>(sub: String, args: [PerlSVConvertible]) throws -> [T?] {
		let array: [PerlSV] = try call(sub: sub, args: args, context: G_ARRAY)
		return try array.map { $0.defined ? try T.fromPerlSV($0) : nil }
	}

	// TODO optional input arguments

	static func call(sub: String, args: PerlSVConvertible...) throws {
		return try call(sub: sub, args: args)
	}

	static func call<T: PerlSVConvertible>(sub: String, args: PerlSVConvertible...) throws -> T {
		return try call(sub: sub, args: args)
	}

	static func call<T: PerlSVConvertible>(sub: String, args: PerlSVConvertible...) throws -> T? {
		return try call(sub: sub, args: args)
	}

	static func call<T: PerlSVConvertible>(sub: String, args: PerlSVConvertible...) throws -> [T] {
		return try call(sub: sub, args: args)
	}

	static func call<T: PerlSVConvertible>(sub: String, args: PerlSVConvertible...) throws -> [T?] {
		return try call(sub: sub, args: args)
	}
}

extension PerlInterpreter {
	internal static func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible], context: Int32) throws -> [T] {
		return try withNewScope {
			var stack = PerlStack()
			return try stack.wrapCall(args) { call_method(method, G_EVAL|context) }
		}
	}

	static func call(method: String, args: [PerlSVConvertible]) throws {
		try call(method: method, args: args, context: G_VOID) as [PerlSV]
	}

	static func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> T {
		return try (call(method: method, args: args, context: G_SCALAR) as [T])[0]
	}

	static func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> T? {
		let sv = try (call(method: method, args: args, context: G_SCALAR) as [PerlSV])[0]
		return sv.defined ? try T.fromPerlSV(sv) : nil
	}

	static func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> [T] {
		return try call(method: method, args: args, context: G_ARRAY)
	}

	static func call<T: PerlSVConvertible>(method: String, args: [PerlSVConvertible]) throws -> [T?] {
		let array: [PerlSV] = try call(method: method, args: args, context: G_ARRAY)
		return try array.map { $0.defined ? try T.fromPerlSV($0) : nil }
	}

	// TODO optional input arguments

	static func call(method: String, args: PerlSVConvertible...) throws {
		return try call(method: method, args: args)
	}

	static func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> T {
		return try call(method: method, args: args)
	}

	static func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> T? {
		return try call(method: method, args: args)
	}

	static func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> [T] {
		return try call(method: method, args: args)
	}

	static func call<T: PerlSVConvertible>(method: String, args: PerlSVConvertible...) throws -> [T?] {
		return try call(method: method, args: args)
	}
}
