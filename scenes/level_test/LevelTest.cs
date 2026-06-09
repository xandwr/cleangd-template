using Godot;
using Xandbox.Csg;

[GlobalClass]
public partial class LevelTest : CSGLevel
{
	public override void _Ready() {
		base._Ready();
		foreach (var part in Parts)
			GD.Print(((Node)part).Name);
	}
}
