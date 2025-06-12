// Example Streamer.Bot init class which sets the ChatIOPath for all other actions to use.
using System;

	public static class ChatIOPath {
		// For B41 Uncomment this one:
		public static readonly string b41 = @"C:\Program Files (x86)\Steam\steamapps\workshop\content\108600\2892858217\mods\AdHocCmds\ChatIO\"; // B41
			
		// For B42 Uncomment this one:
		public static readonly string b42 = @"C:\Program Files (x86)\Steam\steamapps\workshop\content\108600\2892858217\mods\AdHocCmds\common\ChatIO\"; // B42

		// For Local uncomment this one:
		public static readonly string local = @"C:\Users\rick\Zomboid\Workshop\RicksMLC_AdHocCmds\Contents\mods\AdHocCmds\common\ChatIO\";
			
		// Test workshop item
		public static readonly string test = @"C:\Program Files (x86)\Steam\steamapps\workshop\content\108600\3080443286\mods\AdHocCmds\ChatIO\"; // TEST
	}

public class CPHInline
{
	
	public void SetPath(string path) {
		CPH.SetGlobalVar("ChatIOPath", path);
	}
		
	public void Init()
	{	
		SetPath(ChatIOPath.local);
		CPH.RunAction("RicksMLC_SB-Init", false);
	}

	public void Dispose()
	{
		return;
	}

	public bool Execute()
	{
		string msg = "";
		string verString;
		object verObj;
		if (args["__source"].ToString() == "CommandTriggered") {
			if (args["command"].ToString() == "!ricksmlc_init") {
				
				if (args.TryGetValue("rawInput", out verObj)) {
					verString = verObj.ToString();
					if (verString == "b41") {
						msg = SetPath(ChatIOPath.b41);
					} else if (verString == "b42") {
						msg = SetPath(ChatIOPath.b42);
					} else if (verString == "local") {
						msg = SetPath(ChatIOPath.local);
					} else if (verString == "test") {
						msg = SetPath(ChatIOPath.test);
					} else {
						msg = $"error - ver {verString} not recognised";
					}
					CPH.LogInfo($"!ricksmlc_init : {msg}");
				}
			}
		}
		string path = CPH.GetGlobalVar<string>("ChatIOPath");
		CPH.SendMessage($"ChatIOPath: {path}", true);
		return true;
	}
}
