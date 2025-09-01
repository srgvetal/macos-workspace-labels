# Space Labels for macOS (Hammerspoon)

## Why this exists
I often juggle multiple parallel projects. macOS Mission Control still calls desktops “Desktop 1, 2, 3…”, which makes context-switching harder than it should be—you can’t give workspaces meaningful names.

This repo is a lightweight, cosmetic workaround: a Hammerspoon script that lets you **label Spaces**, shows the current label in the menu bar, and displays a banner when switching Spaces.

If you find this useful, please star the repo, share it, and let’s nudge Apple to make workspace naming a **native feature**.

---

## Quick install (short version)

1. *(Optional)* Install **Hummingbird** for smoother window management.  
2. Install **Hammerspoon**: <https://www.hammerspoon.org/>  
3. Copy `init.lua`, `spaces_labels.lua`, and `spaces-labels.json` into `~/.hammerspoon/`.  
4. Reload Hammerspoon config.  
5. Press **⌘⌥L** to set a label, or click the menubar icon.  
6. Done — now your Spaces have names! 🎉

---

## Full install (detailed version)

### 1) Install **Hummingbird** (optional)
A nice companion tool for window management. Not required, but recommended.

### 2) Install **Hammerspoon** (required)
- Download from <https://www.hammerspoon.org/> or install via Homebrew:
  ```bash
  brew install --cask hammerspoon
  ```
- Launch it once and enable it under  
  **System Settings → Privacy & Security → Accessibility**.

### 3) Add config files
Copy these repo files to `~/.hammerspoon/`:
```
~/.hammerspoon/
  init.lua
  spaces_labels.lua
  spaces-labels.json
```

### 4) Reload config
Click the Hammerspoon menubar icon → **Reload Config**.  
Now you should see your current Space label in the menu bar.

### 5) Rename your Spaces
- Hotkey: **⌘⌥L** → enter a name → banner pops up.  
- Or menubar → ⚙ → *Enter manually*.  
- To remove a label: menubar → ⚙ → *Delete*.

### 6) Use presets & history
Edit `spaces-labels.json` to add your favorite labels:
```json
{
  "presets": ["chat", "planning", "chill", "money", "proj1", "proj2"],
  "labelsBySpaceId": {}
}
```
They will appear in the **History** menu.

### 7) Customize
- Menu bar format: `MENUBAR_TITLE_FORMAT`  
- Hotkey: `HOTKEY_LABEL_EDIT` (default ⌘⌥L)  
- Banner size/position: `BANNER_TEXT_SIZE`, `BANNER_Y_POSITION`, etc.  
- Language: set `LOCALE` (`"en"`, `"ru"`, `"de"`, …).

---

## Contributing
PRs are welcome! Especially for translations and macOS version compatibility.  
If this script helps you, star the repo and spread the word:  
**Apple should let us name Spaces natively.**

---

P.S. If you’re with Apple or know someone there: naming Spaces would massively improve multi-project workflows. Let’s make it happen.
