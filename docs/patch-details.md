# How the patch was created

ⓘ This was originally written for the [Stellaris-Exe-Checksum-Patcher project](https://github.com/r0fld4nc3/Stellaris-Exe-Checksum-Patcher/blob/main/docs/update-patch-patterns.md)

## Prerequisites

[Ghidra](github.com/NationalSecurityAgency/ghidra)

## Linux

### 4.5.3 and later versions (starting 2026-11-04)

#### Checksum patch

ⓘ Adapted from the [Windows method](https://steamcommunity.com/sharedfiles/filedetails/?id=2460079052)

1. Find string `checksum_manifest.txt`
1. Get references to it
   1. The function that uses it is `CApplication::CalculateGameFilesChecksum`
1. Get references to that function
   1. The function referencing it is `CGameApplication::InitGame`
1. In the decompiled code, after the call to `CApplication::CalculateGameFilesChecksum` is the call to `CChecksum::GetDataChkSum`
1. The `TEST EBX,EBX` instruction after this call is the one we want to patch
1. As per below, replace it with `XOR EBX,EBX`

### 4.5.2 and earlier versions

#### Checksum patch

1. Open the Stellaris binary in Ghidra
1. Go to _Functions_ and search for `InitGame`
1. Double-click the first instance of _InitGame_ to go to it in the _Decompile_ view
1. Make sure the function is `CGameApplication::InitGame` (There are multiple InitGame functions)
1. Search the function for `CChecksum::GetDataChkSum` and click the line to highlight it
1. Look at the _Listing_ on the left starting from the highlighted instruction
1. Make sure there's a `TEST EBX,EBX` (`85 db`) instruction within the next 10 instructions or so
1. This will need to be patched with `XOR EBX,EBX`
   - This will make it so the test always passes, even if the checksum is changed
