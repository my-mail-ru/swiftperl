final class PerlCoro : PerlObjectType {
	static let perlClassName = "Coro"
	let sv: PerlSV
	init(_ sv: PerlSV) { self.sv = sv }

// use CoroAPI
//	static func schedule() { return try! call(method: "schedule") }
//	static func cede() { return try! call(method: "cede") }

	convenience init(_ cv: PerlCV, args: PerlSVConvertible...) {
		self.init(try! PerlCoro.call(method: "new", args: [cv] + args) as PerlSV)
	}

	func ready() -> Bool { return try! call(method: "ready") }
	func suspend() { return try! call(method: "suspend") }
	func resume() { return try! call(method: "resume") }

	var isNew: Bool { return try! call(method: "is_new") }
	var isZombie: Bool { return try! call(method: "is_zombie") }

	var isReady: Bool { return try! call(method: "is_ready") }
	var isRunning: Bool { return try! call(method: "is_running") }
	var isSuspended: Bool { return try! call(method: "is_suspended") }

	// func cancel
	// func safeCancel
	
	// func scheduleTo
	// func cedeTo

	// func throw
	
	func join() { return try! call(method: "join") }

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
		set { return try! call(method: "prio", args: newValue.rawValue) }
	}

	func nice(_ change: Int) -> Prio { return Prio(rawValue: try! call(method: "nice", args: change))! }

	func desc(_ desc: String) -> String { return try! call(method: "desc", args: desc) }
}
