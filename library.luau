--[[
	GamesenseUI
	UI library client-side no estilo gamesense/skeet.
	Use via require() a partir de um LocalScript.

	local UI = require(ReplicatedStorage.GamesenseUI)
	local window = UI:CreateWindow({ ToggleKey = Enum.KeyCode.Insert })
	local tab = window:AddTab("Misc", "sliders")
	local group = tab:AddGroup("Miscellaneous", "Left")
	group:AddToggle({ Text = "Exemplo", Flag = "exemplo", Callback = print })
	window:AddWatermark({ Text = "gamesense" })
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

local Library = {}

local Theme = {
	Accent = Color3.fromRGB(149, 76, 233),
	Background = Color3.fromRGB(23, 23, 23),
	TabBar = Color3.fromRGB(12, 12, 12),
	Border0 = Color3.fromRGB(10, 10, 10),
	Border1 = Color3.fromRGB(60, 60, 60),
	Border2 = Color3.fromRGB(40, 40, 40),
	GroupBorder = Color3.fromRGB(45, 45, 45),
	Text = Color3.fromRGB(205, 205, 205),
	TextDim = Color3.fromRGB(150, 150, 150),
	TextDisabled = Color3.fromRGB(90, 90, 90),
	Font = Enum.Font.Arial,
	FontBold = Enum.Font.ArialBold,
	TextSize = 13,
}
Library.Theme = Theme

local TAB_WIDTH = 80
local TAB_HEIGHT = 64
local BOX_X = 12
local ELEMENT_X = 33
local RIGHT_MARGIN = 35
local ELEMENT_WIDTH = UDim2.new(1, -(ELEMENT_X + RIGHT_MARGIN), 0, 0)

local SHORT_KEYS = {
	Insert = "INS", Delete = "DEL", Home = "HOME", End = "END",
	PageUp = "PGUP", PageDown = "PGDN", LeftShift = "LSHIFT", RightShift = "RSHIFT",
	LeftControl = "LCTRL", RightControl = "RCTRL", LeftAlt = "LALT", RightAlt = "RALT",
	CapsLock = "CAPS", Backspace = "BACK", Return = "ENTER", Space = "SPACE", Tab = "TAB",
	MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3",
}

-- Utilidades ---------------------------------------------------------------

local function create(className, props, children)
	local inst = Instance.new(className)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function text(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or Theme.Font
	props.TextSize = props.TextSize or Theme.TextSize
	props.TextColor3 = props.TextColor3 or Theme.Text
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	local className = props.ClassName or "TextLabel"
	props.ClassName = nil
	return create(className, props)
end

local function inset(parent, px, color)
	return create("Frame", {
		Position = UDim2.fromOffset(px, px),
		Size = UDim2.new(1, -px * 2, 1, -px * 2),
		BackgroundColor3 = color,
		Parent = parent,
	})
end

local function stroke(parent, color)
	return create("UIStroke", {
		Color = color or Theme.Border0,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function vgradient(parent, top, bottom)
	return create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(top, bottom),
		Parent = parent,
	})
end

local function shade(c, m)
	return Color3.new(math.clamp(c.R * m, 0, 1), math.clamp(c.G * m, 0, 1), math.clamp(c.B * m, 0, 1))
end

local function rainbow(m)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, shade(Color3.fromRGB(55, 177, 218), m)),
		ColorSequenceKeypoint.new(0.5, shade(Color3.fromRGB(204, 82, 198), m)),
		ColorSequenceKeypoint.new(1, shade(Color3.fromRGB(204, 227, 53), m)),
	})
end

local function inside(gui, point)
	local p, s = gui.AbsolutePosition, gui.AbsoluteSize
	return point.X >= p.X and point.X <= p.X + s.X and point.Y >= p.Y and point.Y <= p.Y + s.Y
end

local function keyName(key)
	if not key then
		return "-"
	end
	return SHORT_KEYS[key.Name] or string.upper(key.Name)
end

