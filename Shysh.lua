-- إعدادات الخدمات
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

-- الإعدادات الرئيسية
local Settings = {
    ESP = {
        Enabled = false,
        BoxColor = Color3.new(1, 0, 0),
        DistanceColor = Color3.new(1, 1, 1),
        HealthGradient = { Color3.new(0, 1, 0), Color3.new(1, 1, 0), Color3.new(1, 0, 0) },
        SnaplineEnabled = true,
        SnaplinePosition = "Center",
        RainbowEnabled = false,
        NameESP = false,
        TeamCheck = true,
        OffScreenArrow = false
    },
    Aimbot = {
        Enabled = false,
        FOV = 90,
        MaxDistance = 200,
        ShowFOV = false,
        TargetPart = "Head",
        SmoothAim = 50,
        MagicAim = false,
        AutoFire = false,
        FullHead = false
    },
    Combo = {
        InfiniteJump = {
            Enabled = false,
            Connection = nil
        },
        Speed = {
            Enabled = false,
            Value = 3
        },
        NoWall = false
    }
}

-- تخزين الرسومات
local ESP_Drawings = {}
local CurrentTarget = nil

-- دوال مساعدة
local function GetTeam(player)
    return player and player.Team
end

local function IsSameTeam(p1, p2)
    if not Settings.ESP.TeamCheck then return false end
    local t1, t2 = GetTeam(p1), GetTeam(p2)
    return t1 and t2 and t1 == t2
end

-- إنشاء رسومات ESP للاعب
local function CreateESP(Player)
    if Player == LocalPlayer then return end
    local Drawings = {
        Box = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        Distance = Drawing.new("Text"),
        Snapline = Drawing.new("Line"),
        NameTag = Drawing.new("Text"),
        Arrow = Drawing.new("Triangle")
    }
    
    Drawings.Box.Thickness = 2
    Drawings.Box.Filled = false
    Drawings.Box.Color = Settings.ESP.BoxColor
    
    Drawings.HealthBar.Filled = true
    Drawings.HealthBar.Color = Color3.new(0, 1, 0)
    
    Drawings.Distance.Size = 16
    Drawings.Distance.Center = true
    Drawings.Distance.Color = Settings.ESP.DistanceColor
    
    Drawings.Snapline.Color = Settings.ESP.BoxColor
    
    Drawings.NameTag.Size = 16
    Drawings.NameTag.Center = true
    Drawings.NameTag.Color = Color3.new(1, 1, 1)
    Drawings.NameTag.Text = Player.Name
    
    Drawings.Arrow.Thickness = 2
    Drawings.Arrow.Color = Color3.new(1, 0, 0)
    Drawings.Arrow.Filled = false
    
    for _, DrawingObj in pairs(Drawings) do
        DrawingObj.Visible = false
    end
    
    ESP_Drawings[Player] = Drawings
end

