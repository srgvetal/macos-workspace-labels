-- ============================================================================
-- PARAMETERS (configure for yourself)
-- ============================================================================

local LOCALE = "auto" -- Language: "auto", "en", "ru", "de", "fr", "es", "pt", "ja", "zh"

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
-- LOCALIZATION
-- ============================================================================

local function getSystemLocale()
  local handle = io.popen("defaults read -g AppleLocale")
  local result = handle:read("*a")
  handle:close()
  
  local locale = result:match("^(%a+)")
  if not locale then
    return "en"
  end
  
  local localeMap = {
    en = "en",
    ru = "ru", 
    de = "de",
    fr = "fr",
    es = "es",
    pt = "pt",
    ja = "ja",
    zh = "zh"
  }
  
  return localeMap[locale] or "en"
end

local function getEffectiveLocale()
  if LOCALE == "auto" then
    return getSystemLocale()
  else
    return LOCALE
  end
end

local TEXTS = dofile(hs.configdir .. "/spaces_labels_lang.lua")
local T = TEXTS[getEffectiveLocale()] or TEXTS["en"]

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

local handleUpdate, scheduleUpdate, missionControlNumbers

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
  local missionControlNumbers = getMissionControlNumbers()
  
  for screenId, spaceList in pairs(allSpaceIds) do
    for index, spaceId in ipairs(spaceList) do
      local spaceIdStr = tostring(spaceId)
      local label = getLabelForSpace(spaceIdStr)
      
      local displayLabel = label
      if not label or label == "" then
        local mcNumber = missionControlNumbers[spaceIdStr] or index
        displayLabel = T.space_prefix .. mcNumber
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
-- JSON DATA OPERATIONS
-- ============================================================================

local JsonData = {}

function JsonData.createDefaultStructure()
  return {
    Presets = {},
    History = {},
    labelsBySpaceId = {}
  }
end

function JsonData.loadFromFile()
  local file = io.open(JSON_PATH, "r")
  if not file then
    log("JSON file not found, creating new: " .. JSON_PATH)
    local defaultData = JsonData.createDefaultStructure()
    JsonData.saveToFile(defaultData)
    return {}, {}
  end
  
  local content = file:read("*all")
  file:close()
  
  if not content or content == "" then
    log("JSON file is empty")
    return {}, {}
  end
  
  local success, data = pcall(hs.json.decode, content)
  if not success or not data then
    log("JSON reading error: " .. tostring(data))
    return {}, {}
  end

  local labels = data.labelsBySpaceId or data.labels or {}
  local presets = data.presets or data.Presets or {}
  
  return labels, presets
end

function JsonData.saveToFile(data)
  local function formatArray(arr)
    if not arr or #arr == 0 then
      return "[]"
    end
    
    local items = {}
    for _, item in ipairs(arr) do
      table.insert(items, '"' .. tostring(item) .. '"')
    end
    
    return "[\n    " .. table.concat(items, ",\n    ") .. "\n  ]"
  end
  
  local function formatObject(obj)
    if not obj or next(obj) == nil then
      return "{}"
    end
    
    local items = {}
    for key, value in pairs(obj) do
      table.insert(items, '"' .. tostring(key) .. '": "' .. tostring(value) .. '"')
    end
    
    table.sort(items) -- Сортируем для стабильного порядка
    
    return "{\n    " .. table.concat(items, ",\n    ") .. "\n  }"
  end
  
  local orderedJson = "{\n"
  orderedJson = orderedJson .. '  "Presets": ' .. formatArray(data.Presets or {}) .. ',\n'
  orderedJson = orderedJson .. '  "History": ' .. formatArray(data.History or {}) .. ',\n\n\n'
  orderedJson = orderedJson .. '  "labelsBySpaceId": ' .. formatObject(data.labelsBySpaceId or {}) .. '\n'
  orderedJson = orderedJson .. "}"
  
  local file = io.open(JSON_PATH, "w")
  if file then
    file:write(orderedJson)
    file:close()
    log("Data saved to JSON")
    return true
  else
    log("Error saving JSON")
    return false
  end
end

function JsonData.getExistingData()
  local file = io.open(JSON_PATH, "r")
  local data = JsonData.createDefaultStructure()
  
  if file then
    local content = file:read("*all")
    file:close()
    
    if content and content ~= "" then
      local success, existingData = pcall(hs.json.decode, content)
      if success and existingData then
        data.Presets = existingData.presets or existingData.Presets or {}
        data.History = existingData.history or existingData.History or {}
      end
    end
  end
  
  return data
