import CPerl

typealias UnsafeStackBufferPointer = UnsafeMutableBufferPointer<UnsafeSvPointer>

protocol UnsafeStack {
	var perl: UnsafeInterpreterPointer { get }
}

extension UnsafeStack {
	fileprivate func pushTo<C : Collection>(sp: inout UnsafeMutablePointer<UnsafeSvPointer?>, from source: C)
		where C.Iterator.Element == UnsafeSvPointer, C.IndexDistance == Int {
		if !source.isEmpty {
			sp = perl.pointee.EXTEND(sp, source.count)
			for sv in source {
				sp += 1
				sp.initialize(to: perl.pointee.sv_2mortal(sv))
			}
		}
		perl.pointee.Istack_sp = sp
	}
}

struct UnsafeXSubStack : UnsafeStack {
	let args: UnsafeStackBufferPointer
	let perl: UnsafeInterpreterPointer
	let ax: Int32

	init(perl: UnsafeInterpreterPointer) {
		self.perl = perl
		//SV **sp = (my_perl->Istack_sp); I32 ax = (*(my_perl->Imarkstack_ptr)--); SV **mark = (my_perl->Istack_base) + ax++; I32 items = (I32)(sp - mark);
		var sp = perl.pointee.Istack_sp!
		ax = perl.pointee.POPMARK()
		let mark = perl.pointee.Istack_base + Int(ax)
		let items = sp - mark
		sp -= items
		args = UnsafeStackBufferPointer(start: UnsafeMutableRawPointer(sp + 1).assumingMemoryBound(to: UnsafeSvPointer.self), count: items)
	}

	func xsReturn<C : Collection>(_ result: C)
		where C.Iterator.Element == UnsafeSvPointer, C.IndexDistance == Int {
		var sp = perl.pointee.Istack_base! + Int(ax)
		pushTo(sp: &sp, from: result)
	}

	subscript(_ i: Int) -> UnsafeSvPointer {
		guard i < args.count else {
			return perl.pointee.sv_2mortal(perl.pointee.newSV())
		}
		return args[i]
	}

	func fetch<T : PerlSvConvertible>(at index: Int) throws -> T {
		guard index < args.count else {
			if T.self == PerlScalar.self {
				return PerlScalar() as! T
			} else {
				throw PerlError.noArgumentOnStack(at: index)
			}
		}
		return try T(_fromUnsafeSvContextCopy: UnsafeSvContext(sv: args[index], perl: perl))
	}

	func fetch<T : PerlSvConvertible>(at index: Int) throws -> T? {
		guard index < args.count else { return nil }
		return try Optional<T>(_fromUnsafeSvContextCopy: UnsafeSvContext(sv: args[index], perl: perl))
	}

	@_specialize(Bool) @_specialize(Int) @_specialize(UInt) @_specialize(Double) @_specialize(String) @_specialize(PerlScalar)
	func fetchTail<T : PerlSvConvertible>(startingAt index: Int) throws -> [T] {
		guard index < args.count else { return [] }
		var tail: [T] = []
		tail.reserveCapacity(args.count - index)
		for value in args[index..<args.count] {
			tail.append(try T(_fromUnsafeSvContextCopy: UnsafeSvContext(sv: value, perl: perl)))
		}
		return tail
	}

	@_specialize(Bool) @_specialize(Int) @_specialize(UInt) @_specialize(Double) @_specialize(String) @_specialize(PerlScalar)
	func fetchTail<T : PerlSvConvertible>(startingAt index: Int) throws -> [String: T] {
		guard index < args.count else { return [:] }
		var tail: [String: T] = [:]
		var i = args[index..<args.count].makeIterator()
		while let name = i.next() {
			guard let value = i.next() else { throw PerlError.oddElementsHash }
			tail[try String(UnsafeSvContext(sv: name, perl: perl))] = try T(_fromUnsafeSvContextCopy: UnsafeSvContext(sv: value, perl: perl))
		}
		return tail
	}
}

struct UnsafeCallStack : UnsafeStack {
	let perl: UnsafeInterpreterPointer

	init<C : Collection>(perl: UnsafeInterpreterPointer, args: C)
		where C.Iterator.Element == UnsafeSvPointer, C.IndexDistance == Int {
		self.perl = perl
		var sp = perl.pointee.Istack_sp!
		perl.pointee.PUSHMARK(sp)
		pushTo(sp: &sp, from: args)
	}

	func popReturned(count: Int) -> UnsafeStackBufferPointer {
		return perl.pointee.popFromStack(count: count)
	}
}

extension UnsafeInterpreter {
	mutating func popFromStack(count: Int) -> UnsafeStackBufferPointer {
		var sp = Istack_sp!
		sp -= count
		let result = UnsafeStackBufferPointer(start: UnsafeMutableRawPointer(sp + 1).assumingMemoryBound(to: UnsafeSvPointer.self), count: count)
		Istack_sp = sp
		return result
	}
}
