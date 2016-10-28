import func Glibc.atexit
import var CPerl.GV_ADD

/// A safe Perl Interpreter.
///
/// Instances of this class are useful for embedding Perl Interpreter
/// into your Swift program. For other cases this implementation is
/// mostly abandoned for performance reasons and should be rethinked.
///
/// - SeeAlso: UnsafeInterpreter
/// - SeeAlso: perlembed(1)
public final class PerlInterpreter {
	var pointer: UnsafeInterpreterPointer

	static var initialized: Bool = {
		UnsafeInterpreter.sysInit()
		atexit { UnsafeInterpreter.sysTerm() }
		return true
	}()

	/// Embeds new Perl Interpreter.
	/// Interpreter exists while constructed object alive.
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

	/// Invokes the given closure on the unsafe pointer to the Perl Interpreter.
	///
	/// The `withUnsafeInterpreterPointer(_:)` method ensures that the Interpreter's
	/// lifetime extends through the execution of `body`.
	///
	/// - Parameter body: A closure that takes unsafe pointer to the Perl Interpreter
	///   as its sole argument. If the closure has a return value, it is used as the
	///   return value of the `withUnsafeInterpreterPointer(_:)` method.
	/// - Returns: The return value of the `body` closure, if any.
	public func withUnsafeInterpreterPointer<R>(_ body: (UnsafeInterpreterPointer) throws -> R) rethrows -> R {
		return try body(pointer)
	}

	/// Returns the SV of the specified Perl global or package scalar with the given name.
	/// If the variable does not exist then `nil` is returned.
	public func getSV(_ name: String) -> PerlScalar? {
		return pointer.pointee.getSV(name).map { PerlScalar(incUnchecked: $0, perl: pointer) }
	}

	/// Returns the SV of the specified Perl global or package scalar with the given name.
	/// If the variable does not exist then it will be created.
	public func getSV(add name: String) -> PerlScalar {
		return PerlScalar(incUnchecked: pointer.pointee.getSV(name, flags: GV_ADD)!, perl: pointer)
	}
}
