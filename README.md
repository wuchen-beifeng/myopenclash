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
│   ├── openclash-uci.conf     # /etc/config/openclash 的 UCI 完整配置（已脱敏）
│   ├── clash-all-noicon.yaml  # OpenClash 主配置文件（已脱敏、链接已重定向）
│   ├── clash-all-noicon.runtime.yaml  # 路由器运行时版本（同上）
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
│   ├── zashboard-20250417.json             # Zashboard 面板配置
│   └── ange-clashboard-settings.json       # 另一份面板配置
└── sources/
    ├── little/    # 源项目 https://github.com/liandu2024/little 完整快照
    ├── clash/     # 源项目 https://github.com/liandu2024/clash 完整快照
    └── REPO_SOURCE.md  # 各来源仓库的出处说明
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

### 从路由器上传

```sh
# 在路由器上执行
cd /root/myopenclash
cp /etc/config/openclash config/openclash-uci.conf
cp /etc/openclash/config/clash-all-noicon.yaml config/
cp /etc/openclash/custom/* rules/
cp /etc/openclash/custom/*.sh scripts/
git add -A && git commit -m "sync openclash config"
git push
```

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