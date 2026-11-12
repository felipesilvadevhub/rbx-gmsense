--!nocheck
--[[
	NovaUI - UI library para Roblox (Luau) com icones Lucide.

	local NovaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/NovaUI.luau"))()
	local window = NovaUI:CreateWindow({ Name = "NovaUI", Logo = "mountain", ToggleKey = Enum.KeyCode.Insert })
	local tab = window:AddTab("Ragebot", "pen-tool")
	local section = tab:AddSection("Globals", "Left")
	section:AddToggle({ Text = "Master switch", Flag = "master", Default = true, Risky = true })

	Icones: qualquer nome de https://lucide.dev/icons (ex: "crosshair", "eye", "settings").
	Tambem aceita "rbxassetid://..." ou um id numerico.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Library = {
	Version = "1.0.0",
	LucideUrl = "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau",
	Lucide = nil,
	Flags = {},
	Windows = {},
	Theme = {
		Background = Color3.fromRGB(21, 22, 27),
		Sidebar = Color3.fromRGB(17, 18, 22),
		Panel = Color3.fromRGB(27, 28, 34),
		Element = Color3.fromRGB(36, 38, 46),
		ElementHover = Color3.fromRGB(44, 46, 56),
		Border = Color3.fromRGB(40, 42, 51),
		Text = Color3.fromRGB(222, 224, 230),
		TextDim = Color3.fromRGB(128, 132, 145),
		Header = Color3.fromRGB(98, 102, 115),
		Off = Color3.fromRGB(150, 152, 162),
		Accent = Color3.fromRGB(58, 130, 247),
		Risky = Color3.fromRGB(232, 192, 62),
	},
}

local Theme = Library.Theme
local SIDEBAR = 50
local TOPBAR = 46
local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

-- Utilidades ----------------------------------------------------------------------

local function create(className, props, children)
	local inst = Instance.new(className)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 4), Parent = parent })
end

local function stroke(parent, color, transparency, thickness)
	return create("UIStroke", {
		Color = color or Theme.Border,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function padding(parent, top, bottom, left, right)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		Parent = parent,
	})
end

local function list(parent, pad, direction, hAlign, vAlign)
	return create("UIListLayout", {
		Padding = UDim.new(0, pad or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function text(props)
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	props.Font = props.Font or FONT
	props.TextSize = props.TextSize or 12
	props.TextColor3 = props.TextColor3 or Theme.Text
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return create("TextLabel", props)
end

local function tween(inst, props, duration)
	local t = TweenService:Create(inst, TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function mouse()
	return UserInputService:GetMouseLocation()
end

-- Chama onMove a cada movimento ate soltar o botao.
local function trackDrag(onMove, onEnd)
	local move, ended
	onMove(mouse())
	move = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			onMove(mouse())
		end
	end)
	ended = UserInputService.InputEnded:Connect(function(input)
		if isPress(input) then
			move:Disconnect()
			ended:Disconnect()
			if onEnd then
				onEnd()
			end
		end
	end)
end

local function round(value, decimals)
	local m = 10 ^ (decimals or 0)
	return math.floor(value * m + 0.5) / m
end

local KEY_NAMES = {
	LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl",
	LeftAlt = "LAlt", RightAlt = "RAlt", MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3",
	Insert = "Ins", Delete = "Del", PageUp = "PgUp", PageDown = "PgDn", CapsLock = "Caps",
	Return = "Enter", Backspace = "Back",
}

local function keyName(key)
	if not key then
		return "None"
	end
	return KEY_NAMES[key.Name] or key.Name
end

local function toKey(value)
	if typeof(value) == "EnumItem" then
		return value
	end
	if type(value) == "string" then
		local ok, key = pcall(function()
			return Enum.KeyCode[value]
		end)
		if ok and key then
			return key
		end
		ok, key = pcall(function()
			return Enum.UserInputType[value]
		end)
		if ok and key then
			return key
		end
	end
	return nil
end

local function keyMatches(input, key)
	if not key then
		return false
	end
	if key.EnumType == Enum.KeyCode then
		return input.KeyCode == key
	end
	return input.UserInputType == key
end

local function guiParent()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local canCore = pcall(function()
		local probe = Instance.new("Folder")
		probe.Parent = game:GetService("CoreGui")
		probe:Destroy()
	end)
	if canCore then
		return game:GetService("CoreGui")
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Icones (Lucide) -------------------------------------------------------------------

local function getLucide()
	if Library.Lucide ~= nil then
		return Library.Lucide or nil
	end

	local mod
	pcall(function()
		local inst = ReplicatedStorage:FindFirstChild("Lucide") or ReplicatedStorage:FindFirstChild("lucide-roblox")
		if inst and inst:IsA("ModuleScript") then
			mod = require(inst)
		end
	end)
	if type(mod) ~= "table" or type(mod.GetAsset) ~= "function" then
		mod = nil
	end

	if not mod then
		pcall(function()
			mod = loadstring(game:HttpGet(Library.LucideUrl))()
		end)
	end

	if type(mod) ~= "table" or type(mod.GetAsset) ~= "function" then
		mod = nil
		warn("[NovaUI] Lucide nao carregou; icones ficarao vazios. Use NovaUI:SetLucide(modulo).")
	end
	Library.Lucide = mod or false
	return mod
end

function Library:SetLucide(module)
	Library.Lucide = module or false
end

local function applyIcon(image, icon)
	image.ImageRectSize = Vector2.zero
	image.ImageRectOffset = Vector2.zero
	if not icon or icon == "" then
		image.Image = ""
		return
	end
	if tonumber(icon) then
		image.Image = "rbxassetid://" .. tostring(icon)
		return
	end
	if string.find(icon, "://", 1, true) then
		image.Image = icon
		return
	end

	local lucide = getLucide()
	if not lucide then
		image.Image = ""
		return
	end
	local ok, asset = pcall(lucide.GetAsset, icon, 48)
	if ok and asset then
		image.Image = asset.Url
		image.ImageRectSize = asset.ImageRectSize
		image.ImageRectOffset = asset.ImageRectOffset
	else
		image.Image = ""
		warn("[NovaUI] icone lucide nao encontrado: " .. tostring(icon))
	end
end

function Library.Icon(icon, size, props)
	local image = create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size or 16, size or 16),
		ImageColor3 = Theme.Text,
		ScaleType = Enum.ScaleType.Fit,
	})
	applyIcon(image, icon)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			image[key] = value
		end
	end
	if props and props.Parent then
		image.Parent = props.Parent
	end
	return image
