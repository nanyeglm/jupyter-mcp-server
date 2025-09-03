# 🪐✨ Jupyter MCP Server 完整部署指南

## 📋 项目概述

Jupyter MCP Server 是一个基于 Model Context Protocol (MCP) 的服务器实现，使AI助手能够实时与Jupyter Notebook进行交互，包括编辑、文档化和执行代码等操作。

### 🎯 核心特性

- ⚡ **实时控制**: 即时查看notebook变化
- 🔁 **智能执行**: 根据输出反馈自动调整
- 🤝 **MCP兼容**: 支持Claude Desktop、VS Code、Cursor等客户端

## 🏗️ 个人环境配置

### 系统环境

- **操作系统**: Linux (Ubuntu 24.04.2)
- **Python环境**: `/home/cpu/miniforge3` (base环境)
- **包管理器**: conda + pip
- **容器化**: Docker

### 已安装组件

- **JupyterLab**: 4.4.6
- **jupyter-collaboration**: 4.0.2
- **ipykernel**: 6.30.1
- **datalayer_pycrdt**: 0.12.17

## 🚀 服务端部署

### 第一步：环境准备

#### 1. 激活conda环境

```bash
source /home/cpu/miniforge3/bin/activate
```

#### 2. 安装必要依赖

```bash
# 安装jupyter-collaboration
conda install jupyter-collaboration=4.0.2 -c conda-forge -y

# 卸载冲突包并安装datalayer_pycrdt
pip uninstall -y pycrdt datalayer_pycrdt
pip install datalayer_pycrdt==0.12.17
```

### 第二步：Jupyter服务配置

#### 1. 创建systemd服务文件

```bash
nano ~/.config/systemd/user/jupyter.service
```

#### 2. 服务配置内容

```ini
[Unit]
Description=Jupyter Notebook Server
After=network.target

[Service]
Type=simple
ExecStart=/home/cpu/miniforge3/bin/conda run -n base jupyter notebook --no-browser --ip=127.0.0.1 --port=8888 --NotebookApp.token=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359
WorkingDirectory=/home/cpu
Restart=always
Environment="JUPYTER_CONFIG_DIR=/home/cpu/.jupyter"
Environment="JUPYTER_RUNTIME_DIR=/home/cpu/.local/share/jupyter/runtime"

[Install]
WantedBy=default.target
```

#### 3. 启动Jupyter服务

```bash
# 重新加载systemd配置
systemctl --user daemon-reload

# 启用服务（开机自启）
systemctl --user enable jupyter

# 启动服务
systemctl --user start jupyter

# 检查服务状态
systemctl --user status jupyter
```

### 第三步：Docker部署MCP Server

#### 1. 拉取官方镜像

```bash
docker pull datalayer/jupyter-mcp-server:latest
```

#### 2. 创建测试notebook

在 `/home/cpu/notebook.ipynb` 创建测试文件。

#### 3. 启动MCP Server

**stdio模式（推荐用于客户端）**:

```bash
docker run -i --rm \
  -e DOCUMENT_URL=http://127.0.0.1:8888 \
  -e DOCUMENT_ID=notebook.ipynb \
  -e DOCUMENT_TOKEN=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359 \
  -e RUNTIME_URL=http://127.0.0.1:8888 \
  -e START_NEW_RUNTIME=true \
  -e RUNTIME_TOKEN=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359 \
  --network=host \
  datalayer/jupyter-mcp-server:latest
```

**HTTP模式（用于测试）**:

```bash
docker run -i --rm \
  -e DOCUMENT_URL=http://127.0.0.1:8888 \
  -e DOCUMENT_ID=notebook.ipynb \
  -e DOCUMENT_TOKEN=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359 \
  -e RUNTIME_URL=http://127.0.0.1:8888 \
  -e START_NEW_RUNTIME=true \
  -e RUNTIME_TOKEN=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359 \
  --network=host \
  -p 4040:4040 \
  datalayer/jupyter-mcp-server:latest \
  --transport streamable-http
```

### 第四步：验证部署

#### 1. 检查Jupyter服务

```bash
curl "http://127.0.0.1:8888/api?token=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359"
```

#### 2. 检查MCP Server（HTTP模式）

```bash
curl http://localhost:4040/api/healthz
```

## 🔧 客户端部署教程

### 1. Claude Desktop

