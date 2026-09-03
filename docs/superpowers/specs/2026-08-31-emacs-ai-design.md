# Emacs AI 编码功能设计

日期：2026-08-31
状态：已获用户批准（分节评审通过）
目标仓库：`~/.emacs.d`（配置经 `init-v2.org` org-babel tangle 生成）
分支：`ai-agent`

## 1. 背景与目标

在 Emacs 中实现 AI 编码智能体能力。用户环境：Emacs 29.2、evil、use-package + package.el（清华镜像）、模块化配置、配置源为 `~/.emacs.d/init-v2.org`（org-babel tangle 生成 `init.el` 与 `lisp/*.el`）。

需求清单（用户确认）：

1. Agent 式编码：AI 可读写文件、执行命令、多轮工具调用，驱动整个项目
2. 对话与代码问答：选区问答、解释、重构，不自动动文件
3. 内联补全：光标处 ghost-text
4. 模型接入：OpenAI 兼容多后端（GLM/DeepSeek/本地 vLLM 等）
5. 插件形态：复用现有生态（gptel/mcp.el 等），不自造插件体系
6. 编辑安全模型：直接写入 + git 兜底
7. 会话存储：前期版本默认全局目录（用户已确认接受）

## 2. 技术路线（已选）

**方案 A：gptel 为核心 + 自写薄胶水层。** 否决的备选：B（aidermacs 外部 CLI——两套子系统、Python 依赖、扩展受制于 aider 体系）；C（完全自研请求层——重造 gptel 已有轮子，YAGNI）。

选型依据（均已核实）：

- gptel（MELPA）：OpenAI 兼容多后端注册、流式、原生 tool-use 多轮循环（`gptel-make-tool` / `gptel-use-tools` / `gptel-pre-tool-call-functions`）、preset 系统、活的 context 机制
- gptel-agent（MELPA，gptel 作者维护）：agent 预设（系统提示 + 文件读写/bash/elisp/web 工具集）、`gptel-plan` 只读规划预设、markdown/org 文件定义子代理（`gptel-agent-dirs` 加载）、子代理上下文隔离
- minuet（MELPA）：ghost-text 补全，`minuet-openai-compatible` 后端走 chat API，任意 OpenAI 兼容服务可用
- mcp.el（MELPA，二期可选）：MCP 服务器桥接进 gptel 工具列表

## 3. 架构

```
┌─────────────────────────────────────────────────┐
│ 胶水层 omy-ai（自写，约 300 行 elisp）            │
│  项目上下文注入 · evil 键位 · 工作流命令          │
│  (/commit /review 选区问答 · AGENTS.md 加载)     │
├──────────────┬──────────────┬───────────────────┤
│ 对话/问答     │ Agent 编码    │ 内联补全           │
│ gptel 原生    │ gptel-agent  │ minuet            │
│ (org buffer,  │ (工具循环,    │ (ghost-text,      │
│  选区问答)    │  子代理)      │  chat API)        │
├──────────────┴──────────────┴───────────────────┤
│ gptel 后端注册（全部 OpenAI 兼容协议）             │
│  zhipu(GLM) · deepseek · 本地 vLLM/Ollama        │
└─────────────────────────────────────────────────┘
```

## 4. 会话管理

**会话本体 = org 文件 buffer。** 对话历史与工具调用记录即 buffer 文本；后端/模型/系统提示存 buffer 局部变量。保存文件即持久化；重新打开 + `gptel-mode` 即完整恢复。多会话 = 多 buffer 并存。

**胶水层补充：**

1. `omy-ai-session` 命令族：按项目打开/新建/切换会话；会话文件存 `~/.local/share/omy-ai/sessions/<项目slug>/<日期-标题>.org`；切换命令列出该项目近期会话
2. `M-x gptel-agent` 开 agent 会话时自动挂载项目根 AGENTS.md 上下文与 agent 预设

**上下文与会话分离：** `gptel-context` 是活上下文——每次请求重新读取文件当前内容，不进入历史。AGENTS.md 走此机制，修改 rules 后无需重开会话。

**子代理隔离：** gptel-agent 子代理为独立请求，不共享主会话历史，报告作为工具结果写回主会话。

**上下文窗口管理（已知差距）：** gptel 无自动 compaction。缓解：手动删旧 turn；`gptel-include-reasoning` 设为不进后续轮；胶水层提供 `omy-ai-compact` 手动压缩命令（当前会话交模型总结为新起点）。自动 compaction 不做（YAGNI）。

