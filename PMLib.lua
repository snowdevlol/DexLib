--[[
    PMLib  -  UI Library (estilo Performance Manager)
    Baseada no script "Performance Manage Server" by NarsEdv

    Uso rápido:

        local PMLib = loadstring(game:HttpGet("URL_DO_PMLib.lua"))()

        local Window = PMLib:CreateWindow({
            Title = "Minha Janela",
            Id = "MinhaJanela",              -- (opcional) reexecutar o script destrói a janela antiga
            Watermark = "by NarsEdv",        -- (opcional)
            ResetButton = {                  -- (opcional) botão da toolbar
                Title = "Reset all to Default",
                Callback = function() end
            }
        })

        local Tab = Window:Tab({ Title = "Main", Expanded = true })

        Tab:Button({ Title = "Button", Desc = "Test Button", Callback = function() end })
        Tab:Toggle({ Title = "Toggle", Type = "Checkbox", Value = false, Callback = function(state) end })
        Tab:Dropdown({ Title = "Dropdown", Values = {"A", "B"}, Value = "A", Callback = function(option) end })
        Tab:Slider({ Title = "Slider", Min = 0, Max = 100, Value = 50, Callback = function(v) end })
        Tab:Input({ Title = "Input", Placeholder = "...", Callback = function(text) end })
        Tab:Keybind({ Title = "Keybind", Value = Enum.KeyCode.F, Callback = function(key) end })
        Tab:Label({ Title = "Status", Value = "Ready" })
        Tab:Paragraph({ Title = "Info", Desc = "Texto longo com quebra de linha." })
        Tab:Section({ Title = "Subtítulo" })
]]

local Library = {
    Version = "1.0.0",
    Windows = {}
}

----------------------------------------------------------------------
-- Services / ambiente
----------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local executorEnv = getfenv()

while not Players.LocalPlayer do
    task.wait()
end
local LocalPlayer = Players.LocalPlayer

local function warnMsg(message)
    warn("[PMLib] " .. tostring(message))
end

local genv = nil
pcall(function()
    if type(executorEnv.getgenv) == "function" then
        genv = executorEnv.getgenv()
    end
end)

local function resolveHost()
    local getHiddenUi = executorEnv.gethui or executorEnv.get_hidden_gui
    if type(getHiddenUi) == "function" then
        local ok, hidden = pcall(getHiddenUi)
        if ok and typeof(hidden) == "Instance" then
            return hidden
        end
    end

    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok and typeof(coreGui) == "Instance" then
        return coreGui
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

----------------------------------------------------------------------
-- Tema / ícones
----------------------------------------------------------------------

Library.Theme = {
    Background = Color3.fromHex("#151515"),
    Surface = Color3.fromHex("#1A1A1A"),
    SecondarySurface = Color3.fromHex("#0D0D0D"),
    InspectorRow = Color3.fromHex("#181818"),
    SectionHeader = Color3.fromHex("#1B1B1B"),
    Subsection = Color3.fromHex("#181818"),
    Hover = Color3.fromHex("#282828"),
    Press = Color3.fromHex("#202020"),
    Border = Color3.fromHex("#000000"),
    SearchFocusBorder = Color3.fromHex("#4E4E4E"),
    Divider = Color3.fromHex("#000000"),
    Header = Color3.fromHex("#222222"),
    HeaderDivider = Color3.fromHex("#000000"),
    MutedText = Color3.fromHex("#969696"),
    PrimaryText = Color3.fromHex("#EBEBEB"),
    Active = Color3.fromHex("#FFFFFF"),
    Watermark = Color3.fromHex("#484848"),

    CheckFill = Color3.fromHex("#326FC2"),
    CheckBoxBg = Color3.fromHex("#121212"),
    CheckBoxBorder = Color3.fromHex("#000000"),

    ToggleOn = Color3.fromHex("#326FC2"),
    ToggleOff = Color3.fromHex("#282828"),
    ToggleOnIcon = Color3.fromHex("#000000"),

    ScrollTrack = Color3.fromHex("#161616"),
    ScrollHandle = Color3.fromHex("#4A4A4A"),
    ResizeActive = Color3.fromHex("#FFFFFF"),

    DropdownBtn = Color3.fromHex("#242424"),
    DropdownBtnHover = Color3.fromHex("#2E2E2E"),
    DropdownBtnPress = Color3.fromHex("#1D1D1D"),
    DropdownCard = Color3.fromHex("#1D1D1D"),
    DropdownOptionHover = Color3.fromHex("#282828"),
    DropdownOptionActive = Color3.fromHex("#303030"),

    BtnRestore = Color3.fromHex("#242424"),
    BtnRestoreHover = Color3.fromHex("#2F2F2F"),
    BtnRestorePress = Color3.fromHex("#1B1B1B"),
    BtnRestoreText = Color3.fromHex("#EBEBEB")
}

local Icon = {
    ArrowLeft = "rbxassetid://92473583511724",
    ArrowRight = "rbxassetid://73780377692148",
    ArrowUp = "rbxassetid://132169295529879",
    ArrowDown = "rbxassetid://139953983876976",
    Expand = "rbxassetid://92473583511724",
    Collapse = "rbxassetid://136612013728069",
    Close = "rbxassetid://110786993356448",
    Minimal = "rbxassetid://118026365011536",
    Maximize = "rbxassetid://134243273101015",
    Search = "rbxassetid://121018724060431",
    Checklist = "rbxassetid://93898873302694",
    ToggleOn = "rbxassetid://96479131758775",
    ToggleOff = "rbxassetid://118026365011536",
    Rotate = "rbxassetid://117913330389477"
}

-- Registro de ícones por nome (para usar Icon = "nome" nos elementos).
-- Nomes são case-insensitive e ignoram "-", "_" e espaços.
Library.Icons = {}

local function normalizeIconName(name)
    return (string.gsub(string.lower(tostring(name)), "[%s%-_]", ""))
end

function Library:RegisterIcon(name, asset)
    if type(asset) == "number" then
        asset = "rbxassetid://" .. tostring(asset)
    end
    Library.Icons[normalizeIconName(name)] = asset
end

for name, asset in pairs(Icon) do
    Library:RegisterIcon(name, asset)
end

-- Aceita "rbxassetid://123", número (id), URL, ou um nome registrado.
-- Nome desconhecido => nil (o elemento fica sem ícone, sem erro).
local function resolveIcon(icon)
    if icon == nil or icon == "" then
        return nil
    end
    if type(icon) == "number" then
        return "rbxassetid://" .. tostring(icon)
    end
    if type(icon) == "string" then
        if string.find(icon, "rbxasset", 1, true) or string.find(icon, "^https?://") then
            return icon
        end
        return Library.Icons[normalizeIconName(icon)]
    end
    return nil
end

----------------------------------------------------------------------
-- Utilidades
----------------------------------------------------------------------

local LABEL_RATIO = 0.60

local function randomName()
    local chars = {}
    for i = 1, 16 do
        chars[i] = string.char(math.random(97, 122))
    end
    return table.concat(chars)
end

local function create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function fire(callback, ...)
    if type(callback) ~= "function" then
        return
    end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(callback, table.unpack(args, 1, args.n))
        if not ok then
            warnMsg(err)
        end
    end)
end

local ActiveTweens = setmetatable({}, {__mode = "k"})

local function cancelTween(instance)
    local existing = ActiveTweens[instance]
    if existing then
        ActiveTweens[instance] = nil
        pcall(function()
            existing:Cancel()
        end)
    end
end

local function tween(instance, duration, properties, style, direction)
    cancelTween(instance)
    local object = TweenService:Create(
        instance,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
        properties
    )
    ActiveTweens[instance] = object
    object.Completed:Connect(function()
        if ActiveTweens[instance] == object then
            ActiveTweens[instance] = nil
        end
    end)
    object:Play()
    return object
end

local function cancelTweensUnder(root)
    for instance, object in pairs(ActiveTweens) do
        local ok, inside = pcall(function()
            return instance == root or instance:IsDescendantOf(root)
        end)
        if ok and inside then
            ActiveTweens[instance] = nil
            pcall(function()
                object:Cancel()
            end)
        end
    end
end

local function corner(parent, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 2)}, parent)
end

local function stroke(parent, color)
    return create("UIStroke", {
        Color = color,
        Thickness = 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, parent)
end

local function ensurePadding(parent, left, top, right, bottom)
    local existing = parent:FindFirstChildOfClass("UIPadding")
    if existing then
        existing.PaddingLeft = UDim.new(0, left or 0)
        existing.PaddingTop = UDim.new(0, top or 0)
        existing.PaddingRight = UDim.new(0, right or 0)
        existing.PaddingBottom = UDim.new(0, bottom or 0)
        return existing
    end
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0)
    }, parent)
end

local function listLayout(parent, gap)
    return create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 0)
    }, parent)
end

