# Update patch patterns

ⓘ This was originally written for the [Stellaris-Exe-Checksum-Patcher project](https://github.com/r0fld4nc3/Stellaris-Exe-Checksum-Patcher/blob/main/docs/update-patch-patterns.md)

## Understanding patterns.json

`patch_pattern` is the pattern of bytes the patcher will look for when determining where to apply the patch.

- Sections like `.{8}` mean 8 bytes of anything
- `%s` is where the bytes to replace will be; they must match `hex_find`
- The `hex_find` bytes will be replaced with `hex_replace`

## Prerequisites

[Ghidra](github.com/NationalSecurityAgency/ghidra)

## Linux

### 4.5.3 and later versions (starting 2026-11-04)

#### Checksum pattern

ⓘ Adapted from the [Windows method](https://steamcommunity.com/sharedfiles/filedetails/?id=2460079052)

1. Find string `checksum_manifest.txt`
1. Get references to it
   1. The function that uses it is `CApplication::CalculateGameFilesChecksum`
1. Get references to that function
   1. The function referencing it is `CGameApplication::InitGame`
1. In the decompiled code, after the call to `CApplication::CalculateGameFilesChecksum` is the call to `CChecksum::GetDataChkSum`
1. The `TEST EBX,EBX` instruction after this call is the one we want to patch
1. As per below, replace it with `XOR EBX,EBX`

#### Warning pattern

TODO

#### Tooltip pattern

TODO

### 4.5.2 and earlier versions

#### Checksum pattern

1. Open the Stellaris binary in Ghidra
1. Go to _Functions_ and search for `InitGame`
1. Double-click the first instance of _InitGame_ to go to it in the _Decompile_ view
1. Make sure the function is `CGameApplication::InitGame` (There are multiple InitGame functions)
1. Search the function for `CChecksum::GetDataChkSum` and click the line to highlight it
1. Look at the _Listing_ on the left starting from the highlighted instruction
1. Make sure there's a `TEST EBX,EBX` (`85 db`) instruction within the next 10 instructions or so
1. This will need to be patched with `XOR EBX,EBX`
   - This will make it so the test always passes, even if the checksum is changed

#### Warning pattern

1. Go to _Functions_ and search for `ApplyVersionToTextBox`
1. Double-click the function name to go to it in the _Decompile_ view
1. Search the function for `CChecksum::GetDataChkSum` and click the line to highlight it
1. Look at the _Listing_ on the left starting from the highlighted instruction
1. Make sure there's a `TEST EAX,EAX` (`85 c0`) instruction within the next 10 instructions or so
1. This will need to be patched with `XOR EAX,EAX`

#### Tooltip pattern

1. Go to _Strings_ and search for `ACHIEVEMENT_TOOLTIP_CHECKSUM`
1. Double-click the search result to load it in the Listing
1. In _Listing_ on the left, right-click the highlighted result > _References_ > _Show References to Address_
1. In the _References to_ window, double click the result
1. The reference should be highlighted in _Listing_ on the left
1. Look at the _Listing_ on the left starting from the highlighted instruction
1. Make sure there's a `TEST EAX,EAX` (`85 c0`) instruction within the **previous** 10 instructions or so
1. This will need to be patched with `XOR EAX,EAX`

## Windows

https://steamcommunity.com/sharedfiles/filedetails/?id=2460079052