-- تحديث ESP للاعب
local function UpdateESP(Player, Drawings)
    if not Settings.ESP.Enabled or not Player.Character or IsSameTeam(Player, LocalPlayer) then
        for _, DrawingObj in pairs(Drawings) do
            DrawingObj.Visible = false
        end
        return
    end
    
    local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
    local Head = Player.Character:FindFirstChild("Head")
    
    if not Humanoid or Humanoid.Health <= 0 or not Head then
        for _, DrawingObj in pairs(Drawings) do
            DrawingObj.Visible = false
        end
        return
    end
    
    local HeadPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
    local Distance = (Head.Position - Camera.CFrame.Position).Magnitude
    local Scale = 1000 / Distance
    
    Drawings.Box.Size = Vector2.new(Scale, Scale * 1.5)
    Drawings.Box.Position = Vector2.new(HeadPos.X - Scale/2, HeadPos.Y - Scale * 0.75)
    Drawings.Box.Visible = OnScreen
    
    local HealthPercent = Humanoid.Health / Humanoid.MaxHealth
    local HealthColorIndex = math.clamp(3 - HealthPercent * 2, 1, 3)
    local HealthColor = Settings.ESP.HealthGradient[math.floor(HealthColorIndex)]:Lerp(
        Settings.ESP.HealthGradient[math.ceil(HealthColorIndex)],
        HealthColorIndex % 1
    )
    
    Drawings.HealthBar.Size = Vector2.new(4, Scale * 1.5 * HealthPercent)
    Drawings.HealthBar.Position = Vector2.new(
        HeadPos.X + Scale/2 + 2,
        HeadPos.Y - Scale * 0.75 + (Scale * 1.5 * (1 - HealthPercent))
    )
    Drawings.HealthBar.Color = HealthColor
    Drawings.HealthBar.Visible = OnScreen
    
    Drawings.Distance.Text = math.floor(Distance) .. "m"
    Drawings.Distance.Position = Vector2.new(HeadPos.X, HeadPos.Y + Scale * 0.75 + 5)
    Drawings.Distance.Visible = OnScreen
    
    if Settings.ESP.NameESP then
        Drawings.NameTag.Position = Vector2.new(HeadPos.X, HeadPos.Y - Scale * 0.75 - 20)
        Drawings.NameTag.Visible = OnScreen
    else
        Drawings.NameTag.Visible = false
    end
    
    if Settings.ESP.RainbowEnabled then
        local Hue = (tick() * 0.5) % 1
        Drawings.Box.Color = Color3.fromHSV(Hue, 1, 1)
        Drawings.Snapline.Color = Color3.fromHSV(Hue, 1, 1)
        Drawings.Arrow.Color = Color3.fromHSV(Hue, 1, 1)
    else
        Drawings.Box.Color = Settings.ESP.BoxColor
        Drawings.Snapline.Color = Settings.ESP.BoxColor
        Drawings.Arrow.Color = Settings.ESP.BoxColor
    end
    
    if Settings.ESP.SnaplineEnabled and OnScreen then
        local SnaplineY
        if Settings.ESP.SnaplinePosition == "Bottom" then
            SnaplineY = Camera.ViewportSize.Y
        elseif Settings.ESP.SnaplinePosition == "Top" then
            SnaplineY = 0
        else
            SnaplineY = Camera.ViewportSize.Y / 2
        end
        
        Drawings.Snapline.From = Vector2.new(HeadPos.X, HeadPos.Y + Scale * 0.75)
        Drawings.Snapline.To = Vector2.new(Camera.ViewportSize.X / 2, SnaplineY)
        Drawings.Snapline.Visible = true
    else
        Drawings.Snapline.Visible = false
    end
    
    if Settings.ESP.OffScreenArrow and not OnScreen then
        local Center = Camera.ViewportSize / 2
        local Dir = (Vector2.new(HeadPos.X, HeadPos.Y) - Center).Unit
        local ArrowPos = Center + Dir * 100
        local Angle = math.atan2(Dir.Y, Dir.X)
        
        local Point1 = ArrowPos + Vector2.new(math.cos(Angle) * 20, math.sin(Angle) * 20)
        local Point2 = ArrowPos + Vector2.new(math.cos(Angle + 2.5) * 10, math.sin(Angle + 2.5) * 10)
        local Point3 = ArrowPos + Vector2.new(math.cos(Angle - 2.5) * 10, math.sin(Angle - 2.5) * 10)
        
        Drawings.Arrow.Point1 = Point1
        Drawings.Arrow.Point2 = Point2
        Drawings.Arrow.Point3 = Point3
        Drawings.Arrow.Visible = true
    else
        Drawings.Arrow.Visible = false
    end
end

-- دالة العثور على أفضل هدف
local function FindBestTarget()
    local BestTarget = nil
    local BestAngle = math.huge
    local BestDistance = math.huge
    
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            if Settings.ESP.TeamCheck and IsSameTeam(Player, LocalPlayer) then
                continue
            end
            local Head = Player.Character:FindFirstChild("Head")
            if Head then
                local Direction = (Head.Position - Camera.CFrame.Position).Unit
                local LookVector = Camera.CFrame.LookVector
                local Angle = math.deg(math.acos(Direction:Dot(LookVector)))
                local Distance = (Head.Position - Camera.CFrame.Position).Magnitude
                
                if Angle <= Settings.Aimbot.FOV / 2 and Distance <= Settings.Aimbot.MaxDistance then
                    local RaycastParams = RaycastParams.new()
                    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                    RaycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    
                    local RayResult = workspace:Raycast(Camera.CFrame.Position, Direction * Distance, RaycastParams)
                    if RayResult and RayResult.Instance:IsDescendantOf(Player.Character) then
                        if Angle < BestAngle then
                            BestAngle = Angle
                            BestDistance = Distance
                            BestTarget = Player
                        elseif Angle == BestAngle and Distance < BestDistance then
                            BestDistance = Distance
                            BestTarget = Player
                        end
                    end
                end
            end
        end
    end
    
    return BestTarget, BestAngle