**无会话功能：** minuet 补全、commit message、diff 审查均为无状态单发请求。

## 5. 数据流与交互

**Agent 循环：** 用户输入 → gptel 打包（历史 + 活上下文 + 工具清单）→ OpenAI 兼容端点（流式）→ 模型 tool_call → Emacs 内执行 → 结果回传 → 循环至最终回答；全过程渲染在 org buffer。读类工具自动放行；写/bash 自动放行（git 兜底）；`default-directory` 锁项目根。

**问答/重构：** 选区 + 单发请求（可带 context），结果就地插入或新 buffer。

**内联补全：** 插入后 idle 触发（minuet 内置 debounce）→ prefix/suffix 组装 chat 请求 → ghost-text 多候选 → TAB 接受、`M-n/M-p` 切换。仅 `prog-mode`。

**键位（evil，`SPC a` 前缀 + which-key）：**

| 键 | 功能 |
|---|---|
| `SPC a a` | 当前项目开/切 agent 会话 |
| `SPC a s` | 普通 Chat 会话 |
| `SPC a S` | 会话切换列表 |
| `SPC a c` | 生成 commit message（staged diff → kill-ring + 插入） |
| `SPC a r` | 审查当前 diff |
| `SPC a e` | 解释选区 |
| `SPC a f` | 重构当前函数/选区 |
| `SPC a i` | 手动触发内联补全 |
| TAB / `M-n`/`M-p` | 接受 / 切换补全候选 |

## 6. 错误处理与安全

**API 层：** 认证/限流/网络错误由 gptel 统一呈现于 buffer 与 echo area；会话历史即 buffer 文本，不因失败破坏；多后端注册支持一键切换重发。

**工具层：** 工具失败（文件不存在、命令非零退出）作为错误文本回传模型，模型自行修正重试；不做额外干预。

**安全边界：**

1. bash 工具 `default-directory` 锁项目根；不设命令白名单（直写模型已确认，git 兜底）；agent 会话开启时检查项目是否在 git 仓库内，不在则警告并回退"写类工具逐次确认"
2. 敏感文件：gptel-context 默认拒绝 gitignored 文件（`.env` 天然排除）；AGENTS.md 注入仅读项目根一个文件
3. API key 全部来自环境变量（`ZHIPUAI_API_KEY` / `DEEPSEEK_API_KEY`），缺失时后端注册但标记不可用，首次使用提示
4. 补全成本：仅 `prog-mode` + debounce；补全模型用低价档（GLM 用 `glm-4.5-flash`，DeepSeek 用 `deepseek-chat`）

**失败降级：** agent 循环中断后已执行的写操作保留，靠 git checkout 回滚——直写 + git 兜底是本实现写安全模型的恢复边界。

## 7. 文件布局（org-babel tangle 约定）

所有配置改动在 `~/.emacs.d/init-v2.org` 内完成，tangle 生成 el 文件：

```
init-v2.org
├── *** init-ai.el                     → ~/.emacs.d/lisp/init-ai.el
│     后端注册(zhipu/deepseek/vllm)、use-package 声明
│     (gptel/gptel-agent/minuet)、键位、require omy-ai
├── *** omy-ai                         → ~/.emacs.d/site-lisp/omy-ai.el
│     会话管理、AGENTS.md 注入、commit/review/问答/compact 命令
└── init.el 段落追加 (require 'init-ai)

~/.emacs.d/agents/*.md                 # 子代理定义（新增 code-reviewer 等，纯数据文件）
```

`site-lisp/` 已在 load-path。若 `init-package.el` 未配 MELPA 源，在 init-ai.el 段补清华 MELPA 镜像。预计自写总量约 300 行。

## 8. 验证策略

1. **回归：** `emacs --batch -l ~/.emacs.d/init.el` 加载无报错
2. **ERT 单测：** 胶水纯函数——会话路径生成、AGENTS.md 解析注入、staged diff 提取
3. **冒烟清单（真实端点，逐条对应 §5 数据流）：**
   - GLM 后端对话往返成功
   - agent 会话内指令"创建文件并列目录"验证工具循环与写文件
   - python buffer 中 minuet 出现 ghost-text 且可接受
   - `SPC a c` 对 staged diff 生成 commit message
4. 全部冒烟通过即交付

## 9. 二期（本设计不实现）

mcp.el 桥接 MCP 服务器；自动 compaction；项目内会话存储选项。
