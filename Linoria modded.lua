if _G.NotificationLibrary then
    _G.NotificationLibrary.Cleanup()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NotificationGui"
ScreenGui.Parent = game:GetService("CoreGui")

local TweenService = game:GetService("TweenService")

local Library = {
    MainColor = Color3.fromRGB(30, 30, 35),
    OutlineColor = Color3.fromRGB(50, 50, 55),
    AccentColor = Color3.fromRGB(0, 120, 215),
    FontColor = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.Gotham,
    DPIScale = 1,
    Registry = {},
    ActiveNotifications = {},
    ScreenGui = ScreenGui
}

function Library:GetDarkerColor(color)
    return Color3.new(
        math.max(color.R - 0.1, 0),
        math.max(color.G - 0.1, 0),
        math.max(color.B - 0.1, 0)
    )
end

function Library:GetTextBounds(text, font, size)
    local textLabel = Instance.new("TextLabel")
    textLabel.Font = font
    textLabel.TextSize = size
    textLabel.Text = text
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.Size = UDim2.new(0, 300, 0, 100)
    textLabel.Parent = ScreenGui
    
    local bounds = textLabel.TextBounds
    local xSize = bounds.X + 4
    local ySize = bounds.Y + 4
    
    textLabel:Destroy()
    
    return xSize, ySize
end

function Library:Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

function Library:CreateLabel(properties)
    local label = self:Create("TextLabel", properties)
    label.BackgroundTransparency = 1
    label.TextColor3 = self.FontColor
    label.Font = self.Font
    label.TextWrapped = true
    label.TextScaled = false
    return label
end

function Library:AddToRegistry(instance, colorProperties, updateExisting)
    if updateExisting then
        for prop, colorKey in pairs(colorProperties) do
            if colorKey == "MainColor" then
                instance[prop] = self.MainColor
            elseif colorKey == "OutlineColor" then
                instance[prop] = self.OutlineColor
            elseif colorKey == "AccentColor" then
                instance[prop] = self.AccentColor
            elseif colorKey == "FontColor" then
                instance[prop] = self.FontColor
            end
        end
    end
    
    table.insert(self.Registry, {
        Instance = instance,
        Properties = colorProperties
    })
end

function Library:GetCustomIcon(iconName)
    local icons = {
        info = { Url = "rbxassetid://1234567890" },
        warning = { Url = "rbxassetid://1234567890" },
        error = { Url = "rbxassetid://1234567890" },
        success = { Url = "rbxassetid://1234567890" }
    }
    
    return icons[iconName] or (type(iconName) == "string" and { Url = iconName } or nil)
end

local BottomArea = Library:Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.5, 0, 1, -50),
    Size = UDim2.new(0, 400, 0, 200),
    ZIndex = 11000,
    Parent = ScreenGui,
})

Library:Create("UIListLayout", {
    Padding = UDim.new(0, 8),
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = BottomArea,
})