end

-- دائرة FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100
FOVCircle.Filled = false
FOVCircle.Visible = Settings.Aimbot.ShowFOV
FOVCircle.Color = Color3.new(1, 1, 1)

-- إنشاء واجهة المستخدم
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 1000

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 370, 0, 400)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 100
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0.1, 0.1, 0.1)),
    ColorSequenceKeypoint.new(1, Color3.new(0.3, 0.3, 0.3))
})
UIGradient.Rotation = 90
UIGradient.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 101
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(0, 200, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.Text = "Advanced GUI v2.0"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 102
TitleLabel.Parent = TitleBar

-- زر الإغلاق (X)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -25, 0, 5)
CloseButton.BackgroundColor3 = Color3.new(1, 0, 0)
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 16
CloseButton.ZIndex = 102
CloseButton.Parent = TitleBar
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 20, 0, 20)
MinimizeButton.Position = UDim2.new(1, -50, 0, 5)
MinimizeButton.BackgroundColor3 = Color3.new(1, 0.5, 0)
MinimizeButton.TextColor3 = Color3.new(1, 1, 1)
MinimizeButton.Text = "-"
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextSize = 20
MinimizeButton.ZIndex = 102
MinimizeButton.Parent = TitleBar

local TabsFrame = Instance.new("Frame")
TabsFrame.Name = "TabsFrame"
TabsFrame.Size = UDim2.new(0, 150, 0, MainFrame.Size.Y.Offset - TitleBar.Size.Y.Offset)
TabsFrame.Position = UDim2.new(0, 0, 0, TitleBar.Size.Y.Offset)
TabsFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
TabsFrame.BorderSizePixel = 0
TabsFrame.ZIndex = 101
TabsFrame.Parent = MainFrame

local TabsCorner = Instance.new("UICorner")
TabsCorner.CornerRadius = UDim.new(0, 10)
TabsCorner.Parent = TabsFrame

-- أزرار التبويبات
local ESPTab = Instance.new("TextButton")
ESPTab.Name = "ESPTabButton"
ESPTab.Size = UDim2.new(1, -10, 0, 40)
ESPTab.Position = UDim2.new(0, 5, 0, 10)
ESPTab.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
ESPTab.TextColor3 = Color3.new(1, 1, 1)
ESPTab.Text = "ESP"
ESPTab.Font = Enum.Font.GothamBold
ESPTab.TextSize = 14
ESPTab.ZIndex = 102
ESPTab.Parent = TabsFrame

local ESPTabCorner = Instance.new("UICorner")
ESPTabCorner.CornerRadius = UDim.new(0, 5)
ESPTabCorner.Parent = ESPTab

local AimbotTab = Instance.new("TextButton")
AimbotTab.Name = "AimbotTabButton"
AimbotTab.Size = UDim2.new(1, -10, 0, 40)
AimbotTab.Position = UDim2.new(0, 5, 0, 60)
AimbotTab.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
AimbotTab.TextColor3 = Color3.new(1, 1, 1)
AimbotTab.Text = "Aimbot"
AimbotTab.Font = Enum.Font.GothamBold
AimbotTab.TextSize = 14
AimbotTab.ZIndex = 102
AimbotTab.Parent = TabsFrame

local AimbotTabCorner = Instance.new("UICorner")
AimbotTabCorner.CornerRadius = UDim.new(0, 5)
AimbotTabCorner.Parent = AimbotTab

local ComboTab = Instance.new("TextButton")
ComboTab.Name = "ComboTabButton"
ComboTab.Size = UDim2.new(1, -10, 0, 40)
ComboTab.Position = UDim2.new(0, 5, 0, 110)
ComboTab.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
ComboTab.TextColor3 = Color3.new(1, 1, 1)
ComboTab.Text = "Combo"
ComboTab.Font = Enum.Font.GothamBold
ComboTab.TextSize = 14
ComboTab.ZIndex = 102
ComboTab.Parent = TabsFrame

local ComboTabCorner = Instance.new("UICorner")
ComboTabCorner.CornerRadius = UDim.new(0, 5)
ComboTabCorner.Parent = ComboTab

