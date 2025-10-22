local NotificationLib = {}
NotificationLib.__index = NotificationLib

-- Store a reference to the current instance
local currentInstance = nil

-- Notification type definitions
NotificationLib.Types = {
    NORMAL = "normal",      -- Current default behavior
    FAST = "fast",          -- 1.8x faster animations
    INSTANT = "instant",    -- 3x faster animations  
    NODELAY = "nodelay"     -- Instant animations except slide in/out
}

function NotificationLib.new()
    -- Clean up previous instance if it exists
    if currentInstance then
        currentInstance:Destroy()
    end
    
    local self = setmetatable({}, NotificationLib)
    currentInstance = self
    
    self.container = Instance.new("ScreenGui")
    self.container.Name = "NotificationContainer_" .. tostring(math.random(1, 1000000))
    self.container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.container.Parent = game:GetService("CoreGui") or (gethui and gethui()) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self.activeNotifications = {}
    self.ready = false
    self.queuedNotifications = {}
    
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
            self:CreateNotification(notificationData.text, notificationData.duration, notificationData.color, notificationData.notificationType)
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

function NotificationLib:TypeWriter(textLabel, fullText, speed, notificationType)
    local typedText = ""
    local cursorVisible = true
    local cursorTask = nil
    
    -- Apply speed multipliers based on notification type
    local actualSpeed = speed
    if notificationType == self.Types.FAST then
        actualSpeed = speed / 1.8
    elseif notificationType == self.Types.INSTANT then
        actualSpeed = speed / 3
    elseif notificationType == self.Types.NODELAY then
        -- For nodelay, skip typing animation entirely
        textLabel.Text = fullText
        return
    end
    
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
        task.wait(actualSpeed)
    end
    
    if cursorTask then
        task.cancel(cursorTask)
        textLabel.Text = fullText
    end
end

function NotificationLib:CreateNotification(text, duration, color, notificationType)
    notificationType = notificationType or self.Types.NORMAL
    
    if not self.ready then
        table.insert(self.queuedNotifications, {
            text = text,
            duration = duration,
            color = color,
            notificationType = notificationType
        })
        return
    end

    local textService = game:GetService("TextService")
    local textWidth = textService:GetTextSize(text, 12, Enum.Font.Ubuntu, Vector2.new(10000, 10000)).X
    local minWidth = math.max(textWidth + 24, 150)

    local outerFrame = Instance.new("Frame")
    outerFrame.Name = "OuterFrame"
    outerFrame.Position = UDim2.new(0, -minWidth - 2, 0, -32)
    outerFrame.Size = UDim2.new(0, minWidth + 4, 0, 25)
    outerFrame.BackgroundTransparency = 0
    outerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    outerFrame.BorderSizePixel = 1
    outerFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    outerFrame.ClipsDescendants = true
    outerFrame.Parent = self.container

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.Position = UDim2.new(0, 1, 0, 1)
    holder.Size = UDim2.new(1, -2, 1, -2)
    holder.BackgroundTransparency = 0
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
    textLabel.Position = UDim2.new(0, 8, 0, 0)
    textLabel.Size = UDim2.new(1, -8, 1, 0)
    textLabel.Font = Enum.Font.Ubuntu
    textLabel.Text = ""
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 12
    textLabel.BackgroundTransparency = 1
    textLabel.TextTransparency = 0
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
        notificationType = notificationType
    }
    table.insert(self.activeNotifications, notification)

    self:UpdatePositions()

    local typingSpeed = 0.05
    
    -- Handle different notification types for typing animation
    if notificationType == self.Types.NODELAY then
        textLabel.Text = text
    else
        task.spawn(function()
            self:TypeWriter(textLabel, text, typingSpeed, notificationType)
        end)
    end

    -- Calculate durations based on notification type
    local typingDuration = 0
    if notificationType == self.Types.NODELAY then
        typingDuration = 0
    else
        local speedMultiplier = 1
        if notificationType == self.Types.FAST then
            speedMultiplier = 1.8
        elseif notificationType == self.Types.INSTANT then
            speedMultiplier = 3
        end
        typingDuration = (#text * typingSpeed) / speedMultiplier
    end

    -- Handle progress bar animation based on notification type
    if notificationType == self.Types.NODELAY then
        -- For nodelay, set progress bar to 0 immediately (no animation)
        progressBar.Size = UDim2.new(0, 0, 0, 1)
    else
        local progressDuration = duration
        local progressTweenInfo = TweenInfo.new(progressDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        
        -- Apply speed multipliers to progress bar for FAST and INSTANT types
        if notificationType == self.Types.FAST then
            progressDuration = duration / 1.8
            progressTweenInfo = TweenInfo.new(progressDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        elseif notificationType == self.Types.INSTANT then
            progressDuration = duration / 3
            progressTweenInfo = TweenInfo.new(progressDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        end
        
        task.delay(typingDuration, function()
            game:GetService("TweenService"):Create(
                progressBar,
                progressTweenInfo,
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

    -- Set removal timer based on notification type
    local totalDuration = typingDuration + duration
    if notificationType == self.Types.FAST then
        totalDuration = typingDuration + (duration / 1.8)
    elseif notificationType == self.Types.INSTANT then
        totalDuration = typingDuration + (duration / 3)
    elseif notificationType == self.Types.NODELAY then
        totalDuration = duration  -- No typing delay for nodelay
    end

    task.delay(totalDuration, Remove)
    
    return notification
end

function NotificationLib:Notify(text, duration, color, notificationType)
    task.spawn(function()
        self:CreateNotification(text, duration or 5, color or Color3.fromRGB(255, 255, 255), notificationType or self.Types.NORMAL)
    end)
end

function NotificationLib:WelcomePlayer(notificationType)
    if not self.ready then
        -- Queue the welcome message if game isn't loaded yet
        task.spawn(function()
            while not self.ready do
                task.wait()
            end
            local playerName = game:GetService("Players").LocalPlayer.Name
            local displayName = game:GetService("Players").LocalPlayer.DisplayName
            local welcomeName = displayName ~= playerName and displayName or playerName
            self:Notify("Welcome, "..welcomeName.."!", 5, Color3.fromRGB(255, 215, 0), notificationType)
        end)
        return
    end
    
    local playerName = game:GetService("Players").LocalPlayer.Name
    local displayName = game:GetService("Players").LocalPlayer.DisplayName
    local welcomeName = displayName ~= playerName and displayName or playerName
    self:Notify("Welcome, "..welcomeName.."!", 5, Color3.fromRGB(255, 215, 0), notificationType)
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
end

return NotificationLib
