---
applyTo: '**'
---

# Agent Walkthrough & Visual Proof Standard

## Purpose

Whenever an AI coding agent (Copilot, Cursor, OpenCode, Antigravity, etc.) completes a feature, bugfix, level design, or architectural change, it MUST create or update a `walkthrough.md` document with visual proof and test results to give humans full confidence in the changes.

---

## Walkthrough Document Standard (`walkthrough.md`)

Location: Project root or conversation artifact directory (`walkthrough.md`).

### Required Sections

1. **Executive Summary**: Brief description of the task, problem solved, and core architectural changes.
2. **Visual Proof & Media**:
   - Embed screenshots (`![Caption](path/to/image.png)`) of level layouts, main menu, or UI updates.
   - Use GitHub-Flavored Markdown `carousel` blocks to show sequential state or level maps side-by-side:
     ````carousel
     ![Level 1](path/to/level_1_preview.png)
     Level 1 Overview
     <!-- slide -->
     ![Level 2](path/to/level_2_preview.png)
     Level 2 Overview
     ````
   - Include 4× scale sprite contact sheets (`sprites-review.png`) when art assets change.
3. **Automated Test Results**:
   - Level Validation output (`.\test-game.ps1 -Validate`).
   - Autonomous Replay Bot output (`.\test-game.ps1 -Replay`).
   - Log excerpts proving 0 errors and 0 warnings.
4. **Interactive Playtesting Instructions**:
   - Exact terminal command to launch and play the game locally (`.\test-game.ps1` or `play-game.bat`).

---

## Verification Commands for Agents

Agents must run these verification commands before presenting `walkthrough.md`:

```powershell
# 1. Structural & Jump Reach Validation
.\test-game.ps1 -Validate

# 2. Re-render Visual Level Maps & Sprite Contact Sheets
python generate-sprites.py
python render-level-previews.py

# 3. Autonomous Physics Playtest Replay
.\test-game.ps1 -Replay
```
