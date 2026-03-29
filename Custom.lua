local NotificationLib = {}
NotificationLib.__index = NotificationLib

local currentInstance = nil

local function loadCustomFont()
    local success, customFontFace = pcall(function()
        local HttpService = game:GetService("HttpService")
        local fontData = {
            name = "Tahoma",
            url = "https://github.com/k0nkx/UI-Lib-Tuff/raw/refs/heads/main/Windows-XP-Tahoma.ttf"
        }

        if not isfile(fontData.name .. ".ttf") then
            writefile(fontData.name .. ".ttf", game:HttpGet(fontData.url))
        end

        local fontConfig = {
            name = fontData.name,
            faces = {{
                name = "Regular",
                weight = 400,
                style = "normal",
                assetId = getcustomasset(fontData.name .. ".ttf")
            }}
        }

        writefile(fontData.name .. ".font", HttpService:JSONEncode(fontConfig))
        return Font.new(getcustomasset(fontData.name .. ".font"), Enum.FontWeight.Regular)
    end)
    return success and customFontFace or nil
end

local customFontFace = loadCustomFont()

function NotificationLib.new()
    if currentInstance then
        currentInstance:Destroy()
    end
    
    local self = setmetatable({}, NotificationLib)
    currentInstance = self

    local parent = game:GetService("CoreGui") or (gethui and gethui()) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    for _, v in ipairs(parent:GetChildren()) do
        if v:IsA("ScreenGui") and string.find(v.Name, "NotifUi%-") then
            v:Destroy()
        end
    end
    
    self.container = Instance.new("ScreenGui")
    self.container.Name = "NotifUi-" .. tostring(math.random(1, 1000000))
    self.container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.container.DisplayOrder = 999999999 -- max z-layer
    self.container.ResetOnSpawn = false
    self.container.Parent = parent

    self.activeNotifications = {}
    self.ready = false
    self.queuedNotifications = {}
    
    task.spawn(function()
        local player = game:GetService("Players").LocalPlayer
        while not player.Character do
            player.CharacterAdded:Wait()
            task.wait()
        end
        
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end
        
        task.wait(1)
        
        self.ready = true
        
        for _, data in ipairs(self.queuedNotifications) do
            self:CreateNotification(data.text, data.duration, data.color)
        end
        self.queuedNotifications = {}
    end)
    
    return self
end

function NotificationLib:UpdatePositions()
    for i, notification in ipairs(self.activeNotifications) do
        if notification and notification.outerFrame and notification.outerFrame.Parent then
            local targetY = 20 + ((#self.activeNotifications - i) * 32)
            game:GetService("TweenService"):Create(
                notification.outerFrame,
                TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, 0, 1, -targetY)}
            ):Play()
        end
    end
end

function NotificationLib:CreateNotification(text, duration, color)
    if not self.ready then
        table.insert(self.queuedNotifications, {
            text = text,
            duration = duration,
            color = color
        })
        return
    end

    local textService = game:GetService("TextService")
    local size = textService:GetTextSize(text, 12, Enum.Font.Ubuntu, Vector2.new(1000, 100))
    
    local paddingX = 30
    local minWidth = 150
    local maxWidth = 500
    
    local finalWidth = math.clamp(size.X + paddingX, minWidth, maxWidth)

    local outerFrame = Instance.new("Frame")
    outerFrame.AnchorPoint = Vector2.new(0.5, 1)
    outerFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
    outerFrame.Size = UDim2.new(0, finalWidth, 0, 26)
    outerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    outerFrame.BorderSizePixel = 1
    outerFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    outerFrame.Parent = self.container

    local holder = Instance.new("Frame")
    holder.Position = UDim2.new(0, 1, 0, 1)
    holder.Size = UDim2.new(1, -2, 1, -2)
    holder.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
    holder.BorderSizePixel = 0
    holder.Parent = outerFrame

    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, -4, 1, -4)
    background.Position = UDim2.new(0, 2, 0, 2)
    background.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    background.BorderSizePixel = 0
    background.Parent = holder

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 1)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = color or Color3.fromRGB(255,255,255)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = background

    local textLabel = Instance.new("TextLabel")
    textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    textLabel.Size = UDim2.new(1, -10, 1, -6)
    textLabel.Font = Enum.Font.Ubuntu
    textLabel.Text = text
    textLabel.TextSize = 12
    textLabel.TextColor3 = Color3.new(1,1,1)
    textLabel.BackgroundTransparency = 1
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.TextWrapped = true

    -- apply custom font if loaded
    if customFontFace then
        pcall(function()
            textLabel.FontFace = customFontFace
        end)
    end

    textLabel.Parent = background

    local hoverConn = outerFrame.MouseEnter:Connect(function()
        for _, element in pairs({outerFrame, holder, background, textLabel}) do
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

    local leaveConn = outerFrame.MouseLeave:Connect(function()
        for _, element in pairs({outerFrame, holder, background, textLabel}) do
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
        connections = {hoverConn, leaveConn}
    }
    table.insert(self.activeNotifications, 1, notification)

    -- slide in smoothly
    outerFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
    self:UpdatePositions()

    local function Remove()
        for i, notif in ipairs(self.activeNotifications) do
            if notif == notification then
                table.remove(self.activeNotifications, i)
                break
            end
        end

        for _, conn in ipairs(notification.connections) do
            if conn then conn:Disconnect() end
        end

        local tween = game:GetService("TweenService"):Create(
            outerFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, 0, 1.2, 0), BackgroundTransparency = 1}
        )
        tween:Play()

        task.delay(0.35, function()
            if outerFrame then
                outerFrame:Destroy()
            end
            self:UpdatePositions()
        end)
    end

    task.delay(duration or 5, Remove)
end

function NotificationLib:Notify(text, duration, color)
    task.spawn(function()
        self:CreateNotification(text, duration or 5, color or Color3.fromRGB(255,255,255))
    end)
end

function NotificationLib:Destroy()
    if currentInstance == self then
        currentInstance = nil
    end
    
    for _, n in ipairs(self.activeNotifications) do
        if n.outerFrame then
            n.outerFrame:Destroy()
        end
    end
    
    if self.container then
        self.container:Destroy()
    end

    self.activeNotifications = {}
end

return NotificationLib
