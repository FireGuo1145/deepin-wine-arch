#!/bin/python3

import subprocess

def check_env():
    deps = [
        'ruamel.yaml',
        'pandas',
        'openpyxl'
    ]

    try:
        from ruamel.yaml import YAML
        import pandas as pd
        import openpyxl
    except ImportError as e:
        print(f"缺少依赖 {e.name}，将使用 pip3 安装缺失的依赖:")
        args = [ '/usr/bin/pip3', 'install', '--user', '--prefer-binary' ]
        args += deps
        print(' '.join(args))
        print('\n')

        subprocess.run(args)
check_env()

import os
import threading
import sys
import time
from pathlib import Path
import json
import argparse
import shutil
from ruamel.yaml import YAML
import os
import platform

from ai_screenshot_analy import analyze_screenshot
from parse_test_yamls_res import YamlTesterResultParser

root_path = Path(__file__).resolve().parent.parent.parent
bottle_path = os.environ.get("WINEPREFIX", os.path.join(Path.home(), "my_test"))
test_py = f"{root_path}/appdata/tools/yaml-tester/test_yaml.py"

def get_complete_dir(yaml_file_path):
    """
    将已经测试完成的 yaml 文件移动到 complete_yamls 目录，方便后续
    中断后继续之前未完成的测试
    """
    complete_dir = Path(yaml_file_path)
    if complete_dir.is_file():
        complete_dir = complete_dir.parent
    complete_dir = complete_dir.with_name(f'complete_{complete_dir.name}')

    complete_dir.mkdir(exist_ok=True)
    return complete_dir.as_posix()

def recheck_failed_yamls(yaml_dirs):
    """
    进行失败后的复测
    """
    result_dir = Path("./result")
    if not result_dir.is_dir():
        return

    complete_dir = get_complete_dir(yaml_dirs)
    failed_yamls = []
    for result_json in result_dir.glob("*.json"):
        with open(result_json, "r") as f:
            result = json.load(f)
            try:
                failed_yaml = result_json.with_suffix(".yaml").name
                src_yaml = f"{complete_dir}/{failed_yaml}"
                if result["status"] != "ok" and Path(src_yaml).is_file():
                    failed_yamls.append(failed_yaml)
            except Exception as e:
                print(f"解析 {result_json} 失败，{e}")

    print(f"有 {len(failed_yamls)} 个文件运行失败，将重新复测...")

    for failed_yaml in failed_yamls:
        if not failed_yaml:
            continue
        subprocess.run([ "rm", "-v", f"{complete_dir}/{failed_yaml}" ])

    main(yaml_dirs, recheck=False)

def process_file(file_path):
    complete_dir = get_complete_dir(file_path)
    name = Path(file_path).name
    if Path(complete_dir).joinpath(name).exists():
        print(f"{file_path} 已经测试完成，跳过")
        return

    process = subprocess.Popen(["/usr/bin/python3", test_py, file_path])
    process.communicate()
    complete_dir = get_complete_dir(file_path)
    subprocess.run([ "cp", "-v", file_path, complete_dir ])

def get_screenshot_brief(yaml_file_name):
    """
    使用 ai 获取截图的简要描述
    """
    screenshots = Path(yaml_file_name).with_suffix(".png").name
    path = Path("./screenshots").joinpath(screenshots)

    if not path.exists():
        return

    try:
        result = analyze_screenshot(os.getenv('AI_APIKEY'), path.absolute().as_posix())
        print(f"分析截图内容{screenshots} -> {result}")
        if result:
            os.makedirs(f"./screenshots/{result['type']}", exist_ok=True)
            with open(f"./screenshots/{result['type']}/info.txt", "a") as f:
                f.write(f"{yaml_file_name}: {result['description']}\n")
                f.flush()
            os.rename(
                path.absolute().as_posix(),
                f"./screenshots/{result['type']}/{path.name}"
            )
    except Exception as e:
        print(f"分析截图内容失败，{e}")

def record_testing_yaml(file_path):
    with open("testing-yaml.txt", "w") as f:
        f.writelines( [ file_path ] )

