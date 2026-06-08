## A live request to free the mouse cursor, handed back by MouseLock.request_unlock.
## Hold it open to keep the cursor free; release() it (or drop the last reference)
## to withdraw the request. The cursor re-captures only when no handle remains.
## Idempotent and safe to release twice.
class_name MouseLockHandle extends RefCounted

var _reason: String
var _released := false


func _init(reason: String) -> void:
	_reason = reason


func release() -> void:
	if _released:
		return
	_released = true
	# Deferred so releasing during a teardown/signal can't re-enter the mode
	# resolve mid-frame; the singleton reconciles on the next idle.
	MouseLock._drop.call_deferred(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		release()
