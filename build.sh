#!/usr/bin/env bash
# PixelBlaster build helper script

# red = errors, cyan = warnings, green = confirmations, blue = informational
# plain for generic text, bold for titles, reset flag at each end of line
# plain blue should not be used for readability reasons - use plain cyan instead
CLR_RST=$(tput sgr0)                        ## reset flag
CLR_RED=$CLR_RST$(tput setaf 1)             #  red, plain
CLR_GRN=$CLR_RST$(tput setaf 2)             #  green, plain
CLR_BLU=$CLR_RST$(tput setaf 4)             #  blue, plain
CLR_CYA=$CLR_RST$(tput setaf 6)             #  cyan, plain
CLR_BLD=$(tput bold)                        ## bold flag
CLR_BLD_RED=$CLR_RST$CLR_BLD$(tput setaf 1) #  red, bold
CLR_BLD_GRN=$CLR_RST$CLR_BLD$(tput setaf 2) #  green, bold
CLR_BLD_BLU=$CLR_RST$CLR_BLD$(tput setaf 4) #  blue, bold
CLR_BLD_CYA=$CLR_RST$CLR_BLD$(tput setaf 6) #  cyan, bold

# Set defaults
BUILD_TYPE="userdebug"

function checkExit () {
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "${CLR_BLD_RED}Build failed!${CLR_RST}"
        echo -e ""
        exit $EXIT_CODE
    fi
}

# Output usage help
function showHelpAndExit {
        echo -e "${CLR_BLD_BLU}Usage: $0 <device> [options]${CLR_RST}"
        echo -e ""
        echo -e "${CLR_BLD_BLU}Options:${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -h, --help            Display this help message${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -c, --clean           Wipe the tree before building${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -i, --installclean    Dirty build - Use 'installclean'${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -r, --repo-sync       Sync before building${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -v, --variant         Build variant - Can be Official or Unofficial${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -t, --build-type      Specify build type (userdebug by default)${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -j, --jobs            Specify jobs/threads to use${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -m, --module          Build a specific module${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -s, --sign-keys       Specify path to sign key mappings${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -p, --pwfile          Specify path to sign key password file${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -b, --backup-unsigned Store a copy of unsigned package along with signed${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -d, --delta           Generate a delta ota from the specified target_files zip${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -z, --imgzip          Generate fastboot flashable image zip from signed target_files${CLR_RST}"
        echo -e "${CLR_BLD_BLU}  -u, --upload          Automatically upload release build and push OTA update${CLR_RST}"
        exit 1
}

# Setup getopt.
long_opts="help,clean,installclean,repo-sync,variant:,build-type:,jobs:,module:,sign-keys:,pwfile:,backup-unsigned,delta:,imgzip,upload"
getopt_cmd=$(getopt -o hcirv:t:j:m:s:p:bd:zu --long "$long_opts" \
            -n $(basename $0) -- "$@") || \
            { echo -e "${CLR_BLD_RED}\nError: Getopt failed. Extra args\n${CLR_RST}"; showHelpAndExit; exit 1;}

eval set -- "$getopt_cmd"

while true; do
    case "$1" in
        -h|--help|h|help) showHelpAndExit;;
        -c|--clean|c|clean) FLAG_CLEAN_BUILD=y;;
        -i|--installclean|i|installclean) FLAG_INSTALLCLEAN_BUILD=y;;
        -r|--repo-sync|r|repo-sync) FLAG_SYNC=y;;
        -v|--variant|v|variant) BUILD_VARIANT="$2"; shift;;
        -t|--build-type|t|build-type) BUILD_TYPE="$2"; shift;;
        -j|--jobs|j|jobs) JOBS="$2"; shift;;
        -m|--module|m|module) MODULES+=("$2"); echo $2; shift;;
        -s|--sign-keys|s|sign-keys) KEY_MAPPINGS="$2"; shift;;
        -p|--pwfile|p|pwfile) PWFILE="$2"; shift;;
        -b|--backup-unsigned|b|backup-unsigned) FLAG_BACKUP_UNSIGNED=y;;
        -d|--delta|d|delta) DELTA_TARGET_FILES="$2"; shift;;
        -z|--imgzip|img|imgzip) FLAG_IMG_ZIP=y;;
        -u|--upload|u|upload) UPLOAD=y;;
        --) shift; break;;
    esac
    shift
done

