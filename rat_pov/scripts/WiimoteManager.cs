using Godot;
using System;
using System.Runtime.InteropServices;
using WiimoteLib;

// did not need, since dll was managed and not unmanaged, so I just put it in the project
// and referenced it in the .csproj-file that was created when I added the dll to the project files
public static class WiimoteDLL
{
	//[DllImport("WiimoteLib")]
	//public extern static void Connect();
}

public partial class WiimoteManager : Node
{
	private WiimoteCollection deviceCollection;

	// Balance Board - input
	private float rwWeight;
	private float rwTopLeft;
	private float rwTopRight;
	private float rwBottomLeft;
	private float rwBottomRight;
	
	// Balance Board - calculated (TODO)
	public float x_axis;
	public float y_axis;
	
	// Nunchuk
	public float nunchuk_x; // should be converted to better values
	public float nunchuk_y; // should be converted to better values
	public bool nunchuk_z;
	public bool nunchuk_c;
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{		
		deviceCollection = new WiimoteCollection();
		deviceCollection.FindAllWiimotes();
		
		foreach (Wiimote wiiDevice in deviceCollection) {
			wiiDevice.Connect();
			if (wiiDevice.WiimoteState.ExtensionType != null) {
				GD.Print(wiiDevice.WiimoteState.ExtensionType, " connected");
			} else {
				GD.Print("Device type not compatible");
			}
		}
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		foreach (Wiimote wiiDevice in deviceCollection) {
			if (wiiDevice.WiimoteState.ExtensionType == ExtensionType.BalanceBoard) {    
			rwWeight      = wiiDevice.WiimoteState.BalanceBoardState.WeightKg;
			rwTopLeft     = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.TopLeft;
			rwTopRight    = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.TopRight;
			rwBottomLeft  = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.BottomLeft;
			rwBottomRight = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.BottomRight;
			
			GD.Print(rwTopLeft, rwTopRight, rwBottomLeft, rwBottomRight);
			}
			
			if (wiiDevice.WiimoteState.ExtensionType == ExtensionType.Nunchuk) {    
			nunchuk_x      = wiiDevice.WiimoteState.NunchukState.RawJoystick.X;
			nunchuk_y      = wiiDevice.WiimoteState.NunchukState.RawJoystick.Y;
			nunchuk_z      = wiiDevice.WiimoteState.NunchukState.Z;
			nunchuk_c      = wiiDevice.WiimoteState.NunchukState.C;
			
			GD.Print(nunchuk_x, " ", nunchuk_y, " ", nunchuk_z, " ", nunchuk_c);
			}
		}
	}
}