local function isTouchOnlyInput(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        return true
    end
    local ok, lastType = pcall(function()
        return UserInputService:GetLastInputType()
    end)
    return ok and lastType == Enum.UserInputType.Touch
end

local function isPointerPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function bindHover(button, idle, hover, press, isDisabled)
    local pointerInside = false
    local pressing = false

    local function disabled()
        return isDisabled ~= nil and isDisabled() == true
    end

    local function snapIdle()
        pointerInside = false
        pressing = false
        cancelTween(button)
        button.BackgroundColor3 = idle
    end

    button.MouseEnter:Connect(function()
        if disabled() or isTouchOnlyInput(nil) then
            return
        end
        pointerInside = true
        if not pressing then
            tween(button, 0.08, {BackgroundColor3 = hover})
        end
    end)

    button.MouseLeave:Connect(function()
        pointerInside = false
        pressing = false
        tween(button, 0.10, {BackgroundColor3 = idle})
    end)

    button.InputBegan:Connect(function(input)
        if disabled() then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressing = true
            tween(button, 0.06, {BackgroundColor3 = press})
        elseif input.UserInputType == Enum.UserInputType.Touch then
            pointerInside = false
            pressing = true
            cancelTween(button)
            button.BackgroundColor3 = press
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            snapIdle()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressing = false
            if pointerInside and not isTouchOnlyInput(input) then
                tween(button, 0.08, {BackgroundColor3 = hover})
            else
                tween(button, 0.10, {BackgroundColor3 = idle})
            end
        end
    end)

    button.MouseButton1Click:Connect(function()
        if isTouchOnlyInput(nil) or not pointerInside then
            snapIdle()
        end
    end)

    button:GetPropertyChangedSignal("Visible"):Connect(function()
        if not button.Visible then
            snapIdle()
        end
    end)
end

local function makeLabel(parent, text, theme, properties)
    local props = {
        BackgroundTransparency = 1,
        Font = Enum.Font.BuilderSans,
        Text = text,
        TextColor3 = theme.PrimaryText,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    }
    for key, value in pairs(properties or {}) do
        props[key] = value
    end
    return create("TextLabel", props, parent)
end

local function makeDivider(parent, theme, zIndex, insetTotal)
    return create("Frame", {
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, -(insetTotal or 0), 0, 1),
        BackgroundColor3 = theme.Divider,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = zIndex or 2
    }, parent)
end

local function makeColumnDivider(parent, theme)
    return create("Frame", {
        Position = UDim2.new(LABEL_RATIO, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = theme.Divider,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 2
    }, parent)
end

local function toColor3(value)
    if typeof(value) == "Color3" then
        return value
    end
    if type(value) == "string" then
        local ok, color = pcall(Color3.fromHex, value)
        if ok then
            return color
        end
    end
    return nil
end

local function trim(text)
    return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

----------------------------------------------------------------------
-- Classes
----------------------------------------------------------------------

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Element = {}
Element.__index = Element

----------------------------------------------------------------------
-- Element (base compartilhada por todos os controles)
----------------------------------------------------------------------

function Element:_syncSearch()
    if not self._entry then
        return
    end
    local cfg = self.Config
    self._entry.SearchText = string.lower(
        tostring(cfg.Title or "") .. " " .. tostring(cfg.Desc or "") .. " " .. tostring(self._searchExtra or "")
    )
end

function Element:SetTitle(text)
    self.Config.Title = text
    if self._titleLbl then
        self._titleLbl.Text = tostring(text)
    end
    self:_syncSearch()
end

function Element:SetDesc(text)
    self.Config.Desc = text
    if self._descLbl then
        self._descLbl.Text = tostring(text or "")
        self._descLbl.Visible = text ~= nil and text ~= ""
    end
    self:_syncSearch()
end

function Element:SetLocked(value)
    self.Locked = value and true or false
    local transparency = self.Locked and 0.5 or 0
    for _, inst in ipairs(self._dim or {}) do
        if inst and inst.Parent then
            inst.TextTransparency = transparency
        end
    end
end

function Element:SetVisible(value)
    self.Hidden = not value
    if self.Frame and self.Frame.Parent then
        self.Frame.Visible = value and true or false
    end
end

function Element:SetCallback(callback)
    self.Callback = callback
end

function Element:Destroy()
    local entries = self.Tab.Window.SearchEntries
    for i = #entries, 1, -1 do
        if entries[i].Element == self then
            table.remove(entries, i)
        end
    end
    if self._onDestroy then
        pcall(self._onDestroy)
    end
    if self.Frame then
        self.Frame:Destroy()
    end
end

----------------------------------------------------------------------
-- Construção de linhas
----------------------------------------------------------------------
-- Estrutura de uma linha:
--   row  (Frame/TextButton, AutomaticSize Y, UIListLayout)
--     top   (altura fixa: título à esquerda, controle à direita)
--     desc  (texto de descrição com quebra de linha, opcional)
--     divider (1px)

local function newElement(tab, cfg, opts)
    cfg = cfg or {}
    opts = opts or {}
    local theme = tab.Theme

    local el = setmetatable({
        Tab = tab,
        Config = cfg,
        Locked = cfg.Locked == true,
        Hidden = false,
        Callback = cfg.Callback
    }, Element)

    local topHeight = opts.TopHeight or 22
    local class = opts.Class or "Frame"

    local rowProps = {
        Size = UDim2.new(1, 0, 0, topHeight + 1),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.InspectorRow,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = tab:_nextOrder()
    }
    if class == "TextButton" then
        rowProps.AutoButtonColor = false
        rowProps.Text = ""
    end

    local row = create(class, rowProps, tab.Container)
    listLayout(row, 0)

    if opts.Hover then
        bindHover(row, theme.InspectorRow, theme.Hover, theme.Press, function()
            return el.Locked
        end)
    end

    local top = create("Frame", {
        Size = UDim2.new(1, 0, 0, topHeight),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 1
    }, row)

    if not opts.NoColumn then
        makeColumnDivider(top, theme)
    end

    local labelX = 16
    local iconId = resolveIcon(cfg.Icon)
    if iconId then
        create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 14, 0.5, 0),
            Size = UDim2.fromOffset(13, 13),
            BackgroundTransparency = 1,
            Image = iconId,
            ImageColor3 = theme.PrimaryText
        }, top)
        labelX = 32
    end

    local titleWidth
    if opts.NoColumn then
        titleWidth = UDim2.new(1, -(labelX + 8), 1, 0)
    else
        titleWidth = UDim2.new(LABEL_RATIO, -(labelX + 4), 1, 0)
    end

    local titleLbl = makeLabel(top, tostring(cfg.Title or ""), theme, {
        Position = UDim2.fromOffset(labelX, 0),
        Size = titleWidth,
        Font = opts.TitleFont or Enum.Font.BuilderSans,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    local hasDesc = cfg.Desc ~= nil and cfg.Desc ~= ""
    local descLbl = makeLabel(row, tostring(cfg.Desc or ""), theme, {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        TextSize = 10,
        TextColor3 = theme.MutedText,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = 2,
        Visible = hasDesc
    })
    ensurePadding(descLbl, labelX, 0, 8, 6)

    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Divider,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        LayoutOrder = 3
    }, row)

    el.Frame = row
    el.Top = top
    el._titleLbl = titleLbl
    el._descLbl = descLbl
    el._dim = {titleLbl}

    return el, row, top
end

local function finishElement(tab, el, searchExtra)
    el._searchExtra = searchExtra
    local entry = {
        Tab = tab,
        Element = el,
        SearchText = "",
        Sub = tab._currentSub
    }
    el._entry = entry
    table.insert(tab.Window.SearchEntries, entry)
    el:_syncSearch()
    el:SetLocked(el.Locked)
end

----------------------------------------------------------------------
-- Indicadores (checkbox / switch)
----------------------------------------------------------------------

