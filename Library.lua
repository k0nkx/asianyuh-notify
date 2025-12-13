local NotificationLib = {}
NotificationLib.__index = NotificationLib

-- Store a reference to the current instance
local currentInstance = nil

-- Notification types
NotificationLib.Types = {
    NORMAL = "normal",
    FAST = "fast", 
    INSTANT = "instant",
    NODELAY = "nodelay"
}

-- Start with a high base ZIndex to ensure it's above other elements
local BASE_ZINDEX = 100000

function NotificationLib.new()
    -- Clean up previous instance if it exists
    if currentInstance then
        currentInstance:Destroy()
    end
    
    local self = setmetatable({}, NotificationLib)
    currentInstance = self
    
    self.container = Instance.new("ScreenGui")
    self.container.Name = "NotificationContainer_" .. tostring(math.random(1, 1000000))
    -- Set to Global to ensure it renders on top of other ScreenGuis
    self.container.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.container.DisplayOrder = 99999 -- Very high display order
    self.container.IgnoreGuiInset = true -- Ensure full screen coverage
    self.container.Enabled = true
    self.container.Parent = game:GetService("CoreGui") or (gethui and gethui()) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    self.activeNotifications = {}
    self.ready = false
    self.queuedNotifications = {}
    self.currentZIndex = BASE_ZINDEX
    
    -- Wait for game to fully load
    task.spawn(function()
        -- Wait for player to be loaded
        local player = game:GetService("Players").LocalPlayer
        while not player.Character do
            player.CharacterAdded:Wait()
            task.wait(1) -- Additional buffer time
        end
        
        -- Additional loading checks if needed
        if game:IsLoaded() == false then
            game.Loaded:Wait()
        end
        
        -- Wait for the core UI to be ready
        task.wait(1)
        
        self.ready = true
        
        -- Process any queued notifications
        for _, notificationData in ipairs(self.queuedNotifications) do
            self:CreateNotification(notificationData.text, notificationData.duration, notificationData.color, notificationData.type)
        end
        self.queuedNotifications = {}
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

function NotificationLib:TypeWriter(textLabel, fullText, speed, type)
    if type == NotificationLib.Types.INSTANT or type == NotificationLib.Types.NODELAY then
        -- Instant text display
        textLabel.Text = fullText
        return
    end
    
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

function NotificationLib:CreateNotification(text, duration, color, type)
    if not self.ready then
        table.insert(self.queuedNotifications, {
            text = text,
            duration = duration,
            color = color,
            type = type
        })
        return
    end

    -- Set default type to NORMAL if not provided
    type = type or NotificationLib.Types.NORMAL

    local textService = game:GetService("TextService")
    local textWidth = textService:GetTextSize(text, 12, Enum.Font.Ubuntu, Vector2.new(10000, 10000)).X
    local minWidth = math.max(textWidth + 24, 150)

    -- Increment ZIndex for each new notification
    self.currentZIndex = self.currentZIndex + 1
    
    local outerFrame = Instance.new("Frame")
    outerFrame.Name = "OuterFrame"
    outerFrame.Position = UDim2.new(0, -minWidth - 2, 0, -32)
    outerFrame.Size = UDim2.new(0, minWidth + 4, 0, 25)
    outerFrame.BackgroundTransparency = 0
    outerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    outerFrame.BorderSizePixel = 1
    outerFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    outerFrame.ClipsDescendants = true
    outerFrame.ZIndex = self.currentZIndex + 4
    outerFrame.Parent = self.container

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.Position = UDim2.new(0, 1, 0, 1)
    holder.Size = UDim2.new(1, -2, 1, -2)
    holder.BackgroundTransparency = 0
    holder.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.ZIndex = self.currentZIndex + 5
    holder.Parent = outerFrame

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, -4, 1, -4)
    background.Position = UDim2.new(0, 2, 0, 2)
    background.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    background.BorderSizePixel = 0
    background.ZIndex = self.currentZIndex + 6
    background.Parent = holder

    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Size = UDim2.new(0, 2, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = self.currentZIndex + 7
    accentBar.Parent = background

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, 0, 0, 1)
    progressBar.Position = UDim2.new(0, 0, 1, -1)
    progressBar.BackgroundColor3 = color
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = self.currentZIndex + 8
    progressBar.Parent = background

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TextLabel"
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Position = UDim2.new(0, 8, 0, 0)
    textLabel.Size = UDim2.new(1, -8, 1, 0)
    textLabel.Font = Enum.Font.Ubuntu
    textLabel.Text = ""
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 12
    textLabel.BackgroundTransparency = 1
    textLabel.TextTransparency = 0
    textLabel.ZIndex = self.currentZIndex + 9
    textLabel.Parent = background

    -- Hover effect for entire notification
    local hoverConn = outerFrame.MouseEnter:Connect(function()
        for _, element in pairs({outerFrame, holder, background, accentBar, progressBar, textLabel}) do
            game:GetService("TweenService"):Create(
                element,
                TweenInfo.new(0.2),
                {
                    BackgroundTransparency = element:IsA("TextLabel") and 0.8 or 0.8,
                    TextTransparency = element:IsA("TextLabel") and 0.2 or nil
                }
            ):Play()
        end
    end)

    outerFrame.MouseLeave:Connect(function()
        for _, element in pairs({outerFrame, holder, background, accentBar, progressBar, textLabel}) do
            game:GetService("TweenService"):Create(
                element,
                TweenInfo.new(0.2),
                {
                    BackgroundTransparency = element:IsA("TextLabel") and 1 or 0,
                    TextTransparency = element:IsA("TextLabel") and 0 or nil
                }
            ):Play()
        end
    end)

    local notification = {
        outerFrame = outerFrame,
        holder = holder,
        background = background,
        accentBar = accentBar,
        progressBar = progressBar,
        textLabel = textLabel,
        remove = nil,
        connections = {hoverConn},
        zIndex = self.currentZIndex
    }
    table.insert(self.activeNotifications, notification)

    self:UpdatePositions()

    -- Calculate typing speed based on type
    local baseSpeed = 0.05
    local typingSpeed = baseSpeed
    
    if type == NotificationLib.Types.FAST then
        typingSpeed = baseSpeed / 1.8  -- 1.8x faster
    elseif type == NotificationLib.Types.INSTANT then
        typingSpeed = baseSpeed / 3  -- 3x faster
    elseif type == NotificationLib.Types.NODELAY then
        typingSpeed = 0  -- Instant
    end

    -- Handle text animation based on type
    if type == NotificationLib.Types.NODELAY then
        -- No animations at all, just set text immediately
        textLabel.Text = text
    else
        -- Use typewriter effect with calculated speed
        task.spawn(function()
            self:TypeWriter(textLabel, text, typingSpeed, type)
        end)
    end

    local typingDuration = type == NotificationLib.Types.NODELAY and 0 or (#text * typingSpeed)

    -- Handle progress bar animation
    if type == NotificationLib.Types.NODELAY then
        -- No progress bar animation for nodelay
        progressBar.Size = UDim2.new(0, 0, 0, 1)
    else
        task.delay(typingDuration, function()
            game:GetService("TweenService"):Create(
                progressBar,
                TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 0, 0, 1)}
            ):Play()
        end)
    end

    local function Remove()
        for i, notif in ipairs(self.activeNotifications) do
            if notif == notification then
                table.remove(self.activeNotifications, i)
                break
            end
        end

        if notification.connections then
            for _, conn in ipairs(notification.connections) do
                if conn then
                    conn:Disconnect()
                end
            end
        end

        local fadeOutGroup = {}
        
        table.insert(fadeOutGroup, game:GetService("TweenService"):Create(
            outerFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(0, 10, 0, outerFrame.Position.Y.Offset - 20),
                Size = UDim2.new(0, 0, 0, outerFrame.AbsoluteSize.Y),
                BackgroundTransparency = 1,
                BorderSizePixel = 0
            }
        ))
        
        for _, element in pairs({holder, background, accentBar, progressBar, textLabel}) do
            table.insert(fadeOutGroup, game:GetService("TweenService"):Create(
                element,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                element:IsA("TextLabel") and {TextTransparency = 1} or {BackgroundTransparency = 1}
            ))
        end
        
        for _, tween in ipairs(fadeOutGroup) do
            tween:Play()
        end
        
        task.delay(0.3, function()
            outerFrame:Destroy()
            self:UpdatePositions()
        end)
    end

    notification.remove = Remove

    task.delay(typingDuration + duration, Remove)
    
    return notification
