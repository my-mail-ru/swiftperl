/// Provides a safe wrapper for any SV, which can contain any Perl value,
/// not only scalars. Performs reference counting on initialization and
/// deinitialization.
open class PerlValue : AnyPerl, CustomDebugStringConvertible {
	private let sv: UnsafeSvPointer
	let perl: UnsafeInterpreterPointer

	/// Unsafely creates an instance without incrementing a reference counter of a SV.
	/// Performs no type checks and should be used only if compatibility is known.
	public required init(noincUnchecked sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) {
		self.sv = sv
		self.perl = perl
	}

	/// Unsafely creates an instance incrementing a reference counter of a SV.
	/// Performs no type checks and should be used only if compatibility is known.
	public required init(incUnchecked sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) {
		self.sv = sv.pointee.refcntInc()
		self.perl = perl
	}

	/// Unsafely creates an instance without incrementing a reference counter of a SV.
	/// Performs type checks and throws an error unless compatible.
	public convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		self.init(noincUnchecked: sv, perl: perl)
	}

	/// Unsafely creates an nstance incrementing a reference counter of a SV.
	/// Performs type checks and throws an error unless compatible.
	public convenience init(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(noinc: sv.pointee.refcntInc(), perl: perl)
	}

	deinit {
		sv.pointee.refcntDec(perl: perl)
	}

	/// Invokes the given closure on the unsafe pointers to the SV and the Perl Interpreter.
	///
	/// The `withUnsafeSvPointer(_:)` method ensures that the SV's
	/// lifetime extends through the execution of `body`.
	///
	/// - Parameter body: A closure that takes unsafe pointers to the SV and the Perl Interpreter
	///   as its arguments. If the closure has a return value, it is used as the
	///   return value of the `withUnsafeSvPointer(_:)` method.
	/// - Returns: The return value of the `body` closure, if any.
	public final func withUnsafeSvPointer<R>(_ body: (UnsafeSvPointer, UnsafeInterpreterPointer) throws -> R) rethrows -> R {
		return try body(sv, perl)
	}

	var type: SvType {
		return sv.pointee.type
	}

	static func derivedClass(for sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) -> PerlValue.Type {
		switch sv.pointee.type {
			case .scalar:
				if let classname = sv.pointee.classname(perl: perl) {
					return PerlObject.derivedClass(for: classname)
				} else {
					return PerlSV.self
				}
			case .array: return PerlAV.self
			case .hash: return PerlHV.self
			case .code: return PerlCV.self
			default: return PerlValue.self
		}
	}

	static func initDerived(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) -> PerlValue {
		let subclass = derivedClass(for: sv, perl: perl)
		return subclass.init(noincUnchecked: sv, perl: perl)
	}

	static func initDerived(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) -> PerlValue {
		let subclass = derivedClass(for: sv, perl: perl)
		return subclass.init(incUnchecked: sv, perl: perl)
	}

	/// A textual representation of the SV, suitable for debugging.
	public var debugDescription: String {
		return "PerlValue(\(type))"
	}
}