function Library:Cleanup()
    for _, notification in ipairs(self.ActiveNotifications) do
        pcall(function()
            if notification and notification.Destroy then
                notification:Destroy()
            end
        end)
    end
    self.ActiveNotifications = {}
    
    if self.ScreenGui then
        pcall(function()
            self.ScreenGui:Destroy()
        end)
    end
    
    if self.Registry then
        for _, item in ipairs(self.Registry) do
            pcall(function()
                if item.Instance and item.Instance.Parent then
                    item.Instance:Destroy()
                end
            end)
        end
        self.Registry = {}
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    if typeof(Info) == "table" then
        Data.Title = Info.Title and tostring(Info.Title) or ""
        Data.Description = tostring(Info.Description)
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Persist = Info.Persist
        Data.Icon = Info.Icon
        Data.IconColor = Info.IconColor
    else
        Data.Title = ""
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
    end
    Data.Destroyed = false

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true
            DeleteConnection:Disconnect()
            DeleteConnection = nil
        end)
    end

    local XSize, YSize = Library:GetTextBounds(Data.Description, Library.Font, 14)
    YSize = YSize + 12

    local NotifyOuter = Library:Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 0, YSize),
        ClipsDescendants = true,
        ZIndex = 11000,
        Visible = false,
        Parent = BottomArea,
    })

    local NotifyInner = Library:Create("Frame", {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 11001,
        Parent = NotifyOuter,
    })

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
    }, true)

    local InnerFrame = Library:Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = 11002,
        Parent = NotifyInner,
    })

    local Gradient = Library:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        }),
        Rotation = -90,
        Parent = InnerFrame,
    })

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            })
        end
    })

    local ExtraWidth = 0
    local TextOffset = 0

    if Data.Icon then
        local ParsedIcon = Library:GetCustomIcon(Data.Icon)
        if ParsedIcon then
            ExtraWidth = 24
            TextOffset = 28
            
            local IconLabel = Library:Create("ImageLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Image = ParsedIcon.Url,
                ImageColor3 = Data.IconColor or Library.AccentColor,
                ZIndex = 11004,
                Parent = InnerFrame,
            })
            
            if not Data.IconColor then
                Library:AddToRegistry(IconLabel, {
                    ImageColor3 = "AccentColor",
                }, true)
            end
        end
    end

    local NotifyLabel = Library:CreateLabel({
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 8),
        Size = UDim2.new(1, -(TextOffset + 16), 1, -16),
        Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. Data.Description,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextSize = 14,
        ZIndex = 11003,
        RichText = true,
        Parent = InnerFrame,
    })

    local AccentBar = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, -1, 1, 1),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 2, 0, 3),
        ZIndex = 11004,
        Parent = NotifyOuter,
    })

    Library:AddToRegistry(AccentBar, {
        BackgroundColor3 = "AccentColor",
    }, true)

    function Data:Resize()
        local NewXSize, NewYSize = Library:GetTextBounds(NotifyLabel.Text, Library.Font, 14)
        NewYSize = NewYSize + 12
        XSize, YSize = NewXSize, NewYSize
        
        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, NewXSize + 24 + ExtraWidth, 0, NewYSize), "Out", "Quad", 0.3, true)
    end

    function Data:ChangeTitle(NewText)
        Data.Title = NewText and tostring(NewText) or ""
        NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. Data.Description
        Data:Resize()
    end

    function Data:ChangeDescription(NewText)
        Data.Description = tostring(NewText)
        NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. Data.Description
        Data:Resize()
    end

    function Data:Destroy()
        if Data.Destroyed then return end
        Data.Destroyed = true
        
        for i, notif in ipairs(Library.ActiveNotifications) do
            if notif == Data then
                table.remove(Library.ActiveNotifications, i)
                break
            end
        end

        if typeof(Data.Time) == "Instance" then
            pcall(Data.Time.Destroy, Data.Time)
        end
        
        if DeleteConnection then
            DeleteConnection:Disconnect()
        end

        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.3, true)
        task.wait(0.3)
        NotifyOuter:Destroy()
    end

    Data:Resize()

    if Data.SoundId then
        local sound = Library:Create("Sound", {
            SoundId = "rbxassetid://" .. tostring(Data.SoundId):gsub("rbxassetid://", ""),
            Volume = 3,
            PlayOnRemove = true,
            Parent = game:GetService("SoundService"),
        })
        sound:Destroy()
    end

    NotifyOuter.Visible = true
    NotifyOuter.Size = UDim2.new(0, 0, 0, YSize)
    
    local TargetX = XSize + 24 + ExtraWidth
    local TargetY = YSize
    
    local ExpandTween = TweenService:Create(NotifyOuter, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, TargetX, 0, TargetY)
    })
    
    ExpandTween:Play()
    
    table.insert(Library.ActiveNotifications, Data)

    task.delay(0.4, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat
                task.wait()
            until DeletedInstance or Data.Destroyed
        else
            task.wait(Data.Time or 5)
        end

        if not Data.Destroyed then
            Data:Destroy()
        end
    end)

    return Data
end

_G.NotificationLibrary = Library

return Library
