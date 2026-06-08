class_name TestSuite extends RefCounted

var _failures: int = 0
var _name: String = "suite"


func check(ok: bool, label: String) -> void:
	if ok:
		print("  PASS  %s" % label)
	else:
		_failures += 1
		print("  FAIL  %s" % label)


## Suites override this; return the failure count.
func run(_tree: SceneTree) -> int:
	push_error("TestSuite.run not overridden")
	return 1
