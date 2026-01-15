-- Hammerspoon Configuration
-- Right Command acts as hyper key (Cmd+Ctrl+Alt+Shift)

-- Auto-reload on file changes
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
    for _, file in pairs(files) do
        if file:sub(-4) == ".lua" then
            hs.reload()
            break
        end
    end
end):start()

-- Application bindings
local apps = {
    a = "Agentastic.dev",
    s = "Google Chrome",
    e = "Zed",
    t = "Ghostty",
    x = "Xcode",
    c = "ChatGPT Atlas",
    m = "Slack",
    l = "Linear",
    f = "Figma",
    b = "Bruno",
    v = "Visual Studio Code",
    n = "Notion",
}

local function focusExistingOrLaunch(appName)
    -- Prefer focusing an existing window to avoid Electron apps (e.g., ChatGPT Atlas) spawning duplicates
    local app = hs.application.get(appName)
    if app then
        app:activate(true)
        local win = app:mainWindow()
        if win then
            win:focus()
            return
        end
    end
    hs.application.launchOrFocus(appName)
end

-- Create hyper key bindings
for key, app in pairs(apps) do
    hs.hotkey.bind({"cmd", "ctrl", "alt", "shift"}, key, function()
        focusExistingOrLaunch(app)
    end)
end

-- Window management
local windowBindings = {
    -- Half screen
    ["n"] = {x=0, y=0, w=0.5, h=1},         -- Left half
    ["o"] = {x=0.5, y=0, w=0.5, h=1},       -- Right half
    ["e"] = {x=0, y=0, w=1, h=1},           -- Maximize
    -- Quarter screen
    ["u"] = {x=0, y=0, w=0.5, h=0.5},       -- Upper left
    ["y"] = {x=0.5, y=0, w=0.5, h=0.5},     -- Upper right
    [","] = {x=0, y=0.5, w=0.5, h=0.5},     -- Lower left
    ["."] = {x=0.5, y=0.5, w=0.5, h=0.5},   -- Lower right
}

-- Bind window management keys
for key, unit in pairs(windowBindings) do
    hs.hotkey.bind({"ctrl", "alt"}, key, function()
        local win = hs.window.focusedWindow()
        if win then
            win:moveToUnit(unit)
        end
    end)
end

-- Move window to next monitor
hs.hotkey.bind({"ctrl", "alt"}, "i", function()
    local win = hs.window.focusedWindow()
    if win then
        local screen = win:screen()
        local nextScreen = screen:next()
        win:moveToScreen(nextScreen, true)
    end
end)

-- Pre-compute keycode lookup
local keycodeToString = {}
for k, v in pairs(hs.keycodes.map) do
    keycodeToString[v] = k
end

-- Transform Right Command to hyper key (global to prevent garbage collection)
hyperKeyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
    local flags = event:rawFlags()
    if flags & hs.eventtap.event.rawFlagMasks.deviceRightCommand > 0 then
        local keyString = keycodeToString[event:getKeyCode()]
        if keyString then
            hs.eventtap.event.newKeyEvent({"cmd", "ctrl", "alt", "shift"}, keyString, true):post()
            hs.eventtap.event.newKeyEvent({"cmd", "ctrl", "alt", "shift"}, keyString, false):post()
            return true
        end
    end
    return false
end)
hyperKeyTap:start()
