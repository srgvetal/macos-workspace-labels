# Space Labels for macOS (Hammerspoon)

## Why this exists
I often juggle multiple parallel projects. macOS Mission Control still calls desktops “Desktop 1, 2, 3…”, which makes context-switching harder than it should be—you can’t give workspaces meaningful names.

This repo is a lightweight, cosmetic workaround: a Hammerspoon script that lets you **label Spaces**, display the current label in the menubar and banner, switch between them quickly, and rename them on the fly.

If you find this useful, please star the repo, share it, and let’s nudge Apple to make workspace naming a **native feature**.

---

## Key Features

### 🖥 Core Features
- **Name your Spaces** — assign meaningful labels to desktops you choose, instead of “Desktop 1, 2, 3…”.  
- **Menubar integration** — always see your current Space name at a glance.  
- **One-click switching from menubar** — press, roll down, and release the mouse on the desired name – faster than Mission Control.
- **Visual banner** — a quick, noticeable label at the top showing the Space name whenever you switch.
- **Hotkey support** — press ⌘⌥L to quickly assign or change a Space name.  

### ⚙️ Customization & Workflow
- **Preset label system** — flexible reuse of labels from history or your own custom presets. 
- **Persistent storage** — labels are saved in an easy-to-read and editable JSON and restored after reboot. 
- **MC numbering view** — hold ⌥ while clicking the menubar label to display Spaces with Mission Control numbering.

### 🚀 Advanced Features
- **Multi-monitor support** — smart grouping across displays.
- **Multi-language support** — en/ru/de/fr/es/pt/ja/zh.
- **Auto-reload** — triggered on system wake and JSON changes.

---

## Quick install (short version)

1. Install **Hammerspoon**: <https://www.hammerspoon.org/>  
2. Copy `init.lua`, `spaces_labels.lua` and `spaces_labels_lang.lua` into `~/.hammerspoon/`.  
3. Reload Hammerspoon config.  
4. Press **⌘⌥L** to set or rename a label.  
5. Click the menubar label to switch Spaces or set a quick label.
6. Done — now your Spaces have names! 🎉

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
Use the history of entered labels or move it into presets and manage them — remove, edit, or add your own directly in `spaces-labels.json` (created automatically on first launch, can be opened from the submenu via *Edit presets*):

```json
{
  "Presets": [
    "chat",       // messengers, Slack, Discord
    "proj1",      // replace with your project name
    "proj2",      // another project or task
    "browsing",   // research w/o projects link, web, news
    "calendar",   // planning, scheduling, notes, calendar apps
    "finance",    // banking, invoices, bills, google sheets
    "chill"       // music, video, downtime

    // Remember: you can assign or rename a Space on the fly — as fast as your thoughts — with ⌘⌥L.  
    // If it proves useful, add it to your presets for permanent reuse.
  ],
  "History": [],


  "labelsBySpaceId": {}
}
```
Both Presets and History will show up in the submenu if defined.
You’re free to keep, clear, or fully customize these sections to match your workflow.

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

