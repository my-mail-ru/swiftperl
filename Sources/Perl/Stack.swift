import CPerl

typealias UnsafeStackPointer = UnsafeMutablePointer<UnsafeSvPointer>
typealias UnsafeStackBufferPointer = UnsafeMutableBufferPointer<UnsafeSvPointer>

protocol UnsafeStack {
	var perl: UnsafeInterpreterPointer { get }
}

extension UnsafeStack {
	func pushTo<C : Collection where C.Iterator.Element == UnsafeSvPointer, C.IndexDistance == Int>
		(sp: inout UnsafeStackPointer, from source: C) {
		if !source.isEmpty {
			sp = UnsafeStackPointer(perl.pointee.EXTEND(sp, source.count))
			for sv in source {
				sp += 1
				sp.initialize(with: Perl_sv_2mortal(perl, sv))
			}
		}
		perl.pointee.Istack_sp = UnsafeMutablePointer(sp)
	}
}

struct UnsafeXSubStack : UnsafeStack {
	let args: UnsafeStackBufferPointer
	let perl: UnsafeInterpreterPointer

	init(perl: UnsafeInterpreterPointer) {
		self.perl = perl
		//SV **sp = (my_perl->Istack_sp); I32 ax = (*(my_perl->Imarkstack_ptr)--); SV **mark = (my_perl->Istack_base) + ax++; I32 items = (I32)(sp - mark);
		var sp: UnsafeStackPointer = UnsafeStackPointer(perl.pointee.Istack_sp)
		let ax = perl.pointee.POPMARK()
		let mark = UnsafeStackPointer(perl.pointee.Istack_base) + Int(ax)
		let items = sp - mark
		sp -= items
		args = UnsafeStackBufferPointer(start: sp + 1, count: items)
	}

	func xsReturn<C : Collection where C.Iterator.Element == UnsafeSvPointer, C.IndexDistance == Int>(_ result: C) {
		var sp: UnsafeStackPointer = args.baseAddress! - 1
		pushTo(sp: &sp, from: result)
	}
}

struct UnsafeCallStack : UnsafeStack {
	let perl: UnsafeInterpreterPointer

	init<C : Collection where C.Iterator.Element == UnsafeSvPointer, C.IndexDistance == Int>
		(perl: UnsafeInterpreterPointer, args: C) {
		self.perl = perl
		var sp: UnsafeStackPointer = UnsafeStackPointer(perl.pointee.Istack_sp)
		perl.pointee.PUSHMARK(sp)
		pushTo(sp: &sp, from: args)
	}

	func popReturned(count: Int) -> UnsafeStackBufferPointer {
		var sp: UnsafeStackPointer = UnsafeStackPointer(perl.pointee.Istack_sp)
		sp -= count
		let result = UnsafeStackBufferPointer(start: sp + 1, count: count)
		perl.pointee.Istack_sp = UnsafeMutablePointer(sp)
		return result
	}
}
