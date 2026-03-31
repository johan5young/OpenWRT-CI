以这个为准只编译nn6000 v2 带wifi版本，优化编译流程。
1、在原作者的基础上增加了几个编译前预检测（需选仅输出配置文件……）。
2、强制保活passwall2和oaf应用控制软件。
3、自动跳过机制，不重要的报错不卡死，直接下一个软件包，保证尽可能地出固件。


主要改动说明：
1、测试模式单包APK下载：新增 Upload Test Artifacts 步骤，当 WRT_TEST=true 时自动上传编译好的 .ipk/.apk 文件到 Artifacts，可在 Actions 页面下载
2、报错不停止：在 Update Feeds、Download Packages、Pre-check APK Version Format、Compile Firmware 等关键步骤添加 continue-on-error: ${{env.WRT_TEST == 'true'}}，测试模式下即使出错也继续执行
3、醒目报错：使用 echo "::error::" 标记错误，在 GitHub Actions 界面会显示为红色醒目标记，但不会终止工作流
4、汇总报告：新增 Summary Report 步骤，测试模式最后汇总所有环节的问题，列出成功/失败的包和可供下载的文件列表


# OpenWRT-CI

官方版：

https://github.com/immortalwrt/immortalwrt.git

高通版：

https://github.com/VIKINGYFY/immortalwrt.git

# U-BOOT

高通版：

https://github.com/chenxin527/uboot-ipq60xx-emmc-build

https://github.com/chenxin527/uboot-ipq60xx-nand-build

https://github.com/chenxin527/uboot-ipq60xx-nor-build

联发科版：

https://drive.wrt.moe/uboot/mediatek

# 固件简要说明

固件每天早上4点自动编译。

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

MEDIATEK系列、QUALCOMMAX系列、ROCKCHIP系列、X86系列。

# 目录简要说明

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置

#
[![Stargazers over time](https://starchart.cc/VIKINGYFY/OpenWRT-CI.svg?variant=adaptive)](https://starchart.cc/VIKINGYFY/OpenWRT-CI)
