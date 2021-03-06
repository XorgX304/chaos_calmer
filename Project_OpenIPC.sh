#!/bin/bash
#
# More information on the site - http://openipc.org
#


set -e # exit immediately if a command exits with a non-zero status.

if [ $# -ge 1 ]; then
  build=$1
  vendor=$2
fi


prepare_image_config() {
    echo -e "\nStart building OpenWrt firmware for $1 with kernel $2"                      #
    echo "$1" > target/linux/hi35xx/base-files/etc/soc-version                             # Create identification file for updates
    cp target/linux/hi35xx/examples/.$3 ./.config                                          # Copy default config
    sed -i "s/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=$2/" target/linux/hi35xx/Makefile       # Set right kernel version
    ./scripts/feeds update glutinium openipc                                               # Update glutinium and openipc feed
    #sed -i 's/# CONFIG_ALL is not set.*/CONFIG_ALL=y/' ./.config                          # Enable all packages
    #make package/feeds/OpenIPC/histreamer/{compile,install}
}

start_build() {
    make clean && time make V=s -j$(($(nproc)+1))                                          # Clean and compile
    rm target/linux/hi35xx/base-files/etc/soc-version                                      # Remove temporary identification file for updates
    #DATE=$(date +%Y%m%d) ; [ -d zft_lab ] || mkdir -p zft_lab                             # Set time and create output dir
    #cp -v bin/hi35xx/uImage-OpenWrt-HI35xx zft_lab/uImage-OpenWrt-${SOC}-${DATE}.bin      # Copy Firmware
}


case $build in

  hi3516cv100|hi3518av100|hi3518ev100)
    SOC=${build}
    prepare_image_config ${SOC} "3.0.8" "config_armv5tej_luci_default"
    start_build
    ;;

  hi3518cv100)
    SOC=${build}
    prepare_image_config ${SOC} "3.0.8" "config_18cv100_default"
    start_build
    ;;

  hi3516cv200)
    SOC=${build}
    prepare_image_config ${SOC} "3.4.35" "config_16cv200_jvt_s323h16vf"
    start_build
    ;;

  hi3518ev200|hi3518ev201)
    SOC=${build}
    prepare_image_config ${SOC} "3.4.35" "config_18ev200_jvt_s130h18v"
    start_build
    ;;


  hi3516cv300)
    SOC=${build}
    prepare_image_config ${SOC} "3.18.20" "config_16cv300_default"
    start_build
    ;;

  hi3516ev100)
    SOC=${build}
    prepare_image_config ${SOC} "3.18.20" "config_16ev100_default"
    start_build
    ;;

  hi3520dv100)
    SOC=${build}
    prepare_image_config ${SOC} "3.0.8" "config_armv7_micro"
    start_build
    ;;

#################

  16cv200_jvt_s323h16vf)
    SOC=${build}
    prepare_image_config ${SOC} "3.4.35" "config_16cv200_jvt_s323h16vf"
    start_build
    ;;

  18ev200_jvt_s130h18v)
    SOC=${build}
    prepare_image_config ${SOC} "3.4.35" "config_18ev200_jvt_s130h18v"
    start_build
    ;;

  18ev200_switcam_hs303)
    SOC=${build}
    prepare_image_config ${SOC} "3.4.35" "config_18ev200_switcam_hs303"
    start_build
    ;;

  18ev200_switcam_hs303_rotek)
    SOC=${build}
    prepare_image_config ${SOC} "3.4.35" "config_18ev200_switcam_hs303_rotek"
    start_build
    ;;

