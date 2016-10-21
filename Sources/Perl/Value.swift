class PerlValue : AnyPerl, CustomDebugStringConvertible {
	private let sv: UnsafeSvPointer
	let perl: UnsafeInterpreterPointer

	required init(noincUnchecked sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) {
		self.sv = sv
		self.perl = perl
	}

	required init(incUnchecked sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) {
		self.sv = sv.pointee.refcntInc()
		self.perl = perl
	}

	convenience init(noinc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		self.init(noincUnchecked: sv, perl: perl)
	}

	convenience init(inc sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer) throws {
		try self.init(noinc: sv.pointee.refcntInc(), perl: perl)
	}

	deinit {
		sv.pointee.refcntDec(perl: perl)
	}

	func withUnsafeSvPointer<R>(_ body: (UnsafeSvPointer, UnsafeInterpreterPointer) throws -> R) rethrows -> R {
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

	var debugDescription: String {
		return "PerlValue(\(type))"
	}
}