local function makeCheckbox(parent, theme)
    local box = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(LABEL_RATIO, 8, 0.5, 0),
        Size = UDim2.fromOffset(15, 15),
        BackgroundColor3 = theme.CheckBoxBg,
        BorderSizePixel = 0
    }, parent)
    corner(box, 3)
    local boxStroke = stroke(box, theme.CheckBoxBorder)
    local boxScale = create("UIScale", {Scale = 1}, box)

    local checkIcon = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(11, 11),
        BackgroundTransparency = 1,
        Image = Icon.Checklist,
        ImageColor3 = theme.Active,
        ImageTransparency = 1,
        Visible = false
    }, box)

    local indicator = {Current = false}
    local animToken = 0

    function indicator.Apply(value, instant)
        indicator.Current = value
        animToken = animToken + 1
        local currentToken = animToken

        if value then
            checkIcon.Visible = true
            tween(box, 0.12, {BackgroundColor3 = theme.CheckFill})
            tween(boxStroke, 0.12, {Color = theme.CheckFill})
            cancelTween(boxScale)
            cancelTween(checkIcon)
            if instant then
                boxScale.Scale = 1
                checkIcon.Size = UDim2.fromOffset(11, 11)
                checkIcon.ImageTransparency = 0
            else
                boxScale.Scale = 0.84
                tween(boxScale, 0.18, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                checkIcon.Size = UDim2.fromOffset(2, 2)
                checkIcon.ImageTransparency = 0.25
                tween(checkIcon, 0.16, {ImageTransparency = 0, Size = UDim2.fromOffset(11, 11)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end
        else
            tween(box, 0.12, {BackgroundColor3 = theme.CheckBoxBg})
            tween(boxStroke, 0.12, {Color = theme.CheckBoxBorder})
            cancelTween(boxScale)
            cancelTween(checkIcon)
            if instant then
                boxScale.Scale = 1
                checkIcon.Visible = false
                checkIcon.ImageTransparency = 1
                checkIcon.Size = UDim2.fromOffset(2, 2)
            else
                boxScale.Scale = 0.9
                tween(boxScale, 0.14, {Scale = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local t = tween(checkIcon, 0.12, {ImageTransparency = 1, Size = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                t.Completed:Connect(function(playbackState)
                    if playbackState == Enum.PlaybackState.Completed and currentToken == animToken and not indicator.Current and checkIcon.Parent then
                        checkIcon.Visible = false
                    end
                end)
            end
        end
    end

    return indicator
end

local function makeSwitch(parent, theme)
    local track = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(LABEL_RATIO, 8, 0.5, 0),
        Size = UDim2.fromOffset(30, 16),
        BackgroundColor3 = theme.ToggleOff,
        BorderSizePixel = 0
    }, parent)
    corner(track, 8)

    local knob = create("Frame", {
        Position = UDim2.new(0, 2, 0.5, -6),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = theme.MutedText,
        BorderSizePixel = 0
    }, track)
    corner(knob, 6)

    local icon = create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(8, 8),
        BackgroundTransparency = 1,
        Image = Icon.ToggleOff,
        ImageColor3 = theme.Background
    }, knob)

    local indicator = {Current = false}

    function indicator.Apply(value, instant)
        indicator.Current = value
        local trackColor = value and theme.ToggleOn or theme.ToggleOff
        local knobPos = value and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        local knobColor = value and theme.Active or theme.MutedText

        icon.Image = value and Icon.ToggleOn or Icon.ToggleOff
        icon.ImageColor3 = value and theme.ToggleOnIcon or theme.Background

        if instant then
            cancelTween(track)
            cancelTween(knob)
            track.BackgroundColor3 = trackColor
            knob.Position = knobPos
            knob.BackgroundColor3 = knobColor
        else
            tween(track, 0.14, {BackgroundColor3 = trackColor})
            tween(knob, 0.14, {Position = knobPos, BackgroundColor3 = knobColor})
        end
    end

    return indicator
end

----------------------------------------------------------------------
-- Tab (seção em acordeão)
----------------------------------------------------------------------

function Tab:_nextOrder()
    self._order = self._order + 1
    return self._order
end

local function createAccordion(window, title, order, defaultExpanded)
    local theme = window.Theme

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = order
    }, window.MainScroll)
    listLayout(card, 0)

    local header = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundColor3 = theme.SectionHeader,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = 1
    }, card)
    makeDivider(header, theme, 2)
    bindHover(header, theme.SectionHeader, theme.Hover, theme.Press)

    local arrow = create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 6, 0.5, 0),
        Size = UDim2.fromOffset(11, 11),
        BackgroundTransparency = 1,
        Image = defaultExpanded and Icon.Collapse or Icon.Expand,
        ImageColor3 = theme.PrimaryText
    }, header)

    local titleLabel = makeLabel(header, title, theme, {
        Position = UDim2.fromOffset(21, 0),
        Size = UDim2.new(1, -27, 1, 0),
        Font = Enum.Font.BuilderSansMedium,
        TextColor3 = theme.Active,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    local clipFrame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = defaultExpanded and true or false,
        LayoutOrder = 2
    }, card)

    local inner = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, clipFrame)
    listLayout(inner, 0)

    local cardObj = {
        Card = card,
        Header = header,
        TitleLabel = titleLabel,
        Container = inner,
        Expanded = defaultExpanded and true or false,
        UserExpanded = defaultExpanded and true or false
    }
    local animToken = 0

    local function applyState(animate)
        animToken = animToken + 1
        local currentToken = animToken
        arrow.Image = cardObj.Expanded and Icon.Collapse or Icon.Expand

        if cardObj.Expanded then
            clipFrame.Visible = true
            if animate then
                local targetH = inner.AbsoluteSize.Y
                if targetH <= 0 then
                    clipFrame.AutomaticSize = Enum.AutomaticSize.Y
                    clipFrame.Size = UDim2.new(1, 0, 0, 0)
                    return
                end
                clipFrame.AutomaticSize = Enum.AutomaticSize.None
                local t = tween(clipFrame, 0.16, {Size = UDim2.new(1, 0, 0, targetH)})
                t.Completed:Connect(function(playbackState)
                    if playbackState == Enum.PlaybackState.Completed and currentToken == animToken and cardObj.Expanded and clipFrame.Parent then
                        clipFrame.AutomaticSize = Enum.AutomaticSize.Y
                        clipFrame.Size = UDim2.new(1, 0, 0, 0)
                    end
                end)
            else
                cancelTween(clipFrame)
                clipFrame.AutomaticSize = Enum.AutomaticSize.Y
                clipFrame.Size = UDim2.new(1, 0, 0, 0)
            end
        else
            if animate then
                local currentH = clipFrame.AbsoluteSize.Y
                clipFrame.AutomaticSize = Enum.AutomaticSize.None
                clipFrame.Size = UDim2.new(1, 0, 0, currentH)
                local t = tween(clipFrame, 0.16, {Size = UDim2.new(1, 0, 0, 0)})
                t.Completed:Connect(function(playbackState)
                    if playbackState == Enum.PlaybackState.Completed and currentToken == animToken and not cardObj.Expanded and clipFrame.Parent then
                        clipFrame.Visible = false
                    end
                end)
            else
                cancelTween(clipFrame)
                clipFrame.AutomaticSize = Enum.AutomaticSize.None
                clipFrame.Size = UDim2.new(1, 0, 0, 0)
                clipFrame.Visible = false
            end
        end
    end

    function cardObj:SetExpanded(value, animate, fromUser)
        self.Expanded = value and true or false
        if fromUser then
            self.UserExpanded = self.Expanded
        end
        applyState(animate ~= false)
    end

    header.MouseButton1Click:Connect(function()
        local searchActive = window.SearchBox and window.SearchBox.Text ~= ""
        cardObj:SetExpanded(not cardObj.Expanded, true, not searchActive)
    end)

    applyState(false)
    return cardObj
end

function Window:Tab(cfg)
    if type(cfg) == "string" then
        cfg = {Title = cfg}
    end
    cfg = cfg or {}

    local expanded = cfg.Expanded
    if expanded == nil then
        expanded = true
    end

    self._tabCount = self._tabCount + 1
    local accordion = createAccordion(self, tostring(cfg.Title or ("Tab " .. self._tabCount)), self._tabCount, expanded)

    local tab = setmetatable({
        Window = self,
        Theme = self.Theme,
        Config = cfg,
        Accordion = accordion,
        Card = accordion.Card,
        Container = accordion.Container,
        _order = 0,
        _subCount = 0,
        _currentSub = nil
    }, Tab)

    table.insert(self.Tabs, tab)
    return tab
end

Window.CreateTab = Window.Tab

function Tab:SetTitle(text)
    self.Config.Title = text
    self.Accordion.TitleLabel.Text = tostring(text)
end

function Tab:SetExpanded(value)
    self.Accordion:SetExpanded(value, true, true)
end

function Tab:SetVisible(value)
    self.Hidden = not value
    self.Card.Visible = value and true or false
end

function Tab:Destroy()
    local window = self.Window
    local entries = window.SearchEntries
    for i = #entries, 1, -1 do
        if entries[i].Tab == self then
            table.remove(entries, i)
        end
    end
    for key, sub in pairs(window.Subsections) do
        if sub.Tab == self then
            window.Subsections[key] = nil
        end
    end
    for i, tab in ipairs(window.Tabs) do
        if tab == self then
            table.remove(window.Tabs, i)
            break
        end
    end
    window:_closePopup()
    self.Card:Destroy()
end

----------------------------------------------------------------------
-- Section (subtítulo)
----------------------------------------------------------------------

