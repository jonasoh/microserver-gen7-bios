#!/bin/sh
# Build a FreeDOS USB image that flashes the modded HP MicroServer N40L BIOS
# without user interaction.
#
# Needs: curl, mtools, and bsdtar or 7-Zip (7zz/7z).
set -eu

FD_ZIP=FD14-LiteUSB.zip
FD_URL=https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.4/$FD_ZIP
FD_SHA=857dcd2ebf9d3d094320154db5fb5b830acba6fb98f981a95a0ca7ab3350338b # freedos.org/download/verify.txt
MOD_ZIP=N40L-Mod-Files.zip
MOD_URL=https://www.nathanielperez.us/blog/$MOD_ZIP
MOD_SHA=45caf59278f0738b594e5e1ed248ebc5edf9e3b6636753909893056ed15818d1
OUT=n40l-bios.img
W=work

# bsdtar (debian package libarchive-tools) can handle unzipping exe files
if command -v bsdtar >/dev/null; then
	x() { mkdir -p "$2" && bsdtar -xf "$1" -C "$2"; }
else
	Z=$(command -v 7zz || command -v 7z)
	x() { "$Z" x -y -o"$2" "$1" >/dev/null; }
fi

for z in "$FD_ZIP $FD_URL $FD_SHA" "$MOD_ZIP $MOD_URL $MOD_SHA"; do
	set -- $z
	[ -f "$1" ] || curl -fL -o "$1" "$2"
	h=$({ sha256sum "$1" 2>/dev/null || shasum -a 256 "$1"; } | cut -d' ' -f1)
	[ "$h" = "$3" ] || { echo "$1: bad SHA-256 $h" >&2; exit 1; }
done

rm -rf "$W"
x "$FD_ZIP" "$W/fd"
x "$MOD_ZIP" "$W/mod"
x "$W/mod/SP64420.exe" "$W/sp"

# HP's flash.bat refers to the ROM by its short name; give the modded ROM an 8.3 name.
sed 's/O41100~1\.rom/N40LMOD.ROM/' "$W/sp/USB Key/flash.bat" > "$W/flash.bat"
printf 'FILES=20\r\nBUFFERS=80\r\nSHELL=\\FREEDOS\\BIN\\COMMAND.COM \\FREEDOS\\BIN /E:1024 /P=\\FDAUTO.BAT\r\n' > "$W/fdconfig.sys"
printf '@echo off\r\nSET PATH=\\FREEDOS\\BIN\r\ncall flash.bat\r\necho BIOS flash finished. Remove the USB stick and power cycle the server.\r\n' > "$W/fdauto.bat"

cp "$W/fd/FD14LITE.img" "$OUT"
I="$OUT@@32256" # FAT partition starts at sector 63
export MTOOLS_SKIP_CHECK=1
mcopy -o -i "$I" "$W/fdconfig.sys" ::/FDCONFIG.SYS
mcopy -o -i "$I" "$W/fdauto.bat" ::/FDAUTO.BAT
mcopy -o -i "$I" "$W/flash.bat" ::/FLASH.BAT
mcopy -o -i "$I" "$W/sp/USB Key/kbd.exe" ::/KBD.EXE
mcopy -o -i "$I" "$W/mod/O41100113mod/O41100113.ROM" ::/N40LMOD.ROM
rm -rf "$W"
echo "Done: $OUT"