end

Library.SetIcon = applyIcon

-- Classes -------------------------------------------------------------------------

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local Element = {}
Element.__index = Element

local function newElement(section, kind, opts)
	local self = setmetatable({
		Kind = kind,
		Section = section,
		Window = section.Window,
		Flag = opts.Flag,
		Value = nil,
		_callbacks = {},
		_enabled = true,
		_addons = 0,
	}, Element)
	if opts.Callback then
		table.insert(self._callbacks, opts.Callback)
	end
	if self.Flag then
		self.Window.Flags[self.Flag] = self
		Library.Flags[self.Flag] = self
	end
	return self
end

function Element:Get()
	return self.Value
end

function Element:Set(value, silent)
	if self._normalize then
		value = self._normalize(value)
	end
	local changed = value ~= self.Value or type(value) == "table"
	self.Value = value
	if self._render then
		self:_render()
	end
	if changed and not silent then
		self:_fire()
	end
	return self
end

function Element:_fire()
	for _, fn in ipairs(self._callbacks) do
		task.spawn(fn, self.Value)
	end
end

function Element:OnChanged(fn)
	table.insert(self._callbacks, fn)
	return self
end

function Element:Serialize()
	return self.Value
end

function Element:Deserialize(value)
	self:Set(value)
end

function Element:SetVisible(visible)
	if self.Row then
		self.Row.Visible = visible
	end
	return self
end

function Element:SetText(str)
	if self.Label then
		self.Label.Text = str
	end
	return self
end

function Element:SetEnabled(enabled)
	self._enabled = enabled
	if self.Label then
		self.Label.TextTransparency = enabled and 0 or 0.55
	end
	return self
end

function Element:_nextAddon()
	self._addons += 1
	return self._addons
end

-- Addon: Keybind (icone de teclado ao lado do label/controle) -------------------------

