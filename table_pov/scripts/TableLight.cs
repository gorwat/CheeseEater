using Godot;
using System;
using System.Runtime.InteropServices;

public static class Table
{
	[DllImport("table")]
	public static extern void init(IntPtr hwnd);

	[DllImport("table")]
	public static extern bool isOn();

	[DllImport("table")]
	public static extern float getX();

	[DllImport("table")]
	public static extern float getY();
}

public partial class TableLight : SpotLight3D
{
	[Signal]
	public delegate void SpotPositionChangedEventHandler(bool isOn, Vector3 position);

	public override void _Ready()
	{
		// Initialize table by sending over window handle
		Table.init(new IntPtr(DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle)));
		Visible = false;
	}

	public override void _Process(double delta)
	{
		if(Table.isOn())
		{
			Vector3 p = new Vector3(48.0f * (Table.getX() - 0.5f), 10.0f, 27.0f * (Table.getY() - 0.5f));
			SetPosition(p);
			Visible = true;
			EmitSignal(SignalName.SpotPositionChanged, Visible, p);
		} else if(Visible)
		{
			Visible = false;
			EmitSignal(SignalName.SpotPositionChanged, Visible, new Vector3(0.0f, 0.0f, 0.0f));
		}
	}
}