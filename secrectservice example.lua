-- Example usage
local NotificationModule = loadstring(game:HttpGet("https://github.com/k0nkx/asianyuh-notify/raw/refs/heads/main/secrectservice.lua"))()

-- Initialize with custom settings
-- Show notifications
NotificationModule:Notify("Success", "Script loaded successfully!")
NotificationModule:Notify("Warning", "This is a warning message", 3)
NotificationModule:Notify("Error", "Something went wrong!", 5)

-- Chain methods
NotificationModule:SetAccentColor(Color3.fromRGB(100, 200, 100))
    :SetDefaultDuration(3)
    :Notify("Info", "This is a chained notification")

-- Clear all notifications
-- NotificationModule:ClearAll()

-- Destroy the entire system
-- NotificationModule:Destroy()