-- إطارات المحتوى (ScrollingFrames)
local function CreateScrollTab(name)
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name = name .. "TabContent"
    Scroll.Size = UDim2.new(0, MainFrame.Size.X.Offset - TabsFrame.Size.X.Offset - 20, 0, MainFrame.Size.Y.Offset - TitleBar.Size.Y.Offset - 20)
    Scroll.Position = UDim2.new(0, TabsFrame.Size.X.Offset + 10, 0, TitleBar.Size.Y.Offset + 10)
    Scroll.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    Scroll.BorderSizePixel = 0
    Scroll.ZIndex = 101
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.ScrollBarThickness = 8
    Scroll.Parent = MainFrame
    return Scroll
end

local ESPContent = CreateScrollTab("ESP")
local AimbotContent = CreateScrollTab("Aimbot")
local ComboContent = CreateScrollTab("Combo")
AimbotContent.Visible = false
ComboContent.Visible = false

-- دوال مساعدة لوضع العناصر داخل الـ ScrollingFrame
local ESP_Y = 10
local AIMBOT_Y = 10
local COMBO_Y = 10

local function AddWidget(parent, widget, height, yVar)
    widget.Parent = parent
    widget.Position = UDim2.new(0, 10, 0, yVar)
    parent.CanvasSize = UDim2.new(0, 0, 0, yVar + height + 10)
    return yVar + height + 10
end

-- عناصر ESP
do
    -- ESP toggle
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "ESP"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    ESP_Y = AddWidget(ESPContent, btn, 40, ESP_Y)
    
    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.ESP.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.ESP.Enabled = not Settings.ESP.Enabled
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.ESP.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- Snapline toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Snapline"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    ESP_Y = AddWidget(ESPContent, btn, 40, ESP_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.ESP.SnaplineEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.ESP.SnaplineEnabled = not Settings.ESP.SnaplineEnabled
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.ESP.SnaplineEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- Snapline position label
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 180, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = "Position:"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 101
    ESP_Y = AddWidget(ESPContent, lbl, 20, ESP_Y)
    
    -- Snapline position dropdown
    local posBtn = Instance.new("TextButton")
    posBtn.Size = UDim2.new(0, 180, 0, 40)
    posBtn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    posBtn.TextColor3 = Color3.new(1, 1, 1)
    posBtn.Text = Settings.ESP.SnaplinePosition
    posBtn.Font = Enum.Font.GothamBold
    posBtn.TextSize = 14
    posBtn.TextXAlignment = Enum.TextXAlignment.Center
    posBtn.ZIndex = 101
    ESP_Y = AddWidget(ESPContent, posBtn, 40, ESP_Y)
    local posCycle = {"Center","Top","Bottom"}
    local posIdx = 1
    posBtn.MouseButton1Click:Connect(function()
        posIdx = posIdx % 3 + 1
        Settings.ESP.SnaplinePosition = posCycle[posIdx]
        posBtn.Text = Settings.ESP.SnaplinePosition
    end)
    
    -- Rainbow toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Rainbow"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    ESP_Y = AddWidget(ESPContent, btn, 40, ESP_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.ESP.RainbowEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.ESP.RainbowEnabled = not Settings.ESP.RainbowEnabled
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.ESP.RainbowEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- Name ESP toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Name ESP"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    ESP_Y = AddWidget(ESPContent, btn, 40, ESP_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.ESP.NameESP and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.ESP.NameESP = not Settings.ESP.NameESP
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.ESP.NameESP and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- Team Check toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Team Check"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    ESP_Y = AddWidget(ESPContent, btn, 40, ESP_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.ESP.TeamCheck and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.ESP.TeamCheck = not Settings.ESP.TeamCheck
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.ESP.TeamCheck and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- Off-Screen Arrow toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Off-Screen Arrow"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    ESP_Y = AddWidget(ESPContent, btn, 40, ESP_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.ESP.OffScreenArrow and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.ESP.OffScreenArrow = not Settings.ESP.OffScreenArrow
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.ESP.OffScreenArrow and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
end