function Tab:Section(cfg)
    if type(cfg) == "string" then
        cfg = {Title = cfg}
    end
    cfg = cfg or {}
    local theme = self.Theme

    self._subCount = self._subCount + 1
    local key = tostring(self._order) .. ":" .. tostring(self._subCount)

    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundColor3 = theme.Subsection,
        BorderSizePixel = 0,
        LayoutOrder = self:_nextOrder()
    }, self.Container)
    makeDivider(row, theme, 2)

    local label = makeLabel(row, tostring(cfg.Title or ""), theme, {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -16, 1, 0),
        TextColor3 = theme.MutedText,
        Font = Enum.Font.BuilderSansMedium,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    local sub = {Frame = row, Tab = self, Key = key}
    self.Window.Subsections[key] = sub
    self._currentSub = key

    local section = {Frame = row, Label = label}
    function section:SetTitle(text)
        label.Text = tostring(text)
    end
    function section:Destroy()
        self.Frame:Destroy()
    end
    return section
end

----------------------------------------------------------------------
-- Button
----------------------------------------------------------------------

function Tab:Button(cfg)
    cfg = cfg or {}
    local theme = self.Theme

    local el, row, top = newElement(self, cfg, {Class = "TextButton", Hover = true})

    local actionLbl = makeLabel(top, tostring(cfg.ButtonText or "Execute"), theme, {
        Position = UDim2.new(LABEL_RATIO, 8, 0, 0),
        Size = UDim2.new(1 - LABEL_RATIO, -14, 1, 0),
        Font = Enum.Font.BuilderSansMedium,
        TextColor3 = theme.MutedText,
        TextTruncate = Enum.TextTruncate.AtEnd
    })
    table.insert(el._dim, actionLbl)

    function el:SetButtonText(text)
        actionLbl.Text = tostring(text)
    end

    function el:Click()
        if self.Locked then
            return
        end
        fire(self.Callback)
    end

    row.MouseButton1Click:Connect(function()
        el:Click()
    end)

    finishElement(self, el, cfg.ButtonText)
    return el
end

----------------------------------------------------------------------
-- Toggle  (Type = "Toggle" | "Checkbox")
----------------------------------------------------------------------

function Tab:Toggle(cfg)
    cfg = cfg or {}
    local theme = self.Theme

    local el, row, top = newElement(self, cfg, {Class = "TextButton", Hover = true})

    local kind = string.lower(tostring(cfg.Type or "Toggle"))
    local indicator
    if kind == "checkbox" then
        indicator = makeCheckbox(top, theme)
    else
        indicator = makeSwitch(top, theme)
    end

    el.Value = false

    function el:Set(value, silent)
        self.Value = value and true or false
        indicator.Apply(self.Value, silent)
        if not silent then
            fire(self.Callback, self.Value)
        end
    end

    function el:Get()
        return self.Value
    end

    function el:Toggle()
        self:Set(not self.Value)
    end

    row.MouseButton1Click:Connect(function()
        if el.Locked then
            return
        end
        el:Set(not el.Value)
    end)

    indicator.Apply(false, true)
    if cfg.Value == true or cfg.Default == true then
        el.Value = true
        indicator.Apply(true, true)
    end

    finishElement(self, el)
    return el
end

----------------------------------------------------------------------
-- Dropdown  (Values, Value, Multi)
----------------------------------------------------------------------

function Window:_closePopup()
    local active = self._activePopup
    if active then
        self._activePopup = nil
        if active.Close then
            active.Close()
        end
    end
end

function Window:_hideDropdownLayer()
    if self.DropdownBackdrop and self.DropdownBackdrop.Parent then
        self.DropdownBackdrop.Visible = false
    end
    if self.DropdownLayer and self.DropdownLayer.Parent then
        self.DropdownLayer.Visible = false
    end
end

function Tab:Dropdown(cfg)
    cfg = cfg or {}
    local window = self.Window
    local theme = self.Theme
    local multi = cfg.Multi == true

    local values = {}
    for _, v in ipairs(cfg.Values or {}) do
        values[#values + 1] = v
    end

    local el, row, top = newElement(self, cfg, {Class = "Frame", TopHeight = 24})

    local btn = create("TextButton", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(LABEL_RATIO, 6, 0.5, 0),
        Size = UDim2.new(1 - LABEL_RATIO, -12, 0, 19),
        BackgroundColor3 = theme.DropdownBtn,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ClipsDescendants = true,
        ZIndex = 3
    }, top)
    corner(btn, 3)
    local btnStroke = stroke(btn, theme.Border)
    bindHover(btn, theme.DropdownBtn, theme.DropdownBtnHover, theme.DropdownBtnPress, function()
        return el.Locked
    end)

    local valueLbl = makeLabel(btn, "", theme, {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -22, 1, 0),
        TextSize = 10,
        Font = Enum.Font.BuilderSansMedium,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 4
    })
    table.insert(el._dim, valueLbl)

    local arrow = create("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        Image = Icon.ArrowDown,
        ImageColor3 = theme.MutedText,
        ZIndex = 4
    }, btn)

    -- estado
    local selected = {}      -- usado no modo Multi
    local single = nil       -- usado no modo simples
    el.Expanded = false
    el.Values = values

    local function selectedList()
        local list = {}
        for _, v in ipairs(values) do
            if selected[v] then
                list[#list + 1] = v
            end
        end
        return list
    end

    local function refreshValue()
        if multi then
            el.Value = selectedList()
        else
            el.Value = single
        end
    end

    local function displayText()
        if multi then
            local list = selectedList()
            if #list == 0 then
                return "None"
            end
            local parts = {}
            for i, v in ipairs(list) do
                parts[i] = tostring(v)
            end
            return table.concat(parts, ", ")
        end
        if single == nil then
            return "None"
        end
        return tostring(single)
    end

    local optionButtons = {}
    local popup = nil

    local function isOptionActive(opt)
        if multi then
            return selected[opt] == true
        end
        return opt == single
    end

    local function syncVisual()
        valueLbl.Text = displayText()
        for opt, optBtn in pairs(optionButtons) do
            if optBtn and optBtn.Parent then
                local active = isOptionActive(opt)
                optBtn.BackgroundColor3 = active and theme.DropdownOptionActive or theme.DropdownCard
                optBtn.TextColor3 = active and theme.Active or theme.PrimaryText
            end
        end
    end

    local function closeSelf()
        el.Expanded = false
        optionButtons = {}
        arrow.Image = Icon.ArrowDown
        btnStroke.Color = theme.Border
        if popup and popup.Parent then
            cancelTween(popup)
            popup:Destroy()
        end
        popup = nil
        window:_hideDropdownLayer()
    end

    local function applySelection(val)
        if multi then
            selected = {}
            if type(val) == "table" then
                for _, v in ipairs(val) do
                    selected[v] = true
                end
            elseif val ~= nil then
                selected[val] = true
            end
        else
            if type(val) == "table" then
                val = val[1]
            end
            single = val
        end
        refreshValue()
    end

    function el:Set(val, silent)
        applySelection(val)
        syncVisual()
        if not silent then
            fire(self.Callback, self.Value)
        end
    end

    function el:Get()
        return self.Value
    end

    function el:SetExpanded(open)
        if not open then
            if window._activePopup and window._activePopup.Owner == el then
                window:_closePopup()
            else
                closeSelf()
            end
            return
        end

        window:_closePopup()

        local layer = window.DropdownLayer
        if not layer or not layer.Parent or not btn.Parent then
            return
        end

        el.Expanded = true
        arrow.Image = Icon.ArrowUp
        btnStroke.Color = theme.SearchFocusBorder

        layer.Visible = true
        window.DropdownBackdrop.Visible = true

        local layerPos = layer.AbsolutePosition
        local layerSize = layer.AbsoluteSize
        local btnPos = btn.AbsolutePosition
        local btnSize = btn.AbsoluteSize

        local cardWidth = math.max(48, math.floor(btnSize.X + 0.5))
        local optionHeight = 20
        local verticalPad = 6
        local targetHeight = math.min(#values * optionHeight + verticalPad, 146)

        local relX = math.clamp(math.floor(btnPos.X - layerPos.X + 0.5), 2, math.max(2, layerSize.X - cardWidth - 2))
        local belowY = math.floor((btnPos.Y - layerPos.Y) + btnSize.Y + 3 + 0.5)
        local relY = belowY
        if belowY + targetHeight > layerSize.Y - 4 then
            local aboveY = math.floor((btnPos.Y - layerPos.Y) - targetHeight - 3 + 0.5)
            if aboveY >= 4 then
                relY = aboveY
            else
                relY = math.max(4, layerSize.Y - targetHeight - 4)
            end
        end

        popup = create("Frame", {
            Position = UDim2.fromOffset(relX, relY),
            Size = UDim2.fromOffset(cardWidth, 0),
            BackgroundColor3 = theme.DropdownCard,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 42
        }, layer)
        corner(popup, 3)
        stroke(popup, theme.Border)

        local list = create("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = theme.ScrollHandle,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ElasticBehavior = Enum.ElasticBehavior.Never,
            ZIndex = 42
        }, popup)
        ensurePadding(list, 0, 3, 0, 3)
        listLayout(list, 0)

        optionButtons = {}
        for idx, opt in ipairs(values) do
            local active = isOptionActive(opt)
            local optBtn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, optionHeight),
                BackgroundColor3 = active and theme.DropdownOptionActive or theme.DropdownCard,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.BuilderSansMedium,
                Text = tostring(opt),
                TextColor3 = active and theme.Active or theme.PrimaryText,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                LayoutOrder = idx,
                ZIndex = 43
            }, list)
            ensurePadding(optBtn, 8, 0, 6, 0)

            optBtn.MouseEnter:Connect(function()
                if not isTouchOnlyInput(nil) and not isOptionActive(opt) then
                    tween(optBtn, 0.08, {BackgroundColor3 = theme.DropdownOptionHover})
                end
            end)
            optBtn.MouseLeave:Connect(function()
                if not isOptionActive(opt) then
                    tween(optBtn, 0.08, {BackgroundColor3 = theme.DropdownCard})
                end
            end)
            optBtn.MouseButton1Click:Connect(function()
                if multi then
                    selected[opt] = not selected[opt] or nil
                    refreshValue()
                    syncVisual()
                    fire(el.Callback, el.Value)
                else
                    el:Set(opt)
                    window:_closePopup()
                end
            end)

            optionButtons[opt] = optBtn
        end

        window._activePopup = {Owner = el, Close = closeSelf}
        tween(popup, 0.12, {Size = UDim2.fromOffset(cardWidth, targetHeight)})
    end

    -- Troca a lista de opções. keepValue = true mantém a seleção atual (se ainda existir).
    function el:Refresh(newValues, keepValue)
        if window._activePopup and window._activePopup.Owner == el then
            window:_closePopup()
        end
        values = {}
        for _, v in ipairs(newValues or {}) do
            values[#values + 1] = v
        end
        el.Values = values

        local function exists(v)
            for _, x in ipairs(values) do
                if x == v then
                    return true
                end
            end
            return false
        end

        if multi then
            local kept = {}
            if keepValue then
                for v in pairs(selected) do
                    if exists(v) then
                        kept[v] = true
                    end
                end
            end
            selected = kept
        else
            if not (keepValue and single ~= nil and exists(single)) then
                single = nil
            end
        end
        refreshValue()
        syncVisual()
        local texts = {}
        for i, v in ipairs(values) do
            texts[i] = tostring(v)
        end
        self._searchExtra = table.concat(texts, " ")
        self:_syncSearch()
    end

    btn.MouseButton1Click:Connect(function()
        if el.Locked then
            return
        end
        el:SetExpanded(not el.Expanded)
    end)

    el._onDestroy = function()
        if window._activePopup and window._activePopup.Owner == el then
            window:_closePopup()
        end
    end

    -- valor inicial
    local initial = cfg.Value
    if initial == nil and cfg.Default ~= nil then
        initial = cfg.Default
    end
    applySelection(initial)
    syncVisual()

    local valuesText = {}
    for i, v in ipairs(values) do
        valuesText[i] = tostring(v)
    end
    finishElement(self, el, table.concat(valuesText, " "))
    return el
end

----------------------------------------------------------------------
-- Slider
----------------------------------------------------------------------

function Tab:Slider(cfg)
    cfg = cfg or {}
    local window = self.Window
    local theme = self.Theme

    local minV = tonumber(cfg.Min) or 0
    local maxV = tonumber(cfg.Max) or 100
    if maxV <= minV then
        maxV = minV + 1
    end
    local step = tonumber(cfg.Step or cfg.Increment) or 1
    if step <= 0 then
        step = 1
    end
    local suffix = cfg.Suffix and tostring(cfg.Suffix) or ""

    local el, row, top = newElement(self, cfg, {Class = "Frame"})

    local area = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(LABEL_RATIO, 8, 0.5, 0),
        Size = UDim2.new(1 - LABEL_RATIO, -14, 0, 16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, top)

    local valueLbl = makeLabel(area, "", theme, {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 38, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 10,
        Font = Enum.Font.BuilderSansMedium,
        TextColor3 = theme.MutedText
    })
    table.insert(el._dim, valueLbl)

    local hit = create("TextButton", {
        Size = UDim2.new(1, -44, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = ""
    }, area)

    local bar = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = theme.ToggleOff,
        BorderSizePixel = 0
    }, hit)
    corner(bar, 2)

    local fill = create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme.ToggleOn,
        BorderSizePixel = 0
    }, bar)
    corner(fill, 2)

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = theme.Active,
        BorderSizePixel = 0,
        ZIndex = 2
    }, bar)
    corner(knob, 5)

    local function snap(v)
        v = math.clamp(v, minV, maxV)
        v = minV + math.floor((v - minV) / step + 0.5) * step
        v = math.clamp(v, minV, maxV)
        return tonumber(string.format("%.6f", v))
    end

    local function visual(v)
        local ratio = (v - minV) / (maxV - minV)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
        valueLbl.Text = tostring(v) .. suffix
    end

    el.Value = snap(tonumber(cfg.Value or cfg.Default) or minV)
    visual(el.Value)

    function el:Set(value, silent)
        value = tonumber(value)
        if value == nil then
            return
        end
        value = snap(value)
        local changed = value ~= self.Value
        self.Value = value
        visual(value)
        if changed and not silent then
            fire(self.Callback, value)
        end
    end

    function el:Get()
        return self.Value
    end

    local dragging = false

    local function setFromX(x)
        local width = hit.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local ratio = math.clamp((x - hit.AbsolutePosition.X) / width, 0, 1)
        el:Set(minV + ratio * (maxV - minV))
    end

    hit.InputBegan:Connect(function(input)
        if el.Locked then
            return
        end
        if isPointerPress(input) then
            dragging = true
            window:_closePopup()
            setFromX(input.Position.X)
        end
    end)

    window:_connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)

    window:_connect(UserInputService.InputEnded, function(input)
        if isPointerPress(input) then
            dragging = false
        end
    end)

    finishElement(self, el)
    return el
