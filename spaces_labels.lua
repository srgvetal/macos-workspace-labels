-- ============================================================================
-- PARAMETERS (configure for yourself)
-- ============================================================================
local LOCALE = "en" -- Language: "en", "ru", "de", "fr", "es", "pt", "ja"

local JSON_PATH = os.getenv("HOME") .. "/.hammerspoon/spaces-labels.json"

local MENUBAR_TITLE_FORMAT = '“ %s “' -- menubar title format (%s is replaced with label)
local HOTKEY_LABEL_EDIT = {"cmd", "alt", "L"} -- hotkey for label editing

local BANNER_DURATION = 1.2          -- banner display duration in seconds
local SHOW_ON_MONITOR_CHANGE = false -- show banner on monitor change

local BANNER_TEXT_SIZE = 46          -- banner font size
local BANNER_Y_POSITION = 0.04       -- Y position (fraction of screen height)
local BANNER_MIN_WIDTH = 80          -- minimum banner width in pixels
local BANNER_PADDING_H = 40          -- horizontal padding inside banner in pixels
local BANNER_PADDING_V = 16          -- vertical padding inside banner in pixels

local DEBOUNCE_DELAY = 0.05          -- debouncing delay to prevent excessive updates

local DEBUG_MODE = false             -- print debug information

-- ============================================================================
-- TEXT CONSTANTS FOR DIFFERENT LANGUAGES
-- ============================================================================
local TEXTS = {
  en = {
    no_spaces = "No available workspaces",
    -- edit_menu = "⚙ Edit",
    edit_menu = "⚙ ",
    manual_input = "Enter manually",
    delete_label = "Delete",
    history = "History",
    presets = "Presets",
    edit_presets = "Edit presets",
    clear_history = "Clear history",
    space_prefix = "Space ",
    edit_dialog_title = "Edit workspace label",
    edit_dialog_text = "Enter new label for workspace %s:",
    edit_dialog_ok = "OK",
    edit_dialog_cancel = "Cancel",
    error_no_space = "Cannot determine current workspace"
  },
  ru = {
    no_spaces = "Нет доступных рабочих столов",
    -- edit_menu = "⚙ Изменить",
    edit_menu = "⚙ ",
    manual_input = "Ввести вручную",
    delete_label = "Удалить",
    history = "История",
    presets = "Шаблоны",
    edit_presets = "Изменить шаблоны",
    clear_history = "Очистить историю",
    space_prefix = "Рабочий стол ",
    edit_dialog_title = "Изменить метку рабочего стола",
    edit_dialog_text = "Введите новую метку для рабочего стола %s:",
    edit_dialog_ok = "OK",
    edit_dialog_cancel = "Отмена",
    error_no_space = "Не удается определить текущий рабочий стол"
  },
  de = {
    no_spaces = "Keine verfügbaren Arbeitsbereiche",
    -- edit_menu = "⚙ Bearbeiten",
    edit_menu = "⚙ ",
    manual_input = "Manuell eingeben",
    delete_label = "Löschen",
    history = "Verlauf",
    presets = "Favoriten",
    edit_presets = "Favoriten bearbeiten",
    clear_history = "Verlauf löschen",
    space_prefix = "Schreibtisch ",
    edit_dialog_title = "Arbeitsbereich-Label bearbeiten",
    edit_dialog_text = "Neues Label für Arbeitsbereich %s eingeben:",
    edit_dialog_ok = "OK",
    edit_dialog_cancel = "Abbrechen",
    error_no_space = "Aktueller Arbeitsbereich kann nicht bestimmt werden"
  },
  fr = {
    no_spaces = "Aucun espace de travail disponible",
    -- edit_menu = "⚙ Modifier",
    edit_menu = "⚙ ",
    manual_input = "Saisir manuellement",
    delete_label = "Supprimer",
    history = "Historique",
    presets = "Favoris",
    edit_presets = "Modifier les favoris",
    clear_history = "Effacer l'historique",
    space_prefix = "Bureau ",
    edit_dialog_title = "Modifier le libellé de l'espace de travail",
    edit_dialog_text = "Entrer un nouveau libellé pour l'espace de travail %s:",
    edit_dialog_ok = "OK",
    edit_dialog_cancel = "Annuler",
    error_no_space = "Impossible de déterminer l'espace de travail actuel"
  },
  es = {
    no_spaces = "No hay espacios de trabajo disponibles",
    -- edit_menu = "⚙ Editar",
    edit_menu = "⚙ ",
    manual_input = "Introducir manualmente",
    delete_label = "Eliminar",
    history = "Historial",
    presets = "Favoritos",
    edit_presets = "Editar favoritos",
    clear_history = "Limpiar historial",
    space_prefix = "Escritorio ",
    edit_dialog_title = "Editar etiqueta del espacio de trabajo",
    edit_dialog_text = "Introducir nueva etiqueta para el espacio de trabajo %s:",
    edit_dialog_ok = "OK",
    edit_dialog_cancel = "Cancelar",
    error_no_space = "No se puede determinar el espacio de trabajo actual"
  },
  pt = {
    no_spaces = "Nenhum espaço de trabalho disponível",
    -- edit_menu = "⚙ Editar",
    edit_menu = "⚙ ",
    manual_input = "Inserir manualmente",
    delete_label = "Excluir",
    history = "Histórico",
    presets = "Favoritos",
    edit_presets = "Editar favoritos",
    clear_history = "Limpar histórico",
    space_prefix = "Área de trabalho ",
    edit_dialog_title = "Editar rótulo do espaço de trabalho",
    edit_dialog_text = "Digite um novo rótulo para o espaço de trabalho %s:",
    edit_dialog_ok = "OK",
    edit_dialog_cancel = "Cancelar",
    error_no_space = "Não é possível determinar o espaço de trabalho atual"
  },
  ja = {
    no_spaces = "利用可能なワークスペースがありません",
    -- edit_menu = "⚙ 編集",
    edit_menu = "⚙ ",
    manual_input = "手動で入力",
    delete_label = "削除",
    history = "履歴",
    presets = "お気に入り",
    edit_presets = "お気に入りを編集",
    clear_history = "履歴をクリア",
    space_prefix = "デスクトップ ",
    edit_dialog_title = "ワークスペースラベルを編集",
    edit_dialog_text = "ワークスペース %s の新しいラベルを入力:",
    edit_dialog_ok = "OK",
    edit_dialog_cancel = "キャンセル",
    error_no_space = "現在のワークスペースを特定できません"
  }
}