# Mandatory argument
if [ $# -eq 0 ]; then
    echo -e "${CLR_BLD_RED}Error: No device specified${CLR_RST}"
    showHelpAndExit
fi
export DEVICE="$1"; shift

# Make sure we are running on 64-bit before carrying on with anything
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
if [ "$ARCH" != "64" ]; then
        echo -e "${CLR_BLD_RED}error: unsupported arch (expected: 64, found: $ARCH)${CLR_RST}"
        exit 1
fi

# Set up paths
cd $(dirname $0)
DIR_ROOT=$(pwd)

# Make sure everything looks sane so far
if [ ! -d "$DIR_ROOT/vendor/blaster" ]; then
        echo -e "${CLR_BLD_RED}error: insane root directory ($DIR_ROOT)${CLR_RST}"
        exit 1
fi

# Setup Build variant if specified
if [ $BUILD_VARIANT ]; then
    BUILD_VARIANT=`echo $BUILD_VARIANT |  tr "[:upper:]" "[:lower:]"`
    if [ "${BUILD_VARIANT}" = "official" ]; then
        DEVICE_LIST=`find vendor/blaster/products/ -name *.dependencies | sed -n 's/vendor\/blaster\/products\/\([^/]*\).dependencies/\1/p'`
        if [[ ! $DEVICE_LIST =~ (^|[[:space:]])$DEVICE($|[[:space:]]) ]]; then
            echo -e "${CLR_BLD_RED} Error! Your device is not officially supported.\n Please do an unofficial build.${CLR_RST}"
            exit 1
        else
            export BLASTER_BUILDTYPE=OFFICIAL
        fi
    elif [ "${BUILD_VARIANT}" = "unofficial" ]; then
        export BLASTER_BUILDTYPE=UNOFFICIAL
    else
        echo -e "${CLR_BLD_RED} Unknown Build variant - use official or unofficial${CLR_RST}"
        exit 1
    fi
fi

# Initializationizing!
echo -e "${CLR_BLD_BLU}Setting up the environment${CLR_RST}"
echo -e ""
. build/envsetup.sh
echo -e ""

# Use the thread count specified by user
CMD=""
if [ $JOBS ]; then
  CMD+="-j$JOBS"
fi

# Pick the default thread count (allow overrides from the environment)
if [ -z "$JOBS" ]; then
        if [ "$(uname -s)" = 'Darwin' ]; then
                JOBS=$(sysctl -n machdep.cpu.core_count)
        else
                JOBS=$(cat /proc/cpuinfo | grep '^processor' | wc -l)
        fi
fi

# Grab the build version
BLASTER_DISPLAY_VERSION="$(cat $DIR_ROOT/vendor/blaster/config/version.mk | grep 'BLASTER_BUILD_VERSION := *' | sed 's/.*= //') "

# Prep for a clean build, if requested so
if [ "$FLAG_CLEAN_BUILD" = 'y' ]; then
        echo -e "${CLR_BLD_BLU}Cleaning output files left from old builds${CLR_RST}"
        echo -e ""
        m clobber "$CMD"
fi

# Sync up, if asked to
if [ "$FLAG_SYNC" = 'y' ]; then
        echo -e "${CLR_BLD_BLU}Downloading the latest source files${CLR_RST}"
        echo -e ""
        repo sync -j"$JOBS" -c --no-clone-bundle --current-branch --no-tags
fi

# Check the starting time (of the real build process)
TIME_START=$(date +%s.%N)

# Friendly logging to tell the user everything is working fine is always nice
echo -e "${CLR_BLD_GRN}Building PixelBlaster $BLASTER_DISPLAY_VERSION for $DEVICE${CLR_RST}"
echo -e "${CLR_GRN}Start time: $(date)${CLR_RST}"
echo -e ""

# Lunch-time!
echo -e "${CLR_BLD_BLU}Lunching $DEVICE${CLR_RST} ${CLR_CYA}(Including dependencies sync)${CLR_RST}"
echo -e ""
lunch "blaster_$DEVICE-$BUILD_TYPE"
BLASTER_VERSION="$(get_build_var BLASTER_VERSION)"
checkExit
echo -e ""

# Perform installclean, if requested so
if [ "$FLAG_INSTALLCLEAN_BUILD" = 'y' ]; then
	echo -e "${CLR_BLD_BLU}Cleaning compiled image files left from old builds${CLR_RST}"
	echo -e ""
	m installclean "$CMD"
fi

# Build away!
echo -e "${CLR_BLD_BLU}Starting compilation${CLR_RST}"
echo -e ""

# If we aren't in Jenkins, use the engineering tag
if [ -z "${BUILD_NUMBER}" ]; then
    export FILE_NAME_TAG=eng.$USER
else
    export FILE_NAME_TAG=$BUILD_NUMBER
fi

# Build a specific module(s)
if [ "${MODULES}" ]; then
    m ${MODULES[@]} "$CMD"
    checkExit

# Build signed rom package if specified
elif [ "${KEY_MAPPINGS}" ]; then
    # Set sign key password file if specified
    if [ "${PWFILE}" ]; then
        export ANDROID_PW_FILE=$PWFILE
    fi

    # Make target-files-package
    m otatools target-files-package "$CMD"

    checkExit

    echo -e "${CLR_BLD_BLU}Signing target files apks${CLR_RST}"
    sign_target_files_apks -o -d $KEY_MAPPINGS \
    --extra_apks com.android.adbd.apex=certs/com.android.adbd \
    --extra_apks com.android.adservices.apex=certs/com.android.adservices \
    --extra_apks com.android.adservices.api.apex=certs/com.android.adservices.api \
    --extra_apks com.android.appsearch.apex=certs/com.android.appsearch \
    --extra_apks com.android.art.apex=certs/com.android.art \
    --extra_apks com.android.bluetooth.apex=certs/com.android.bluetooth \
    --extra_apks com.android.btservices.apex=certs/com.android.btservices \
    --extra_apks com.android.cellbroadcast.apex=certs/com.android.cellbroadcast \
    --extra_apks com.android.compos.apex=certs/com.android.compos \
    --extra_apks com.android.configinfrastructure.apex=certs/com.android.configinfrastructure \
    --extra_apks com.android.connectivity.resources.apex=certs/com.android.connectivity.resources \
    --extra_apks com.android.conscrypt.apex=certs/com.android.conscrypt \
    --extra_apks com.android.devicelock.apex=certs/com.android.devicelock \
    --extra_apks com.android.extservices.apex=certs/com.android.extservices \
    --extra_apks com.android.hardware.wifi.apex=certs/com.android.hardware.wifi \
    --extra_apks com.android.healthfitness.apex=certs/com.android.healthfitness \
    --extra_apks com.android.hotspot2.osulogin.apex=certs/com.android.hotspot2.osulogin \
    --extra_apks com.android.i18n.apex=certs/com.android.i18n \
    --extra_apks com.android.ipsec.apex=certs/com.android.ipsec \
    --extra_apks com.android.media.apex=certs/com.android.media \
    --extra_apks com.android.media.swcodec.apex=certs/com.android.media.swcodec \
    --extra_apks com.android.mediaprovider.apex=certs/com.android.mediaprovider \
    --extra_apks com.android.nearby.halfsheet.apex=certs/com.android.nearby.halfsheet \
    --extra_apks com.android.networkstack.tethering.apex=certs/com.android.networkstack.tethering \
    --extra_apks com.android.neuralnetworks.apex=certs/com.android.neuralnetworks \
    --extra_apks com.android.ondevicepersonalization.apex=certs/com.android.ondevicepersonalization \
    --extra_apks com.android.os.statsd.apex=certs/com.android.os.statsd \
    --extra_apks com.android.permission.apex=certs/com.android.permission \
    --extra_apks com.android.resolv.apex=certs/com.android.resolv \
    --extra_apks com.android.rkpd.apex=certs/com.android.rkpd \
    --extra_apks com.android.runtime.apex=certs/com.android.runtime \
    --extra_apks com.android.safetycenter.resources.apex=certs/com.android.safetycenter.resources \
    --extra_apks com.android.scheduling.apex=certs/com.android.scheduling \
    --extra_apks com.android.sdkext.apex=certs/com.android.sdkext \
    --extra_apks com.android.support.apexer.apex=certs/com.android.support.apexer \
    --extra_apks com.android.telephony.apex=certs/com.android.telephony \
    --extra_apks com.android.telephonymodules.apex=certs/com.android.telephonymodules \
    --extra_apks com.android.tethering.apex=certs/com.android.tethering \
    --extra_apks com.android.tzdata.apex=certs/com.android.tzdata \
    --extra_apks com.android.uwb.apex=certs/com.android.uwb \
    --extra_apks com.android.uwb.resources.apex=certs/com.android.uwb.resources \
    --extra_apks com.android.virt.apex=certs/com.android.virt \
    --extra_apks com.android.vndk.current.apex=certs/com.android.vndk.current \
    --extra_apks com.android.wifi.apex=certs/com.android.wifi \
    --extra_apks com.android.wifi.dialog.apex=certs/com.android.wifi.dialog \
    --extra_apks com.android.wifi.resources.apex=certs/com.android.wifi.resources \
    --extra_apks com.google.pixel.vibrator.hal.apex=certs/com.google.pixel.vibrator.hal \
    --extra_apks com.qorvo.uwb.apex=certs/com.qorvo.uwb \
    --extra_apex_payload_key com.android.adbd.apex=certs/com.android.adbd.pem \
    --extra_apex_payload_key com.android.adservices.apex=certs/com.android.adservices.pem \
    --extra_apex_payload_key com.android.adservices.api.apex=certs/com.android.adservices.api.pem \
    --extra_apex_payload_key com.android.appsearch.apex=certs/com.android.appsearch.pem \
    --extra_apex_payload_key com.android.art.apex=certs/com.android.art.pem \
    --extra_apex_payload_key com.android.bluetooth.apex=certs/com.android.bluetooth.pem \
    --extra_apex_payload_key com.android.btservices.apex=certs/com.android.btservices.pem \
    --extra_apex_payload_key com.android.cellbroadcast.apex=certs/com.android.cellbroadcast.pem \
    --extra_apex_payload_key com.android.compos.apex=certs/com.android.compos.pem \
    --extra_apex_payload_key com.android.configinfrastructure.apex=certs/com.android.configinfrastructure.pem \
    --extra_apex_payload_key com.android.connectivity.resources.apex=certs/com.android.connectivity.resources.pem \
    --extra_apex_payload_key com.android.conscrypt.apex=certs/com.android.conscrypt.pem \
    --extra_apex_payload_key com.android.devicelock.apex=certs/com.android.devicelock.pem \
    --extra_apex_payload_key com.android.extservices.apex=certs/com.android.extservices.pem \
    --extra_apex_payload_key com.android.hardware.wifi.apex=certs/com.android.hardware.wifi.pem \
    --extra_apex_payload_key com.android.healthfitness.apex=certs/com.android.healthfitness.pem \
    --extra_apex_payload_key com.android.hotspot2.osulogin.apex=certs/com.android.hotspot2.osulogin.pem \
    --extra_apex_payload_key com.android.i18n.apex=certs/com.android.i18n.pem \
    --extra_apex_payload_key com.android.ipsec.apex=certs/com.android.ipsec.pem \
    --extra_apex_payload_key com.android.media.apex=certs/com.android.media.pem \
    --extra_apex_payload_key com.android.media.swcodec.apex=certs/com.android.media.swcodec.pem \
    --extra_apex_payload_key com.android.mediaprovider.apex=certs/com.android.mediaprovider.pem \
    --extra_apex_payload_key com.android.nearby.halfsheet.apex=certs/com.android.nearby.halfsheet.pem \
    --extra_apex_payload_key com.android.networkstack.tethering.apex=certs/com.android.networkstack.tethering.pem \
    --extra_apex_payload_key com.android.neuralnetworks.apex=certs/com.android.neuralnetworks.pem \
    --extra_apex_payload_key com.android.ondevicepersonalization.apex=certs/com.android.ondevicepersonalization.pem \
    --extra_apex_payload_key com.android.os.statsd.apex=certs/com.android.os.statsd.pem \
    --extra_apex_payload_key com.android.permission.apex=certs/com.android.permission.pem \
    --extra_apex_payload_key com.android.resolv.apex=certs/com.android.resolv.pem \
    --extra_apex_payload_key com.android.rkpd.apex=certs/com.android.rkpd.pem \
    --extra_apex_payload_key com.android.runtime.apex=certs/com.android.runtime.pem \
    --extra_apex_payload_key com.android.safetycenter.resources.apex=certs/com.android.safetycenter.resources.pem \
    --extra_apex_payload_key com.android.scheduling.apex=certs/com.android.scheduling.pem \
    --extra_apex_payload_key com.android.sdkext.apex=certs/com.android.sdkext.pem \
    --extra_apex_payload_key com.android.support.apexer.apex=certs/com.android.support.apexer.pem \
    --extra_apex_payload_key com.android.telephony.apex=certs/com.android.telephony.pem \
    --extra_apex_payload_key com.android.telephonymodules.apex=certs/com.android.telephonymodules.pem \
    --extra_apex_payload_key com.android.tethering.apex=certs/com.android.tethering.pem \
    --extra_apex_payload_key com.android.tzdata.apex=certs/com.android.tzdata.pem \
    --extra_apex_payload_key com.android.uwb.apex=certs/com.android.uwb.pem \
    --extra_apex_payload_key com.android.uwb.resources.apex=certs/com.android.uwb.resources.pem \
    --extra_apex_payload_key com.android.virt.apex=certs/com.android.virt.pem \
    --extra_apex_payload_key com.android.vndk.current.apex=certs/com.android.vndk.current.pem \
    --extra_apex_payload_key com.android.wifi.apex=certs/com.android.wifi.pem \
    --extra_apex_payload_key com.android.wifi.dialog.apex=certs/com.android.wifi.dialog.pem \
    --extra_apex_payload_key com.android.wifi.resources.apex=certs/com.android.wifi.resources.pem \
    --extra_apex_payload_key com.google.pixel.vibrator.hal.apex=certs/com.google.pixel.vibrator.hal.pem \
    --extra_apex_payload_key com.qorvo.uwb.apex=certs/com.qorvo.uwb.pem \
        "$OUT"/obj/PACKAGING/target_files_intermediates/blaster_$DEVICE-target_files-$FILE_NAME_TAG.zip \
        blaster-$BLASTER_VERSION-signed-target_files-$FILE_NAME_TAG.zip

    checkExit

    echo -e "${CLR_BLD_BLU}Generating signed install package${CLR_RST}"
    ota_from_target_files -k $KEY_MAPPINGS/releasekey \
        --block ${INCREMENTAL} \
        blaster-$BLASTER_VERSION-signed-target_files-$FILE_NAME_TAG.zip \
        PixelBlaster-$BLASTER_VERSION.zip

    checkExit

    if [ "$DELTA_TARGET_FILES" ]; then
        # die if base target doesn't exist
        if [ ! -f "$DELTA_TARGET_FILES" ]; then
                echo -e "${CLR_BLD_RED}Delta error: base target files don't exist ($DELTA_TARGET_FILES)${CLR_RST}"
                exit 1
        fi
        ota_from_target_files -k $KEY_MAPPINGS/releasekey \
            --block --incremental_from $DELTA_TARGET_FILES \
            blaster-$BLASTER_VERSION-signed-target_files-$FILE_NAME_TAG.zip \
            PixelBlaster-$BLASTER_VERSION-delta.zip
        checkExit
    fi

    if [ "$FLAG_IMG_ZIP" = 'y' ]; then
        echo -e "${CLR_BLD_BLU}Generating signed fastboot package${CLR_RST}"
        img_from_target_files \
            blaster-$BLASTER_VERSION-signed-target_files-$FILE_NAME_TAG.zip \
            PixelBlaster-$BLASTER_VERSION-image.zip
        checkExit
    fi
# Build rom package
elif [ "$FLAG_IMG_ZIP" = 'y' ]; then
    m otatools target-files-package "$CMD"

    checkExit

    echo -e "${CLR_BLD_BLU}Generating install package${CLR_RST}"
    ota_from_target_files \
        "$OUT"/obj/PACKAGING/target_files_intermediates/blaster_$DEVICE-target_files-$FILE_NAME_TAG.zip \
        PixelBlaster-$BLASTER_VERSION.zip

    checkExit

    echo -e "${CLR_BLD_BLU}Generating fastboot package${CLR_RST}"
    img_from_target_files \
        "$OUT"/obj/PACKAGING/target_files_intermediates/blaster_$DEVICE-target_files-$FILE_NAME_TAG.zip \
        PixelBlaster-$BLASTER_VERSION-image.zip

    checkExit

else
    m otapackage "$CMD"

    checkExit

    cp -f $OUT/blaster_$DEVICE-ota-$FILE_NAME_TAG.zip $OUT/PixelBlaster-$BLASTER_VERSION.zip
    echo "Package Complete: $OUT/PixelBlaster-$BLASTER_VERSION.zip"
fi
echo -e ""

if [ $BUILD_VARIANT ]; then
    BUILD_VARIANT=`echo $BUILD_VARIANT |  tr "[:upper:]" "[:lower:]"`
if [ "${BUILD_VARIANT}" = "official" ]; then
if [ ! -z "$UPLOAD" ]; then
        echo -e "${CLR_BLD_GRN}Pushing OTA...${CLR_RST}"
        ./ota.sh $DEVICE PixelBlaster-$BLASTER_VERSION.zip
fi
fi
fi

# Check the finishing time
TIME_END=$(date +%s.%N)

# Log those times at the end as a fun fact of the day
echo -e "${CLR_BLD_GRN}Total time elapsed:${CLR_RST} ${CLR_GRN}$(echo "($TIME_END - $TIME_START) / 60" | bc) minutes ($(echo "$TIME_END - $TIME_START" | bc) seconds)${CLR_RST}"
echo -e ""

exit 0
