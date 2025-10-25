-- 🧪 ALPHA Feature — Mission Control overlay labels
-- (Adjust numeric parameters below to calibrate for your screen and resolution)

-- ============================================================================
-- PARAMETERS — manual calibration recommended (units: pixels)
-- ============================================================================

local MENUBAR_HEIGHT = 25  -- macOS menubar height (used for Y offset baseline)

-- Mission Control — collapsed state
local MC_COLLAPSED_SPACE_WIDTH = 140    -- width of one space thumbnail
local MC_COLLAPSED_LEFT_OFFSET  = 4     -- horizontal offset (move all labels right)
local MC_COLLAPSED_TOP_OFFSET   = 40    -- vertical offset from top in collapsed MC

-- Mission Control — expanded state
local MC_EXPANDED_SPACE_WIDTH = 192     -- width of one space thumbnail
local MC_EXPANDED_LEFT_OFFSET  = 27     -- horizontal offset (move all labels right)
local MC_EXPANDED_TOP_OFFSET   = 145    -- vertical offset from top in expanded MC

-- Mouse - expanded state detection
local MOUSE_TOP_THRESHOLD   = 40        -- Y coordinate threshold for switching to expanded mode
local MOUSE_CHECK_INTERVAL  = 0.05      -- how often to check mouse position (seconds)

-- Label appearance
local LABEL_HEIGHT           = 30       -- label height
local LABEL_FONT_SIZE        = 16       -- font size
local LABEL_APEARANCE_DELAY  = 0.1      -- delay (seconds) after key press before showing

-- Debug
local DEBUG_MODE            = true      -- print debug info to console

-- ============================================================================
-- MESSAGES
-- ============================================================================

local MESSAGES = {
    f3Pressed = "F3 pressed - Mission Control activated",
    ctrlUpPressed = "Ctrl+Up pressed - Mission Control activated",
    showingLabels = "Showing labels on all screens",
    labelsHidden = "Labels hidden"
}

-- ============================================================================
-- GLOBAL VARIABLES
-- ============================================================================

local canvases = {}
local eventTap = nil
local mouseMoveWatcher = nil
local mouseClickWatcher = nil
local currentPositionData = nil -- Store current calculated positions
local labelsVisible = false -- Label visibility state flag, collapsed or expanded

-- Using functions from spaces_labels.lua:
-- log(), getMissionControlNumbers(), getLabelForSpace()
-- And global variables: spaceLabels


function log(msg)
  if DEBUG_MODE then print("[MissionControlLabels] " .. tostring(msg)) end
end


-- ============================================================================
-- CANVAS MANAGEMENT
-- ============================================================================

local function stopWatcher(watcher)
    if watcher then
        pcall(function() watcher:stop() end)
    end
    return nil
end

local function restartEventTap()
    if eventTap then
        pcall(function() eventTap:stop() end)
    end
    eventTap = createSystemEventTap()
    if eventTap then
        eventTap:start()
        log("Event tap restarted")
    else
        log("ERROR: Failed to restart event tap")
    end
end

local function hideLabelsAndReset()
    log("Hiding labels and resetting state")
    
    -- First reset visibility flag so watchers stop working
    labelsVisible = false

    -- Stop watchers
    mouseMoveWatcher = stopWatcher(mouseMoveWatcher)
    mouseClickWatcher = stopWatcher(mouseClickWatcher)

    -- Delete all canvases
    for _, canvas in pairs(canvases) do
        if canvas then
            pcall(function() canvas:delete() end)
        end
    end
    canvases = {}
    
    -- Reset state
    currentPositionData = nil
    
    -- Restart event tap
    restartEventTap()
    
    log("" .. MESSAGES.labelsHidden)
end

