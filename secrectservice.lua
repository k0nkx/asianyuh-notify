-- NotificationModule.lua
local NotificationModule = {}

local HttpService = (cloneref and cloneref(game:GetService("HttpService"))) or game:GetService("HttpService")
local CoreGui = (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
local TweenService = (cloneref and cloneref(game:GetService("TweenService"))) or game:GetService("TweenService")

local AccentColor = Color3.fromRGB(120, 100, 180)
local BackgroundColor = Color3.fromRGB(15, 15, 15)

local ScreenGui = nil
local Holder = nil
local fontFace = nil

local function loadFont()
    if not isfile("Tahoma.ttf") then
        writefile("Tahoma.ttf", game:HttpGet("https://github.com/k0nkx/UI-Lib-Tuff/raw/refs/heads/main/Windows-XP-Tahoma.ttf"))
    end

    writefile("Tahoma.font", HttpService:JSONEncode({
        name = "Tahoma",
        faces = {{
            name = "Regular", weight = 400, style = "normal",
            assetId = getcustomasset("Tahoma.ttf")
        }}
    }))

    fontFace = Font.new(getcustomasset("Tahoma.font"), Enum.FontWeight.Regular)
end

local function setupUI()
    if CoreGui:FindFirstChild("SecretService_Notifications") then
        CoreGui.SecretService_Notifications:Destroy()
    end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SecretService_Notifications"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    
    Holder = Instance.new("Frame")
    Holder.Name = "NotifHolder"
    Holder.BackgroundTransparency = 1
    Holder.Position = UDim2.new(0, 20, 0, 20)
    Holder.Size = UDim2.new(0, 250, 1, 0)
    Holder.AnchorPoint = Vector2.new(0, 0)
    Holder.Parent = ScreenGui
    
    local Layout = Instance.new("UIListLayout", Holder)
    Layout.VerticalAlignment = Enum.VerticalAlignment.Top
    Layout.Padding = UDim.new(0, 12)
end

function NotificationModule:Notify(title, content, duration)
    if not ScreenGui then
        loadFont()
        setupUI()
    end
    
    local Main = Instance.new("Frame")
    Main.BackgroundColor3 = BackgroundColor
    Main.BorderSizePixel = 0
    Main.Size = UDim2.new(1, 0, 0, 65)
    Main.ZIndex = 2
    Main.BackgroundTransparency = 1
    Main.Parent = Holder
    
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
    
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 4)
    
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Color3.fromRGB(45, 45, 45)
    Stroke.Thickness = 1
    Stroke.Transparency = 1
    
    local Accent = Instance.new("Frame")
    Accent.BackgroundColor3 = AccentColor
    Accent.BorderSizePixel = 0
    Accent.Size = UDim2.new(1, 0, 0, 2)
    Accent.ZIndex = 3
    Accent.Parent = Main
    Accent.BackgroundTransparency = 1
    Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 4)
    
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, AccentColor),
        ColorSequenceKeypoint.new(0.5, AccentColor),
        ColorSequenceKeypoint.new(1, AccentColor)
    })
    Gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    Gradient.Parent = Accent
    
    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 10)
    Title.Size = UDim2.new(1, -24, 0, 20)
    Title.FontFace = fontFace
    Title.Text = title
    Title.TextColor3 = Color3.fromRGB(240, 240, 240)
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 3
    Title.Parent = Main
    Title.TextTransparency = 1
    
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
    
    Main.Position = UDim2.new(0, 0, 0, 0)
    
    local fadeIn = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    
    local strokeFadeIn = TweenService:Create(Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0
    })
    
    local accentFadeIn = TweenService:Create(Accent, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    
    local titleFadeIn = TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    
    local descFadeIn = TweenService:Create(Description, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    
    fadeIn:Play()
    strokeFadeIn:Play()
    accentFadeIn:Play()
    titleFadeIn:Play()
    descFadeIn:Play()
    
    task.delay(duration or 5, function()
        local fadeOut = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        
        local strokeFadeOut = TweenService:Create(Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Transparency = 1
        })
        
        local accentFadeOut = TweenService:Create(Accent, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        
        local titleFadeOut = TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        })
        
        local descFadeOut = TweenService:Create(Description, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        })
        
        fadeOut:Play()
        strokeFadeOut:Play()
        accentFadeOut:Play()
        titleFadeOut:Play()
        descFadeOut:Play()
        
        task.wait(0.3)
        Main:Destroy()
    end)
end

return NotificationModule
