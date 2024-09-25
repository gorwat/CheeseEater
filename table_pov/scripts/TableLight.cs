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
	
	[DllImport("table")]
	public static extern float getSizeX();

	[DllImport("table")]
	public static extern float getSizeY();
}

public partial class TableLight : SpotLight3D
{
	[Signal]
	public delegate void SpotPositionChangedEventHandler(bool isOn, Vector3 position, float angle);

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
			Vector3 p = new Vector3(27.0f * (Table.getX() - 0.5f) * 2.0f, 10.0f, 16.0f * (Table.getY() - 0.5f) * 2.0f);
			SetPosition(p);
			Visible = true;
			SpotAngle = ((float)Math.Atan((Math.Max(Table.getSizeX() * 27.0f, Table.getSizeY() * 16.0f))/10.0f)) * 2.0f * (180.0f / 3.14f);
			EmitSignal(SignalName.SpotPositionChanged, Visible, p, SpotAngle);
		} else if(Visible)
		{
			Visible = false;
			EmitSignal(SignalName.SpotPositionChanged, Visible, new Vector3(0.0f, 0.0f, 0.0f), 1.0f);
		}
	}
}
