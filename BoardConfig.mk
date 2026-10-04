#
# BoardConfig.mk —— 华为畅享 8 (LDN-AL20) / 骁龙 430 (MSM8937) / arm64
#
# 平台参数全部取自原厂固件实测 (UPDATE_f8c83bfc):
#   ro.product.name        = msm8937_64
#   ro.build.flavor        = msm8937_64-user
#   ro.board.platform      = msm8937
#   ro.product.cpu.abi     = arm64-v8a,armeabi-v7a,armeabi
#   ro.build.version.sdk   = 26   (Android 8.0.0)
#   dalvik.vm.isa.arm64.variant = generic
#
LOCAL_PATH := device/huawei/ldn_al20

# ============ 架构 ============
# 对齐 ro.product.cpu.abilist = arm64-v8a,armeabi-v7a,armeabi
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
# 原厂 default.prop 报 generic, 但实际是 Cortex-A53 (MSM8937 = A53 x4)
TARGET_CPU_VARIANT := generic
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53

# 高通 RTC 需要额外初始化, 否则 recovery 里时间戳是 1970
TARGET_RECOVERY_QCOM_RTC_FIX := true
ENABLE_CPUSETS := true
ENABLE_SCHEDBOOST := true

# ============ 平台 ============
# msm8937 = 骁龙 430, GPU 为 Adreno 505
TARGET_BOARD_PLATFORM := msm8937
TARGET_BOARD_PLATFORM_GPU := qcom-adreno505
TARGET_BOARD_SUFFIX := _64

# ============ Bootloader ============
# ro.product.name / ro.build.flavor 均为 msm8937_64
TARGET_BOOTLOADER_BOARD_NAME := msm8937_64

# ============ Recovery 分区几何 ============
# 关键: LDN-AL20 是华为 eROS 三段式 recovery, 不是标准 A/B 或 A-only 单 boot 分区。
# 实测 GPT (gpt_main0.bin, 512B/扇区):
#   erecovery_kernel  LBA 524288   114688 扇区 = 58720256 字节 = 56.00 MB
#   recovery_ramdisk  LBA 884736    65536 扇区 = 33554432 字节 = 32.00 MB
#   recovery_vendor   LBA 950272    32768 扇区 = 16777216 字节 = 16.00 MB
#   kernel            LBA 737280   114688 扇区 = 58720256 字节 = 56.00 MB
#   ramdisk           LBA 851968    32768 扇区 = 16777216 字节 = 16.00 MB
#
# BOARD_RECOVERYIMAGE_PARTITION_SIZE 控制 boot.img 体积上限。
# TWRP 单 recovery.img = kernel(56MB 上限) + ramdisk + vendor。
# 这里给 ramdisk+vendor 留出余量, 内核段按 erecovery_kernel 的 56MB 封顶。
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 58720256
BOARD_FLASH_BLOCK_SIZE := 131072

# ============ 存储 ============
# LDN-AL20 无真实 SD 卡槽, /data 在 userdata (可能是 FBE/LBSE 加密)
BOARD_HAS_NO_REAL_SDCARD := true
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# ============ 华为 eROS 特有行为 ============
# Huawei bootloader 用 fastboot 协议但自定义 oem 握手
BOARD_SUPPRESS_SECURE_ERASE := true
BOARD_SUPPRESS_EMMC_WIPE := true
BOARD_RECOVERY_SWIPE := true
BOARD_USES_MMCUTILS := true

# ============ 内核 ============
# 使用本项目自建的 LDN-AL20 内核 (见 E:\111\ldn-al20)
# 内核为 Image.gz-dtb (dtb 已打包进 Image.gz), 分区名是 kernel 不是 boot
TARGET_KERNEL_SOURCE :=
TARGET_PREBUILT_KERNEL := device/huawei/ldn_al20/prebuilt/kernel
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_PAGESIZE := 2048

# 与原厂 kernel.mk 一致的华为/高通 cmdline 关键项
BOARD_KERNEL_CMDLINE := androidboot.hardware=qcom \
    androidboot.bootdevice=7824900.sdhci \
    androidboot.selinux=permissive \
    androidboot.hardware.wifi=0 \
    msm_rtb.filter=0x237 \
    ehci-hcd.park=3 \
    lpm_levels.sleep_disabled=1 \
    slub_min_objects=12 \
    unmovable_isolate1=2:192M,3:224M,4:256M \
    unmovable_isolate2=2:64M,3:80M,4:80M \
    buildvariant=userdebug

BOARD_MKBOOTIMG_ARGS := --ramdisk_offset 0x02000000 --tags_offset 0x00000100

# ============ TWRP 主题 ============
BOARD_USE_CUSTOM_RECOVERY_FONT := roboto_23x41.h
ifeq ($(TW_THEME),)
  TW_THEME := portrait_hdpi
endif
RECOVERY_SDCARD_ON_DATA := true
RECOVERY_GRAPHICS_USE_LINELENGTH := true

# ============ 文件系统插件 ============
TW_INCLUDE_FUSE_EXFAT := true
TW_INCLUDE_FUSE_NTFS := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_MTP := true
