# Codex External Skill Manager

一个用于管理第三方 Codex skills 的 Windows skill。

它适合这种场景：你想长期使用别人 GitHub 仓库里的 skill，同时希望这些 skill 可以像普通 Git 仓库一样 `pull` 更新，而不是把文件手动复制到 `.codex/skills` 里。

## 它解决什么问题

推荐的管理方式是：

```text
%USERPROFILE%\Documents\Codex\
  external-skills\                 # 外部 Git 仓库集中放这里
    some-skill-repo\
  external-skills.config.json      # 可选：自定义 external-skills 路径
  update-external-skills.ps1       # 统一更新脚本
  external-skills-update-latest.md # 最近一次更新报告

%USERPROFILE%\.codex\skills\
  skill-name -> junction 到 external-skills 里的真实 skill 目录
```

这样做的好处：

- 第三方 skill 保持在 Git 仓库里，方便 `git pull` 更新。
- `.codex/skills` 里只放 junction 链接，不混入外部仓库文件。
- 新增外部仓库后，统一更新脚本会自动扫描并更新。
- Windows 计划任务可以每天自动更新，并生成状态报告。

## 首次安装：Bootstrap

第一次安装时还没有 `$external-skill-manager`，所以需要先运行一次 bootstrap 脚本。安装后，这个仓库会像其他外部 skills 一样放在 Git 目录里，并通过 junction 暴露给 Codex。

推荐先下载、查看，再执行：

```powershell
irm https://raw.githubusercontent.com/yclinhh/codex-external-skill-manager/main/install.ps1 -OutFile install.ps1
notepad .\install.ps1
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

如果你信任脚本，也可以一行安装：

```powershell
irm https://raw.githubusercontent.com/yclinhh/codex-external-skill-manager/main/install.ps1 | iex
```

安装后重启 Codex。

## Git 代理排查

如果 `install.ps1` 能下载，但在 `git clone` 时出现类似错误：

```text
OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to github.com:443
```

通常是 Git 没有走当前代理，或者还保留着旧代理端口。先查看 Git 配置：

```powershell
git config --global --list
```

如果你使用 V2RayN，并且 HTTP 代理端口是 `10808`，推荐设置成通用 Git 代理：

```powershell
git config --global --unset http.https://github.com.proxy
git config --global http.proxy http://127.0.0.1:10808
git config --global https.proxy http://127.0.0.1:10808
```

如果你只想让 GitHub 走这个代理：

```powershell
git config --global http.https://github.com.proxy http://127.0.0.1:10808
```

测试 Git 是否已经能访问 GitHub：

```powershell
git ls-remote https://github.com/yclinhh/codex-external-skill-manager.git
```

如果前一次安装失败留下了不完整目录，先删除后再重新安装：

```powershell
$repo = "$env:USERPROFILE\Documents\Codex\external-skills\codex-external-skill-manager"
if (Test-Path $repo) { Remove-Item -LiteralPath $repo -Recurse -Force }
irm https://raw.githubusercontent.com/yclinhh/codex-external-skill-manager/main/install.ps1 | iex
```

## 自定义安装位置

默认外部 Git 仓库目录是：

```text
%USERPROFILE%\Documents\Codex\external-skills
```

如果你想把外部 skills 放到其他位置，例如 D 盘：

```powershell
irm https://raw.githubusercontent.com/yclinhh/codex-external-skill-manager/main/install.ps1 -OutFile install.ps1
powershell -ExecutionPolicy Bypass -File .\install.ps1 -ExternalSkillsRoot "D:\CodexExternalSkills"
```

安装脚本会写入：

```text
%USERPROFILE%\Documents\Codex\external-skills.config.json
```

后续 `$external-skill-manager` 和统一更新脚本都会从这个配置读取外部 Git 仓库目录。

## 第一次使用

重启 Codex 后，在对话里输入：

```text
$external-skill-manager 初始化
```

它会按推荐流程检查：

- `Documents\Codex` 是否存在
- `external-skills.config.json` 是否存在
- 外部 skill Git 仓库目录是否存在
- `.codex\skills` 是否存在
- junction 是否有效
- 统一更新脚本是否已部署
- Windows 计划任务是否需要创建

## 常用指令

安装一个 GitHub skill：

```text
$external-skill-manager install https://github.com/owner/repo.git
```

查看已安装的外部 skills：

```text
$external-skill-manager list external skills
```

设置每日自动更新：

```text
$external-skill-manager configure scheduled updates
```

自定义外部 Git 仓库目录：

```text
$external-skill-manager set custom external skills path
```

## 更新和报告

统一更新脚本会扫描 `external-skills` 下所有包含 `.git` 的一级目录，并执行：

```text
git fetch --prune
git pull --ff-only
```

更新后会生成：

```text
%USERPROFILE%\Documents\Codex\external-skills-update-status.txt
%USERPROFILE%\Documents\Codex\external-skills-update-latest.md
%USERPROFILE%\Documents\Codex\logs\
```

如果有 skill 更新或更新失败，脚本会弹出 Windows 提示；如果全部已经是最新，则只写报告，不打扰你。

## 仓库结构

```text
install.ps1
skills/
  external-skill-manager/
    SKILL.md
    agents/
      openai.yaml
    scripts/
      install-external-skill.ps1
      list-external-skills.ps1
      setup-scheduled-task.ps1
      update-external-skills.ps1
    references/
      first-run.md
      second-machine-setup.md
      sparse-checkout-long-path.md
      windows-junction.md
```

## 注意事项

- 不建议直接同步整个 `%USERPROFILE%\.codex` 目录到另一台电脑。
- 不建议把第三方 Git 仓库直接 clone 到 `.codex\skills`。
- 删除 skill 时，先确认你删的是 junction 路径，不是外部 Git 仓库本体。
- 对于你不打算修改的第三方 skill，推荐只使用 `git pull --ff-only` 更新。
