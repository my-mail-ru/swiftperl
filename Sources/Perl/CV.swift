import CPerl

final class PerlCV : PerlSVProtocol {
	typealias Struct = UnsafeCV
	typealias Pointer = UnsafeCvPointer
	let pointer: Pointer
	let perl: UnsafeInterpreterPointer

	init(_ p: Pointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) {
		self.perl = perl
		pointer = p
		pointer.pointee.refcntInc()
	}

	@discardableResult
	init(name: String?, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current, file: StaticString = #file, body: CvBody) {
		self.perl = perl
		pointer = perl.pointee.newCV(name: name, file: file, body: body)
		if name != nil {
			pointer.pointee.refcntInc()
		}
	}

	deinit {
		pointer.pointee.refcntDec(perl: perl)
	}
}

extension PerlCV {
	@discardableResult
	convenience init(name: String? = nil, file: StaticString = #file, body: () throws -> Void) {
		self.init(name: name, file: file) {
			(stack: UnsafeXSubStack) in
			try body()
			stack.xsReturn(EmptyCollection())
		}
	}

	@discardableResult
	convenience init<T: PerlSVConvertible>(name: String? = nil, file: StaticString = #file, body: (T) throws -> Void) {
		self.init(name: name, file: file) {
			(stack: UnsafeXSubStack) in
			try body(T.cast(from: stack.args[0]))
			stack.xsReturn(EmptyCollection())
		}
	}

	@discardableResult
	convenience init<T: PerlSVConvertible, R: PerlSVConvertible>(name: String? = nil, file: StaticString = #file, body: (T) throws -> R) {
		self.init(name: name, file: file) {
			(stack: UnsafeXSubStack) in
			let result = try body(T.cast(from: stack.args[0]))
			stack.xsReturn(CollectionOfOne(result.newUnsafeSvPointer(perl: stack.perl)))
		}
	}

	@discardableResult
	convenience init<T1: PerlSVConvertible, T2: PerlSVConvertible, R: PerlSVConvertible>(name: String? = nil, file: StaticString = #file, body: (T1, T2) throws -> R) {
		self.init(name: name, file: file) {
			(stack: UnsafeXSubStack) in
			let result = try body(T1.cast(from: stack.args[0]), T2.cast(from: stack.args[1]))
			stack.xsReturn(CollectionOfOne(result.newUnsafeSvPointer(perl: stack.perl)))
		}
	}

	@discardableResult
	convenience init<T1: PerlSVConvertible, T2: PerlSVConvertible, T3: PerlSVConvertible, R: PerlSVConvertible>(name: String? = nil, file: StaticString = #file, body: (T1, T2, T3) throws -> R) {
		self.init(name: name, file: file) {
			(stack: UnsafeXSubStack) in
			let result = try body(T1.cast(from: stack.args[0]), T2.cast(from: stack.args[1]), T3.cast(from: stack.args[2]))
			stack.xsReturn(CollectionOfOne(result.newUnsafeSvPointer(perl: stack.perl)))
		}
	}

	@discardableResult
	convenience init<R: Collection where R.Iterator.Element == PerlSV>
		(name: String? = nil, file: StaticString = #file, body: (ContiguousArray<PerlSV>) throws -> R) {
		self.init(name: name, file: file) {
			(stack: UnsafeXSubStack) in
			let args = try ContiguousArray<PerlSV>(stack.args, perl: stack.perl)
			let result = try body(args)
			stack.xsReturn(ContiguousArray<UnsafeSvPointer>(result, perl: stack.perl))
		}
	}
}
