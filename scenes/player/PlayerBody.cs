using Godot;

namespace Xandbox.Player;

/// Camera-relative kinematic mover. Mouse X yaws the whole body; mouse Y
/// pitches only the camera arm. WASD moves relative to where the body faces,
/// so movement always tracks the camera. Gravity comes from project settings.
[GlobalClass]
public partial class PlayerBody : CharacterBody3D
{
	[Export]
	public float Speed = 3.5f;

	[Export]
	public float SprintSpeed = 6.5f;

	[Export]
	public float JumpSpeed = 6.0f;

	[Export(PropertyHint.Range, "0.0001,0.01")]
	public float MouseSensitivity = 0.002f;

	private SpringArm3D _cameraArm;
	private float _gravity = (float)ProjectSettings.GetSetting("physics/3d/default_gravity");

	public override void _Ready()
	{
		_cameraArm = GetNode<SpringArm3D>("%CameraArm");
		Input.MouseMode = Input.MouseModeEnum.Captured;
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventMouseMotion motion && Input.MouseMode == Input.MouseModeEnum.Captured)
		{
			RotateY(-motion.Relative.X * MouseSensitivity);

			var pitch = _cameraArm.Rotation;
			pitch.X = Mathf.Clamp(
				pitch.X - motion.Relative.Y * MouseSensitivity,
				Mathf.DegToRad(-89.0f),
				Mathf.DegToRad(89.0f));
			_cameraArm.Rotation = pitch;
		}

		if (Input.IsActionJustPressed("pause"))
			Input.MouseMode = Input.MouseMode == Input.MouseModeEnum.Captured
				? Input.MouseModeEnum.Visible
				: Input.MouseModeEnum.Captured;
	}

	public override void _PhysicsProcess(double delta)
	{
		var velocity = Velocity;

		if (!IsOnFloor())
			velocity.Y -= _gravity * (float)delta;

		if (Input.IsActionJustPressed("move_jump") && IsOnFloor())
			velocity.Y = JumpSpeed;

		var input = Input.GetVector("move_left", "move_right", "move_forward", "move_backward");
		var direction = (Transform.Basis * new Vector3(input.X, 0.0f, input.Y)).Normalized();
		var speed = Input.IsActionPressed("move_sprint") ? SprintSpeed : Speed;

		velocity.X = direction.X * speed;
		velocity.Z = direction.Z * speed;

		Velocity = velocity;
		MoveAndSlide();
	}
}
