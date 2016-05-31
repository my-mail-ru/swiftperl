import CPerl

internal func commonResolver(pi: PerlInterpreter.Pointer?, cv: PerlCV.Pointer?) -> Void {
	do {
		try PerlCV.cvBodies[cv!]!()
	} catch PerlError.died(let sv) {
		croak_sv(sv.pointer)
	} catch {
		croak_sv(PerlSV("Exception: \(error)").pointer) // FIXME no one leak
	}
}

final class PerlCV : PerlSVProtocol {
	typealias Struct = CV
	typealias Pointer = UnsafeMutablePointer<Struct>
	let pointer: Pointer

	static var cvBodies = Dictionary<Pointer, () throws -> ()>()

	init(_ p: Pointer) {
		pointer = p
		refcntInc()
	}

	init(unwrappedWithName name: String?, file: String = #file, _ body: () throws -> ()) {
		pointer = file.withCString {
			(file) in
			if let name = name {
				return name.withCString { newXS_flags($0, commonResolver, file, nil, UInt32(XS_DYNAMIC_FILENAME)) }
			} else {
				return newXS_flags(nil, commonResolver, file, nil, UInt32(XS_DYNAMIC_FILENAME))
			}
		}
		PerlCV.cvBodies[pointer] = body
		if name != nil {
			refcntInc()
		}
	}

	deinit {
		refcntDec()
	}
}

extension PerlCV {
	convenience init(name: String? = nil, file: String = #file, body: (PerlStack) throws -> [PerlSV]) {
		self.init(unwrappedWithName: name, file: file) {
			var stack = PerlStack()
			try stack.wrapXSub(body)
		}
	}

	convenience init<T: PerlSVConvertible>(name: String? = nil, file: String = #file, body: (T) throws -> Void) {
		self.init(name: name, file: file) {
			(args: PerlStack) throws in
			try body(T.fromPerlSV(args[0]))
			return []
		}
	}

	convenience init<T: PerlSVConvertible, R: PerlSVConvertible>(name: String? = nil, file: String = #file, body: (T) throws -> R) {
		self.init(name: name, file: file) {
			(args) throws in
			return try [body(T.fromPerlSV(args[0])).perlSV]
		}
	}

	convenience init<T1: PerlSVConvertible, T2: PerlSVConvertible, R: PerlSVConvertible>(name: String? = nil, file: String = #file, body: (T1, T2) throws -> R) {
		self.init(name: name, file: file) {
			(args) in
			return try [body(T1.fromPerlSV(args[0]), T2.fromPerlSV(args[1])).perlSV]
		}
	}

	convenience init<T1: PerlSVConvertible, T2: PerlSVConvertible, T3: PerlSVConvertible, R: PerlSVConvertible>(name: String? = nil, file: String = #file, body: (T1, T2, T3) throws -> R) {
		self.init(name: name, file: file) {
			(args) in
			return try [body(T1.fromPerlSV(args[0]), T2.fromPerlSV(args[1]), T3.fromPerlSV(args[2])).perlSV]
		}
	}
}
