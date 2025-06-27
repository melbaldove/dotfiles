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
    s = "Dia",
    e = "Emacs",
    t = "Ghostty",
    x = "Xcode-beta",
    c = "Claude",
}

-- Create hyper key bindings
for key, app in pairs(apps) do
    hs.hotkey.bind({"cmd", "ctrl", "alt", "shift"}, key, function()
        hs.application.launchOrFocus(app)
    end)
end

-- Pre-compute keycode lookup
local keycodeToString = {}
for k, v in pairs(hs.keycodes.map) do
    keycodeToString[v] = k
end

-- Transform Right Command to hyper key
hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
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
end):start()