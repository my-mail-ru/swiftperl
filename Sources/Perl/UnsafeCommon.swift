protocol UnsafeSvProtocol {}
protocol UnsafeSvCastProtocol : UnsafeSvProtocol {}
extension UnsafeSV : UnsafeSvProtocol {}
extension UnsafeAV : UnsafeSvCastProtocol {}
extension UnsafeHV : UnsafeSvCastProtocol {}
extension UnsafeCV : UnsafeSvCastProtocol {}

extension UnsafeSvCastProtocol {
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