local function createLabelCanvas(screen, x, y, width, height, text)
    local canvas = hs.canvas.new({
        x = x,
        y = y,
        w = width,
        h = height + 4
    })
    
    -- Label background
    canvas[1] = {
        type = "rectangle",
        action = "fill",
        roundedRectRadii = {xRadius = 6, yRadius = 6},
        fillColor = {hex = "#181818", alpha = 1}
    }
    
    -- Label text
    canvas[2] = {
        type = "text",
        text = text,
        textSize = LABEL_FONT_SIZE,
        textColor = {white = 0.9, alpha = 1},
        textAlignment = "center",
        frame = {x = 4, y = 8, w = width - 8, h = height - 8}
    }
    
    return canvas
end

-- ============================================================================
-- MAIN LABEL DISPLAY FUNCTION
-- ============================================================================

local function calculatePositionsForMode(screen, screenFrame, spaces, spaceWidth, topOffset, leftOffset, missionControlNumbers)
    local positions = {}
    local spaceCount = #spaces
    local totalWidth = spaceWidth * spaceCount
    local startX = leftOffset + math.floor(screenFrame.x + (screenFrame.w - totalWidth) / 2)
    local yPos = screenFrame.y - MENUBAR_HEIGHT + topOffset - 6
    
    for index, spaceId in ipairs(spaces) do
        local spaceIdStr = tostring(spaceId)
        local label = getLabelForSpace(spaceIdStr)
        
        -- If label is empty, use Mission Control number
        -- if not label or label == "" then
        --     local mcNumber = missionControlNumbers[spaceIdStr] or index
        --     label = tostring(mcNumber)  -- Add this logic
        -- end
        
        if label and label ~= "" then
            local x = startX + (index - 1) * spaceWidth
            table.insert(positions, {
                screen = screen,
                x = x,
                y = yPos,
                label = label,
                index = index,
                spaceId = spaceIdStr
            })
        end
    end
    
    return positions, startX
end

local function calculateLabelPositions()
    local positionData = {
        collapsed = {},
        expanded = {}
    }
    
    local allScreens = hs.screen.allScreens()
    local allSpaces = hs.spaces.allSpaces()
    local missionControlNumbers = getMissionControlNumbers()  -- Add this line
    
    for _, screen in ipairs(allScreens) do
        local screenUUID = screen:getUUID()
        local screenFrame = screen:frame()
        local spaces = allSpaces[screenUUID] or {}
        local spaceCount = #spaces
        
        if spaceCount > 0 then
            -- Collapsed: calculate positions for collapsed MC
            local collapsedPositions, collapsedStartX = calculatePositionsForMode(
                screen, screenFrame, spaces, 
                MC_COLLAPSED_SPACE_WIDTH, MC_COLLAPSED_TOP_OFFSET, MC_COLLAPSED_LEFT_OFFSET,
                missionControlNumbers  -- Add this parameter
            )
            
            -- Expanded: calculate positions for expanded MC
            local expandedPositions, expandedStartX = calculatePositionsForMode(
                screen, screenFrame, spaces,
                MC_EXPANDED_SPACE_WIDTH, MC_EXPANDED_TOP_OFFSET, MC_EXPANDED_LEFT_OFFSET,
                missionControlNumbers  -- Add this parameter
            )
            
            -- Add positions to common arrays
            for _, pos in ipairs(collapsedPositions) do
                table.insert(positionData.collapsed, pos)
            end
            
            for _, pos in ipairs(expandedPositions) do
                table.insert(positionData.expanded, pos)
            end
            
            log(string.format("Screen %s: %d spaces, collapsed_startX=%d, expanded_startX=%d", 
                screenUUID:sub(1, 8), spaceCount, collapsedStartX, expandedStartX))
        end
    end
    
    return positionData
end

local function redrawLabels(mode, positionData)
    -- Clear old labels
    for _, canvas in pairs(canvases) do
        if canvas then
            canvas:delete()
        end
    end
    canvases = {}
    
    -- Get positions for selected mode
    local positions = positionData[mode]
    
    -- Create labels at positions
    for _, pos in ipairs(positions) do
        local canvas = createLabelCanvas(
            pos.screen,
            pos.x,
            pos.y,
            MC_COLLAPSED_SPACE_WIDTH - 10, -- label width with small offset
            LABEL_HEIGHT,
            pos.label
        )
        
        canvas:show()
        table.insert(canvases, canvas)
        
        log(string.format("Label '%s' at space %d (x=%d, y=%d, mode=%s)", 
            pos.label, pos.index, pos.x, pos.y, mode))
    end
    
    labelsVisible = mode
