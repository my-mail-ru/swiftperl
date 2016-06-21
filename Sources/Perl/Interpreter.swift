import func Glibc.atexit

final class PerlInterpreter {
	typealias Pointer = UnsafeInterpreterPointer

	var pointer: Pointer

	static var initialized: Bool = {
		UnsafeInterpreter.sysInit()
		atexit { UnsafeInterpreter.sysTerm() }
		return true
	}()

	init() {
		_ = PerlInterpreter.initialized
		pointer = UnsafeInterpreter.alloc()
		pointer.pointee.construct()
		pointer.pointee.embed()
	}

	deinit {
		pointer.pointee.destruct()
		pointer.pointee.free()
	}
}
