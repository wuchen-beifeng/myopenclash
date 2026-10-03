# myopenclash

OpenClash 配置同步与管理仓库。用于在路由器（Kwrt / OpenWrt）与本仓库之间同步
OpenClash 的完整配置：UCI 配置、主配置文件、自定义规则、覆写脚本、面板配置等。

> 本仓库是 **公开** 仓库。订阅链接、面板密码等敏感信息已脱敏处理，切勿将真实
> 订阅地址或密钥提交到此仓库。

## 目录结构

```
myopenclash/
├── README.md                  # 本文件
├── config/
│   ├── openclash-uci.conf     # /etc/config/openclash 的 UCI 完整配置（面板密码明文）
│   ├── clash-all-noicon.yaml  # OpenClash 主配置文件（订阅链接已脱敏）
│   ├── clash-all-noicon.runtime.yaml  # 路由器运行时版本（订阅链接已脱敏）
│   └── default-demo.yaml      # OpenClash 默认配置模板
├── rules/
│   ├── openclash_custom_rules.list        # 自定义规则（规则设置 → 自定义规则）
│   ├── openclash_custom_rules_2.list      # 自定义规则 2
│   ├── openclash_custom_hosts.list        # 自定义 Hosts
│   ├── openclash_custom_fake_filter.list   # Fake-IP 过滤规则
│   ├── openclash_custom_fallback_filter.yaml  # Fallback-Filter
│   ├── openclash_custom_sniffer.yaml       # Sniffer 配置
│   ├── openclash_custom_domain_dns_policy.list     # 域名 DNS 策略
│   └── openclash_custom_proxy_server_dns_policy.list  # 代理服务器 DNS 策略
├── scripts/
│   ├── openclash_custom_firewall_rules.sh  # 自定义防火墙规则钩子
│   └── openclash_custom_overwrite.sh       # 自定义覆写脚本
├── dashboard/
│   ├── wuchen-dashboard-settings.json      # Zashboard 面板配置（v3.29 迁移版）
│   ├── zashboard-20250417.json             # Zashboard 面板历史配置
│   └── ange-clashboard-settings.json       # 另一份面板配置
```

## 同步方式

### 下载到路由器

```sh
# 1. 克隆仓库到路由器
git clone https://github.com/wuchen-beifeng/myopenclash /root/myopenclash

# 2. 覆盖配置
cp /root/myopenclash/config/clash-all-noicon.yaml /etc/openclash/config/
cp /root/myopenclash/config/openclash-uci.conf /etc/config/openclash
cp /root/myopenclash/rules/* /etc/openclash/custom/
cp /root/myopenclash/scripts/* /etc/openclash/custom/

# 3. 重启 OpenClash
/etc/init.d/openclash restart
```

> 上传到路由器前，请把 `external-ui-url` 与订阅链接恢复为你自己的真实地址。

## 从仓库同步到路由器

当仓库中已有最新配置，需要把变更推送到路由器时，按以下步骤执行。
推荐在路由器上直接拉取，避免中间拷贝导致格式或换行被破坏。

```sh
# 1. 确认执行权限
chmod +x scripts/openclash_custom_firewall_rules.sh
chmod +x scripts/openclash_custom_overwrite.sh

# 2. 在路由器上克隆仓库（若已克隆则改为 cd 并 git pull）
git clone https://github.com/wuchen-beifeng/myopenclash /root/myopenclash
cd /root/myopenclash

# 3. 执行前检查
git status
git diff --stat origin/main
# 确认 config/openclash-uci.conf 中的 dashboard_password 已恢复为你的真实面板密码
grep "dashboard_password" config/openclash-uci.conf
# 确认 config/clash-all-noicon.yaml 中的订阅链接已替换为真实地址
grep "REDACTED" config/*.yaml
# 确认脚本语法无误
bash -n scripts/openclash_custom_firewall_rules.sh
bash -n scripts/openclash_custom_overwrite.sh

# 4. 覆盖配置文件
cp config/openclash-uci.conf /etc/config/openclash
cp config/clash-all-noicon.yaml /etc/openclash/config/
cp config/clash-all-noicon.runtime.yaml /etc/openclash/
cp rules/* /etc/openclash/custom/
cp scripts/* /etc/openclash/custom/

# 5. 重新加载 OpenClash（不要直接 restart，先 reload）
uci commit openclash
/etc/init.d/openclash reload

# 6. 执行后检查
uci show openclash | grep -E "dashboard_password|config_path|default_dashboard"
ls -la /etc/openclash/config/clash-all-noicon.yaml
/etc/init.d/openclash status
logread | tail -20 | grep -i openclash
```

> **注意**
> - `config/openclash-uci.conf` 中的 `dashboard_password` 为**明文**，仅在局域网面板使用，同步时不要做脱敏处理。
> - `config/clash-all-noicon.yaml` 中的 `url` 字段在仓库里是 `<REDACTED_SUBSCRIBE_URL>`，推送到路由器前必须替换成你自己的真实订阅地址（含 token）。
> - 若只更新了部分文件，可跳过 `git pull`，直接把对应文件 `cp` 到路由器即可。

## 通过命令行更新 Zashboard 到路由器

Zashboard 面板通常放在 `/usr/share/openclash/ui/zashboard`。OpenClash 配置中
`external-ui-url` 指向源码仓库的 `gh-pages` 归档，更新可用命令行一步完成。

