#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
	#修改WIFI地区
	sed -i "s/country='.*'/country='CN'/g" $WIFI_UC
	#修改WIFI加密
	sed -i "s/encryption='.*'/encryption='psk2+ccmp'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#取消nss相关feed
	echo "CONFIG_FEED_nss_packages=n" >> ./.config
	echo "CONFIG_FEED_sqm_scripts_nss=n" >> ./.config
	#设置NSS版本
	echo "CONFIG_NSS_FIRMWARE_VERSION_11_4=n" >> ./.config
	if [[ "${WRT_CONFIG,,}" == *"ipq50"* ]]; then
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_2=y" >> ./.config
	else
		echo "CONFIG_NSS_FIRMWARE_VERSION_12_5=y" >> ./.config
	fi
	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
	#其他调整
	echo "CONFIG_PACKAGE_kmod-usb-serial-qualcomm=y" >> ./.config
fi



# 锁定分区大小
sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=100/g' .config
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=1024/g' .config
# 补齐 Python3 核心运行环境 (彻底消除依赖警告)
# ---------------------------------------------------------
# 最小 Python 环境（解决依赖警告）
echo "CONFIG_PACKAGE_python3-light=y" >> .config
echo "CONFIG_PACKAGE_python3-pkg-resources=y" >> .config
# 不要加 python3、python3-codecs、python3-logging、python3-openssl 等

echo "CONFIG_PACKAGE_luci-app-oaf=y" >> .config
echo "CONFIG_PACKAGE_open-app-filter=y" >> .config
echo "CONFIG_PACKAGE_oaf=y" >> .config


# ---------精简编译 节约时间 精简无用驱动或插件------------------------------------------------
# 1. 彻底禁用 USB 手机网络共享与苹果设备支持 (iPhone/Android Tethering)
# ---------------------------------------------------------
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-ipheth\.y/# CONFIG_PACKAGE_kmod-usb-net-ipheth is not set/g' .config
sed -i 's/CONFIG_PACKAGE_libimobiledevice\.y/# CONFIG_PACKAGE_libimobiledevice is not set/g' .config
sed -i 's/CONFIG_PACKAGE_usbmuxd\.y/# CONFIG_PACKAGE_usbmuxd is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-rndis\.y/# CONFIG_PACKAGE_kmod-usb-net-rndis is not set/g' .config
# ---------------------------------------------------------
# 2. 彻底禁用外置 USB 有线网卡驱动 (ASIX/Realtek/CDC)
# ---------------------------------------------------------
sed -i 's/CONFIG_PACKAGE_kmod-usb-net\.y/# CONFIG_PACKAGE_kmod-usb-net is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-asix\.y/# CONFIG_PACKAGE_kmod-usb-net-asix is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-asix-ax88179\.y/# CONFIG_PACKAGE_kmod-usb-net-asix-ax88179 is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-cdc-eem\.y/# CONFIG_PACKAGE_kmod-usb-net-cdc-eem is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-cdc-ether\.y/# CONFIG_PACKAGE_kmod-usb-net-cdc-ether is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-cdc-ncm\.y/# CONFIG_PACKAGE_kmod-usb-net-cdc-ncm is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-cdc-subset\.y/# CONFIG_PACKAGE_kmod-usb-net-cdc-subset is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-rtl8150\.y/# CONFIG_PACKAGE_kmod-usb-net-rtl8150 is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-rtl8152\.y/# CONFIG_PACKAGE_kmod-usb-net-rtl8152 is not set/g' .config
# ---------------------------------------------------------
# 3. 彻底禁用 4G/5G 模块与 WWAN 拨号驱动 (QMI/MBIM/Huawei)
# ---------------------------------------------------------
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-cdc-mbim\.y/# CONFIG_PACKAGE_kmod-usb-net-cdc-mbim is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm\.y/# CONFIG_PACKAGE_kmod-usb-net-huawei-cdc-ncm is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-qmi-wwan\.y/# CONFIG_PACKAGE_kmod-usb-net-qmi-wwan is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-fibocom\.y/# CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-fibocom is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-quectel\.y/# CONFIG_PACKAGE_kmod-usb-net-qmi-wwan-quectel is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-usb-net-sierrawireless\.y/# CONFIG_PACKAGE_kmod-usb-net-sierrawireless is not set/g' .config
# ---------------------------------------------------------
# 4. 彻底禁用 USB 音频支持 (USB Audio/Sound Core)
# ---------------------------------------------------------
sed -i 's/CONFIG_PACKAGE_kmod-usb-audio\.y/# CONFIG_PACKAGE_kmod-usb-audio is not set/g' .config
sed -i 's/CONFIG_PACKAGE_kmod-sound-core\.y/# CONFIG_PACKAGE_kmod-sound-core is not set/g' .config




# ============================================================
# 1. 强制使用 firewall4 (nftables) 并禁用冲突的 legacy 包
# ============================================================
sed -i '/CONFIG_PACKAGE_iptables-zz-legacy=y/d' .config
sed -i '/CONFIG_PACKAGE_firewall3=y/d' .config
sed -i '/CONFIG_PACKAGE_firewall=y/d' .config
echo "# CONFIG_PACKAGE_iptables-zz-legacy is not set" >> .config
echo "# CONFIG_PACKAGE_firewall3 is not set" >> .config
echo "# CONFIG_PACKAGE_firewall is not set" >> .config
echo "CONFIG_PACKAGE_firewall4=y" >> .config
echo "CONFIG_PACKAGE_iptables-nft=y" >> .config

# 重新运行 defconfig 使配置生效（同时会解析依赖）
make defconfig

# ============================================================
# 2. 冲突回滚检查 + 依赖分析（测试模式下自动定位肇事包）
# ============================================================
echo ""
echo "正在检查依赖冲突回滚..."

FORBIDDEN_PACKAGES="iptables-zz-legacy firewall3 firewall"
CONFLICT=0

for pkg in $FORBIDDEN_PACKAGES; do
    if grep -q "^CONFIG_PACKAGE_${pkg}=y" .config; then
        echo "::error::检测到冲突！包 ${pkg} 被依赖强制重新启用。"
        CONFLICT=1
        
        # 如果是测试模式，自动分析依赖来源
        if [[ "$WRT_TEST" == "true" ]]; then
            echo "正在分析依赖来源（测试模式），请稍候..."
            echo "----------------------------------------"
            # 使用 make -n 模拟编译，抓取依赖关系（不会实际编译）
            make -j1 -n V=s package/${pkg}/compile 2>&1 | grep -E "Selected by|needs to be built" | head -20 || true
            echo "----------------------------------------"
            echo "上述输出中的 'Selected by' 或 'needs to be built' 即为强制依赖 ${pkg} 的包。"
            echo "您可以根据这些信息，在 'make menuconfig' 中禁用对应的上游包。"
        fi
    fi
done

if [ $CONFLICT -eq 1 ]; then
    echo ""
    echo "::error::由于依赖冲突，编译无法继续。请根据上述分析结果调整您的软件包选择。"
    exit 1
else
    echo "✓ 依赖回滚检查通过，未发现强制禁用包被重新启用。"
fi

echo ""
echo "配置已锁定，开始后续编译..."





# 最后清理配置，确保生效
sed -i 's/\r$//' .config