#################

  release)
    # Rebuild kernel, rootfs, firmware
    make V=99 -j$(($(nproc)+1)) target/install
    ;;

  update)
    # Update feeds
    ./scripts/feeds update glutinium openipc packages luci management routing telephony # zftlab
    ./scripts/feeds install -p glutinium -a -d m -f
    ./scripts/feeds install -p openipc -a -d m -f
    ./scripts/feeds install -p luci -a -d m -f
    ./scripts/feeds install -p packages -a -d m -f
    ./scripts/feeds install -p routing -a -d m -f
    ./scripts/feeds install -p management -a -d m -f
    ./scripts/feeds install -p telephony -a -d m -f
    #./scripts/feeds install -p zftlab -a -d m -f
    #
    sed -i 's/+luci-app-firewall//' feeds/luci/collections/luci/Makefile
    ;;

  project)
    # Show project changes
    HASH1="ceddf6298ad84c0ac103d25559e4e76a57f5bf76"
    HASH2="6022105ccc"
    #
    clear
    echo -e "\n####################################################################################################\n"
    git diff --name-only ${HASH1} ${HASH2} | grep -v "^dl/" | grep -v "target/linux/ar71xx" | grep -v "^target/linux/hi35xx" | grep -v "^target/linux/ramips" | grep -v "^package/boot" | grep -v "^user_cmarxmeier"
    echo -e "\n####################################################################################################\n"
    git diff --name-only ${HASH1} ${HASH2} | grep -e "^package/boot"
    echo -e "\n####################################################################################################\n"
    git diff --name-only ${HASH1} ${HASH2} | grep -e "^target/linux/hi35xx"
    echo -e "\n####################################################################################################\n"
    #git diff --name-only ${HASH1} ${HASH2} | grep -e "^target/linux/ar71xx"
    #echo -e "\n####################################################################################################\n"
    #git diff --name-only ${HASH1} ${HASH2} | grep -e "^target/linux/ramips"
    #echo -e "\n####################################################################################################\n"
    ;;

  push)
    echo "Start pushing firmware"
    cd bin/hi35xx
    scp openwrt-hi35xx-*-default-initramfs-uImage openwrt-hi35xx-*-default-uImage    root@172.28.200.72:/srv/tftp/                                # Push firmware to ZFT Lab. TFTP server
    scp openwrt-hi35xx-*-default-initramfs-uImage openwrt-hi35xx-*-default-uImage    zig@172.28.200.74:~                                          # Push firmware to my PC
    ;;

  upload)
    echo "Start uploading firmware and packages"
    cd bin/hi35xx
    scp openwrt-hi35xx-*-default-initramfs-uImage openwrt-hi35xx-*-default-uImage \
      root@araneus:/var/www/net_flyrouter/downloads/software/ipcam/GitHub_OpenWrt/Firmware/      # Upload firmware to WEB server
    scp -r packages/* \
      root@araneus:/var/www/net_flyrouter/downloads/software/ipcam/GitHub_OpenWrt/Packages/      # Upload packages to WEB server
    scp -r OpenWrt-ImageBuilder-* OpenWrt-SDK-* \
      root@araneus:/var/www/net_flyrouter/downloads/software/ipcam/GitHub_OpenWrt/SDK/           # Upload SDK an ImageBuilder to WEB server
    ;;

  ipeye)
    # For test
    ./scripts/feeds update zftlab
    #make package/feeds/glutinium/kdb/{clean,compile,install}
    make package/feeds/zftlab/ipeye/{clean,compile,install}
    #scp ./bin/hi35xx/packages/zftlab/*.ipk zig@172.28.200.74:~
    ;;

  minihttp)
    # For test
    ./scripts/feeds update glutinium
    make -j1 V=s package/feeds/glutinium/minihttp/{clean,compile,install}
    #scp root@172.28.200.80:/usr/bin/minihttp_test
    ;;

  osdrv1)
    # For test
    ./scripts/feeds update glutinium
    ./scripts/feeds install -f -p glutinium hisi-osdrv1-base hisi-sample
    make package/feeds/glutinium/hisi-osdrv1/clean  &&  make -j1 V=s package/feeds/glutinium/hisi-osdrv1/compile  &&  make -j1 V=s package/feeds/glutinium/hisi-osdrv1/install
    make package/feeds/glutinium/hisi-sample/clean  &&  make -j1 V=s package/feeds/glutinium/hisi-sample/compile  &&  make -j1 V=s package/feeds/glutinium/hisi-sample/install
    #scp ./bin/hi35xx/packages/glutinium/*.ipk zig@172.28.200.74:~
    ;;

  osdrv2)
    # For test
    ./scripts/feeds update glutinium
    ./scripts/feeds install -f -p glutinium hisi-osdrv2-base hisi-sample
    make package/feeds/glutinium/hisi-osdrv2/clean  &&  make -j1 V=s package/feeds/glutinium/hisi-osdrv2/compile  &&  make -j1 V=s package/feeds/glutinium/hisi-osdrv2/install
    make package/feeds/glutinium/hisi-sample/clean  &&  make -j1 V=s package/feeds/glutinium/hisi-sample/compile  &&  make -j1 V=s package/feeds/glutinium/hisi-sample/install
    #scp ./bin/hi35xx/packages/glutinium/*.ipk zig@172.28.200.74:~
    ;;

  uboot)
    make -j1 V=s package/boot/uboot-hi35xx/{clean,compile,install}
    ;;

  *)
    echo -e "\n#####################################"
    echo -e "\nMore information on the site - http://openipc.org\n"
    echo -e "\nPLEASE SELECT ONE OPTION IN COMMAND LINE"
    echo -e "\nProfiles:\n  16cv200_jvt_s323h16vf\n\n  18ev200_jvt_s130h18v\n  18ev200_switcam_hs303\n  18ev200_switcam_hs303_rotek"
    echo -e "\nUntested:\n  hi3516cv100\n  hi3518av100\n  hi3518cv100\n  hi3518ev100\n\n  hi3518ev201\n\n  hi3516cv300\n  hi3516ev100\n\n  hi3520dv100"
    #echo -e "\nSystem command section:\n  project\n  push\n  update\n  upload"
    #echo -e "\nRebuild software section:\n  osdrv2\n  release"
    echo -e "\n#####################################"
    (echo -e "\nCheck OPENWRT repo...\n" ; git status)
    echo -e "\n#####################################"
    (echo -e "\nCheck GLUTINIUM feed...\n" ; cd feeds/glutinium ; git status)
    echo -e "\n#####################################"
    (echo -e "\nCheck OPENIPC feed...\n" ; cd feeds/openipc ; git status)
    echo -e "\n#####################################"
    #(echo -e "\nCheck ZFTLAB feed...\n" ; cd feeds/zftlab ; git status)
    #echo -e "\n#####################################"
    ;;

esac



#    sed -i 's/CONFIG_HIETH_MII_RMII_MODE_U:=.*/CONFIG_HIETH_MII_RMII_MODE_U:=1/' target/linux/hi35xx/config-3.0.8.phy-xm      # Set CONFIG_HIETH_MII_RMII_MODE_U=1   - XM+BLUE vendor
#    sed -i 's/CONFIG_HIETH_MII_RMII_MODE_D:=.*/CONFIG_HIETH_MII_RMII_MODE_D:=1/' target/linux/hi35xx/config-3.0.8.phy-xm      # Set CONFIG_HIETH_MII_RMII_MODE_D=1   - XM+BLUE vendor
#
#    sed -i 's/CONFIG_HIETH_PHYID_U:=.*/CONFIG_HIETH_PHYID_U:=1/' target/linux/hi35xx/config-3.0.8.phy-xm                      # Set CONFIG_HIETH_PHYID_U=1           - XM model
#    sed -i 's/CONFIG_HIETH_PHYID_D:=.*/CONFIG_HIETH_PHYID_D:=2/' target/linux/hi35xx/config-3.0.8.phy-xm                      # Set CONFIG_HIETH_PHYID_D=2           - XM model
#
#    sed -i 's/CONFIG_HIETH_PHYID_U:=.*/CONFIG_HIETH_PHYID_U:=0/' target/linux/hi35xx/config-3.0.8.phy-xm                      # Set CONFIG_HIETH_PHYID_U=0           - BLUE vendor
#    sed -i 's/CONFIG_HIETH_PHYID_D:=.*/CONFIG_HIETH_PHYID_D:=1/' target/linux/hi35xx/config-3.0.8.phy-xm                      # Set CONFIG_HIETH_PHYID_D=1           - BLUE vendor


