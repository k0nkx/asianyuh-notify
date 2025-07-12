local NotificationLib = {}
NotificationLib.__index = NotificationLib

local currentInstance = nil

function NotificationLib.new()
    -- Clean up previous instance
    if currentInstance then
        currentInstance:Destroy()
    end
    
    local self = setmetatable({}, NotificationLib)
    currentInstance = self
    
    -- Create container
    self.container = Instance.new("ScreenGui")
    self.container.Name = "NotificationLib_"..tostring(math.random(1, 1e6))
    self.container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Safe parent assignment
    pcall(function()
        self.container.Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end)
    
    self.activeNotifications = {}
    self.ready = false
    self.queuedNotifications = {}
    
    -- Robust initialization
    task.spawn(function()
        local maxAttempts = 5
        local attempts = 0
        
        while not self.ready and attempts < maxAttempts do
            local success = pcall(function()
                -- Wait for essential services
                local players = game:GetService("Players")
                while not players.LocalPlayer do
                    task.wait(1)
                end
                local player = players.LocalPlayer
                
                -- Wait for character safely
                if not player.Character then
                    local charEvent
                    charEvent = player.CharacterAdded:Connect(function()
                        if charEvent then charEvent:Disconnect() end
                    end)
                    player.CharacterAdded:Wait()
                    task.wait(0.5) -- Buffer time
                end
                
                -- Wait for game load
                if not game:IsLoaded() then
                    game.Loaded:Wait()
                end
                
                task.wait(0.5) -- Final buffer
                self.ready = true
                
                -- Process queued notifications
                for _, notif in ipairs(self.queuedNotifications) do
                    self:CreateNotification(notif.text, notif.duration, notif.color)
                end
                self.queuedNotifications = {}
            end)
            
            attempts += 1
            if not success and attempts >= maxAttempts then
                self.ready = true -- Force ready state
            end
            task.wait(1)
        end
    end)
    
    return self
end

function NotificationLib:UpdatePositions()
    for i, notification in ipairs(self.activeNotifications) do
        if notification and notification.outerFrame and notification.outerFrame.Parent then
            local targetY = 20 + ((i - 1) * 30)
            game:GetService("TweenService"):Create(
                notification.outerFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 15, 0, targetY)}
            ):Play()
        end
    end
end

function NotificationLib:TypeWriter(textLabel, fullText, speed)
    local typedText = ""
    local cursorVisible = true
    local cursorTask = nil
    
    local function ToggleCursor()
        while true do
            textLabel.Text = typedText .. (cursorVisible and "|" or "")
            cursorVisible = not cursorVisible
            task.wait(0.5)
        end
    end
    
    cursorTask = task.spawn(ToggleCursor)
    
    for i = 1, #fullText do
        typedText = string.sub(fullText, 1, i)
        if cursorTask then
            textLabel.Text = typedText .. "|"
        end
        task.wait(speed)
    end
    
    if cursorTask then
        task.cancel(cursorTask)
        textLabel.Text = fullText
    end
end

function NotificationLib:CreateNotification(text, duration, color)
    text = text or "Notification"
    duration = duration or 5
    color = color or Color3.fromRGB(255, 255, 255)
    
    if not self.ready then
        table.insert(self.queuedNotifications, {
            text = text,
            duration = duration,
            color = color
        })
        return
    end

    local textService = game:GetService("TextService")
    local textSize = textService:GetTextSize(text, 12, Enum.Font.Ubuntu, Vector2.new(10000, 10000))
    local minWidth = math.max(textSize.X + 24, 150)
    local minHeight = math.max(textSize.Y + 12, 25)

    local outerFrame = Instance.new("Frame")
    outerFrame.Name = "NotificationFrame"
    outerFrame.Position = UDim2.new(0, -minWidth - 2, 0, -32)
    outerFrame.Size = UDim2.new(0, minWidth + 4, 0, minHeight + 4)
    outerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    outerFrame.BorderSizePixel = 1
    outerFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    outerFrame.ClipsDescendants = true
    outerFrame.Parent = self.container

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.Position = UDim2.new(0, 1, 0, 1)
    holder.Size = UDim2.new(1, -2, 1, -2)
    holder.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.Parent = outerFrame

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, -4, 1, -4)
    background.Position = UDim2.new(0, 2, 0, 2)
    background.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    background.BorderSizePixel = 0
    background.Parent = holder

    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Size = UDim2.new(0, 2, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.Parent = background

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, 0, 0, 1)
    progressBar.Position = UDim2.new(0, 0, 1, -1)
    progressBar.BackgroundColor3 = color
    progressBar.BorderSizePixel = 0
    progressBar.Parent = background

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TextLabel"
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Position = UDim2.new(0, 8, 0, 0)
    textLabel.Size = UDim2.new(1, -8, 1, 0)
    textLabel.Font = Enum.Font.Ubuntu
    textLabel.Text = ""
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 12
    textLabel.BackgroundTransparency = 1
    textLabel.TextWrapped = true
    textLabel.Parent = background

    -- Animation
    outerFrame:TweenPosition(
        UDim2.new(0, 15, 0, 20 + (#self.activeNotifications * 30)),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )

    -- Typewriter effect
    self:TypeWriter(textLabel, text, 0.05)

    -- Progress animation
    task.delay(#text * 0.05, function()
        progressBar:TweenSize(
            UDim2.new(0, 0, 0, 1),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Linear,
            duration,
            true
        )
    end)

    local notification = {
        outerFrame = outerFrame,
        remove = function()
            outerFrame:TweenPosition(
                UDim2.new(0, 10, 0, outerFrame.Position.Y.Offset - 20),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.3,
                true,
                function()
                    outerFrame:Destroy()
                    self:UpdatePositions()
                end
            )
        end
    }
    
    table.insert(self.activeNotifications, notification)
    self:UpdatePositions()

    -- Auto-remove after duration
    task.delay(#text * 0.05 + duration, function()
        for i, notif in ipairs(self.activeNotifications) do
            if notif == notification then
                table.remove(self.activeNotifications, i)
                break
            end
        end
        notification.remove()
    end)
    
    return notification
end

function NotificationLib:Notify(text, duration, color)
    task.spawn(function()
        self:CreateNotification(text, duration, color)
    end)
end

function NotificationLib:WelcomePlayer()
    task.spawn(function()
        while not self.ready do
            task.wait()
        end
        
        local success, player = pcall(function()
            return game:GetService("Players").LocalPlayer
        end)
        
        if success and player then
            local name = player.DisplayName ~= player.Name and player.DisplayName or player.Name
            self:Notify("Welcome, "..name.."!", 5, Color3.fromRGB(255, 215, 0))
        end
    end)
end

function NotificationLib:Destroy()
    if currentInstance == self then
        currentInstance = nil
    end
    
    if self.container then
        self.container:Destroy()
    end
    
    if self.activeNotifications then
        for _, notification in ipairs(self.activeNotifications) do
            if notification and notification.remove then
                notification.remove()
            end
        end
    end
    
    self.activeNotifications = nil
    self.container = nil
    self.queuedNotifications = nil
end

return NotificationLib
