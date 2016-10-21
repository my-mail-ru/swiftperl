import func Glibc.atexit

final class PerlInterpreter {
	var pointer: UnsafeInterpreterPointer

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