def dump_result_excel():
    """
    测试完成后，将测试结果导出成 excel 表格
    """
    result_dir = Path("./result")
    if not result_dir.is_dir() or len(list(result_dir.iterdir())) == 0:
        print("没有测试结果，跳过生成 excel")
        return

    res = YamlTesterResultParser()
    res.load_result_dir(result_dir.as_posix())

    filename = f"测试结果-{time.strftime('%Y-%m-%d-%H-%M-%S')}.xlsx"
    res.to_excel(f"./{filename}")

    print(f"测试结果已导出到 {filename}")

def main(folder_path, recheck=True):
    if os.path.isdir(folder_path):
        for file_name in os.listdir(folder_path):
            file_path = os.path.join(folder_path, file_name)
            if os.path.isfile(file_path):
                record_testing_yaml(file_path)
                process_file(file_path)
                get_screenshot_brief(file_path)
        if recheck:
            # 测试完成后，对失败的 yaml 文件进行一轮复测
            recheck_failed_yamls(folder_path)
    elif os.path.isfile(folder_path):
        file_path = folder_path
        record_testing_yaml(file_path)
        process_file(file_path)
        get_screenshot_brief(file_path)

    else:
        print("请输入测试的yml文件或者目录")

def parse_wine_logs(winelogs_dir, save=False) -> dict:
    """
    解析 wine 日志，获取缺少的组件
    """
    missing_components = {}

    for file_name in os.listdir(winelogs_dir):
        for logname in os.listdir(os.path.join(winelogs_dir, file_name)):
            logpath = os.path.join(winelogs_dir, file_name, logname)
            proc = subprocess.Popen([ "/opt/apps/deepin-wine-builder/files/bin/winelogparser", logpath ], stdout=subprocess.PIPE)
            stdout, _ = proc.communicate()
            try:
                components = json.loads(stdout)
                if components:
                    missing_components[Path(file_name).with_suffix(".yaml").name] = components
            except Exception as e:
                print(f"解析 {file_name} 失败，{e}")

    if save:
        with open("missing_components.json", "w") as f:
            f.write(json.dumps(missing_components, indent=4, ensure_ascii=False))

    return missing_components

def fix(folder_path):
    # 创建保存正在修复的yml文件的目录
    _folder_path = Path(folder_path)
    _fixing_path = _folder_path.with_name(_folder_path.name + "_fixing")
    os.makedirs(_fixing_path.as_posix(), exist_ok=True)

    # 解析 wine 日志
    print("正在解析日志...")
    missing_components = parse_wine_logs("winelogs", save=True)

    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.indent(mapping=2, sequence=4, offset=2)

    # 创建测试 yaml 文件
    for yamlname in missing_components.keys():
        try:
            with open(_folder_path.joinpath(yamlname).as_posix(), "r") as f:
                yaml_content = yaml.load(f)

                # 添加缺失的组件
                added_components = yaml_content["Dependencies"]
                for comp in missing_components[yamlname]:
                    if comp not in added_components:
                        added_components.append(comp)
                yaml_content["Dependencies"] = added_components

                # 保存添加组件后的 yaml 文件
                with open(_fixing_path.joinpath(yamlname).as_posix(), "w") as f:
                    yaml.dump(yaml_content, f)
        except Exception as e:
            print(f"修复 {yamlname} 失败，{e}")

    # 进行测试
    print("正在测试修复后的yml文件...")
    main(_fixing_path.as_posix())

if __name__ == "__main__":

    if not shutil.which('scrot'):
        print("请先安装 scrot")
        exit(1)

    parser = argparse.ArgumentParser(
        usage="测试yml文件，如果要使用 ai 分析截图，请先设置环境变量:\n\n"
                    "export AI_APIKEY=<your_api_key>\n"
                    "export AI_BASEURL=https://example.com/chat/v1\n"
                    "export AI_MODEL=chatglm3-130b\n"
    )
    sub_parsers = parser.add_subparsers(dest="command")

    test_parser = sub_parsers.add_parser("test")
    test_parser.add_argument("yamlpath", type=str, help="yml文件或者目录")

    fix_parser = sub_parsers.add_parser("fix")
    fix_parser.add_argument("yamlpath", type=str, help="yml文件或者目录")

    args = parser.parse_args()

    try:
        if args.command == "test":
            main(args.yamlpath)
            dump_result_excel()
        elif args.command == "fix":
            fix(args.yamlpath)
    finally:
        if os.path.exists("testing-yaml.txt"):
            os.remove("testing-yaml.txt")
