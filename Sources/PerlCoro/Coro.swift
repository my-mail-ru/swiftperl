import CPerlCoro
@testable import Perl

// TODO generic on function argument
final class PerlCoro : PerlObject, PerlNamedClass {
	static let perlClassName = "Coro"

	enum CoroError : Error {
		case coroApiNotFound
		case coroApiVersionMismatch(used: (ver: Int32, rev: Int32), compiled: (ver: Int32, rev: Int32))
	}

	static var coroApi: UnsafeMutablePointer<CoroAPI>!
	static var perl: UnsafeInterpreterPointer!

	static func initialize(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws { // FIXME = UnsafeInterpreter.main?
		self.perl = perl
		perl.pointee.loadModule("Coro")
		guard let sv = perl.pointee.getSV("Coro::API") else {
			throw PerlCoro.CoroError.coroApiNotFound
		}
		coroApi = UnsafeMutablePointer<CoroAPI>(bitPattern: Int(unchecked: sv))
		guard coroApi.pointee.ver == CORO_API_VERSION && coroApi.pointee.rev >= CORO_API_REVISION else {
			throw PerlCoro.CoroError.coroApiVersionMismatch(
				used: (ver: coroApi.pointee.ver, rev: coroApi.pointee.rev),
				compiled: (ver: CORO_API_VERSION, rev: CORO_API_REVISION)
			)
		}
	}

	static func schedule() {
		coroApi.pointee.schedule(perl)
	}

	@discardableResult
	static func cede(notSelf: Bool = false) -> Bool {
		let f = notSelf ? coroApi.pointee.cede_notself : coroApi.pointee.cede
		return f!(perl) != 0
	}

	static var nReady: Int32 {
		return coroApi.pointee.nready
	}

	static var current: PerlCoro {
		return PerlCoro(incUnchecked: coroApi.pointee.current, perl: PerlCoro.perl)
	}

	static var readyhook: @convention(c) () -> () {
		get { return coroApi.pointee.readyhook }
		set { coroApi.pointee.readyhook = newValue }
	}

	convenience init(_ cv: PerlCV, args: PerlSvConvertible?...) {
		var args = args
		args.insert(cv, at: 0)
		try! self.init(method: "new", args: args)
	}

	@discardableResult
	func ready() -> Bool {
		return withUnsafeSvPointer { sv, perl in PerlCoro.coroApi.pointee.ready!(perl, sv) != 0 }
	}

	func suspend() { return try! call(method: "suspend") }
	func resume() { return try! call(method: "resume") }

	var isNew: Bool { return try! call(method: "is_new") }
	var isZombie: Bool { return try! call(method: "is_zombie") }

	var isReady: Bool {
		return withUnsafeSvPointer { sv, perl in PerlCoro.coroApi.pointee.is_ready!(perl, sv) != 0 }
	}

	var isRunning: Bool { return try! call(method: "is_running") }
	var isSuspended: Bool { return try! call(method: "is_suspended") }

	// func cancel
	// func safeCancel
	
	// func scheduleTo
	// func cedeTo

	// func throw
	
	func join<R : PerlSvConvertible>() -> R? { return try! call(method: "join") }

	// func onDestroy
	
	enum Prio : Int {
		case max    = 3
		case high2  = 2
		case high   = 1
		case normal = 0
		case low    = -1
		case low2   = -2
		case idle   = -3
		case min    = -4
	}

	var prio: Prio {
		get { return Prio(rawValue: try! call(method: "prio"))! }
		set { return try! call(method: "prio", newValue.rawValue) }
	}

	func nice(_ change: Int) -> Prio { return Prio(rawValue: try! call(method: "nice", change))! }

	func desc(_ desc: String) -> String { return try! call(method: "desc", desc) }
}
