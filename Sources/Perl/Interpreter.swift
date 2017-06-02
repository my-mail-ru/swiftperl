import CPerl

/// A Perl interpreter.
///
/// This type hides a pointer to the underlying C Perl interpreter and
/// provides a clean Swifty interface to it.
/// It doesn't provide any guarantees about a Perl interpreter
/// instance aliveness and should be used only while they are provided
/// by outer conditions.
/// Generally it is not a problem because a Perl interpreter is only
/// created once on startup and destroyed on shutdown of a process.
/// In the case of an XS module an interpreter aliveness is guaranteed
/// during the scope of an XSUB call.
///
/// ## Embedding a Perl interpreter
///
/// ```swift
/// let perl = PerlInterpreter.new()
/// try perl.eval("print qq/OK\\n/") // Do something interesting with Perl
/// perl.destroy()
/// ```
///
/// ## Writting an XS module
///
/// ```swift
/// @_cdecl("boot_Your__Module__Name")
/// public func boot(_ perl: PerlInterpreter.Pointer) {
///		let perl = PerlInterpreter(perl)
///		// Create XSUBs
///		PerlSub(name: "test", perl: perl) { () -> Void in
///			print("OK")
///		}
/// }
/// ```
public struct PerlInterpreter {
	typealias Pointee = CPerl.PerlInterpreter

	/// A type of the pointer to the underlying C `PerlInterpreter`.
	public typealias Pointer = UnsafeMutablePointer<CPerl.PerlInterpreter>

	/// A pointer to the underlying C `PerlInterpreter` structure.
	public let pointer: Pointer

	var pointee: Pointee {
		unsafeAddress {
			return UnsafePointer(pointer)
		}
		nonmutating unsafeMutableAddress {
			return pointer
		}
	}

	/// Wrap a pointer to the C `PerlInterpreter` structure.
	public init(_ pointer: Pointer) {
		self.pointer = pointer
	}

	/// A Perl interpreter stored in the thread local storage.
	public static var current: PerlInterpreter {
		get { return PerlInterpreter(PERL_GET_THX()) }
		set { PERL_SET_THX(newValue.pointer) }
	}

	/// The main Perl interpreter of the process.
	public static var main: PerlInterpreter {
		get { return PerlInterpreter(PERL_GET_INTERP()) }
		set { PERL_SET_INTERP(newValue.pointer) }
	}

	var error: UnsafeSvContext {
		return UnsafeSvContext(sv: pointee.ERRSV, perl: self)
	}

	/// Loads the module by name.
	/// It is analogous to Perl code `eval "require $module"` and even implemented that way.
	public func require(_ module: String) throws {
		try eval("require \(module)")
	}

	/// Loads the module by its file name.
	/// It is analogous to Perl code `eval "require '$file'"` and even implemented that way.
	public func require(file: String) throws {
		try eval("require q\0\(file)\0")
	}

	func getSV(_ name: String, flags: Int32 = 0) -> UnsafeSvPointer? {
		return pointee.get_sv(name, SVf_UTF8|flags)
	}

	func getAV(_ name: String, flags: Int32 = 0) -> UnsafeAvPointer? {
		return pointee.get_av(name, SVf_UTF8|flags)
	}

	func getHV(_ name: String, flags: Int32 = 0) -> UnsafeHvPointer? {
		return pointee.get_hv(name, SVf_UTF8|flags)
	}

	func getCV(_ name: String, flags: Int32 = 0) -> UnsafeCvPointer? {
		return pointee.get_cv(name, SVf_UTF8|flags)
	}
}
