func isStrictSubclass(_ child: AnyClass, of parent: AnyClass) -> Bool {
	var cur: AnyClass = child
	while let next = _getSuperclass(cur) {
		cur = next
		if cur == parent {
			return true
		}
	}
	return false
}
