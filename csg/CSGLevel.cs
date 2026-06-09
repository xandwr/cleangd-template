using System.Collections.Generic;
using Godot;

namespace Xandbox.Csg;

/// Holds every ICSGPart in the level. The interface is the umbrella: a box and
/// a sphere extend different native CSG types but share one typed collection.
[GlobalClass]
public partial class CSGLevel : Node3D
{
	public readonly List<ICSGPart> Parts = new();

	public override void _Ready()
	{
		foreach (var child in GetChildren())
			if (child is ICSGPart part)
				Parts.Add(part);
	}
}