end

function JsonData.getHistory()
  local file = io.open(JSON_PATH, "r")
  if not file then return {} end
  
  local content = file:read("*all")
  file:close()
  
  if not content or content == "" then return {} end
  
  local success, data = pcall(hs.json.decode, content)
  if success and data and (data.History or data.history) then
    return data.History or data.history
  end
  
  return {}
end

local function loadLabelsFromJSON()
  return JsonData.loadFromFile()
end

local function saveLabelsToJSON()
  local data = JsonData.getExistingData()
  data.labelsBySpaceId = spaceLabels
  return JsonData.saveToFile(data)
end

local function reloadLabels()
  spaceLabels, spacePresets = loadLabelsFromJSON()
  log("Loaded labels: " .. tostring(#spaceLabels) .. ", presets: " .. tostring(#spacePresets))
end

-- ============================================================================
-- HISTORY OPERATIONS
-- ============================================================================

local function addLabelToHistory(label)
  if not label or label == "" then return end
  
  local data = JsonData.getExistingData()
  data.labelsBySpaceId = spaceLabels
  
  -- Remove duplicate if exists in History
  for i = #data.History, 1, -1 do
    if data.History[i] == label then
      table.remove(data.History, i)
    end
  end
  
  table.insert(data.History, label)
  JsonData.saveToFile(data)
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

  local missionControlNumbers = getMissionControlNumbers()
  local mcNumber = missionControlNumbers[currentSpaceId] or "?"
  
  local button, text = hs.dialog.textPrompt(
    T.edit_dialog_title, 
    string.format(T.edit_dialog_text, mcNumber),
    currentLabel,
    T.edit_dialog_ok,
    T.edit_dialog_cancel
  )
  
  if button == T.edit_dialog_ok then
    if text and text ~= "" then
      spaceLabels[currentSpaceId] = text
      addLabelToHistory(text)
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
-- MISSION CONTROL NUMBERING SYSTEM
-- ============================================================================

function getMissionControlNumbers()
  local allSpaceIds = hs.spaces.allSpaces()
  local missionControlNumbers = {}
  
  local spacesByScreen = {}
  for screenId, spaceList in pairs(allSpaceIds) do
    spacesByScreen[screenId] = {}
    for _, spaceId in ipairs(spaceList) do
      table.insert(spacesByScreen[screenId], {
        id = spaceId,
        idStr = tostring(spaceId)
      })
    end
  end
  
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
    if screenSpaces then
      for _, space in ipairs(screenSpaces) do
        missionControlNumbers[space.idStr] = currentNumber
        currentNumber = currentNumber + 1
      end
    end
  end
  
  return missionControlNumbers
end

-- ============================================================================
-- MENU AND SUBMENU CREATION AND ACTIONS
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
            addLabelToHistory(preset)
            saveLabelsToJSON()
            handleUpdate("label_changed")
          end
        end
      })
    end
    hasContent = true
  end
  
  local spaceHistory = JsonData.getHistory()
  local historyLabels = {}
  local presetSet = {}
  for _, preset in ipairs(spacePresets or {}) do
    presetSet[preset] = true
  end
  
  for i = #spaceHistory, 1, -1 do
    local label = spaceHistory[i]
    if label and label ~= "" and not presetSet[label] then
      local found = false
      for _, existing in ipairs(historyLabels) do
        if existing == label then
          found = true
          break
        end
      end
      if not found then
        table.insert(historyLabels, label)
      end
    end
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
            addLabelToHistory(label)
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
        local data = JsonData.getExistingData()
        data.History = {}
        data.labelsBySpaceId = spaceLabels
        JsonData.saveToFile(data)
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
    missionControlNumbers = getMissionControlNumbers()
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
local jsonWatcher = nil

local function startJSONWatcher()
  if jsonWatcher then
    jsonWatcher:stop()
    jsonWatcher = nil
  end
  
  jsonWatcher = hs.pathwatcher.new(JSON_PATH, function()
    log("JSON file changed, reloading labels")
    reloadLabels()
    scheduleUpdate("json_reload")
    
    -- Restart watcher after delay to prevent issues
    hs.timer.doAfter(1, function()
      startJSONWatcher()
    end)
  end)
  
  if jsonWatcher then
    jsonWatcher:start()
  end
end

startJSONWatcher()

log("SpaceLabels loaded. JSON: " .. JSON_PATH)
log("Hotkey for label editing: " .. table.concat(HOTKEY_LABEL_EDIT, "+"))