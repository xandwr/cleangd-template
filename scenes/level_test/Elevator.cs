using Godot;

namespace Xandbox.Csg;

/// Drives a PathFollow3D back and forth along its parent Path3D. Whatever
/// rides the platform is parented to this node, so it inherits the motion.
/// The cube ping-pongs between the bottom and top of PinkElevatorPath.
[GlobalClass]
public partial class Elevator : PathFollow3D
{
    /// Units travelled along the curve per second.
    [Export]
    public float Speed = 2.0f;

    /// Seconds to wait at each end before reversing.
    [Export]
    public float DwellTime = 1.5f;

    private int _direction = 1;
    private float _dwellRemaining;

    public override void _Ready()
    {
        Loop = false;
        Progress = 0.0f;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_dwellRemaining > 0.0f)
        {
            _dwellRemaining -= (float)delta;
            return;
        }

        ProgressRatio += _direction * Speed * (float)delta / GetCurveLength();

        if (ProgressRatio >= 1.0f || ProgressRatio <= 0.0f)
        {
            ProgressRatio = Mathf.Clamp(ProgressRatio, 0.0f, 1.0f);
            _direction = -_direction;
            _dwellRemaining = DwellTime;
        }
    }

    private float GetCurveLength()
    {
        var curve = (GetParent() as Path3D)?.Curve;
        return curve != null ? curve.GetBakedLength() : 1.0f;
    }
}