-- عناصر Aimbot
do
    -- Aimbot toggle
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Aimbot"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, btn, 40, AIMBOT_Y)
    
    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.Aimbot.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.Aimbot.Enabled = not Settings.Aimbot.Enabled
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.Aimbot.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- FOV Circle toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "FOV Circle"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, btn, 40, AIMBOT_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.Aimbot.ShowFOV and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.Aimbot.ShowFOV = not Settings.Aimbot.ShowFOV
        FOVCircle.Visible = Settings.Aimbot.ShowFOV
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.Aimbot.ShowFOV and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- FOV label
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 180, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = "FOV:"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, lbl, 20, AIMBOT_Y)
    
    -- FOV textbox
    local fovBox = Instance.new("TextBox")
    fovBox.Size = UDim2.new(0, 180, 0, 40)
    fovBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    fovBox.TextColor3 = Color3.new(1, 1, 1)
    fovBox.Text = tostring(Settings.Aimbot.FOV)
    fovBox.Font = Enum.Font.GothamBold
    fovBox.TextSize = 14
    fovBox.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, fovBox, 40, AIMBOT_Y)
    fovBox.FocusLost:Connect(function(enter)
        if enter then
            local v = tonumber(fovBox.Text)
            if v then Settings.Aimbot.FOV = math.clamp(v,1,360) end
            fovBox.Text = tostring(Settings.Aimbot.FOV)
        end
    end)
    
    -- Max Distance label
    lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 180, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = "Max Distance:"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, lbl, 20, AIMBOT_Y)
    
    -- Distance textbox
    local distBox = Instance.new("TextBox")
    distBox.Size = UDim2.new(0, 180, 0, 40)
    distBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    distBox.TextColor3 = Color3.new(1, 1, 1)
    distBox.Text = tostring(Settings.Aimbot.MaxDistance)
    distBox.Font = Enum.Font.GothamBold
    distBox.TextSize = 14
    distBox.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, distBox, 40, AIMBOT_Y)
    distBox.FocusLost:Connect(function(enter)
        if enter then
            local v = tonumber(distBox.Text)
            if v then Settings.Aimbot.MaxDistance = math.max(v,1) end
            distBox.Text = tostring(Settings.Aimbot.MaxDistance)
        end
    end)
    
    -- Smooth Aim label
    lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 180, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = "Smooth Aim (1-100):"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, lbl, 20, AIMBOT_Y)
    
    -- Smooth Aim textbox
    local smoothBox = Instance.new("TextBox")
    smoothBox.Size = UDim2.new(0, 180, 0, 40)
    smoothBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    smoothBox.TextColor3 = Color3.new(1, 1, 1)
    smoothBox.Text = tostring(Settings.Aimbot.SmoothAim)
    smoothBox.Font = Enum.Font.GothamBold
    smoothBox.TextSize = 14
    smoothBox.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, smoothBox, 40, AIMBOT_Y)
    smoothBox.FocusLost:Connect(function(enter)
        if enter then
            local v = tonumber(smoothBox.Text)
            if v then Settings.Aimbot.SmoothAim = math.clamp(v,1,100) end
            smoothBox.Text = tostring(Settings.Aimbot.SmoothAim)
        end
    end)
    
    -- Magic Aim toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Magic Aim"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, btn, 40, AIMBOT_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.Aimbot.MagicAim and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.Aimbot.MagicAim = not Settings.Aimbot.MagicAim
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.Aimbot.MagicAim and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- Auto Fire toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Auto Fire"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, btn, 40, AIMBOT_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.Aimbot.AutoFire and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.Aimbot.AutoFire = not Settings.Aimbot.AutoFire
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.Aimbot.AutoFire and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- Full Head toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Full Head"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    AIMBOT_Y = AddWidget(AimbotContent, btn, 40, AIMBOT_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.Aimbot.FullHead and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.Aimbot.FullHead = not Settings.Aimbot.FullHead
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.Aimbot.FullHead and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
end

