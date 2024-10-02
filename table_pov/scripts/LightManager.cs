using Godot;
using System;
using System.Runtime.InteropServices;

public static class Table
{
	[DllImport("table")]
	public static extern uint init(IntPtr hwnd);

	[DllImport("table")]
	public static extern uint accuireAccess();
	
	[DllImport("table")]
	public static extern void releaseAccess();

	[DllImport("table")]
	public static extern float getX(uint i);

	[DllImport("table")]
	public static extern float getY(uint i);

	[DllImport("table")]
	public static extern float getSizeX(uint i);

	[DllImport("table")]
	public static extern float getSizeY(uint i);
}

public partial class LightManager : Node
{
	
	[Signal]
	public delegate void SpotPositionsChangedEventHandler(Vector3[] positions, float[] angles);

	public override void _Ready()
	{
		// Initialize table by sending over window handle
		Table.init(new IntPtr(DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle)));
		
		for(int i = 0; i < 10; ++i) 
		{
			SpotLight3D spotLight = new SpotLight3D();
			AddChild(spotLight);
			spotLight.RotationDegrees = new Vector3(-90.0f, 180.0f, 0.0f);
			spotLight.Visible = false;
			spotLight.LightEnergy = 10.0f;
			spotLight.SpotRange = 20.0f;
		}
	}

	public override void _Process(double delta)
	{
		uint count = Table.accuireAccess();

		Vector3[] positions = new Vector3[count];
		float[] angles = new float[count];
		
		for(uint i = 0; i < count; ++i) 
		{
			float x = Table.getX(i);
			float y = Table.getY(i);
			float sizeX = Table.getSizeX(i);
			float sizeY = Table.getSizeY(i);
			
			Vector3 p = new Vector3(27.0f * (x - 0.5f) * 2.0f, 10.0f, 16.0f * (y - 0.5f) * 2.0f);
			GetChild<SpotLight3D>((int)i).SetPosition(p);
			
			GetChild<SpotLight3D>((int)i).SpotAngle = ((float)Math.Atan((Math.Max(sizeX * 27.0f, sizeY * 16.0f)) / 10.0f)) * 2.0f * (180.0f / 3.14f);
			
			GetChild<SpotLight3D>((int)i).Visible = true;
			
			positions[i] = p;
			angles[i] = GetChild<SpotLight3D>((int)i).SpotAngle;
		}
		Table.releaseAccess();
		
		for(uint i = count; i < 10; ++i) {
			GetChild<SpotLight3D>((int)i).Visible = false;
		}
		
		EmitSignal(SignalName.SpotPositionsChanged, positions, angles);
	}
}
