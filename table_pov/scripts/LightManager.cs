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
	SpotLight3D[] spotLights;

	public override void _Ready()
	{
		// Initialize table by sending over window handle
		uint maxLights = Table.init(new IntPtr(DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle)));
		
		spotLights = new SpotLight3D[maxLights];
		for(uint i = 0; i < maxLights; ++i) 
		{
			spotLights[i] = new SpotLight3D();
			spotLights[i].Visible = false;
			spotLights[i].LightEnergy = 10.0f;
			spotLights[i].SpotRange = 15.0f;
			AddChild(spotLights[i]);
		}
	}

	public override void _Process(double delta)
	{
		uint count = Table.accuireAccess();
		for(uint i = 0; i < count; ++i) 
		{
			float x = Table.getX(i);
			float y = Table.getY(i);
			float sizeX = Table.getSizeX(i);
			float sizeY = Table.getSizeY(i);
			
			Vector3 p = new Vector3(27.0f * (x - 0.5f) * 2.0f, 10.0f, 16.0f * (y - 0.5f) * 2.0f);
			spotLights[i].SetPosition(p);
			
			spotLights[i].SpotAngle = ((float)Math.Atan((Math.Max(sizeX * 27.0f, sizeY * 16.0f)) / 10.0f)) * 2.0f * (180.0f / 3.14f);
			
			spotLights[i].Visible = true;
		}
		Table.releaseAccess();
		
		for(uint i = count; i < spotLights.Length; ++i) {
			spotLights[i].Visible = false;
		}
	}
}
