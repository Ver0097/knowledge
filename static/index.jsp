<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>智能知识库问答系统</title>
    <!-- Markdown 渲染库 -->
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Microsoft YaHei', Arial, sans-serif;
            background: #f5f5f5;
            color: #1a1a1a;
            min-height: 100vh;
            display: flex;
        }

        /* ===== 左侧侧边栏 ===== */
        .sidebar {
            width: 260px;
            background: #1a1a2e;
            color: #ffffff;
            display: flex;
            flex-direction: column;
            position: fixed;
            height: 100vh;
            left: 0;
            top: 0;
            z-index: 100;
            transition: transform 0.3s ease;
        }

        .sidebar-header {
            padding: 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }

        .sidebar-logo {
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .logo-icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
        }

        .logo-text {
            font-size: 16px;
            font-weight: 600;
        }

        .logo-subtitle {
            font-size: 12px;
            color: rgba(255,255,255,0.6);
        }

        /* 导航菜单 */
        .nav-menu {
            padding: 16px 12px;
            flex: 1;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 14px 16px;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            margin-bottom: 4px;
            color: rgba(255,255,255,0.8);
        }

        .nav-item:hover {
            background: rgba(255,255,255,0.1);
            color: #ffffff;
        }

        .nav-item.active {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
        }

        .nav-icon {
            font-size: 18px;
            width: 24px;
            text-align: center;
        }

        .nav-text {
            font-size: 14px;
        }

        /* 知识库信息 */
        .kb-info {
            padding: 16px;
            border-top: 1px solid rgba(255,255,255,0.1);
        }

        .kb-title {
            font-size: 12px;
            color: rgba(255,255,255,0.5);
            margin-bottom: 8px;
        }

        .kb-stats {
            display: flex;
            justify-content: space-between;
            padding: 8px 12px;
            background: rgba(255,255,255,0.05);
            border-radius: 6px;
        }

        .kb-stat {
            text-align: center;
        }

        .kb-stat-value {
            font-size: 18px;
            font-weight: 600;
            color: #667eea;
        }

        .kb-stat-label {
            font-size: 11px;
            color: rgba(255,255,255,0.5);
        }

        /* 底部操作 */
        .sidebar-footer {
            padding: 16px;
            border-top: 1px solid rgba(255,255,255,0.1);
        }

        .sidebar-btn {
            width: 100%;
            padding: 10px 16px;
            border-radius: 6px;
            border: none;
            cursor: pointer;
            font-size: 13px;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.2s ease;
        }

        .btn-manage {
            background: rgba(255,255,255,0.1);
            color: #ffffff;
        }

        .btn-manage:hover {
            background: rgba(255,255,255,0.2);
        }

        .btn-clear {
            background: rgba(239,68,68,0.2);
            color: #ef4444;
        }

        .btn-clear:hover {
            background: rgba(239,68,68,0.3);
        }

        /* ===== 右侧主界面 ===== */
        .main-content {
            flex: 1;
            margin-left: 260px;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }

        /* 页面容器 */
        .page-container {
            display: none;
            flex: 1;
            flex-direction: column;
        }

        .page-container.active {
            display: flex;
        }

        /* ===== 上传文档页面 ===== */
        .upload-page {
            padding: 40px;
            max-width: 800px;
            margin: 0 auto;
            width: 100%;
        }

        .page-header {
            margin-bottom: 32px;
        }

        .page-title {
            font-size: 28px;
            font-weight: 600;
            color: #1a1a2e;
            margin-bottom: 8px;
        }

        .page-desc {
            font-size: 14px;
            color: #666;
        }

        /* 上传区域 */
        .upload-box {
            background: #ffffff;
            border: 2px dashed #667eea;
            border-radius: 16px;
            padding: 60px 40px;
            text-align: center;
            transition: all 0.3s ease;
            cursor: pointer;
            position: relative;
            overflow: hidden;
        }

        .upload-box:hover {
            border-color: #764ba2;
            background: rgba(102,126,234,0.02);
        }

        .upload-box.dragover {
            border-color: #764ba2;
            border-style: solid;
            background: rgba(102,126,234,0.05);
        }

        .upload-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, rgba(102,126,234,0.1) 0%, rgba(118,75,162,0.1) 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 36px;
        }

        .upload-text {
            font-size: 18px;
            color: #1a1a2e;
            margin-bottom: 8px;
        }

        .upload-hint {
            font-size: 14px;
            color: #666;
        }

        .upload-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
            padding: 12px 32px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            margin-top: 20px;
            transition: all 0.2s ease;
        }

        .upload-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102,126,234,0.3);
        }

        .file-input {
            display: none;
        }

        /* 上传状态 */
        .upload-status {
            margin-top: 20px;
        }

        .status-success {
            background: rgba(34,197,94,0.1);
            border: 1px solid #22c55e;
            color: #16a34a;
            padding: 16px 20px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .status-error {
            background: rgba(239,68,68,0.1);
            border: 1px solid #ef4444;
            color: #dc2626;
            padding: 16px 20px;
            border-radius: 8px;
        }

        .status-loading {
            color: #667eea;
            padding: 16px;
        }

        /* 文档列表 */
        .documents-section {
            margin-top: 40px;
        }

        .section-title {
            font-size: 18px;
            font-weight: 600;
            color: #1a1a2e;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .documents-list {
            background: #ffffff;
            border-radius: 12px;
            padding: 16px;
        }

        .doc-item {
            display: flex;
            align-items: center;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 8px;
            background: #f8f9fa;
            transition: all 0.2s ease;
        }

        .doc-item:last-child {
            margin-bottom: 0;
        }

        .doc-item:hover {
            background: #f0f0f0;
        }

        .doc-icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #ffffff;
            font-size: 18px;
            margin-right: 12px;
        }

        .doc-info {
            flex: 1;
        }

        .doc-name {
            font-size: 14px;
            font-weight: 500;
            color: #1a1a2e;
        }

        .doc-chunks {
            font-size: 12px;
            color: #666;
        }

        .doc-empty {
            text-align: center;
            color: #666;
            padding: 24px;
        }

        /* ===== 问答页面 ===== */
        .qa-page {
            flex-direction: column;
            height: 100vh;
        }

        .qa-page.active {
            display: flex;
        }

        .qa-header {
            padding: 20px 40px;
            background: #ffffff;
            border-bottom: 1px solid #e5e5e5;
        }

        .qa-title {
            font-size: 20px;
            font-weight: 600;
            color: #1a1a2e;
        }

        /* 对话区域 */
        .chat-container {
            flex: 1;
            overflow-y: auto;
            padding: 24px 40px;
            background: #f5f5f5;
        }

        .chat-messages {
            max-width: 800px;
            margin: 0 auto;
        }

        .chat-welcome {
            text-align: center;
            padding: 60px 40px;
        }

        .welcome-icon {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 36px;
            color: #ffffff;
        }

        .welcome-title {
            font-size: 24px;
            font-weight: 600;
            color: #1a1a2e;
            margin-bottom: 8px;
        }

        .welcome-text {
            font-size: 14px;
            color: #666;
            max-width: 400px;
            margin: 0 auto;
        }

        /* 消息样式 */
        .message {
            display: flex;
            margin-bottom: 24px;
            animation: fadeIn 0.3s ease;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .message-user {
            justify-content: flex-end;
        }

        .message-avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            margin-right: 12px;
        }

        .avatar-ai {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
        }

        .avatar-user {
            background: #e5e5e5;
            color: #666;
            order: 2;
            margin-right: 0;
            margin-left: 12px;
        }

        .message-content {
            max-width: 70%;
            padding: 16px 20px;
            border-radius: 16px;
            line-height: 1.6;
        }

        .content-user {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
        }

        .content-ai {
            background: #ffffff;
            color: #1a1a2e;
            border: 1px solid #e5e5e5;
        }

        /* 来源信息 */
        .message-sources {
            margin-top: 12px;
            padding-top: 12px;
            border-top: 1px solid #e5e5e5;
        }

        .sources-title {
            font-size: 12px;
            color: #666;
            margin-bottom: 8px;
        }

        .source-tag {
            display: inline-block;
            background: rgba(102,126,234,0.1);
            color: #667eea;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            margin-right: 6px;
            margin-bottom: 4px;
        }

        /* 输入区域 */
        .input-area {
            padding: 20px 40px;
            background: #ffffff;
            border-top: 1px solid #e5e5e5;
        }

        .input-wrapper {
            max-width: 800px;
            margin: 0 auto;
            display: flex;
            gap: 12px;
            align-items: center;
        }

        .input-box {
            flex: 1;
            display: flex;
            align-items: center;
            background: #f5f5f5;
            border-radius: 12px;
            padding: 4px 16px;
            border: 2px solid transparent;
            transition: all 0.2s ease;
        }

        .input-box:focus-within {
            border-color: #667eea;
            background: #ffffff;
        }

        .question-input {
            flex: 1;
            padding: 12px 8px;
            border: none;
            background: transparent;
            font-size: 15px;
            outline: none;
            color: #1a1a2e;
        }

        .question-input::placeholder {
            color: #999;
        }

        .send-btn {
            width: 44px;
            height: 44px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            border-radius: 12px;
            color: #ffffff;
            font-size: 18px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .send-btn:hover:not(:disabled) {
            transform: scale(1.05);
        }

        .send-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }

        /* 加载动画 - 思考中效果 */
        .typing-indicator {
            display: flex;
            align-items: center;
            padding: 8px 12px;
        }

        .typing-text {
            font-size: 15px;
            color: #667eea;
            margin-right: 4px;
        }

        .typing-dots {
            display: inline-flex;
        }

        .typing-dot-text {
            color: #667eea;
            font-size: 15px;
            animation: typingDot 1.4s infinite ease-in-out;
        }

        .typing-dot-text:nth-child(1) { animation-delay: 0s; }
        .typing-dot-text:nth-child(2) { animation-delay: 0.2s; }
        .typing-dot-text:nth-child(3) { animation-delay: 0.4s; }

        @keyframes typingDot {
            0%, 80%, 100% { opacity: 0; }
            40% { opacity: 1; }
        }

        .streaming-text {
            white-space: pre-wrap; /* 保持换行格式 */
        }

        /* Markdown 内容样式 */
        .markdown-content {
            line-height: 1.6;
        }

        .markdown-content p {
            margin: 0;
        }

        .markdown-content ul, .markdown-content ol {
            margin: 0;
            padding-left: 1.5em;
        }

        .markdown-content li {
            margin: 0;
        }

        .markdown-content li p {
            margin: 0;
        }

        .markdown-content strong {
            color: #1a1a2e;
            font-weight: 600;
        }

        .markdown-content code {
            background: rgba(102,126,234,0.1);
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Consolas', 'Monaco', monospace;
            font-size: 0.9em;
        }

        .markdown-content pre {
            background: #f8f9fa;
            padding: 12px 16px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 0.5em 0;
        }

        .markdown-content pre code {
            background: none;
            padding: 0;
        }

        .markdown-content h1, .markdown-content h2, .markdown-content h3 {
            margin: 0.8em 0 0.4em;
            color: #1a1a2e;
        }

        .markdown-content blockquote {
            border-left: 3px solid #667eea;
            padding-left: 1em;
            margin: 0.5em 0;
            color: #666;
        }

        /* ===== 移动端适配 ===== */
        .sidebar-toggle {
            display: none;
            position: fixed;
            top: 16px;
            left: 16px;
            width: 44px;
            height: 44px;
            background: #1a1a2e;
            border: none;
            border-radius: 8px;
            color: #ffffff;
            font-size: 20px;
            cursor: pointer;
            z-index: 101;
        }

        @media (max-width: 768px) {
            .sidebar {
                transform: translateX(-100%);
            }

            .sidebar.open {
                transform: translateX(0);
            }

            .main-content {
                margin-left: 0;
            }

            .sidebar-toggle {
                display: flex;
                align-items: center;
                justify-content: center;
            }

            .upload-page {
                padding: 24px 16px;
            }

            .qa-header {
                padding: 16px;
            }

            .chat-container {
                padding: 16px;
            }

            .input-area {
                padding: 16px;
            }

            .message-content {
                max-width: 85%;
            }
        }
    </style>
