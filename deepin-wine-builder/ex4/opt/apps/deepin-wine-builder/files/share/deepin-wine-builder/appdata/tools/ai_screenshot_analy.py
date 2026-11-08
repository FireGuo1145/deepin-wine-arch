#!/usr/bin/env python3

"""
用来分析截图，返回截图的类型和描述
"""

import requests
import base64
import json
import sys
import os

# 定义提示词
prompt = '''
简单分析这张截图内容，然后以 json 格式输出，输出的字段有：

- type: 代表截图的类型，
  1. 如果是安装程序（setup 或者 installer），界面里明确有“安装”、产品名称、同意协议许可等元素，输出 "安装程序"
  2. 如果截图里出现崩溃或者错误弹窗，输出 "错误弹窗"
  3. 如果截图里的应用没有出现任何界面（黑屏或者白屏），输出 "黑屏或白屏"
  4. 如果是一个正常的应用界面，输出 "正常显示界面"
- description: 对截图内容的描述，在 50 字以内，格式为应用名称 + 描述比如
  "zipper:安装向导界面" 或者 "QQ音乐:应用的崩溃弹窗"，

输出示例：

```
{"type": "安装程序","description": "zipper:安装向导界面"}
```
'''

# API 配置
url = os.environ.get('AI_BASEURL', 'https://ai.uniontech.com/api/v1') + "/chat/completions"
model = os.environ.get('AI_MODEL',"qwen-vl-plus")

def analyze_screenshot(apikey, image_path) -> dict:
    """分析截图并返回JSON格式的结果"""

    # 检查文件是否存在
    if not os.path.exists(image_path):
        print(f"错误：文件 {image_path} 不存在", file=sys.stderr)
        return {}

    # 读取并编码图片
    try:
        with open(image_path, 'rb') as image_file:
            base64_image = base64.b64encode(image_file.read()).decode('utf-8')
    except Exception as e:
        print(f"错误：无法读取图片文件 - {e}", file=sys.stderr)
        return {}

    # 构建请求数据
    request_data = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": [
                    {
                        "type": "text",
                        "text": prompt
                    }
                ]
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/png;base64,{base64_image}"
                        }
                    }
                ]
            }
        ]
    }

    # 设置请求头
    headers = {
        "Authorization": f"Bearer {apikey}",
        "Content-Type": "application/json"
    }

    # 发送请求
    response = requests.post(url, headers=headers, json=request_data)
    try:
        response.raise_for_status()  # 检查HTTP错误
        response = json.loads(response.text)
        response = response['choices'][0]['message']['content']
        # 删除 `{}` 前后的字符串
        if response.find('{') != -1:
            response = response[response.find('{'):]
        if response.find('}') != -1:
            response = response[:response.find('}') + 1]
        return json.loads(response)
    except Exception as e:
        print(f"请求错误：{e}", file=sys.stderr)
        print(f"请求返回：{response}", file=sys.stderr)
        return {}

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法: python3 ai_screenshot_analy.py <图片路径>", file=sys.stderr)
        sys.exit(1)

    image_path = sys.argv[1]
    print(analyze_screenshot(os.getenv("AI_APIKEY"), image_path))
