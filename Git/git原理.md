## Git

### 工作区域

> Git本地具有三个工作区域，即工作目录、暂存区、本地仓库
>
> 除此之外还有远程仓库



#### 工作区域

即构建项目或文件夹的本地目录

#### 暂存区

**临时**存放项目代码的地方，事实上只是一个文件，用以保存即将提交的文件信息

#### 本地仓库

本地存储代码的仓库，保存有提交的所有版本的数据





在工作目录下初始化后有隐藏文件`.git`



项目提交流程

- 本地工作区域将代码`git add .`到暂存区
- `git commit -m`将项目从暂存区提交到本地仓库
- git push将本地仓库里的项目推送到远程仓库（github、gitee、gitlab等）



### 基本命令

```bash
#查看当前分支的状态，包括已修改、已暂存和未跟踪的文件列表。它还会提示是否有未提交的更改。
git status

#将所有文件文件添加到暂存区
git add .

#将暂存区中的内容提交到本地仓库
git commit -m "消息内容"

git push

#查看当前分支的提交记录
git log

#显示本地仓库中所有的文件
git ls-files
```



### 忽略文件

有时有些文件我们并不像提交到仓库或暂存区中，则可以在项目中添加`.gitignore`文件来忽略那些我们不想提交的文件

```bash
*.txt     #忽略所有以.txt结尾的文件
!lib.txt  #忽略的文件里排除lib.txt
/temp     #忽略
build/    #忽略build目录下的文件
doc/*.txt  #忽略doc文件夹下的.txt文件
```



### 分支

```bash
git branch   #获取当前所有分支
git branch -r #获取远程所有分支 
git branch <分支名>  #创建分支,但依然停留在当前分支，例如创建dev分支  git branch dev
git checkout <分支名> #切换分支
git checkout -b <分支名> #创建分支并切换
git branch -d <分支名> #删除本地分支
git push origin --delete <分支名> #删除远程分支
```