#### 安装Claude Desktop

- **macOS/Windows**: 从[官方页面](https://claude.ai/download)下载
- **Linux**: 使用非官方构建

```bash
NIXPKGS_ALLOW_UNFREE=1 nix run github:k3d3/claude-desktop-linux-flake \
  --impure \
  --extra-experimental-features flakes \
  --extra-experimental-features nix-command
```

#### 配置Claude Desktop

编辑 `~/.config/claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "jupyter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "DOCUMENT_URL",
        "-e", "DOCUMENT_TOKEN",
        "-e", "DOCUMENT_ID",
        "-e", "RUNTIME_URL",
        "-e", "RUNTIME_TOKEN",
        "--network=host",
        "datalayer/jupyter-mcp-server:latest"
      ],
      "env": {
        "DOCUMENT_URL": "http://127.0.0.1:8888",
        "DOCUMENT_TOKEN": "ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359",
        "DOCUMENT_ID": "notebook.ipynb",
        "RUNTIME_URL": "http://127.0.0.1:8888",
        "RUNTIME_TOKEN": "ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359"
      }
    }
  }
}
```

### 2. VS Code

#### 安装要求

1. 安装[VS Code](https://code.visualstudio.com/Download)
2. 订阅[GitHub Copilot](https://github.com/features/copilot)
3. 安装[GitHub Copilot Chat扩展](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)

#### 配置VS Code

**方式1: 用户级配置**
编辑 `~/.vscode/settings.json`:

```json
{
  "mcp": {
    "servers": {
      "DatalayerJupyter": {
        "command": "docker",
        "args": [
          "run", "-i", "--rm",
          "-e", "DOCUMENT_URL",
          "-e", "DOCUMENT_TOKEN",
          "-e", "DOCUMENT_ID",
          "-e", "RUNTIME_URL",
          "-e", "RUNTIME_TOKEN",
          "--network=host",
          "datalayer/jupyter-mcp-server:latest"
        ],
        "env": {
          "DOCUMENT_URL": "http://127.0.0.1:8888",
          "DOCUMENT_TOKEN": "ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359",
          "DOCUMENT_ID": "notebook.ipynb",
          "RUNTIME_URL": "http://127.0.0.1:8888",
          "RUNTIME_TOKEN": "ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359"
        }
      }
    }
  }
}
```

**方式2: 工作区配置**
创建 `.vscode/mcp.json`:

```json
{
  "servers": {
    "DatalayerJupyter": {
      // 同上配置
    }
  }
}
```

#### 使用VS Code MCP

1. 启动Copilot Chat (`Ctrl+Alt+I` / `⌃⌘I`)
2. 切换到**Agent**模式
3. 点击**Tools** ⚙️ 图标管理工具
4. 使用`#toolName`调用工具或让Copilot自动调用

### 3. Cursor

#### 安装Cursor

从[Cursor官网](https://www.cursor.com/downloads)下载安装。

#### 配置Cursor

编辑 `~/.cursor/mcp.json`:

```json
{
  "servers": {
    "jupyter": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-e", "DOCUMENT_URL",
        "-e", "DOCUMENT_TOKEN",
        "-e", "DOCUMENT_ID",
        "-e", "RUNTIME_URL",
        "-e", "RUNTIME_TOKEN",
        "--network=host",
        "datalayer/jupyter-mcp-server:latest"
      ],
      "env": {
        "DOCUMENT_URL": "http://127.0.0.1:8888",
        "DOCUMENT_TOKEN": "ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359",
        "DOCUMENT_ID": "notebook.ipynb",
        "RUNTIME_URL": "http://127.0.0.1:8888",
        "RUNTIME_TOKEN": "ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359"
      }
    }
  }
}
```

### 4. 手动配置MCP客户端

对于支持手动添加MCP服务器的客户端：

#### 配置参数

- **Name**: `Jupyter MCP Server`
- **Command**: `docker run -i --rm -e DOCUMENT_URL -e DOCUMENT_TOKEN -e DOCUMENT_ID -e RUNTIME_URL -e RUNTIME_TOKEN --network=host datalayer/jupyter-mcp-server:latest`

#### 环境变量

| 变量名 | 值 |
|--------|-----|
| `DOCUMENT_URL` | `http://127.0.0.1:8888` |
| `DOCUMENT_TOKEN` | `ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359` |
| `DOCUMENT_ID` | `notebook.ipynb` |
| `RUNTIME_URL` | `http://127.0.0.1:8888` |
| `RUNTIME_TOKEN` | `ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359` |

## 🛠️ 可用工具

MCP Server提供12个主要工具：

### 单元格操作

- `append_markdown_cell` - 添加markdown单元格
- `insert_markdown_cell` - 插入markdown单元格
- `append_execute_code_cell` - 添加并执行代码单元格
- `insert_execute_code_cell` - 插入并执行代码单元格
- `overwrite_cell_source` - 覆写单元格源码
- `delete_cell` - 删除单元格

### 单元格执行

- `execute_cell_simple_timeout` - 简单超时执行
- `execute_cell_streaming` - 流式执行（长时间运行）
- `execute_cell_with_progress` - 带进度监控执行

### 信息获取

- `read_cell` - 读取指定单元格
- `read_all_cells` - 读取所有单元格
- `get_notebook_info` - 获取notebook基本信息

## 🔍 故障排除

### 常见问题及解决方案

#### 1. Jupyter服务问题

```bash
# 检查服务状态
systemctl --user status jupyter

# 重启服务
systemctl --user restart jupyter

# 查看日志
journalctl --user -u jupyter -f
```

#### 2. Docker权限问题

```bash
# 添加用户到docker组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker
```

#### 3. 网络连接问题

- 确保使用 `--network=host` 参数
- 检查防火墙设置
- 验证端口未被占用

#### 4. Token认证问题

- 确认token正确性
- 检查Jupyter配置
- 验证API访问权限

## 📝 最佳实践

### 安全建议

1. **生产环境**: 更换默认token
2. **网络安全**: 限制访问IP范围
3. **权限控制**: 使用最小权限原则

### 性能优化

1. **资源监控**: 定期检查内存和CPU使用
2. **日志管理**: 配置日志轮转
3. **自动重启**: 使用systemd确保服务可用性

### 维护建议

1. **定期更新**: 更新Docker镜像和依赖
2. **备份策略**: 备份重要notebook文件
3. **监控告警**: 设置服务状态监控

## 🛠️ 快速启动工具

为了方便使用，我还为你创建了一个启动脚本 `start_mcp_server.sh`：

```bash
# 使用启动脚本
./start_mcp_server.sh

# 脚本会自动：
# 1. 检查Docker和Jupyter服务状态
# 2. 验证API访问
# 3. 提供模式选择（stdio/HTTP）
# 4. 启动对应的MCP Server
```

## 📊 部署验证清单

### 服务状态检查

- [ ] Jupyter服务运行正常
- [ ] Docker镜像已拉取
- [ ] MCP Server能够启动
- [ ] API访问正常
- [ ] 客户端配置完成

### 功能测试

- [ ] 能够读取notebook信息
- [ ] 能够执行代码单元格
- [ ] 能够添加新单元格
- [ ] 能够修改现有单元格
- [ ] 客户端工具调用正常

## 🔄 服务管理命令

### Jupyter服务管理

```bash
# 启动服务
systemctl --user start jupyter

# 停止服务
systemctl --user stop jupyter

# 重启服务
systemctl --user restart jupyter

# 查看状态
systemctl --user status jupyter

# 查看日志
journalctl --user -u jupyter -f
```

### Docker容器管理

```bash
# 查看运行中的容器
docker ps

# 停止MCP Server容器
docker stop <container_id>

# 查看容器日志
docker logs <container_id>

# 清理停止的容器
docker container prune
```

## 🌟 高级配置

### 自定义notebook路径

如果你想使用不同的notebook文件，只需修改环境变量：

```bash
# 修改DOCUMENT_ID为你的notebook路径
-e DOCUMENT_ID=path/to/your/notebook.ipynb
```

### 多notebook支持

可以为不同的notebook创建不同的MCP Server实例：

```bash
# Notebook 1
docker run -i --rm \
  -e DOCUMENT_ID=project1/analysis.ipynb \
  # ... 其他配置

# Notebook 2
docker run -i --rm \
  -e DOCUMENT_ID=project2/model.ipynb \
  # ... 其他配置
```

### 远程访问配置

如果需要远程访问，修改IP绑定：

```bash
# 在Jupyter服务配置中修改
--ip=0.0.0.0

# 在MCP Server中使用实际IP
-e DOCUMENT_URL=http://your-server-ip:8888
```

## 🎯 总结

通过本指南，你已经完成了：

- ✅ Jupyter服务的systemd配置
- ✅ MCP Server的Docker部署
- ✅ 多种客户端的配置方案
- ✅ 完整的故障排除指南
- ✅ 快速启动工具和管理命令
- ✅ 高级配置选项

现在可以开始使用AI助手与Jupyter Notebook进行实时交互了！

### 🚀 下一步建议

1. 选择并配置你喜欢的MCP客户端
2. 测试基本的notebook操作功能
3. 根据实际需求调整配置参数
4. 考虑设置生产环境的安全措施
5. 定期更新和维护服务组件

## 🗑️ 完整移除教程

如果你需要彻底移除Jupyter MCP Server及相关组件，请按以下步骤操作：

### 第一步：停止所有运行的服务

#### 1. 停止MCP Server容器

```bash
# 查看运行中的MCP Server容器
docker ps | grep jupyter-mcp-server

# 停止所有相关容器
docker stop $(docker ps -q --filter ancestor=datalayer/jupyter-mcp-server)

# 强制删除容器（如果需要）
docker rm -f $(docker ps -aq --filter ancestor=datalayer/jupyter-mcp-server)
```

#### 2. 停止Jupyter服务

```bash
# 停止systemd服务
systemctl --user stop jupyter

# 禁用开机自启
systemctl --user disable jupyter

# 验证服务已停止
systemctl --user status jupyter
```

### 第二步：移除Docker镜像和容器

#### 1. 删除MCP Server镜像

```bash
# 删除官方镜像
docker rmi datalayer/jupyter-mcp-server:latest

# 删除所有相关镜像（如果有多个版本）
docker images | grep jupyter-mcp-server | awk '{print $3}' | xargs docker rmi

# 清理未使用的镜像
docker image prune -f
```

#### 2. 清理Docker资源

```bash
# 清理停止的容器
docker container prune -f

# 清理未使用的网络
docker network prune -f

# 清理未使用的卷
docker volume prune -f

# 清理构建缓存
docker builder prune -f
```

### 第三步：移除systemd服务配置

#### 1. 删除服务文件

```bash
# 删除用户服务文件
rm -f ~/.config/systemd/user/jupyter.service

# 重新加载systemd配置
systemctl --user daemon-reload

# 重置失败状态（如果有）
systemctl --user reset-failed
```

#### 2. 验证服务已移除

```bash
# 检查服务是否还存在
systemctl --user list-unit-files | grep jupyter

# 检查是否有残留的服务状态
systemctl --user status jupyter
```

### 第四步：卸载Python依赖包

#### 1. 卸载MCP相关包

```bash
# 激活conda环境
source /home/cpu/miniforge3/bin/activate

# 卸载jupyter-collaboration
conda remove jupyter-collaboration -y

# 卸载datalayer_pycrdt
pip uninstall datalayer_pycrdt -y

# 重新安装标准pycrdt（如果需要）
conda install pycrdt -c conda-forge -y
```

#### 2. 可选：完全卸载Jupyter（谨慎操作）

```bash
# 如果你不再需要Jupyter，可以完全卸载
conda remove jupyterlab jupyter jupyter_server ipykernel -y

# 或者卸载整个base环境（极度谨慎）
# conda env remove -n base
```

### 第五步：清理配置文件和数据

#### 1. 删除项目文件

```bash
# 删除部署目录中的配置文件
cd /mnt/data/mcp/jupyter-mcp-server
rm -f claude_desktop_config.json
rm -f vscode_mcp_config.json
rm -f cursor_mcp_config.json
rm -f start_mcp_server.sh
rm -f COMPLETE_DEPLOYMENT_GUIDE.md
rm -f QUICK_REFERENCE.md
rm -f DEPLOYMENT_GUIDE.md
rm -f notebook.ipynb

# 删除测试notebook
rm -f /home/cpu/notebook.ipynb
```

#### 2. 清理Jupyter配置（可选）

```bash
# 备份现有配置（推荐）
cp -r ~/.jupyter ~/.jupyter.backup.$(date +%Y%m%d)

# 删除Jupyter配置目录（谨慎操作）
# rm -rf ~/.jupyter

# 删除Jupyter运行时目录
rm -rf ~/.local/share/jupyter/runtime/*
```

### 第六步：移除客户端配置

#### 1. Claude Desktop

```bash
# 备份配置文件
cp ~/.config/claude/claude_desktop_config.json ~/.config/claude/claude_desktop_config.json.backup

# 编辑配置文件，移除jupyter相关配置
nano ~/.config/claude/claude_desktop_config.json

# 或者完全删除配置文件重新开始
# rm ~/.config/claude/claude_desktop_config.json
```

#### 2. VS Code

```bash
# 备份VS Code设置
cp ~/.vscode/settings.json ~/.vscode/settings.json.backup

# 编辑settings.json，移除mcp.servers.DatalayerJupyter配置
nano ~/.vscode/settings.json

# 删除工作区MCP配置文件
find . -name ".vscode" -type d -exec rm -f {}/mcp.json \;
```

#### 3. Cursor

```bash
# 备份Cursor配置
cp ~/.cursor/mcp.json ~/.cursor/mcp.json.backup

# 编辑配置文件，移除jupyter相关配置
nano ~/.cursor/mcp.json

# 或者删除整个MCP配置文件
# rm ~/.cursor/mcp.json
```

### 第七步：验证完全移除

#### 1. 检查进程

```bash
# 检查是否有残留的Jupyter进程
ps aux | grep jupyter

# 检查是否有残留的Docker容器
docker ps -a | grep jupyter

# 检查端口占用
netstat -tlnp | grep -E "(8888|4040)"
```

#### 2. 检查文件系统

```bash
# 搜索残留的配置文件
find ~ -name "*jupyter*" -type f 2>/dev/null
find ~ -name "*mcp*" -type f 2>/dev/null

# 检查Docker镜像
docker images | grep jupyter
```

#### 3. 检查服务状态

```bash
# 检查systemd服务
systemctl --user list-units | grep jupyter

# 检查开机自启项
systemctl --user list-unit-files | grep jupyter
```

### 第八步：清理脚本（一键移除）

为了方便操作，你可以创建一个自动化清理脚本：

```bash
#!/bin/bash
# 创建清理脚本
cat > cleanup_jupyter_mcp.sh << 'EOF'
#!/bin/bash

echo "🗑️ 开始清理Jupyter MCP Server..."

# 停止服务
echo "停止服务..."
systemctl --user stop jupyter 2>/dev/null
systemctl --user disable jupyter 2>/dev/null

# 停止Docker容器
echo "停止Docker容器..."
docker stop $(docker ps -q --filter ancestor=datalayer/jupyter-mcp-server) 2>/dev/null
docker rm -f $(docker ps -aq --filter ancestor=datalayer/jupyter-mcp-server) 2>/dev/null

# 删除Docker镜像
echo "删除Docker镜像..."
docker rmi datalayer/jupyter-mcp-server:latest 2>/dev/null
docker image prune -f

# 删除服务文件
echo "删除systemd服务..."
rm -f ~/.config/systemd/user/jupyter.service
systemctl --user daemon-reload

# 卸载Python包
echo "卸载Python包..."
source /home/cpu/miniforge3/bin/activate
pip uninstall datalayer_pycrdt -y 2>/dev/null
conda remove jupyter-collaboration -y 2>/dev/null

# 删除配置文件
echo "删除配置文件..."
rm -f claude_desktop_config.json vscode_mcp_config.json cursor_mcp_config.json
rm -f start_mcp_server.sh *.md notebook.ipynb
rm -f /home/cpu/notebook.ipynb

echo "✅ 清理完成！"
echo "请手动检查并清理客户端配置文件中的MCP相关配置。"
EOF

# 使脚本可执行
chmod +x cleanup_jupyter_mcp.sh

# 运行清理脚本
./cleanup_jupyter_mcp.sh
```

### ⚠️ 重要提醒

1. **备份重要数据**: 移除前请备份重要的notebook文件和配置
2. **分步执行**: 建议分步执行，避免误删重要文件
3. **检查依赖**: 确认其他应用不依赖要删除的组件
4. **客户端配置**: 手动检查并清理客户端中的MCP配置
5. **系统影响**: 卸载Jupyter可能影响其他Python项目

### 🔄 重新安装

如果将来需要重新安装，只需重新按照部署指南操作即可。所有配置文件都已保存，可以快速恢复。
