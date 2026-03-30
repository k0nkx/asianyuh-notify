local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local PlayerGui
if RunService:IsStudio() or not pcall(function() local _ = CoreGui.Name end) then
    PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
else
    PlayerGui = CoreGui
end

local NotificationUI = Instance.new("ScreenGui")
NotificationUI.Name = "StandaloneNotifications"
NotificationUI.ResetOnSpawn = false
NotificationUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotificationUI.Parent = PlayerGui

local BottomNotificationArea = Instance.new("Frame")
BottomNotificationArea.AnchorPoint = Vector2.new(0.5, 1)
BottomNotificationArea.BackgroundTransparency = 1
BottomNotificationArea.Position = UDim2.new(0.5, 0, 1, -40)
BottomNotificationArea.Size = UDim2.new(0, 300, 0, 200)
BottomNotificationArea.ZIndex = 11000
BottomNotificationArea.Parent = NotificationUI

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 4)
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = BottomNotificationArea

local NotificationLibrary = {}
NotificationLibrary.MainColor = Color3.fromRGB(35, 35, 35)
NotificationLibrary.OutlineColor = Color3.fromRGB(20, 20, 20)
NotificationLibrary.AccentColor = Color3.fromRGB(150, 180, 255)
NotificationLibrary.FontColor = Color3.fromRGB(255, 255, 255)
NotificationLibrary.Font = Enum.Font.Code
NotificationLibrary.FontSize = 14
NotificationLibrary.DPIScale = 1

local function GetDarkerColor(col)
    local h, s, v = Color3.toHSV(col)
    return Color3.fromHSV(h, s, math.max(v - 0.1, 0))
end

local function GetTextBounds(text, font, size)
    local bounds = TextService:GetTextSize(text, size, font, Vector2.new(math.huge, math.huge))
    return bounds.X, bounds.Y
end

function NotificationLibrary:Notify(Info, ...)
    local Data = {}
    if type(Info) == "table" then
        Data.Title = Info.Title and tostring(Info.Title) or ""
        Data.Description = tostring(Info.Description)
        Data.Time = Info.Time or 5
        Data.Persist = Info.Persist
        Data.LineColor = Info.LineColor
    else
        Data.Title = ""
        Data.Description = tostring(Info)
        Data.Time = select(1, ...) or 5
    end
    Data.Destroyed = false

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true
            if DeleteConnection then
                DeleteConnection:Disconnect()
                DeleteConnection = nil
            end
        end)
    end

    local LabelText = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. Data.Description
    local XSize, YSize = GetTextBounds(LabelText, self.Font, self.FontSize)
    YSize = YSize + 7

    local NotifyOuter = Instance.new("Frame")
    NotifyOuter.BorderColor3 = Color3.new(0, 0, 0)
    NotifyOuter.Size = UDim2.new(0, 0, 0, YSize)
    NotifyOuter.ClipsDescendants = true
    NotifyOuter.ZIndex = 11000
    NotifyOuter.Visible = false
    NotifyOuter.Name = "Notif"
    NotifyOuter.Parent = BottomNotificationArea

    local NotifyInner = Instance.new("Frame")
    NotifyInner.BackgroundColor3 = self.MainColor
    NotifyInner.BorderColor3 = self.OutlineColor
    NotifyInner.BorderMode = Enum.BorderMode.Inset
    NotifyInner.Size = UDim2.new(1, 0, 1, 0)
    NotifyInner.ZIndex = 11001
    NotifyInner.Parent = NotifyOuter

    local InnerFrame = Instance.new("Frame")
    InnerFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Position = UDim2.new(0, 1, 0, 1)
    InnerFrame.Size = UDim2.new(1, -2, 1, -2)
    InnerFrame.ZIndex = 11002
    InnerFrame.Parent = NotifyInner

    local Gradient = Instance.new("UIGradient")
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, GetDarkerColor(self.MainColor)),
        ColorSequenceKeypoint.new(1, self.MainColor)
    })
    Gradient.Rotation = -90
    Gradient.Parent = InnerFrame

    local NotifyLabel = Instance.new("TextLabel")
    NotifyLabel.BackgroundTransparency = 1
    NotifyLabel.AnchorPoint = Vector2.new(0.5, 0)
    NotifyLabel.Position = UDim2.new(0.5, 0, 0, 0)
    NotifyLabel.Size = UDim2.new(1, -4, 1, 0)
    NotifyLabel.Text = LabelText
    NotifyLabel.TextXAlignment = Enum.TextXAlignment.Center
    NotifyLabel.Font = self.Font
    NotifyLabel.TextColor3 = self.FontColor
    NotifyLabel.TextSize = self.FontSize
    NotifyLabel.ZIndex = 11003
    NotifyLabel.RichText = true
    NotifyLabel.Parent = InnerFrame

    local SideColor = Instance.new("Frame")
    SideColor.AnchorPoint = Vector2.new(0, 1)
    SideColor.Position = UDim2.new(0, -1, 1, 1)
    SideColor.BackgroundColor3 = Data.LineColor or self.AccentColor
    SideColor.BorderSizePixel = 0
    SideColor.Size = UDim2.new(1, 2, 0, 2)
    SideColor.ZIndex = 11004
    SideColor.Parent = NotifyOuter

    function Data:Resize()
        LabelText = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
        XSize, YSize = GetTextBounds(LabelText, NotificationLibrary.Font, NotificationLibrary.FontSize)
        YSize = YSize + 7
        local targetX = XSize * NotificationLibrary.DPIScale + 12
        pcall(function()
            NotifyOuter:TweenSize(UDim2.new(0, targetX, 0, YSize), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4, true)
        end)
    end

    function Data:ChangeTitle(NewText)
        Data.Title = NewText == nil and "" or tostring(NewText)
        NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
        Data:Resize()
    end

    function Data:ChangeDescription(NewText)
        if NewText == nil then return end
        Data.Description = tostring(NewText)
        NotifyLabel.Text = (Data.Title == "" and "" or "[" .. Data.Title .. "] ") .. tostring(Data.Description)
        Data:Resize()
    end

    function Data:Destroy()
        Data.Destroyed = true
        if typeof(Data.Time) == "Instance" then
            pcall(function() Data.Time:Destroy() end)
        end
        if DeleteConnection then
            DeleteConnection:Disconnect()
            DeleteConnection = nil
        end
        pcall(function()
            NotifyOuter:TweenSize(UDim2.new(0, 0, 0, YSize), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4, true)
        end)
        task.wait(0.4)
        NotifyOuter:Destroy()
    end

    Data:Resize()
    NotifyOuter.Visible = true
    NotifyOuter.Size = UDim2.new(0, 0, 0, YSize)
    
    local TargetX = XSize * self.DPIScale + 12
    local LineTween = TweenService:Create(NotifyOuter, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, TargetX, 0, YSize)
    })
    LineTween:Play()

    task.delay(0.4, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat task.wait() until DeletedInstance or Data.Destroyed
        else
            task.wait(Data.Time or 5)
        end
        if not Data.Destroyed then
            Data:Destroy()
        end
    end)

    return Data
end

return NotificationLibrary
