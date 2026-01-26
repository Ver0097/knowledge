# DeepSeek API 配置说明

## 快速配置

项目已自动配置DeepSeek API密钥。如需修改，请按以下步骤操作：

### 方式1：使用.env文件（推荐）

在项目根目录创建 `.env` 文件（如果不存在），添加以下内容：

```env
DEEPSEEK_API_KEY=sk-103b2634aed4409a972a2754dba7e0f6
```

**注意**：`.env` 文件已添加到 `.gitignore`，不会被提交到Git仓库。

### 方式2：设置环境变量

**Windows (PowerShell):**
```powershell
$env:DEEPSEEK_API_KEY="sk-103b2634aed4409a972a2754dba7e0f6"
```

**Windows (CMD):**
```cmd
set DEEPSEEK_API_KEY=sk-103b2634aed4409a972a2754dba7e0f6
```

**Linux/Mac:**
```bash
export DEEPSEEK_API_KEY=sk-103b2634aed4409a972a2754dba7e0f6
```

## 验证配置

启动服务后，查看控制台输出：

- ✅ **成功**：看到 `✅ 已成功初始化DeepSeek API`
- ⚠️ **失败**：看到 `⚠️ 提示：未配置DEEPSEEK_API_KEY环境变量`

## 模型选择

系统默认使用 `deepseek-chat`（标准对话模式）。如需使用思考模式，修改 `app/services/qa_service.py`：

```python
self.llm = ChatOpenAI(
    model="deepseek-reasoner",  # 改为思考模式
    openai_api_key=deepseek_api_key,
    openai_api_base="https://api.deepseek.com",
    temperature=0.7,
)
```

## API文档

更多信息请参考：[DeepSeek API文档](https://api-docs.deepseek.com/zh-cn/)

## 获取API密钥

如果还没有API密钥，请访问：[DeepSeek Platform](https://platform.deepseek.com/api_keys)
