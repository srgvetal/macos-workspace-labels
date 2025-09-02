# Space Labels for macOS (Hammerspoon)

## Why this exists
I often juggle multiple parallel projects. macOS Mission Control still calls desktops “Desktop 1, 2, 3…”, which makes context-switching harder than it should be—you can’t give workspaces meaningful names.

This repo is a lightweight, cosmetic workaround: a Hammerspoon script that lets you **label Spaces**, display the current label in the menubar and banner, switch between them quickly, and rename them on the fly.

If you find this useful, please star the repo, share it, and let’s nudge Apple to make workspace naming a **native feature**.

---

## Key Features

### 🖥 Core Features
- **Name your Spaces** — give each desktop a meaningful label instead of “Desktop 1, 2, 3…”.  
- **Menubar integration** — always see your current Space name at a glance.  
- **One-click switching from menubar** — switch Spaces faster than Mission Control; hold **⌥ (Option)** for a numbered view.
- **Visual banner** — a quick, noticeable label at the top showing the Space name whenever you switch.
- **Hotkey support** — press ⌘⌥L to quickly assign or change a Space name.  

### ⚙️ Customization & Workflow
- **Preset label system** — quickly reuse labels with a history-based template list.  
- **Persistent storage** — labels are saved in JSON and restored after reboot.

### 🚀 Advanced Features
- **Multi-monitor support** with smart grouping.  
- **Multi-language support** (en/ru/de/fr/es/pt/ja).  
- **Auto-reload** on system wake and JSON file changes.

---

## Quick install (short version)

1. Install **Hammerspoon**: <https://www.hammerspoon.org/>  
2. Copy `init.lua`, `spaces_labels.lua`, `spaces_labels_lang.lua`, and `spaces-labels.json` into `~/.hammerspoon/`.  
3. Reload Hammerspoon config.  
4. Press **⌘⌥L** to set a label, or click directly on the menubar label.
5. Done — now your Spaces have names! 🎉

---

## Full install (detailed version)

### 1) Install **Hammerspoon** (required)
- Download from <https://www.hammerspoon.org/> or install via Homebrew:
  ```bash
  brew install --cask hammerspoon
  ```
- Launch it once and enable it under  
  **System Settings → Privacy & Security → Accessibility**.

### 2) Add config files
Copy these repo files to `~/.hammerspoon/`:
```
~/.hammerspoon/
  init.lua
  spaces_labels.lua
  spaces_labels_lang.lua  
  spaces-labels.json
```

### 3) Reload config
Click the Hammerspoon menubar icon → **Reload Config**.  
Now you should see your current Space label in the menu bar.

### 4) Rename your Spaces
- Hotkey: **⌘⌥L** → enter a name → label assigned.  
- Or menubar → ⚙ → *Enter manually*.
- Or pick a name directly from menubar → ⚙ → **History** for quick reuse.    
- To remove a label: menubar → ⚙ → *Delete*.

### 5) Use history & presets
Use the history of entered labels, or add your own favorites directly in `spaces-labels.json`:
```json
{
  "presets": ["chat", "planning", "chill", "money", "proj1", "proj2"],
  "labelsBySpaceId": {}
}
```
They will appear in the **History** menu.

### 6) Customize
- Menu bar format: `MENUBAR_TITLE_FORMAT`  
- Hotkey: `HOTKEY_LABEL_EDIT` (default ⌘⌥L)  
- Banner size/position: `BANNER_TEXT_SIZE`, `BANNER_Y_POSITION`, etc.  
- Language: leave `LOCALE` to **auto** or pick from (`"en"`, `"ru"`, `"de"`, `"fr"`, `"es"`, `"pt"`, `"ja"`, `"zh"`).



---

## Contributing
PRs are welcome! Especially for translations and macOS version compatibility.  

If this script helps you, star the repo and spread the word:  
Naming Spaces would massively improve multi-tasking workflows. **Apple should let us name Spaces natively.** Let’s make it happen.

