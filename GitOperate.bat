@echo off

rem 执行git add .命令
git add .

rem 提交代码,提交信息为当前日期，%date%会获取当前日期
git commit -m "%date%,update Git"

rem 推送代码到远程仓库
git push

pause