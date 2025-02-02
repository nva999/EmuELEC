#!/bin/sh

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present SumavisionQ5 (https://github.com/SumavisionQ5)
# Modifications by Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile

PLATFORM="${1}"

ROMNAME=$(basename "${2%.*}")
RACONFIG="/storage/.config/retroarch/retroarch.cfg"
OPACITY="1.000000"
BEZELDIR="/storage/roms/bezels"
DEFAULT_BEZEL="false"

case ${PLATFORM} in
 "arcade"|"fba"|"fbn"|"neogeo"|"mame"|cps*)
   PLATFORM="ARCADE"
  ;;
  "default")
  if [ -f "/storage/.config/bezels_enabled" ]; then
  clear_bezel
  sed -i '/input_overlay = "/d' ${RACONFIG}
  rm "/storage/.config/bezels_enabled"
  fi
   exit 0
  ;;
  "SETUP")
  # fbterm does not need bezels
  exit 0
  ;;
esac

 if [ ! -f "/storage/.config/bezels_enabled" ]; then
   touch /storage/.config/bezels_enabled
 fi

# we make sure the platform is all lowercase
PLATFORM=${PLATFORM,,}

# bezelmap.cfg in ${BEZELDIR}/ is to share bezels between arcade clones and parent. 
BEZELMAP="/emuelec/bezels/arcademap.cfg"
BZLNAME=$(sed -n "/"${PLATFORM}"_"${ROMNAME}" = /p" "${BEZELMAP}")
BZLNAME="${BZLNAME#*\"}"
BZLNAME="${BZLNAME%\"*}"
OVERLAYDIR1=$(find ${BEZELDIR}/${PLATFORM} -maxdepth 1 -iname "${ROMNAME}*.cfg" | sort -V | head -n 1)
[ ! -z "${BZLNAME}" ] && OVERLAYDIR2=$(find ${BEZELDIR}/${PLATFORM} -maxdepth 1 -iname "${BZLNAME}*.cfg" | sort -V | head -n 1)
OVERLAYDIR3="${BEZELDIR}/${PLATFORM}/default.cfg"

clear_bezel() { 
		sed -i '/aspect_ratio_index = "/d' ${RACONFIG}
		sed -i '/custom_viewport_width = "/d' ${RACONFIG}
		sed -i '/custom_viewport_height = "/d' ${RACONFIG}
		sed -i '/custom_viewport_x = "/d' ${RACONFIG}
		sed -i '/custom_viewport_y = "/d' ${RACONFIG}
		sed -i '/video_scale_integer = "/d' ${RACONFIG}
		sed -i '/input_overlay_opacity = "/d' ${RACONFIG}
		echo 'video_scale_integer = "false"' >> ${RACONFIG}
		echo 'input_overlay_opacity = "0.150000"' >> ${RACONFIG}
}

set_bezel() {
# $OPACITY: input_overlay_opacity
# ${1}: custom_viewport_width 
# ${2}: custom_viewport_height
# ${3}: ustom_viewport_x
# ${4}: custom_viewport_y
# ${5}: video_scale_integer
# ${6}: aspect_ratio_index
        clear_bezel
        sed -i '/input_overlay_opacity = "/d' ${RACONFIG}
        sed -i "1i input_overlay_opacity = \"$OPACITY\"" ${RACONFIG}
		sed -i "2i aspect_ratio_index = \"${6}\"" ${RACONFIG}
		sed -i "3i custom_viewport_width = \"${1}\"" ${RACONFIG}
		sed -i "4i custom_viewport_height = \"${2}\"" ${RACONFIG}
		sed -i "5i custom_viewport_x = \"${3}\"" ${RACONFIG}
		sed -i "6i custom_viewport_y = \"${4}\"" ${RACONFIG}
		sed -i "7i video_scale_integer = \"${5}\"" ${RACONFIG}
}

check_overlay_dir() {
# The bezel will be searched and used in following order:
# 1.${OVERLAYDIR1} will be used, if it does not exist, then
# 2.${OVERLAYDIR2} will be used, if it does not exist, then
# 3.${OVERLAYDIR2} platform default bezel as "${BEZELDIR}/"${PLATFORM}"/default.cfg\" will be used.
# 4.Default bezel at "${BEZELDIR}/default.cfg\" will be used.
	
	sed -i '/input_overlay = "/d' ${RACONFIG}
		
	if [ -f "${OVERLAYDIR1}" ]; then
		echo -e "input_overlay = \""${OVERLAYDIR1}"\"\n" >> ${RACONFIG}
	elif [ -f "${OVERLAYDIR2}" ]; then
		echo -e "input_overlay = \""${OVERLAYDIR2}"\"\n" >> ${RACONFIG}
	elif [ -f "${OVERLAYDIR3}" ]; then
		echo -e "input_overlay = \""${OVERLAYDIR3}"\"\n" >> ${RACONFIG}
	else
		echo -e "input_overlay = \"${BEZELDIR}/default.cfg\"\n" >> ${RACONFIG}
		DEFAULT_BEZEL="true"
	fi
}


# Only 720P and 1080P can use bezels. For 480p/i and 576p/i we just delete bezel config.
hdmimode=$(cat /sys/class/display/mode)

# This whole section needs to be reworked, specially for Odroid-GO Super, but for now we just force bezels at 720p
if [ $(oga_ver) == "OGS" ]; then
    hdmimode="OGS"
fi

case ${hdmimode} in
  480*)
	sed -i '/input_overlay = "/d' ${RACONFIG}
	clear_bezel
  ;;
  576*)
	sed -i '/input_overlay = "/d' ${RACONFIG}
	clear_bezel
  ;;
  "OGS")
	check_overlay_dir "${PLATFORM}"
        case "${PLATFORM}" in
            "gamegear")
                set_bezel "780" "580" "245" "70" "true" "22"
            ;;
            "gb")
                set_bezel "429" "380" "420" "155" "true" "22"
            ;;
            "gbc")
                set_bezel "430" "380" "425" "155" "true" "22"
            ;;
            "ngp")
                set_bezel "461" "428" "407" "145" "true" "22"
            ;;
            "ngpc")
                set_bezel "460" "428" "407" "145" "true" "22"
            ;;
            "wonderswan")
                set_bezel "645" "407" "325" "150" "true" "22"
            ;;
            "wonderswancolor")
                set_bezel "643" "405" "325" "150" "true" "22"
            ;;
            *)
                # delete aspect_ratio_index to make sure video is expanded fullscreen. Only certain handheld platforms need custom_viewport.
                clear_bezel
                sed -i '/input_overlay_opacity = "/d' ${RACONFIG}
                sed -i "1i input_overlay_opacity = \"$OPACITY\"" ${RACONFIG}
            ;;
        esac
    ;;
    *)
        check_overlay_dir "${PLATFORM}"
        clear_bezel
        sed -i '/input_overlay_opacity = "/d' ${RACONFIG}
        sed -i "1i input_overlay_opacity = \"$OPACITY\"" ${RACONFIG}
    ;;
esac

if [ "${DEFAULT_BEZEL}" = "true" ] && [ $(oga_ver) != "OGS" ]; then
	set_bezel "1427" "1070" "247" "10" "false" "23"
elif [ $(oga_ver) != "OGS" ]; then
	set_bezel "1427" "1070" "247" "10" "true" "22"
fi
