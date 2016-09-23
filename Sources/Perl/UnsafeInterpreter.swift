import CPerl
import var Glibc.environ

typealias UnsafeInterpreter = CPerl.PerlInterpreter
typealias UnsafeInterpreterPointer = UnsafeMutablePointer<UnsafeInterpreter>

extension UnsafeInterpreter {
	static var main: UnsafeInterpreterPointer {
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
				var cargs: [UnsafeMutablePointer<CChar>?] = [$0, $0 + 1, $0 + 4]
				let status = cargs.withUnsafeMutableBufferPointer {
					parse(xs_init, Int32($0.count), $0.baseAddress, nil)
				}
				assert(status == 0)
			}
		}
	}

	mutating func loadModule(_ module: String) {
		let sv = newSV(module)
		// Perl's load_module() decrements refcnt for each passed SV*
		load_module_noargs(0, sv, nil)
	}

	mutating func getSV(_ name: String, flags: Int32 = 0) -> UnsafeSvPointer? {
		return get_sv(name, SVf_UTF8|flags)
	}
}
