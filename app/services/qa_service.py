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
        创建问答链
        
        Args:
            vectorstore: 向量数据库实例
            llm: 语言模型实例（可选）
            
        Returns:
            RetrievalQA链实例（如果有LLM）或None
        """
        if not llm:
            return None
        
        try:
            from langchain.chains.combine_documents import create_stuff_documents_chain
            from langchain.chains import create_retrieval_chain
            from langchain_core.runnables import RunnablePassthrough
            
            # 自定义提示词模板（中文优化）
            prompt_template = """基于以下上下文信息回答问题。如果你不知道答案，就说不知道，不要编造答案。

上下文信息：
{context}

问题：{question}

请用中文回答："""
            
            PROMPT = PromptTemplate(
                template=prompt_template,
                input_variables=["context", "question"]
            )
            
            # 创建文档链
            document_chain = create_stuff_documents_chain(llm, PROMPT)
            
            # 创建检索链
            retriever = vectorstore.as_retriever(
                search_kwargs={"k": 3}  # 检索前3个最相关的文档片段
            )
            
            qa_chain = create_retrieval_chain(retriever, document_chain)
            
            return qa_chain
        except Exception as e:
            print(f"创建问答链失败：{str(e)}")
            return None
    
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
            
            # 检索相关文档（新版本LangChain使用invoke方法）
            retriever = vectorstore.as_retriever(search_kwargs={"k": 3})
            # 新版本使用invoke方法替代get_relevant_documents
            try:
                # 尝试使用新版本的invoke方法
                relevant_docs = retriever.invoke(question)
            except AttributeError:
                # 如果失败，尝试旧版本的get_relevant_documents方法
                try:
                    relevant_docs = retriever.get_relevant_documents(question)
                except Exception as e:
                    print(f"[ERROR] 检索文档失败：{str(e)}")
                    return {
                        "answer": "抱歉，检索文档时出错，请稍后重试。",
                        "sources": []
                    }
            except Exception as e:
                print(f"[ERROR] 检索文档失败：{str(e)}")
                return {
                    "answer": "抱歉，检索文档时出错，请稍后重试。",
                    "sources": []
                }
            
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
