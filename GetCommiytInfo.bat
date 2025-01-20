@echo off
setlocal enabledelayedexpansion

REM 初始化变量
set CUR_PORT=
set CUR_USER=

REM 检查 P4PORT
echo 检查 P4PORT...
echo.

REM 获取当前的 P4PORT
for /f "tokens=2 delims==" %%i in ('p4 set -s P4PORT') do (
    for /f "tokens=1" %%j in ("%%i") do (
        set CUR_PORT=%%j
    )
)

REM 获取当前的 P4USER
for /f "tokens=2 delims==" %%u in ('p4 set -s P4USER') do (
    for /f "tokens=1" %%v in ("%%u") do (
        set CUR_USER=%%v
    )
)

REM 显示当前的 P4PORT 和 P4USER
echo 当前 P4PORT: %CUR_PORT%
echo 当前 P4USER: %CUR_USER%
echo.

REM 检查 P4PORT 是否正确
if "%CUR_PORT%" == "p4.aki.kuro.com:1666" (
    echo P4PORT 设置正确。
    echo.
    goto confirm_username
) else (
    echo 检查到 P4PORT 错误，正在重新设置...
    echo.
    goto set_p4port
)

:confirm_username
REM 让用户确认 P4USER 是否正确
set /p confirm=是否获取当前用户%CUR_USER%的提交记录 (输入'Y'或'N'): 
if /i "%confirm%"=="Y" (
    echo 获取当前用户 %CUR_USER% 的提交记录。
    echo.
    goto get_commit_info
) else if /i "%confirm%"=="N" (
    echo 设置用户名。
    echo.
    goto set_username
) else (
    echo 输入信息无效，请输入'Y'或'N'
    goto confirm_username
)

:set_username
REM 设置新的 P4USER
set /p username=请输入需要获取提交记录的用户的用户名 (如: zhangsan): 
set CUR_USER=%username%
echo.
goto confirm_username

:set_p4port
REM 设置 P4PORT
echo p4 set P4PORT=p4.aki.kuro.com:1666
p4 set P4PORT=p4.aki.kuro.com:1666
set CUR_PORT=p4.aki.kuro.com:1666
echo P4PORT 已设置为: %CUR_PORT%
echo.
goto confirm_username

:get_commit_info
REM 清空输出文件
set OUTPUT_FILE=CommitInfo.txt
echo. > %OUTPUT_FILE%

:ask_date_range
REM 询问用户是否需要指定日期范围
set /p DATE_RANGE=是否需要指定日期范围 (输入'Y'或'N'):

:process_date_range
set DATE_FILTER=
REM 根据用户选择处理日期范围
if /i "%DATE_RANGE%"=="Y" (
    echo 请指定提交日期范围。
    goto input_start_date
) else if /i "%DATE_RANGE%"=="N" (
    echo 将拉取全部提交信息。
    goto get_user_commit_info
) else (
    echo 输入信息无效，请输入'Y'或'N'
    goto ask_date_range
)

REM 输入开始日期
:input_start_date
set /p START_DATE=请输入开始日期 (格式: YYYY/MM/DD):
if "%START_DATE%"=="" (
    echo 开始日期不能为空，请重新输入。
    goto input_start_date
)

REM 调用 Python 脚本检查日期
python python_scripts\check_date.py "%START_DATE%"
set PYTHON_RESULT=%errorlevel%

REM 根据 Python 脚本的返回值判断日期是否合法
if %PYTHON_RESULT% equ 0 (
    REM 日期合法，不打印提示信息
) else (
    echo 输入的日期非法: %START_DATE%
    goto input_start_date
)

REM 输入结束日期
:input_end_date
set /p END_DATE=请输入结束日期 (格式: YYYY/MM/DD):
if "%END_DATE%"=="" (
    echo 结束日期不能为空，请重新输入。
    goto input_end_date
)

REM 调用 Python 脚本检查日期
python python_scripts\check_date.py "%END_DATE%"
set PYTHON_RESULT=%errorlevel%

REM 根据 Python 脚本的返回值判断日期是否合法
if %PYTHON_RESULT% equ 0 (
    REM 日期合法，不打印提示信息
) else (
    echo 输入的日期非法: %END_DATE%
    goto input_end_date
)

REM 检查日期格式是否正确
echo 开始日期: %START_DATE%
echo 结束日期: %END_DATE%
set DATE_FILTER=@%START_DATE%,@%END_DATE%

REM 拉取指定用户的提交信息
:get_user_commit_info
echo 正在拉取用户 %CUR_USER% 的提交信息...
p4 changes -u %CUR_USER% %DATE_FILTER% > %OUTPUT_FILE%

REM 检查是否成功
if %errorlevel% equ 0 (
    echo 提交信息已成功提取并保存到 %OUTPUT_FILE%
) else (
    echo 拉取提交信息失败，请检查 Perforce 配置和网络连接。
)

REM 调用 Python 脚本处理提交信息
python python_scripts\process_commit_info.py "%CUR_USER%"

:end
echo 脚本执行完毕。
pause