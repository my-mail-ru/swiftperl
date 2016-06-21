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
		var argc = Process.argc
		var argv: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = Process.unsafeArgv
		var env: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = environ
		Perl_sys_init3(&argc, &argv, &env)
	}

	static func sysTerm() {
		Perl_sys_term()
	}

	static func alloc() -> UnsafeInterpreterPointer {
		return perl_alloc()
	}

	mutating func construct() {
		perl_construct(&self)
	}

	@discardableResult
	mutating func destruct() -> Int32 {
		return perl_destruct(&self)
	}

	mutating func free() {
		perl_free(&self)
	}

	mutating func embed() {
		Iorigalen = 1
		Iperl_destruct_level = 2
		Iexit_flags |= UInt8(PERL_EXIT_DESTRUCT_END)
		let status = "".withCString { a0 in
			"-e".withCString { a1 in
				"0".withCString { a2 in
					[a0, a1, a2].withUnsafeBufferPointer { perl_parse(&self, xs_init, Int32($0.count), UnsafeMutablePointer($0.baseAddress), nil) }
				}
			}
		}
		assert(status == 0)
	}

	mutating func loadModule(_ module: String) {
		let sv = newSV(module)
		// Perl's load_module() decrements refcnt for each passed SV*
		load_module_noargs(0, sv, nil)
	}

	mutating func getSV(_ name: String, flags: Int32 = 0) -> UnsafeSvPointer? {
		return name.withCString { Perl_get_sv(&self, $0, SVf_UTF8|flags) }
	}
}
