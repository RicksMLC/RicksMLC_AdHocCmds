Rick's MLC AdHocCmds: Streamer.bot chat integration instructions.

The streamer.bot tool has an Import feature which imports actions and commands.
To assist in getting integration up-and-running, the RicksMLC_ChatSpawnAndSupplyInport.txt file is 
included in this directory for you to... import.

It will create the following Actions:
  "RicksMLC_BrownOut"
  "RicksMLC_ChatRadio"
  "RicksMLC_Flies"  (not ready yet for B42)
  "RicksMLC_Players"  (not ready yet for B42)
  "RicksMLC_ResetLostMaps"  (not ready yet for B42)
  "RicksMLC_Spawn"
  "RicksMLC_Supply"
  "RicksMLC_TreasureHunt" (not ready yet for B42)

To use them create the channel point reward(s), commands and/or raid actions that you require and assign
the corresponding Action to them.

If you customise these Actions I recommend saving them with a different name from "RicksMLC..." so that when 
the AdHocCmds mod is updated and if you re-import the Actions your customisations are not lost.

The spawn, supply and radio Actions read the imput from the Chat and write the appropriate RicksMLC_AdHocCmds integration files
to the ChatIO directory, then wait 500ms, then force an F10 key press so PZ will read the files immediately.
If PZ is not your currently "in-focus" application the F10 key will go to whatever application is current.  Note that 
the AdHocCmds mod will read the integration files every 10 in-game minutes so no updates are actioned even if the F10 is missed

The spawn action will spawn zombies for:
    - bit cheers: 1 zombie / bit
    - Channel Point Rewards: 5 zombies for 500 points.  12 zombies for 1000 points.
      Edit the source to change the amounts
    - Raids: A raid triggers the zombie spawn. 1 zombie per viewer.
    - Follow: Spawn 5 zombies for a follow.

The RicksMLC_Radio can be used with a command (eg !radio) or a channel point redeem.

Have Fun.
Rick's MLC.
