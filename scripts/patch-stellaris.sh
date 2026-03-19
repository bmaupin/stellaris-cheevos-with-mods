#!/usr/bin/env bash

bin_path="/home/${USER}/.local/share/Steam/steamapps/common/Stellaris/stellaris"

if [ -z "${1}" ]; then
    echo "No path provided; using ${bin_path}"
    echo

    if [[ ! -f "${bin_path}" ]]; then
        echo "Error: Stellaris binary not found. Please make sure it's installed or provide an alternative path as a parameter to this script."
        exit 1
    fi
fi

if [ -n "${1}" ]; then
    bin_path="$1"

    if [[ ! -f "${bin_path}" ]]; then
        echo "Error: No file exists at ${bin_path}"
        exit 1
    fi
fi

getdatachksum_function_name=_ZNK9CChecksum13GetDataChkSumEv
# Make sure the function name hasn't changed
if ! objdump -d --disassemble="${getdatachksum_function_name}" "${bin_path}" | grep -q "${getdatachksum_function_name}"; then
    echo "Searching for CChecksum::GetDataChkSum function ..."
    echo
    getdatachksum_virtual_address=$(objdump -d --demangle "${bin_path}" | grep '<CChecksum::GetDataChkSum() const>:' | awk '{print $1}')
    getdatachksum_function_name=$(nm "${bin_path}" | grep "${getdatachksum_virtual_address}" | awk '{print $3}')
fi



# ************************************ Cheevo patch ************************************
initgame_function_name=_ZN16CGameApplication8InitGameEv
if ! objdump -d --disassemble="${initgame_function_name}" "${bin_path}" | grep -q "${initgame_function_name}"; then
    echo "Searching for CGameApplication::InitGame function ..."
    initgame_virtual_address=$(objdump -d --demangle "${bin_path}" | grep '<CGameApplication::InitGame()>:' | awk '{print $1}')
    initgame_function_name=$(nm "${bin_path}" | grep "${initgame_virtual_address}" | awk '{print $3}')
fi

virtual_address=$(objdump -d --disassemble="${initgame_function_name}" "${bin_path}" | grep -A 10 "${getdatachksum_function_name}" | grep "test   %ebx,%ebx" | awk '{print $1}' | sed 's/://')

if [[ -z "$virtual_address" ]]; then
    echo "Unable to find address to patch; has the file already been patched?"
    exit 1
fi

# Get the file offset corresponding to the virtual address of the search string
text_file_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $6 }')
text_virtual_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $4 }')

file_offset=$((0x$virtual_address + 0x$text_file_offset - 0x$text_virtual_offset))

bytes=$(xxd -p -l 2 --seek "${file_offset}" "${bin_path}" | tr -d '\n')

# Make sure bytes match what we expect
if [[ "${bytes}" != "85db" ]]; then
    echo "Unexpected bytes at offset ${file_offset}: ${bytes}"
    echo "This shouldn't happen; please check the binary file."
    exit 1
fi

# Subtract 0 instead of 1 so that the number of turn resets never decreases
patched_bytes='31db'

echo "Patch the checksum test to make achivements earnable with mods that modify the checksum integrity"
echo "    Patching bytes at offset ${file_offset} from ${bytes} to ${patched_bytes}"
echo

# Write the patched bytes back to the binary file
echo "${patched_bytes}" | xxd -p -r | dd of="${bin_path}" bs=1 conv=notrunc seek="${file_offset}"



# Exit early and skip aesthetic patches
exit



# ************************************ Patch warning ************************************
# Without this, the version number on the main screen is yellow. As best as I can tell
# this is only aesthetic.
applyversion_function_name=_ZN13CGameGraphics21ApplyVersionToTextBoxEP15CInstantTextBox
if ! objdump -d --disassemble="${applyversion_function_name}" "${bin_path}" | grep -q "${applyversion_function_name}"; then
    echo "Searching for CGameGraphics::ApplyVersionToTextBox function ..."
    applyversion_virtual_address=$(objdump -d --demangle "${bin_path}" | grep '<CGameGraphics::ApplyVersionToTextBox(CInstantTextBox\*)>:' | awk '{print $1}')
    applyversion_function_name=$(nm "${bin_path}" | grep "${applyversion_virtual_address}" | awk '{print $3}')