function Element:AddKeybind(opts)
	opts = opts or {}
	local parentEl = self
	local window = self.Window
	local kb = newElement(self.Section, "Keybind", { Flag = opts.Flag, Callback = opts.ChangedCallback })
	kb.Row = self.Row
	kb.Mode = opts.Mode or "Toggle"
	kb.Active = kb.Mode == "Always"
	kb._listening = false

	local btn = create("TextButton", {
		Name = "Keybind",
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
		LayoutOrder = self:_nextAddon(),
		Parent = self._addonTo,
	})
	list(btn, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
	local icon = Library.Icon(opts.Icon or "keyboard", 14, { ImageColor3 = Theme.TextDim, ZIndex = 3, Parent = btn })
	local keyText = text({
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 10,
		TextColor3 = Theme.TextDim,
		ZIndex = 3,
		LayoutOrder = 1,
		Parent = btn,
	})

	kb._normalize = toKey
	kb._render = function()
		local color = (kb._listening or kb.Active) and Theme.Accent or Theme.TextDim
		icon.ImageColor3 = color
		keyText.TextColor3 = color
		if kb._listening then
			keyText.Text = "[...]"
		elseif kb.Value then
			local mode = kb.Mode == "Toggle" and "" or (" " .. string.lower(kb.Mode))
			keyText.Text = "[" .. keyName(kb.Value) .. mode .. "]"
		else
			keyText.Text = ""
		end
	end

	local function setActive(state)
		kb.Active = state
		if parentEl.Kind == "Toggle" and opts.SyncToggle ~= false then
			parentEl:Set(state)
		end
		kb:_render()
		if opts.Callback then
			task.spawn(opts.Callback, state)
		end
	end
	kb.SetActive = function(_, state)
		setActive(state)
	end

	function kb:SetMode(mode)
		kb.Mode = mode
		if mode == "Always" then
			setActive(true)
		elseif mode == "Hold" then
			setActive(false)
		end
		kb:_render()
		return kb
	end

	function kb:Serialize()
		return { Key = kb.Value and kb.Value.Name or nil, Mode = kb.Mode }
	end

	function kb:Deserialize(value)
		if type(value) == "table" then
			if value.Mode then
				kb:SetMode(value.Mode)
			end
			kb:Set(value.Key)
		else
			kb:Set(value)
		end
	end

	btn.Activated:Connect(function()
		if not kb._enabled then
			return
		end
		kb._listening = true
		kb:_render()
	end)

	local modes = { "Toggle", "Hold", "Always" }
	btn.MouseButton2Click:Connect(function()
		local index = table.find(modes, kb.Mode) or 1
		kb:SetMode(modes[index % #modes + 1])
	end)

	window:_connect(UserInputService.InputBegan:Connect(function(input, processed)
		if kb._listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				kb._listening = false
				if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
					kb:Set(nil)
				else
					kb:Set(input.KeyCode)
				end
				kb:_render()
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
				kb._listening = false
				kb:Set(input.UserInputType)
				kb:_render()
			end
			return
		end
		if processed or not keyMatches(input, kb.Value) then
			return
		end
		if kb.Mode == "Toggle" then
			local current = kb.Active
			if parentEl.Kind == "Toggle" and opts.SyncToggle ~= false then
				current = parentEl.Value
			end
			setActive(not current)
		elseif kb.Mode == "Hold" then
			setActive(true)
		end
	end))

	window:_connect(UserInputService.InputEnded:Connect(function(input)
		if kb.Mode == "Hold" and keyMatches(input, kb.Value) then
			setActive(false)
		end
	end))

	window:_onAccent(function()
		kb:_render()
	end)
	kb:Set(opts.Default, true)
	return kb
end

-- Addon: Color picker -------------------------------------------------------------------

function Element:AddColorPicker(opts)
	opts = opts or {}
	local window = self.Window
	local cp = newElement(self.Section, "ColorPicker", opts)
	cp.Row = self.Row
	cp.H, cp.S, cp.V = 0, 0, 1

	local swatch = create("TextButton", {
		Name = "ColorPicker",
		Size = UDim2.fromOffset(20, 11),
		AutoButtonColor = false,
		Text = "",
		ZIndex = 3,
		LayoutOrder = self:_nextAddon(),
		Parent = self._addonTo,
	})
	corner(swatch, 3)
	stroke(swatch, Theme.Border)

	local popup = window:_newPopup("ColorPopup", { Size = UDim2.fromOffset(192, 168) })

	local sv = create("TextButton", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(150, 122),
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = popup,
	})
	corner(sv, 4)
	local white = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv })
	corner(white, 4)
	create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
	local black = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv })
	corner(black, 4)
	create("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = black })
	local svCursor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = sv,
	})
	corner(svCursor, 4)
	stroke(svCursor, Color3.new(1, 1, 1), 0, 1.5)

	local rainbow = {}
	for i = 0, 6 do
		table.insert(rainbow, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 1, 1)))
	end
	local hue = create("TextButton", {
		Position = UDim2.fromOffset(166, 8),
		Size = UDim2.fromOffset(18, 122),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Parent = popup,
	})
	corner(hue, 4)
	create("UIGradient", { Color = ColorSequence.new(rainbow), Rotation = 90, Parent = hue })
	local hueCursor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 4, 0, 3),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = hue,
	})
	corner(hueCursor, 2)

	local hex = create("TextBox", {
		Position = UDim2.fromOffset(8, 138),
		Size = UDim2.new(1, -16, 0, 22),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 11,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		Text = "",
		Parent = popup,
	})
	corner(hex, 4)

	local fromHSV = false
	cp._normalize = function(value)
		if typeof(value) == "Color3" then
			return value
		end
		if type(value) == "string" then
			local ok, color = pcall(Color3.fromHex, value)
			if ok then
				return color
			end
		end
		return cp.Value or Color3.new(1, 1, 1)
	end
	cp._render = function()
		if not fromHSV then
			cp.H, cp.S, cp.V = cp.Value:ToHSV()
		end
		swatch.BackgroundColor3 = cp.Value
		sv.BackgroundColor3 = Color3.fromHSV(cp.H, 1, 1)
		svCursor.Position = UDim2.fromScale(cp.S, 1 - cp.V)
		hueCursor.Position = UDim2.new(0.5, 0, cp.H, 0)
		hex.Text = "#" .. string.upper(cp.Value:ToHex())
	end

	local function setHSV()
		fromHSV = true
		cp:Set(Color3.fromHSV(cp.H, cp.S, cp.V))
		fromHSV = false
	end

	sv.InputBegan:Connect(function(input)
		if isPress(input) then
			trackDrag(function(pos)
				cp.S = math.clamp((pos.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
				cp.V = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
				setHSV()
			end)
		end
	end)
	hue.InputBegan:Connect(function(input)
		if isPress(input) then
			trackDrag(function(pos)
				cp.H = math.clamp((pos.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 0.999)
				setHSV()
			end)
		end
	end)
	hex.FocusLost:Connect(function()
		cp:Set(hex.Text)
		cp:_render()
	end)

	swatch.Activated:Connect(function()
		if cp._enabled then
			window:_togglePopup(popup, swatch, "Below")
		end
	end)

	function cp:Serialize()
		return cp.Value:ToHex()
	end

	cp:Set(opts.Default or Color3.new(1, 1, 1), true)
	return cp
end

-- Addon: engrenagem que abre um painel de opcoes extras ---------------------------------

function Element:AddSettings(opts)
	opts = opts or {}
	local window = self.Window

	local gear = create("ImageButton", {
		Name = "Settings",
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ImageColor3 = Theme.TextDim,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 3,
		LayoutOrder = self:_nextAddon(),
		Parent = self._addonTo,
	})
	applyIcon(gear, opts.Icon or "settings")
	gear.MouseEnter:Connect(function()
		tween(gear, { ImageColor3 = Theme.Text })
	end)
	gear.MouseLeave:Connect(function()
		tween(gear, { ImageColor3 = Theme.TextDim })
	end)

	local popup = window:_newPopup("SettingsPopup", {
		Size = UDim2.fromOffset(opts.Width or 240, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	padding(popup, 6, 6, 10, 10)
	list(popup)

	local sec = setmetatable({ Window = window, Container = popup, _count = 0 }, Section)
	if opts.Title then
		local _, _, _, lbl = sec:_row(22)
		lbl.Text = string.upper(opts.Title)
		lbl.Font = FONT_BOLD
		lbl.TextSize = 11
		lbl.TextColor3 = Theme.Header
	end

	gear.Activated:Connect(function()
		window:_togglePopup(popup, gear, "Right")
	end)
	return sec
end

-- Section ---------------------------------------------------------------------------

function Section:_row(height)
	self._count += 1
	local row = create("Frame", {
		Name = "Row",
		Size = UDim2.new(1, 0, 0, height or 26),
		BackgroundTransparency = 1,
		LayoutOrder = self._count,
		Parent = self.Container,
	})
	local left = create("Frame", {
		Name = "Left",
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = row,
	})
	list(left, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
	local right = create("Frame", {
		Name = "Right",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = row,
	})
	list(right, 7, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
	local lbl = text({
		Name = "Label",
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 0,
		Parent = left,
	})
	return row, left, right, lbl
end

function Section:AddLabel(opts)
	if type(opts) == "string" then
		opts = { Text = opts }
	end
	opts = opts or {}
	local row, _, right, lbl = self:_row(opts.Height or 24)
	local el = newElement(self, "Label", opts)
	el.Row, el.Label, el._addonTo = row, lbl, right
	lbl.Text = opts.Text or ""
	lbl.TextColor3 = opts.Color or (opts.Risky and Theme.Risky) or Theme.Text
	return el
end

function Section:AddDivider()
	self._count += 1
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 9),
		BackgroundTransparency = 1,
		LayoutOrder = self._count,
		Parent = self.Container,
	}, {
		create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Theme.Border,
			BorderSizePixel = 0,
		}),
	})
end

function Section:AddToggle(opts)
	opts = opts or {}
	local row, _, right, lbl = self:_row(26)
	local el = newElement(self, "Toggle", opts)
	el.Row, el.Label, el._addonTo = row, lbl, right
	lbl.Text = opts.Text or "Toggle"
	lbl.TextColor3 = opts.Risky and Theme.Risky or Theme.Text

	local click = create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 1,
		Parent = row,
	})
	local dot = create("Frame", {
		Name = "Dot",
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Theme.Off,
		BorderSizePixel = 0,
		LayoutOrder = 1000,
		Parent = right,
	})
	corner(dot, 5)
	local glow = stroke(dot, Theme.Accent, 1, 3)

	el._normalize = function(value)
		return value == true
	end
	el._render = function()
		tween(dot, { BackgroundColor3 = el.Value and Theme.Accent or Theme.Off })
		glow.Color = Theme.Accent
		tween(glow, { Transparency = el.Value and 0.75 or 1 })
	end

	click.Activated:Connect(function()
		if el._enabled then
			el:Set(not el.Value)
		end
	end)

	self.Window:_onAccent(function()
		el:_render()
	end)
	el:Set(opts.Default == true, true)
	return el
end

function Section:AddSlider(opts)
	opts = opts or {}
	local min, max = opts.Min or 0, opts.Max or 100
	local decimals = opts.Decimals or 0
	local suffix = opts.Suffix or ""
	local row, left, right, lbl = self:_row(26)
	local el = newElement(self, "Slider", opts)
	el.Row, el.Label, el._addonTo = row, lbl, left
	el.Min, el.Max = min, max
	lbl.Text = opts.Text or "Slider"
	lbl.TextColor3 = opts.Risky and Theme.Risky or Theme.Text

	local holder = create("Frame", {
		Size = UDim2.fromOffset(opts.Width or 150, 18),
		BackgroundTransparency = 1,
		LayoutOrder = 1000,
		Parent = right,
	})
	local track = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 5, 0.5, 0),
		Size = UDim2.new(1, -54, 0, 4),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		Parent = holder,
	})
	corner(track, 2)
	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(fill, 2)
	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = track,
	})
	corner(knob, 5)
	local hit = create("TextButton", {
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 3,
		Parent = holder,
	})
	local box = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(38, 18),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 11,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		Text = "",
		Parent = holder,
	})
	corner(box, 3)

	local function format(value)
		if decimals == 0 then
			return string.format("%d", value) .. suffix
		end
		return string.format("%." .. decimals .. "f", value) .. suffix
	end

	el._normalize = function(value)
		value = tonumber(value) or min
		return math.clamp(round(value, decimals), min, max)
	end
	el._render = function()
		local p = (max == min) and 0 or (el.Value - min) / (max - min)
		fill.Size = UDim2.fromScale(p, 1)
		knob.Position = UDim2.fromScale(p, 0.5)
		fill.BackgroundColor3 = Theme.Accent
		knob.BackgroundColor3 = Theme.Accent
		box.Text = format(el.Value)
	end

	hit.InputBegan:Connect(function(input)
		if not isPress(input) or not el._enabled then
			return
		end
		trackDrag(function(pos)
			local p = math.clamp((pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			el:Set(min + (max - min) * p)
		end)
	end)

	box.FocusLost:Connect(function()
		local raw = string.gsub(box.Text, "[^%d%.%-]", "")
		local n = tonumber(raw)
		if n and el._enabled then
			el:Set(n)
		end
		el:_render()
	end)

	self.Window:_onAccent(function()
		el:_render()
	end)
	el:Set(opts.Default or min, true)
	return el
end

function Section:AddDropdown(opts)
	opts = opts or {}
	local window = self.Window
	local multi = opts.Multi == true
	local width = opts.Width or 130
	local row, left, right, lbl = self:_row(28)
	local el = newElement(self, "Dropdown", opts)
	el.Row, el.Label, el._addonTo = row, lbl, left
	el.Values = opts.Values or {}
	el.Multi = multi
	lbl.Text = opts.Text or "Dropdown"
	lbl.TextColor3 = opts.Risky and Theme.Risky or Theme.Text

	local btn = create("TextButton", {
		Size = UDim2.fromOffset(width, 20),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = 1000,
		Parent = right,
	})
	corner(btn, 4)
	local current = text({
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -28, 1, 0),
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = btn,
	})
	local chevron = Library.Icon("chevron-down", 12, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		ImageColor3 = Theme.TextDim,
		Parent = btn,
	})

	local ITEM_HEIGHT = 24
	local SEARCH_HEIGHT = 30

	local popup = window:_newPopup("DropdownPopup", {
		Size = UDim2.fromOffset(width, 0),
		BackgroundColor3 = Theme.Element,
		ClipsDescendants = true,
	})

	local searchHolder = create("Frame", {
		Size = UDim2.new(1, 0, 0, SEARCH_HEIGHT),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = popup,
	})
	local searchBox = create("TextBox", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 0, 22),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 11,
		TextColor3 = Theme.Text,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Text = "",
		Parent = searchHolder,
	})
	corner(searchBox, 3)
	padding(searchBox, 0, 0, 24, 6)
	Library.Icon("search", 12, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -17, 0.5, 0),
		ImageColor3 = Theme.TextDim,
		Parent = searchBox,
	})

	local scroll = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.TextDim,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = popup,
	})
	padding(scroll, 4, 4, 4, 4)
	list(scroll, 1)

	local empty = text({
		Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
		Text = "No results",
		TextSize = 11,
		TextColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		LayoutOrder = 100000,
		Parent = scroll,
	})

	local options = {}
	local order = {}

	local function searchEnabled()
		if opts.Search ~= nil then
			return opts.Search
		end
		return #el.Values > 8
	end

	local function isSelected(value)
		if multi then
			return table.find(el.Value or {}, value) ~= nil
		end
		return el.Value == value
	end

	local function paintOptions()
		for value, item in pairs(options) do
			local selected = isSelected(value)
			item.Label.TextColor3 = selected and Theme.Text or Theme.TextDim
			item.Label.Font = selected and FONT_BOLD or FONT
			item.Bar.Visible = selected
			item.Bar.BackgroundColor3 = Theme.Accent
			item.Check.Visible = selected
			item.Check.ImageColor3 = Theme.Accent
		end
	end

	local function visibleCount()
		local count = 0
		for _, item in pairs(options) do
			if item.Button.Visible then
				count += 1
			end
		end
		return count
	end

	local function targetHeight()
		local top = searchEnabled() and SEARCH_HEIGHT or 0
		local count = math.max(visibleCount(), 1)
		return math.min(top + count * (ITEM_HEIGHT + 1) + 8, opts.MaxHeight or 210)
	end

	local function filter(query)
		query = string.lower(query or "")
		for value, item in pairs(options) do
			item.Button.Visible = query == "" or string.find(string.lower(tostring(value)), query, 1, true) ~= nil
		end
		empty.Visible = visibleCount() == 0
	end

	local function choose(value)
		if multi then
			local selected = table.clone(el.Value or {})
			local at = table.find(selected, value)
			if at then
				table.remove(selected, at)
			else
				table.insert(selected, value)
			end
			el:Set(selected)
		elseif opts.AllowNone and el.Value == value then
			el:Set(nil)
		else
			el:Set(value)
			window:_closePopup(popup)
		end
	end

	local function build()
		for _, item in pairs(options) do
			item.Button:Destroy()
		end
		table.clear(options)
		table.clear(order)
		for index, value in ipairs(el.Values) do
			local optBtn = create("TextButton", {
				Size = UDim2.new(1, 0, 0, ITEM_HEIGHT),
				BackgroundColor3 = Theme.ElementHover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Parent = scroll,
			})
			corner(optBtn, 3)
			local bar = create("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(2, 12),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				Visible = false,
				Parent = optBtn,
			})
			corner(bar, 1)
			local optLabel = text({
				Position = UDim2.fromOffset(9, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Text = tostring(value),
				TextSize = 11,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = optBtn,
			})
			local check = Library.Icon("check", 12, {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Visible = false,
				Parent = optBtn,
			})
			optBtn.MouseEnter:Connect(function()
				tween(optBtn, { BackgroundTransparency = 0 }, 0.08)
			end)
			optBtn.MouseLeave:Connect(function()
				tween(optBtn, { BackgroundTransparency = 1 }, 0.08)
			end)
			optBtn.Activated:Connect(function()
				choose(value)
			end)
			options[value] = { Button = optBtn, Label = optLabel, Check = check, Bar = bar }
			table.insert(order, value)
		end
		filter(searchBox.Text)
		paintOptions()
	end

	local function layoutPopup()
		local top = searchEnabled() and SEARCH_HEIGHT or 0
		searchHolder.Visible = top > 0
		scroll.Position = UDim2.fromOffset(0, top)
		scroll.Size = UDim2.new(1, 0, 1, -top)
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		filter(searchBox.Text)
		if popup.Visible then
			tween(popup, { Size = UDim2.fromOffset(width, targetHeight()) }, 0.1)
		end
	end)
	searchBox.FocusLost:Connect(function(enter)
		if not enter then
			return
		end
		for _, value in ipairs(order) do
			if options[value].Button.Visible then
				choose(value)
				break
			end
		end
	end)

	el._normalize = function(value)
		if multi then
			local out = {}
			if type(value) == "table" then
				for _, v in ipairs(el.Values) do
					if table.find(value, v) then
						table.insert(out, v)
					end
				end
			end
			return out
		end
		return value
	end
	el._render = function()
		if multi then
			current.Text = #el.Value > 0 and table.concat(el.Value, ", ") or "None"
		else
			current.Text = el.Value ~= nil and tostring(el.Value) or "None"
		end
		paintOptions()
	end

	function el:Refresh(values, keepSelection)
		el.Values = values or {}
		build()
		if keepSelection then
			el:Set(el.Value, true)
		else
			el:Set(multi and {} or nil, true)
		end
		return el
	end

	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.ElementHover }, 0.1)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.Element }, 0.1)
	end)
	btn.Activated:Connect(function()
		if not el._enabled then
			return
		end
		searchBox.Text = ""
		layoutPopup()
		filter("")
		local height = targetHeight()
		popup.Size = UDim2.fromOffset(width, height)
		window:_togglePopup(popup, btn, "Below", function(open)
			tween(chevron, { Rotation = open and 180 or 0 })
			tween(btn, { BackgroundColor3 = open and Theme.ElementHover or Theme.Element }, 0.1)
			if open then
				popup.Size = UDim2.fromOffset(width, 0)
				tween(popup, { Size = UDim2.fromOffset(width, height) }, 0.16)
			end
		end)
	end)

	window:_onAccent(paintOptions)
	build()
	el:Set(opts.Default or (multi and {} or nil), true)
	return el
