local HttpService = game:GetService("HttpService")

local UI = loadstring(game:HttpGet("COLE_A_URL_RAW_DA_LIBRARY"))()
local ScreenOverlay = (function()
-- Desenho local no centro da tela. Não lê outros personagens.

local ScreenOverlay = {}
ScreenOverlay.__index = ScreenOverlay

function ScreenOverlay.new(parent)
	local self = setmetatable({}, ScreenOverlay)

	self._crosshair = {}
	for i = 1, 4 do
		local part = Instance.new("Frame")
		part.Name = "Crosshair"
		part.AnchorPoint = Vector2.new(0.5, 0.5)
		part.BorderSizePixel = 0
		part.Visible = false
		part.ZIndex = 20
		part.Parent = parent
		self._crosshair[i] = part
	end

	local circle = Instance.new("Frame")
	circle.Name = "FovCircle"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromScale(0.5, 0.5)
	circle.BackgroundTransparency = 1
	circle.BorderSizePixel = 0
	circle.Visible = false
	circle.ZIndex = 19
	circle.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = circle

	self._circle = circle
	self._stroke = stroke
	return self
end

local function opacityToTransparency(opacity)
	return 1 - math.clamp((tonumber(opacity) or 100) / 100, 0, 1)
end

function ScreenOverlay:SetCrosshair(opts)
	opts = opts or {}
	local enabled = opts.Enabled == true
	local color = opts.Color or Color3.new(1, 1, 1)
	local length = tonumber(opts.Length) or 8
	local gap = tonumber(opts.Gap) or 4
	local thickness = math.max(1, tonumber(opts.Thickness) or 1)
	local transparency = opacityToTransparency(opts.Opacity)
	local offset = gap + length / 2

	local layout = {
		{ UDim2.fromOffset(length, thickness), UDim2.new(0.5, -offset, 0.5, 0) },
		{ UDim2.fromOffset(length, thickness), UDim2.new(0.5, offset, 0.5, 0) },
		{ UDim2.fromOffset(thickness, length), UDim2.new(0.5, 0, 0.5, -offset) },
		{ UDim2.fromOffset(thickness, length), UDim2.new(0.5, 0, 0.5, offset) },
	}
	for i, part in ipairs(self._crosshair) do
		part.Visible = enabled
		part.BackgroundColor3 = color
		part.BackgroundTransparency = transparency
		part.Size = layout[i][1]
		part.Position = layout[i][2]
	end
end

function ScreenOverlay:SetFov(opts)
	opts = opts or {}
	local radius = math.max(4, tonumber(opts.Radius) or 90)
	self._circle.Visible = opts.Enabled == true
	self._circle.Size = UDim2.fromOffset(radius * 2, radius * 2)
	self._stroke.Thickness = math.max(1, tonumber(opts.Thickness) or 1)
	self._stroke.Color = opts.Color or Color3.new(1, 1, 1)
	self._stroke.Transparency = opacityToTransparency(opts.Opacity)
end

return ScreenOverlay

end)()

if shared.GamesenseWindow then
	shared.GamesenseWindow:Destroy()
end

local window = UI:CreateWindow({
	Name = "GamesenseUI",
	ToggleKey = Enum.KeyCode.Insert,
	Accent = Color3.fromRGB(149, 76, 233),
})
shared.GamesenseWindow = window

-- Ícones da library: user, eye, settings, crosshair, sliders, chevron, shield, target, sun, box.
local playerTab = window:AddTab("Player", "user")
local visualsTab = window:AddTab("Visuals", "eye")
local settingsTab = window:AddTab("Settings", "settings")

local watermark = window:AddWatermark({
	Text = "gamesense",
	Icon = "crosshair",
})

-- Player ------------------------------------------------------------------------
local movement = playerTab:AddGroup("Movement", "Left")

movement:AddToggle({ Text = "Sprint", Flag = "sprint", Default = true })
	:AddKeybind({ Default = Enum.KeyCode.LeftShift, Mode = "Hold", Flag = "sprintKey" })

movement:AddSlider({ Text = "Walk speed", Flag = "walkSpeed", Min = 8, Max = 32, Default = 16 })
movement:AddSlider({ Text = "Camera smoothing", Flag = "smoothing", Min = 0, Max = 100, Default = 5, Suffix = "%" })

movement:AddDropdown({
	Text = "Camera mode",
	Flag = "cameraMode",
	Values = { "Classic", "Follow", "Orbital" },
	Default = "Classic",
})

movement:AddDropdown({
	Text = "Notifications",
	Flag = "notifications",
	Multi = true,
	Values = { "Chat", "Kills", "Purchases", "Friends" },
	Default = { "Chat", "Friends" },
})

