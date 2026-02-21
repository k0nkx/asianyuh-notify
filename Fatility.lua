local NotificationLib = {}

local Players = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local function setup()
    local existingFolder = CoreGui:FindFirstChild("FatilityNotifications")
    if existingFolder then
        existingFolder:Destroy()
    end

    local Folder = Instance.new("Folder")
    Folder.Name = "FatilityNotifications"
    Folder.Parent = CoreGui

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HitNotifySystem"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = Folder

    local Container = Instance.new("Frame")
    Container.Name = "NotifyHolder"
    Container.Position = UDim2.new(0, 25, 0, 25) 
    Container.Size = UDim2.new(0, 500, 0, 800)
    Container.BackgroundTransparency = 1
    Container.Parent = ScreenGui
    Container.ClipsDescendants = true

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 4)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.VerticalAlignment = Enum.VerticalAlignment.Top 
    Layout.Parent = Container

    return {
        Container = Container,
        ScreenGui = ScreenGui,
        Folder = Folder
    }
end

local ui = setup()
local count = 0

local function generateRandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%"
    local randomString = ""
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        randomString = randomString .. string.sub(chars, randomIndex, randomIndex)
    end
    return randomString
end

local function createNotification(message, isHitNotification, victimName, partName, damage, remainingHealth)
    count += 1
    
    local Slot = Instance.new("Frame")
    Slot.Name = "NotifySlot-" .. generateRandomString(6)
    Slot.Size = UDim2.new(0, 500, 0, 24)
    Slot.BackgroundTransparency = 1
    Slot.LayoutOrder = count
    Slot.ClipsDescendants = true
    Slot.Parent = ui.Container

    local Label = Instance.new("CanvasGroup")
    Label.Name = "HitNotif"
    Label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Label.BackgroundTransparency = 0.5
    Label.BorderSizePixel = 0
    Label.GroupTransparency = 1
    
    Label.Position = UDim2.new(0, -400, 0, 0) 
    Label.Size = UDim2.new(0, 0, 1, 0)
    Label.AutomaticSize = Enum.AutomaticSize.X 
    Label.Parent = Slot
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Label
    
    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, 0, 1, 0)
    Text.BackgroundTransparency = 1
    Text.RichText = true
    Text.Font = Enum.Font.FredokaOne
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextSize = 13
    Text.TextXAlignment = Enum.TextXAlignment.Left
    Text.Parent = Label
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(0, 0, 0)
    Stroke.Thickness = 1
    Stroke.Parent = Text
    
    if isHitNotification then
        local pink = "#ff00ff"
        Text.Text = string.format(
            "Hit <font color='%s'>%s</font> in the <font color='%s'>%s</font> for <font color='%s'>-%d</font> (%d health remaining)",
            pink, victimName, pink, partName, pink, damage, remainingHealth
        )
    else
        Text.Text = message
    end

    local Padding = Instance.new("UIPadding")
    Padding.PaddingLeft = UDim.new(0, 30) 
    Padding.PaddingRight = UDim.new(0, 30)
    Padding.Parent = Label

    local Gradient = Instance.new("UIGradient")
    Gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    Gradient.Parent = Label

    local entryInfo = TweenInfo.new(0.2, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
    TweenService:Create(Label, entryInfo, {
        Position = UDim2.new(0, 0, 0, 0), 
        GroupTransparency = 0
    }):Play()

    task.delay(3.5, function()
        local exitInfo = TweenInfo.new(0.1, Enum.EasingStyle.Circular, Enum.EasingDirection.In)
        local exit = TweenService:Create(Label, exitInfo, {
            Position = UDim2.new(0, -400, 0, 0),
            GroupTransparency = 1
        })
        exit:Play()
        
        exit.Completed:Wait()
        
        local slotShrinkInfo = TweenInfo.new(0.1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
        local slotShrink = TweenService:Create(Slot, slotShrinkInfo, {
            Size = UDim2.new(0, 500, 0, 0)
        })
        slotShrink:Play()
        
        slotShrink.Completed:Wait()
        Slot:Destroy()
    end)
end

function NotificationLib:NotifyHit(victimName, partName, damage, remainingHealth)
    createNotification("", true, victimName, partName, damage, remainingHealth)
end

function NotificationLib:NotifyMessage(message)
    createNotification(message, false)
end

function NotificationLib:Destroy()
    if ui and ui.Folder then
        ui.Folder:Destroy()
    end
end

return NotificationLib