end

function Section:AddButton(opts)
	opts = opts or {}
	local row = self:_row(32)
	local el = newElement(self, "Button", opts)
	el.Row = row

	local btn = create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = FONT,
		TextSize = 12,
		TextColor3 = opts.Risky and Theme.Risky or Theme.Text,
		Text = opts.Text or "Button",
		ZIndex = 3,
		Parent = row,
	})
	corner(btn, 4)
	local outline = stroke(btn, Theme.Border)
	el.Label = btn
	if opts.Icon then
		Library.Icon(opts.Icon, 14, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			ImageColor3 = Theme.TextDim,
			ZIndex = 3,
			Parent = btn,
		})
	end

	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.ElementHover }, 0.1)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.Element }, 0.1)
	end)
	btn.Activated:Connect(function()
		if not el._enabled then
			return
		end
		outline.Color = Theme.Accent
		tween(outline, { Color = Theme.Border }, 0.4)
		el:_fire()
	end)
	return el
end

function Section:AddTextbox(opts)
	opts = opts or {}
	local hasLabel = opts.Text ~= nil
	local row, left, right, lbl = self:_row(28)
	local el = newElement(self, "Textbox", opts)
	el.Row, el.Label, el._addonTo = row, lbl, left
	lbl.Text = opts.Text or ""

	local box = create("TextBox", {
		Size = hasLabel and UDim2.fromOffset(opts.Width or 130, 20) or UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 11,
		TextColor3 = Theme.Text,
		PlaceholderText = opts.Placeholder or "",
		PlaceholderColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClearTextOnFocus = false,
		Text = "",
		LayoutOrder = 1000,
		ZIndex = 3,
		Parent = hasLabel and right or row,
	})
	if not hasLabel then
		box.AnchorPoint = Vector2.new(0, 0.5)
		box.Position = UDim2.fromScale(0, 0.5)
	end
	corner(box, 4)
	padding(box, 0, 0, 8, 8)
	local outline = stroke(box, Theme.Border)

	el._normalize = function(value)
		value = tostring(value or "")
		if opts.Numeric then
			value = string.gsub(value, "[^%d%.%-]", "")
		end
		return value
	end
	el._render = function()
		box.Text = el.Value
	end

	box.Focused:Connect(function()
		tween(outline, { Color = Theme.Accent })
	end)
	box.FocusLost:Connect(function(enter)
		tween(outline, { Color = Theme.Border })
		if not el._enabled then
			el:_render()
			return
		end
		if opts.Finished and not enter then
			el:_render()
			return
		end
		el:Set(box.Text)
	end)

	el:Set(opts.Default or "", true)
	return el
