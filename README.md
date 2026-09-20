# Ornith-1.5-9B-MTP · KVMem 超长上下文 · 8GB 笔记本实测（128K@42.7 / 210K@36.6）

> EN: Ornith-1.5-9B-MTP with KVMem (KV-in-RAM) on 8GB laptop: 128K@42.7 tok/s, 210K@36.6 tok/s, multi-turn follow-ups in ~1s. Full limits list in start script comments.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**硬件**：RTX 4060 Laptop 8GB · 32GB DDR5 双通道 · Windows 11 · llama.cpp 系 fork

**量化**：IQ4_XS + MTP 头（5.08 GB）

**引擎**：**kvmem-llama.cpp v0.16.0-rc2**（KV 常驻主机内存，GPU 只留预算窗口 + 检索回填；MTP 投机 n_max=3/p-min=0.75，接受率 94-96%）

## 生产配置（start.bat 即仓库内同名文件，零漂移）

```bat
--kvmem --kvmem-budget 32768 --kvmem-gen-reserve 4096 --kvmem-cpu-gb 6 --kvmem-mtp-state snapshots --spec-type draft-mtp -c 131072 -n 4096 --temp 0.7
```

## 实测结果（服务端真实长提示口径）

| 项 | 实测 |
|---|---|
| 128K 全上下文 + MTP | **42.7 t/s** |
| 210K token 上下文 | 36.6 t/s（预填 1519） |
| 多轮（66K 文档） | 首载 41.6s → 追问 1.1s / 0.8s |
| 100K 级文档问答 | 端到端可用 |

## 关键发现

- KV 常驻主机内存（--kvmem-cpu-gb 6），GPU 只留 budget+reserve 窗口，按查询检索回相关块——8G 卡跑 200K+ 上下文的可行路径。
- 硬限制清单：-c 262144 会崩（用 131072）；单次生成不得超过 gen-reserve；单槽不并发；不支持三值 Bonsai（type 143）。
- MTP 投机在 KVMem 上反而赚：接受率 94-96%（--kvmem-mtp-state snapshots 必须显式开）。
- 定位=长文档阅读器/预处理节点，不当生产级编码 agent（能力边界见姊妹仓 kat-coder 的 bench）。

## 复现

```bash
python tools/depth_probe_atomic.py <模型.gguf> <端口> <标签> --depths 0,32768,65536,98304,118784 -ctk turbo4 -ctv turbo4 -b 2816 -ub 2816 --threads 24
python tools/test_engines.py
```

## data/ 与 tools/

`data/` 是全部实测数据（summary_*.txt 为权威深度/预填/矩阵总表，每行带时间戳，可复现）。
`tools/` 是探针与判分脚本（服务端真实长提示口径；llama-bench pp512 在本机与真实负载差 2.8 倍，仅作参考）。

## 姊妹仓库（同机同方法论）

- [ornith-1.5-35b-8g-tuning](https://github.com/rui08984-dot/ornith-1.5-35b-8g-tuning)
- [kat-coder-35b-8g-tuning](https://github.com/rui08984-dot/kat-coder-35b-8g-tuning)
- [qwen3.6-35b-8g-tuning](https://github.com/rui08984-dot/qwen3.6-35b-8g-tuning)
- [bonsai2-27b-8g-tuning](https://github.com/rui08984-dot/bonsai2-27b-8g-tuning)
- [zhrp-gemma4-26b-8g-tuning](https://github.com/rui08984-dot/zhrp-gemma4-26b-8g-tuning)

## 致谢

- [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp) — 本体
- [TheTom/llama-cpp-turboquant](https://github.com/TheTom/llama-cpp-turboquant) — turbo4 KV 原始 fork
- [AtomicBot-ai/atomic-llama-cpp-turboquant](https://github.com/AtomicBot-ai/atomic-llama-cpp-turboquant) — 现用构建
- [PrismML](https://huggingface.co/PrismML) — Bonsai 三值 QAT
- KVMem — KV-in-RAM 超长上下文引擎

## License

MIT。模型权重遵循各自发布页许可。
