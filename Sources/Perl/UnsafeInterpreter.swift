import CPerl
import var Glibc.environ

public typealias UnsafeInterpreter = CPerl.PerlInterpreter
public typealias UnsafeInterpreterPointer = UnsafeMutablePointer<UnsafeInterpreter>

extension UnsafeInterpreter {
	public static var main: UnsafeInterpreterPointer {
		get { return PL_curinterp }
		set { PL_curinterp = newValue }
	}

	static func sysInit() {
		var argc = CommandLine.argc
		var argv = CommandLine.unsafeArgv
		var env = environ
		PERL_SYS_INIT3(&argc, &argv, &env)
	}

	static func sysTerm() {
		PERL_SYS_TERM()
	}

	mutating func embed() {
		Iorigalen = 1
		Iperl_destruct_level = 2
		Iexit_flags |= UInt8(PERL_EXIT_DESTRUCT_END)
		let args: StaticString = "\0-e\00\0"
		args.withUTF8Buffer {
			$0.baseAddress!.withMemoryRebound(to: CChar.self, capacity: $0.count) {
				let start = UnsafeMutablePointer(mutating: $0)
				var cargs: [UnsafeMutablePointer<CChar>?] = [start, start + 1, start + 4]
				let status = cargs.withUnsafeMutableBufferPointer {
					parse(xs_init, Int32($0.count), $0.baseAddress, nil)
				}
				assert(status == 0)
			}
		}
	}

	@available(*, deprecated, renamed: "require(_:)")
	public mutating func loadModule(_ module: String) {
		let sv = newSV(module)
		// Perl's load_module() decrements refcnt for each passed SV*
		load_module_noargs(0, sv, nil)
	}

	/// Loads the module by name.
	/// It is analogous to Perl code `eval "require $module"` and even implemented that way.
	public mutating func require(_ module: String) throws {
		try eval("require \(module)")
	}

	/// Loads the module by its file name.
	/// It is analogous to Perl code `eval "require '$file'"` and even implemented that way.
	public mutating func require(file: String) throws {
		try eval("require q\0\(file)\0")
	}

	/// Returns the SV of the specified Perl scalar.
	/// If `GV_ADD` is set in `flags` and the Perl variable does not exist then it will be created.
	/// If `flags` is zero and the variable does not exist then `nil` is returned.
	public mutating func getSV(_ name: String, flags: Int32 = 0) -> UnsafeSvPointer? {
		return get_sv(name, SVf_UTF8|flags)
	}

	/// Returns the AV of the specified Perl array.
	/// If `GV_ADD` is set in `flags` and the Perl variable does not exist then it will be created.
	/// If `flags` is zero and the variable does not exist then `nil` is returned.
	public mutating func getAV(_ name: String, flags: Int32 = 0) -> UnsafeAvPointer? {
		return get_av(name, SVf_UTF8|flags)
	}

	/// Returns the HV of the specified Perl hash.
	/// If `GV_ADD` is set in `flags` and the Perl variable does not exist then it will be created.
	/// If `flags` is zero and the variable does not exist then `nil` is returned.
	public mutating func getHV(_ name: String, flags: Int32 = 0) -> UnsafeHvPointer? {
		return get_hv(name, SVf_UTF8|flags)
	}

	/// Returns the CV of the specified Perl subroutine.
	/// If `GV_ADD` is set in `flags` and the Perl subroutine does not exist then it will be declared
	/// (which has the same effect as saying `sub name;`).
	/// If `GV_ADD` is not set and the subroutine does not exist then `nil` is returned.
	public mutating func getCV(_ name: String, flags: Int32 = 0) -> UnsafeCvPointer? {
		return get_cv(name, SVf_UTF8|flags)
	}
}