-- عناصر Combo
do
    -- Infinite Jump
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Infinite Jump"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    COMBO_Y = AddWidget(ComboContent, btn, 40, COMBO_Y)
    
    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.Combo.InfiniteJump.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.Combo.InfiniteJump.Enabled = not Settings.Combo.InfiniteJump.Enabled
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.Combo.InfiniteJump.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
        if Settings.Combo.InfiniteJump.Enabled then
            Settings.Combo.InfiniteJump.Connection = UserInputService.JumpRequest:Connect(function()
                if Settings.Combo.InfiniteJump.Enabled and LocalPlayer.Character then
                    local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if Humanoid then Humanoid:ChangeState("Jumping") end
                end
            end)
        else
            if Settings.Combo.InfiniteJump.Connection then
                Settings.Combo.InfiniteJump.Connection:Disconnect()
                Settings.Combo.InfiniteJump.Connection = nil
            end
        end
    end)
    
    -- Speed toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "Speed"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    COMBO_Y = AddWidget(ComboContent, btn, 40, COMBO_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.Combo.Speed.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.Combo.Speed.Enabled = not Settings.Combo.Speed.Enabled
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.Combo.Speed.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
    
    -- Speed value label
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 180, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = "Speed Value (1-6):"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 101
    COMBO_Y = AddWidget(ComboContent, lbl, 20, COMBO_Y)
    
    -- Speed value textbox
    local speedBox = Instance.new("TextBox")
    speedBox.Size = UDim2.new(0, 180, 0, 40)
    speedBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    speedBox.TextColor3 = Color3.new(1, 1, 1)
    speedBox.Text = tostring(Settings.Combo.Speed.Value)
    speedBox.Font = Enum.Font.GothamBold
    speedBox.TextSize = 14
    speedBox.ZIndex = 101
    COMBO_Y = AddWidget(ComboContent, speedBox, 40, COMBO_Y)
    speedBox.FocusLost:Connect(function(enter)
        if enter then
            local v = tonumber(speedBox.Text)
            if v then Settings.Combo.Speed.Value = math.clamp(v,1,6) end
            speedBox.Text = tostring(Settings.Combo.Speed.Value)
        end
    end)
    
    -- No Wall toggle
    btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = "No Wall"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.ZIndex = 101
    COMBO_Y = AddWidget(ComboContent, btn, 40, COMBO_Y)
    
    ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 20, 0, 20)
    ind.Position = UDim2.new(1, -25, 0, 5)
    ind.BackgroundColor3 = Settings.Combo.NoWall and Color3.new(0,1,0) or Color3.new(1,0,0)
    ind.BorderSizePixel = 0
    ind.ZIndex = 102
    ind.Parent = btn
    Instance.new("UICorner").CornerRadius = UDim.new(0,5).Parent = ind
    
    btn.MouseButton1Click:Connect(function()
        Settings.Combo.NoWall = not Settings.Combo.NoWall
        TweenService:Create(ind, TweenInfo.new(0.2), {BackgroundColor3 = Settings.Combo.NoWall and Color3.new(0,1,0) or Color3.new(1,0,0)}):Play()
    end)
end

-- تطبيق تأثير Hover على جميع الأزرار (باستثناء أزرار التبويبات التي لها تأثير خاص)
local function ApplyHover(btn)
    local origSize = btn.Size
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {Size = origSize + UDim2.new(0,5,0,5), BackgroundColor3 = Color3.new(0.25,0.25,0.25)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {Size = origSize, BackgroundColor3 = Color3.new(0.15,0.15,0.15)}):Play()
    end)
end

-- تطبيق Hover على جميع الأزرار
for _, obj in ipairs(MainFrame:GetDescendants()) do
    if obj:IsA("TextButton") and obj ~= MinimizeButton and obj ~= CloseButton then
        ApplyHover(obj)
    end
end
ApplyHover(MinimizeButton)
ApplyHover(CloseButton)

-- تبديل التبويبات
local CurrentTab = "ESP"
local function SwitchTab(tabName)
    CurrentTab = tabName
    ESPContent.Visible = (tabName == "ESP")
    AimbotContent.Visible = (tabName == "Aimbot")
    ComboContent.Visible = (tabName == "Combo")
    
    -- تحديث ألوان أزرار التبويبات
    ESPTab.BackgroundColor3 = (tabName == "ESP") and Color3.new(0.2,0.2,0.2) or Color3.new(0.15,0.15,0.15)
    AimbotTab.BackgroundColor3 = (tabName == "Aimbot") and Color3.new(0.2,0.2,0.2) or Color3.new(0.15,0.15,0.15)
    ComboTab.BackgroundColor3 = (tabName == "Combo") and Color3.new(0.2,0.2,0.2) or Color3.new(0.15,0.15,0.15)
end

ESPTab.MouseButton1Click:Connect(function() SwitchTab("ESP") end)
AimbotTab.MouseButton1Click:Connect(function() SwitchTab("Aimbot") end)
ComboTab.MouseButton1Click:Connect(function() SwitchTab("Combo") end)

