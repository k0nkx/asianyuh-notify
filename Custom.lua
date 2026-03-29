local NotificationLib = {}
NotificationLib.__index = NotificationLib

local currentInstance = nil
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- load custom font (fallback to Ubuntu if fails)
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

-- protect GUI like ping visualizer
local function protectGui(gui)
    gui.AncestryChanged:Connect(function()
        if gui.Parent ~= CoreGui then
            local ok, _ = pcall(function() gui.Parent = CoreGui end)
            if not ok then gui:Destroy() end
        end
    end)
end

function NotificationLib.new()
    if currentInstance then
        currentInstance:Destroy()
    end
    
    local self = setmetatable({}, NotificationLib)
    currentInstance = self

    -- cleanup old containers
    for _, v in ipairs(CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") and string.find(v.Name, "NotifUi%-") then
            v:Destroy()
        end
    end
    
    self.container = Instance.new("ScreenGui")
    self.container.Name = "NotifUi-" .. tostring(math.random(1, 1000000))
    self.container.ZIndexBehavior = Enum.ZIndexBehavior.Global
    self.container.DisplayOrder = 999 -- stay on top
    self.container.ResetOnSpawn = false
    self.container.Parent = CoreGui

    protectGui(self.container)

    self.activeNotifications = {}
    self.ready = true
    self.queuedNotifications = {}
    
    return self
end

function NotificationLib:UpdatePositions()
    for i, notification in ipairs(self.activeNotifications) do
        if notification and notification.outerFrame and notification.outerFrame.Parent then
            local targetY = 20 + ((#self.activeNotifications - i) * 32)
            TweenService:Create(
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

    local sizeX = math.clamp(#text * 8 + 30, 150, 500)

    local outerFrame = Instance.new("Frame")
    outerFrame.AnchorPoint = Vector2.new(0.5, 1)
    outerFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
    outerFrame.Size = UDim2.new(0, sizeX, 0, 26)
    outerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    outerFrame.BorderSizePixel = 1
    outerFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    outerFrame.ZIndex = 2147483647
    outerFrame.Parent = self.container

    local holder = Instance.new("Frame")
    holder.Position = UDim2.new(0, 1, 0, 1)
    holder.Size = UDim2.new(1, -2, 1, -2)
    holder.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
    holder.BorderSizePixel = 0
    holder.ZIndex = 2147483647
    holder.Parent = outerFrame

    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, -4, 1, -4)
    background.Position = UDim2.new(0, 2, 0, 2)
    background.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    background.BorderSizePixel = 0
    background.ZIndex = 2147483647
    background.Parent = holder

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 0, 1)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = color or Color3.fromRGB(255,255,255)
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 2147483647
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
    textLabel.ZIndex = 2147483647

    if customFontFace then
        pcall(function()
            textLabel.FontFace = customFontFace
        end)
    end

    textLabel.Parent = background

    local notification = {
        outerFrame = outerFrame
    }
    table.insert(self.activeNotifications, 1, notification)

    outerFrame.Position = UDim2.new(0.5, 0, 1.2, 0)
    self:UpdatePositions()

    local function Remove()
        for i, notif in ipairs(self.activeNotifications) do
            if notif == notification then
                table.remove(self.activeNotifications, i)
                break
            end
        end

        local tween = TweenService:Create(
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
