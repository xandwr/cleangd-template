# tests

Use this for automated tests, fixtures, mocks, and test scenes. Keep test-only
helpers here so production folders stay focused.

Good examples:

- `tests/unit/test_weighted_picker.gd`
- `tests/integration/test_save_system.gd`
- `tests/fixtures/sample_inventory.tres`
- `tests/scenes/physics_probe.tscn`

For GDScript projects, this folder can hold tests for GdUnit4, Gut, or a custom
test runner. For C# projects, it can hold Godot integration scenes plus any
external test project notes.

Avoid relying on tests to patch project state permanently. Tests should clean
up files, nodes, and settings they create.