-- Get current language texts
local T = TEXTS[LOCALE] or TEXTS["en"]

-- ============================================================================
-- CODE (don't touch unless necessary)
-- ============================================================================

local spaceLabels = {}
local spacePresets = {}
local menubar = nil
local canvas = nil
local hideTimer = nil
local updateTimer = nil
local lastSpaceId = nil
local lastScreenId = nil
local labelEditHotkey = nil

local handleUpdate, scheduleUpdate

local optionKeyPressed = false

-- ============================================================================
-- CORE FUNCTIONS
-- ============================================================================

local function log(msg)
  if DEBUG_MODE then print("[SpaceLabels] " .. tostring(msg)) end
end

local function getCurrentSpaceId()
  local screen = hs.screen.mainScreen()
  if not screen then return nil end
  
  local spaceId = hs.spaces.activeSpaceOnScreen(screen)
  if not spaceId then
    spaceId = hs.spaces.activeSpace()
  end
  
  return spaceId and tostring(spaceId) or nil
end

local function getCurrentScreenId()
  local screen = hs.screen.mainScreen()
  return screen and screen:getUUID() or ""
end

local function getLabelForSpace(spaceId)
  if not spaceId then return "—" end
  local label = spaceLabels[spaceId]
  return label and label ~= "" and label or ""
  -- return label and label ~= "" and label or (T.space_prefix .. spaceId)
end

local function getAllSpacesWithLabels()
  local spaces = {}
  local allSpaceIds = hs.spaces.allSpaces()
  
  for screenId, spaceList in pairs(allSpaceIds) do
    for index, spaceId in ipairs(spaceList) do
      local spaceIdStr = tostring(spaceId)
      local label = getLabelForSpace(spaceIdStr)
      
      local displayLabel = label
      if not label or label == "" then
        displayLabel = T.space_prefix .. index
      end
      
      table.insert(spaces, {
        id = spaceId,
        idStr = spaceIdStr,
        label = displayLabel,
        screenId = screenId
      })
    end
  end
  
  return spaces
end

local function switchToSpace(spaceId)
  local spaceIdNum = tonumber(spaceId)
  if spaceIdNum then
    hs.spaces.gotoSpace(spaceIdNum)
    log("Switching to Space: " .. spaceId)
  end
end

-- ============================================================================
-- DATA PERSISTENCE
-- ============================================================================

local function loadLabelsFromJSON()
  local file = io.open(JSON_PATH, "r")
  if not file then
    log("JSON file not found, creating new: " .. JSON_PATH)
    local defaultData = {
      labels = {},
      presets = {}
    }
    local newFile = io.open(JSON_PATH, "w")
    if newFile then
      newFile:write(hs.json.encode(defaultData, true))
      newFile:close()
    end
    return {}, {}
  end
  
  local content = file:read("*all")
  file:close()
  
  if not content or content == "" then
    log("JSON file is empty")
    return {}, {}
  end
  
  local success, data = pcall(hs.json.decode, content)
  if not success then
    log("JSON reading error: " .. tostring(data))
    return {}, {}
  end
  
  local labels = {}
  local presets = data.presets or {}
  
  -- Support different JSON formats
  if data.labelsBySpaceId then
    labels = data.labelsBySpaceId
  elseif data.labels then
    labels = data.labels
  else
    labels = data
  end
  
  return labels, presets
end

local function saveLabelsToJSON()
  local file = io.open(JSON_PATH, "r")
  local data = {
    labels = {},
    presets = {}
  }
  
  if file then
    local content = file:read("*all")
    file:close()
    
    if content and content ~= "" then
      local success, existingData = pcall(hs.json.decode, content)
      if success then
        data = existingData
      end
    end
  end
  
  -- Update labels while preserving existing presets
  if data.labelsBySpaceId then
    data.labelsBySpaceId = spaceLabels
  else
    data.labels = spaceLabels
  end
  
  local newFile = io.open(JSON_PATH, "w")
  if newFile then
    newFile:write(hs.json.encode(data, true))
    newFile:close()
    log("Labels saved to JSON")
    return true
  else
    log("Error saving JSON")
    return false
  end
end

local function reloadLabels()
  spaceLabels, spacePresets = loadLabelsFromJSON()
  log("Loaded labels: " .. tostring(#spaceLabels) .. ", presets: " .. tostring(#spacePresets))
end

-- ============================================================================
-- BANNER SYSTEM
-- ============================================================================

local function createCanvas(text)
  local screen = hs.screen.mainScreen()
  if not screen then return end
  
  local textSize = hs.drawing.getTextDrawingSize(text or "Space", { size = BANNER_TEXT_SIZE })
  local bannerWidth = math.max(BANNER_MIN_WIDTH, textSize.w + BANNER_PADDING_H)
  local bannerHeight = textSize.h + BANNER_PADDING_V
  
  local frame = screen:fullFrame()
  local x = frame.x + (frame.w - bannerWidth) / 2
  local y = frame.y + (frame.h * BANNER_Y_POSITION)
  
  if canvas then
    canvas:delete()
    canvas = nil
  end
  
  canvas = hs.canvas.new({x=x, y=y, w=bannerWidth, h=bannerHeight})
  
  canvas[1] = {
    type = "rectangle",
    action = "fill",
    roundedRectRadii = {xRadius = 16, yRadius = 16},
    fillColor = {white=0, alpha=0.85},
    strokeColor = {white=1, alpha=0.15},
    strokeWidth = 1
  }
  
  canvas[2] = {
    type = "text",
    text = "",
    textSize = BANNER_TEXT_SIZE,
    textColor = {white=1, alpha=0.9},
    textAlignment = "center",
    frame = {x=8, y=5, w=bannerWidth-16, h=bannerHeight-16}
  }
  
  canvas:hide()
  log("Canvas created: " .. bannerWidth .. "x" .. bannerHeight .. " for text: " .. (text or "Space"))
end

local function showBanner(text)
  if not text or text == "" then 
    log("Banner not shown: empty text")
    return 
  end
  
  createCanvas(text)
  if not canvas then 
    log("Banner not shown: canvas not created")
    return 
  end
  
  canvas[2].text = text
  canvas:show()
  log("Banner shown: " .. text)
  
  if hideTimer then
    hideTimer:stop()
    hideTimer = nil
  end
  
  hideTimer = hs.timer.doAfter(BANNER_DURATION, function()
    if canvas then 
      canvas:hide()
      log("Banner hidden")
    end
  end)
end

-- ============================================================================
-- DIALOG SYSTEM
-- ============================================================================

function showLabelEditDialog()
  local currentSpaceId = getCurrentSpaceId()
  if not currentSpaceId then
    hs.alert.show(T.error_no_space)
    return
  end
  
  local currentLabel = spaceLabels[currentSpaceId] or ""
  
  local button, text = hs.dialog.textPrompt(
    T.edit_dialog_title, 
    string.format(T.edit_dialog_text, currentSpaceId),
    currentLabel,
    T.edit_dialog_ok,
    T.edit_dialog_cancel
  )
  
  if button == T.edit_dialog_ok then
    if text and text ~= "" then
      spaceLabels[currentSpaceId] = text
      log("Set label '" .. text .. "' for Space " .. currentSpaceId)
    else
      spaceLabels[currentSpaceId] = nil
      log("Removed label for Space " .. currentSpaceId)
    end
    
    saveLabelsToJSON()
    handleUpdate("label_edited")
    
    if text and text ~= "" then
      showBanner(text)
    end
  end
end

-- ============================================================================
-- MENU CREATION
-- ============================================================================

local function createEditSubmenu()
  local menuItems = {}
  
  table.insert(menuItems, {
    title = T.manual_input,
    fn = function()
      showLabelEditDialog()
    end
  })
  
  table.insert(menuItems, {
    title = T.delete_label,
    fn = function()
      local currentSpaceId = getCurrentSpaceId()
      if currentSpaceId then
        spaceLabels[currentSpaceId] = nil
        saveLabelsToJSON()
        handleUpdate("label_removed")
      end
    end
  })
  
  local hasContent = false
  
  if spacePresets and #spacePresets > 0 then
    table.insert(menuItems, {title = "-"})
    table.insert(menuItems, {title = T.presets, disabled = true})
    
    for _, preset in ipairs(spacePresets) do
      table.insert(menuItems, {
        title = "  " .. preset,
        fn = function()
          local currentSpaceId = getCurrentSpaceId()
          if currentSpaceId then
            spaceLabels[currentSpaceId] = preset
            saveLabelsToJSON()
            handleUpdate("label_changed")
          end
        end
      })
    end
    hasContent = true
  end
  
  local historyLabels = {}
  local presetSet = {}
  for _, preset in ipairs(spacePresets or {}) do
    presetSet[preset] = true
  end
  
  local labelsList = {}
  for spaceId, label in pairs(spaceLabels) do
    if label and label ~= "" and not presetSet[label] then
      table.insert(labelsList, label)
    end
  end
  
  for i = #labelsList, 1, -1 do
    table.insert(historyLabels, labelsList[i])
  end
  
  if #historyLabels > 0 then
    if hasContent then
      table.insert(menuItems, {title = "-"})
    else
      table.insert(menuItems, {title = "-"})
    end
    table.insert(menuItems, {title = T.history, disabled = true})
    
    for _, label in ipairs(historyLabels) do
      table.insert(menuItems, {
        title = "  " .. label,
        fn = function()
          local currentSpaceId = getCurrentSpaceId()
          if currentSpaceId then
            spaceLabels[currentSpaceId] = label
            saveLabelsToJSON()
            handleUpdate("label_changed")
          end
        end
      })
    end
    hasContent = true
  end
  
  if hasContent then
    table.insert(menuItems, {title = "-"})
  end
  
  table.insert(menuItems, {
    title = T.edit_presets,
    fn = function()
      os.execute("open -a TextEdit '" .. JSON_PATH .. "'")
    end
  })
  
  if #historyLabels > 0 then
    table.insert(menuItems, {
      title = T.clear_history,
      fn = function()
        local allSpaceIds = {}
        for _, spaceList in pairs(hs.spaces.allSpaces()) do
          for _, spaceId in ipairs(spaceList) do
            allSpaceIds[tostring(spaceId)] = true
          end
        end
        
        for spaceId in pairs(spaceLabels) do
          if not allSpaceIds[spaceId] then
            spaceLabels[spaceId] = nil
          end
        end
        
        saveLabelsToJSON()
        handleUpdate("history_cleared")
      end
    })
  end
  
  return menuItems
end

local function createMainMenu()
  local flags = hs.eventtap.checkKeyboardModifiers()
  optionKeyPressed = flags.alt or false
  
  local spaces = getAllSpacesWithLabels()
  local menuItems = {}
  
  local spacesByScreen = {}
  for _, space in ipairs(spaces) do
    if not spacesByScreen[space.screenId] then
      spacesByScreen[space.screenId] = {}
    end
    table.insert(spacesByScreen[space.screenId], space)
  end
  
  local missionControlNumbers = {}
  
  if optionKeyPressed then
    local currentNumber = 1
    
    local screenInfos = {}
    for screenId, _ in pairs(spacesByScreen) do
      local screen = hs.screen.find(screenId)
      if screen then
        table.insert(screenInfos, {
          uuid = screenId,
          internalId = screen:id(),
          isPrimary = screen == hs.screen.primaryScreen()
        })
      end
    end
    
    table.sort(screenInfos, function(a, b)
      if a.isPrimary and not b.isPrimary then return true end
      if b.isPrimary and not a.isPrimary then return false end
      return a.internalId < b.internalId
    end)
    
    for _, screenInfo in ipairs(screenInfos) do
      local screenSpaces = spacesByScreen[screenInfo.uuid]
      for _, space in ipairs(screenSpaces) do
        missionControlNumbers[space.idStr] = currentNumber
        currentNumber = currentNumber + 1
      end
    end
  end
  
  local activeScreenId = getCurrentScreenId()
  local isFirst = true
  
  if spacesByScreen[activeScreenId] then
    for _, space in ipairs(spacesByScreen[activeScreenId]) do
      local title = space.label
      if optionKeyPressed then
        local mcNumber = missionControlNumbers[space.idStr] or "?"
        title = mcNumber .. ": " .. space.label
      end
      
      table.insert(menuItems, {
        title = title,
        fn = function()
          switchToSpace(space.id)
        end
      })
    end
    isFirst = false
  end
  
  for screenId, screenSpaces in pairs(spacesByScreen) do
    if screenId ~= activeScreenId then
      if not isFirst then
        table.insert(menuItems, {title = "-"})
      end
      
      for _, space in ipairs(screenSpaces) do
        local title = space.label
        if optionKeyPressed then
          local mcNumber = missionControlNumbers[space.idStr] or "?"
          title = mcNumber .. ": " .. space.label
        end
        
        table.insert(menuItems, {
          title = title,
          fn = function()
            switchToSpace(space.id)
          end
        })
      end
      
      isFirst = false
    end
  end
  
  if #menuItems == 0 then
    table.insert(menuItems, {title = T.no_spaces, disabled = true})
  end
  
  table.insert(menuItems, {title = "-"})
  
  local hotkeyText = table.concat(HOTKEY_LABEL_EDIT, ""):gsub("cmd", "⌘"):gsub("alt", "⌥")
  table.insert(menuItems, {
    title = T.edit_menu .. "\t" .. hotkeyText,
    menu = createEditSubmenu()
  })
  
  return menuItems
end

local function updateMenubar(label)
  if not menubar then
    menubar = hs.menubar.new()
  end
  if menubar then
    local title = string.format(MENUBAR_TITLE_FORMAT, label)
    menubar:setTitle(title)
    
    menubar:setMenu(function()
      return createMainMenu()
    end)
  end
end

-- ============================================================================
-- UPDATE SYSTEM
-- ============================================================================

function handleUpdate(reason)
  local spaceId = getCurrentSpaceId()
  local screenId = getCurrentScreenId()
  local label = getLabelForSpace(spaceId)
  
  log("Update: " .. reason .. " -> Space:" .. tostring(spaceId) .. " Label:" .. label)
  
  updateMenubar(label)
  
  local shouldShowBanner = false

  if spaceId ~= lastSpaceId then
    shouldShowBanner = true
  end

  if screenId ~= lastScreenId and not SHOW_ON_MONITOR_CHANGE then 
    shouldShowBanner = false 
  end

  if shouldShowBanner and label and label ~= "—" then
    showBanner(label)
  end
  
  lastSpaceId = spaceId
  lastScreenId = screenId
end

function scheduleUpdate(reason)
  if updateTimer then
    updateTimer:stop()
    updateTimer = nil
  end
  
  updateTimer = hs.timer.doAfter(DEBOUNCE_DELAY, function()
    handleUpdate(reason)
  end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Cleanup on reload
if menubar then menubar:delete() menubar = nil end
if canvas then canvas:delete() canvas = nil end
if hideTimer then hideTimer:stop() hideTimer = nil end
if updateTimer then updateTimer:stop() updateTimer = nil end
if labelEditHotkey then labelEditHotkey:delete() labelEditHotkey = nil end

-- Load labels from JSON
reloadLabels()

-- Create menubar with immediate update
menubar = hs.menubar.new()
handleUpdate("init") -- Immediate update instead of delayed

-- Setup hotkey for label editing
local mods = { HOTKEY_LABEL_EDIT[1], HOTKEY_LABEL_EDIT[2] }
local key  = HOTKEY_LABEL_EDIT[3]
labelEditHotkey = hs.hotkey.bind(mods, key, function()
  showLabelEditDialog()
end)

-- Watch for space changes
hs.spaces.watcher.new(function()
  scheduleUpdate("space_change")
end):start()

-- Watch for screen changes
hs.screen.watcher.new(function()
  scheduleUpdate("screen_change")
end):start()

-- Watch for system wake
hs.caffeinate.watcher.new(function(event)
  if event == hs.caffeinate.watcher.systemDidWake then
    hs.timer.doAfter(1, function()
      reloadLabels()
      createCanvas()
      scheduleUpdate("wake")
    end)
  end
end):start()

-- Watch for window focus changes
hs.window.filter.new(true):subscribe(hs.window.filter.windowFocused, function()
  scheduleUpdate("focus_change")
end)

-- Watch for JSON file changes
hs.pathwatcher.new(JSON_PATH, function()
  log("JSON file changed, reloading labels")
  reloadLabels()
  scheduleUpdate("json_reload")
end):start()

log("SpaceLabels loaded. JSON: " .. JSON_PATH)
log("Hotkey for label editing: " .. table.concat(HOTKEY_LABEL_EDIT, "+"))