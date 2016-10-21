import func Glibc.atexit
import var CPerl.GV_ADD

public final class PerlInterpreter {
	var pointer: UnsafeInterpreterPointer

	static var initialized: Bool = {
		UnsafeInterpreter.sysInit()
		atexit { UnsafeInterpreter.sysTerm() }
		return true
	}()

	public init() {
		_ = PerlInterpreter.initialized
		pointer = UnsafeInterpreter.alloc()
		pointer.pointee.construct()
		pointer.pointee.embed()
	}

	deinit {
		pointer.pointee.destruct()
		pointer.pointee.free()
	}

	public func withUnsafeInterpreterPointer<R>(_ body: (UnsafeInterpreterPointer) throws -> R) rethrows -> R {
		return try body(pointer)
	}

	public func getSV(_ name: String) -> PerlSV? {
		return pointer.pointee.getSV(name).map { PerlSV(incUnchecked: $0, perl: pointer) }
	}

	public func getSV(add name: String) -> PerlSV {
		return PerlSV(incUnchecked: pointer.pointee.getSV(name, flags: GV_ADD)!, perl: pointer)
	}
}
