# AI Agent v0.1

Emacs 内置的 AI 编码智能体：gptel 多后端对话与工具循环、minuet 内联补全。实现分布在 `lisp/init-ai.el`（后端注册、包声明、键位）与 `site-lisp/omy-ai.el`（会话管理、上下文注入、工作流命令），入口统一挂在 evil leader 键 `SPC a` 下（which-key 可见）。

## Requirements and backends

依赖：Emacs 29.2、gptel、gptel-agent、minuet（MELPA 自动安装）、外部命令 `curl` 与 `git`。

三个后端全部走 OpenAI 兼容 chat API，由 gptel 注册：

| 后端 | 认证 | 模型 |
|---|---|---|
| zhipu（默认） | 环境变量 `ZHIPUAI_API_KEY` | `glm-5.3-flash`（默认）、`glm-4.6`、`glm-4.5`、`glm-4.5-air`、`glm-4.5-flash` |
| deepseek | 环境变量 `DEEPSEEK_API_KEY` | `deepseek-chat`、`deepseek-reasoner` |
| vllm（本地，可选） | 无需 key | 启动本地 vLLM 后以 `/v1/models` 返回为准，`gptel-menu` 临时切换 |

- 默认后端 zhipu，默认模型 `glm-5.3-flash`（智谱 coding-plan 端点）。
- `glm-5.3-flash` 的请求固定携带 `thinking: disabled`：GLM 5.x 交错思考输出与 gptel 的块解析冲突，按智谱官方参数禁用思考。
- 后端与模型随时 `M-x gptel-menu` 切换。
- `ZHIPUAI_API_KEY` 与 `DEEPSEEK_API_KEY` 都未设置时，Emacs 启动后在 echo area 提示 AI 功能不可用。

## Project chat sessions

| 键 | 功能 |
|---|---|
| `SPC a s` | 为当前项目新建会话 |
| `SPC a S` | 列出并打开当前项目的既有会话（最新在前） |
| `SPC a C` | 把当前会话压缩为交接摘要，重置为新起点 |

- 会话文件按项目分目录存放：`$XDG_DATA_HOME`（缺省 `~/.local/share`）下的 `omy-ai/sessions/<项目slug>/<时间戳>-<标题>.org`。项目判定用 projectile，不在项目内时回退当前目录。
- `SPC a s` 提示输入标题（回车默认 `session`）；新会话预写 backend/model 文件属性（恢复时无警告，文件自述创建时的后端与模型），光标直接停在 `*** ` 提示处。
- 会话即 org 文件：对话与工具调用记录就是 buffer 文本，backend/model 存在文件属性里。保存即持久化，重新打开（`SPC a S` 或 `M-x gptel-mode`）即恢复；多会话 = 多 buffer 并存。
- 没有会话时 `SPC a S` 报错，提示先用 `SPC a s` 新建。
- `SPC a C` 仅在 gptel 会话 buffer 内可用：整段历史交给模型总结为交接摘要（目标、已做决定、当前状态、下一步，保留关键文件路径与命令），buffer 重置为摘要新起点。gptel 无自动 compaction，长会话靠本命令或手动删除旧 turn 收缩上下文。

## Chat buffer behavior

- 用户输入以 org 三级标题 `*** ` 开头（gptel 提示前缀），AI 回复跟在提示下方；`C-c RET` 发送。AI 输出保留原生 markdown，不做 org 转换。
- 会话 buffer 使用比例字体与整窗软折行（`visual-line-mode`，并显式关闭 `visual-fill-column-mode`，文字吃满窗口宽度）；代码块分隔线以 80% 高度灰字弱化显示。
- 流式输出期间，所有显示该 buffer 的窗口自动跟随最新文本（挂在 `gptel-post-stream-hook` 上）。
- 每条回复完成后：只展开该回复范围内的 `#+begin_reasoning` 思考块，并把窗口与光标带到下一条 `*** ` 提示处。
- 思考内容默认仍写进 buffer 展示，但不进入后续轮次请求（`gptel-include-reasoning` 为 `ignore`）。

