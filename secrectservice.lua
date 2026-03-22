-- NotificationModule.lua
local NotificationModule = {}

local HttpService = (cloneref and cloneref(game:GetService("HttpService"))) or game:GetService("HttpService")
local CoreGui = (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
local TweenService = (cloneref and cloneref(game:GetService("TweenService"))) or game:GetService("TweenService")

-- Configuration
local Config = {
    AccentColor = Color3.fromRGB(120, 100, 180),
    BackgroundColor = Color3.fromRGB(15, 15, 15),
    NotificationWidth = 250,
    NotificationHeight = 65,
    FadeDuration = 0.3,
    DefaultDuration = 5,
    Padding = 12,
    Offset = 20,
    FontName = "Tahoma",
    FontUrl = "https://github.com/k0nkx/UI-Lib-Tuff/raw/refs/heads/main/Windows-XP-Tahoma.ttf"
}

-- Private variables
local ScreenGui = nil
local Holder = nil
local fontFace = nil
local isInitialized = false

-- Private functions
local function loadFont()
    if not isfile(Config.FontName .. ".ttf") then
        writefile(Config.FontName .. ".ttf", game:HttpGet(Config.FontUrl))
    end
    
    writefile(Config.FontName .. ".font", HttpService:JSONEncode({
        name = Config.FontName,
        faces = {{
            name = "Regular", 
            weight = 400, 
            style = "normal",
            assetId = getcustomasset(Config.FontName .. ".ttf")
        }}
    }))
    
    fontFace = Font.new(getcustomasset(Config.FontName .. ".font"), Enum.FontWeight.Regular)
end

local function createNotificationUI()
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NotificationModule"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local parent = (gethui and gethui()) or 
                   (syn and syn.protect_gui and (syn.protect_gui(ScreenGui) or CoreGui)) or 
                   CoreGui
    ScreenGui.Parent = parent
    
    Holder = Instance.new("Frame")
    Holder.Name = "NotificationHolder"
    Holder.BackgroundTransparency = 1
    Holder.Position = UDim2.new(0, Config.Offset, 0, Config.Offset)
    Holder.Size = UDim2.new(0, Config.NotificationWidth, 1, 0)
    Holder.AnchorPoint = Vector2.new(0, 0)
    Holder.Parent = ScreenGui
    
    local Layout = Instance.new("UIListLayout", Holder)
    Layout.VerticalAlignment = Enum.VerticalAlignment.Top
    Layout.Padding = UDim.new(0, Config.Padding)
end

local function createNotificationElement(title, content)
    local Main = Instance.new("Frame")
    Main.BackgroundColor3 = Config.BackgroundColor
    Main.BorderSizePixel = 0
    Main.Size = UDim2.new(1, 0, 0, Config.NotificationHeight)
    Main.ZIndex = 2
    Main.BackgroundTransparency = 1
    Main.Parent = Holder
    
    -- Glow effect
    local Glow = Instance.new("ImageLabel")
    Glow.Name = "Glow"
    Glow.BackgroundTransparency = 1
    Glow.Position = UDim2.new(0, -15, 0, -15)
    Glow.Size = UDim2.new(1, 30, 1, 30)
    Glow.Image = "rbxassetid://4996891970"
    Glow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Glow.ImageTransparency = 0.4
    Glow.ScaleType = Enum.ScaleType.Slice
    Glow.SliceCenter = Rect.new(20, 20, 280, 280)
    Glow.ZIndex = 1
    Glow.Parent = Main
    Glow.BackgroundTransparency = 1
    
    -- Corner radius
    local Corner = Instance.new("UICorner", Main)
    Corner.CornerRadius = UDim.new(0, 4)
    
    -- Stroke
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Color3.fromRGB(45, 45, 45)
    Stroke.Thickness = 1
    Stroke.Transparency = 1
    
    -- Accent bar
    local Accent = Instance.new("Frame")
    Accent.BackgroundColor3 = Config.AccentColor
    Accent.BorderSizePixel = 0
    Accent.Size = UDim2.new(1, 0, 0, 2)
    Accent.ZIndex = 3
    Accent.Parent = Main
    Accent.BackgroundTransparency = 1
    Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 4)
    
    -- Gradient for accent bar
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.AccentColor),
        ColorSequenceKeypoint.new(0.5, Config.AccentColor),
        ColorSequenceKeypoint.new(1, Config.AccentColor)
    })
    Gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    Gradient.Parent = Accent
    
    -- Title text
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position = UDim2.new(0, 12, 0, 10)
    TitleLabel.Size = UDim2.new(1, -24, 0, 20)
    TitleLabel.FontFace = fontFace
    TitleLabel.Text = title
    TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 3
    TitleLabel.Parent = Main
    TitleLabel.TextTransparency = 1
    
    -- Description text
    local Description = Instance.new("TextLabel")
    Description.BackgroundTransparency = 1
    Description.Position = UDim2.new(0, 12, 0, 32)
    Description.Size = UDim2.new(1, -24, 0, 20)
    Description.FontFace = fontFace
    Description.Text = content
    Description.TextColor3 = Color3.fromRGB(160, 160, 160)
    Description.TextSize = 14
    Description.TextXAlignment = Enum.TextXAlignment.Left
    Description.ZIndex = 3
    Description.Parent = Main
    Description.TextTransparency = 1
    
    return {
        Main = Main,
        Stroke = Stroke,
        Accent = Accent,
        Title = TitleLabel,
        Description = Description
    }
