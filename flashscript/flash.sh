#!/bin/bash

# ===============================
# 通用刷机脚本（带错误处理）
# 支持动态分区识别与错误跳过
# ===============================

SCRIPT_PATH=$(dirname "$0")
LOG_FILE="${SCRIPT_PATH}/flash_log_$(date +%Y%m%d_%H%M%S).txt"
declare -A PARTITION_MAP
declare -i ERROR_COUNT=0  # 错误计数器[5](@ref)

# 日志函数
function log {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 初始化日志
log "========== 刷机开始 =========="
log "日志文件: $LOG_FILE"

# --- 带错误处理的擦除操作 ---
log "执行预擦除操作..."
{
    fastboot erase boot_ab
    fastboot erase expdb
    fastboot erase metadata
    fastboot erase opconfig
    fastboot erase imagefv_ab
} 2>&1 | tee -a "$LOG_FILE" | while IFS= read -r line; do
    # 检测错误并跳过[5,6](@ref)
    if [[ "$line" == *"FAILED"* || "$line" == *"error"* ]]; then
        log "擦除失败: $line (已跳过)"
        ((ERROR_COUNT++))
    fi
done

# --- 动态分区刷写引擎（添加错误处理）---
function parse_comments {
    local in_comment_block=false
    
    while IFS= read -r line; do
        if [[ "$line" == "# --- 特殊镜像刷写"* ]]; then
            in_comment_block=true
            continue
        fi
        
        if [[ "$line" == "# --- 文档4特有分区"* ]]; then
            in_comment_block=false
            continue
        fi
        
        if $in_comment_block && [[ "$line" == "# fastboot flash "* ]]; then
            local partition=$(echo "$line" | awk '{print $3}')
            local img_path=$(echo "$line" | awk '{print $4}')
            PARTITION_MAP["$partition"]="$img_path"
        fi
    done < "$0"
}

parse_comments
log "扫描镜像目录: ${SCRIPT_PATH}/images/"

find "${SCRIPT_PATH}/images" -type f \( -name "*.img" -o -name "*.bin" -o -name "*.elf" -o -name "*.mbn" \) | while read -r img_path; do
    img_name=$(basename "$img_path")
    partition_name="${img_name%.*}"

    # 特殊处理preloader（添加错误跳过）
    if [[ "$img_name" =~ ^preloader_ ]]; then
        log "刷写 preloader: $img_name → $partition_name"
        if ! fastboot flash "$partition_name" "$img_path" 2>&1 | tee -a "$LOG_FILE"; then
            log "错误：$img_name 刷写失败，已跳过！[7](@ref)"
            ((ERROR_COUNT++))
        fi
        continue
    fi

    # 普通分区映射（支持_a/_b后缀自动匹配）
    if [[ -v "PARTITION_MAP[$partition_name]" ]]; then
        PARTITION_MAP["$partition_name"]="$img_path"
    else
        for existing_part in "${!PARTITION_MAP[@]}"; do
            if [[ "$existing_part" =~ ^${partition_name}_[ab]$ ]]; then
                PARTITION_MAP["$existing_part"]="$img_path"
            fi
        done
    fi
done

# --- 核心分区刷写（添加错误处理）---
log "开始刷写 ${#PARTITION_MAP[@]} 个分区..."
for partition in "${!PARTITION_MAP[@]}"; do
    img_path="${PARTITION_MAP[$partition]}"
    log "刷写分区: $partition ← $(basename "$img_path")"

    # 添加错误处理（分区不存在/签名错误/空间不足时跳过）[1,6](@ref)
    if ! fastboot flash "$partition" "$img_path" 2>&1 | tee -a "$LOG_FILE"; then
        log "错误：$partition 刷写失败！可能原因："
        log "  1. 分区不存在（尝试添加_a/_b后缀）[6](@ref)"
        log "  2. 镜像签名错误[3](@ref)"
        log "  3. 分区空间不足[6](@ref)"
        ((ERROR_COUNT++))
    fi
done

# --- OEM命令（错误仍执行但不中断）---
log "执行OEM命令..."
fastboot oem cdms 2>&1 | tee -a "$LOG_FILE"  # 忽略OEM错误[5](@ref)

# --- 最终操作 ---
log "设置活动槽位为 a..."
fastboot set_active a | tee -a "$LOG_FILE"

log "重启设备..."
fastboot reboot | tee -a "$LOG_FILE"

# 错误汇总提示
if ((ERROR_COUNT > 0)); then
    log "警告：共检测到 $ERROR_COUNT 个错误！请检查："
    log "  1. 分区名后缀（Android 11+需用_a/_b）[6](@ref)"
    log "  2. 镜像兼容性（使用设备对应版本）[2](@ref)"
    log "  3. Fastboot版本（旧版本需用 flash:raw）[7](@ref)"
else
    log "所有操作已完成"
fi
log "详细日志见: $LOG_FILE"
exit $ERROR_COUNT  # 返回错误数量为退出码

# ===== 以下注释用于分区名解析（严格保留原文）=====
# --- 特殊镜像刷写（不同设备独立处理）---
# 按文档顺序刷写两种设备preloader（后者会覆盖前者）
# fastboot flash preloader_a ${SCRIPT_PATH}/images/preloader_turner.bin
# fastboot flash preloader_b ${SCRIPT_PATH}/images/preloader_turner.bin
# fastboot flash preloader_a ${SCRIPT_PATH}/images/preloader_dali.bin
# fastboot flash preloader_b ${SCRIPT_PATH}/images/preloader_dali.bin

# --- 核心分区刷写（去重策略）---
# 原则：相同分区只保留最后出现的刷写命令
# fastboot flash vbmeta_ab        ${SCRIPT_PATH}/images/vbmeta.img
# fastboot flash vbmeta_system_ab ${SCRIPT_PATH}/images/vbmeta_system.img
# fastboot flash vbmeta_vendor_ab ${SCRIPT_PATH}/images/vbmeta_vendor.img
# fastboot flash spmfw_ab         ${SCRIPT_PATH}/images/spmfw.img
# fastboot flash audio_dsp_ab     ${SCRIPT_PATH}/images/audio_dsp.img
# fastboot flash pi_img_ab        ${SCRIPT_PATH}/images/pi_img.img
# fastboot flash dpm_ab           ${SCRIPT_PATH}/images/dpm.img
# fastboot flash scp_ab           ${SCRIPT_PATH}/images/scp.img
# fastboot flash ccu_ab           ${SCRIPT_PATH}/images/ccu.img
# fastboot flash vcp_ab           ${SCRIPT_PATH}/images/vcp.img
# fastboot flash sspm_ab          ${SCRIPT_PATH}/images/sspm.img
# fastboot flash mcupm_ab         ${SCRIPT_PATH}/images/mcupm.img
# fastboot flash gpueb_ab         ${SCRIPT_PATH}/images/gpueb.img
# fastboot flash apusys_ab        ${SCRIPT_PATH}/images/apusys.img
# fastboot flash mvpu_algo_ab     ${SCRIPT_PATH}/images/mvpu_algo.img
# fastboot flash gz_ab            ${SCRIPT_PATH}/images/gz.img
# fastboot flash lk_ab            ${SCRIPT_PATH}/images/lk.img
# fastboot flash vendor_boot_ab   ${SCRIPT_PATH}/images/vendor_boot.img
# fastboot flash dtbo_ab          ${SCRIPT_PATH}/images/dtbo.img
# fastboot flash tee_ab           ${SCRIPT_PATH}/images/tee.img
# fastboot flash connsys_gnss_ab  ${SCRIPT_PATH}/images/connsys_gnss.img
# fastboot flash rotfw_ab         ${SCRIPT_PATH}/images/rotfw.img
# fastboot flash logo_ab          ${SCRIPT_PATH}/images/logo.bin
# fastboot flash super            ${SCRIPT_PATH}/images/super.img
# fastboot flash countrycode_ab   ${SCRIPT_PATH}/images/countrycode.img
# fastboot flash userdata         ${SCRIPT_PATH}/images/userdata.img
# fastboot flash rescue           ${SCRIPT_PATH}/images/rescue.img
# fastboot flash misc             ${SCRIPT_PATH}/images/misc.img
# fastboot flash boot_ab          ${SCRIPT_PATH}/images/boot.img
# fastboot flash init_boot_ab     ${SCRIPT_PATH}/images/init_boot.img

# --- 文档2/4特有分区（去重后）---
# fastboot flash abl_ab           ${SCRIPT_PATH}/images/abl.elf
# fastboot flash xbl_ab           ${SCRIPT_PATH}/images/xbl_s.melf
# fastboot flash xbl_config_ab    ${SCRIPT_PATH}/images/xbl_config.elf
# fastboot flash shrm_ab          ${SCRIPT_PATH}/images/shrm.elf
# fastboot flash aop_ab           ${SCRIPT_PATH}/images/aop.mbn
# fastboot flash aop_config_ab    ${SCRIPT_PATH}/images/aop_devcfg.mbn
# fastboot flash tz_ab            ${SCRIPT_PATH}/images/tz.mbn
# fastboot flash devcfg_ab        ${SCRIPT_PATH}/images/devcfg.mbn
# fastboot flash featenabler_ab   ${SCRIPT_PATH}/images/featenabler.mbn
# fastboot flash hyp_ab           ${SCRIPT_PATH}/images/hypvmperformance.mbn
# fastboot flash uefi_ab          ${SCRIPT_PATH}/images/uefi.elf
# fastboot flash uefisecapp_ab    ${SCRIPT_PATH}/images/uefi_sec.mbn
# modem_ab 在文档3有更新版本，此处省略
# fastboot flash bluetooth_ab     ${SCRIPT_PATH}/images/BTFM.bin
# fastboot flash dsp_ab           ${SCRIPT_PATH}/images/dspso.bin
# fastboot flash keymaster_ab     ${SCRIPT_PATH}/images/keymint.mbn
# fastboot flash qupfw_ab         ${SCRIPT_PATH}/images/qupv3fw.elf
# fastboot flash multiimgoem_ab   ${SCRIPT_PATH}/images/multi_image.mbn
# fastboot flash multiimgqti_ab   ${SCRIPT_PATH}/images/multi_image_qti.mbn
# fastboot flash cpucp_ab         ${SCRIPT_PATH}/images/cpucp.elf
# fastboot flash logfs            ${SCRIPT_PATH}/images/logfs_ufs_8mb.bin
# fastboot flash storsec          ${SCRIPT_PATH}/images/storsec.mbn
# fastboot flash toolsfv          ${SCRIPT_PATH}/images/tools.fv
# fastboot flash xbl_ramdump_ab   ${SCRIPT_PATH}/images/XblRamdump.elf
# fastboot flash xbl_sc_test_mode ${SCRIPT_PATH}/images/xbl_sc_test_mode.bin
# imagefv_ab 在后续刷写，此处省略
# fastboot flash vm-bootsys_ab    ${SCRIPT_PATH}/images/vm-bootsys.img
# fastboot flash cust             ${SCRIPT_PATH}/images/cust.img
# fastboot flash recovery_ab      ${SCRIPT_PATH}/images/recovery.img

# --- 文档3特有分区（覆盖重复分区）---
# fastboot flash modem_ab         ${SCRIPT_PATH}/images/modem.img  # 覆盖文档2的modem_ab
# fastboot flash mcf_ota_ab       ${SCRIPT_PATH}/images/mcf_ota.img

# --- 文档4特有分区（覆盖/补充）---
# fastboot flash cpucp_dtb_ab     ${SCRIPT_PATH}/images/cpucp_dtbs.elf
# fastboot flash spuservice_ab    ${SCRIPT_PATH}/images/spu_service.mbn
# fastboot flash modemfirmware_ab ${SCRIPT_PATH}/images/MODEM-FW.bin
# fastboot flash soccp_debug_ab   ${SCRIPT_PATH}/images/sdi.mbn
# fastboot flash soccp_dcd_ab     ${SCRIPT_PATH}/images/dcd.mbn
# fastboot flash pvmfw_ab         ${SCRIPT_PATH}/images/pvmfw.img
# fastboot flash idmanager_ab     ${SCRIPT_PATH}/images/idmanager.mbn
# fastboot flash imagefv_ab       ${SCRIPT_PATH}/images/imagefv.elf  # 覆盖文档2的imagefv_ab