end

----------------------------------------------------------------------
-- Input (TextBox)
----------------------------------------------------------------------

function Tab:Input(cfg)
    cfg = cfg or {}
    local theme = self.Theme

    local el, row, top = newElement(self, cfg, {Class = "Frame", TopHeight = 24})

    local holder = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(LABEL_RATIO, 6, 0.5, 0),
        Size = UDim2.new(1 - LABEL_RATIO, -12, 0, 19),
        BackgroundColor3 = theme.SecondarySurface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 3
    }, top)
    corner(holder, 3)
    local holderStroke = stroke(holder, theme.Border)

    local numeric = cfg.Numeric == true
    local box = create("TextBox", {
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 1, 0),
        BackgroundTransparency = 1,
        ClearTextOnFocus = cfg.ClearTextOnFocus == true,
        Font = Enum.Font.BuilderSansMedium,
        PlaceholderText = tostring(cfg.Placeholder or ""),
        PlaceholderColor3 = theme.MutedText,
        Text = "",
        TextColor3 = theme.PrimaryText,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
        ZIndex = 4
    }, holder)

    el.Value = cfg.Value ~= nil and cfg.Value or (numeric and 0 or "")
    box.Text = tostring(el.Value)

    box.Focused:Connect(function()
        holderStroke.Color = theme.SearchFocusBorder
    end)

    local function normalize(text)
        if numeric then
            local n = tonumber(text)
            if n == nil then
                return nil
            end
            if cfg.Min then
                n = math.max(n, cfg.Min)
            end
            if cfg.Max then
                n = math.min(n, cfg.Max)
            end
            return n
        end
        return text
    end

    box.FocusLost:Connect(function()
        holderStroke.Color = theme.Border
        if el.Locked then
            box.Text = tostring(el.Value)
            return
        end
        local value = normalize(box.Text)
        if value == nil then
            box.Text = tostring(el.Value)
            return
        end
        el.Value = value
        box.Text = tostring(value)
        fire(el.Callback, value)
    end)

    function el:Set(value, silent)
        local normalized = normalize(tostring(value))
        if normalized == nil then
            return
        end
        self.Value = normalized
        box.Text = tostring(normalized)
        if not silent then
            fire(self.Callback, normalized)
        end
    end

    function el:Get()
        return self.Value
    end

    finishElement(self, el)
    return el
end

----------------------------------------------------------------------
-- Keybind
----------------------------------------------------------------------

function Tab:Keybind(cfg)
    cfg = cfg or {}
    local window = self.Window
    local theme = self.Theme

    local el, row, top = newElement(self, cfg, {Class = "TextButton", Hover = true})

    local chip = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(LABEL_RATIO, 6, 0.5, 0),
        Size = UDim2.new(1 - LABEL_RATIO, -12, 0, 17),
        BackgroundColor3 = theme.DropdownBtn,
        BorderSizePixel = 0
    }, top)
    corner(chip, 3)
    local chipStroke = stroke(chip, theme.Border)

    local keyLbl = makeLabel(chip, "", theme, {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextSize = 10,
        Font = Enum.Font.BuilderSansMedium
    })
    table.insert(el._dim, keyLbl)

    el.ChangedCallback = cfg.ChangedCallback or cfg.OnChanged
    local listening = false

    local function toKeyCode(value)
        if typeof(value) == "EnumItem" then
            return value
        end
        if type(value) == "string" then
            local ok, key = pcall(function()
                return Enum.KeyCode[value]
            end)
            if ok then
                return key
            end
        end
        return nil
    end

    local function refreshLabel()
        if listening then
            keyLbl.Text = "..."
            chipStroke.Color = theme.SearchFocusBorder
        else
            keyLbl.Text = el.Value and el.Value.Name or "None"
            chipStroke.Color = theme.Border
        end
    end

    el.Value = toKeyCode(cfg.Value or cfg.Default)
    refreshLabel()

    function el:Set(key, silent)
        self.Value = toKeyCode(key)
        listening = false
        refreshLabel()
        if not silent then
            fire(self.ChangedCallback, self.Value)
        end
    end

    function el:Get()
        return self.Value
    end

    row.MouseButton1Click:Connect(function()
        if el.Locked then
            return
        end
        listening = not listening
        refreshLabel()
    end)

    window:_connect(UserInputService.InputBegan, function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if listening then
            if input.KeyCode == Enum.KeyCode.Escape then
                el:Set(nil)
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                el:Set(input.KeyCode)
            end
            return
        end
        if gameProcessed or el.Locked then
            return
        end
        if el.Value and input.KeyCode == el.Value then
            fire(el.Callback, el.Value)
        end
    end)

    finishElement(self, el)
    return el
end

----------------------------------------------------------------------
-- Label (linha de informação) e Paragraph (texto longo)
----------------------------------------------------------------------

