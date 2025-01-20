import os
import subprocess
import re
import sys

def extract_commit_info(line):
    # 使用正则表达式匹配 Change 后面的 changelistId 和日期
    match = re.match(r'Change (\d+) on (\d{4}/\d{2}/\d{2})', line.strip())
    if match:
        changelist_id = match.group(1)
        date = match.group(2)
        return changelist_id, date
    return None, None

def get_commit_description(changelist_id):
    # 使用 p4 describe -s 命令获取描述信息
    try:
        result = subprocess.run(['p4', 'describe', '-s', changelist_id], capture_output=True, text=True, check=True)
        output = result.stdout
        description = None
        # 按行分割，跳过第一行
        output_lines = output.splitlines()

        # 按行分割，跳过第一行
        if len(output_lines) > 1:
            # 合并从第二行开始的内容
            info = "\n".join(output_lines[1:]).strip()
            if info.startswith('[测试中]') or info.startswith('[全通过]') or info.startswith('[未通过]') or info.startswith('<enter description here>'):
                return description
            affected_files_index = info.find("Affected files ...")
            if affected_files_index != -1:
                # 提取 Affected files 行之前的内容
                description = info[0:affected_files_index].strip()
                return description
        return description
    except subprocess.CalledProcessError as e:
        print(f"Error fetching description for changelist {changelist_id}: {e}")
        return None

def process_commit_info(input_file, output_file):
    commit_count = 0
    with open(input_file, 'r', encoding='utf-8') as infile, open(output_file, 'w', encoding='utf-8') as outfile:
        for line in infile:
            changelist_id, date = extract_commit_info(line)
            if changelist_id and date:
                description = get_commit_description(changelist_id)
                if description != None:
                    # 将 changelistId、日期和描述信息写入新文件
                    info = f"提交: {changelist_id}\t日期: {date}\t描述: {description}\n"
                    print(info)
                    outfile.write(info)
                    commit_count = commit_count + 1
        print(f"一共记录了 {commit_count} 条提交")
        outfile.write(f"\n一共记录了 {commit_count} 条提交")

if __name__ == "__main__":
    # 检查是否传递了用户名参数
    if len(sys.argv) != 2:
        print("Usage: python process_commit_info.py <username>")
        sys.exit(1)

    # 获取用户名参数
    username = sys.argv[1]

    input_file = "CommitInfo.txt"
    output_file = f"{username}_commit_info.txt"

    # 处理提交信息
    process_commit_info(input_file, output_file)
    print(f"处理完成，结果已保存到 {output_file}")

    # 删除 CommitInfo.txt 文件
    if os.path.exists(input_file):
        os.remove(input_file)