@echo off
echo ������YGC���ͣ�1��basic 2��Behavior 3��Level 4��UI��
set /p ygcType=�������Ӧ����:
set /p ygcName=������YGC����:
set /p useXpl=�Ƿ�ʹ��XPL��y/n��:
YahahaGen.exe ygc %ygcType% %ygcName% %useXpl%
pause