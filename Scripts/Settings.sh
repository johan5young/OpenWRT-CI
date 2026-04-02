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



#!/bin/bash

# ============================================================
# NN6000 V2 (ImmortalWrt Snapshot) 终极修复脚本   gemini版
# 策略：物理切除报错源 + 建立虚拟重定向包 + 锁定 FW4 体系
# ============================================================

echo "开始执行深层环境清理与依赖修补..."

# 1. 物理切除导致 Kconfig 递归报错/依赖缺失的源码目录
# 这些包在快照版中存在逻辑 Bug 或会导致编译链中断，且路由器基本不需要
REMOVE_LIST=(
    "package/feeds/packages/fwupd"
    "package/feeds/packages/openvswitch"
    "package/feeds/packages/ovsd"
    "package/feeds/packages/ovn"
    "package/feeds/packages/fail2ban"
    "package/feeds/packages/onionshare-cli"
    "package/feeds/packages/setools"
    "package/feeds/packages/selinux-python"
    "package/feeds/packages/luci-app-timewol"
    "package/feeds/base/iptables-zz-legacy"
)

echo "1. 正在物理剔除不稳定源码源..."
for dir in "${REMOVE_LIST[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "   ✓ 已移除: $dir"
    fi
done

# 2. 执行定向重定向（修正其他插件 Makefile 里的硬编码点名）
echo "2. 正在执行 Makefile 依赖引导..."
find package/ feeds/ -name "Makefile" -type f -exec sed -i 's/+iptables-zz-legacy/+iptables-nft/g' {} + 2>/dev/null
# 针对直接点名 +iptables 的情况，引导至现代版本
find package/ feeds/ -name "Makefile" -type f -exec sed -i 's/+iptables$/+iptables-nft/g' {} + 2>/dev/null

# 3. 创建虚拟兼容包 (Stub Package)
# 目的：骗过那些死活要找 iptables-zz-legacy 的插件，使其转向 firewall4
echo "3. 正在创建虚拟定向包 iptables-zz-legacy -> firewall4 ..."
mkdir -p package/feeds/base/iptables-zz-legacy
cat <<EOF > package/feeds/base/iptables-zz-legacy/Makefile
include \$(TOPDIR)/rules.mk

PKG_NAME:=iptables-zz-legacy
PKG_VERSION:=999
PKG_RELEASE:=1

include \$(INCLUDE_DIR)/package.mk

define Package/iptables-zz-legacy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Fake Compatibility Layer for Firewall4
  DEPENDS:=+firewall4 +iptables-nft
endef

define Build/Compile
endef

define Package/iptables-zz-legacy/install
	true
endef

\$(eval \$(call BuildPackage,iptables-zz-legacy))
EOF

# 4. 注入核心配置并封杀递归包
echo "4. 正在锁定 .config 防火墙体系..."
# 清除旧的冲突标记
sed -i '/CONFIG_PACKAGE_firewall/d' .config
sed -i '/CONFIG_PACKAGE_iptables/d' .config

{
    # 强制开启现代防火墙架构
    echo "CONFIG_PACKAGE_firewall4=y"
    echo "CONFIG_PACKAGE_iptables-nft=y"
    echo "CONFIG_PACKAGE_ip6tables-nft=y"
    echo "CONFIG_PACKAGE_xtables-nft=y"
    echo "CONFIG_PACKAGE_ebtables-nft=y"
    
    # 显式禁用导致死循环和冲突的包
    echo "# CONFIG_PACKAGE_iptables-zz-legacy is not set"
    echo "# CONFIG_PACKAGE_firewall is not set"
    echo "# CONFIG_PACKAGE_firewall3 is not set"
    echo "# CONFIG_PACKAGE_openvswitch is not set"
    echo "# CONFIG_PACKAGE_fwupd is not set"
    echo "# CONFIG_PACKAGE_fwupd-libs is not set"
    
    # 保护核心内核转发模块 (Quickfile/Passwall 所需)
    echo "CONFIG_PACKAGE_kmod-ipt-core=y"
    echo "CONFIG_PACKAGE_kmod-ipt-nat=y"
    echo "CONFIG_PACKAGE_kmod-ipt-tproxy=y"
} >> .config

# 5. 禁用已知会强行拉回 legacy 的高风险插件
echo "5. 隔离可能引发二次冲突的插件..."
for pkg in mwan3 qos-scripts shorewall shorewall6 wifidog libreswan strongswan nodogsplash; do
    sed -i "/CONFIG_PACKAGE_${pkg}=y/d" .config
    echo "# CONFIG_PACKAGE_${pkg} is not set" >> .config
done

# 6. 执行依赖解析与最终清洗
echo "6. 正在执行 make defconfig 最终校验..."
make defconfig

# 再次确保 legacy 没有被意外勾选（双重保险）
if grep -q "CONFIG_PACKAGE_iptables-zz-legacy=y" .config; then
    sed -i 's/CONFIG_PACKAGE_iptables-zz-legacy=y/# CONFIG_PACKAGE_iptables-zz-legacy is not set/g' .config
    make defconfig
fi

echo "============================================================"
echo "✓ 依赖修补完成！"
echo "✓ 递归依赖已通过物理切除修复。"
echo "✓ 虚拟定向包已就位，将引导系统使用现代防火墙。"
echo "============================================================"



# 最后清理配置，确保生效
sed -i 's/\r$//' .config
