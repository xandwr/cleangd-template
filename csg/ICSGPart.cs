using Godot;

namespace Xandbox.Csg;

public enum PhysicsMode { Static, Dynamic }

/// The umbrella every custom CSG primitive satisfies, whatever native
/// CSGShape3D it extends. The shared static/dynamic physics-body machinery
/// lives in CSGPartCore; each shape supplies its own mesh + collision shape.
public interface ICSGPart
{
    PhysicsMode Mode { get; }

    /// The visual mesh handed to the spawned RigidBody in Dynamic mode.
    Mesh BuildMesh();

    /// The collision shape handed to the spawned RigidBody in Dynamic mode.
    Shape3D BuildCollisionShape();
}
