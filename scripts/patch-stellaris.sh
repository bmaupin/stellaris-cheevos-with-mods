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

if ! file "${bin_path}" | grep -q ELF; then
    echo "Error: ${bin_path} is not a Linux executable"
    exit 1
fi

verbose=true


patch_binary_with_symbols() {
    echo "Patching binary with symbols"

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
        virtual_address=$(objdump -d --disassemble="${initgame_function_name}" "${bin_path}" | grep -A 10 "${getdatachksum_function_name}" | grep "xor    %ebx,%ebx" | awk '{print $1}' | sed 's/://')
    fi

    if [[ -z "$virtual_address" ]]; then
        echo "Unable to find address to patch; aborting"
        exit 1
    fi

    # Get the file offset corresponding to the virtual address of the search string
    text_file_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $6 }')
    text_virtual_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $4 }')

    file_offset=$((0x$virtual_address + 0x$text_file_offset - 0x$text_virtual_offset))

    bytes=$(xxd -p -l 2 --seek "${file_offset}" "${bin_path}" | tr -d '\n')

    # See https://steamcommunity.com/sharedfiles/filedetails/?id=2460079052
    expected_bytes='85db'
    patched_bytes='31db'

    if [[ "${bytes}" == "${patched_bytes}" ]]; then
        echo "Achievements with mods patch already applied"
        echo
    elif [[ "${bytes}" == "${expected_bytes}" ]]; then
        echo "Patch the checksum test to make achivements earnable with mods that modify the checksum integrity"
        echo "    Patching bytes at offset ${file_offset} from ${bytes} to ${patched_bytes}"
        echo
        # Write the patched bytes back to the binary file
        echo "${patched_bytes}" | xxd -p -r | dd of="${bin_path}" bs=1 conv=notrunc seek="${file_offset}"
        echo
    else
        echo "Unexpected bytes at offset ${file_offset}: ${bytes}"
        echo "This shouldn't happen; please check the binary file."
        exit 1
    fi



    # Comment this out to apply aesthetic patches
    echo "NOTE: Not applying aesthetic patches; see script for how to apply them"
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
        virtual_address=$(objdump -d --disassemble="${applyversion_function_name}" "${bin_path}" | grep -A 10 "${getdatachksum_function_name}" | grep "xor    %eax,%eax" | awk '{print $1}' | sed 's/://')
    fi

    if [[ -z "$virtual_address" ]]; then
        echo "Unable to find address to patch; aborting"
        exit 1
    fi

    # Get the file offset corresponding to the virtual address of the search string
    text_file_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $6 }')
    text_virtual_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $4 }')

    file_offset=$((0x$virtual_address + 0x$text_file_offset - 0x$text_virtual_offset))

    bytes=$(xxd -p -l 2 --seek "${file_offset}" "${bin_path}" | tr -d '\n')

    expected_bytes='85c0'
    patched_bytes='31c0'

    if [[ "${bytes}" == "${patched_bytes}" ]]; then
        echo "Warning indicator patch already applied"
        echo
    elif [[ "${bytes}" == "${expected_bytes}" ]]; then
        echo "Patch the yellow warning indicating the checksum is modified"
        echo "    Patching bytes at offset ${file_offset} from ${bytes} to ${patched_bytes}"
        echo
        # Write the patched bytes back to the binary file
        echo "${patched_bytes}" | xxd -p -r | dd of="${bin_path}" bs=1 conv=notrunc seek="${file_offset}"
        echo
    else
        echo "Unexpected bytes at offset ${file_offset}: ${bytes}"
        echo "This shouldn't happen; please check the binary file."
        exit 1
    fi


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
        virtual_address=$(objdump -d --disassemble="${gettooltip_function_name}" "${bin_path}" | grep -A 10 "${getdatachksum_function_name}" | grep "xor    %eax,%eax" | awk '{print $1}' | sed 's/://')
    fi

    if [[ -z "$virtual_address" ]]; then
        echo "Unable to find address to patch; aborting"
        exit 1
    fi

    # Get the file offset corresponding to the virtual address of the search string
    text_file_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $6 }')
    text_virtual_offset=$(objdump -h "${bin_path}" | grep .text | awk '{ print $4 }')

    file_offset=$((0x$virtual_address + 0x$text_file_offset - 0x$text_virtual_offset))

    bytes=$(xxd -p -l 2 --seek "${file_offset}" "${bin_path}" | tr -d '\n')

    expected_bytes='85c0'
    patched_bytes='31c0'

    if [[ "${bytes}" == "${patched_bytes}" ]]; then
        echo "Tooltip patch already applied"
        echo
    elif [[ "${bytes}" == "${expected_bytes}" ]]; then
        echo "Patch the tooltip text indicating that the checksum is modified"
        echo "    Patching bytes at offset ${file_offset} from ${bytes} to ${patched_bytes}"
        echo
        # Write the patched bytes back to the binary file
        echo "${patched_bytes}" | xxd -p -r | dd of="${bin_path}" bs=1 conv=notrunc seek="${file_offset}"
        echo
    else
        echo "Unexpected bytes at offset ${file_offset}: ${bytes}"
        echo "This shouldn't happen; please check the binary file."
        exit 1
    fi
}



