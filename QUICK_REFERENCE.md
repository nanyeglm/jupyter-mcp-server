# 🚀 Jupyter MCP Server 快速参考

## 📋 个人配置信息

### 🔧 关键参数
- **Jupyter URL**: `http://127.0.0.1:8888`
- **Jupyter Token**: `ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359`
- **Notebook文件**: `notebook.ipynb`
- **工作目录**: `/home/cpu`
- **MCP端口**: `4040` (HTTP模式)

### 🐳 Docker镜像
```bash
datalayer/jupyter-mcp-server:latest
```

## ⚡ 快速启动命令

### 1. 检查Jupyter服务
```bash
systemctl --user status jupyter
```

### 2. 启动MCP Server (stdio模式)
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

### 3. 启动MCP Server (HTTP模式)
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

## 🔍 验证命令

### Jupyter API测试
```bash
curl "http://127.0.0.1:8888/api?token=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359"
```

### MCP Server健康检查
```bash
curl http://localhost:4040/api/healthz
```

## 🎯 客户端配置

### 手动配置参数
- **Name**: `Jupyter MCP Server`
- **Command**: `docker run -i --rm -e DOCUMENT_URL -e DOCUMENT_TOKEN -e DOCUMENT_ID -e RUNTIME_URL -e RUNTIME_TOKEN --network=host datalayer/jupyter-mcp-server:latest`

### 环境变量
| 变量 | 值 |
|------|-----|
| `DOCUMENT_URL` | `http://127.0.0.1:8888` |
| `DOCUMENT_TOKEN` | `ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359` |
| `DOCUMENT_ID` | `notebook.ipynb` |
| `RUNTIME_URL` | `http://127.0.0.1:8888` |
| `RUNTIME_TOKEN` | `ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359` |

## 🛠️ 常用工具

### 基础操作
- `get_notebook_info` - 获取notebook信息
- `read_all_cells` - 读取所有单元格
- `read_cell` - 读取指定单元格

### 单元格操作
- `append_markdown_cell` - 添加markdown单元格
- `append_execute_code_cell` - 添加并执行代码单元格
- `insert_markdown_cell` - 插入markdown单元格
- `insert_execute_code_cell` - 插入并执行代码单元格
- `overwrite_cell_source` - 覆写单元格源码
- `delete_cell` - 删除单元格

### 执行操作
- `execute_cell_simple_timeout` - 简单超时执行
- `execute_cell_streaming` - 流式执行
- `execute_cell_with_progress` - 带进度执行

## 🚨 故障排除

### 服务重启
```bash
# 重启Jupyter服务
systemctl --user restart jupyter

# 查看服务日志
journalctl --user -u jupyter -f
```

### Docker问题
```bash
# 查看运行容器
docker ps

# 清理容器
docker container prune

# 重新拉取镜像
docker pull datalayer/jupyter-mcp-server:latest
```

## 📁 相关文件

- `COMPLETE_DEPLOYMENT_GUIDE.md` - 完整部署指南
- `claude_desktop_config.json` - Claude Desktop配置
- `vscode_mcp_config.json` - VS Code配置
- `cursor_mcp_config.json` - Cursor配置
- `start_mcp_server.sh` - 启动脚本
- `notebook.ipynb` - 测试notebook
