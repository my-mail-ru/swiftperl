import CPerlCoro

// TODO generic on function argument
final class PerlCoro : PerlObjectType {
	static let perlClassName = "Coro"
	let sv: PerlSV
	init(_ sv: PerlSV) { self.sv = sv }

	enum Error : ErrorProtocol {
		case coroApiNotFound
		case coroApiVersionMismatch(used: (ver: Int32, rev: Int32), compiled: (ver: Int32, rev: Int32))
	}

	static var coroApi: UnsafeMutablePointer<CoroAPI>!
	static var perl: UnsafeInterpreterPointer!

	static func initialize(perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws { // FIXME = UnsafeInterpreter.main?
		self.perl = perl
		perl.pointee.loadModule("Coro")
		guard let sv = perl.pointee.getSV("Coro::API") else {
			throw PerlCoro.Error.coroApiNotFound
		}
		coroApi = UnsafeMutablePointer<CoroAPI>(bitPattern: Int(sv))
		guard coroApi.pointee.ver == CORO_API_VERSION && coroApi.pointee.rev >= CORO_API_REVISION else {
			throw PerlCoro.Error.coroApiVersionMismatch(
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
		return PerlCoro(PerlSV(coroApi.pointee.current)) // is it?
	}

	static var readyhook: @convention(c) () -> () {
		get { return coroApi.pointee.readyhook }
		set { coroApi.pointee.readyhook = newValue }
	}

	convenience init(_ cv: PerlCV, args: PerlSVConvertible?...) {
		var args = args
		args.insert(cv, at: 0)
		self.init(try! PerlCoro.call(method: "new", args: args) as PerlSV)
	}

	@discardableResult
	func ready() -> Bool { return PerlCoro.coroApi.pointee.ready(PerlCoro.perl, sv.pointer) != 0 }
	func suspend() { return try! call(method: "suspend") }
	func resume() { return try! call(method: "resume") }

	var isNew: Bool { return try! call(method: "is_new") }
	var isZombie: Bool { return try! call(method: "is_zombie") }

	var isReady: Bool { return PerlCoro.coroApi.pointee.is_ready(PerlCoro.perl, sv.pointer) != 0 }
	var isRunning: Bool { return try! call(method: "is_running") }
	var isSuspended: Bool { return try! call(method: "is_suspended") }

	// func cancel
	// func safeCancel
	
	// func scheduleTo
	// func cedeTo

	// func throw
	
	func join<R : PerlSVConvertible>() -> R? { return try! call(method: "join") }

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