#    sed -i 's/CONFIG_HIETH_MII_RMII_MODE_U:=.*/CONFIG_HIETH_MII_RMII_MODE_U:=1/' target/linux/hi35xx/config-3.4.35.phy-xm     # Set CONFIG_HIETH_MII_RMII_MODE_U=1   - XM+BLUE vendor
#    sed -i 's/CONFIG_HIETH_MII_RMII_MODE_D:=.*/CONFIG_HIETH_MII_RMII_MODE_D:=1/' target/linux/hi35xx/config-3.4.35.phy-xm     # Set CONFIG_HIETH_MII_RMII_MODE_D=1   - XM+BLUE vendor
#
#    sed -i 's/CONFIG_HIETH_PHYID_U:=.*/CONFIG_HIETH_PHYID_U:=0/' target/linux/hi35xx/config-3.4.35.phy-xm                     # Set CONFIG_HIETH_PHYID_U=1           - XM vendor
#    sed -i 's/CONFIG_HIETH_PHYID_D:=.*/CONFIG_HIETH_PHYID_D:=1/' target/linux/hi35xx/config-3.4.35.phy-xm                     # Set CONFIG_HIETH_PHYID_D=3           - XM vendor
#
#    sed -i 's/CONFIG_HIETH_PHYID_U:=.*/CONFIG_HIETH_PHYID_U:=0/' target/linux/hi35xx/config-3.4.35.phy-xm                     # Set CONFIG_HIETH_PHYID_U=0           - BLUE vendor
#    sed -i 's/CONFIG_HIETH_PHYID_D:=.*/CONFIG_HIETH_PHYID_D:=1/' target/linux/hi35xx/config-3.4.35.phy-xm                     # Set CONFIG_HIETH_PHYID_D=1           - BLUE vendor

