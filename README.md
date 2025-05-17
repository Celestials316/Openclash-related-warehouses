# OpenClash 配置仓库

这里是我自用的 OpenClash 配置文件仓库，用于集中管理 Clash 配置、规则和订阅，方便日常使用和备份。

## 仓库结构一览

. ├── clash/                # 主配置目录 │   ├── config.yaml       # Clash 主配置文件 │   ├── Country.mmdb      # 地理 IP 数据库（可选） │   └── profiles/         # 节点订阅文件夹 ├── rules/                # 分流规则目录 │   ├── custom-rules.yaml # 自定义规则 │   └── providers/        # 第三方规则源（如 ACL4SSR） ├── scripts/              # 实用脚本（如订阅更新） │   └── update.sh └── README.md             # 当前文件