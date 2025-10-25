# Space Labels for macOS (Hammerspoon)

## Why this exists
I often juggle multiple parallel projects. macOS Mission Control still calls desktops “Desktop 1, 2, 3…”, which makes context-switching harder than it should be—you can’t give workspaces meaningful names.

This repo is a lightweight, cosmetic workaround: a Hammerspoon script that lets you **label Spaces**, display the current label in the menubar and banner, switch between them quickly, and rename them on the fly.

If you find this useful, please star the repo, share it, and let’s nudge Apple to make workspace naming a **native feature**.

---

## Key Features

### 🖥 Core Features
- **Name your Spaces** — assign meaningful labels to desktops you choose, instead of “Desktop 1, 2, 3…”.  
- **Visual banner** — a quick, noticeable label at the top showing the Space name whenever you switch.
- **Menubar integration** — always see your current Space name at a glance.  
- **One-click switching from menubar** — press, roll down, and release the mouse on the desired name – faster than Mission Control.
- **Hotkey support** — press ⌘⌥L to quickly assign or change a Space name.  

### ⚙️ Customization & Workflow
- **Preset label system** — flexible reuse of labels from history or your own custom presets. 
- **Persistent storage** — labels are saved in an easy-to-read and editable JSON and restored after reboot. 
- **MC numbering view** — hold ⌥ while clicking the menubar label to display Spaces with Mission Control numbering.

### 🚀 Advanced Features
- **Multi-monitor support** — smart grouping across displays.
- **Multi-language support** — en / ru / de / fr / es / pt / ja / zh.
- **Auto-reload** — triggered on system wake and JSON changes.

### 🧪 ALPHA Feature — Mission Control
- **Mission Control overlay labels** — shows Space labels directly inside Mission Control (**F3** / **Ctrl + ↑** to show)

---

## Quick install (short version)

1. Install **Hammerspoon**: <https://www.hammerspoon.org/>  
2. Copy `init.lua`, `spaces_labels.lua`, `spaces_labels_lang.lua` and `spaces_labels_misson_control_show_alpha.lua` into `~/.hammerspoon/`.  
3. Reload Hammerspoon config.  
4. Press **⌘⌥L** to set or rename a label.  
5. Click the menubar label to switch Spaces or set a quick label.
6. Press **F3** / **Ctrl + ↑** to show Space labels directly inside Mission Control (**alpha** feature).  
   See more details in **Full install → section 6**.
7. Done — now your Spaces have names! 🎉

---

## Full install (detailed version)

### Setup

#### 1) Install **Hammerspoon** (required)
- Download from <https://www.hammerspoon.org/> or install via Homebrew:
  ```bash
  brew install --cask hammerspoon
  ```
- Launch it once and enable it under  
  **System Settings → Privacy & Security → Accessibility**.

#### 2) Add config files
Copy these repo files to `~/.hammerspoon/`:
```
~/.hammerspoon/
  init.lua
  spaces_labels.lua
  spaces_labels_lang.lua
  spaces_labels_misson_control_show_alpha.lua
```

#### 3) Reload config
Click the Hammerspoon menubar icon → **Reload Config**.  
Now you should see your current empty Space label in the menu bar as symbols **“ “**.

---

### Usage

#### 4) Rename your Spaces
- Hotkey: **⌘⌥L** → enter a name → label assigned.  
- Or menubar → ⚙ → *Enter manually*.  
- To remove a label: use hotkey **⌘⌥L** → clear the name → press *Enter*.
- Or menubar → ⚙ → *Delete*.
- After some time using it, pick a name directly from menubar → ⚙ → **History** or **Presets** for quick reuse.

#### 5) Use history & presets
The system is flexible: you can reuse labels from history or define your own presets.  
They are stored in `spaces-labels.json` (created automatically on first launch, can be opened from the submenu via *Edit presets*).

**Example file:**
```json
{
  "Presets": [
    "chat",
    "proj1",
    "proj2",
    "browsing",
    "calendar",
    "finance",
    "chill"
  ],
  "History": [],


  "labelsBySpaceId": {}
}
```

**Preset ideas:**
- `chat` — messengers, Slack, Discord  
- `proj1`, `proj2` — replace with project or task names  
- `browsing` — research w/o projects link, web, news  
- `calendar` — planning, scheduling, notes, calendar apps  
- `finance` — banking, invoices, sheets  
- `chill` — music, video, downtime  

💡 *Tip: Remember, you can assign or rename a Space on the fly — as fast as your thoughts — with **⌘⌥L**. If the name proves useful, add it to your presets for permanent reuse.*  

#### 6) 🧪 Mission Control overlay labels (alpha)
- Press **F3** / **Ctrl + ↑** to show Space labels directly inside Mission Control. **Esc** or mouse click hides the labels.  
- Coordinates are approximate and may differ on some displays, and behavior may be inconsistent in the *expanded* Mission Control view — adjust numeric values at the top of the Lua file if needed.  
- **Manual calibration required:** it looks as each user needs to fine-tune numeric parameters once for their own language, display and resolution to align labels properly.  
- **Customization:** adjust numeric values at the top of `spaces_labels_misson_control_show_alpha.lua` — mainly `MC_COLLAPSED_SPACE_WIDTH`, `MC_COLLAPSED_LEFT_OFFSET`, `MC_EXPANDED_SPACE_WIDTH`, and `MC_EXPANDED_LEFT_OFFSET` to align labels precisely for your language, screen and resolution.  
- To **disable**: comment out or delete the `require("spaces_labels_misson_control_show")` line in `~/.hammerspoon/init.lua`.

#### 7) Customize in `spaces_labels.lua`
- Menu bar format: `MENUBAR_TITLE_FORMAT`  
- Hotkey: `HOTKEY_LABEL_EDIT` (default ⌘⌥L)  
- Banner size/position: `BANNER_TEXT_SIZE`, `BANNER_Y_POSITION`, etc.  
- Language: leave `LOCALE` to **auto** or pick from (`"en"`, `"ru"`, `"de"`, `"fr"`, `"es"`, `"pt"`, `"ja"`, `"zh"`).

---

## ⚠️ Alpha Feature MC labels limitations & call for contributors

- **Approximate coordinates.** Labels are positioned heuristically; alignment may vary across resolutions, scaling modes, language locales, and number of Spaces.
- **Expanded MC behavior.** In the *expanded* Mission Control view, label placement can be **inconsistent** due to animation/layout differences.
- **Gestures unsupported.** Classic Mission Control gestures (three-/four-finger swipe, pinch) are not detected by Hammerspoon; use **F3 / Ctrl + ↑**.

### 🤝 Join the improvement
Want to help refine this feature?
**Pull requests** improving position accuracy, auto-calibration, or gesture detection are highly appreciated.  

---

## Contributing
PRs are welcome! Especially for translations and macOS version compatibility.  

If this script helps you, star the repo and spread the word:  
Naming Spaces would massively improve multi-tasking workflows. **Apple should let us name Spaces natively.** Let’s make it happen.