end

local function animateFadeIn(elements)
    local fadeIn = TweenService:Create(elements.Main, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    
    local strokeFadeIn = TweenService:Create(elements.Stroke, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0
    })
    
    local accentFadeIn = TweenService:Create(elements.Accent, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    
    local titleFadeIn = TweenService:Create(elements.Title, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    
    local descFadeIn = TweenService:Create(elements.Description, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    
    fadeIn:Play()
    strokeFadeIn:Play()
    accentFadeIn:Play()
    titleFadeIn:Play()
    descFadeIn:Play()
    
    return true
end

local function animateFadeOut(elements)
    local fadeOut = TweenService:Create(elements.Main, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    
    local strokeFadeOut = TweenService:Create(elements.Stroke, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Transparency = 1
    })
    
    local accentFadeOut = TweenService:Create(elements.Accent, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    })
    
    local titleFadeOut = TweenService:Create(elements.Title, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1
    })
    
    local descFadeOut = TweenService:Create(elements.Description, TweenInfo.new(Config.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1
    })
    
    fadeOut:Play()
    strokeFadeOut:Play()
    accentFadeOut:Play()
    titleFadeOut:Play()
    descFadeOut:Play()
    
    return true
end

-- Public functions
function NotificationModule:Initialize(config)
    if isInitialized then
        return self
    end
    
    if config then
        for key, value in pairs(config) do
            if Config[key] ~= nil then
                Config[key] = value
            end
        end
    end
    
    loadFont()
    createNotificationUI()
    isInitialized = true
    
    return self
end

function NotificationModule:Notify(title, content, duration)
    if not isInitialized then
        self:Initialize()
    end
    
    duration = duration or Config.DefaultDuration
    
    local elements = createNotificationElement(title, content)
    animateFadeIn(elements)
    
    task.delay(duration, function()
        animateFadeOut(elements)
        task.wait(Config.FadeDuration)
        elements.Main:Destroy()
    end)
    
    return self
end

function NotificationModule:SetAccentColor(color)
    Config.AccentColor = color
    return self
end

function NotificationModule:SetBackgroundColor(color)
    Config.BackgroundColor = color
    return self
end

function NotificationModule:SetFadeDuration(duration)
    Config.FadeDuration = duration
    return self
end

function NotificationModule:SetDefaultDuration(duration)
    Config.DefaultDuration = duration
    return self
end

function NotificationModule:SetPosition(offsetX, offsetY)
    if Holder then
        Holder.Position = UDim2.new(0, offsetX or Config.Offset, 0, offsetY or Config.Offset)
    end
    Config.Offset = offsetX or Config.Offset
    return self
end

function NotificationModule:ClearAll()
    if Holder then
        for _, child in ipairs(Holder:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    return self
end

function NotificationModule:Destroy()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    isInitialized = false
    ScreenGui = nil
    Holder = nil
    return self
end

return NotificationModule