local function list(parent, padding, direction)
	return create("UIListLayout", {
		Padding = UDim.new(0, padding or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
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

local function draggable(inst)
	inst:SetAttribute("GSDrag", true)
	return inst
end

-- Icones geometricos proprios, desenhados na UI. Nao usa pacote externo.

local ICONS = {
	user = {
		rings = { { 12, 7.5, 3.2 } },
		lines = { { 6.5, 20, 9, 15.2 }, { 9, 15.2, 15, 15.2 }, { 15, 15.2, 17.5, 20 } },
	},
	eye = {
		rings = { { 12, 12, 5.5 } },
		dots = { { 12, 12, 2 } },
	},
	settings = {
		rings = { { 12, 12, 3.4 } },
		lines = {
			{ 12, 4, 12, 6.6 }, { 17.7, 6.3, 16.2, 8.4 }, { 20, 12, 17.4, 12 }, { 17.7, 17.7, 16.2, 15.6 },
			{ 12, 20, 12, 17.4 }, { 6.3, 17.7, 7.8, 15.6 }, { 4, 12, 6.6, 12 }, { 6.3, 6.3, 7.8, 8.4 },
		},
	},
	crosshair = {
		rings = { { 12, 12, 6.5 } },
		lines = { { 12, 2.5, 12, 6 }, { 12, 18, 12, 21.5 }, { 2.5, 12, 6, 12 }, { 18, 12, 21.5, 12 } },
	},
	sliders = {
		lines = {
			{ 4, 7, 20, 7 }, { 4, 12, 20, 12 }, { 4, 17, 20, 17 },
			{ 9, 5, 9, 9 }, { 15, 10, 15, 14 }, { 8, 15, 8, 19 },
		},
	},
	chevron = {
		lines = { { 6, 9, 12, 15 }, { 12, 15, 18, 9 } },
	},
	shield = {
		lines = { { 12, 3.5, 19, 6.5 }, { 19, 6.5, 19, 12 }, { 19, 12, 12, 20.5 }, { 12, 20.5, 5, 12 }, { 5, 12, 5, 6.5 }, { 5, 6.5, 12, 3.5 } },
	},
	target = {
		rings = { { 12, 12, 8 }, { 12, 12, 4 } },
		dots = { { 12, 12, 1.5 } },
	},
	sun = {
		rings = { { 12, 12, 3.6 } },
		lines = {
			{ 12, 3, 12, 5.6 }, { 18.4, 5.6, 16.6, 7.4 }, { 21, 12, 18.4, 12 }, { 18.4, 18.4, 16.6, 16.6 },
			{ 12, 21, 12, 18.4 }, { 5.6, 18.4, 7.4, 16.6 }, { 3, 12, 5.6, 12 }, { 5.6, 5.6, 7.4, 7.4 },
		},
	},
	box = {
		lines = { { 5, 5, 19, 5 }, { 19, 5, 19, 19 }, { 19, 19, 5, 19 }, { 5, 19, 5, 5 } },
	},
}

local ICON_ALIASES = {
	["sliders-horizontal"] = "sliders",
	["chevron-down"] = "chevron",
	cog = "settings",
	gear = "settings",
	person = "user",
}

local function iconKey(name)
	if type(name) ~= "string" then
		return nil
	end
	local key = string.lower((string.gsub(name, "[_ ]+", "-")))
	key = ICON_ALIASES[key] or key
	if ICONS[key] then
		return key
	end
	return ICONS[string.gsub(key, "%-", "")] and string.gsub(key, "%-", "") or nil
end

local function drawStroke(parent, a, b, thickness, color)
	local delta = b - a
	local len = delta.Magnitude
	if len < 0.2 then
		return nil
	end
	local line = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
		Size = UDim2.fromOffset(len, thickness),
		Rotation = math.deg(math.atan2(delta.Y, delta.X)),
		BackgroundColor3 = color,
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
	return line
end

function Library.DrawIcon(parent, name, size, color)
	local spec = ICONS[iconKey(name)]
	if not spec then
		return nil
	end
	local holder = create("Frame", {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local colored = {}
	local function paint(c)
		for _, inst in ipairs(colored) do
			if inst:IsA("UIStroke") then
				inst.Color = c
			else
				inst.BackgroundColor3 = c
			end
		end
	end
	local scale = size / 24
	local thickness = math.max(1, 2 * scale)
	local function point(x, y)
		return Vector2.new(x * scale, y * scale)
	end
	for _, seg in ipairs(spec.lines or {}) do
		local line = drawStroke(holder, point(seg[1], seg[2]), point(seg[3], seg[4]), thickness, color)
		if line then
			table.insert(colored, line)
		end
	end
	for _, ring in ipairs(spec.rings or {}) do
		local disk = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(ring[1] * scale, ring[2] * scale),
			Size = UDim2.fromOffset(ring[3] * 2 * scale, ring[3] * 2 * scale),
			BackgroundTransparency = 1,
			Parent = holder,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = disk })
		table.insert(colored, create("UIStroke", { Thickness = thickness, Color = color, Parent = disk }))
	end
	for _, dot in ipairs(spec.dots or {}) do
		local disk = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(dot[1] * scale, dot[2] * scale),
			Size = UDim2.fromOffset(dot[3] * 2 * scale, dot[3] * 2 * scale),
			BackgroundColor3 = color,
			Parent = holder,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = disk })
		table.insert(colored, disk)
	end
	return holder, paint
end


-- Element base ---------------------------------------------------------------

local Element = {}
Element.__index = Element

local function newElement(window, kind, opts)
	local el = setmetatable({
		Window = window,
		Kind = kind,
		Flag = opts.Flag,
		Callback = opts.Callback,
		_changed = {},
	}, Element)
	if el.Flag then
		window.Elements[el.Flag] = el
	end
	return el
end

function Element:Get()
	return self.Value
end

function Element:_sync()
	if self.Flag then
		self.Window.Flags[self.Flag] = self.Value
	end
end

function Element:_fire()
	self:_sync()
	if self.Callback then
		task.spawn(self.Callback, self.Value)
	end
	for _, fn in ipairs(self._changed) do
		task.spawn(fn, self.Value)
	end
end

function Element:Set(value, silent)
	self.Value = value
	if self._render then
		self._render()
	end
	if silent then
		self:_sync()
	else
		self:_fire()
	end
end

function Element:OnChanged(fn)
	table.insert(self._changed, fn)
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
end

function Element:SetText(str)
	if self._label then
		self._label.Text = str
	end
end

function Element:SetEnabled(enabled)
	self._enabled = enabled
	if self._label then
		self._label.TextColor3 = enabled and Theme.Text or Theme.TextDisabled
	end
	if self.Row then
		for _, desc in ipairs(self.Row:GetDescendants()) do
			if desc:IsA("GuiButton") then
				desc.Active = enabled
				desc.Selectable = enabled
			elseif desc:IsA("TextBox") then
				desc.TextEditable = enabled
			end
		end
	end
	return self
end

function Element:_getHolder()
	if not self._holder then
		self._holder = create("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 0),
			Size = UDim2.fromOffset(0, 14),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = self.Row,
		})
		local layout = list(self._holder, 6, Enum.FillDirection.Horizontal)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
	end
	return self._holder
end

