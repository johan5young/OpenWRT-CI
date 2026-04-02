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
# 终极防冲突方案：精准物理切除 + 依赖重定向 + 递归隔离
# ============================================================
echo ""
echo "正在执行依赖清理与冲突包物理删除..."

# 1. 物理删除冲突包源码（使用 find 避免路径硬编码，确保源码彻底消失）
echo "1. 物理删除冲突包源码..."
BLACKLIST_PKGS=(
    "iptables-zz-legacy"
    "fail2ban"
    "onionshare-cli"
    "setools"
    "selinux-python"
    "luci-app-timewol"
)
for pkg in "${BLACKLIST_PKGS[@]}"; do
    find package/ feeds/ -type d -name "$pkg" -exec rm -rf {} \; 2>/dev/null
    echo "已切除源码目录: $pkg"
done

# 2. 定向依赖重定向（修正 Makefile 里的硬编码依赖）
echo "2. 执行定向依赖重定向..."
# 只替换特定的 legacy 报名，防止误伤 iptables-mod-* 链条
find package/ feeds/ -name "Makefile" -type f -exec sed -i 's/+iptables-zz-legacy/+iptables-nft/g' {} + 2>/dev/null
# 针对某些老旧插件直接依赖虚拟包 'iptables' 的情况，引导至 nft
find package/ feeds/ -name "Makefile" -type f -exec sed -i 's/+iptables$/+iptables-nft/g' {} + 2>/dev/null
echo "✓ 依赖定向重定向完成。"

# 3. 注入核心配置与屏蔽死循环包
echo "3. 强制锁定防火墙体系并隔离递归依赖源..."
# 物理抹除旧配置标记
sed -i '/CONFIG_PACKAGE_iptables-zz-legacy=y/d' .config
sed -i '/CONFIG_PACKAGE_firewall/d' .config

{
    echo "CONFIG_PACKAGE_firewall4=y"
    echo "CONFIG_PACKAGE_iptables-nft=y"
    echo "CONFIG_PACKAGE_ip6tables-nft=y"
    echo "CONFIG_PACKAGE_xtables-nft=y"
    echo "CONFIG_PACKAGE_ebtables-nft=y"
    echo "# CONFIG_PACKAGE_iptables-zz-legacy is not set"
    echo "# CONFIG_PACKAGE_firewall is not set"
    echo "# CONFIG_PACKAGE_firewall3 is not set"
    
    # --- 强力切断递归依赖死循环 (针对快照版 Bug) ---
    echo "# CONFIG_PACKAGE_openvswitch is not set"
    echo "# CONFIG_PACKAGE_openvswitch-ovn-host is not set"
    echo "# CONFIG_PACKAGE_ovsd is not set"
    echo "# CONFIG_PACKAGE_kmod-openvswitch-geneve is not set"
    echo "# CONFIG_PACKAGE_kmod-openvswitch-gre is not set"
    echo "# CONFIG_PACKAGE_kmod-openvswitch-vxlan is not set"
    echo "# CONFIG_PACKAGE_fwupd is not set"
    echo "# CONFIG_PACKAGE_fwupd-libs is not set"
} >> .config

# 4. 禁用已知会强行拉回 legacy 的不稳定插件
echo "4. 禁用可能引发冲突的高风险上游包..."
for pkg in mwan3 qos-scripts shorewall shorewall6 wifidog libreswan strongswan nodogsplash; do
    sed -i "/CONFIG_PACKAGE_${pkg}=y/d" .config
    echo "# CONFIG_PACKAGE_${pkg} is not set" >> .config
done

# 5. 首次解析依赖并二次清洗
echo "5. 运行解析与二次配置清洗..."
make defconfig
# 再次确保 legacy 没有因为依赖自动回滚被重新勾选
sed -i '/CONFIG_PACKAGE_iptables-zz-legacy=y/d' .config
echo "# CONFIG_PACKAGE_iptables-zz-legacy is not set" >> .config
make defconfig

# 6. 二次冲突扫描
echo ""
echo "6. 执行二次冲突扫描..."
if grep -q "^CONFIG_PACKAGE_iptables-zz-legacy=y" .config; then
    echo "::error::错误：iptables-zz-legacy 仍然被依赖强制启用！"
    if [[ "$WRT_TEST" == "true" ]]; then
        echo "----------------------------------------"
        echo "残留配置分析："
        grep -E "iptables-zz-legacy|kmod-ipt-" .config | grep "=y" || echo "（仅内核模块残留，通常安全）"
        echo "----------------------------------------"
    fi
    exit 1
else
    echo "✓ 二次扫描通过：防火墙冲突隐患已排除。"
fi

# 7. 摘要输出 (测试模式)
if [[ "$WRT_TEST" == "true" ]]; then
    mkdir -p ./test_output
    cp .config ./test_output/Config-Final.txt
    echo "========== 关键配置摘要 =========="
    grep -E "^CONFIG_PACKAGE_(firewall4|iptables-nft|iptables-zz-legacy)=" .config || true
    echo "================================="
fi

echo "配置已成功锁定，正在继续编译流程..."



# 最后清理配置，确保生效
sed -i 's/\r$//' .config
