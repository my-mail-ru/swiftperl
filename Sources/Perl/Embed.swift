import CPerl
#if os(Linux) || os(FreeBSD) || os(PS4) || os(Android) || CYGWIN
import func Glibc.atexit
#elseif os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import func Darwin.atexit
#endif

private var perlInitialized: Bool = {
	PerlInterpreter.sysInit()
	atexit { PerlInterpreter.sysTerm() }
	return true
}()

extension PerlInterpreter {
	static func sysInit() {
		var argc = CommandLine.argc
		var argv = CommandLine.unsafeArgv
		var env = environ!
		PERL_SYS_INIT3(&argc, &argv, &env)
	}

	static func sysTerm() {
		PERL_SYS_TERM()
	}

	/// Creates a new embedded Perl interpreter.
	public static func new() -> PerlInterpreter {
		_ = perlInitialized
		let perl = PerlInterpreter(Pointee.alloc()!)
		perl.pointee.construct()
		perl.embed()
		return perl
	}

	/// Shuts down the Perl interpreter.
	public func destroy() {
		pointee.destruct()
		pointee.free()
	}

	func embed() {
		pointee.Iorigalen = 1
		pointee.Iperl_destruct_level = 2
		pointee.Iexit_flags |= UInt8(PERL_EXIT_DESTRUCT_END)
		let args: StaticString = "\0-e\00\0"
		args.withUTF8Buffer {
			$0.baseAddress!.withMemoryRebound(to: CChar.self, capacity: $0.count) {
				let start = UnsafeMutablePointer<CChar>(mutating: $0)
				var cargs: [UnsafeMutablePointer<CChar>?] = [start, start + 1, start + 4]
				let status = cargs.withUnsafeMutableBufferPointer {
					pointee.parse(xs_init, Int32($0.count), $0.baseAddress, nil)
				}
				assert(status == 0)
			}
		}
	}
}
