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