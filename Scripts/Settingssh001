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

# =========================================================
# 脚本名称: Settings.sh    gemini成功后再次优化版
# 适用架构: NN6000 V2 (MediaTek MT7986)
# 核心功能: 解决递归依赖、切断旧版防火墙、优化编译环境
# =========================================================

echo "🚀 正在执行深度环境修补与配置优化..."

# 1. 物理移除冲突或冗余的软件包源码
# 这些包会导致 Recursive Dependency (循环依赖) 或在 aarch64 上编译报错
REMOVE_LIST=(
    "package/feeds/packages/fwupd"
    "package/feeds/packages/openvswitch"
    "package/feeds/packages/ovsd"
    "package/feeds/packages/ovn"
    "package/feeds/packages/fail2ban"
    "package/feeds/packages/onionshare-cli"
    "package/feeds/packages/setools"
    "package/feeds/base/iptables-zz-legacy" # 彻底移除原有的冲突包
)

for dir in "${REMOVE_LIST[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        echo "  - 已清理冲突路径: $dir"
    fi
done

# 2. 建立虚拟占位包 (iptables-zz-legacy)
# 目的：满足 Passwall 2 等插件对 'iptables-zz-legacy' 的命名依赖
# 方案：创建一个空包，只指向现代化的 nft 依赖，从而骗过编译器并切断循环依赖链
echo "  - 正在注入防火墙虚拟兼容层..."
STUB_DIR="package/feeds/base/iptables-zz-legacy"
mkdir -p "$STUB_DIR"

cat <<EOF > "$STUB_DIR/Makefile"
include \$(TOPDIR)/rules.mk

PKG_NAME:=iptables-zz-legacy
PKG_VERSION:=999
PKG_RELEASE:=1

include \$(INCLUDE_DIR)/package.mk

define Package/iptables-zz-legacy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Fake Compatibility Layer for Firewall4
  # 核心：将旧名映射到现代组件，不直接依赖 firewall4 从而打破递归
  DEPENDS:=+kmod-nft-core +iptables-nft +xtables-nft
endef

define Build/Compile
	# 虚拟包无需编译
endef

define Package/iptables-zz-legacy/install
	true
endef

\$(eval \$(call BuildPackage,iptables-zz-legacy))
EOF

# 3. 修正 .config 中的防火墙与内核配置
# 强制移除旧版防火墙标志，确保使用 Firewall4 (nftables) 体系
echo "  - 正在优化 .config 防火墙架构..."
sed -i '/CONFIG_PACKAGE_firewall/d' .config
sed -i '/CONFIG_PACKAGE_iptables/d' .config

{
    echo "CONFIG_PACKAGE_firewall4=y"
    echo "CONFIG_PACKAGE_iptables-nft=y"
    echo "CONFIG_PACKAGE_ip6tables-nft=y"
    echo "CONFIG_PACKAGE_xtables-nft=y"
    # 显式关闭旧版组件
    echo "# CONFIG_PACKAGE_firewall is not set" >> .config
    echo "# CONFIG_PACKAGE_firewall3 is not set" >> .config
} >> .config

# 4. 基础体验优化
# 默认修改登录地址（根据你的 WRT_IP 变量，或在此手动指定）
#
echo "  - 设置默认登录 IP..."
# 如果 yml 传入了 WRT_IP，则优先使用，否则默认 192.168.10.1
DEFAULT_IP=${WRT_IP:-"192.168.10.1"}
sed -i "s/192.168.1.1/$DEFAULT_IP/g" package/base-files/files/bin/config_generate

# 5. 性能与加速选项
# 开启 Ccache 支持（如果 yml 中配置了路径）
echo "CONFIG_CCACHE=y" >> .config

# 禁用 LLVM 构建（除非必须），这能显著缩短你的初次编译时间
# 只有当你确定需要 eBPF 监控等功能时才开启它
echo "# CONFIG_USE_LLVM is not set" >> .config

echo "✅ Settings.sh 执行完成，环境已就绪。"


# 最后清理配置，确保生效
sed -i 's/\r$//' .config
