@echo off
rem ================================================================
rem  KVMem long-context server (Ornith-1.5-9B-MTP, 256K workspace)
rem  Engine: kvmem-llama.cpp v0.16.0-rc2 (Windows CUDA 13.2.86)
rem  MEASURED 2026-09-19 on this box (4060 Laptop 8G / 32G RAM):
rem    128K full context + MTP : 42.7 t/s decode (acceptance 94-96%)
rem    210K token context      : 36.6 t/s, prefill 1519 t/s
rem    multi-turn on 66K doc   : 1st load 41.6s -> follow-ups 1.1s / 0.8s
rem  WHY: KV lives in host RAM; only a bounded window (budget+reserve)
rem    stays on GPU, retrieval brings back relevant blocks per query.
rem  LIMITS (measured):
rem    - one generation cannot exceed --kvmem-gen-reserve (4096 here)
rem    - -c 262144 crashes the server; use 131072
rem    - --kvmem-mtp-state snapshots is REQUIRED for MTP in server mode
rem      (default 'replay' refuses: GDN replay requires Qwen 27B)
rem    - single-slot: no concurrent requests
rem  USE: long documents + multi-turn Q&A. For agent/code use the 35B bats.
rem  NOTE: does NOT support Bonsai-2 PTQ1_0 (private ggml type 143).
rem  ================================================================
cd /d D:\agent1super\tmp\kvmem\kvmem-v0.16.0-rc2-windows-x86_64-cuda13.2.86\bin
llama-kvmem-server.exe ^
  -m "D:\llm\models\Ornith-1.5-9B-MTP-IQ4_XS.gguf" ^
  --host 127.0.0.1 --port 24560 ^
  -c 131072 -n 4096 ^
  --kvmem --kvmem-budget 32768 --kvmem-gen-reserve 4096 ^
  --kv-dtype q8_0 --kvmem-cpu-gb 6 ^
  --spec-type draft-mtp --spec-draft-n-max 3 --spec-draft-p-min 0.75 ^
  --kvmem-mtp-state snapshots ^
  --temp 0.7
pause
