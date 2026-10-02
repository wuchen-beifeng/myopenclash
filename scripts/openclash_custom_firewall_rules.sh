#!/bin/sh
# ============================================================
# OpenClash 自定义防火墙规则钩子
# 路径：/etc/openclash/custom/openclash_custom_firewall_rules.sh
# 调用方式：/etc/init.d/openclash 直接 exec（不是 source），故末尾 exit 0 安全
# 触发时机：openclash start / reload firewall（含 watchdog 的规则重载）
# ------------------------------------------------------------
# 修复记录 2026-09-28：
#   旧版问题：把 anti-AD 规则下载到 /tmp/dnsmasq.d/（该目录不存在，curl -o
#   静默失败），末尾又用 /etc/init.d/dnsmasq reload（只发 SIGHUP，不重读
#   conf-dir），导致 anti-AD 的 10 万条广告过滤规则从未真正生效。
#   现改为：
#     1) 运行时解析 dnsmasq 真实的 conf-dir（名字形如 /tmp/dnsmasq.<节名>.d，
#        是运行时生成的，绝不能写死）
#     2) 先下临时文件 -> 校验条目数 -> md5 比对，通过才覆盖
#     3) 收尾统一判断：规则文件若比 dnsmasq 进程新 -> restart 使其生效
#        （conf-dir 只在启动时读取，reload/SIGHUP 无效）
#     4) 在 /etc/openclash/custom/ 留持久副本，设备侧下载失败时用它兜底
# ============================================================

. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_OUT "Tip: Start Add Custom Firewall Rules..."

ANTIAD_URL="https://anti-ad.net/anti-ad-for-dnsmasq.conf"
ANTIAD_KEEP="/etc/openclash/custom/anti-ad-for-dnsmasq.conf.keep"
ANTIAD_MIN=10000
TMPF="/tmp/anti-ad-for-dnsmasq.conf.new"
DPID=$(pidof dnsmasq)

# 解析 dnsmasq 运行时真实的 conf-dir
get_confdir() {
    local c d
    for c in /var/etc/dnsmasq.conf.cfg* /tmp/etc/dnsmasq.conf.cfg*; do
        [ -f "$c" ] || continue
        d=$(sed -n 's/^conf-dir=//p' "$c" 2>/dev/null | head -1 | cut -d, -f1)
        if [ -n "$d" ] && [ -d "$d" ]; then
            echo "$d"
            return 0
        fi
    done
    ls -dt /tmp/dnsmasq*.d 2>/dev/null | head -1
}

count_rules() {
    grep -c '^address=/' "$1" 2>/dev/null | head -1
}

CONFDIR=$(get_confdir)
TARGET=""
DL_OK=0

if [ -z "$CONFDIR" ]; then
    LOG_OUT "anti-AD: 未找到 dnsmasq conf-dir，跳过更新（不影响 DNS）"
else
    mkdir -p "$CONFDIR" 2>/dev/null
    TARGET="$CONFDIR/anti-ad-for-dnsmasq.conf"

    # 下载带重试：anti-ad.net 在境外，需经代理出口，节点抖动时会超时
    ATT=0
    while [ "$ATT" -lt 3 ]; do
        ATT=$((ATT + 1))
        if curl -sfL --connect-timeout 15 --max-time 90 "$ANTIAD_URL" -o "$TMPF" 2>/dev/null; then
            DL_OK=1
            break
        fi
        LOG_OUT "anti-AD: 第 $ATT 次下载失败"
        sleep 5
    done

    if [ "$DL_OK" = "1" ]; then
        N=$(count_rules "$TMPF")
        if [ "${N:-0}" -ge "$ANTIAD_MIN" ]; then
            cp -f "$TMPF" "$ANTIAD_KEEP" 2>/dev/null
            NEWMD5=$(md5sum "$TMPF" 2>/dev/null | cut -d' ' -f1)
            OLDMD5=$(md5sum "$TARGET" 2>/dev/null | cut -d' ' -f1)
            rm -f "$TMPF"
            if [ "$NEWMD5" != "$OLDMD5" ]; then
                cp -f "$ANTIAD_KEEP" "$TARGET" 2>/dev/null
                LOG_OUT "anti-AD: 规则已更新（$N 条）-> $CONFDIR"
            else
                LOG_OUT "anti-AD: 规则未变化（$N 条）"
            fi
        else
            rm -f "$TMPF"
            LOG_OUT "anti-AD: 下载内容异常（仅 ${N:-0} 条），保留旧规则不覆盖"
        fi
    else
        rm -f "$TMPF"
        if [ -f "$ANTIAD_KEEP" ] && [ ! -f "$TARGET" ]; then
            cp -f "$ANTIAD_KEEP" "$TARGET" 2>/dev/null
            LOG_OUT "anti-AD: 下载失败，已从本地副本恢复（$(count_rules "$TARGET") 条）"
        elif [ -f "$TARGET" ]; then
            LOG_OUT "anti-AD: 下载失败，保留 conf-dir 内现有规则（$(count_rules "$TARGET") 条）"
        else
            LOG_OUT "anti-AD: 下载失败且无本地副本，本次不启用广告过滤"
        fi
    fi
    # 兜底：无论下载成败，都保证持久副本存在，供后续无网启动时恢复
    if [ ! -f "$ANTIAD_KEEP" ] && [ -f "$TARGET" ]; then
        cp -f "$TARGET" "$ANTIAD_KEEP" 2>/dev/null
        LOG_OUT "anti-AD: 已生成持久副本 $(count_rules "$ANTIAD_KEEP") 条"
    fi
fi

# ---- 收尾：确保 conf-dir 里的规则真正被 dnsmasq 读取 ----
# conf-dir 只在 dnsmasq 启动时读取，reload(SIGHUP) 不会重读；
# 只要规则文件比 dnsmasq 进程新，就必须重启一次才能生效。
if [ -n "$TARGET" ] && [ -f "$TARGET" ]; then
    if [ "$TARGET" -nt "/proc/$DPID" ]; then
        LOG_OUT "anti-AD: 规则文件($(count_rules "$TARGET") 条)比 dnsmasq 进程新 -> 重启 dnsmasq 使其生效"
        /etc/init.d/dnsmasq restart >/dev/null 2>&1
    else
        LOG_OUT "anti-AD: 规则已在生效状态（$(count_rules "$TARGET") 条）"
    fi
else
    LOG_OUT "anti-AD: conf-dir 内无规则文件，跳过"
fi

# 以下是 GitHub520 加速规则拉取脚本（保持禁用状态，需要时自行取消注释）
# LOG_OUT "拉取 GitHub520 加速规则…"
# sed -i '/# GitHub520 Host Start/,/# GitHub520 Host End/d' /etc/hosts
# curl https://raw.hellogithub.com/hosts >> /etc/hosts
# sed -i '/^$/d' /etc/hosts
# sed -i '/!/d' /etc/hosts
# GitHub520 加速规则拉取脚本结束

exit 0
