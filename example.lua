local NotificationLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/k0nkx/asianyuh-notify/refs/heads/main/Library.lua'))()
local Notif = NotificationLib.new()

-- Send a welcome message
task.wait(2) -- Wait for game to load
Notif:WelcomePlayer()

-- Different types of notifications
Notif:Notify("This is a normal notification", 5, Color3.fromRGB(255, 50, 50), NotificationLib.Types.NORMAL)
Notif:Notify("Fast typing notification", 5, Color3.fromRGB(50, 255, 50), NotificationLib.Types.FAST)
Notif:Notify("Instant notification", 5, Color3.fromRGB(50, 50, 255), NotificationLib.Types.INSTANT)
Notif:Notify("No delay notification", 5, Color3.fromRGB(255, 255, 50), NotificationLib.Types.NODELAY)