local hud = playerTab:AddGroup("HUD", "Right")
hud:AddToggle({ Text = "Show FPS", Flag = "showFps", Default = true })
hud:AddToggle({ Text = "Show ping", Flag = "showPing" })
hud:AddTextbox({ Text = "Display name", Placeholder = "digite aqui...", Flag = "displayName" })

-- Visuals -----------------------------------------------------------------------
local overlay = ScreenOverlay.new(window.Gui)

local function lock(el)
	el:SetEnabled(false)
	return el
end

local function lockColor(group, text, color)
	local row = group:AddLabel(text)
	local picker = row:AddColorPicker({ Default = color })
	row:SetEnabled(false)
	picker:SetEnabled(false)
end

local function unavailable(group)
	lock(group:AddLabel("Unavailable in this environment."))
end

local aim = visualsTab:AddGroup("FOV & crosshair", "Left")

local fovToggle = aim:AddToggle({ Text = "Enable FOV circle", Flag = "fovCircle" })
local fovRadius = aim:AddSlider({
	Text = "FOV radius",
	Flag = "fovRadius",
	Min = 20,
	Max = 300,
	Default = 90,
})
local fovThickness = aim:AddSlider({
	Text = "FOV thickness",
	Flag = "fovThickness",
	Min = 1,
	Max = 4,
	Default = 1,
})
local fovColor = aim:AddLabel("FOV color"):AddColorPicker({
	Default = Color3.fromRGB(255, 255, 255),
	Flag = "fovColor",
})
local fovAlpha = aim:AddSlider({
	Text = "FOV opacity",
	Flag = "fovAlpha",
	Min = 0,
	Max = 100,
	Default = 100,
	Suffix = "%",
})

local crosshairToggle = aim:AddToggle({ Text = "Enable crosshair", Flag = "crosshair" })
local crosshairColor = crosshairToggle:AddColorPicker({
	Default = Color3.fromRGB(255, 255, 255),
	Flag = "crosshairColor",
})
local crosshairLength = aim:AddSlider({
	Text = "Crosshair length",
	Flag = "crosshairLength",
	Min = 2,
	Max = 20,
	Default = 8,
})
local crosshairGap = aim:AddSlider({
	Text = "Crosshair gap",
	Flag = "crosshairGap",
	Min = 0,
	Max = 16,
	Default = 4,
})
local crosshairThickness = aim:AddSlider({
	Text = "Crosshair thickness",
	Flag = "crosshairThickness",
	Min = 1,
	Max = 4,
	Default = 1,
})
local crosshairAlpha = aim:AddSlider({
	Text = "Crosshair opacity",
	Flag = "crosshairAlpha",
	Min = 0,
	Max = 100,
	Default = 100,
	Suffix = "%",
})

local function updateOverlay()
	overlay:SetFov({
		Enabled = fovToggle:Get() == true,
		Radius = fovRadius:Get(),
		Thickness = fovThickness:Get(),
		Color = fovColor:Get(),
		Opacity = fovAlpha:Get(),
	})
	overlay:SetCrosshair({
		Enabled = crosshairToggle:Get() == true,
		Color = crosshairColor:Get(),
		Length = crosshairLength:Get(),
		Gap = crosshairGap:Get(),
		Thickness = crosshairThickness:Get(),
		Opacity = crosshairAlpha:Get(),
	})
end

for _, el in ipairs({
	fovToggle, fovRadius, fovThickness, fovColor, fovAlpha,
	crosshairToggle, crosshairColor, crosshairLength, crosshairGap, crosshairThickness, crosshairAlpha,
}) do
	el:OnChanged(updateOverlay)
end
updateOverlay()

local world = visualsTab:AddGroup("World", "Left")
world:AddToggle({ Text = "Fullbright", Flag = "fullbright" })
world:AddSlider({ Text = "Field of view", Flag = "fov", Min = 60, Max = 120, Default = 70 })
world:AddSlider({ Text = "Brightness", Flag = "brightness", Min = 0, Max = 5, Default = 2, Decimals = 1 })

local esp = visualsTab:AddGroup("Player ESP", "Right")
unavailable(esp)
lock(esp:AddToggle({ Text = "Enable ESP" }))
lock(esp:AddToggle({ Text = "Bounding box" }))
lock(esp:AddDropdown({ Text = "Box style", Values = { "Full", "Corner", "3D" } }))
lock(esp:AddToggle({ Text = "Player name" }))
lock(esp:AddToggle({ Text = "Distance" }))
lock(esp:AddToggle({ Text = "Health bar" }))
lock(esp:AddToggle({ Text = "Health text" }))
lock(esp:AddToggle({ Text = "Weapon name" }))
lock(esp:AddToggle({ Text = "Skeleton" }))
lock(esp:AddToggle({ Text = "Snaplines" }))
lock(esp:AddToggle({ Text = "Head dot" }))

