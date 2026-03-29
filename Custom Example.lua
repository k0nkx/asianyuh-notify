local NotificationLib = loadstring(game:HttpGet("https://github.com/k0nkx/asianyuh-notify/raw/refs/heads/main/Custom.lua"))()

-- create a new instance of the NotificationLib
local Notify = NotificationLib.new()

--[[
========================
  USAGE WITH INSTANCE
========================
Functions on the instance:
1. Notify:Notify(text, duration, color)
   - text: string to display
   - duration: seconds the notif stays
   - color: Color3 for the top line

2. Notify:Destroy()
   - removes all active notifications and cleans GUI
]]

-- Example 1: basic notification
Notify:Notify("Hello world!", 5, Color3.fromRGB(255, 182, 193))

-- Example 2: custom duration + color
Notify:Notify("This will last 10 seconds", 10, Color3.fromRGB(0, 255, 0))

-- Example 3: multiple stacked notifications
Notify:Notify("First notif", 5, Color3.fromRGB(255, 0, 0))
Notify:Notify("Second notif", 5, Color3.fromRGB(0, 0, 255))
Notify:Notify("Third notif with long text, auto width adjusts", 8, Color3.fromRGB(255, 255, 0))

-- Example 4: cleanup all notifications
-- Notify:Destroy()