get_function_including_address() {
    address="$1"
    readelf --debug-dump=frames "$bin_path" |
    gawk -v address="${address}" '
        /FDE.*pc=/ {
            split($0, parts, "pc=")
            split(parts[2], bounds, /\.\./)
            start = strtonum("0x" bounds[1])
            end = strtonum("0x" bounds[2])
            if (strtonum("0x" address) >= start && strtonum("0x" address) < end)
                printf "%x\n", start
        }
    '
}

patch_binary_without_symbols() {
    echo "Patching binary without symbols"

    # 20261104 build: 0x037c0508
    string_byte_offset=$(grep --byte-offset --only-matching --text checksum_manifest.txt "${bin_path}" | cut -f 1 -d :)

    # Get the virtual address corresponding to the byte offset of the search string
    rodata_file_offset=$(objdump -h "${bin_path}" | grep .rodata | awk '{ print $6 }')
    rodata_virtual_offset=$(objdump -h "${bin_path}" | grep .rodata | awk '{ print $4 }')

    string_virtual_address_decimal=$(($string_byte_offset + 0x$rodata_virtual_offset - 0x$rodata_file_offset))
    string_virtual_address=$(printf '%x' $string_virtual_address_decimal)

    if $verbose; then
        echo "checksum_manifest.txt found: 0x${string_virtual_address}"
    fi

    # Find the function where it's used; this is CApplication::CalculateGameFilesChecksum
    string_usage_address=$(objdump -d "${bin_path}" | grep "${string_virtual_address}" | cut -f 1 -d : | tr -d ' ')
    if $verbose; then
        echo "checksum_manifest.txt usage: 0x${string_usage_address}"
    fi

    CalculateGameFilesChecksum_address=$(get_function_including_address "${string_usage_address}")
    if $verbose; then
        echo "CalculateGameFilesChecksum address: 0x${CalculateGameFilesChecksum_address}"
    fi

    # Now find where CApplication::CalculateGameFilesChecksum is called
    CalculateGameFilesChecksum_usage_address=$(objdump -d "${bin_path}" | grep "${CalculateGameFilesChecksum_address}" | cut -f 1 -d : | tr -d ' ' | head -n 1)
    if $verbose; then
        echo "CalculateGameFilesChecksum usage: 0x${CalculateGameFilesChecksum_usage_address}"
    fi

    # Find address to patch within 10 instructions of usage address; don't want to go further or we'll patch the wrong instruction
    # 20261104 build: 0x8eec9b
    address_to_patch=$(objdump -d --start-address="0x${CalculateGameFilesChecksum_usage_address}" --stop-address=$((0x"${CalculateGameFilesChecksum_usage_address}" + 100)) "${bin_path}" | grep -A 10 "${CalculateGameFilesChecksum_usage_address}" | grep "test   %ebx,%ebx" | awk '{print $1}' | sed 's/://')

    if [[ -z "$address_to_patch" ]]; then
        address_to_patch=$(objdump -d --start-address="0x${CalculateGameFilesChecksum_usage_address}" --stop-address=$((0x"${CalculateGameFilesChecksum_usage_address}" + 100)) "${bin_path}" | grep -A 10 "${CalculateGameFilesChecksum_usage_address}" | grep "xor    %ebx,%ebx" | awk '{print $1}' | sed 's/://')
    fi

    if $verbose; then
        echo Address to patch: "0x${address_to_patch}"
    fi

    if [[ -z "$address_to_patch" ]]; then
        echo "Unable to find address to patch; aborting"
        exit 1
    fi

    file_offset_to_patch=$((0x$address_to_patch + 0x$rodata_file_offset - 0x$rodata_virtual_offset))

    if $verbose; then
        echo File offset to patch: "0x${file_offset_to_patch}"
    fi

    bytes=$(xxd -p -l 2 --seek "${file_offset_to_patch}" "${bin_path}" | tr -d '\n')

    # See https://steamcommunity.com/sharedfiles/filedetails/?id=2460079052
    expected_bytes='85db'
    patched_bytes='31db'

    if [[ "${bytes}" == "${patched_bytes}" ]]; then
        echo "Achievements with mods patch already applied"
        echo
    elif [[ "${bytes}" == "${expected_bytes}" ]]; then
        echo "Patch the checksum test to make achivements earnable with mods that modify the checksum integrity"
        echo "    Patching bytes at offset ${file_offset_to_patch} from ${bytes} to ${patched_bytes}"
        echo
        # Write the patched bytes back to the binary file
        echo "${patched_bytes}" | xxd -p -r | dd of="${bin_path}" bs=1 conv=notrunc seek="${file_offset_to_patch}"
        echo
    else
        echo "Unexpected bytes at offset ${file_offset_to_patch}: ${bytes}"
        echo "This shouldn't happen; please check the binary file."
        exit 1
    fi

    echo "NOTE: Not applying aesthetic patches"
}

# See if the binary has symbols; the binary was stripped as of update 4.5.3 (2026-11-04)
if readelf -S "${bin_path}" | grep .symtab; then
    patch_binary_with_symbols
else
    patch_binary_without_symbols
fi
