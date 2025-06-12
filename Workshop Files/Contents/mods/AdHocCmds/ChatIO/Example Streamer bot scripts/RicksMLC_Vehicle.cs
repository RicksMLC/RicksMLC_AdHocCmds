// Example script for vehicle chat integration events
// NOte uses CPH.GetGlobalVar<string>("ChatIOPath"); from RicksMLC_SB-Init.

using System;
using System.Collections.Generic;
using System.IO;

namespace RicksMLC {
	public class VehicleConfig {	
		public static List<string> PartListWindows = new List<string> {
			"ATA2ProtectionWindshield",
			"ATA2ProtectionWindowFrontLeft",
			"ATA2ProtectionWindowFrontRight",
			"ATA2ProtectionWindowRearLeft",
			"ATA2ProtectionWindowRearRight",
			"ATA2ProtectionWindowMiddleLeft", 
			"ATA2ProtectionWindowMiddleRight"
		};
		public static List<string> PartListDoors = new List<string> {
			"ATA2ProtectionTrunk",
			"ATA2ProtectionDoorsRear",
			"ATA2ProtectionHood", 
			"ATA2ProtectionHoodNoScoop",
			"ATA2ProtectionDoorFrontLeft",
			"ATA2ProtectionDoorFrontRight",
			"ATA2ProtectionDoorRearLeft",
			"ATA2ProtectionDoorRearRight",
			"ATA2ProtectionDoorMiddleLeft",
			"ATA2ProtectionDoorMiddleRight" 
		};
		public static List<string> ModelListWindowsAndDoors = new List<string> {
			"Light",
			"Heavy",
			"LightRusted",
			"HeavyRusted",
			"LightSpiked",
			"HeavySpiked",
			"LightSpikedRusted", 
			"HeavySpikedRusted",
			"Reinforced",
			"ReinforcedRusted"
		};
		public static List<string> PartListBullbars = new List<string> {
			"ATA2Bullbar"//, --Trucks and Police-specific are not in vanilla?
			//"ATA2BullbarTruck",
			//"ATA2BullbarPolice",
			//"ATA2BullbarPoliceSUV"
		};
		public static List<string> ModelListBullbars = new List<string> {
			"Small",
			"Medium",
			"Large",
			"LargeSpiked",
			"Plow",
			"PlowRusted",
			"PlowSpiked",
			"PlowSpikedRusted"
			// "Truck" is just for for truck bullbar
		};
		
		public static (string, string) GetRandomWindow() {
			var rand = new Random();
			return (RicksMLC.VehicleConfig.PartListWindows[rand.Next(RicksMLC.VehicleConfig.PartListWindows.Count)],
					RicksMLC.VehicleConfig.ModelListWindowsAndDoors[rand.Next(RicksMLC.VehicleConfig.ModelListWindowsAndDoors.Count)]);
		}
		
		public static (string, string) GetRandomDoor() {
			var rand = new Random();
			return (RicksMLC.VehicleConfig.PartListDoors[rand.Next(RicksMLC.VehicleConfig.PartListDoors.Count)],
					RicksMLC.VehicleConfig.ModelListWindowsAndDoors[rand.Next(RicksMLC.VehicleConfig.ModelListWindowsAndDoors.Count)]);
		}
			
		public static (string, string) GetRandomBullbar() {
			string part;
			string modelType;
			var rand = new Random();
			part = RicksMLC.VehicleConfig.PartListBullbars[rand.Next(RicksMLC.VehicleConfig.PartListBullbars.Count)];
			if (part == "ATA2BullbarTruck" && rand.Next(RicksMLC.VehicleConfig.PartListBullbars.Count+1) == RicksMLC.VehicleConfig.PartListBullbars.Count) {
				modelType = "Truck";
			} else {
				modelType = RicksMLC.VehicleConfig.ModelListBullbars[rand.Next(RicksMLC.VehicleConfig.ModelListBullbars.Count)];
			}						
			return (part, modelType);
		}
	}
}

public class CPHInline
{

	private void UpdateChatInput(string filename) {
		string SteamModChatIOPath = CPH.GetGlobalVar<string>("ChatIOPath");
		string path = SteamModChatIOPath + "chatInput.txt";
		CPH.LogInfo($"Writing Supply command to ChatIO {path}");
		System.IO.File.WriteAllText(path, $"{filename}=immediate");
	}
	
	public bool Execute()
	{
		foreach (var arg in args) {
            CPH.LogInfo($"LogVars :: {arg.Key} = {arg.Value}");
        }

		if (args["__source"].ToString() == "CommandTriggered") {
			// No commands yet
		} else if (args["__source"].ToString() == "TwitchRewardRedemption") {	
			//Dump();
			string part = "ATA2ProtectionHood";
			string modelType = "Light";
			string action = "";
			var rand = new Random();
			string rewardName = args["rewardName"].ToString();
			if (rewardName == "Vehicle Armor (Random)") {
				switch (rand.Next(3)) {
					case 0:
						(part, modelType) = RicksMLC.VehicleConfig.GetRandomWindow();
						break;
					case 1:
						(part, modelType) = RicksMLC.VehicleConfig.GetRandomDoor();
						break;
					case 2:
						(part, modelType) = RicksMLC.VehicleConfig.GetRandomBullbar();
						break;
					default:
						break;
				}
				CPH.LogInfo($" Vehicle:: part: {part} modelType: {modelType}");
			} 
			
			if (rewardName.Contains("Bullbar")) {
				if (rewardName.Contains("Random")) {
					(part, modelType) = RicksMLC.VehicleConfig.GetRandomBullbar();
				} else {
					part = "bullbar";
				}
			} else if (rewardName.Contains("Hood")) {
				if (rewardName.Contains("Random")) {
					part = "ATA2ProtectionHood";
					modelType = RicksMLC.VehicleConfig.ModelListWindowsAndDoors[rand.Next(RicksMLC.VehicleConfig.ModelListWindowsAndDoors.Count)]; 
				} else {
					part = "hood";
				}
			} else if (rewardName.Contains("Trunk")) {
				if (rewardName.Contains("Random")) {
					part = "ATA2ProtectionTrunk";
					modelType = RicksMLC.VehicleConfig.ModelListWindowsAndDoors[rand.Next(RicksMLC.VehicleConfig.ModelListWindowsAndDoors.Count)]; 
				} else {
					part = "trunk";
				}
			}
			
			if (rewardName.Contains("Remove")) {
				action = "remove";
			} else if (rewardName.Contains("Upgrade")) {
				action = "upgrade";
			} else if (rewardName.Contains("Downgrade")) {
				action = "downgrade";
			}
			
			
			string player = "";
			object playerObj;
			if (args.TryGetValue("rawInput", out playerObj)){
				 // Player name goes here for multiplayer - The rewards with rawInput are prompted for the user.
				player = playerObj.ToString();
			} else {
				//CPH.SendMessage($"No player name set.  Default to host player");
			}
			
			string contents =
				  $"type=vehicle\n"
				+ $"part={part}\n"
				+ $"modelType={modelType}\n"
				+ $"action={action}\n"
				+ $"player={player}\n";
			
			CPH.LogInfo($"Contents: {contents}");
			string SteamModChatIOPath = CPH.GetGlobalVar<string>("ChatIOPath");
			string path = SteamModChatIOPath + "Vehicle.txt";
			System.IO.File.WriteAllText(path, contents);
			
			UpdateChatInput("Vehicle.txt");
		}
		
		return true;
		return true;
	}
}
