local NotificationLibrary = {}
local IsInitialized = false

local function Initialize()
    if IsInitialized then
        if _G.NotificationLibrary and _G.NotificationLibrary._ScreenGui then
            return _G.NotificationLibrary
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NotificationGui"
    ScreenGui.Parent = game:GetService("CoreGui")

    local TweenService = game:GetService("TweenService")

    local Library = {
        _ScreenGui = ScreenGui,
        _TweenService = TweenService,
        MainColor = Color3.fromRGB(30, 30, 35),
        OutlineColor = Color3.fromRGB(50, 50, 55),
        AccentColor = Color3.fromRGB(0, 120, 215),
        FontColor = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        DPIScale = 1,
        Registry = {}
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
        textLabel.Parent = self._ScreenGui
        
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

    Library.BottomNotificationArea = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 1, -40),
        Size = UDim2.new(0, 300, 0, 200),
        ZIndex = 11000,
        Parent = Library._ScreenGui,
    })

    Library:Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = Library.BottomNotificationArea,
    })

    function Library:Notify(...)
        local Data = {}
        local Info = select(1, ...)

        if typeof(Info) == "table" then
            Data.Title = Info.Title and tostring(Info.Title) or ""
            Data.Description = tostring(Info.Description)
            Data.Time = Info.Time or 5
            Data.SoundId = Info.SoundId
            Data.Steps = Info.Steps
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
        YSize = YSize + 7

        local NotifyOuter = Library:Create("Frame", {
            BorderColor3 = Color3.new(0, 0, 0),
            Size = UDim2.new(0, 0, 0, YSize),
            ClipsDescendants = true,
            ZIndex = 11000,
            Visible = false,
            Name = "Notif",
            Parent = Library.BottomNotificationArea,
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
        local TextPosition = UDim2.new(0.5, 0, 0, 0)
        local TextSizeOffsetX = -4
        local TextSizeOffsetY = 0

        local IconLabel
        if Data.Icon then
            local ParsedIcon = Library:GetCustomIcon(Data.Icon)
            if ParsedIcon then
                ExtraWidth = ExtraWidth + 20
                TextSizeOffsetX = TextSizeOffsetX - 20
                TextSizeOffsetY = TextSizeOffsetY - 2

                IconLabel = Library:Create("ImageLabel", {
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 4, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    Image = ParsedIcon.Url,
                    ImageColor3 = Data.IconColor or Library.FontColor,
                    ImageRectOffset = ParsedIcon.ImageRectOffset,
                    ImageRectSize = ParsedIcon.ImageRectSize,
                    ZIndex = 11004,
                    Parent = InnerFrame,
                })
                
                if not Data.IconColor then
                    Library:AddToRegistry(IconLabel, {
                        ImageColor3 = "FontColor",
                    }, true)
                end
                
                TextPosition = UDim2.new(0.5, 8, 0, 0)
            end
        end

        local NotifyLabel = Library:CreateLabel({
            AnchorPoint = Vector2.new(0.5, 0),
            Position = TextPosition,
            Size = UDim2.new(1, TextSizeOffsetX, 1, TextSizeOffsetY),
            Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextSize = 14,
            ZIndex = 11003,
            RichText = true,
            Parent = InnerFrame,
        })

        local SideColor = Library:Create("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, -1, 1, 1),
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 2, 0, 2),
            ZIndex = 11004,
            Parent = NotifyOuter,
        })

        Library:AddToRegistry(SideColor, {
            BackgroundColor3 = "AccentColor",
        }, true)

        function Data:Resize()
            XSize, YSize = Library:GetTextBounds(NotifyLabel.Text, Library.Font, 14)
            YSize = YSize + 7
            
            pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize * Library.DPIScale + 8 + 4 + ExtraWidth, 0, YSize), "Out", "Quad", 0.4, true)
        end

        function Data:ChangeTitle(NewText)
            NewText = NewText == nil and "" or tostring(NewText)
            Data.Title = NewText
            NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
            Data:Resize()
        end

        function Data:ChangeDescription(NewText)
            if NewText == nil then return end
            NewText = tostring(NewText)
            Data.Description = NewText
            NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
            Data:Resize()
        end

        function Data:ChangeStep(...)
        end

        function Data:Destroy()
            Data.Destroyed = true

            if typeof(Data.Time) == "Instance" then
                pcall(Data.Time.Destroy, Data.Time)
            end
            
            if DeleteConnection then
                DeleteConnection:Disconnect()
            end

            pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.4, true)
            task.wait(0.4)
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
        
        local TargetX = XSize * Library.DPIScale + 8 + 4 + ExtraWidth
        
        local LineTween = Library._TweenService:Create(NotifyOuter, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, TargetX, 0, YSize)
        })
        
        LineTween:Play()

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

    function Library:SetColor(colorType, color)
        if colorType == "Main" then
            self.MainColor = color
        elseif colorType == "Outline" then
            self.OutlineColor = color
        elseif colorType == "Accent" then
            self.AccentColor = color
        elseif colorType == "Font" then
            self.FontColor = color
        end
        
        for _, item in ipairs(self.Registry) do
            for prop, colorKey in pairs(item.Properties) do
                if colorKey == "MainColor" then
                    item.Instance[prop] = self.MainColor
                elseif colorKey == "OutlineColor" then
                    item.Instance[prop] = self.OutlineColor
                elseif colorKey == "AccentColor" then
                    item.Instance[prop] = self.AccentColor
                elseif colorKey == "FontColor" then
                    item.Instance[prop] = self.FontColor
                elseif type(colorKey) == "function" then
                    item.Instance[prop] = colorKey()
                end
            end
        end
    end

    function Library:Destroy()
        if self._ScreenGui then
            self._ScreenGui:Destroy()
        end
        IsInitialized = false
    end

    IsInitialized = true
    _G.NotificationLibrary = Library
    return Library
end

function NotificationLibrary.new()
    if _G.NotificationLibrary and _G.NotificationLibrary._ScreenGui and _G.NotificationLibrary._ScreenGui.Parent then
        return _G.NotificationLibrary
    end
    return Initialize()
end

function NotificationLibrary:Notify(...)
    local instance = self.new()
    return instance:Notify(...)
end

function NotificationLibrary:SetColor(colorType, color)
    local instance = self.new()
    instance:SetColor(colorType, color)
end

function NotificationLibrary:Destroy()
    if _G.NotificationLibrary then
        _G.NotificationLibrary:Destroy()
        _G.NotificationLibrary = nil
    end
    IsInitialized = false
end

setmetatable(NotificationLibrary, {
    __call = function(_, ...)
        return NotificationLibrary:Notify(...)
    end
})

return NotificationLibrary
