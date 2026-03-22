local NotificationModule = {}

local existingModule = nil
for _, obj in pairs(coreGui:GetChildren()) do
    if obj.Name == "NotificationModule_Instance" then
        existingModule = obj
        break
    end
end

if existingModule then
    local moduleInterface = {
        Initialize = function(self, config)
            if existingModule:FindFirstChild("Config") then
                local configFrame = existingModule.Config
                if config then
                    for key, value in pairs(config) do
                        if configFrame[key] ~= nil then
                            configFrame[key] = value
                        end
                    end
                end
            end
            return self
        end,
        
        Notify = function(self, title, content, duration)
            existingModule:WaitForChild("Notifier"):Notify(title, content, duration or 5)
            return self
        end,
        
        SetAccentColor = function(self, color)
            local config = existingModule:FindFirstChild("Config")
            if config then
                config.AccentColor = color
                for _, notif in pairs(existingModule.Holder:GetChildren()) do
                    if notif:IsA("Frame") and notif:FindFirstChild("Accent") then
                        notif.Accent.BackgroundColor3 = color
                        if notif.Accent:FindFirstChild("Gradient") then
                            local gradient = notif.Accent.Gradient
                            gradient.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, color),
                                ColorSequenceKeypoint.new(0.5, color),
                                ColorSequenceKeypoint.new(1, color)
                            })
                        end
                    end
                end
            end
            return self
        end,
        
        SetBackgroundColor = function(self, color)
            local config = existingModule:FindFirstChild("Config")
            if config then
                config.BackgroundColor = color
                for _, notif in pairs(existingModule.Holder:GetChildren()) do
                    if notif:IsA("Frame") and notif:FindFirstChild("Main") then
                        notif.Main.BackgroundColor3 = color
                    end
                end
            end
            return self
        end,
        
        SetFadeDuration = function(self, duration)
            local config = existingModule:FindFirstChild("Config")
            if config then
                config.FadeDuration = duration
            end
            return self
        end,
        
        SetDefaultDuration = function(self, duration)
            local config = existingModule:FindFirstChild("Config")
            if config then
                config.DefaultDuration = duration
            end
            return self
        end,
        
        SetPosition = function(self, offsetX, offsetY)
            local holder = existingModule:FindFirstChild("Holder")
            if holder then
                holder.Position = UDim2.new(0, offsetX or 20, 0, offsetY or 20)
            end
            return self
        end,
        
        ClearAll = function(self)
            local holder = existingModule:FindFirstChild("Holder")
            if holder then
                for _, child in ipairs(holder:GetChildren()) do
                    if child:IsA("Frame") then
                        child:Destroy()
                    end
                end
            end
            return self
        end,
        
        Destroy = function(self)
            if existingModule and existingModule.Parent then
                existingModule:Destroy()
            end
            return self
        end
    }
    
    return moduleInterface
end

