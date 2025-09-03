# 🚀 Jupyter MCP Server 部署指南

## 📋 部署概览

本指南基于你的个人环境配置，提供完整的 Jupyter MCP Server 部署方案。

### 🏗️ 环境信息
- **Python环境**: `/home/cpu/miniforge3` (base环境)
- **Jupyter服务**: systemd用户服务，端口8888
- **Jupyter Token**: `ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359`
- **工作目录**: `/home/cpu`
- **测试Notebook**: `notebook.ipynb`

## ✅ 部署状态检查

### 1. Jupyter服务状态
```bash
systemctl --user status jupyter
```

### 2. Jupyter API访问测试
```bash
curl "http://127.0.0.1:8888/api?token=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359"
```

### 3. MCP Server健康检查（HTTP模式）
```bash
curl http://localhost:4040/api/healthz
```

## 🐳 Docker部署方式

### stdio模式（推荐用于Claude Desktop）
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

### HTTP模式（推荐用于测试和远程访问）
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

## 🔧 客户端配置

### Claude Desktop
配置文件位置: `~/.config/claude/claude_desktop_config.json`
使用提供的 `claude_desktop_config.json` 内容。

### VS Code
配置文件位置: `~/.vscode/settings.json` 或 `.vscode/mcp.json`
使用提供的 `vscode_mcp_config.json` 内容。

### Cursor
配置文件位置: `~/.cursor/mcp.json`
使用提供的 `cursor_mcp_config.json` 内容。

## 🛠️ 快速启动

使用提供的启动脚本：
```bash
./start_mcp_server.sh
```

## 🧪 功能测试

### 可用的MCP工具
1. `get_notebook_info` - 获取notebook信息
2. `read_all_cells` - 读取所有单元格
3. `read_cell` - 读取指定单元格
4. `append_markdown_cell` - 添加markdown单元格
5. `append_execute_code_cell` - 添加并执行代码单元格
6. `insert_markdown_cell` - 插入markdown单元格
7. `insert_execute_code_cell` - 插入并执行代码单元格
8. `overwrite_cell_source` - 覆写单元格源码
9. `delete_cell` - 删除单元格
10. `execute_cell_simple_timeout` - 简单超时执行
11. `execute_cell_streaming` - 流式执行
12. `execute_cell_with_progress` - 带进度执行

## 🔍 故障排除

### 常见问题
1. **Jupyter服务未启动**
   ```bash
   systemctl --user start jupyter
   ```

2. **Docker权限问题**
   ```bash
   sudo usermod -aG docker $USER
   # 重新登录或运行: newgrp docker
   ```

3. **端口冲突**
   - 检查端口占用: `netstat -tlnp | grep :8888`
   - 修改Jupyter端口或MCP端口

4. **网络连接问题**
   - 确保使用 `--network=host` 参数
   - 检查防火墙设置

## 📝 注意事项

1. **安全性**: 生产环境请更换默认token
2. **性能**: 长时间运行建议使用systemd服务
3. **备份**: 定期备份重要的notebook文件
4. **更新**: 定期更新Docker镜像

## 🎯 下一步

1. 配置你喜欢的MCP客户端
2. 测试基本的notebook操作
3. 根据需要调整配置参数
4. 考虑设置自动启动服务