end

-- Tab ---------------------------------------------------------------------------------

function Tab:AddSection(name, side)
	local column = (side == "Right" or side == 2) and self._right or self._left
	self._sections += 1

	local holder = create("Frame", {
		Name = name or "Section",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self._sections,
		Parent = column,
	})
	list(holder, 6)
	text({
		Size = UDim2.new(1, 0, 0, 14),
		Text = string.upper(name or ""),
		Font = FONT_BOLD,
		TextSize = 11,
		TextColor3 = Theme.Header,
		Parent = holder,
	})
	local panel = create("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Parent = holder,
	})
	corner(panel, 6)
	stroke(panel, Theme.Border)
	padding(panel, 5, 5, 12, 12)
	list(panel)

	return setmetatable({ Window = self.Window, Tab = self, Container = panel, Holder = holder, _count = 0 }, Section)
end

-- Alias para quem vem de outras libs.
Tab.AddGroup = Tab.AddSection

function Tab:Select()
	local window = self.Window
	window:_closePopups(0)
	for _, tab in ipairs(window.Tabs) do
		local selected = tab == self
		tab.Page.Visible = selected
		tab._bar.Visible = selected
		tab._bar.BackgroundColor3 = Theme.Accent
		tween(tab._button, { BackgroundTransparency = selected and 0 or 1 })
		tween(tab._icon, { ImageColor3 = selected and Theme.Text or Theme.TextDim })
	end
	window.ActiveTab = self
	window._title.Text = self.Name