end

function NotificationLib:Notify(text, duration, color, type)
    task.spawn(function()
        self:CreateNotification(text, duration or 5, color or Color3.fromRGB(255, 255, 255), type)
    end)
end

function NotificationLib:WelcomePlayer(type)
    if not self.ready then
        -- Queue the welcome message if game isn't loaded yet
        task.spawn(function()
            while not self.ready do
                task.wait()
            end
            local playerName = game:GetService("Players").LocalPlayer.Name
            local displayName = game:GetService("Players").LocalPlayer.DisplayName
            local welcomeName = displayName ~= playerName and displayName or playerName
            self:Notify("Welcome, "..welcomeName.."!", 5, Color3.fromRGB(255, 215, 0), type)
        end)
        return
    end
    
    local playerName = game:GetService("Players").LocalPlayer.Name
    local displayName = game:GetService("Players").LocalPlayer.DisplayName
    local welcomeName = displayName ~= playerName and displayName or playerName
    self:Notify("Welcome, "..welcomeName.."!", 5, Color3.fromRGB(255, 215, 0), type)
end

function NotificationLib:Destroy()
    -- Clear the current instance reference if it's this one
    if currentInstance == self then
        currentInstance = nil
    end
    
    for _, notification in ipairs(self.activeNotifications) do
        if notification.remove then
            notification.remove()
        end
    end
    
    if self.container then
        self.container:Destroy()
    end
    
    self.activeNotifications = nil
    self.container = nil
    self.queuedNotifications = nil
    self.currentZIndex = nil
end

return NotificationLib
