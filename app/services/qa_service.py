"""
问答服务
基于向量数据库检索和LangChain实现智能问答
支持DeepSeek API（与OpenAI API兼容）
"""
import os
import asyncio
from typing import Dict, List
from langchain_core.prompts import PromptTemplate
from dotenv import load_dotenv

from app.services.document_service import DocumentService

# 加载环境变量
load_dotenv()


class QAService:
    """问答服务类"""
    
    def __init__(self):
        """初始化问答服务"""
        self.document_service = DocumentService()
        
        # 初始化 Reranker 模型 (懒加载)
        self._reranker = None
        self.reranker_model_path = os.getenv("RERANKER_MODEL_PATH", "BAAI/bge-reranker-base")
        
        # 初始化LLM
        # 优先使用DeepSeek API，如果未配置则使用基于检索的简化问答
        self.llm = None
        
        # 尝试初始化DeepSeek API
        deepseek_api_key = os.getenv("DEEPSEEK_API_KEY")
        if deepseek_api_key:
            try:
                from langchain_openai import ChatOpenAI
                
                # DeepSeek API与OpenAI API兼容，使用ChatOpenAI
                # 参考文档：https://api-docs.deepseek.com/zh-cn/
                self.llm = ChatOpenAI(
                    model="deepseek-chat",  # 使用deepseek-chat（非思考模式）
                    # 或使用 "deepseek-reasoner"（思考模式）
                    openai_api_key=deepseek_api_key,
                    openai_api_base="https://api.deepseek.com",
                    temperature=0.7,  # 控制回答的随机性
                    timeout=60,  # 设置60秒超时
                    max_retries=2,  # 最大重试次数
                )
                print("[OK] DeepSeek API initialized successfully")
            except ImportError:
                print("[WARN] langchain-openai not installed, using retrieval-only mode")
                print("   Please run: pip install langchain-openai")
            except Exception as e:
                print(f"[WARN] DeepSeek API initialization failed ({str(e)}), using retrieval-only mode")
                self.llm = None
        else:
            print("[WARN] DEEPSEEK_API_KEY not configured, using retrieval-only mode")
            print("   Please set DEEPSEEK_API_KEY in .env file or environment variable")
    
    def create_qa_chain(self, vectorstore, llm=None):
        """
        创建问答链（支持混合检索和 Rerank）
        
        Args:
            vectorstore: 向量数据库实例
            llm: 语言模型实例（可选）
            
        Returns:
            QAChainWrapper 实例
        """
        if not llm:
            return None
        
        try:
            # 自定义混合检索器实现（使用 RRF 算法替代 EnsembleRetriever）
            class HybridRetriever:
                """
                混合检索器：使用 Reciprocal Rank Fusion (RRF) 算法融合多个检索器的结果
                
                RRF 算法原理：
                - 对每个检索器返回的文档列表，根据其排名位置计算倒数排名分数
                - 公式：score = 1 / (rank + k)，其中 k 是平滑常数（默认60）
                - 将所有检索器对同一文档的分数相加，得到最终融合分数
                - 按融合分数降序排列，返回去重后的文档列表
                
                优势：
                - 无需手动调整权重参数
                - 对不同检索器的评分尺度不敏感
                - 能有效平衡多个检索源的贡献
                """
                def __init__(self, retrievers, k=60):
                    """
                    初始化混合检索器
                    
                    Args:
                        retrievers: 检索器列表，如 [vector_retriever, bm25_retriever]
                        k: RRF 平滑常数，默认 60（论文推荐值）
                           - k 值越大，排名靠后的文档分数衰减越慢
                           - k 值越小，更偏重排名靠前的文档
                    """
                    self.retrievers = retrievers
                    self.k = k
                
                def invoke(self, query: str):
                    """
                    执行 RRF 混合检索
                    
                    Args:
                        query: 查询字符串
                        
                    Returns:
                        融合后的文档列表（已去重并按 RRF 分数排序）
                    """
                    # 存储融合分数：{文档内容: RRF分数}
                    fused_scores = {}
                    # 存储文档对象：{文档内容: Document对象}
                    doc_map = {}
                    
                    # 从所有检索器获取文档并计算 RRF 分数
                    for retriever in self.retrievers:
                        try:
                            # 调用检索器获取文档列表
                            docs = retriever.invoke(query)
                            
                            # 遍历文档，根据排名计算 RRF 分数
                            for rank, doc in enumerate(docs):
                                # 使用文档内容作为唯一键（去重依据）
                                # 注意：实际生产环境建议使用文档ID，但当前使用内容哈希
                                doc_key = doc.page_content
                                
                                # RRF 核心公式：score = 1 / (rank + k)
                                # rank 从 0 开始，所以实际是 1/(0+60), 1/(1+60), 1/(2+60)...
                                rrf_score = 1.0 / (rank + self.k)
                                
                                # 累加来自不同检索器的分数（同一文档可能被多个检索器返回）
                                if doc_key not in fused_scores:
                                    fused_scores[doc_key] = 0.0
                                    doc_map[doc_key] = doc
                                fused_scores[doc_key] += rrf_score
                                
                        except Exception as e:
                            print(f"[WARN] 检索器执行失败: {str(e)}")
                            continue
                    
                    # 按 RRF 融合分数降序排序
                    sorted_items = sorted(
                        fused_scores.items(), 
                        key=lambda x: x[1],  # 按分数排序
                        reverse=True  # 降序
                    )
                    
                    # 返回去重后的文档列表
                    return [doc_map[doc_key] for doc_key, score in sorted_items]

            from langchain_core.runnables import RunnablePassthrough, RunnableLambda
            from langchain_core.prompts import ChatPromptTemplate
            
            # 1. 向量检索器
            vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
            
            # 2. 关键词检索器 (BM25)
            collection_name = vectorstore._collection_name
            bm25_retriever = self.document_service.get_bm25_retriever(collection_name, k=5)
            
            # 3. 构建混合检索器 (Hybrid with RRF)
            if bm25_retriever:
                # 使用 RRF 算法融合向量检索和 BM25 检索
                # k=60 是 RRF 论文推荐的默认值
                hybrid_retriever = HybridRetriever(
                    retrievers=[vector_retriever, bm25_retriever],
                    k=60
                )
                print("✓ 混合检索器 (向量 + BM25 + RRF) 已启用")
            else:
                hybrid_retriever = vector_retriever
                print("[INFO] 使用纯向量检索")
            
            # 自定义提示词模板 (增强容错性和格式化要求)
            prompt_template = """你是一个专业的知识库助手。请根据提供的上下文信息，简洁、准确地回答用户的问题。

### 规则：
1. **仅根据上下文回答**：如果上下文中没有提到相关信息，请诚实告知，不要胡编乱造。
2. **结构化回答**：如果步骤较多，请使用列表形式（如 1. 2. 3.）。
3. **语言处理**：上下文可能包含一些由于解析产生的异常空格（如“中 文”），请在理解时自动忽略这些空格，并以正常的中文格式回答。

### 上下文信息：
{context}

### 问题：
{question}

### 助手回答："""
            
            # 使用 ChatPromptTemplate（兼容 ChatOpenAI）
            prompt = ChatPromptTemplate.from_template(prompt_template)
            
            # 格式化文档的函数
            def format_docs(docs):
                return "\n\n".join(doc.page_content for doc in docs)
            
            # 构建检索链：检索文档 -> 格式化 -> 生成答案
            # 基础链：输入 {"context": "...", "question": "..."} -> 输出 LLM 响应
            llm_chain = prompt | llm
            
            # 包装为统一的接口，使其返回包含 "answer" 和 "context" 的字典
            class QAChainWrapper:
                def __init__(self, llm_chain, retriever, rerank_func=None):
                    self.llm_chain = llm_chain
                    self.retriever = retriever
                    self.rerank_func = rerank_func
                
                def invoke(self, input_data):
                    # 从输入中提取问题
                    if isinstance(input_data, str):
                        question = input_data
                    elif isinstance(input_data, dict):
                        question = input_data.get("input", input_data.get("question", ""))
                    else:
                        question = str(input_data)
                    
                    # 1. 检索候选文档
                    docs = self.retriever.invoke(question)
                    
                    # 2. 如果有重排序函数，进行重排序
                    if self.rerank_func:
                        docs = self.rerank_func(question, docs, top_n=3)
                    
                    # 2.5 文本清洗 (解决存量数据的空格问题)
                    cleaned_docs = []
                    import re
                    for doc in docs:
                        content = doc.page_content
                        # 移除中文字符间的异常空格
                        content = re.sub(r'([\u4e00-\u9fa5])\s+([\u4e00-\u9fa5])', r'\1\2', content)
                        content = re.sub(r'([\u4e00-\u9fa5])\s+([\u4e00-\u9fa5])', r'\1\2', content)
                        doc.page_content = content
                        cleaned_docs.append(doc)
                    
                    # 3. 使用 LLM 生成答案
                    context_text = "\n\n".join(doc.page_content for doc in cleaned_docs)
                    result = self.llm_chain.invoke({"context": context_text, "question": question})
                    
                    # 提取答案内容
                    answer = result.content if hasattr(result, 'content') else str(result)
                    
                    # 返回统一格式
                    return {
                        "answer": answer,
                        "context": docs,
                        "result": answer
                    }
            
            return QAChainWrapper(llm_chain, hybrid_retriever, self._rerank_documents)
        except Exception as e:
            print(f"创建问答链失败：{str(e)}")
            import traceback
            traceback.print_exc()
            return None
    
    @property
    def reranker(self):
        """懒加载 Reranker 模型"""
        if self._reranker is None:
            try:
                from sentence_transformers import CrossEncoder
                print(f"正在加载 Reranker 模型: {self.reranker_model_path}")
                
                # 检查本地路径
                model_path = self.reranker_model_path
                if not os.path.exists(model_path):
                    print(f"警告: 本地 Reranker 路径不存在，将尝试在线下载: {model_path}")
                    # 如果不存在且不是绝对路径，可能需要下载
                
                self._reranker = CrossEncoder(model_path, device='cpu')
                print("✓ Reranker 模型加载成功")
            except Exception as e:
                print(f"[WARN] Reranker 加载失败: {str(e)}，将跳过重排序步骤")
                self._reranker = False # 标记为加载失败，避免重复尝试
        return self._reranker

    def _rerank_documents(self, query: str, docs: List, top_n: int = 3) -> List:
        """使用 Reranker 对文档进行重排序"""
        if not docs or not self.reranker:
            return docs[:top_n]
            
        try:
            # 准备输入对：(query, content)
            pairs = [[query, doc.page_content] for doc in docs]
            # 计算分数
            scores = self.reranker.predict(pairs)
            
            # 将分数添加到文档元数据中并排序
            for doc, score in zip(docs, scores):
                doc.metadata["rerank_score"] = float(score)
            
            # 按分数降序排列
            reranked_docs = sorted(docs, key=lambda x: x.metadata["rerank_score"], reverse=True)
            return reranked_docs[:top_n]
        except Exception as e:
            print(f"重排序失败: {str(e)}")
            return docs[:top_n]

    async def answer_question(
        self, 
        question: str, 
        collection_name: str = "default"
    ) -> Dict:
        """
        回答用户问题
        
        Args:
            question: 用户问题
            collection_name: 知识库集合名称
            
        Returns:
            包含答案和来源的字典
        """
        try:
            # 获取向量数据库
            vectorstore = self.document_service.get_vectorstore(collection_name)
            
            # 1. 构建混合检索器 (向量 + BM25)
            vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
            bm25_retriever = self.document_service.get_bm25_retriever(collection_name, k=5)
            
            # 自定义混合检索器实现（RRF 算法）
            class HybridRetriever:
                """
                混合检索器：使用 Reciprocal Rank Fusion (RRF) 算法融合多个检索器的结果
                RRF 公式：score = 1 / (rank + k)，k默认60
                """
                def __init__(self, retrievers, k=60):
                    self.retrievers = retrievers
                    self.k = k
                
                def invoke(self, query: str):
                    """执行 RRF 混合检索"""
                    fused_scores = {}
                    doc_map = {}
                    
                    for retriever in self.retrievers:
                        try:
                            docs = retriever.invoke(query)
                            for rank, doc in enumerate(docs):
                                doc_key = doc.page_content
                                rrf_score = 1.0 / (rank + self.k)
                                if doc_key not in fused_scores:
                                    fused_scores[doc_key] = 0.0
                                    doc_map[doc_key] = doc
                                fused_scores[doc_key] += rrf_score
                        except Exception as e:
                            print(f"[WARN] 检索器执行失败: {str(e)}")
                            continue
                    
                    sorted_items = sorted(fused_scores.items(), key=lambda x: x[1], reverse=True)
                    return [doc_map[doc_key] for doc_key, score in sorted_items]

            if bm25_retriever:
                retriever = HybridRetriever(
                    retrievers=[vector_retriever, bm25_retriever],
                    k=60  # RRF 平滑常数
                )
            else:
                retriever = vector_retriever
                
            # 2. 检索相关文档候选集
            try:
                candidate_docs = retriever.invoke(question)
            except Exception as e:
                print(f"[ERROR] 检索候选文档失败：{str(e)}")
                # 降级到纯向量检索
                candidate_docs = vector_retriever.invoke(question)
            
            # 3. Rerank 重排序
            relevant_docs = self._rerank_documents(question, candidate_docs, top_n=3)
            
            # 3.5 实时清洗检索到的片段 (应对历史存量数据)
            import re
            for doc in relevant_docs:
                content = doc.page_content
                content = re.sub(r'([\u4e00-\u9fa5])\s+([\u4e00-\u9fa5])', r'\1\2', content)
                content = re.sub(r'([\u4e00-\u9fa5])\s+([\u4e00-\u9fa5])', r'\1\2', content)
                doc.page_content = content

            if not relevant_docs:
                return {
                    "answer": "抱歉，在知识库中没有找到相关信息。",
                    "sources": []
                }
            
            # 如果有LLM，使用问答链生成答案
            if self.llm:
                qa_chain = self.create_qa_chain(vectorstore, self.llm)
                if qa_chain:
                    try:
                        # 使用asyncio设置超时，避免无限等待
                        loop = asyncio.get_event_loop()
                        result = await asyncio.wait_for(
                            loop.run_in_executor(
                                None, 
                                lambda: qa_chain.invoke({"input": question})
                            ),
                            timeout=60.0  # 60秒超时
                        )
                        answer = result.get("answer", result.get("result", ""))
                        sources = []
                        # 新版本可能使用context字段
                        context_docs = result.get("context", [])
                        if context_docs:
                            sources = [
                                doc.metadata.get("source", "未知来源") 
                                for doc in context_docs if hasattr(doc, 'metadata')
                            ]
                        # 兼容旧版本的source_documents
                        if not sources:
                            source_docs = result.get("source_documents", [])
                            if source_docs:
                                sources = [
                                    doc.metadata.get("source", "未知来源") 
                                    for doc in source_docs if hasattr(doc, 'metadata')
                                ]
                    except asyncio.TimeoutError:
                        # 超时，回退到检索模式
                        print("[WARN] LLM API调用超时，使用检索模式")
                        answer = self._format_retrieval_answer(relevant_docs)
                        sources = [
                            doc.metadata.get("source", "未知来源") 
                            for doc in relevant_docs if hasattr(doc, 'metadata')
                        ]
                    except Exception as e:
                        # LLM生成失败，回退到检索模式
                        print(f"[WARN] LLM生成答案失败，使用检索模式：{str(e)}")
                        answer = self._format_retrieval_answer(relevant_docs)
                        sources = [
                            doc.metadata.get("source", "未知来源") 
                            for doc in relevant_docs if hasattr(doc, 'metadata')
                        ]
                else:
                    # 问答链创建失败，使用检索模式
                    answer = self._format_retrieval_answer(relevant_docs)
                    sources = [
                        doc.metadata.get("source", "未知来源") 
                        for doc in relevant_docs
                    ]
            else:
                # 简化版：直接返回最相关的文档片段
                answer = self._format_retrieval_answer(relevant_docs)
                # 如果是因为没有配置 LLM，在回答开头加上提示
                if not self.llm:
                    answer = "【提示：未配置 LLM (DeepSeek)，当前为纯检索模式】\n\n" + answer
                sources = [
                    doc.metadata.get("source", "未知来源") 
                    for doc in relevant_docs
                ]
            
            return {
                "answer": answer,
                "sources": list(set(sources))  # 去重
            }
        
        except Exception as e:
            raise Exception(f"问答处理失败：{str(e)}")
    
    def _format_retrieval_answer(self, docs: List) -> str:
        """
        格式化检索到的文档片段作为答案
        
        Args:
            docs: 检索到的文档列表
            
        Returns:
            格式化后的答案字符串
        """
        if not docs:
            return "抱歉，在知识库中没有找到相关信息。"
        
        # 组合前3个最相关的文档片段
        answer_parts = ["根据知识库内容，相关信息如下：\n"]
        for i, doc in enumerate(docs[:3], 1):
            content = doc.page_content.strip()
            if len(content) > 500:
                content = content[:500] + "..."
            answer_parts.append(f"\n【片段 {i}】\n{content}")
        
        return "\n".join(answer_parts)