end

-- Window --------------------------------------------------------------------------------

function Library:CreateWindow(opts)
	opts = opts or {}
	if opts.Accent then
		Theme.Accent = opts.Accent
	end

	local self = setmetatable({
		Name = opts.Name or "NovaUI",
		Flags = {},
		Tabs = {},
		ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
		ConfigFolder = opts.ConfigFolder or "NovaUI",
		_conns = {},
		_popups = {},
		_accentHooks = {},
		_unload = {},
		_locked = false,
		_loading = false,
		_unlockMouse = opts.UnlockMouse ~= false,
		_renderName = "NovaUI_" .. HttpService:GenerateGUID(false),
		_logoIcon = opts.Logo or "mountain",
	}, Window)

	local gui = create("ScreenGui", {
		Name = "NovaUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	gui.Parent = guiParent()
	self.Gui = gui

	local main = create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = opts.Size or UDim2.fromOffset(660, 460),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = gui,
	})
	corner(main, 8)
	stroke(main, Theme.Border)
	self.Main = main
	self._scale = create("UIScale", { Parent = main })

	-- Botao Modal: em primeira pessoa/shift-lock o Roblox solta o cursor enquanto ele esta visivel.
	create("TextButton", {
		Name = "Modal",
		Modal = self._unlockMouse,
		Size = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Text = "",
		Parent = main,
	})

	-- Sidebar
	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, SIDEBAR, 1, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = main,
	})
	corner(sidebar, 8)
	create("Frame", {
		Position = UDim2.new(1, -8, 0, 0),
		Size = UDim2.new(0, 8, 1, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	create("Frame", {
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		Parent = sidebar,
	})
	local logo = Library.Icon(opts.Logo or "mountain", 22, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, TOPBAR / 2),
		ImageColor3 = Theme.Text,
		Parent = sidebar,
	})
	self._logo = logo

	self._tabList = create("Frame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(0, TOPBAR + 6),
		Size = UDim2.new(1, 0, 1, -(TOPBAR + 60)),
		BackgroundTransparency = 1,
		Parent = sidebar,
	})
	list(self._tabList, 2)
	self._bottomList = create("Frame", {
		Name = "Bottom",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = sidebar,
	})
	list(self._bottomList, 2)

	-- Topbar
	local topbar = create("Frame", {
		Name = "Topbar",
		Position = UDim2.fromOffset(SIDEBAR + 1, 0),
		Size = UDim2.new(1, -(SIDEBAR + 1), 0, TOPBAR),
		BackgroundTransparency = 1,
		Parent = main,
	})
	self._title = text({
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -32, 1, 0),
		Font = FONT_BOLD,
		TextSize = 16,
		Text = "",
		Parent = topbar,
	})
	text({
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -32, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Theme.Header,
		TextSize = 11,
		Text = opts.Subtitle or self.Name,
		Parent = topbar,
	})

	self.Content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(SIDEBAR + 1, TOPBAR),
		Size = UDim2.new(1, -(SIDEBAR + 1), 1, -TOPBAR),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main,
	})

	self.PopupLayer = create("Frame", {
		Name = "Popups",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	})

	-- Camada invisivel atras dos popups: clicar fora fecha tudo sem depender da posicao do mouse.
	self._blocker = create("TextButton", {
		Name = "Blocker",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 1,
		Parent = self.PopupLayer,
	})
	self._blocker.MouseButton1Down:Connect(function()
		self:_closePopups(0)
	end)
	self._blocker.MouseButton2Down:Connect(function()
		self:_closePopups(0)
	end)

	self._notifications = create("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 270, 1, -32),
		BackgroundTransparency = 1,
		ZIndex = 60,
		Parent = gui,
	})
	list(self._notifications, 6, nil, nil, Enum.VerticalAlignment.Bottom)

	-- Arrastar pela topbar e pelo logo
	for _, handle in ipairs({ topbar, logo }) do
		handle.InputBegan:Connect(function(input)
			if not isPress(input) or self._locked then
				return
			end
			self:_closePopups(0)
			local start = mouse()
			local origin = main.Position
			trackDrag(function(pos)
				local delta = pos - start
				main.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
			end)
		end)
	end

	self:_connect(UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.Escape and #self._popups > 0 then
			self:_closePopups(0)
			return
		end
		if not processed and self.ToggleKey and input.KeyCode == self.ToggleKey then
			self:Toggle()
		end
	end))

	if opts.MobileButton ~= false and UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		local mobile = create("ImageButton", {
			Name = "MobileToggle",
			Position = UDim2.fromOffset(16, 80),
			Size = UDim2.fromOffset(42, 42),
			BackgroundColor3 = Theme.Background,
			ImageColor3 = Theme.Text,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 70,
			Parent = gui,
		})
		corner(mobile, 8)
		stroke(mobile, Theme.Border)
		padding(mobile, 10, 10, 10, 10)
		applyIcon(mobile, opts.Logo or "mountain")
		mobile.Activated:Connect(function()
			self:Toggle()
		end)
	end

	table.insert(Library.Windows, self)

	if opts.Loading then
		self:_runLoader(opts.Loading)
	else
		self:_setMouseFree(true)
	end
	return self
end

