import func CPerl.SvOK

public protocol UnsafeSvProtocol {
	static var type: SvType { get }
}

extension UnsafeSV : UnsafeSvProtocol {
	public static var type: SvType { return .scalar }
}

public protocol UnsafeSvCastable : UnsafeSvProtocol {}

extension UnsafeAV : UnsafeSvCastable {
	public static var type: SvType { return .array }
}

extension UnsafeHV : UnsafeSvCastable {
	public static var type: SvType { return .hash }
}

extension UnsafeCV : UnsafeSvCastable {
	public static var type: SvType { return .code }
}

extension UnsafeSvCastable {
	@discardableResult
	mutating func refcntInc() -> UnsafeMutablePointer<Self> {
		let ptr = UnsafeMutablePointer(mutating: &self)
		ptr.withMemoryRebound(to: UnsafeSV.self, capacity: 1) {
			_ = $0.pointee.refcntInc()
		}
		return ptr
	}

	mutating func refcntDec(perl: UnsafeInterpreterPointer) {
		UnsafeMutablePointer(mutating: &self).withMemoryRebound(to: UnsafeSV.self, capacity: 1) {
			$0.pointee.refcntDec(perl: perl)
		}
	}
}

extension UnsafeMutablePointer where Pointee : UnsafeSvCastable {
	init?(autoDeref sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		let v: UnsafeSvPointer
		if sv.pointee.type == .scalar {
			guard SvOK(sv) else { return nil }
			guard let xv = sv.pointee.referent else {
				throw PerlError.unexpectedSvType(fromUnsafeSvPointer(inc: sv, perl: perl), want: Pointee.type)
			}
			v = xv
		} else {
			v = sv
		}
		guard v.pointee.type == Pointee.type else {
			throw PerlError.unexpectedSvType(fromUnsafeSvPointer(inc: sv, perl: perl), want: Pointee.type)
		}
		self = UnsafeMutableRawPointer(v).bindMemory(to: Pointee.self, capacity: 1)
	}
}
