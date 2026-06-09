using Godot;

namespace Xandbox.Csg;

[GlobalClass]
public partial class CSGBox : CsgBox3D, ICSGPart
{
    private PhysicsMode _mode = PhysicsMode.Static;

    [Export]
    public PhysicsMode Mode
    {
        get => _mode;
        set
        {
            if (value == _mode)
                return;
            _mode = value;
            _core?.OnModeChanged();
        }
    }

    private CSGPartCore _core;

    public override void _Ready()
    {
        _core = new CSGPartCore(this, this);
        _core.Ready();
    }

    public Mesh BuildMesh() => new BoxMesh { Size = Size };

    public Shape3D BuildCollisionShape() => new BoxShape3D { Size = Size };
}