function Window:_setMouseFree(free)
	if not self._unlockMouse then
		return
	end
	if free and not self._mouseBound then
		self._mouseBound = true
		self._prevMouseIcon = UserInputService.MouseIconEnabled
		RunService:BindToRenderStep(self._renderName, Enum.RenderPriority.Last.Value + 1, function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end)
	elseif not free and self._mouseBound then
		self._mouseBound = false
		pcall(RunService.UnbindFromRenderStep, RunService, self._renderName)
		if self._prevMouseIcon ~= nil then
			UserInputService.MouseIconEnabled = self._prevMouseIcon
		end
	end
end

function Window:_runLoader(cfg)
	cfg = type(cfg) == "table" and cfg or {}
	self._loading = true
	self.Main.Visible = false

	local gui = self.Gui
	local backdrop = create("Frame", {
		Name = "LoadingBackdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 80,
		Parent = gui,
	})
	local card = create("CanvasGroup", {
		Name = "Loading",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(320, 176),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		ZIndex = 81,
		Parent = gui,
	})
	corner(card, 10)
	stroke(card, Theme.Border)
	local scale = create("UIScale", { Scale = 0.9, Parent = card })

	local glow = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 20),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Parent = card,
	})
	corner(glow, 12)
	local logo = Library.Icon(cfg.Icon or self._logoIcon, 28, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ImageColor3 = Theme.Accent,
		Parent = glow,
	})
	text({
		Position = UDim2.fromOffset(0, 82),
		Size = UDim2.new(1, 0, 0, 20),
		Text = cfg.Title or self.Name,
		Font = FONT_BOLD,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})
	text({
		Position = UDim2.fromOffset(0, 104),
		Size = UDim2.new(1, 0, 0, 14),
		Text = cfg.Subtitle or "Carregando interface",
		TextSize = 11,
		TextColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = card,
	})
	local track = create("Frame", {
		Position = UDim2.new(0, 24, 1, -40),
		Size = UDim2.new(1, -48, 0, 4),
		BackgroundColor3 = Theme.Element,
		BorderSizePixel = 0,
		Parent = card,
	})
	corner(track, 2)
	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(fill, 2)
	local status = text({
		Position = UDim2.new(0, 24, 1, -30),
		Size = UDim2.new(1, -48, 0, 16),
		TextSize = 11,
		TextColor3 = Theme.TextDim,
		Text = "",
		Parent = card,
	})
	local percent = text({
		Position = UDim2.new(0, 24, 1, -30),
		Size = UDim2.new(1, -48, 0, 16),
		TextSize = 11,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "0%",
		Parent = card,
	})

	tween(backdrop, { BackgroundTransparency = 0.45 }, 0.3)
	tween(card, { GroupTransparency = 0 }, 0.3)
	tween(scale, { Scale = 1 }, 0.3)

	task.spawn(function()
		-- Espera o script terminar de montar abas/elementos antes de pre-carregar os icones.
		task.wait()
		local duration = cfg.Duration or 2.5
		local steps = cfg.Steps or { "Inicializando", "Carregando icones", "Montando interface", "Pronto" }

		local assets, seen = {}, {}
		for _, inst in ipairs(gui:GetDescendants()) do
			if (inst:IsA("ImageLabel") or inst:IsA("ImageButton")) and inst.Image ~= "" and not seen[inst.Image] then
				seen[inst.Image] = true
				table.insert(assets, inst.Image)
			end
		end
		local preloaded = false
		task.spawn(function()
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync(assets)
			end)
			preloaded = true
		end)

		local start = os.clock()
		while gui.Parent do
			local elapsed = os.clock() - start
			local t = math.clamp(elapsed / duration, 0, 1)
			if not preloaded and elapsed < duration + 5 then
				t = math.min(t, 0.92)
			end
			fill.Size = UDim2.fromScale(t, 1)
			percent.Text = math.floor(t * 100) .. "%"
			status.Text = steps[math.clamp(math.floor(t * #steps) + 1, 1, #steps)]
			logo.Rotation = math.sin(elapsed * 3) * 6
			if t >= 1 then
				break
			end
			task.wait()
		end
		if not gui.Parent then
			return
		end

		task.wait(0.2)
		tween(backdrop, { BackgroundTransparency = 1 }, 0.25)
		tween(card, { GroupTransparency = 1 }, 0.25)
		tween(scale, { Scale = 0.9 }, 0.25)
		task.wait(0.25)
		backdrop:Destroy()
		card:Destroy()

		self._loading = false
		self:Toggle(true)
		if cfg.Callback then
			task.spawn(cfg.Callback)
		end
	end)
end

function Window:_newPopup(name, props)
	local popup = create("TextButton", {
		Name = name,
		Visible = false,
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Active = true,
		Parent = self.PopupLayer,
	})
	for key, value in pairs(props or {}) do
		popup[key] = value
	end
	corner(popup, 6)
	stroke(popup, Theme.Border)
	-- Clique no fundo do popup fecha so os popups abertos acima dele (ex: dropdown dentro da engrenagem).
	popup.MouseButton1Down:Connect(function()
		local index = self:_popupIndex(popup)
		if index then
			self:_closePopups(index)
		end
	end)
	return popup
end

function Window:_connect(connection)
	table.insert(self._conns, connection)
	return connection
end

function Window:_onAccent(fn)
	table.insert(self._accentHooks, fn)
end

function Window:_popupIndex(frame)
	for i, popup in ipairs(self._popups) do
		if popup.Frame == frame then
			return i
		end
	end
	return nil
end

function Window:_closePopups(keep)
	for i = #self._popups, keep + 1, -1 do
		local popup = table.remove(self._popups, i)
		popup.Frame.Visible = false
		if popup.OnState then
			popup.OnState(false)
		end
	end
	self._blocker.Visible = #self._popups > 0
end

function Window:_closePopup(frame)
	local index = self:_popupIndex(frame)
	if index then
		self:_closePopups(index - 1)
	end
end

function Window:_togglePopup(frame, anchor, placement, onState)
	local index = self:_popupIndex(frame)
	if index then
		self:_closePopups(index - 1)
		return
	end

	local ap, as = anchor.AbsolutePosition, anchor.AbsoluteSize
	local screen = self.Gui.AbsoluteSize
	local width = frame.Size.X.Offset
	local height = frame.AutomaticSize == Enum.AutomaticSize.Y and frame.AbsoluteSize.Y or frame.Size.Y.Offset
	frame.Active = true
	local x, y
	if placement == "Right" then
		x, y = ap.X + as.X + 10, ap.Y - 8
	else
		x, y = ap.X + as.X - width, ap.Y + as.Y + 4
		if y + height > screen.Y - 4 then
			y = ap.Y - height - 4
		end
	end
	x = math.clamp(x, 4, math.max(4, screen.X - width - 4))
	y = math.clamp(y, 4, math.max(4, screen.Y - height - 4))
	frame.Position = UDim2.fromOffset(x, y)
	frame.ZIndex = 10 + #self._popups
	frame.Visible = true
	self._blocker.Visible = true

	table.insert(self._popups, { Frame = frame, Anchor = anchor, OnState = onState })
	if onState then
		onState(true)
	end
end

function Window:AddTab(name, icon, opts)
	if type(name) == "table" then
		opts = name
		name, icon = opts.Name, opts.Icon
	end
	opts = opts or {}

	local tab = setmetatable({ Window = self, Name = name or "Tab", _sections = 0 }, Tab)

	local button = create("TextButton", {
		Name = tab.Name,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = #self.Tabs + 1,
		Parent = opts.Bottom and self._bottomList or self._tabList,
	})
	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(2, 22),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Visible = false,
		Parent = button,
	})
	local iconImage = Library.Icon(icon or "circle", 18, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ImageColor3 = Theme.TextDim,
		Parent = button,
	})
	tab._button, tab._bar, tab._icon = button, bar, iconImage

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			tween(iconImage, { ImageColor3 = Theme.Text })
		end
	end)
	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			tween(iconImage, { ImageColor3 = Theme.TextDim })
		end
	end)
	button.Activated:Connect(function()
		tab:Select()
	end)

	local page = create("Frame", {
		Name = tab.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.Content,
	})
	tab.Page = page

	local function column(position)
		local scroll = create("ScrollingFrame", {
			Position = position,
			Size = UDim2.new(0.5, -18, 1, -4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Border,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = page,
		})
		padding(scroll, 2, 12, 1, 1)
		list(scroll, 12)
		return scroll
	end
	tab._left = column(UDim2.fromOffset(12, 0))
	tab._right = column(UDim2.new(0.5, 6, 0, 0))

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		tab:Select()
	end
	self:_onAccent(function()
		bar.BackgroundColor3 = Theme.Accent
	end)
	return tab
end

function Window:Notify(opts)
	if type(opts) == "string" then
		opts = { Content = opts }
	end
	opts = opts or {}
	local duration = opts.Duration or 4

	local card = create("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		ZIndex = 60,
		Parent = self._notifications,
	})
	corner(card, 6)
	stroke(card, Theme.Border)
	padding(card, 10, 12, 12, 12)

	Library.Icon(opts.Icon or "bell", 16, {
		ImageColor3 = Theme.Accent,
		ZIndex = 61,
		Parent = card,
	})
	local body = create("Frame", {
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(1, -26, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 61,
		Parent = card,
	})
	list(body, 3)
	text({
		Size = UDim2.new(1, 0, 0, 16),
		Text = opts.Title or self.Name,
		Font = FONT_BOLD,
		TextSize = 13,
		ZIndex = 61,
		Parent = body,
	})
	if opts.Content then
		text({
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = opts.Content,
			TextColor3 = Theme.TextDim,
			TextWrapped = true,
			ZIndex = 61,
			LayoutOrder = 1,
			Parent = body,
		})
	end
	local progress = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, -12, 1, 12),
		Size = UDim2.new(1, 24, 0, 2),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 62,
		Parent = card,
	})
	TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
	task.delay(duration, function()
		card:Destroy()
	end)
