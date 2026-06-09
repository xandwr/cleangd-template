using Godot;

namespace Xandbox.Player;

/// Camera-relative kinematic mover. Mouse X yaws the whole body; mouse Y
/// pitches only the camera arm. WASD moves relative to where the body faces,
/// so movement always tracks the camera. Gravity comes from project settings.
[GlobalClass]
public partial class PlayerBody : CharacterBody3D
{
    /// Spring-arm length per view: collapsed onto the head for first-person,
    /// pulled back behind the body for third-person.
    public enum CameraPerspective { FirstPerson, ThirdPerson }

    private CameraPerspective _perspective = CameraPerspective.FirstPerson;

    [Export]
    public CameraPerspective Perspective
    {
        get => _perspective;
        set
        {
            _perspective = value;
            ApplyPerspective();
        }
    }

    /// Distance the arm pulls back in third-person.
    [Export]
    public float ThirdPersonDistance = 3.0f;

    [Export]
    public float Speed = 5.0f;

    [Export]
    public float SprintSpeed = 8.0f;

    [Export]
    public float JumpSpeed = 8.0f;

    [Export(PropertyHint.Range, "0.0001,0.01")]
    public float MouseSensitivity = 0.003f;

    private SpringArm3D _cameraArm;
    private float _gravity = (float)ProjectSettings.GetSetting("physics/3d/default_gravity");

    public override void _Ready()
    {
        _cameraArm = GetNode<SpringArm3D>("%CameraArm");
        ApplyPerspective();
        Input.MouseMode = Input.MouseModeEnum.Captured;
    }

    private void ApplyPerspective()
    {
        if (_cameraArm == null)
            return;
        _cameraArm.SpringLength = _perspective == CameraPerspective.ThirdPerson
            ? ThirdPersonDistance
            : 0.0f;
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

        if (Input.IsActionJustPressed("toggle_perspective"))
            Perspective = _perspective == CameraPerspective.FirstPerson
                ? CameraPerspective.ThirdPerson
                : CameraPerspective.FirstPerson;
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
