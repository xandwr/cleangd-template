using Godot;

namespace Xandbox.Csg;

[GlobalClass]
public partial class CSGSphere : CsgSphere3D, ICSGPart
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

    public Mesh BuildMesh() => new SphereMesh { Radius = Radius, Height = Radius * 2.0f };

    public Shape3D BuildCollisionShape() => new SphereShape3D { Radius = Radius };
}
