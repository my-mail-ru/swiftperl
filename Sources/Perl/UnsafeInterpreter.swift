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

	public mutating func loadModule(_ module: String) {
		let sv = newSV(module)
		// Perl's load_module() decrements refcnt for each passed SV*
		load_module_noargs(0, sv, nil)
	}

	public mutating func getSV(_ name: String, flags: Int32 = 0) -> UnsafeSvPointer? {
		return get_sv(name, SVf_UTF8|flags)
	}
}