function Tab:Label(cfg)
    if type(cfg) == "string" then
        cfg = {Title = cfg}
    end
    cfg = cfg or {}
    local theme = self.Theme

    local el, row, top = newElement(self, cfg, {Class = "Frame", TopHeight = 21})

    local valueLbl = makeLabel(top, tostring(cfg.Value or ""), theme, {
        Position = UDim2.new(LABEL_RATIO, 8, 0, 0),
        Size = UDim2.new(1 - LABEL_RATIO, -12, 1, 0),
        Font = Enum.Font.BuilderSansMedium,
        TextColor3 = theme.MutedText,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    el.Value = cfg.Value

    function el:SetValue(text)
        self.Value = text
        valueLbl.Text = tostring(text)
        self._searchExtra = tostring(text)
        self:_syncSearch()
    end

    finishElement(self, el, cfg.Value)
    return el
end

function Tab:Paragraph(cfg)
    if type(cfg) == "string" then
        cfg = {Desc = cfg}
    end
    cfg = cfg or {}

    local el = newElement(self, cfg, {
        Class = "Frame",
        TopHeight = (cfg.Title ~= nil and cfg.Title ~= "") and 20 or 6,
        NoColumn = true,
        TitleFont = Enum.Font.BuilderSansMedium
    })

    finishElement(self, el)
    return el
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------

function Window:_connect(signal, callback)
    local connection = signal:Connect(callback)
    self._connections[#self._connections + 1] = connection
    return connection
end

function Window:_disconnectAll()
    for i = #self._connections, 1, -1 do
        local conn = self._connections[i]
        self._connections[i] = nil
        if conn then
            pcall(function()
                conn:Disconnect()
            end)
        end
    end
end

function Window:_applySearch()
    self:_closePopup()
    local raw = self.SearchBox and self.SearchBox.Text or ""
    local query = string.lower(trim(raw))

    if self.SearchClearBtn then
        self.SearchClearBtn.Visible = raw ~= ""
    end

    if query == "" then
        for _, entry in ipairs(self.SearchEntries) do
            local frame = entry.Element.Frame
            if frame and frame.Parent then
                frame.Visible = not entry.Element.Hidden
            end
        end
        for _, sub in pairs(self.Subsections) do
            if sub.Frame and sub.Frame.Parent then
                sub.Frame.Visible = true
            end
        end
        for _, tab in ipairs(self.Tabs) do
            if tab.Card and tab.Card.Parent then
                tab.Card.Visible = not tab.Hidden
                tab.Accordion:SetExpanded(tab.Accordion.UserExpanded, false, false)
            end
        end
        if self.EmptySearchLabel then
            self.EmptySearchLabel.Visible = false
        end
        if self._updateScroll then
            self._updateScroll()
        end
        return
    end

    local tabHasMatch = {}
    local subHasMatch = {}

    for _, entry in ipairs(self.SearchEntries) do
        local matched = string.find(entry.SearchText, query, 1, true) ~= nil
        local frame = entry.Element.Frame
        if frame and frame.Parent then
            frame.Visible = matched and not entry.Element.Hidden
        end
        if matched then
            tabHasMatch[entry.Tab] = true
            if entry.Sub then
                subHasMatch[entry.Sub] = true
            end
        end
    end

    for key, sub in pairs(self.Subsections) do
        if sub.Frame and sub.Frame.Parent then
            sub.Frame.Visible = subHasMatch[key] == true
        end
    end

    local anyVisible = false
    for _, tab in ipairs(self.Tabs) do
        if tab.Card and tab.Card.Parent then
            local has = tabHasMatch[tab] == true
            tab.Card.Visible = has and not tab.Hidden
            if has then
                anyVisible = true
                tab.Accordion:SetExpanded(true, false, false)
            end
        end
    end

    if self.EmptySearchLabel then
        self.EmptySearchLabel.Visible = not anyVisible
    end
    if self._updateScroll then
        self._updateScroll()
    end
end

function Window:SetTitle(text)
    self.Config.Title = text
    if self.TitleLabel then
        self.TitleLabel.Text = tostring(text)
    end
end

function Window:SetVisible(value)
    self.Visible = value and true or false
    if not self.Visible then
        self:_closePopup()
    end
    if self.Screen and self.Screen.Parent then
        self.Screen.Enabled = self.Visible
    end
end

function Window:Toggle()
    self:SetVisible(not self.Visible)
end

function Window:Minimize(value)
    if self._setMinimized then
        self._setMinimized(value and true or false)
    end
end

function Window:IsMinimized()
    return self.Minimized
end

function Window:Destroy(animate)
    if not self.Running then
        return
    end
    if animate and self._closing then
        return
    end
    self.Running = false

    self:_closePopup()
    if self._endPointer then
        self._endPointer()
    end
    cancelTweensUnder(self.Screen)
    self:_disconnectAll()

    for i, w in ipairs(Library.Windows) do
        if w == self then
            table.remove(Library.Windows, i)
            break
        end
    end
    local id = self.Config.Id
    if genv and id and genv.__PMLibWindows and genv.__PMLibWindows[id] == self then
        genv.__PMLibWindows[id] = nil
    end

    if self.Config.OnClose then
        fire(self.Config.OnClose)
    end

    local function cleanup()
        pcall(function()
            if self.Screen then
                self.Screen:Destroy()
            end
        end)
    end

    local main = self.Main
    if animate and main and main.Parent then
        self._closing = true
        if self.ResizeOverlay and self.ResizeOverlay.Parent then
            self.ResizeOverlay.Visible = false
        end
        for _, handle in pairs(self.Resize) do
            if handle and handle.Parent then
                handle.Active = false
                handle.Visible = false
            end
        end

        local currentWidth = main.AbsoluteSize.X
        if currentWidth <= 0 then
            currentWidth = main.Size.X.Offset
        end
        local currentHeight = main.AbsoluteSize.Y
        if currentHeight <= 0 then
            currentHeight = main.Size.Y.Offset
        end

        main.ClipsDescendants = true
        main.Size = UDim2.fromOffset(currentWidth, currentHeight)

        if self.Shadow and self.Shadow.Parent then
            pcall(function()
                tween(self.Shadow, 0.14, {Transparency = 1})
            end)
        end

        local finished = false
        local function finish()
            if finished then
                return
            end
            finished = true
            cancelTweensUnder(self.Screen)
            cleanup()
        end

        local wipe = tween(main, 0.18, {Size = UDim2.fromOffset(currentWidth, 0)}, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        wipe.Completed:Connect(finish)
        task.delay(0.24, finish)
    else
        cleanup()
    end
end

Window.Close = Window.Destroy

----------------------------------------------------------------------
-- Scroller (barra de rolagem customizada)
----------------------------------------------------------------------

local function createScroller(window, parent)
    local theme = window.Theme

    local holder = create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1)
    }, parent)

    local scroll = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -15, 1, 0),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Never,
        ClipsDescendants = true
    }, holder)

    local bar = create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromScale(1, 0),
        Size = UDim2.new(0, 15, 1, 0),
        BackgroundColor3 = theme.ScrollTrack,
        BorderSizePixel = 0
    }, holder)

    local up = create("ImageButton", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(15, 15),
        BackgroundTransparency = 1,
        Image = Icon.ArrowUp,
        ImageColor3 = theme.MutedText,
        AutoButtonColor = false
    }, bar)

    local down = create("ImageButton", {
        Position = UDim2.new(0, 0, 1, -15),
        Size = UDim2.fromOffset(15, 15),
        BackgroundTransparency = 1,
        Image = Icon.ArrowDown,
        ImageColor3 = theme.MutedText,
        AutoButtonColor = false
    }, bar)

    local track = create("Frame", {
        Position = UDim2.fromOffset(0, 15),
        Size = UDim2.new(1, 0, 1, -30),
        BackgroundColor3 = theme.ScrollTrack,
        BorderSizePixel = 0
    }, bar)

    local handle = create("Frame", {
        Size = UDim2.new(0, 15, 0, 55),
        BackgroundColor3 = theme.ScrollHandle,
        BorderSizePixel = 0
    }, track)

    local function maxScroll()
        return math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y)
    end

    local function getHandleHeight(trackHeight)
        if trackHeight <= 0 then
            return 0
        end
        return math.min(55, trackHeight)
    end

    local function update()
        local trackHeight = track.AbsoluteSize.Y
        local limit = maxScroll()
        if scroll.CanvasPosition.Y > limit then
            scroll.CanvasPosition = Vector2.new(0, limit)
        end
        local handleHeight = getHandleHeight(trackHeight)
        handle.Size = UDim2.new(0, 15, 0, handleHeight)
        handle.Visible = limit > 0 and trackHeight > 0
        local ratio = 0
        if limit > 0 then
            ratio = math.clamp(scroll.CanvasPosition.Y / limit, 0, 1)
        end
        handle.Position = UDim2.fromOffset(0, math.floor((trackHeight - handleHeight) * ratio))
    end

    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(update)
    scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(update)
    scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(update)
    track:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)

    local holdDirection = 0
    local holdConnection = nil
    local dragging = false
    local dragStartY = 0
    local dragStartHandle = 0

    local function scrollBy(amount)
        scroll.CanvasPosition = Vector2.new(0, math.clamp(scroll.CanvasPosition.Y + amount, 0, maxScroll()))
    end

    local function stopHold()
        holdDirection = 0
        if holdConnection then
            holdConnection:Disconnect()
            holdConnection = nil
        end
    end

    local function startHold(direction)
        stopHold()
        holdDirection = direction
        scrollBy(direction * 24)
        holdConnection = RunService.Heartbeat:Connect(function(dt)
            if not window.Running then
                stopHold()
                return
            end
            if holdDirection ~= 0 then
                scrollBy(holdDirection * 520 * dt)
            end
        end)
    end

    up.InputBegan:Connect(function(input)
        if isPointerPress(input) then
            startHold(-1)
        end
    end)

    down.InputBegan:Connect(function(input)
        if isPointerPress(input) then
            startHold(1)
        end
    end)

    handle.InputBegan:Connect(function(input)
        if isPointerPress(input) then
            dragging = true
            dragStartY = input.Position.Y
            dragStartHandle = handle.Position.Y.Offset
        end
    end)

    track.InputBegan:Connect(function(input)
        if not isPointerPress(input) then
            return
        end
        local y = input.Position.Y
        local top = handle.AbsolutePosition.Y
        local handleHeight = getHandleHeight(track.AbsoluteSize.Y)
        if y >= top and y <= top + handleHeight then
            return
        end
        local span = track.AbsoluteSize.Y - handleHeight
        if span > 0 then
            local target = math.clamp(y - track.AbsolutePosition.Y - handleHeight / 2, 0, span)
            scroll.CanvasPosition = Vector2.new(0, target / span * maxScroll())
            dragging = true
            dragStartY = y
            dragStartHandle = target
        end
    end)

    window:_connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local handleHeight = getHandleHeight(track.AbsoluteSize.Y)
            local span = track.AbsoluteSize.Y - handleHeight
            if span > 0 then
                local target = math.clamp(dragStartHandle + (input.Position.Y - dragStartY), 0, span)
                scroll.CanvasPosition = Vector2.new(0, target / span * maxScroll())
            end
        end
    end)

    window:_connect(UserInputService.InputEnded, function(input)
        if isPointerPress(input) then
            dragging = false
            stopHold()
        end
    end)

    holder.Destroying:Connect(stopHold)
    update()
    return holder, scroll, update
end

----------------------------------------------------------------------
-- Library:CreateWindow
----------------------------------------------------------------------