-- Keybind (anexado a Toggle/Label) --------------------------------------------

function Element:AddKeybind(opts)
	opts = opts or {}
	local window = self.Window
	local el = newElement(window, "Keybind", opts)
	el.Value = opts.Default
	el.Row = self.Row
	el.Mode = opts.Mode or "Toggle" -- "Toggle" | "Hold"
	el.Active = false

	local listening = false
	local button = text({
		ClassName = "TextButton",
		AutoButtonColor = false,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 14),
		TextSize = 11,
		TextColor3 = Color3.fromRGB(118, 118, 118),
		Parent = self:_getHolder(),
	})

	el._render = function()
		button.Text = "[" .. (listening and "..." or keyName(el.Value)) .. "]"
		button.TextColor3 = listening and Theme.Accent or Color3.fromRGB(118, 118, 118)
	end

	local function setActive(state)
		if el.Active == state then
			return
		end
		el.Active = state
		if opts.OnStateChanged then
			task.spawn(opts.OnStateChanged, state)
		end
	end

	local function matches(input)
		local v = el.Value
		if not v then
			return false
		end
		if v.EnumType == Enum.KeyCode then
			return input.KeyCode == v
		end
		return input.UserInputType == v
	end

	button.MouseButton1Click:Connect(function()
		if listening then
			return
		end
		listening = true
		window._listening = true
		el._render()
	end)

	window:_connect(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if listening then
			local key
			local t = input.UserInputType
			if t == Enum.UserInputType.Keyboard then
				if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Backspace then
					key = input.KeyCode
				end
			elseif t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3 then
				key = t
			else
				return
			end
			listening = false
			task.defer(function()
				window._listening = false
			end)
			el:Set(key)
			return
		end
		if gameProcessed or window._listening or UserInputService:GetFocusedTextBox() then
			return
		end
		if matches(input) then
			if el.Mode == "Toggle" then
				setActive(not el.Active)
			else
				setActive(true)
			end
			if opts.OnPress then
				task.spawn(opts.OnPress)
			end
		end
	end))

	window:_connect(UserInputService.InputEnded:Connect(function(input)
		if el.Mode == "Hold" and matches(input) then
			setActive(false)
		end
	end))

	function el:Serialize()
		local v = self.Value
		if not v then
			return nil
		end
		return (v.EnumType == Enum.KeyCode and "KeyCode." or "UserInputType.") .. v.Name
	end

	function el:Deserialize(value)
		if type(value) ~= "string" then
			self:Set(nil)
			return
		end
		local enumName, itemName = string.match(value, "^(%w+)%.(%w+)$")
		local ok, item = pcall(function()
			return Enum[enumName][itemName]
		end)
		self:Set(ok and item or nil)
	end

	el._render()
	el:_sync()
	return el
end

-- ColorPicker (anexado a Toggle/Label) ----------------------------------------

