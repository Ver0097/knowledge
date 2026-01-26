"""
测试DeepSeek API配置
用于验证API密钥是否正确配置
"""
import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def test_deepseek_config():
    """测试DeepSeek API配置"""
    api_key = os.getenv("DEEPSEEK_API_KEY")
    
    if not api_key:
        print("❌ 未找到DEEPSEEK_API_KEY环境变量")
        print("   请创建.env文件并添加：DEEPSEEK_API_KEY=your-api-key")
        return False
    
    if api_key.startswith("sk-"):
        print(f"✅ 找到API密钥：{api_key[:10]}...{api_key[-4:]}")
    else:
        print(f"⚠️ API密钥格式可能不正确：{api_key[:20]}...")
    
    # 尝试导入并初始化
    try:
        from langchain_openai import ChatOpenAI
        
        llm = ChatOpenAI(
            model="deepseek-chat",
            openai_api_key=api_key,
            openai_api_base="https://api.deepseek.com",
            temperature=0.7,
        )
        
        print("✅ DeepSeek API配置成功！")
        print("   可以正常使用智能问答功能")
        return True
        
    except ImportError:
        print("❌ langchain-openai未安装")
        print("   请运行: pip install langchain-openai")
        return False
    except Exception as e:
        print(f"❌ 配置测试失败：{str(e)}")
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("DeepSeek API 配置测试")
    print("=" * 50)
    print()
    
    test_deepseek_config()
    
    print()
    print("=" * 50)
