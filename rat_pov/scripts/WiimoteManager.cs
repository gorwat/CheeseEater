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
	private Wiimote wiiDevice;
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		//WiimoteDLL.Connect();
		GD.Print("attempt");
		
		wiiDevice = new Wiimote();
		wiiDevice.Connect(); // Call methods as needed
		var deviceCollection = new WiimoteCollection();
		deviceCollection.FindAllWiimotes();
		GD.Print("testa");
		GD.Print(wiiDevice.WiimoteState.ExtensionType);
		if (wiiDevice.WiimoteState.ExtensionType != ExtensionType.BalanceBoard)
			{
				GD.Print("DEVICE IS NOT A BALANCE BOARD...");
		 }
		
		 var rwWeight      = wiiDevice.WiimoteState.BalanceBoardState.WeightKg;
		 var rwTopLeft     = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.TopLeft;
		 var rwTopRight    = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.TopRight;
		 var rwBottomLeft  = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.BottomLeft;
		 var rwBottomRight = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.BottomRight;
		 var aButton       = wiiDevice.WiimoteState.ButtonState.A;
		
		GD.Print(rwTopLeft, " ", rwTopRight);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		 var rwWeight      = wiiDevice.WiimoteState.BalanceBoardState.WeightKg;
		 var rwTopLeft     = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.TopLeft;
		 var rwTopRight    = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.TopRight;
		 var rwBottomLeft  = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.BottomLeft;
		 var rwBottomRight = wiiDevice.WiimoteState.BalanceBoardState.SensorValuesKg.BottomRight;
		 var aButton       = wiiDevice.WiimoteState.ButtonState.A;
		
		GD.Print(rwTopLeft, " ", rwTopRight);
	}
}
