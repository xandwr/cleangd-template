## A live request to free the mouse cursor, handed back by MouseLock.request_unlock.
## Hold it open to keep the cursor free; release() it (or drop the last reference)
## to withdraw the request. The cursor re-captures only when no handle remains.
## Idempotent and safe to release twice.
class_name MouseLockHandle extends RefCounted

var _reason: String
var _released := false
var _owner: WeakRef


func _init(owner: Node, reason: String) -> void:
	_owner = weakref(owner)
	_reason = reason


func release() -> void:
	if _released:
		return
	_released = true
	# Hold the owner weakly and resolve it here rather than touching the MouseLock
	# global: during app shutdown the autoload Node is freed before lingering
	# handles finalize. A WeakRef to a freed Node can still resolve non-null
	# (freed-but-not-cleared), so guard with is_instance_valid, not just a null
	# check — otherwise _drop dispatches on a dead instance and faults.
	var owner = _owner.get_ref()
	if not is_instance_valid(owner) or owner.is_shutting_down():
		return
	# Explicit release may run mid-signal/teardown; defer so the mode resolve
	# can't re-enter this frame. The singleton reconciles on the next idle.
	owner._drop.call_deferred(self)


func _notification(what: int) -> void:
	# NOTIFICATION_PREDELETE fires both for ordinary handle drops (live app) and
	# during engine shutdown, where the MouseLock autoload may already be gone.
	# Resolve and validate the owner inline here — calling out to _release and
	# letting it dispatch on a dead owner is what faulted. If the owner is still
	# valid we drop synchronously; if not, there is nothing left to reconcile.
	if what != NOTIFICATION_PREDELETE or _released:
		return
	_released = true
	var owner = _owner.get_ref()
	# is_instance_valid is necessary but NOT sufficient during shutdown: the node
	# can be valid while its members are mid-unwind, so _drop would fault. The
	# owner's own teardown flag is the real gate.
	if is_instance_valid(owner) and not owner.is_shutting_down():
		owner._drop(self)