function Library:CreateWindow(config)
    if type(config) == "string" then
        config = {Title = config}
    end
    config = config or {}

    -- destrói instância anterior com o mesmo Id (reexecução do script)
    local id = config.Id
    if genv and id then
        genv.__PMLibWindows = genv.__PMLibWindows or {}
        local previous = genv.__PMLibWindows[id]
        if previous and type(previous.Destroy) == "function" then
            pcall(previous.Destroy, previous)
        end
    end

    -- tema (cópia + overrides)
    local theme = {}
    for key, value in pairs(Library.Theme) do
        theme[key] = value
    end
    for key, value in pairs(config.Theme or {}) do
        local color = toColor3(value)
        if color then
            theme[key] = color
        end
    end

    local window = setmetatable({
        Config = config,
        Theme = theme,
        Tabs = {},
        SearchEntries = {},
        Subsections = {},
        Resize = {},
        Running = true,
        Visible = true,
        Minimized = false,
        _connections = {},
        _activePopup = nil,
        _tabCount = 0
    }, Window)

    -- dimensões
    local initialWidth, initialHeight = 270, 320
    if typeof(config.Size) == "Vector2" then
        initialWidth, initialHeight = config.Size.X, config.Size.Y
    elseif typeof(config.Size) == "UDim2" then
        initialWidth, initialHeight = config.Size.X.Offset, config.Size.Y.Offset
    end
    local MinSize = typeof(config.MinSize) == "Vector2" and config.MinSize or Vector2.new(240, 140)
    initialWidth = math.max(initialWidth, MinSize.X)
    initialHeight = math.max(initialHeight, MinSize.Y)

    local headerHeight = 22
    local showSearch = config.Search ~= false
    local resetCfg = type(config.ResetButton) == "table" and config.ResetButton or nil
    local toolbarHeight = (showSearch or resetCfg) and 26 or 0

    local viewport = Vector2.new(800, 600)
    pcall(function()
        local camera = Workspace.CurrentCamera
        if camera then
            viewport = camera.ViewportSize
        end
    end)

    -- ScreenGui
    local screen = create("ScreenGui", {
        Name = randomName(),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = config.DisplayOrder or 50,
        IgnoreGuiInset = true
    })
    window.Screen = screen

    pcall(function()
        local protect = executorEnv.protect_gui or (executorEnv.syn and executorEnv.syn.protect_gui)
        if type(protect) == "function" then
            protect(screen)
        end
    end)

    local parented = pcall(function()
        screen.Parent = resolveHost()
    end)
    if not parented then
        pcall(function()
            screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    local screenSize = screen.AbsoluteSize
    if screenSize.X < 100 or screenSize.Y < 100 then
        screenSize = viewport
    end

    local startPos = UDim2.fromOffset(
        math.max(0, math.floor(screenSize.X / 2 - initialWidth / 2)),
        math.max(0, math.floor(screenSize.Y / 2 - initialHeight / 2))
    )
    if typeof(config.Position) == "Vector2" then
        startPos = UDim2.fromOffset(config.Position.X, config.Position.Y)
    elseif typeof(config.Position) == "UDim2" then
        startPos = UDim2.fromOffset(config.Position.X.Offset, config.Position.Y.Offset)
    end

    local main = create("Frame", {
        Position = startPos,
        Size = UDim2.fromOffset(initialWidth, initialHeight),
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = false
    }, screen)
    window.Main = main

    -- sombra (UIShadow pode não existir em todos os clientes)
    do
        local okShadow, shadow = pcall(function()
            return Instance.new("UIShadow")
        end)
        if okShadow and shadow then
            local shadowProps = {
                ZIndex = -1,
                BlurRadius = UDim.new(0, 14),
                Color = Color3.fromRGB(0, 0, 0),
                Enabled = true,
                Offset = UDim2.fromOffset(0, 4),
                Spread = UDim2.fromScale(0, 0),
                Transparency = 0.45
            }
            for property, value in pairs(shadowProps) do
                pcall(function()
                    shadow[property] = value
                end)
            end
            pcall(function()
                shadow.Parent = main
            end)
            window.Shadow = shadow
        end
    end

    -- Header
    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, headerHeight),
        BackgroundColor3 = theme.Header,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 2
    }, main)
    window.Header = header

    create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.HeaderDivider,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 2
    }, header)

    window.TitleLabel = makeLabel(header, tostring(config.Title or "Window"), theme, {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -54, 1, 0),
        Font = Enum.Font.BuilderSansMedium,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3
    })

    local function headerButton(offsetX, image)
        local button = create("ImageButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, offsetX, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            BackgroundColor3 = theme.Header,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 3
        }, header)
        corner(button, 3)
        local icon = create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(10, 10),
            BackgroundTransparency = 1,
            Image = image,
            ImageColor3 = theme.PrimaryText,
            ZIndex = 4
        }, button)
        bindHover(button, theme.Header, theme.BtnRestoreHover, theme.BtnRestorePress)
        return button, icon
    end

    local closeButton = headerButton(-4, Icon.Close)
    local minimizeButton, minimizeIcon = headerButton(-22, Icon.Minimal)

    -- Toolbar (busca + botão opcional)
    if toolbarHeight > 0 then
        window.Toolbar = create("Frame", {
            Position = UDim2.fromOffset(0, headerHeight),
            Size = UDim2.new(1, 0, 0, toolbarHeight),
            BackgroundColor3 = theme.Surface,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 2
        }, main)
        makeDivider(window.Toolbar, theme, 3, 20)

        local resetWidth = resetCfg and (resetCfg.Width or 118) or 0

        if showSearch then
            local searchHolder = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 6, 0.5, 0),
                Size = resetCfg and UDim2.new(1, -(resetWidth + 16), 0, 19) or UDim2.new(1, -12, 0, 19),
                BackgroundColor3 = theme.SecondarySurface,
                BorderSizePixel = 0,
                ClipsDescendants = true
            }, window.Toolbar)
            corner(searchHolder, 3)
            local searchStroke = stroke(searchHolder, theme.Border)

            create("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 5, 0.5, 0),
                Size = UDim2.fromOffset(11, 11),
                BackgroundTransparency = 1,
                Image = Icon.Search,
                ImageColor3 = theme.MutedText
            }, searchHolder)

            window.SearchBox = create("TextBox", {
                Position = UDim2.fromOffset(20, 0),
                Size = UDim2.new(1, -36, 1, 0),
                BackgroundTransparency = 1,
                ClearTextOnFocus = false,
                Font = Enum.Font.BuilderSans,
                PlaceholderText = tostring(config.SearchPlaceholder or "Search settings"),
                PlaceholderColor3 = theme.MutedText,
                Text = "",
                TextColor3 = theme.PrimaryText,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClipsDescendants = true
            }, searchHolder)

            local clearBtn = create("ImageButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -4, 0.5, 0),
                Size = UDim2.fromOffset(11, 11),
                BackgroundTransparency = 1,
                Image = Icon.Close,
                ImageColor3 = theme.MutedText,
                Visible = false,
                AutoButtonColor = false
            }, searchHolder)

            window.SearchBox.Focused:Connect(function()
                searchStroke.Color = theme.SearchFocusBorder
            end)
            window.SearchBox.FocusLost:Connect(function()
                searchStroke.Color = theme.Border
            end)
            clearBtn.MouseButton1Click:Connect(function()
                window.SearchBox.Text = ""
            end)
            window.SearchClearBtn = clearBtn
        end

        if resetCfg then
            local resetBtn = create("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0),
                Size = UDim2.fromOffset(resetWidth, 19),
                BackgroundColor3 = theme.BtnRestore,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ClipsDescendants = true
            }, window.Toolbar)
            corner(resetBtn, 3)
            stroke(resetBtn, theme.Border)
            bindHover(resetBtn, theme.BtnRestore, theme.BtnRestoreHover, theme.BtnRestorePress)

            local resetIcon = resolveIcon(resetCfg.Icon) or Icon.Rotate
            create("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 6, 0.5, 0),
                Size = UDim2.fromOffset(11, 11),
                BackgroundTransparency = 1,
                Image = resetIcon,
                ImageColor3 = theme.BtnRestoreText
            }, resetBtn)

            window.ResetButton = resetBtn
            window.ResetButtonLabel = makeLabel(resetBtn, tostring(resetCfg.Title or "Reset"), theme, {
                Position = UDim2.fromOffset(20, 0),
                Size = UDim2.new(1, -24, 1, 0),
                Font = Enum.Font.BuilderSansMedium,
                TextColor3 = theme.BtnRestoreText,
                TextSize = 10,
                TextTruncate = Enum.TextTruncate.AtEnd
            })

            resetBtn.MouseButton1Click:Connect(function()
                fire(resetCfg.Callback)
            end)
        end
    end

    -- Conteúdo
    window.Content = create("Frame", {
        Position = UDim2.fromOffset(0, headerHeight + toolbarHeight),
        Size = UDim2.new(1, 0, 1, -(headerHeight + toolbarHeight)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true
    }, main)

    if config.Watermark and config.Watermark ~= "" then
        window.Watermark = makeLabel(window.Content, tostring(config.Watermark), theme, {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 10, 1, -6),
            Size = UDim2.fromOffset(200, 14),
            TextColor3 = theme.Watermark,
            TextSize = 10,
            Active = false,
            ZIndex = 0
        })
    end

    local _, mainScroll, updateScroll = createScroller(window, window.Content)
    listLayout(mainScroll, 0)
    window.MainScroll = mainScroll
    window._updateScroll = updateScroll

    window.DropdownLayer = create("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 40
    }, window.Content)

    window.DropdownBackdrop = create("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        ZIndex = 40
    }, window.DropdownLayer)

    window.DropdownBackdrop.MouseButton1Click:Connect(function()
        window:_closePopup()
    end)

    mainScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if window._activePopup then
            window:_closePopup()
        end
    end)

    window.EmptySearchLabel = makeLabel(mainScroll, "No matching settings", theme, {
        Size = UDim2.new(1, 0, 0, 26),
        TextColor3 = theme.MutedText,
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
        LayoutOrder = 999999
    })

    if window.SearchBox then
        window.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            window:_applySearch()
        end)
    end

    ------------------------------------------------------------------
    -- Arrastar / redimensionar / minimizar
    ------------------------------------------------------------------

    local lastHeight = initialHeight

    local function currentBounds()
        local size = screen.AbsoluteSize
        if size.X < 100 or size.Y < 100 then
            local okCam, cam = pcall(function()
                return Workspace.CurrentCamera
            end)
            if okCam and cam then
                size = cam.ViewportSize
            else
                size = viewport
            end
        end
        return size
    end

    window.ResizeOverlay = create("Frame", {
        Position = main.Position,
        Size = main.Size,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 100
    }, screen)

    local function syncResizeOverlay()
        if not window.ResizeOverlay or not main then
            return
        end
        window.ResizeOverlay.Position = main.Position
        window.ResizeOverlay.Size = main.Size
        window.ResizeOverlay.Visible = not window.Minimized
    end

    main:GetPropertyChangedSignal("Position"):Connect(syncResizeOverlay)
    main:GetPropertyChangedSignal("Size"):Connect(function()
        syncResizeOverlay()
        if window._activePopup then
            window:_closePopup()
        end
    end)

    local Pointer = {
        Mode = nil,
        Edge = nil,
        Handle = nil,
        ActiveInput = nil,
        Start = Vector3.new(),
        StartPosition = UDim2.new(),
        StartSize = Vector2.new()
    }

    local function beginPointer(mode, input, edge, handle)
        Pointer.Mode = mode
        Pointer.Edge = edge
        Pointer.Handle = handle
        Pointer.ActiveInput = input
        Pointer.Start = input.Position
        Pointer.StartPosition = main.Position
        Pointer.StartSize = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset)
        if handle then
            cancelTween(handle)
            handle.BackgroundTransparency = 0.2
        end
    end

    local function endPointer()
        if Pointer.Handle and Pointer.Handle.Parent then
            cancelTween(Pointer.Handle)
            Pointer.Handle.BackgroundTransparency = 1
        end
        for _, handle in pairs(window.Resize) do
            if handle and handle.Parent then
                cancelTween(handle)
                handle.BackgroundTransparency = 1
            end
        end
        Pointer.Mode = nil
        Pointer.Edge = nil
        Pointer.Handle = nil
        Pointer.ActiveInput = nil
    end
    window._endPointer = endPointer

    local minimizeToken = 0

    local function setMinimized(value)
        if value == window.Minimized then
            return
        end
        window.Minimized = value
        minimizeToken = minimizeToken + 1
        local currentToken = minimizeToken

        if Pointer.Mode == "Resize" then
            endPointer()
        end

        if value then
            window:_closePopup()
            lastHeight = main.Size.Y.Offset
            if window.Toolbar then
                window.Toolbar.Visible = false
            end
            window.Content.Visible = false
            window.ResizeOverlay.Visible = false
            for _, handle in pairs(window.Resize) do
                handle.Active = false
                handle.Visible = false
                handle.BackgroundTransparency = 1
            end
            minimizeIcon.Image = Icon.Maximize
            tween(main, 0.16, {Size = UDim2.fromOffset(main.Size.X.Offset, headerHeight)})
        else
            if window.Toolbar then
                window.Toolbar.Visible = true
            end
            window.Content.Visible = true
            for _, handle in pairs(window.Resize) do
                handle.Visible = true
                handle.Active = true
                handle.BackgroundTransparency = 1
            end
            minimizeIcon.Image = Icon.Minimal
            local bounds = currentBounds()
            local targetHeight = math.clamp(lastHeight, MinSize.Y, math.max(MinSize.Y, bounds.Y))
            local clampedY = math.clamp(main.Position.Y.Offset, 0, math.max(0, bounds.Y - targetHeight))
            local t = tween(main, 0.16, {
                Size = UDim2.fromOffset(main.Size.X.Offset, targetHeight),
                Position = UDim2.fromOffset(main.Position.X.Offset, clampedY)
            })
            t.Completed:Connect(function(playbackState)
                if playbackState == Enum.PlaybackState.Completed and currentToken == minimizeToken and not window.Minimized then
                    syncResizeOverlay()
                    updateScroll()
                end
            end)
        end
    end
    window._setMinimized = setMinimized

    minimizeButton.MouseButton1Click:Connect(function()
        setMinimized(not window.Minimized)
    end)

    closeButton.MouseButton1Click:Connect(function()
        window:Destroy(true)
    end)

    header.InputBegan:Connect(function(input)
        if isPointerPress(input) then
            beginPointer("Drag", input)
        end
    end)

    local function handlePointerMove(input)
        if not Pointer.Mode then
            return
        end
        if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
            if input.UserInputType ~= Enum.UserInputType.Touch or not Pointer.ActiveInput or Pointer.ActiveInput == input then
                endPointer()
            end
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch and Pointer.ActiveInput and input ~= Pointer.ActiveInput then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - Pointer.Start
        local bounds = currentBounds()
        local startX = Pointer.StartPosition.X.Offset
        local startY = Pointer.StartPosition.Y.Offset

        if Pointer.Mode == "Drag" then
            local width = main.Size.X.Offset
            local height = main.Size.Y.Offset
            local maxX = math.max(0, bounds.X - width)
            local maxY = math.max(0, bounds.Y - height)
            local x = math.clamp(math.floor(startX + delta.X + 0.5), 0, maxX)
            local y = math.clamp(math.floor(startY + delta.Y + 0.5), 0, maxY)
            main.Position = UDim2.fromOffset(x, y)
            return
        end

        if window.Minimized then
            return
        end

        local startW = Pointer.StartSize.X
        local startH = Pointer.StartSize.Y
        local posX = startX
        local posY = startY
        local width = startW
        local height = startH

        if Pointer.Edge == "Right" then
            local maxW = math.max(MinSize.X, bounds.X - startX)
            width = math.clamp(math.floor(startW + delta.X + 0.5), MinSize.X, maxW)
        elseif Pointer.Edge == "Left" then
            local rightEdge = startX + startW
            local clampedX = math.clamp(math.floor(startX + delta.X + 0.5), 0, math.max(0, rightEdge - MinSize.X))
            posX = clampedX
            width = rightEdge - clampedX
        elseif Pointer.Edge == "Bottom" then
            local maxH = math.max(MinSize.Y, bounds.Y - startY)
            height = math.clamp(math.floor(startH + delta.Y + 0.5), MinSize.Y, maxH)
        elseif Pointer.Edge == "Top" then
            local bottomEdge = startY + startH
            local clampedY = math.clamp(math.floor(startY + delta.Y + 0.5), 0, math.max(0, bottomEdge - MinSize.Y))
            posY = clampedY
            height = bottomEdge - clampedY
        end

        main.Position = UDim2.fromOffset(posX, posY)
        main.Size = UDim2.fromOffset(width, height)
        lastHeight = height
    end

    window:_connect(UserInputService.InputChanged, handlePointerMove)

    pcall(function()
        window:_connect(UserInputService.TouchMoved, handlePointerMove)
    end)

    window:_connect(UserInputService.InputEnded, function(input)
        if not Pointer.Mode then
            return
        end
        if input.UserInputType == Enum.UserInputType.Touch then
            if not Pointer.ActiveInput or Pointer.ActiveInput == input then
                endPointer()
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            endPointer()
        end
    end)

    pcall(function()
        window:_connect(UserInputService.TouchEnded, function(input)
            if Pointer.Mode and (not Pointer.ActiveInput or Pointer.ActiveInput == input) then
                endPointer()
            end
        end)
    end)

    pcall(function()
        window:_connect(UserInputService.WindowFocusReleased, function()
            if Pointer.Mode then
                endPointer()
            end
        end)
    end)

    local function createResizeHandle(edge, position, size)
        local handle = create("TextButton", {
            Position = position,
            Size = size,
            BackgroundColor3 = theme.ResizeActive,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            Selectable = false,
            Active = true,
            ZIndex = 105
        }, window.ResizeOverlay)

        handle.MouseEnter:Connect(function()
            if not Pointer.Mode and not window.Minimized and not isTouchOnlyInput(nil) then
                tween(handle, 0.10, {BackgroundTransparency = 0.55})
            end
        end)

        handle.MouseLeave:Connect(function()
            if Pointer.Handle ~= handle then
                cancelTween(handle)
                handle.BackgroundTransparency = 1
            end
        end)

        handle.InputBegan:Connect(function(input)
            if isPointerPress(input) and not window.Minimized then
                beginPointer("Resize", input, edge, handle)
            end
        end)

        handle.InputEnded:Connect(function(input)
            if Pointer.Handle == handle and isPointerPress(input) then
                endPointer()
            elseif Pointer.Handle ~= handle then
                cancelTween(handle)
                handle.BackgroundTransparency = 1
            end
        end)

        window.Resize[edge] = handle
        return handle
    end

    if config.Resizable ~= false then
        createResizeHandle("Left", UDim2.new(0, -5, 0, 0), UDim2.new(0, 5, 1, 0))
        createResizeHandle("Top", UDim2.new(0, 0, 0, -5), UDim2.new(1, 0, 0, 5))
        createResizeHandle("Right", UDim2.new(1, 0, 0, 0), UDim2.new(0, 5, 1, 0))
        createResizeHandle("Bottom", UDim2.new(0, 0, 1, 0), UDim2.new(1, 0, 0, 5))
    end

    syncResizeOverlay()

    -- tecla para mostrar/ocultar
    if config.ToggleKey then
        window:_connect(UserInputService.InputBegan, function(input, gameProcessed)
            if gameProcessed then
                return
            end
            if input.KeyCode == config.ToggleKey then
                window:Toggle()
            end
        end)
    end

    -- registro global
    table.insert(Library.Windows, window)
    if genv and id then
        genv.__PMLibWindows[id] = window
    end

    return window
end

function Library:DestroyAll()
    for i = #self.Windows, 1, -1 do
        local window = self.Windows[i]
        if window then
            window:Destroy()
        end
    end
end

return Library