function Element:AddColorPicker(opts)
	opts = opts or {}
	local window = self.Window
	local el = newElement(window, "ColorPicker", opts)
	el.Value = opts.Default or Theme.Accent
	el.Row = self.Row

	local h, s, v = el.Value:ToHSV()

	local swatch = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(18, 9),
		BackgroundColor3 = el.Value,
		Parent = self:_getHolder(),
	})
	stroke(swatch)
	vgradient(swatch, Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190))

	local popup = create("Frame", {
		Size = UDim2.fromOffset(184, 162),
		BackgroundColor3 = Theme.GroupBorder,
		Visible = false,
		ZIndex = 20,
		Parent = window.Gui,
	})
	stroke(popup)
	local body = inset(popup, 1, Theme.Background)

	local sv = create("Frame", {
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.fromOffset(148, 148),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		Parent = body,
	})
	stroke(sv)
	local white = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 1,
		Parent = sv,
	})
	create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
	local black = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		ZIndex = 2,
		Parent = sv,
	})
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
	local svCursor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = sv,
	})
	stroke(svCursor)
	local svHit = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
		Parent = sv,
	})

	local hueKeys = {}
	for i = 0, 6 do
		table.insert(hueKeys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
	end
	local hue = create("Frame", {
		Position = UDim2.fromOffset(162, 6),
		Size = UDim2.fromOffset(12, 148),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = body,
	})
	stroke(hue)
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(hueKeys), Parent = hue })
	local hueCursor = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = hue,
	})
	stroke(hueCursor)
	local hueHit = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 4,
		Parent = hue,
	})

	local function render()
		swatch.BackgroundColor3 = el.Value
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCursor.Position = UDim2.fromScale(s, 1 - v)
		hueCursor.Position = UDim2.fromScale(0, h)
	end
	el._render = render

	local function commit()
		el.Value = Color3.fromHSV(h, s, v)
		render()
		el:_fire()
	end

	svHit.MouseButton1Down:Connect(function()
		window:_beginDrag(function(m)
			s = math.clamp((m.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
			v = 1 - math.clamp((m.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
			commit()
		end)
	end)

	hueHit.MouseButton1Down:Connect(function()
		window:_beginDrag(function(m)
			h = math.clamp((m.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 0.999)
			commit()
		end)
	end)

	swatch.MouseButton1Click:Connect(function()
		if el._enabled == false then
			return
		end
		if window._popup and window._popup.Frame == popup then
			window:_closePopup()
			return
		end
		window:_openPopup(popup, swatch, function()
			local p, sz = swatch.AbsolutePosition, swatch.AbsoluteSize
			return UDim2.fromOffset(p.X + sz.X - popup.AbsoluteSize.X, p.Y + sz.Y + 4)
		end)
	end)

	function el:Set(color, silent)
		h, s, v = color:ToHSV()
		Element.Set(self, color, silent)
	end

	function el:Serialize()
		return self.Value:ToHex()
	end

	function el:Deserialize(value)
		if type(value) == "string" then
			self:Set(Color3.fromHex(value))
		end
	end

	render()
	el:_sync()
	return el
end

-- Group -----------------------------------------------------------------------

local Group = {}
Group.__index = Group

function Group:_row(height)
	self._order += 1
	return create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = self._order,
		Parent = self.Content,
	})
end

function Group:_label(row, str, y)
	return text({
		Text = str,
		Position = UDim2.fromOffset(ELEMENT_X, y or 0),
		Size = UDim2.new(1, -ELEMENT_X, 0, 14),
		Parent = row,
	})
end

function Group:AddLabel(opts)
	if type(opts) == "string" then
		opts = { Text = opts }
	end
	local el = newElement(self.Window, "Label", opts)
	el.Row = self:_row(14)
	el._label = self:_label(el.Row, opts.Text or "")
	return el
end

function Group:AddToggle(opts)
	opts = opts or {}
	local window = self.Window
	local el = newElement(window, "Toggle", opts)
	el.Value = opts.Default == true

	local row = self:_row(14)
	el.Row = row

	local box = create("Frame", {
		Position = UDim2.fromOffset(BOX_X, 3),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = row,
	})
	stroke(box)
	local gradient = vgradient(box, Color3.new(), Color3.new())
	el._label = self:_label(row, opts.Text or "Toggle")

	local hit = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		Parent = row,
	})

	local hovered = false
	el._render = function()
		if el.Value then
			gradient.Color = ColorSequence.new(Theme.Accent, shade(Theme.Accent, 0.65))
		elseif hovered then
			gradient.Color = ColorSequence.new(Color3.fromRGB(95, 95, 95), Color3.fromRGB(70, 70, 70))
		else
			gradient.Color = ColorSequence.new(Color3.fromRGB(77, 77, 77), Color3.fromRGB(51, 51, 51))
		end
	end
	window:_onAccent(el._render)

	hit.MouseEnter:Connect(function()
		hovered = true
		el._render()
	end)
	hit.MouseLeave:Connect(function()
		hovered = false
		el._render()
	end)
	hit.MouseButton1Click:Connect(function()
		if el._enabled == false then
			return
		end
		el:Set(not el.Value)
	end)

	el:_sync()
	return el
end

function Group:AddSlider(opts)
	opts = opts or {}
	local window = self.Window
	local el = newElement(window, "Slider", opts)
	local min, max = opts.Min or 0, opts.Max or 100
	local decimals = opts.Decimals or 0
	local suffix = opts.Suffix or ""
	local step = 10 ^ -decimals

	local function round(n)
		return math.clamp(math.floor(n / step + 0.5) * step, min, max)
	end
	el.Value = round(opts.Default or min)

	local hasText = opts.Text ~= nil
	local row = self:_row(hasText and 28 or 13)
	el.Row = row
	if hasText then
		el._label = self:_label(row, opts.Text)
	end

	local bar = create("Frame", {
		Position = UDim2.fromOffset(ELEMENT_X, hasText and 16 or 2),
		Size = ELEMENT_WIDTH + UDim2.fromOffset(0, 7),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = row,
	})
	stroke(bar)
	vgradient(bar, Color3.fromRGB(52, 52, 52), Color3.fromRGB(68, 68, 68))

	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = bar,
	})
	local fillGradient = vgradient(fill, Color3.new(), Color3.new())

	local valueText = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(0, 12),
		AutomaticSize = Enum.AutomaticSize.X,
		Font = Theme.FontBold,
		TextSize = 12,
		TextStrokeTransparency = 0.4,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
		Parent = bar,
	})

	local hit = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, -4),
		Size = UDim2.new(1, 0, 1, 8),
		ZIndex = 4,
		Parent = bar,
	})

	el._render = function()
		local pct = (max == min) and 0 or (el.Value - min) / (max - min)
		fill.Size = UDim2.fromScale(pct, 1)
		fillGradient.Color = ColorSequence.new(Theme.Accent, shade(Theme.Accent, 0.6))
		valueText.Position = UDim2.new(pct, 0, 1, 1)
		valueText.Text = string.format("%." .. decimals .. "f", el.Value) .. suffix
	end
	window:_onAccent(el._render)

	hit.MouseButton1Down:Connect(function()
		if el._enabled == false then
			return
		end
		window:_beginDrag(function(m)
			local pct = math.clamp((m.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local value = round(min + (max - min) * pct)
			if value ~= el.Value then
				el:Set(value)
			end
		end)
	end)

	function el:Set(value, silent)
		Element.Set(self, round(tonumber(value) or min), silent)
	end

	el:_sync()
	return el
end

local function makeBox(row, y)
	local box = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Position = UDim2.fromOffset(ELEMENT_X, y),
		Size = ELEMENT_WIDTH + UDim2.fromOffset(0, 20),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = row,
	})
	stroke(box)
	local gradient = vgradient(box, Color3.fromRGB(36, 36, 36), Color3.fromRGB(31, 31, 31))
	box.MouseEnter:Connect(function()
		gradient.Color = ColorSequence.new(Color3.fromRGB(42, 42, 42), Color3.fromRGB(36, 36, 36))
	end)
	box.MouseLeave:Connect(function()
		gradient.Color = ColorSequence.new(Color3.fromRGB(36, 36, 36), Color3.fromRGB(31, 31, 31))
	end)
	return box
end