end

local function showMissionControlBanner()
    log("" .. MESSAGES.showingLabels)
    
    -- If labels already visible, clean up first
    if labelsVisible then
        log("Labels already visible, cleaning up first")
        hideLabelsAndReset()
    end
    
    -- Recalculate positions on each hotkey press
    currentPositionData = calculateLabelPositions()
    
    if not currentPositionData or (#currentPositionData.collapsed == 0 and #currentPositionData.expanded == 0) then
        log("No labels to display")
        return
    end
    
    -- Show labels in collapsed MC state
    redrawLabels("collapsed", currentPositionData)
    
    -- Start mouse movement tracking for mode switching
    mouseMoveWatcher = hs.timer.doEvery(MOUSE_CHECK_INTERVAL, function()
        if not labelsVisible then
            mouseMoveWatcher = stopWatcher(mouseMoveWatcher)
            return
        end
        
        -- Check mouse position
        local mousePos = hs.mouse.absolutePosition()
        
        -- If mouse reached top of screen and we're still in collapsed mode
        if labelsVisible == "collapsed" and mousePos.y <= MOUSE_TOP_THRESHOLD then
            log(string.format("Mouse reached top (y=%d), switching to expanded mode", math.floor(mousePos.y)))
            if currentPositionData then
                redrawLabels("expanded", currentPositionData)
            end
        end
    end)
    
    -- Start mouse click tracking to hide labels
    mouseClickWatcher = hs.eventtap.new({
        hs.eventtap.event.types.leftMouseUp
    }, function(event)
        if not labelsVisible then
            return false
        end
        
        local eventType = event:getType()
        local mousePos = hs.mouse.absolutePosition()
        log(string.format("Mouse key up (y=%d)", math.floor(mousePos.y)))


        if labelsVisible == "expanded" and mousePos.y <= MC_EXPANDED_TOP_OFFSET then 
            return false
        end

        if labelsVisible then
            hideLabelsAndReset()
        end
        
        return false
    end)
    
    if mouseClickWatcher then
        mouseClickWatcher:start()
    end
    
    log("Labels displayed successfully")
end

-- ============================================================================
-- EVENT TAP SYSTEM
-- ============================================================================

function createSystemEventTap()
    return hs.eventtap.new({
        hs.eventtap.event.types.keyDown
    }, function(event)
        local flags = event:getFlags()
        local keyCode = event:getKeyCode()
        
        -- F3 (standard Mission Control key)
        if keyCode == 160 then
            log(MESSAGES.f3Pressed)
            hs.timer.doAfter(LABEL_APEARANCE_DELAY, showMissionControlBanner)
            return false
        end
        
        -- Ctrl+Up Arrow
        if flags.ctrl and keyCode == 126 then
            log(MESSAGES.ctrlUpPressed)
            hs.timer.doAfter(LABEL_APEARANCE_DELAY, showMissionControlBanner)
            return false
        end
        
        -- Esc (keyCode 53) - hide labels if visible
        if keyCode == 53 and labelsVisible then
            log("Esc pressed, hiding labels")
            hideLabelsAndReset()
            return false
        end
        
        return false
    end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Cleanup on reload
if eventTap then
    eventTap:stop()
    eventTap = nil
end

mouseMoveWatcher = stopWatcher(mouseMoveWatcher)
mouseClickWatcher = stopWatcher(mouseClickWatcher)

-- Create and start event tap
eventTap = createSystemEventTap()
if eventTap then
    eventTap:start()
    log("Event tap started - monitoring F3, Ctrl+Up, and Esc")
else
    log("ERROR: Failed to create event tap")
end

log("Module loaded successfully")