#!/usr/bin/env python3

import subprocess
import re
import time
import tempfile
import json
import os
import pathlib
import sys

scrot_args = [ 'scrot' ]
try:
    if '--overwrite' in subprocess.check_output([ 'scrot', '--help' ]).decode('utf-8'):
        scrot_args.append('--overwrite')
except subprocess.CalledProcessError:
    pass

_text_to_click = re.compile(r'next|下一步|安装|完成|Finish|Done|OK|Yes|继续|是|确定|立即启动|我同意|Install|I\s*Accept|Agree>|\(Y\)', re.IGNORECASE)

def get_center_point(box) :
    """
    获取中心点坐标
    :param box: [[x1, y1], [x2, y2], [x3, y3], [x4, y4]]
    :return: [x, y]
    """
    _min_x = min(box[0][0], box[1][0], box[2][0], box[3][0])
    _max_x = max(box[0][0], box[1][0], box[2][0], box[3][0])
    _min_y = min(box[0][1], box[1][1], box[2][1], box[3][1])
    _max_y = max(box[0][1], box[1][1], box[2][1], box[3][1])
    return [
        _min_x + (_max_x - _min_x) / 2,
        _min_y + (_max_y - _min_y) / 2
    ]

def click_point(p):
    subprocess.Popen(['xdotool', 'mousemove', str(p[0]), str(p[1]), 'click', '1']).communicate()

def get_arch():
    """
    获取当前系统的CPU架构信息

    返回:
        str: 系统架构字符串 ('x64' 或 'arm64')

    异常:
        RuntimeError: 当系统架构不被支持时抛出
    """
    import platform

    machine = platform.machine().lower()
    system = platform.system().lower()

    # 常见x64架构标识
    x64_identifiers = {'x86_64', 'amd64', 'x64'}
    # 常见arm64架构标识
    arm64_identifiers = {'arm64', 'aarch64' }

    if machine in x64_identifiers:
        return 'x64'
    elif machine in arm64_identifiers:
        return 'arm64'
    else:
        raise RuntimeError(
            f"不支持的架构: {machine} (系统: {system}). "
            "当前仅支持x64和arm64架构"
        )


def press_alt():
    # 按下 alt + y
    # 错误弹窗确认
    subprocess.Popen(['xdotool', 'key', 'alt+y']).communicate()

    # 按下 alt + n
    # 通常为下一步
    subprocess.Popen(['xdotool', 'key', 'alt+n']).communicate()

    # 按下 alt + i
    # 通常为安装
    subprocess.Popen(['xdotool', 'key', 'alt+i']).communicate()

    # 按下 alt + a
    # 通常为同意
    subprocess.Popen(['xdotool', 'key', 'alt+a']).communicate()

    # finish
    subprocess.Popen(['xdotool', 'key', 'alt+f']).communicate()
    subprocess.Popen(['xdotool', 'key', 'alt+x']).communicate()

def capture_and_save_screen():
    """
    根据当前运行的 exe，保存截图
    """
    if not os.path.exists("testing-yaml.txt"):
        return

    with open("testing-yaml.txt") as f:
        yml_path = f.read().strip()

        if not os.path.exists(yml_path):
            return

        screenshot_filename = pathlib.Path(yml_path).with_suffix(".png").name
        os.makedirs("./screenshots/", exist_ok=True)
        save_path = os.path.join("./screenshots/", screenshot_filename)
        try:
            subprocess.run(scrot_args + [save_path], check=True)
        except Exception as e:
            pass

def _get_active_window_rect():
    try:
        proc_out = subprocess.check_output(["xdotool", "getactivewindow", "getwindowgeometry", "--shell"]).decode().strip()
        for line in proc_out.split("\n"):
            if "x=" in line.lower():
                x = int(line.split("=")[1])
            if "y=" in line.lower():
                y = int(line.split("=")[1])
            if "width=" in line.lower():
                width = int(line.split("=")[1])
            if "height=" in line.lower():
                height = int(line.split("=")[1])
        return x, y, width, height
    except Exception as e:
        return None

def _is_active_wine_window(wineprefix_path):
    try:
        window_pid = subprocess.check_output(["xdotool", "getactivewindow", "getwindowpid"]).decode().strip()
        grep_proc = subprocess.Popen(["grep", "-q", "ntdll.dll", f"/proc/{window_pid}/maps"])
        grep_proc.wait()
        is_wine_app = (grep_proc.returncode == 0)
        if not wineprefix_path:
            return is_wine_app
        elif is_wine_app:
            # 运行 xprop，检查 __wine_prefix
            window_id = subprocess.check_output(["xdotool", "getactivewindow"]).decode().strip()
            xprop_output = subprocess.check_output(
                ["xprop", "-id", window_id, "__wine_prefix"],
                stderr=subprocess.DEVNULL
            ).decode().strip()
            # __wine_prefix(STRING) = "/home/uos/.wine"
            window_wine_prefix = xprop_output.split("=")[1].strip()
            window_wine_prefix = window_wine_prefix.strip('"')
            return os.path.samefile(window_wine_prefix, wineprefix_path)
        else:
            return False
    except Exception as e:
        return False

def click_next(check_is_wine_process = False, wineprefix = None):
    """
    点击下一步
    :return:
    """
    print("Start ocr-autoclick-setup...")
    while True:
        if check_is_wine_process and not _is_active_wine_window(wineprefix):
            time.sleep(2)
            continue

        capture_and_save_screen()
        _, tmpfile = tempfile.mkstemp(suffix=".png")

        # 截图当前窗口
        subprocess.Popen(scrot_args + ['--focused', tmpfile]).communicate()
        subprocess.Popen([
            os.path.dirname(os.path.abspath(__file__)) + f"/bin/ocr-json-{get_arch()}",
            tmpfile,
            "/tmp/ocr-json.json"
        ], stdout=subprocess.DEVNULL).communicate()

        if os.path.exists(tmpfile):
            os.remove(tmpfile)

        try:
            x, y, _, _ = _get_active_window_rect()

            with open("/tmp/ocr-json.json") as f:
                stdout = json.loads(f.read())
                for textbox in stdout:
                    if _text_to_click.search(textbox['text']):
                        _text_x, text_y = get_center_point(textbox['box'])

                        # 截图内的位置 + 窗口位置 = 窗口内的位置
                        click_point([x + _text_x, y + text_y])

                press_alt()

        except Exception as e:
            print("ocr-json error: ", e)

        if os.path.exists("/tmp/ocr-json.json"):
            os.remove("/tmp/ocr-json.json")

        time.sleep(2)

if __name__ == "__main__":
    check_wine_process = False
    wine_prefix = None

    if len(sys.argv) >= 2:
        if sys.argv[1] == '--wine':
            check_wine_process = True
            if len(sys.argv) >= 3:
                wine_prefix = sys.argv[2]
            else:
                wine_prefix = os.environ.get("WINEPREFIX")

    click_next(check_wine_process, wine_prefix)