function Group:AddDropdown(opts)
	opts = opts or {}
	local window = self.Window
	local el = newElement(window, "Dropdown", opts)
	el.Values = opts.Values or {}
	el.Multi = opts.Multi == true

	local function normalize(value)
		if el.Multi then
			local map = {}
			if type(value) == "table" then
				for k, v in pairs(value) do
					if type(k) == "number" then
						map[v] = true
					elseif v then
						map[k] = true
					end
				end
			end
			return map
		end
		return value
	end
	el.Value = normalize(opts.Default or (not el.Multi and el.Values[1]) or nil)

	local hasText = opts.Text ~= nil
	local row = self:_row(hasText and 36 or 21)
	el.Row = row
	if hasText then
		el._label = self:_label(row, opts.Text)
	end

	local box = makeBox(row, hasText and 15 or 0)
	local valueText = text({
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -28, 1, 0),
		TextColor3 = Theme.TextDim,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = box,
	})
	local chevron = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Parent = box,
	})
	Library.DrawIcon(chevron, "chevron-down", 12, Theme.TextDim)

	local popup = create("ScrollingFrame", {
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		ZIndex = 20,
		Parent = window.Gui,
	})
	stroke(popup)
	list(popup)

	local items = {}

	local function isSelected(value)
		if el.Multi then
			return el.Value[value] == true
		end
		return el.Value == value
	end

	local function display()
		if el.Multi then
			local parts = {}
			for _, v in ipairs(el.Values) do
				if el.Value[v] then
					table.insert(parts, tostring(v))
				end
			end
			return #parts > 0 and table.concat(parts, ", ") or "-"
		end
		return el.Value ~= nil and tostring(el.Value) or "-"
	end

	el._render = function()
		valueText.Text = display()
		popup.ScrollBarImageColor3 = Theme.Accent
		for value, item in pairs(items) do
			local selected = isSelected(value)
			item.Label.TextColor3 = selected and Theme.Accent or Theme.Text
			item.Label.Font = selected and Theme.FontBold or Theme.Font
		end
	end
	window:_onAccent(el._render)

	local function build()
		for _, item in pairs(items) do
			item.Button:Destroy()
		end
		table.clear(items)
		for i, value in ipairs(el.Values) do
			local button = create("TextButton", {
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = Color3.fromRGB(35, 35, 35),
				Parent = popup,
			})
			local label = text({
				Text = tostring(value),
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -10, 1, 0),
				Parent = button,
			})
			button.MouseEnter:Connect(function()
				button.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
			end)
			button.MouseLeave:Connect(function()
				button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			end)
			button.MouseButton1Click:Connect(function()
				if el.Multi then
					local map = table.clone(el.Value)
					map[value] = not map[value] or nil
					el:Set(map)
				else
					el:Set(value)
					window:_closePopup()
				end
			end)
			items[value] = { Button = button, Label = label }
		end
		el._render()
	end

	box.MouseButton1Click:Connect(function()
		if el._enabled == false then
			return
		end
		if window._popup and window._popup.Frame == popup then
			window:_closePopup()
			return
		end
		window:_openPopup(popup, box, function()
			local p, sz = box.AbsolutePosition, box.AbsoluteSize
			popup.Size = UDim2.fromOffset(sz.X, math.min(#el.Values, 8) * 20)
			return UDim2.fromOffset(p.X, p.Y + sz.Y + 1)
		end)
	end)

	function el:Set(value, silent)
		Element.Set(self, normalize(value), silent)
	end

	function el:Refresh(values, keepValue)
		self.Values = values
		if not keepValue then
			self.Value = normalize(self.Multi and {} or values[1])
		end
		build()
		self:_fire()
	end

	function el:Serialize()
		if self.Multi then
			local out = {}
			for _, v in ipairs(self.Values) do
				if self.Value[v] then
					table.insert(out, v)
				end
			end
			return out
		end
		return self.Value
	end

	build()
	el:_sync()
	return el
end

function Group:AddButton(opts)
	opts = opts or {}
	local el = newElement(self.Window, "Button", opts)
	local row = self:_row(25)
	el.Row = row

	local outer = create("Frame", {
		Position = UDim2.fromOffset(ELEMENT_X, 0),
		Size = ELEMENT_WIDTH + UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Border0,
		Parent = row,
	})
	local mid = inset(outer, 1, Color3.fromRGB(50, 50, 50))
	local button = text({
		ClassName = "TextButton",
		AutoButtonColor = false,
		Text = opts.Text or "Button",
		Font = Theme.FontBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		Parent = mid,
	})
	el._label = button
	local gradient = vgradient(button, Color3.fromRGB(35, 35, 35), Color3.fromRGB(25, 25, 25))

	local hovered = false
	button.MouseEnter:Connect(function()
		hovered = true
		gradient.Color = ColorSequence.new(Color3.fromRGB(42, 42, 42), Color3.fromRGB(30, 30, 30))
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		gradient.Color = ColorSequence.new(Color3.fromRGB(35, 35, 35), Color3.fromRGB(25, 25, 25))
	end)
	button.MouseButton1Down:Connect(function()
		gradient.Color = ColorSequence.new(Color3.fromRGB(25, 25, 25), Color3.fromRGB(35, 35, 35))
	end)
	button.MouseButton1Up:Connect(function()
		gradient.Color = hovered and ColorSequence.new(Color3.fromRGB(42, 42, 42), Color3.fromRGB(30, 30, 30))
			or ColorSequence.new(Color3.fromRGB(35, 35, 35), Color3.fromRGB(25, 25, 25))
	end)
	button.MouseButton1Click:Connect(function()
		if el.Callback then
			task.spawn(el.Callback)
		end
	end)

	return el
end

function Group:AddTextbox(opts)
	opts = opts or {}
	local el = newElement(self.Window, "Textbox", opts)
	el.Value = opts.Default or ""

	local hasText = opts.Text ~= nil
	local row = self:_row(hasText and 36 or 21)
	el.Row = row
	if hasText then
		el._label = self:_label(row, opts.Text)
	end

	local box = makeBox(row, hasText and 15 or 0)
	local input = text({
		ClassName = "TextBox",
		Text = el.Value,
		PlaceholderText = opts.Placeholder or "",
		PlaceholderColor3 = Theme.TextDisabled,
		ClearTextOnFocus = false,
		TextColor3 = Theme.TextDim,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Parent = box,
	})
	box.MouseButton1Click:Connect(function()
		input:CaptureFocus()
	end)

	el._render = function()
		input.Text = el.Value
	end
	input.FocusLost:Connect(function(enterPressed)
		if opts.Finished and not enterPressed then
			input.Text = el.Value
			return
		end
		el:Set(input.Text)
	end)

	el:_sync()
	return el
end

function Group:AddListbox(opts)
	opts = opts or {}
	local window = self.Window
	local el = newElement(window, "Listbox", opts)
	el.Values = opts.Values or {}
	el.Value = opts.Default

	local row = self:_row(opts.Height or 95)
	el.Row = row

	local frame = create("ScrollingFrame", {
		Position = UDim2.fromOffset(ELEMENT_X, 0),
		Size = ELEMENT_WIDTH + UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = row,
	})
	stroke(frame)
	list(frame)
	padding(frame, 3, 3, 0, 0)

	local items = {}

	el._render = function()
		frame.ScrollBarImageColor3 = Theme.Accent
		for value, label in pairs(items) do
			label.TextColor3 = (el.Value == value) and Theme.Accent or Theme.TextDim
		end
	end
	window:_onAccent(el._render)

	local function build()
		for _, label in pairs(items) do
			label:Destroy()
		end
		table.clear(items)
		for i, value in ipairs(el.Values) do
			local label = text({
				ClassName = "TextButton",
				AutoButtonColor = false,
				Text = "   " .. tostring(value),
				LayoutOrder = i,
				Size = UDim2.new(1, 0, 0, 15),
				TextSize = 12,
				Parent = frame,
			})
			label.MouseButton1Click:Connect(function()
				el:Set(value)
			end)
			items[value] = label
		end
		el._render()
	end

	function el:Refresh(values)
		self.Values = values
		if not table.find(values, self.Value) then
			self.Value = nil
		end
		build()
		self:_fire()
	end

	build()
	el:_sync()
	return el
end

-- Tab -------------------------------------------------------------------------

local Tab = {}
Tab.__index = Tab

function Tab:AddGroup(name, side)
	local column = (side == "Right") and self.Right or self.Left
	self._order += 1

	local outer = draggable(create("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Border0,
		LayoutOrder = self._order,
		Parent = column,
	}))
	padding(outer, 1, 1, 1, 1)
	local mid = draggable(create("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.GroupBorder,
		Parent = outer,
	}))
	padding(mid, 1, 1, 1, 1)
	local content = draggable(create("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background,
		Parent = mid,
	}))
	padding(content, 14, 10, 0, 0)
	list(content, 5)

	local title = text({
		Text = name,
		Font = Theme.FontBold,
		TextSize = 12,
		Position = UDim2.fromOffset(10, -8),
		Size = UDim2.fromOffset(0, 14),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Background,
		ZIndex = 5,
		Parent = outer,
	})
	padding(title, 0, 0, 3, 3)

	return setmetatable({
		Window = self.Window,
		Tab = self,
		Frame = outer,
		Content = content,
		Title = title,
		_order = 0,
	}, Group)
