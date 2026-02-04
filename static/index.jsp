<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>智能知识库问答系统</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Microsoft YaHei', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #1a1a1a;
            min-height: 100vh;
            padding: 20px;
            line-height: 1.6;
        }
        
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background: #ffffff;
            border: 2px solid #1a1a1a;
            border-radius: 8px;
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 60px 40px;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        
        .header::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
            animation: headerGlow 15s linear infinite;
        }
        
        @keyframes headerGlow {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .header h1 {
            font-size: 2.2em;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 12px;
            letter-spacing: -0.5px;
            position: relative;
            z-index: 1;
            text-shadow: 0 2px 10px rgba(0,0,0,0.2);
        }
        
        .header p {
            font-size: 1em;
            color: rgba(255,255,255,0.95);
            font-weight: 400;
            position: relative;
            z-index: 1;
        }
        
        .content {
            padding: 40px 30px;
            background: #ffffff;
            box-shadow: 0 -4px 20px rgba(0,0,0,0.1);
        }
        
        .section {
            margin-bottom: 50px;
        }
        
        .section:last-child {
            margin-bottom: 0;
        }
        
        .section-title {
            font-size: 1.4em;
            font-weight: 600;
            color: #667eea;
            margin-bottom: 24px;
            padding-bottom: 12px;
            border-bottom: 2px solid #667eea;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .section-title::before {
            content: '';
            width: 4px;
            height: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: inline-block;
            border-radius: 2px;
        }
        
        .upload-area {
            border: 2px dashed #667eea;
            border-radius: 12px;
            padding: 50px 30px;
            text-align: center;
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%);
            transition: all 0.3s ease;
            cursor: pointer;
        }
        
        .upload-area:hover {
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
            border-color: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(102, 126, 234, 0.2);
        }
        
        .upload-area.dragover {
            background: #f0f0f0;
            border-color: #000000;
            border-style: solid;
        }
        
        .upload-area p {
            color: #1a1a1a;
            margin-bottom: 12px;
        }
        
        .upload-area p:first-child {
            font-size: 1.1em;
            font-weight: 500;
        }
        
        .upload-area p:last-of-type {
            font-size: 0.9em;
            color: #666;
        }
        
        .file-input {
            display: none;
        }
        
        .upload-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
            padding: 14px 36px;
            border: none;
            border-radius: 8px;
            font-size: 1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 20px;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .upload-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 25px rgba(102, 126, 234, 0.4);
        }
        
        .upload-btn:active {
            transform: translateY(0);
        }
        
        .file-info {
            margin-top: 20px;
            color: #666;
            font-size: 0.9em;
        }
        
        .qa-area {
            margin-top: 0;
        }
        
        .input-group {
            display: flex;
            gap: 12px;
            margin-bottom: 24px;
        }
        
        .question-input {
            flex: 1;
            padding: 14px 18px;
            border: 2px solid #667eea;
            border-radius: 8px;
            font-size: 1em;
            background: #ffffff;
            color: #1a1a1a;
            outline: none;
            transition: all 0.3s ease;
        }
        
        .question-input:focus {
            border-color: #764ba2;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
            transform: translateY(-1px);
        }
        
        .question-input::placeholder {
            color: #999;
        }
        
        .ask-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #ffffff;
            padding: 14px 32px;
            border: none;
            border-radius: 8px;
            font-size: 1em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            white-space: nowrap;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
        }
        
        .ask-btn:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 6px 25px rgba(102, 126, 234, 0.4);
        }
        
        .ask-btn:active:not(:disabled) {
            transform: translateY(0);
        }
        
        .ask-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            background: #666;
            border-color: #666;
        }
        
        .answer-area {
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%);
            border: 2px solid #667eea;
            border-radius: 12px;
            padding: 24px;
            margin-top: 20px;
            min-height: 120px;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.1);
        }
        
        .answer-title {
            font-weight: 600;
            color: #667eea;
            margin-bottom: 16px;
            font-size: 1.1em;
            padding-bottom: 12px;
            border-bottom: 2px solid #667eea;
        }
        
        .answer-content {
            color: #1a1a1a;
            line-height: 1.8;
            white-space: pre-wrap;
            font-size: 0.95em;
        }
        
        .sources {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #ddd;
        }
        
        .sources-title {
            font-weight: 600;
            color: #1a1a1a;
            margin-bottom: 12px;
            font-size: 0.95em;
        }
        
        .source-item {
            color: #333;
            font-size: 0.9em;
            margin: 8px 0;
            padding-left: 16px;
            position: relative;
        }
        
        .source-item::before {
            content: '•';
            position: absolute;
            left: 0;
            color: #1a1a1a;
            font-weight: bold;
        }
        
        .loading {
            text-align: center;
            color: #666;
            padding: 30px;
            font-size: 0.95em;
        }
        
        .error {
            background: #fff5f5;
            color: #c53030;
            padding: 16px;
            border: 2px solid #c53030;
            border-radius: 4px;
            margin-top: 12px;
            font-size: 0.9em;
        }
        
        .success {
            background: #f0fff4;
            color: #22543d;
            padding: 16px;
            border: 2px solid #22543d;
            border-radius: 4px;
            margin-top: 12px;
            font-size: 0.9em;
        }
        
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }
            
            .container {
                border-width: 1px;
            }
            
            .header {
                padding: 30px 20px;
            }
            
            .header h1 {
                font-size: 1.8em;
            }
            
            .content {
                padding: 30px 20px;
            }
            
            .input-group {
                flex-direction: column;
            }
            
            .ask-btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>智能知识库问答系统</h1>
            <p>基于LangChain和Chroma的文档智能问答平台</p>
        </div>
        
        <div class="content">
            <!-- 文档上传区域 -->
            <div class="section">
                <h2 class="section-title">上传文档</h2>
                <div class="upload-area" id="uploadArea">
                    <p>拖拽文件到此处或点击选择文件</p>
                    <p>支持格式：PDF、DOCX、TXT</p>
                    <input type="file" id="fileInput" class="file-input" accept=".pdf,.docx,.txt">
                    <button class="upload-btn" onclick="document.getElementById('fileInput').click()">
                        选择文件
                    </button>
                    <div class="file-info" id="fileInfo"></div>
                    <div id="uploadStatus"></div>
                    <!-- 查看片段按钮 -->
                    <div id="viewChunksSection" style="display: none; margin-top: 24px;">
                        <button class="upload-btn" onclick="openChunksViewerPage()" style="background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);">
                            🔍 查看文档片段
                        </button>
                    </div>
                    <!-- 文档管理按钮 -->
                    <div style="margin-top: 24px; display: flex; gap: 12px; justify-content: center; flex-wrap: wrap;">
                        <button class="upload-btn" onclick="openDocumentManager()" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">
                            📁 文档管理
                        </button>
                        <button class="upload-btn" onclick="clearKnowledgeBase()" style="background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);">
                            🗑️ 清空知识库
                        </button>
                    </div>
                </div>
            </div>
            
            <!-- 问答区域 -->
            <div class="section qa-area">
                <h2 class="section-title">智能问答</h2>
                <div class="input-group">
                    <input 
                        type="text" 
                        class="question-input" 
                        id="questionInput" 
                        placeholder="请输入您的问题..."
                        onkeypress="if(event.key==='Enter') askQuestion()"
                    >
                    <button class="ask-btn" id="askBtn" onclick="askQuestion()">提问</button>
                </div>
                <div class="answer-area" id="answerArea" style="display: none;">
                    <div class="answer-title">回答</div>
                    <div class="answer-content" id="answerContent"></div>
                    <div class="sources" id="sourcesArea" style="display: none;">
                        <div class="sources-title">参考来源</div>
                        <div id="sourcesList"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        const API_BASE = 'http://localhost:8000/api';
        
        // 文件上传相关
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('fileInput');
        const fileInfo = document.getElementById('fileInfo');
        const uploadStatus = document.getElementById('uploadStatus');
        
        // 拖拽上传
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.classList.add('dragover');
        });
        
        uploadArea.addEventListener('dragleave', () => {
            uploadArea.classList.remove('dragover');
        });
        
        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.classList.remove('dragover');
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
            fileInfo.textContent = `已选择：${file.name} (${(file.size / 1024).toFixed(2)} KB)`;
            uploadStatus.innerHTML = '<div class="loading">正在上传和处理文档...</div>';
            // 隐藏查看片段区域
            document.getElementById('viewChunksSection').style.display = 'none';
                    
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
                    uploadStatus.innerHTML = `<div class="success">文档上传成功<br>已切分为 ${result.chunks_count} 个片段</div>`;
                    // 显示查看片段按钮
                    document.getElementById('viewChunksSection').style.display = 'block';
                } else {
                    uploadStatus.innerHTML = `<div class="error">上传失败：${result.detail || '未知错误'}</div>`;
                }
            } catch (error) {
                uploadStatus.innerHTML = `<div class="error">上传出错：${error.message}</div>`;
            }
        }
                
        // 打开新页面查看文档片段
        function openChunksViewerPage() {
            window.open('/static/document_chunks.html', '_blank');
        }
        
        // 打开文档管理页面
        function openDocumentManager() {
            window.open('/static/document_manager.html', '_blank');
        }
        
        // 清空知识库
        async function clearKnowledgeBase() {
            if (!confirm('确定要清空所有文档吗？此操作不可恢复！')) {
                return;
            }
            
            try {
                const response = await fetch(`${API_BASE}/collection/default`, {
                    method: 'DELETE'
                });
                
                const result = await response.json();
                
                if (response.ok) {
                    alert('知识库已清空！');
                    uploadStatus.innerHTML = '';
                    fileInfo.textContent = '';
                    document.getElementById('viewChunksSection').style.display = 'none';
                } else {
                    alert(`清空失败：${result.detail || '未知错误'}`);
                }
            } catch (error) {
                alert(`清空出错：${error.message}`);
            }
        }
        
        // 问答相关
        const questionInput = document.getElementById('questionInput');
        const askBtn = document.getElementById('askBtn');
        const answerArea = document.getElementById('answerArea');
        const answerContent = document.getElementById('answerContent');
        const sourcesArea = document.getElementById('sourcesArea');
        const sourcesList = document.getElementById('sourcesList');
        
        async function askQuestion() {
            const question = questionInput.value.trim();
            if (!question) {
                alert('请输入问题');
                return;
            }
            
            askBtn.disabled = true;
            askBtn.textContent = '思考中...';
            answerArea.style.display = 'block';
            answerContent.innerHTML = '<div class="loading">正在思考，请稍候...</div>';
            sourcesArea.style.display = 'none';
            
            try {
                const response = await fetch(`${API_BASE}/ask`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        question: question,
                        collection_name: 'default'
                    })
                });
                
                const result = await response.json();
                
                if (response.ok) {
                    answerContent.textContent = result.answer;
                    
                    if (result.sources && result.sources.length > 0) {
                        sourcesList.innerHTML = result.sources.map(source => 
                            `<div class="source-item">${source}</div>`
                        ).join('');
                        sourcesArea.style.display = 'block';
                    }
                } else {
                    answerContent.innerHTML = `<div class="error">问答失败：${result.detail || '未知错误'}</div>`;
                }
            } catch (error) {
                answerContent.innerHTML = `<div class="error">请求出错：${error.message}</div>`;
            } finally {
                askBtn.disabled = false;
                askBtn.textContent = '提问';
            }
        }
    </script>
</body>
</html>
