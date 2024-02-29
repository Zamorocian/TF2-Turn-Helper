# (TF2) Turn Helper
This plugin shows whether you are turning enough to gradually increase your speed with the shields.

| Colour  | Description |
| ------------- | ------------- |
| Red  | Not charging, you are +20 degrees further than the maximum angle, you are -20 degrees less than the minimum angle, or you are not gradually increasing in speed.  |
| Yellow | +/-10 degrees from maximum angle  |
| Cyan  | +/-5 degrees from maximum angle  |
| Green | Sufficient.  |

The code isn't great, because I don't really understand game maths to an adequate extent (yet).

Made for SolarLight.

Zamoroc edits:
| Icon  | Description |
| ------------- | ------------- |
| v | Your velocity  |
| - | The minimum angle from your velocity to gain speed  |
| \| | The optimal angle from your velocity to gain speed |

Example: [upward last to first trimp (tf2 tide turner)](https://youtu.be/fJPEFj5maX4)

# How to get it to work
This is how I did it but there may be different ways, if I find a better way I'll put it here.

Make a dedicated TF2 server with metamod and sourcemod, there are videos and guides which walk you through the whole thing. I didn't need to portforward or open firewalls practising in singleplayer.

Compile the demoknight-turn.sp file into .smx (there's a compiler in sourcemod or on the sourcemod website), then add the .smx to the plugins folder.

After launching the server, it should appear in the Lan section of the server browser in-game.

Commands are (just put them in the normal in-game console by themself, it may say not recognised but it's lying) : chargetoggle - all displays on/off, angletoggle - the angle from velocity value, extratoggle - the optimal/min values, speedtoggle - the horizontal speed value, targettoggle - the moving targets.