```sh
# 1. 执行前备份
cp -a /usr/share/openclash/ui/zashboard /usr/share/openclash/ui/zashboard.bak.$(date +%Y%m%d_%H%M%S)

# 2. 下载最新 Zashboard（gh-pages 归档，兼容国内代理）
cd /tmp
wget -O zashboard.zip https://gh-proxy.com/github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip
# 或直接用官方地址（若网络可行）
# wget -O zashboard.zip https://github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip

# 3. 解压并覆盖
rm -rf /usr/share/openclash/ui/zashboard
unzip -q zashboard.zip -d /tmp
# 归档内部目录名为 zashboard-gh-pages，调整为目标目录
mv /tmp/zashboard-gh-pages/* /usr/share/openclash/ui/zashboard/
# 若目录为空（某些发行版解压后为嵌套目录），使用：
# mkdir -p /usr/share/openclash/ui/zashboard
# cp -a /tmp/zashboard-gh-pages/* /usr/share/openclash/ui/zashboard/

# 4. 权限与清理
chown -R root:root /usr/share/openclash/ui/zashboard
chmod -R 755 /usr/share/openclash/ui/zashboard
rm -f /tmp/zashboard.zip
rm -rf /tmp/zashboard-gh-pages

# 5. 重新加载 OpenClash（不需要重启，ui 为静态文件）
/etc/init.d/openclash reload

# 6. 执行后检查
ls -la /usr/share/openclash/ui/zashboard/index.html
curl -s http://localhost:9090/ | head -n 1
logread | tail -20 | grep -i openclash
```

补充说明：
- 确认 UCI 中面板类型：`uci show openclash | grep default_dashboard`，应为 `zashboard`。
- 若路由器在 `external-ui-url` 中使用 `gh-proxy`，更新配置后 `external-ui-url` 保持为
  `https://gh-proxy.com/github.com/Zephyruso/zashboard/archive/refs/heads/gh-pages.zip`。
- 如需回滚：`rm -rf /usr/share/openclash/ui/zashboard && cp -a /usr/share/openclash/ui/zashboard.bak.* /usr/share/openclash/ui/zashboard && /etc/init.d/openclash reload`。

## 下载 Zashboard 配置到本地

仓库中 `dashboard/` 目录保存了面板的本地 JSON 配置，方便离线修改或多设备备份。可通过命令行一次性下载最新配置到本地工作目录：

```sh
# 1. 创建本地目录
mkdir -p ~/myopenclash-local/dashboard
cd ~/myopenclash-local

# 2. 下载 Zashboard 配置（v3.29 迁移版）
wget -O dashboard/wuchen-dashboard-settings.json \
  https://raw.githubusercontent.com/wuchen-beifeng/myopenclash/refs/heads/main/dashboard/wuchen-dashboard-settings.json

# 3. 同时下载历史配置备份
wget -O dashboard/zashboard-20250417.json \
  https://raw.githubusercontent.com/wuchen-beifeng/myopenclash/refs/heads/main/dashboard/zashboard-20250417.json

wget -O dashboard/ange-clashboard-settings.json \
  https://raw.githubusercontent.com/wuchen-beifeng/myopenclash/refs/heads/main/dashboard/ange-clashboard-settings.json

# 4. 校验文件完整性
ls -lh dashboard/
sha256sum dashboard/wuchen-dashboard-settings.json

# 5. 本地修改后可推回仓库（仅当你拥有写权限）
git init
git remote add origin https://github.com/wuchen-beifeng/myopenclash.git
git checkout -b local-edit
git add dashboard/wuchen-dashboard-settings.json
git commit -m "local: update zashboard settings"
git push -u origin local-edit
```

说明：
- `wuchen-dashboard-settings.json` 为当前使用的 Zashboard v3.29 配置，保持与路由器的面板设置一致。
- 下载时请使用 `raw.githubusercontent.com` 链接，避免通过 GitHub Web 页面下载到 HTML。
- 修改前建议先备份原文件，并使用 JSON 校验工具检查格式。

## 外部资源本地化

配置中引用的外部规则资源，凡是来自以下两个参考项目的，已下载并保存在
`sources/` 目录下，链接已重定向为指向本仓库的相对路径：

- https://github.com/liandu2024/little
- https://github.com/liandu2024/clash

原始链接格式：`https://raw.githubusercontent.com/liandu2024/clash/main/list/<name>`
重定向为：`https://raw.githubusercontent.com/wuchen-beifeng/myopenclash/main/sources/clash/list/<name>`

## 敏感信息处理

| 项目 | 处理方式 |
|---|---|
| 机场订阅链接（含 token） | 替换为 `<REDACTED_SUBSCRIBE_URL>` |
| 面板密码 `dashboard_password` | 替换为 `<REDACTED>` |
| 订阅链接 | 请自行在本地版本中维护，不要提交到公开仓库 |

## 依赖

- OpenClash >= 0.47.156（luci-app-openclash）
- Clash Meta（Mihomo）核心
- 路由器：Kwrt 25.12-SNAPSHOT / OpenWrt

## 校验

```sh
# YAML 语法
ruby -ryaml -e "YAML.load_file('config/clash-all-noicon.yaml'); puts 'OK'"

# 脚本语法
bash -n scripts/openclash_custom_firewall_rules.sh
bash -n scripts/openclash_custom_overwrite.sh
```