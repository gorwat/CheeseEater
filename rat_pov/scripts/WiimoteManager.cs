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
	private float inputBalanceWeight;
	private float inputBalanceTopLeft;
	private float inputBalanceTopRight;
	private float inputBalanceBottomLeft;
	private float inputBalanceBottomRight;
	
	// Balance Board - calculated
	private float balanceThresh = 15;
	
	public float balance_x_axis = 0.0f;
	public float balance_y_axis = 0.0f;
	public bool balance_go_left = false;
	public bool balance_go_right = false;
	public bool balance_go_forward = false;
	public bool balance_go_back = false;
	
	// Nunchuk - input
	private float inputNunchuckX; // should be converted to better values
	private float inputNunchuckY; // should be converted to better values
	public bool nunchuk_z = false;
	public bool nunchuk_c = false;
	
	// Nunchuk - calculated
	private int nunchukMidVal = 122;
	private int nunchukThresh = 50;
	
	public float nunchuk_x_axis = 0.0f;
	public float nunchuk_y_axis = 0.0f;
	
	public static float Absf(float x) {
		if (x < 0.0f) {
			return -x;
		} else {
			return x;
		}
	}
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{	
		try {
			deviceCollection = new WiimoteCollection();
			deviceCollection.FindAllWiimotes();
		} catch {
			GD.Print("NO WIIMOTE FOUND");
		}
		
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
			inputBalanceWeight      = wiiDevice.WiimoteState.BalanceBoardState.WeightKg;
			
			inputBalanceTopLeft     = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.TopLeft;
			inputBalanceTopRight    = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.TopRight;
			inputBalanceBottomLeft  = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.BottomLeft;
			inputBalanceBottomRight = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.BottomRight;
			
			
			
			
			// reset inputs
			balance_go_left = false;
			balance_go_right = false;
			balance_go_forward = false;
			balance_go_back = false;

			balance_x_axis = (inputBalanceBottomRight + inputBalanceTopRight) - (inputBalanceBottomLeft + inputBalanceTopLeft);
			balance_y_axis = (inputBalanceTopLeft + inputBalanceTopRight) - (inputBalanceBottomLeft + inputBalanceBottomRight);
			
			if (Absf(balance_x_axis) < balanceThresh) balance_x_axis = 0.0f;
			if (Absf(balance_y_axis) < balanceThresh) balance_y_axis = 0.0f;

			if (balance_y_axis < 0.0f) balance_go_back = true;
			if (balance_y_axis > 0.0f) balance_go_forward = true;
			
			if (balance_x_axis < 0.0f) balance_go_left = true;
			if (balance_x_axis > 0.0f) balance_go_right = true;
			
			//GD.Print(inputBalanceTopLeft, inputBalanceTopRight, inputBalanceBottomLeft, inputBalanceBottomRight);
			//GD.Print(balance_go_left, " ", balance_go_right, " ", balance_go_forward, " ", balance_go_back);
			}
			
			if (wiiDevice.WiimoteState.ExtensionType == ExtensionType.Nunchuk) {    
			inputNunchuckX      = wiiDevice.WiimoteState.NunchukState.RawJoystick.X;
			inputNunchuckY      = wiiDevice.WiimoteState.NunchukState.RawJoystick.Y;
			nunchuk_z           = wiiDevice.WiimoteState.NunchukState.Z;
			nunchuk_c           = wiiDevice.WiimoteState.NunchukState.C;
			
			// x axis calculation
			if (inputNunchuckX < nunchukMidVal - nunchukThresh) {
				nunchuk_x_axis = -1;
			} else if (inputNunchuckX > nunchukMidVal + nunchukThresh) {
				nunchuk_x_axis = 1;
			} else {
				nunchuk_x_axis = 0;
			}
			
			// y axis calculation
			if (inputNunchuckY < nunchukMidVal - nunchukThresh) {
				nunchuk_y_axis = 1;
			} else if (inputNunchuckY > nunchukMidVal + nunchukThresh) {
				nunchuk_y_axis = -1;
			} else {
				nunchuk_y_axis = 0;
			}
			
			//GD.Print("Input: ", inputNunchuckX, " ", inputNunchuckY, " Calculated: ", nunchuk_x_axis, " ", nunchuk_y_axis);
			}
		}
	}
	
	
}