local espStyle = visualsTab:AddGroup("ESP customization", "Right")
unavailable(espStyle)
lockColor(espStyle, "Box color", Color3.fromRGB(255, 255, 255))
lockColor(espStyle, "Name color", Color3.fromRGB(255, 255, 255))
lockColor(espStyle, "Skeleton color", Color3.fromRGB(255, 255, 255))
lockColor(espStyle, "Tracer color", Color3.fromRGB(255, 255, 255))
lockColor(espStyle, "Health high", Color3.fromRGB(80, 180, 80))
lockColor(espStyle, "Health low", Color3.fromRGB(180, 60, 60))
lock(espStyle:AddSlider({ Text = "Box thickness", Min = 1, Max = 4, Default = 1 }))
lock(espStyle:AddSlider({ Text = "Skeleton thickness", Min = 1, Max = 4, Default = 1 }))
lock(espStyle:AddSlider({ Text = "Tracer thickness", Min = 1, Max = 4, Default = 1 }))
lock(espStyle:AddSlider({ Text = "ESP opacity", Min = 0, Max = 100, Default = 100, Suffix = "%" }))
lock(espStyle:AddSlider({ Text = "Text size", Min = 10, Max = 20, Default = 13 }))
lock(espStyle:AddSlider({ Text = "Max distance", Min = 50, Max = 2000, Default = 500 }))

local chams = visualsTab:AddGroup("Chams", "Right")
unavailable(chams)
lock(chams:AddToggle({ Text = "Enable chams" }))
lockColor(chams, "Visible color", Color3.fromRGB(80, 180, 80))
lockColor(chams, "Occluded color", Color3.fromRGB(180, 60, 60))
lock(chams:AddSlider({ Text = "Fill opacity", Min = 0, Max = 100, Default = 40, Suffix = "%" }))
lock(chams:AddSlider({ Text = "Outline opacity", Min = 0, Max = 100, Default = 100, Suffix = "%" }))
lock(chams:AddDropdown({ Text = "Depth mode", Values = { "Visible", "Occluded", "Always" } }))

-- Settings ----------------------------------------------------------------------
local settings = settingsTab:AddGroup("Settings", "Right")

settings:AddLabel("Menu key"):AddKeybind({
	Default = Enum.KeyCode.Insert,
	Flag = "menuKey",
	Callback = function(key)
		if key then
			window:SetToggleKey(key)
		end
	end,
})

settings:AddLabel("Menu color"):AddColorPicker({
	Default = UI.Theme.Accent,
	Flag = "menuColor",
	Callback = function(color)
		window:SetAccent(color)
	end,
})

settings:AddToggle({
	Text = "Watermark",
	Flag = "watermark",
	Default = true,
	Callback = function(on)
		watermark:SetVisible(on)
	end,
})

settings:AddToggle({
	Text = "Lock menu layout",
	Flag = "lockLayout",
	Callback = function(locked)
		window:SetLocked(locked)
	end,
})

-- Configs em memória (duram a sessão). Use Export/Import para levar a config como texto.
local configs = {}
local others = settingsTab:AddGroup("Other", "Right")

local configList = others:AddListbox({ Values = {}, Height = 95 })
local configName = others:AddTextbox({ Placeholder = "New configuration name" })

local function refresh()
	local names = {}
	for name in pairs(configs) do
		table.insert(names, name)
	end
	table.sort(names)
	configList:Refresh(names)
end

others:AddButton({
	Text = "Add",
	Callback = function()
		local name = configName:Get()
		if name ~= "" then
			configs[name] = HttpService:JSONEncode(window:GetConfig())
			refresh()
		end
	end,
})

others:AddButton({
	Text = "Remove",
	Callback = function()
		local name = configList:Get()
		if name then
			configs[name] = nil
			refresh()
		end
	end,
})

others:AddButton({
	Text = "Load",
	Callback = function()
		local name = configList:Get()
		if name and configs[name] then
			window:LoadConfig(HttpService:JSONDecode(configs[name]))
		end
	end,
})

others:AddButton({
	Text = "Save",
	Callback = function()
		local name = configList:Get()
		if name then
			configs[name] = HttpService:JSONEncode(window:GetConfig())
		end
	end,
})

local configText = others:AddTextbox({ Placeholder = "JSON da config" })

others:AddButton({
	Text = "Export",
	Callback = function()
		configText:Set(HttpService:JSONEncode(window:GetConfig()))
	end,
})

others:AddButton({
	Text = "Import",
	Callback = function()
		local ok, config = pcall(HttpService.JSONDecode, HttpService, configText:Get())
		if ok and type(config) == "table" then
			window:LoadConfig(config)
		end
	end,
})

window:OnUnload(function()
	if shared.GamesenseWindow == window then
		shared.GamesenseWindow = nil
	end
end)

others:AddButton({
	Text = "Unload",
	Callback = function()
		window:Unload()
	end,
})
