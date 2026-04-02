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
echo "CONFIG_PACKAGE_ip6tables-nft=y" >> .config
echo "CONFIG_PACKAGE_xtables-nft=y" >> .config
echo "CONFIG_PACKAGE_ebtables-nft=y" >> .config



# ============================================================
# 终极防冲突方案：依赖重定向 + 物理删除 + 二次扫描
# ============================================================
echo ""
echo "正在执行依赖重定向与冲突包物理删除..."

# 1. 将所有 Makefile 中对 iptables-zz-legacy 的依赖重定向到 iptables-nft
find package/ feeds/ -name "Makefile" -type f -exec sed -i 's/+iptables-zz-legacy/+iptables-nft/g' {} \; 2>/dev/null
# 同时处理可能直接依赖 iptables (虚拟包) 的情况，强制改为 iptables-nft
find package/ feeds/ -name "Makefile" -type f -exec sed -i 's/+iptables\b/+iptables-nft/g' {} \; 2>/dev/null
find package/ feeds/ -name "Makefile" -type f -exec sed -i 's/+ip6tables\b/+ip6tables-nft/g' {} \; 2>/dev/null
echo "✓ 依赖重定向完成（所有 +iptables 已指向 +iptables-nft）"

# 2. 定义并物理删除黑名单包（这些包会引入冲突或产生无用警告）
BLACKLIST=(
    "package/feeds/base/iptables-zz-legacy"
    "package/feeds/packages/fail2ban"
    "package/feeds/packages/onionshare-cli"
    "package/feeds/packages/setools"
    "package/feeds/packages/luci-app-timewol"
)
for target in "${BLACKLIST[@]}"; do
    if [ -d "$target" ]; then
        rm -rf "$target"
        echo "已删除: $target"
    fi
done

# 3. 强制锁定 firewall4 和 iptables-nft 配置（确保 .config 中正确设置）
sed -i '/CONFIG_PACKAGE_iptables-zz-legacy=y/d' .config
sed -i '/CONFIG_PACKAGE_firewall3=y/d' .config
sed -i '/CONFIG_PACKAGE_firewall=y/d' .config
echo "# CONFIG_PACKAGE_iptables-zz-legacy is not set" >> .config
echo "# CONFIG_PACKAGE_firewall3 is not set" >> .config
echo "# CONFIG_PACKAGE_firewall is not set" >> .config
echo "CONFIG_PACKAGE_firewall4=y" >> .config
echo "CONFIG_PACKAGE_iptables-nft=y" >> .config
echo "CONFIG_PACKAGE_ip6tables-nft=y" >> .config
echo "CONFIG_PACKAGE_xtables-nft=y" >> .config
echo "CONFIG_PACKAGE_ebtables-nft=y" >> .config
echo "✓ 已强制启用 firewall4 / iptables-nft 并禁用 legacy 包"

# 4. 运行 defconfig 让依赖解析生效
make defconfig

# 5. 二次冲突扫描：检查 iptables-zz-legacy 是否仍被意外启用
echo ""
echo "正在执行二次冲突扫描..."
if grep -q "^CONFIG_PACKAGE_iptables-zz-legacy=y" .config; then
    echo "::error::警告：iptables-zz-legacy 仍然被依赖强制启用！"
    echo "正在尝试定位肇事包（测试模式将输出详细依赖链）..."
    
    # 如果是测试模式，输出更详细的信息
    if [[ "$WRT_TEST" == "true" ]]; then
        echo "----------------------------------------"
        echo "方法1：通过 .config 反向查找可能的上游包"
        grep -E "^CONFIG_PACKAGE_(mwan3|olsrd|qos-scripts|bandwidthd|coova-chilli|pbr|kmod-ipt|iptables-mod)" .config
        echo ""
        echo "方法2：模拟编译 iptables-zz-legacy 查看依赖来源"
        make -j1 -n V=s package/iptables-zz-legacy/compile 2>&1 | grep -E "Selected by|needs to be built" | head -20 || true
        echo "----------------------------------------"
        echo "请根据上方输出手动禁用对应的上游包，或检查是否还有遗漏的 Makefile 未重定向。"
    fi
    echo "::error::由于冲突无法自动解决，编译将终止。"
    exit 1
else
    echo "✓ 二次扫描通过：iptables-zz-legacy 已被成功移除。"
fi

# ============================================================
# 6. 输出最终配置文件供下载（测试模式）
# ============================================================
if [[ "$WRT_TEST" == "true" ]]; then
    # 确保 test_output 目录存在（如果不存在则创建）
    mkdir -p ./test_output
    cp .config ./test_output/Config-Final.txt
    echo "✓ 最终配置文件已保存至 ./test_output/Config-Final.txt，可在 Actions 的 Artifacts 中下载检查。"
    
    # 可选：输出关键配置摘要到日志，方便快速查看
    echo ""
    echo "========== 关键配置摘要 =========="
    echo "firewall4: $(grep '^CONFIG_PACKAGE_firewall4=' .config)"
    echo "iptables-nft: $(grep '^CONFIG_PACKAGE_iptables-nft=' .config)"
    echo "iptables-zz-legacy: $(grep '^CONFIG_PACKAGE_iptables-zz-legacy=' .config)"
    echo "核心包状态:"
    for pkg in oaf open-app-filter luci-app-oaf luci-app-passwall2; do
        grep "^CONFIG_PACKAGE_${pkg}=" .config || echo "CONFIG_PACKAGE_${pkg} not set"
    done
    echo "================================="
fi

echo "配置已锁定，继续后续编译..."





# 最后清理配置，确保生效
sed -i 's/\r$//' .config