</head>
<body>
    <!-- 移动端侧边栏切换按钮 -->
    <button class="sidebar-toggle" onclick="toggleSidebar()">☰</button>

    <!-- 左侧侧边栏 -->
    <div class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <div class="sidebar-logo">
                <div class="logo-icon">📚</div>
                <div>
                    <div class="logo-text">知识库问答</div>
                    <div class="logo-subtitle">智能文档助手</div>
                </div>
            </div>
        </div>

        <!-- 导航菜单 -->
        <nav class="nav-menu">
            <div class="nav-item active" data-page="qa" onclick="switchPage('qa')">
                <span class="nav-icon">💬</span>
                <span class="nav-text">智能问答</span>
            </div>
            <div class="nav-item" data-page="upload" onclick="switchPage('upload')">
                <span class="nav-icon">📤</span>
                <span class="nav-text">上传文档</span>
            </div>
        </nav>

        <!-- 知识库信息 -->
        <div class="kb-info">
            <div class="kb-title">知识库状态</div>
            <div class="kb-stats">
                <div class="kb-stat">
                    <div class="kb-stat-value" id="docCount">-</div>
                    <div class="kb-stat-label">文档数</div>
                </div>
                <div class="kb-stat">
                    <div class="kb-stat-value" id="chunkCount">-</div>
                    <div class="kb-stat-label">片段数</div>
                </div>
            </div>
        </div>

        <!-- 底部操作 -->
        <div class="sidebar-footer">
            <button class="sidebar-btn btn-manage" onclick="openDocumentManager()">
                <span>📁</span> 文档管理
            </button>
            <button class="sidebar-btn btn-clear" onclick="clearKnowledgeBase()">
                <span>🗑️</span> 清空知识库
            </button>
        </div>
    </div>

    <!-- 右侧主界面 -->
    <div class="main-content">
        <!-- 上传文档页面 -->
        <div class="page-container upload-page" id="uploadPage">
            <div class="page-header">
                <h1 class="page-title">上传文档</h1>
                <p class="page-desc">上传 PDF、DOCX、TXT 文档，系统将自动进行切片和向量化处理</p>
            </div>

            <!-- 上传区域 -->
            <div class="upload-box" id="uploadBox">
                <div class="upload-icon">📤</div>
                <div class="upload-text">拖拽文件到此处，或点击选择文件</div>
                <div class="upload-hint">支持格式：PDF、DOCX、TXT</div>
                <input type="file" class="file-input" id="fileInput" accept=".pdf,.docx,.txt">
                <button class="upload-btn" onclick="document.getElementById('fileInput').click()">
                    选择文件
                </button>
            </div>

            <!-- 上传状态 -->
            <div class="upload-status" id="uploadStatus"></div>

            <!-- 文档列表 -->
            <div class="documents-section">
                <div class="section-title">📁 已上传文档</div>
                <div class="documents-list" id="documentsList">
                    <div class="doc-empty">暂无文档，请先上传</div>
                </div>
            </div>
        </div>

        <!-- 智能问答页面 -->
        <div class="page-container qa-page active" id="qaPage">
            <div class="qa-header">
                <h1 class="qa-title">智能问答</h1>
            </div>

            <!-- 对话区域 -->
            <div class="chat-container" id="chatContainer">
                <div class="chat-messages" id="chatMessages">
                    <div class="chat-welcome" id="chatWelcome">
                        <div class="welcome-icon">💬</div>
                        <div class="welcome-title">欢迎使用智能问答</div>
                        <div class="welcome-text">基于知识库内容回答问题，请先上传文档再开始提问</div>
                    </div>
                </div>
            </div>

            <!-- 输入区域 -->
            <div class="input-area">
                <div class="input-wrapper">
                    <div class="input-box">
                        <input type="text" class="question-input" id="questionInput"
                               placeholder="输入您的问题..."
                               onkeypress="if(event.key==='Enter') sendQuestion()">
                    </div>
                    <button class="send-btn" id="sendBtn" onclick="sendQuestion()">➤</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        const API_BASE = 'http://localhost:8000/api';

        // 当前页面
        let currentPage = 'qa';

        // 对话历史
        let chatHistory = [];

        // ===== 侧边栏操作 =====
        function toggleSidebar() {
            document.getElementById('sidebar').classList.toggle('open');
        }

        function switchPage(page) {
            currentPage = page;

            // 更新导航状态
            document.querySelectorAll('.nav-item').forEach(item => {
                item.classList.remove('active');
                if (item.dataset.page === page) {
                    item.classList.add('active');
                }
            });

            // 切换页面
            document.querySelectorAll('.page-container').forEach(p => {
                p.classList.remove('active');
            });
            document.getElementById(page + 'Page').classList.add('active');

            // 关闭移动端侧边栏
            document.getElementById('sidebar').classList.remove('open');

            // 刷新数据
            if (page === 'upload') {
                loadDocumentsList();
            }
            loadKbStats();
        }

        // ===== 知识库统计 =====
        async function loadKbStats() {
            try {
                const response = await fetch(`${API_BASE}/documents/default`);
                const data = await response.json();

                document.getElementById('docCount').textContent = data.total_documents || 0;
                document.getElementById('chunkCount').textContent = data.total_chunks || 0;
            } catch (error) {
                document.getElementById('docCount').textContent = '-';
                document.getElementById('chunkCount').textContent = '-';
            }
        }

        // ===== 文档上传 =====
        const uploadBox = document.getElementById('uploadBox');
        const fileInput = document.getElementById('fileInput');
        const uploadStatus = document.getElementById('uploadStatus');

        // 拖拽上传
        uploadBox.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadBox.classList.add('dragover');
        });

        uploadBox.addEventListener('dragleave', () => {
            uploadBox.classList.remove('dragover');
        });

        uploadBox.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadBox.classList.remove('dragover');
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                handleFileUpload(files[0]);
            }
        });

        fileInput.addEventListener('change', (e) => {
            if (e.target.files.length > 0) {
                handleFileUpload(e.target.files[0]);
            }
        });

        async function handleFileUpload(file) {
            uploadStatus.innerHTML = '<div class="status-loading">正在上传和处理文档...</div>';

            const formData = new FormData();
            formData.append('file', file);
            formData.append('collection_name', 'default');

            try {
                const response = await fetch(`${API_BASE}/upload`, {
                    method: 'POST',
                    body: formData
                });

                const result = await response.json();

                if (response.ok) {
                    uploadStatus.innerHTML = `
                        <div class="status-success">
                            <span style="font-size:20px;">✓</span>
                            <div>
                                <div style="font-weight:500;">上传成功</div>
                                <div style="font-size:13px;color:#16a34a;">已切分为 ${result.chunks_count} 个片段</div>
                            </div>
                        </div>
                    `;
                    loadDocumentsList();
                    loadKbStats();
                    // 清空文件输入
                    fileInput.value = '';
                } else {
                    uploadStatus.innerHTML = `
                        <div class="status-error">上传失败：${result.detail || '未知错误'}</div>
                    `;
                }
            } catch (error) {
                uploadStatus.innerHTML = `<div class="status-error">上传出错：${error.message}</div>`;
            }
        }

        // ===== 文档列表 =====
        async function loadDocumentsList() {
            try {
                const response = await fetch(`${API_BASE}/documents/default`);
                const data = await response.json();

                const list = document.getElementById('documentsList');

                if (!data.documents || data.documents.length === 0) {
                    list.innerHTML = '<div class="doc-empty">暂无文档，请先上传</div>';
                    return;
                }

                list.innerHTML = data.documents.map(doc => `
                    <div class="doc-item">
                        <div class="doc-icon">📄</div>
                        <div class="doc-info">
                            <div class="doc-name">${doc.filename}</div>
                            <div class="doc-chunks">${doc.chunks_count} 个片段</div>
                        </div>
                    </div>
                `).join('');
            } catch (error) {
                document.getElementById('documentsList').innerHTML =
                    '<div class="doc-empty">加载失败，请刷新页面</div>';
            }
        }

        // ===== 智能问答 =====
        const chatMessages = document.getElementById('chatMessages');
        const chatWelcome = document.getElementById('chatWelcome');
        const questionInput = document.getElementById('questionInput');
        const sendBtn = document.getElementById('sendBtn');

        let currentAiMessage = null;
        let currentSources = null;
        let hasStartedStreaming = false; // 标记是否已开始显示内容
        let streamingText = ''; // 保存流式输出的纯文本

        function addMessage(role, content, sources = null) {
            // 隐藏欢迎消息
            if (chatWelcome) {
                chatWelcome.style.display = 'none';
            }

            const messageDiv = document.createElement('div');
            messageDiv.className = `message message-${role}`;

            const avatarClass = role === 'user' ? 'avatar-user' : 'avatar-ai';
            const contentClass = role === 'user' ? 'content-user' : 'content-ai';
            const avatarText = role === 'user' ? '👤' : '🤖';

            let sourcesHtml = '';
            if (sources && sources.length > 0) {
                sourcesHtml = `
                    <div class="message-sources" id="sourcesArea">
                        <div class="sources-title">参考来源</div>
                        ${sources.map(s => `<span class="source-tag">${s}</span>`).join('')}
                    </div>
                `;
            }

            // 为 AI 消息添加一个内容容器，方便流式更新
            if (role === 'ai') {
                messageDiv.innerHTML = `
                    <div class="message-avatar ${avatarClass}">${avatarText}</div>
                    <div class="message-content ${contentClass}" id="aiContent">
                        ${content}
                        ${sourcesHtml}
                    </div>
                `;
                currentAiMessage = messageDiv;
            } else {
                messageDiv.innerHTML = `
                    <div class="message-avatar ${avatarClass}">${avatarText}</div>
                    <div class="message-content ${contentClass}">
                        ${content}
                        ${sourcesHtml}
                    </div>
                `;
            }

            chatMessages.appendChild(messageDiv);

            // 滚动到底部
            scrollToBottom();
        }

        function addStreamingMessage() {
            // 隐藏欢迎消息
            if (chatWelcome) {
                chatWelcome.style.display = 'none';
            }

            const messageDiv = document.createElement('div');
            messageDiv.className = 'message message-ai';
            messageDiv.innerHTML = `
                <div class="message-avatar avatar-ai">🤖</div>
                <div class="message-content content-ai" id="streamingContent">
                    <span class="streaming-text"></span>
                    <div class="message-sources" id="sourcesArea" style="display:none;">
                        <div class="sources-title">参考来源</div>
                    </div>
                </div>
            `;
            chatMessages.appendChild(messageDiv);
            currentAiMessage = messageDiv;
            scrollToBottom();
        }

        function updateStreamingContent(text) {
            // 追加纯文本
            streamingText += text;

            // 压缩多余换行（超过2个换行变成1个）
            const displayText = streamingText.replace(/\n{2,}/g, '\n');

            const contentEl = document.getElementById('streamingContent');
            if (contentEl) {
                const textSpan = contentEl.querySelector('.streaming-text');
                if (textSpan) {
                    textSpan.textContent = displayText;
                }
                scrollToBottom();
            }
        }

        function updateSources(sources) {
            const sourcesArea = document.getElementById('sourcesArea');
            if (sourcesArea && sources && sources.length > 0) {
                sourcesArea.innerHTML = `
                    <div class="sources-title">参考来源</div>
                    ${sources.map(s => `<span class="source-tag">${s}</span>`).join('')}
                `;
                sourcesArea.style.display = 'block';
            }
        }

        function finalizeStream() {
            // 清理 id，防止重复
            const contentEl = document.getElementById('streamingContent');
            if (contentEl) {
                contentEl.removeAttribute('id');
            }
            const sourcesArea = document.getElementById('sourcesArea');
            if (sourcesArea) {
                sourcesArea.removeAttribute('id');
            }
        }

        function scrollToBottom() {
            document.getElementById('chatContainer').scrollTop =
                document.getElementById('chatContainer').scrollHeight;
        }

        function addTypingIndicator() {
            const typingDiv = document.createElement('div');
            typingDiv.className = 'message';
            typingDiv.id = 'typingIndicator';
            typingDiv.innerHTML = `
                <div class="message-avatar avatar-ai">🤖</div>
                <div class="message-content content-ai">
                    <div class="typing-indicator">
                        <span class="typing-text">思考中</span>
                        <span class="typing-dots">
                            <span class="typing-dot-text">.</span>
                            <span class="typing-dot-text">.</span>
                            <span class="typing-dot-text">.</span>
                        </span>
                    </div>
                </div>
            `;
            chatMessages.appendChild(typingDiv);
            scrollToBottom();
        }

        function removeTypingIndicator() {
            const typing = document.getElementById('typingIndicator');
            if (typing) {
                typing.remove();
            }
        }

        async function sendQuestion() {
            const question = questionInput.value.trim();
            if (!question) return;

            // 重置流式状态
            hasStartedStreaming = false;
            streamingText = ''; // 重置文本缓冲

            // 添加用户消息
            addMessage('user', question);
            questionInput.value = '';
            sendBtn.disabled = true;

            // 显示思考动画
            addTypingIndicator();

            try {
                const response = await fetch(`${API_BASE}/ask/stream`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        question: question,
                        collection_name: 'default'
                    })
                });

                // 注意：不移除思考动画，等待收到第一个内容数据时才移除

                const reader = response.body.getReader();
                const decoder = new TextDecoder('utf-8');
                let buffer = '';

                while (true) {
                    const { done, value } = await reader.read();
                    if (done) {
                        // 处理剩余 buffer
                        if (buffer.trim()) {
                            await processSSELine(buffer.trim());
                        }
                        break;
                    }

                    buffer += decoder.decode(value, { stream: true });

                    // 按换行分割，保留未完成的行
                    const lines = buffer.split('\n');
                    // 最后一行可能不完整，保留到下次处理
                    buffer = lines.pop() || '';

                    for (const line of lines) {
                        await processSSELine(line);
                    }
                }

                // 如果一直没有收到内容（异常情况），确保移除动画
                if (!hasStartedStreaming) {
                    removeTypingIndicator();
                    addMessage('ai', '抱歉，未能获取有效回答。');
                }

            } catch (error) {
                removeTypingIndicator();
                addMessage('ai', `请求出错：${error.message}`);
            } finally {
                sendBtn.disabled = false;
            }
        }

        // 延迟函数
        function sleep(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        }

        async function processSSELine(line) {
            if (!line.trim()) return;

            if (line.startsWith('data: ')) {
                const data = line.slice(6).trim();

                if (data === '[DONE]') {
                    finalizeStream();
                    return;
                }

                try {
                    const json = JSON.parse(data);

                    if (json.type === 'sources') {
                        // 先保存来源信息，等开始显示内容时再显示
                        currentSources = json.content;
                    } else if (json.type === 'content') {
                        // 收到第一个内容时，移除思考动画并创建流式消息容器
                        if (!hasStartedStreaming) {
                            removeTypingIndicator();
                            addStreamingMessage();
                            // 如果之前已收到来源信息，现在显示
                            if (currentSources) {
                                updateSources(currentSources);
                            }
                            hasStartedStreaming = true;
                        }
                        updateStreamingContent(json.content);
                        // 每显示一个片段后等待，实现打字机效果
                        await sleep(50);
                    } else if (json.type === 'error') {
                        // 收到错误时，移除思考动画并显示错误
                        if (!hasStartedStreaming) {
                            removeTypingIndicator();
                            addStreamingMessage();
                            hasStartedStreaming = true;
                        }
                        updateStreamingContent(json.content);
                    }
                } catch (e) {
                    console.warn('[SSE] JSON parse error:', e, data);
                }
            }
        }

        // ===== 其他操作 =====
        function openDocumentManager() {
            window.open('/static/document_manager.html', '_blank');
        }

        async function clearKnowledgeBase() {
            if (!confirm('确定要清空所有文档吗？此操作不可恢复！')) {
                return;
            }

            try {
                const response = await fetch(`${API_BASE}/collection/default`, {
                    method: 'DELETE'
                });

                if (response.ok) {
                    alert('知识库已清空！');
                    loadDocumentsList();
                    loadKbStats();

                    // 清空对话历史
                    chatMessages.innerHTML = `
                        <div class="chat-welcome" id="chatWelcome">
                            <div class="welcome-icon">💬</div>
                            <div class="welcome-title">欢迎使用智能问答</div>
                            <div class="welcome-text">基于知识库内容回答问题，请先上传文档再开始提问</div>
                        </div>
                    `;
                } else {
                    const result = await response.json();
                    alert(`清空失败：${result.detail || '未知错误'}`);
                }
            } catch (error) {
                alert(`清空出错：${error.message}`);
            }
        }

        // ===== 初始化 =====
        document.addEventListener('DOMContentLoaded', () => {
            loadKbStats();
            loadDocumentsList();
        });
    </script>
</body>
</html>