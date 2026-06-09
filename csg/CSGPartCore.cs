using Godot;

namespace Xandbox.Csg;

/// The physics-mode machinery shared by every ICSGPart, held by composition
/// because the shapes can't share a base class (each extends a different
/// native CsgShape3D). The owning node forwards _Ready and physics_mode
/// changes here; this swaps the CSG shape between a static editor body and a
/// spawned RigidBody3D clone.
public sealed class CSGPartCore
{
    private readonly CsgShape3D _shape;
    private readonly ICSGPart _part;
    private RigidBody3D _physObject;

    public CSGPartCore(CsgShape3D shape, ICSGPart part)
    {
        _shape = shape;
        _part = part;
    }

    public void Ready() => Apply();

    /// Call when Mode changes after _Ready. No-op before the node is in-tree.
    public void OnModeChanged()
    {
        if (_shape.IsNodeReady())
            Apply();
    }

    private void Apply()
    {
        if (_part.Mode == PhysicsMode.Dynamic)
        {
            if (!GodotObject.IsInstanceValid(_physObject))
                SpawnPhysicsBody();
        }
        else
        {
            if (GodotObject.IsInstanceValid(_physObject))
            {
                _physObject.QueueFree();
                _physObject = null;
            }
            _shape.Visible = true;
        }
    }

    private async void SpawnPhysicsBody()
    {
        _physObject = new RigidBody3D();

        var mesh = new MeshInstance3D
        {
            Mesh = _part.BuildMesh(),
            MaterialOverride = _shape.MaterialOverride,
        };
        _physObject.AddChild(mesh);

        var col = new CollisionShape3D { Shape = _part.BuildCollisionShape() };
        _physObject.AddChild(col);

        var spawnTransform = _shape.GlobalTransform;
        _shape.GetParent().CallDeferred(Node.MethodName.AddChild, _physObject);
        _physObject.SetDeferred(Node3D.PropertyName.GlobalTransform, spawnTransform);

        await _shape.ToSignal(_shape.GetTree(), SceneTree.SignalName.ProcessFrame);
        if (GodotObject.IsInstanceValid(_shape))
            _shape.Visible = false;
    }
}
