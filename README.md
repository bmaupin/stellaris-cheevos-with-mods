# Enable achievements with mods in Stellaris

This is a script for Linux to patch Stellaris to allow achievements with mods.

For a GUI tool that supports Linux and Windows/Proton, see [Stellaris Checksum Patcher](https://github.com/r0fld4nc3/Stellaris-Exe-Checksum-Patcher)

## Usage

```
./scripts/patch-stellaris.sh
```

To have the patch tool run every time you start the game, in Steam go to the game Properties and add the patch tool to your _Launch Options_, e.g.

```
"/home/$USER/workspace/stellaris-cheevos-with-mods/scripts/patch-stellaris.sh" && %command%
```

#### How to tell that the game is patched

There's no easy way to tell the patch is working other than getting an achievement.

However, installing this patch modifies the game binary, and you can visually confirm this:

1. Start the game from the launcher
1. Find the version of the game near the bottom of the screen; the text should be yellow
1. Mouse over the version and it should show a message indicating the game is modified

## Uninstall

To uninstall the patch:

1. Open Steam and go to _Library_

1. Find _Stellaris_ and right-click on it > _Properties_

1. _Installed Files_ > _Verify integrity of game files_

## More information about the patch

See [docs/patch-details.md](docs/patch-details.md)

## Motivation

This was inspired by [Stellaris Checksum Patcher](https://github.com/r0fld4nc3/Stellaris-Exe-Checksum-Patcher); compared to that project:

- This project uses a script instead of a GUI so it can be run every time the game is started to automatically patch the game when it's updated
- This project uses logic that should allow it to work for different versions of the game; Stellaris Checksum Patcher relies on specific byte patterns that can change when the game is updated

## Credits

- [Stellaris Checksum Patcher](https://github.com/r0fld4nc3/Stellaris-Exe-Checksum-Patcher)
- [Enabling Achievements in Stellaris With Mods (All game versions) [SRE]](https://steamcommunity.com/sharedfiles/filedetails/?id=2460079052)
