# Universal Agent Guidelines & Walkthrough Specification

This document provides guidelines for all AI coding agents (Antigravity, GitHub Copilot, Cursor, OpenCode, Aider, etc.) operating in this repository.

---

## 1. Core Rule: Walkthrough & Visual Proofing

All agents working on features, bug fixes, or level designs MUST produce or update a walkthrough.md artifact containing:
- **Summary**: Concise breakdown of changes made.
- **Visual Evidence**: Embedded PNG screenshots of level maps (logs/*_preview.png) and sprite contact sheets (sprites-review.png). Use carousel blocks for multi-slide previews.
- **Automated Verification Results**: Proof of passing tests from .\test-game.ps1 -Validate and .\test-game.ps1 -Replay.
- **How to Play**: Commands to run the game locally (play-game.bat or .\test-game.ps1).

---

## 2. 4-Tier Verification Suite

Before marking any task complete, agents MUST run:

```powershell
# Tier 1: Level Nodes & Jump Gap Reachability Validator
.\test-game.ps1 -Validate

# Tier 2: Pixel Art Crispness & Lossless Import Audit
.\test-game.ps1 -Pixel

# Tier 3: Render Map & Sprite Screenshots
python tools/python_scripts/generate-sprites.py
.\test-game.ps1 -Preview

# Tier 4: GDScript Unit Test Quality Gate (TDD Runner)
.\test-game.ps1 -Test

# Tier 5: Autonomous Physics Playtest Bot Replay
.\test-game.ps1 -Replay
```

---

## 3. Project Conventions

- **Viewport**: 480x270 resolution, gl_compatibility renderer, 	exture_filter = 1 (Nearest).
- **Procedural Assets**: 57 PNG frames in generate-sprites.py, 7 chiptune WAVs in generate-sfx.py.
- **Autoload Singleton**: GameState (scripts/game_state.gd) manages lives, score, high score, level unlocks, and audio streaming.

---

## 4. Agentic Delegation Primitives

When breaking down tasks, delegating to subagents is highly encouraged to maximize speed, maintain isolated contexts, and run tasks in parallel. Always select the appropriate LLM model for the subagent based on task complexity:

- **flash_lite**: Use for ultra-fast, simple tasks like reading file contents, extracting specific lines of code, or verifying basic conditions.
- **flash**: Use for targeted codebase research, simple refactors, localized bug fixes, and well-scoped asset generation. (This is the default fallback if no model is specified).
- **pro**: Use for complex multi-file reasoning, architectural design, deep debugging of obscure logic bugs, and multi-step planning tasks.

When possible, launch multiple subagents concurrently to bakeoff different approaches or parse large independent systems simultaneously.

## 5. Multi-Model IDE Playbook

When using an IDE that supports manual model switching (via a dropdown or @model command), users and agents should select models based on **empirical performance rather than assumptions**. While models have general reputations, you should conduct quick bakeoffs (testing the same prompt across models) to determine the best efficiency/cost ratio for your specific workflow.

**Empirically Verified Playbook:**
- **Gemini 3.6 Flash (Primary Daily Driver)**: Recommended default orchestrator. Proved faster, cheaper, and generated superior code structure (e.g. O(log N) MinHeap A*) compared to heavier models in empirical testing.
- **Gemini 3.1 Pro (Heavy Fallback)**: Reserved for emergency escalation when a task requires deep context synthesis across dozens of massive files, or when Flash hits a complex logic wall.
- **Claude Sonnet / Opus 4.6 (Manual IDE Option)**: Available in the IDE dropdown for manual side-by-side design or logic comparisons when desired.
- **GPT-OSS 120B (Medium)**: Quick fallback for boilerplate code generation.