end

function Tab:Select()
	local window = self.Window
	for _, tab in ipairs(window.Tabs) do
		local selected = tab == self
		tab.Page.Visible = selected
		tab.Button.BackgroundTransparency = selected and 0 or 1
		tab.TopLine.Visible = selected
		tab.BottomLine.Visible = selected
		tab._setIconColor(selected and Theme.Text or Color3.fromRGB(90, 90, 90))
	end
	window.ActiveTab = self
	window:_closePopup()
end

-- Window ----------------------------------------------------------------------

local Window = {}
Window.__index = Window

function Library:CreateWindow(opts)
	opts = opts or {}
	if opts.Accent then
		Theme.Accent = opts.Accent
	end

	local self = setmetatable({
		Flags = {},
		Elements = {},
		Tabs = {},
		ToggleKey = opts.ToggleKey or Enum.KeyCode.Insert,
		Locked = false,
		_accentHooks = {},
		_connections = {},
		_unloadHooks = {},
	}, Window)

	local size = opts.Size or Vector2.new(660, 565)

	local gui = create("ScreenGui", {
		Name = opts.Name or "GamesenseUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000,
		Parent = opts.Parent or LocalPlayer:WaitForChild("PlayerGui"),
	})
	self.Gui = gui

	local main = draggable(create("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.new(0.5, -size.X / 2, 0.5, -size.Y / 2),
		BackgroundColor3 = Theme.Border0,
		Parent = gui,
	}))
	self.Main = main

	local b1 = draggable(inset(main, 1, Theme.Border1))
	local b2 = draggable(inset(b1, 1, Theme.Border2))
	local b3 = draggable(inset(b2, 3, Theme.Border1))
	local inner = draggable(inset(b3, 1, Theme.Background))

	local line = create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = inner,
	})
	create("UIGradient", { Color = rainbow(1), Parent = line })
	local lineDim = create("Frame", {
		Position = UDim2.fromOffset(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = inner,
	})
	create("UIGradient", { Color = rainbow(0.5), Parent = lineDim })

	local tabBar = draggable(create("Frame", {
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(0, TAB_WIDTH, 1, -2),
		BackgroundColor3 = Theme.TabBar,
		Parent = inner,
	}))
	create("Frame", {
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.GroupBorder,
		ZIndex = 1,
		Parent = tabBar,
	})
	local tabList = draggable(create("Frame", {
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, 0, 1, -18),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = tabBar,
	}))
	list(tabList)
	self.TabList = tabList

	local content = draggable(create("Frame", {
		Position = UDim2.fromOffset(TAB_WIDTH, 2),
		Size = UDim2.new(1, -TAB_WIDTH, 1, -2),
		BackgroundTransparency = 1,
		Parent = inner,
	}))
	self.Content = content

	self:_connect(UserInputService.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.MouseButton2 then
			local popup = self._popup
			if popup then
				local m = UserInputService:GetMouseLocation()
				if not inside(popup.Frame, m) and not inside(popup.Anchor, m) then
					self:_closePopup()
				end
			end
		end

		if t == Enum.UserInputType.MouseButton1 and not self.Locked and not self._dragFn then
			local objects = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
			local top = objects[1]
			local wm = self._watermark
			local onWatermark = false
			local cursor = top
			while cursor and cursor ~= self.Gui do
				if cursor:GetAttribute("GSWatermark") then
					onWatermark = true
					break
				end
				cursor = cursor.Parent
			end
			if wm and wm.Frame.Visible and onWatermark then
				local startMouse = UserInputService:GetMouseLocation()
				local startPos = wm.Frame.Position
				self:_beginDrag(function(m)
					local delta = m - startMouse
					wm.Frame.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					)
				end)
			elseif main.Visible and top and top:GetAttribute("GSDrag") and (top == main or top:IsDescendantOf(main)) then
				local startMouse = UserInputService:GetMouseLocation()
				local startPos = main.Position
				self:_closePopup()
				self:_beginDrag(function(m)
					local delta = m - startMouse
					main.Position = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y
					)
				end)
			end
		end

		if t == Enum.UserInputType.Keyboard and input.KeyCode == self.ToggleKey
			and not self._listening and not UserInputService:GetFocusedTextBox() then
			self:Toggle()
		end
	end))

	self:_connect(UserInputService.InputChanged:Connect(function(input)
		if self._dragFn and input.UserInputType == Enum.UserInputType.MouseMovement then
			self._dragFn(UserInputService:GetMouseLocation())
		end
	end))

	self:_connect(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self._dragFn = nil
		end
	end))

	self._fpsAcc = 0
	self._fpsFrames = 0
	self._fps = 0
	self:_connect(RunService.RenderStepped:Connect(function(dt)
		local popup = self._popup
		if popup then
			popup.Frame.Position = popup.Place()
		end
		self._fpsAcc += dt
		self._fpsFrames += 1
		if self._fpsAcc >= 0.25 then
			self._fps = math.floor(self._fpsFrames / self._fpsAcc + 0.5)
			self._fpsAcc = 0
			self._fpsFrames = 0
			if self._watermark then
				self._watermark:_refresh()
			end
		end
	end))

	return self
