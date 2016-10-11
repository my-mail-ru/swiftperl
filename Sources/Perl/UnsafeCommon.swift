import func CPerl.SvOK

protocol UnsafeSvProtocol {}

extension UnsafeSV : UnsafeSvProtocol {}

protocol UnsafeSvCastable : UnsafeSvProtocol {
	static var type: SvType { get }
}

extension UnsafeAV : UnsafeSvCastable {
	static var type: SvType { return .array }
}

extension UnsafeHV : UnsafeSvCastable {
	static var type: SvType { return .hash }
}

extension UnsafeCV : UnsafeSvCastable {
	static var type: SvType { return .code }
}

extension UnsafeSvCastable {
	typealias Pointer = UnsafeMutablePointer<Self>

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
	init?(_ sv: UnsafeSvPointer, perl: UnsafeInterpreterPointer = UnsafeInterpreter.current) throws {
		guard SvOK(sv) else { return nil }
		let v = sv.pointee.referent ?? sv
		guard v.pointee.type == Pointee.type else { throw PerlError.unexpectedType(PerlSV(sv), want: Pointee.type) }
		self = UnsafeMutableRawPointer(v).bindMemory(to: Pointee.self, capacity: 1)
	}
}
