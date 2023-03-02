@echo off
echo 请输入YGC类型（1：basic 2：Behavior 3：Level 4：UI）
set /p ygcType=请输入对应数字:
set /p ygcName=请输入YGC名称:
set /p useXpl=是否使用XPL（y/n）:
YahahaGen.exe ygc %ygcType% %ygcName% %useXpl%
pause