local HttpService = (cloneref and cloneref(game:GetService("HttpService"))) or game:GetService("HttpService")
local CoreGui = (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
local TweenService = (cloneref and cloneref(game:GetService("TweenService"))) or game:GetService("TweenService")

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

-- Create main container in CoreGui only
local ModuleContainer = Instance.new("ScreenGui")
ModuleContainer.Name = "NotificationModule_Instance"
ModuleContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ModuleContainer.ResetOnSpawn = false
ModuleContainer.IgnoreGuiInset = true

local parent = CoreGui
ModuleContainer.Parent = parent

local ConfigStore = Instance.new("Folder")
ConfigStore.Name = "Config"
for key, value in pairs(Config) do
    ConfigStore[key] = value
end
ConfigStore.Parent = ModuleContainer

local Holder = Instance.new("Frame")
Holder.Name = "Holder"
Holder.BackgroundTransparency = 1
Holder.Position = UDim2.new(0, Config.Offset, 0, Config.Offset)
Holder.Size = UDim2.new(0, Config.NotificationWidth, 1, 0)
Holder.AnchorPoint = Vector2.new(0, 0)
Holder.Parent = ModuleContainer

local Layout = Instance.new("UIListLayout", Holder)
Layout.VerticalAlignment = Enum.VerticalAlignment.Top
Layout.Padding = UDim.new(0, Config.Padding)

local fontFace = nil
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
loadFont()

local function createNotification(title, content, duration)
    local Main = Instance.new("Frame")
    Main.BackgroundColor3 = ConfigStore.BackgroundColor
    Main.BorderSizePixel = 0
    Main.Size = UDim2.new(1, 0, 0, ConfigStore.NotificationHeight)
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
    
    local Corner = Instance.new("UICorner", Main)
    Corner.CornerRadius = UDim.new(0, 4)
    
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Color3.fromRGB(45, 45, 45)
    Stroke.Thickness = 1
    Stroke.Transparency = 1
    
    local Accent = Instance.new("Frame")
    Accent.BackgroundColor3 = ConfigStore.AccentColor
    Accent.BorderSizePixel = 0
    Accent.Size = UDim2.new(1, 0, 0, 2)
    Accent.ZIndex = 3
    Accent.Parent = Main
    Accent.BackgroundTransparency = 1
    Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 4)
    
    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ConfigStore.AccentColor),
        ColorSequenceKeypoint.new(0.5, ConfigStore.AccentColor),
        ColorSequenceKeypoint.new(1, ConfigStore.AccentColor)
    })
    Gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    Gradient.Parent = Accent
    
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
    
    local fadeIn = TweenService:Create(Main, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    
    local strokeFadeIn = TweenService:Create(Stroke, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 0
    })
    
    local accentFadeIn = TweenService:Create(Accent, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    })
    
    local titleFadeIn = TweenService:Create(TitleLabel, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    
    local descFadeIn = TweenService:Create(Description, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    })
    
    fadeIn:Play()
    strokeFadeIn:Play()
    accentFadeIn:Play()
    titleFadeIn:Play()
    descFadeIn:Play()
    
    task.delay(duration or ConfigStore.DefaultDuration, function()
        local fadeOut = TweenService:Create(Main, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        
        local strokeFadeOut = TweenService:Create(Stroke, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Transparency = 1
        })
        
        local accentFadeOut = TweenService:Create(Accent, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })
        
        local titleFadeOut = TweenService:Create(TitleLabel, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        })
        
        local descFadeOut = TweenService:Create(Description, TweenInfo.new(ConfigStore.FadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        })
        
        fadeOut:Play()
        strokeFadeOut:Play()
        accentFadeOut:Play()
        titleFadeOut:Play()
        descFadeOut:Play()
        
        task.wait(ConfigStore.FadeDuration)
        Main:Destroy()
    end)
    
    return Main
end

local Notifier = {}
function Notifier:Notify(title, content, duration)
    createNotification(title, content, duration)
end

local NotifierInstance = Instance.new("Folder")
NotifierInstance.Name = "Notifier"
NotifierInstance.Parent = ModuleContainer

for methodName, methodFunc in pairs(Notifier) do
    NotifierInstance[methodName] = methodFunc
end

local ModuleInterface = {
    Initialize = function(self, config)
        if config then
            for key, value in pairs(config) do
                if ConfigStore[key] ~= nil then
                    ConfigStore[key] = value
                end
            end
        end
        return self
    end,
    
    Notify = function(self, title, content, duration)
        NotifierInstance:Notify(title, content, duration or ConfigStore.DefaultDuration)
        return self
    end,
    
    SetAccentColor = function(self, color)
        ConfigStore.AccentColor = color
        for _, notif in pairs(Holder:GetChildren()) do
            if notif:IsA("Frame") and notif:FindFirstChild("Accent") then
                notif.Accent.BackgroundColor3 = color
                if notif.Accent:FindFirstChild("Gradient") then
                    local gradient = notif.Accent.Gradient
                    gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, color),
                        ColorSequenceKeypoint.new(0.5, color),
                        ColorSequenceKeypoint.new(1, color)
                    })
                end
            end
        end
        return self
    end,
    
    SetBackgroundColor = function(self, color)
        ConfigStore.BackgroundColor = color
        for _, notif in pairs(Holder:GetChildren()) do
            if notif:IsA("Frame") then
                notif.BackgroundColor3 = color
            end
        end
        return self
    end,
    
    SetFadeDuration = function(self, duration)
        ConfigStore.FadeDuration = duration
        return self
    end,
    
    SetDefaultDuration = function(self, duration)
        ConfigStore.DefaultDuration = duration
        return self
    end,
    
    SetPosition = function(self, offsetX, offsetY)
        Holder.Position = UDim2.new(0, offsetX or ConfigStore.Offset, 0, offsetY or ConfigStore.Offset)
        ConfigStore.Offset = offsetX or ConfigStore.Offset
        return self
    end,
    
    ClearAll = function(self)
        for _, child in ipairs(Holder:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        return self
    end,
    
    Destroy = function(self)
        if ModuleContainer and ModuleContainer.Parent then
            ModuleContainer:Destroy()
        end
        return self
    end
}

return ModuleInterface