-- حلقة التحديث الرئيسية
RunService.RenderStepped:Connect(function()
    -- تحديث دائرة FOV
    if Settings.Aimbot.ShowFOV and Camera then
        local Center = Camera.ViewportSize / 2
        FOVCircle.Position = Vector2.new(Center.X, Center.Y)
        FOVCircle.Radius = Settings.Aimbot.FOV * (Center.X / 360)
    end
    
    -- تحديث ESP
    for Player, Drawings in pairs(ESP_Drawings) do
        pcall(function() UpdateESP(Player, Drawings) end)
    end
    
    -- تحديث سرعة المشي و No Wall
    if LocalPlayer.Character then
        local Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            if Settings.Combo.Speed.Enabled then
                Humanoid.WalkSpeed = Settings.Combo.Speed.Value
            else
                Humanoid.WalkSpeed = 16
            end
        end
        if Settings.Combo.NoWall then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
    
    -- منطق Aimbot
    if Settings.Aimbot.Enabled and Camera then
        local BestTarget, BestAngle = FindBestTarget()
        
        if Settings.Aimbot.MagicAim and BestTarget then
            CurrentTarget = BestTarget
        else
            if BestTarget then
                if CurrentTarget and CurrentTarget ~= BestTarget then
                    if CurrentTarget.Character and CurrentTarget.Character:FindFirstChild("Head") then
                        local Head = CurrentTarget.Character.Head
                        local Dir = (Head.Position - Camera.CFrame.Position).Unit
                        local CurAngle = math.deg(math.acos(Dir:Dot(Camera.CFrame.LookVector)))
                        local Dist = (Head.Position - Camera.CFrame.Position).Magnitude
                        if CurAngle <= Settings.Aimbot.FOV/2 and Dist <= Settings.Aimbot.MaxDistance then
                            BestTarget = CurrentTarget
                        else
                            CurrentTarget = BestTarget
                        end
                    else
                        CurrentTarget = BestTarget
                    end
                else
                    CurrentTarget = BestTarget
                end
            else
                CurrentTarget = nil
            end
        end
        
        if CurrentTarget and CurrentTarget.Character then
            local Head = CurrentTarget.Character:FindFirstChild("Head")
            if Head then
                local TargetCF = CFrame.lookAt(Camera.CFrame.Position, Head.Position)
                local Speed = Settings.Aimbot.MagicAim and 1 or (Settings.Aimbot.SmoothAim / 100)
                Camera.CFrame = Camera.CFrame:Lerp(TargetCF, Speed)
            end
        end
        
        -- Auto Fire
        if Settings.Aimbot.AutoFire and CurrentTarget and CurrentTarget.Character then
            local Head = CurrentTarget.Character:FindFirstChild("Head")
            if Head then
                local Dir = (Head.Position - Camera.CFrame.Position).Unit
                local Look = Camera.CFrame.LookVector
                local Angle = math.deg(math.acos(Dir:Dot(Look)))
                if Angle < 5 then
                    local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if Tool then
                        Tool:Activate()
                    else
                        VirtualUser:Button1Down(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2))
                        wait(0.1)
                        VirtualUser:Button1Up(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2))
                    end
                end
            end
        end
    else
        CurrentTarget = nil
    end
end)

-- إضافة اللاعبين
Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then CreateESP(plr) end
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then CreateESP(plr) end
end

-- إزالة اللاعبين
Players.PlayerRemoving:Connect(function(plr)
    if ESP_Drawings[plr] then
        for _, d in pairs(ESP_Drawings[plr]) do d:Remove() end
        ESP_Drawings[plr] = nil
    end
    if CurrentTarget == plr then CurrentTarget = nil end
end)

-- تحديث الكاميرا
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

-- زر التصغير
local Minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {
        Size = Minimized and UDim2.new(0,370,0,30) or UDim2.new(0,370,0,400)
    }):Play()
    TabsFrame.Visible = not Minimized
    ESPContent.Visible = not Minimized and CurrentTab=="ESP"
    AimbotContent.Visible = not Minimized and CurrentTab=="Aimbot"
    ComboContent.Visible = not Minimized and CurrentTab=="Combo"
    MinimizeButton.Text = Minimized and "+" or "-"
end)