end

function Window:_connect(connection)
	table.insert(self._connections, connection)
	return connection
end

function Window:_onAccent(fn)
	table.insert(self._accentHooks, fn)
	fn(Theme.Accent)
end

function Window:_beginDrag(fn)
	self._dragFn = fn
	fn(UserInputService:GetMouseLocation())
end

function Window:_openPopup(frame, anchor, place)
	self:_closePopup()
	self._popup = { Frame = frame, Anchor = anchor, Place = place }
	frame.Position = place()
	frame.Visible = true
end

function Window:_closePopup()
	local popup = self._popup
	if popup then
		self._popup = nil
		popup.Frame.Visible = false
	end
end

function Window:AddTab(name, icon)
	local tab = setmetatable({ Window = self, Name = name, _order = 0 }, Tab)

	local button = create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 1,
		LayoutOrder = #self.Tabs + 1,
		Parent = self.TabList,
	})
	tab.Button = button
	tab.TopLine = create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.GroupBorder,
		Visible = false,
		Parent = button,
	})
	tab.BottomLine = create("Frame", {
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.GroupBorder,
		Visible = false,
		Parent = button,
	})

	icon = icon or string.sub(name, 1, 1)
	local _, setIconColor = Library.DrawIcon(button, icon, 28, Color3.fromRGB(90, 90, 90))
	if setIconColor then
		tab._setIconColor = setIconColor
	elseif type(icon) == "string" and string.find(icon, "rbxasset", 1, true) then
		local iconObj = create("ImageLabel", {
			Image = icon,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(40, 40),
			BackgroundTransparency = 1,
			Parent = button,
		})
		tab._setIconColor = function(c)
			iconObj.ImageColor3 = c
		end
	else
		local glyph = (type(icon) == "string" and #icon <= 2) and icon or string.sub(name, 1, 1)
		local iconObj = text({
			Text = glyph,
			Font = Enum.Font.GothamBold,
			TextSize = 26,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Parent = button,
		})
		tab._setIconColor = function(c)
			iconObj.TextColor3 = c
		end
	end
	tab._setIconColor(Color3.fromRGB(90, 90, 90))

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			tab._setIconColor(Color3.fromRGB(140, 140, 140))
		end
	end)
	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			tab._setIconColor(Color3.fromRGB(90, 90, 90))
		end
	end)
	button.MouseButton1Click:Connect(function()
		tab:Select()
	end)

	local page = draggable(create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.Content,
	}))
	tab.Page = page

	local function column(position)
		local col = draggable(create("ScrollingFrame", {
			Position = position,
			Size = UDim2.new(0.5, -30, 1, -30),
			BackgroundTransparency = 1,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Parent = page,
		}))
		padding(col, 8, 8, 1, 1)
		list(col, 18)
		return col
	end
	tab.Left = column(UDim2.fromOffset(20, 15))
	tab.Right = column(UDim2.new(0.5, 10, 0, 15))

	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then
		tab:Select()
	end
	return tab
