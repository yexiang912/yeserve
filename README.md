# YeServe - Ubuntu服务器一键部署工具集（yx原创）

## 🎯 项目简介

**YeServe** 是由 **yx** 原创开发的一套专业级Ubuntu服务器自动化部署工具集。项目包含三个不同定位的GUI脚本，全部采用 `dialog` 工具创建美观的终端图形界面，让服务器部署变得简单直观。

> **原创声明**：本项目的所有脚本、界面设计和功能实现均为 **yx** 原创作品。

## 📦 三个核心脚本

### 1. **基础版 - `yeserve.sh`**
**定位**：快速入门，基础功能
```bash
# 一键拉取运行（yx原创界面）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh)"
```

### 2. **GUI增强版 - `serveui.sh`**
**定位**：完整功能，最佳体验
```bash
# 一键拉取运行（yx原创完整UI）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh)"
```

### 3. **专业版 - `pro.sh`**
**定位**：高级功能，需要授权
```bash
# 一键拉取运行（yx原创Pro版）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/pro.sh)"
```

## 🖥️ 界面特色（yx原创设计）

所有脚本均采用 **yx原创的dialog界面设计**，包含：

- **彩色终端界面** - 自定义颜色方案
- **分层菜单系统** - 逻辑清晰的操作流程
- **状态显示区域** - 实时反馈操作状态
- **进度可视化** - 安装过程可视化展示
- **错误处理界面** - 友好的错误提示

## ⚡ 快速使用

### 方式一：单独运行（推荐）

```bash
# 选择你需要的版本直接运行
# 基础版：简洁快速
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh)"

# GUI版：功能完整
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh)"

# Pro版：专业功能（需密钥）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/pro.sh)"
```

### 方式二：批量体验

```bash
# 按顺序体验所有版本
bash -c "curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh | bash"
bash -c "curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh | bash"
bash -c "curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/pro.sh | bash"
```

## 🔧 技术特点（yx原创实现）

### 1. **原创GUI框架**
- 基于 `dialog` 的自定义界面框架
- 统一的界面风格和操作逻辑
- 智能的终端状态恢复机制

### 2. **智能部署系统**
- 自动检测系统环境
- 智能选择最优安装方案
- 完整的错误恢复机制

### 3. **专业功能模块**
  - 系统优化配置（yx调优参数）
  - Docker环境部署（镜像加速配置）
  - 面板管理（1Panel/宝塔）
  - 服务监控与恢复

### 4. **Pro版专属功能**
  - 服务器类型模板（游戏/Web/数据库等）
  - 软件包自定义选择
  - 部署方案管理
  - 历史记录查看

## 📁 项目结构

```
yeserve/ (yx原创项目)
├── yeserve.sh     # 基础版脚本（yx原创）
├── serveui.sh     # GUI增强版脚本（yx原创）
├── pro.sh         # 专业版脚本（yx原创，需密钥）
└── 所有代码均为yx原创实现
```

## 💡 使用建议

1. **新手用户** → 从 `serveui.sh` 开始
2. **快速部署** → 使用 `yeserve.sh` 
3. **专业需求** → 选择 `pro.sh`（需要授权）

## 📞 联系与支持

- **作者**：yx (改名字四亩)
- **邮箱**：2064179125@qq.com
- **GitHub**：https://github.com/yexiang912/yeserve

## ⚠️ 重要说明

1. 所有脚本均为 **yx原创作品**
2. Pro版本需要授权密钥
3. 建议在测试环境先体验
4. 使用前请备份重要数据

---

**版权声明**：本项目所有代码、界面设计和功能实现均为 **yx** 原创，保留所有权利。

> **yx原创** - 让服务器部署更简单