end

function Window:SetAccent(color)
	Theme.Accent = color
	for _, fn in ipairs(self._accentHooks) do
		task.spawn(fn)
	end
end

function Window:SetToggleKey(key)
	self.ToggleKey = toKey(key)
end

function Window:SetLocked(locked)
	self._locked = locked == true
end

function Window:Toggle(visible)
	if self._loading then
		return
	end
	if visible == nil then
		visible = not self.Main.Visible
	end
	if visible then
		self.Main.Visible = true
		self._scale.Scale = 0.96
		tween(self._scale, { Scale = 1 }, 0.18)
	else
		self:_closePopups(0)
		self.Main.Visible = false
	end
	self:_setMouseFree(visible)
end

function Window:GetConfig()
	local out = {}
	for flag, el in pairs(self.Flags) do
		out[flag] = el:Serialize()
	end
	return out
end

function Window:LoadConfig(config)
	if type(config) == "string" then
		config = HttpService:JSONDecode(config)
	end
	for flag, value in pairs(config or {}) do
		local el = self.Flags[flag]
		if el then
			pcall(el.Deserialize, el, value)
		end
	end
end

-- Configs em arquivo (somente onde writefile/readfile existirem).
local function hasFileApi()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

function Window:SaveConfigFile(name)
	if not hasFileApi() then
		return false, "file api indisponivel"
	end
	if type(isfolder) == "function" and not isfolder(self.ConfigFolder) then
		makefolder(self.ConfigFolder)
	end
	writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(self:GetConfig()))
	return true
end

function Window:LoadConfigFile(name)
	local path = self.ConfigFolder .. "/" .. name .. ".json"
	if not hasFileApi() or not isfile(path) then
		return false, "config nao encontrada"
	end
	local ok, err = pcall(function()
		self:LoadConfig(readfile(path))
	end)
	return ok, err
end

function Window:DeleteConfigFile(name)
	local path = self.ConfigFolder .. "/" .. name .. ".json"
	if hasFileApi() and type(delfile) == "function" and isfile(path) then
		delfile(path)
		return true
	end
	return false
end

function Window:ListConfigFiles()
	local names = {}
	if not hasFileApi() or type(listfiles) ~= "function" or type(isfolder) ~= "function" or not isfolder(self.ConfigFolder) then
		return names
	end
	for _, path in ipairs(listfiles(self.ConfigFolder)) do
		local name = string.match(path, "([^/\\]+)%.json$")
		if name then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

function Window:OnUnload(fn)
	table.insert(self._unload, fn)
end

function Window:Destroy()
	for _, fn in ipairs(self._unload) do
		pcall(fn)
	end
	table.clear(self._unload)
	self:_setMouseFree(false)
	for _, connection in ipairs(self._conns) do
		connection:Disconnect()
	end
	table.clear(self._conns)
	for flag, el in pairs(self.Flags) do
		if Library.Flags[flag] == el then
			Library.Flags[flag] = nil
		end
	end
	local index = table.find(Library.Windows, self)
	if index then
		table.remove(Library.Windows, index)
	end
	self.Gui:Destroy()
end

Window.Unload = Window.Destroy

return Library