end

function Window:AddWatermark(opts)
	opts = opts or {}
	if self._watermark then
		self._watermark.Frame:Destroy()
		self._watermark = nil
	end

	local inset = GuiService:GetGuiInset()
	local bar = create("Frame", {
		Name = "Watermark",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = opts.Position or UDim2.new(0.5, 0, 0, inset.Y + 8),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Border0,
		Parent = self.Gui,
	})
	bar:SetAttribute("GSWatermark", true)
	padding(bar, 1, 1, 1, 1)
	local inner = create("Frame", {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		BackgroundColor3 = Theme.TabBar,
		Parent = bar,
	})
	local line = create("Frame", {
		Size = UDim2.fromOffset(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = inner,
	})
	create("UIGradient", { Color = rainbow(1), Parent = line })

	local row = create("Frame", {
		Position = UDim2.fromOffset(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		BackgroundTransparency = 1,
		Parent = inner,
	})
	local layout = list(row, 0, Enum.FillDirection.Horizontal)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local function spacer(width, order)
		create("Frame", {
			LayoutOrder = order,
			Size = UDim2.fromOffset(width, 1),
			BackgroundTransparency = 1,
			Parent = row,
		})
	end
	spacer(8, 1)

	local iconName = opts.Icon or "crosshair"
	local iconHolder = create("Frame", {
		LayoutOrder = 2,
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = row,
	})
	local _, paintIcon = Library.DrawIcon(iconHolder, iconName, 14, Theme.Accent)
	if paintIcon then
		iconHolder.Visible = true
		spacer(6, 3)
	end

	local brand = text({
		Text = opts.Text or "gamesense",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Theme.Accent,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 16),
		LayoutOrder = 4,
		Parent = row,
	})
	local info = text({
		Text = "",
		RichText = true,
		TextSize = 12,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 16),
		LayoutOrder = 5,
		Parent = row,
	})
	spacer(8, 6)
	row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		line.Size = UDim2.fromOffset(row.AbsoluteSize.X, 1)
	end)

	local wm = {
		Frame = bar,
		Window = self,
		ShowPlayer = opts.ShowPlayer ~= false,
		ShowFPS = opts.ShowFPS ~= false,
		ShowPing = opts.ShowPing ~= false,
		ShowClock = opts.ShowClock ~= false,
	}

	local function escape(s)
		return (string.gsub(string.gsub(string.gsub(s, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
	end

	function wm:SetText(str)
		brand.Text = str
	end

	function wm:SetVisible(visible)
		bar.Visible = visible
	end

	function wm:_refresh()
		local parts = {}
		if self.ShowPlayer then
			local who = LocalPlayer.DisplayName
			if who == "" then
				who = LocalPlayer.Name
			end
			table.insert(parts, escape(who))
		end
		if self.ShowFPS then
			table.insert(parts, tostring(self.Window._fps) .. " fps")
		end
		if self.ShowPing then
			local ok, seconds = pcall(function()
				return LocalPlayer:GetNetworkPing()
			end)
			if ok and type(seconds) == "number" then
				table.insert(parts, tostring(math.floor(seconds * 1000 + 0.5)) .. " ms")
			end
		end
		if self.ShowClock then
			table.insert(parts, os.date("%H:%M:%S"))
		end
		if #parts == 0 then
			info.Text = ""
		else
			info.Text = '  <font color="#5A5A5A">|</font>  ' .. table.concat(parts, '  <font color="#5A5A5A">|</font>  ')
		end
	end

	self:_onAccent(function(c)
		brand.TextColor3 = c
		if paintIcon then
			paintIcon(c)
		end
	end)

	self._watermark = wm
	wm:_refresh()
	return wm
end

function Window:SetAccent(color)
	Theme.Accent = color
	for _, fn in ipairs(self._accentHooks) do
		fn(color)
	end
end

function Window:SetToggleKey(key)
	self.ToggleKey = key
end

function Window:SetLocked(locked)
	self.Locked = locked
end

function Window:Toggle(visible)
	if visible == nil then
		visible = not self.Main.Visible
	end
	self.Main.Visible = visible
	if not visible then
		self:_closePopup()
	end
end

function Window:GetConfig()
	local config = {}
	for flag, el in pairs(self.Elements) do
		if el.Kind ~= "Button" and el.Kind ~= "Label" then
			config[flag] = el:Serialize()
		end
	end
	return config
end

function Window:LoadConfig(config)
	for flag, value in pairs(config) do
		local el = self.Elements[flag]
		if el then
			el:Deserialize(value)
		end
	end
end

function Window:OnUnload(fn)
	table.insert(self._unloadHooks, fn)
end

function Window:Destroy()
	if self.Unloaded then
		return
	end
	self.Unloaded = true
	self:_closePopup()
	self._dragFn = nil
	for _, fn in ipairs(self._unloadHooks) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[GamesenseUI] OnUnload:", err)
		end
	end
	table.clear(self._unloadHooks)
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	self.Gui:Destroy()
end

Window.Unload = Window.Destroy

return Library
