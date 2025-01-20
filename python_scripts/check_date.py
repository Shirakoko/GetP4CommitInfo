import sys
from datetime import datetime

def is_valid_date(date_str):
    try:
        # 尝试将字符串转换为日期对象
        datetime.strptime(date_str, "%Y/%m/%d")
        return True
    except ValueError:
        # 如果转换失败，说明日期不合法
        return False

if __name__ == "__main__":
    # 获取批处理脚本传递的日期参数
    if len(sys.argv) != 2:
        print("Usage: python check_date.py <date>")
        sys.exit(1)

    date_str = sys.argv[1]
    if is_valid_date(date_str):
        sys.exit(0)  # 返回 0 表示合法
    else:
        sys.exit(1)  # 返回 1 表示非法