fi

virtual_address=$(objdump -d --disassemble="${applyversion_function_name}" "${bin_path}" | grep -A 10 "${getdatachksum_function_name}" | grep "test   %eax,%eax" | awk '{print $1}' | sed 's/://')

if [[ -z "$virtual_address" ]]; then
    echo "Unable to find address to patch; has the file already been patched?"
    exit 1
fi

# Get the file offset corresponding to the virtual address of the search string
text_file_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $6 }')
text_virtual_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $4 }')

file_offset=$((0x$virtual_address + 0x$text_file_offset - 0x$text_virtual_offset))

bytes=$(xxd -p -l 2 --seek "${file_offset}" "${bin_path}" | tr -d '\n')

# Make sure bytes match what we expect
if [[ "${bytes}" != "85c0" ]]; then
    echo "Unexpected bytes at offset ${file_offset}: ${bytes}"
    echo "This shouldn't happen; please check the binary file."
    exit 1
fi

# Subtract 0 instead of 1 so that the number of turn resets never decreases
patched_bytes='31c0'

echo "Patch the yellow warning indicating the checksum is modified"
echo "    Patching bytes at offset ${file_offset} from ${bytes} to ${patched_bytes}"
echo

# Write the patched bytes back to the binary file
echo "${patched_bytes}" | xxd -p -r | dd of="${bin_path}" bs=1 conv=notrunc seek="${file_offset}"



# ************************************ Patch tooltip ************************************
# Without this, the version number on the main screen has a warning that indicates the
# game is modified. As best as I can tell this is only aesthetic.
gettooltip_function_name=_ZNK13CGameGraphics10GetToolTipEPK10CGuiObjectR8CToolTip
if ! objdump -d --disassemble="${gettooltip_function_name}" "${bin_path}" | grep -q "${gettooltip_function_name}"; then
    echo "Searching for CGameGraphics::GetToolTip function ..."
    gettooltip_virtual_address=$(objdump -d --demangle "${bin_path}" | grep '<CGameGraphics::GetToolTip(CGuiObject const\*, CToolTip&) const>:' | awk '{print $1}')
    gettooltip_function_name=$(nm "${bin_path}" | grep "${gettooltip_virtual_address}" | awk '{print $3}')
fi

virtual_address=$(objdump -d --disassemble="${gettooltip_function_name}" "${bin_path}" | grep -A 10 "${getdatachksum_function_name}" | grep "test   %eax,%eax" | awk '{print $1}' | sed 's/://')

if [[ -z "$virtual_address" ]]; then
    echo "Unable to find address to patch; has the file already been patched?"
    exit 1
fi

# Get the file offset corresponding to the virtual address of the search string
text_file_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $6 }')
text_virtual_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $4 }')

file_offset=$((0x$virtual_address + 0x$text_file_offset - 0x$text_virtual_offset))

bytes=$(xxd -p -l 2 --seek "${file_offset}" "${bin_path}" | tr -d '\n')

# Make sure bytes match what we expect
if [[ "${bytes}" != "85c0" ]]; then
    echo "Unexpected bytes at offset ${file_offset}: ${bytes}"
    echo "This shouldn't happen; please check the binary file."
    exit 1
fi

# Subtract 0 instead of 1 so that the number of turn resets never decreases
patched_bytes='31c0'

echo "Patch the tooltip text indicating that the checksum is modified"
echo "    Patching bytes at offset ${file_offset} from ${bytes} to ${patched_bytes}"
echo

# Write the patched bytes back to the binary file
echo "${patched_bytes}" | xxd -p -r | dd of="${bin_path}" bs=1 conv=notrunc seek="${file_offset}"