## Agent workflow commands

| 键 | 命令 | 功能 |
|---|---|---|
| `SPC a a` | `omy-ai-agent` | 为当前项目打开 agent 会话（文件读写/bash 等工具循环） |
| `SPC a p` | `omy-ai-plan` | 为当前项目打开只读规划会话（gptel-plan 预设：仅 Read/Grep/Glob/web/子代理，产出实施计划不写文件） |
| `SPC a c` | `omy-ai-commit` | staged diff → commit message，复制进 kill-ring 并在 echo 区显示 |
| `SPC a r` | `omy-ai-review` | 审查 staged diff，结果在 `*omy-ai review*` |
| `SPC a e` | `omy-ai-explain` | 解释当前选区，结果在 `*omy-ai explain*` |
| `SPC a f` | `omy-ai-refactor` | 重构当前选区（保持外部行为，只返回代码），结果在 `*omy-ai refactor*` 供检查后替换 |

- `SPC a a` 打开的 agent 会话以项目根为工作目录。项目在 git 工作树内时，写类工具免逐次确认（直接写入，git 回滚兜底），并自动把项目根 `AGENTS.md` 注入为活上下文——每次请求重读文件当前内容，修改规则无需重开会话。不在 git 仓库内则保持逐次确认，并 echo 提示。
- `SPC a p` 与 `SPC a a` 共用同一入口逻辑（`omy-ai--open-agent`），仅把 preset 换成包内自带的 `gptel-plan`：AGENTS.md 注入与 git 免确认策略完全一致，只换工具集与系统提示。会话 header-line 的 [Agent]/[Plan] 按钮可在两种 preset 间随时切换。
- 子代理定义从 `~/.emacs.d/agents/*.md` 与 gptel-agent 包自带 `agents/` 目录加载（两者都在 `gptel-agent-dirs` 里），在 agent 会话里点名调用，报告作为工具结果写回主会话。自带的只读 `code-reviewer`（正确性、边界、并发、安全、测试缺口，按严重程度输出中文报告，无问题明确 LGTM）之外，包内还预置 `executor`（自主执行多步任务）、`researcher`（联网与代码库调研）、`introspector`（Elisp/Emacs API 内省），开箱即用。
- commit/review/explain/refactor 都是无状态单发请求：不走会话历史，使用当前默认后端与模型。commit 与 review 要求先 `git add`；不在 git 仓库或没有 staged 改动时直接报错。
- `SPC a C`（会话压缩）同为单发请求，见 Project chat sessions。

## Inline completion

- minuet ghost-text 补全：走 zhipu 同一端点与 `ZHIPUAI_API_KEY`，模型 `glm-5.3-flash`。
- 所有 `prog-mode` buffer 自动启用自动建议（0.4s debounce、1.0s throttle 限频）；`SPC a i` 可手动立即触发一次。
- 建议出现后按 `TAB` 接受；补全请求携带 `thinking: disabled`，关闭思考以降低延迟。

## Safety and limits

- 写入模型 = 直接写入 + git 兜底：agent 循环中断后已执行的写操作保留，用 git（`checkout`/`revert` 等）回滚——git 回滚就是写操作的恢复边界。免确认直写仅在 git 工作树内生效，否则逐次确认。
- `AGENTS.md` 注入只读项目根这一个文件；gptel-context 默认拒绝 gitignored 文件（`.env` 等天然排除）。
- API key 只从环境变量读取（`ZHIPUAI_API_KEY` / `DEEPSEEK_API_KEY`），不写入配置；都缺失时启动警告。
- 内联补全仅在 `prog-mode` 触发，带 debounce/throttle 限频，并关闭思考控制延迟。
- 无自动上下文压缩：长会话用 `SPC a C` 手动压缩，或直接删除 buffer 里的旧 turn。
