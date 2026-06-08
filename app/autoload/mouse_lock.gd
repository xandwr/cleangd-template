## Single writer for the OS mouse mode. Gameplay captures the cursor for look
## control; anything that needs it free (pause, dialogs, inventory, console)
## requests a release and holds the returned handle for as long as it needs.
##
## Releases are refcounted: the cursor stays free while ANY handle is live and
## re-captures only when the last one is dropped, so overlapping requesters
## (a dialog opening over a pause menu) compose without coordinating. Window
## focus loss frees the cursor regardless and restores intent on regain.
##
## Registered as an autoload named MouseLock. Nothing else should touch
## Input.mouse_mode directly.
extends Node

## What unlock exposes the cursor as. VISIBLE frees it to leave the window;
## CONFINED keeps it inside for borderless/menu UX without capturing look.
enum UnlockKind { VISIBLE, CONFINED }

## Cursor mode used while gameplay holds the lock with no active releases.
@export var captured_mode := Input.MOUSE_MODE_CAPTURED
## Cursor mode used while one or more release handles are live.
@export var unlock_kind := UnlockKind.VISIBLE

## True once gameplay has asked to capture at all. Before this we leave the OS
## mouse alone so menus/boot UI keep a normal cursor without anyone asking.
var _capture_wanted := false
var _holders: Array[MouseLockHandle] = []
var _focused := true


func _ready() -> void:
	# Survive scene-tree pauses: the mouse must still resolve while paused so a
	# pause menu can free the cursor.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Gameplay calls this to take the cursor (typically on the player spawning /
## a level becoming active). Idempotent.
func capture() -> void:
	_capture_wanted = true
	_apply()


## Gameplay calls this to permanently give the cursor back (level unloaded,
## returned to menu). Outstanding release handles become moot.
func release_capture() -> void:
	_capture_wanted = false
	_apply()


## Request the cursor be freed. Hold the returned handle for as long as you need
## it free; release() it (or drop the reference) to withdraw the request. The
## cursor re-captures only when no handle remains and gameplay still wants it.
func request_unlock(reason: String = "") -> MouseLockHandle:
	var handle := MouseLockHandle.new(reason)
	_holders.append(handle)
	_apply()
	return handle


## True when gameplay wants the cursor and nothing is currently holding it free.
## Useful for look code that should ignore motion while the cursor is loose.
func is_captured() -> bool:
	return _capture_wanted and _holders.is_empty() and _focused


func _drop(handle: MouseLockHandle) -> void:
	_holders.erase(handle)
	_apply()


func _apply() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_MOUSE):
		return  # Headless / no window: nothing to set, safe to call anywhere.

	var mode: Input.MouseMode
	if not _capture_wanted:
		mode = Input.MOUSE_MODE_VISIBLE
	elif _holders.is_empty() and _focused:
		mode = captured_mode
	else:
		mode = Input.MOUSE_MODE_CONFINED if unlock_kind == UnlockKind.CONFINED \
			else Input.MOUSE_MODE_VISIBLE

	if Input.mouse_mode != mode:
		Input.mouse_mode = mode


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
			_apply()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
			_apply()
