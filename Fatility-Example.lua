local Notifications = loadstring(game:HttpGet("https://github.com/k0nkx/asianyuh-notify/raw/refs/heads/main/Fatility.lua"))()

task.wait(0.3)
Notifications:NotifyHit("Player1", "Head", 30, 70)
-- Notifications:NotifyHit(victimName, partName, damage, remainingHealth)

task.wait(0.3)
Notifications:NotifyMessage("Unlocked")
-- Notifications:NotifyMessage(message)


-- Notifications:Destroy()
