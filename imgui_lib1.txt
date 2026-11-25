local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local env = (getgenv and getgenv()) or _G
if env.__IMGUI_LIB then
	pcall(function()
		env.__IMGUI_LIB:Destroy()
	end)
end

local TOUCH = UIS.TouchEnabled and not UIS.KeyboardEnabled
local FONT = Enum.Font.Code
local TS = 13
local FH = 19
local GAP = 4
local PADX = 8
local GW = 10
local SB = 7
local Settings = {Ripple = false, Anim = true, Theme = "Iris 深色", Accent = nil, Opacity = 1, Numpad = false, Round = 0, Border = 1, Blur = 0, Sounds = false, Speed = 1}

local function tok(r, g, b, t)
	return {Color3.fromRGB(r, g, b), t}
end

local T = {
	WindowBg = tok(15, 15, 15, 0.06),
	PopupBg = tok(20, 20, 20, 0.06),
	Title = tok(10, 10, 10, 0),
	TitleActive = tok(41, 74, 122, 0),
	TitleCollapsed = tok(0, 0, 0, 0.5),
	Menubar = tok(36, 36, 36, 0),
	Frame = tok(41, 74, 122, 0.46),
	Inset = tok(0, 0, 0, 0.4),
	FrameHover = tok(66, 150, 250, 0.46),
	FrameActive = tok(66, 150, 250, 0.33),
	Button = tok(66, 150, 250, 0.6),
	ButtonHover = tok(66, 150, 250, 0),
	ButtonActive = tok(15, 135, 250, 0),
	Header = tok(66, 150, 250, 0.69),
	HeaderHover = tok(66, 150, 250, 0.2),
	HeaderActive = tok(66, 150, 250, 0),
	Tab = tok(46, 89, 148, 0.14),
	TabHover = tok(66, 150, 250, 0.2),
	TabActive = tok(51, 105, 173, 0),
	Grab = tok(66, 150, 250, 0),
	GrabActive = tok(117, 180, 255, 0),
	Separator = tok(110, 110, 128, 0.5),
	Border = tok(110, 110, 125, 0.5),
	Clear = tok(0, 0, 0, 1),
	Histogram = tok(230, 179, 0, 0),
	GripIdle = tok(66, 150, 250, 0.8),
	GripActive = tok(66, 150, 250, 0.05),
	Text = Color3.fromRGB(255, 255, 255),
	TextDisabled = Color3.fromRGB(128, 128, 128),
	CheckMark = Color3.fromRGB(66, 150, 250),
	Scroll = Color3.fromRGB(79, 79, 79)
}

local DARK = {}
for k, v in T do
	DARK[k] = typeof(v) ~= "Color3" and {v[1], v[2]} or v
end

local ICONS = {
	Right = "rbxassetid://105541346271951",
	Check = "rbxassetid://109638815494221",
	Close = "rbxassetid://133890060015237",
	Grip = "rbxassetid://125737344915000"
}

local FALLBACK = {Right = "▶", Check = "✓", Close = "x", Grip = "◢"}

local function paint(obj, t)
	obj.BackgroundColor3 = t[1]
	obj.BackgroundTransparency = t[2]
end

local function new(class, props, parent)
	local obj = Instance.new(class)
	for k, v in props do
		obj[k] = v
	end
	if Settings.Round > 0 and (class == "Frame" or class == "TextButton" or class == "TextBox") and obj.BackgroundTransparency < 1 then
		local c = Instance.new("UICorner")
		c.Name = "__R"
		c.CornerRadius = UDim.new(0, Settings.Round)
		c.Parent = obj
	end
	if class == "TextLabel" or class == "TextButton" then
		if props.TextTruncate == nil and props.TextWrapped ~= true and props.AutomaticSize == nil then
			obj.TextTruncate = Enum.TextTruncate.AtEnd
		end
	elseif class == "TextBox" and props.ClipsDescendants == nil then
		obj.ClipsDescendants = true
	end
	obj.Parent = parent
	if class == "UICorner" and parent and obj.Name ~= "__R" then
		local r = parent:FindFirstChild("__R")
		if r then
			r:Destroy()
		end
	end
	return obj
end

local function frame(parent, t, props)
	local p = {BackgroundColor3 = t[1], BackgroundTransparency = t[2], BorderSizePixel = 0}
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	return new("Frame", p, parent)
end

local function label(parent, str, props)
	local p = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		Text = str,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center
	}
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	return new("TextLabel", p, parent)
end

local function button(parent, t, props)
	local p = {
		BackgroundColor3 = t[1],
		BackgroundTransparency = t[2],
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text
	}
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	return new("TextButton", p, parent)
end

local function pad(parent, l, r, t, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l),
		PaddingRight = UDim.new(0, r),
		PaddingTop = UDim.new(0, t),
		PaddingBottom = UDim.new(0, b)
	}, parent)
end

local function list(parent, gap, horizontal, wraps)
	return new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Wraps = wraps and true or false
	}, parent)
end

local function stroke(parent, t, thickness)
	return new("UIStroke", {
		Color = t[1],
		Transparency = t[2],
		Thickness = thickness or Settings.Border,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	}, parent)
end

local function textWidth(str)
	local ok, bounds = pcall(function()
		return TextService:GetTextSize(str, TS, FONT, Vector2.new(10000, 10000))
	end)
	if ok then
		return bounds.X
	end
	return #str * 8
end

local function clamp(v, a, b)
	return math.max(a, math.min(b, v))
end

local function icon(parent, name, props)
	local p = {
		BackgroundTransparency = 1,
		Image = ICONS[name],
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = T.Text
	}
	if props then
		for k, v in props do
			p[k] = v
		end
	end
	local img = new("ImageLabel", p, parent)
	task.spawn(function()
		local ok, failed = pcall(function()
			local cp = game:GetService("ContentProvider")
			cp:PreloadAsync({img})
			return cp:GetAssetFetchStatus(img.Image) ~= Enum.AssetFetchStatus.Success
		end)
		if ok and failed and img.Parent then
			img.Visible = false
			label(img.Parent, FALLBACK[name], {
				Size = img.Size,
				Position = img.Position,
				AnchorPoint = img.AnchorPoint,
				Rotation = img.Rotation,
				TextColor3 = img.ImageColor3,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = img.ZIndex
			})
		end
	end)
	return img
end

local UIHooks = {}
local FADE = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SPIN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local spun = setmetatable({}, {__mode = "k"})

local function spin(obj, deg)
	if Settings.Anim and spun[obj] and obj.Parent then
		TweenService:Create(obj, SPIN, {Rotation = deg}):Play()
	else
		obj.Rotation = deg
	end
	spun[obj] = true
end

local function ripple(btn, pos)
	local abs, sz = btn.AbsolutePosition, btn.AbsoluteSize
	if sz.X <= 0 or sz.Y <= 0 then
		return
	end
	local sc = Settings.Scale or 1
	btn.ClipsDescendants = true
	local d = math.max(sz.X, sz.Y) / sc * 2
	local c = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((pos.X - abs.X) / sc, (pos.Y - abs.Y) / sc),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = 15,
		Name = "__FX"
	}, btn)
	new("UICorner", {CornerRadius = UDim.new(1, 0)}, c)
	pcall(function()
		TweenService:Create(c, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1}):Play()
	end)
	task.delay(0.5, function()
		if c.Parent then
			c:Destroy()
		end
	end)
end

local function bind(btn, normal, hover, press)
	local over, down = false, false
	local st = {Normal = normal, Hover = hover, Press = press}
	local ready = false
	local function refresh()
		local t
		if down then
			t = st.Press
		elseif over and not TOUCH then
			t = st.Hover
		else
			t = st.Normal
		end
		if ready and Settings.Anim and btn.Parent then
			TweenService:Create(btn, FADE, {BackgroundColor3 = t[1], BackgroundTransparency = t[2]}):Play()
		else
			paint(btn, t)
		end
	end
	btn.InputBegan:Connect(function(input)
		if Settings.Ripple and btn.BackgroundTransparency < 1 and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			ripple(btn, input.Position)
		end
	end)
	btn.MouseEnter:Connect(function()
		over = true
		refresh()
	end)
	btn.MouseLeave:Connect(function()
		over = false
		down = false
		refresh()
	end)
	btn.MouseButton1Click:Connect(function()
		if UIHooks.Click then
			UIHooks.Click()
		end
	end)
	btn.MouseButton1Down:Connect(function()
		down = true
		refresh()
	end)
	btn.MouseButton1Up:Connect(function()
		down = false
		refresh()
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			down = false
			over = false
			refresh()
		end
	end)
	st.Refresh = refresh
	refresh()
	ready = true
	return st
end

local function colorTokens(c)
	return {c, 0}, {c:Lerp(Color3.new(1, 1, 1), 0.15), 0}, {c:Lerp(Color3.new(1, 1, 1), 0.3), 0}
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function clampHit(self, row, hit, nameLabel, offset)
	if self.Inline then
		return
	end
	hit:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local rw = row.AbsoluteSize.X
		if rw > 0 and hit.AbsoluteSize.X > rw + 0.5 and hit.AutomaticSize ~= Enum.AutomaticSize.None then
			hit.AutomaticSize = Enum.AutomaticSize.None
			hit.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.Size = UDim2.new(1, -offset, 1, 0)
		end
	end)
end

local Library = {Windows = {}, Conns = {}, TopZ = 1, Binds = {}}
Library.__index = Library

local Container = {}
Container.__index = Container

local Window = {}
Window.__index = Window
setmetatable(Window, {__index = Container})

local Drag

local function beginDrag(input, fn, onEnd)
	if Drag and Drag.End then
		local prev = Drag
		Drag = nil
		prev.End()
	end
	Drag = {Input = input, Fn = fn, End = onEnd}
end

local function makeContainer(win, content, inline)
	return setmetatable({Win = win, Content = content, Inline = inline, _n = 0}, Container)
end

function Container:_row(height, wide)
	self._n = self._n + 1
	if self.Inline and not wide then
		return new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 0, height or FH),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = self._n
		}, self.Content)
	end
	return new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or FH),
		LayoutOrder = self._n
	}, self.Content)
end

function Container:_sub(inline, leftPad, gap)
	self._n = self._n + 1
	local f = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._n
	}, self.Content)
	local l = list(f, gap or (inline and PADX or GAP), inline, inline)
	l.VerticalAlignment = Enum.VerticalAlignment.Top
	if leftPad and leftPad > 0 then
		pad(f, leftPad, 0, 0, 0)
	end
	local c = makeContainer(self.Win, f, inline)
	c.ItemWidth = self.ItemWidth
	return c, f
end

function Container:SetItemWidth(w)
	self.ItemWidth = clamp(w, 0.2, 0.9)
end

local function makeSlider(win, track, o)
	local grab = frame(track, T.Grab, {Size = UDim2.new(0, GW, 1, -2), Position = UDim2.new(0, 0, 0, 1)})
	local text = label(track, "", {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2})
	local s = {Value = o.Value, Min = o.Min, Max = o.Max}

	local function fmt(v)
		if o.Format then
			return string.format(o.Format, v)
		end
		if o.Int then
			return string.format("%d", v)
		end
		return string.format("%.3f", v)
	end

	local function render()
		local r = 0
		if s.Max > s.Min then
			r = clamp((s.Value - s.Min) / (s.Max - s.Min), 0, 1)
		end
		grab.Position = UDim2.new(r, -r * GW, 0, 1)
		text.Text = fmt(s.Value)
	end

	function s.Set(v, fire)
		v = clamp(v, s.Min, s.Max)
		if o.Int then
			v = math.floor(v + 0.5)
		else
			v = math.floor(v * 1000000 + 0.5) / 1000000
		end
		local changed = v ~= s.Value
		s.Value = v
		render()
		if fire and changed and o.OnChange then
			o.OnChange(v)
		end
	end

	local function fromX(x)
		local scale = win.Scale
		local abs = track.AbsolutePosition.X
		local w = track.AbsoluteSize.X
		local r = clamp((x - abs - GW / 2 * scale) / math.max(w - GW * scale, 1), 0, 1)
		s.Set(s.Min + (s.Max - s.Min) * r, true)
	end

	local function edit()
		if Settings.Numpad and win.Lib then
			win.Lib:Numpad(s.Value, function(n)
				s.Set(n, true)
			end, {Int = o.Int, Min = s.Min, Max = s.Max, Title = "输入数值"})
			return
		end
		local box = new("TextBox", {
			BackgroundColor3 = T.FrameActive[1],
			BackgroundTransparency = T.FrameActive[2],
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Font = FONT,
			TextSize = TS,
			TextColor3 = T.Text,
			Text = o.Int and string.format("%d", s.Value) or tostring(s.Value),
			ClearTextOnFocus = false,
			ZIndex = 5
		}, track)
		box.FocusLost:Connect(function()
			local n = tonumber(box.Text)
			if n then
				s.Set(n, true)
			end
			box:Destroy()
		end)
		box:CaptureFocus()
	end

	local hoverTrack = false
	track.MouseEnter:Connect(function()
		hoverTrack = true
		if not TOUCH then
			paint(track, T.FrameHover)
		end
	end)
	track.MouseLeave:Connect(function()
		hoverTrack = false
		paint(track, T.Frame)
	end)

	track.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local touch = input.UserInputType == Enum.UserInputType.Touch
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local moved = not touch
		paint(track, T.FrameActive)
		grab.BackgroundColor3 = T.GrabActive[1]
		win.Body.ScrollingEnabled = false
		if moved then
			fromX(input.Position.X)
		end
		beginDrag(input, function(pos)
			if not moved then
				if (pos - start).Magnitude < 6 then
					return
				end
				moved = true
			end
			fromX(pos.X)
		end, function()
			paint(track, hoverTrack and not TOUCH and T.FrameHover or T.Frame)
			grab.BackgroundColor3 = T.Grab[1]
			win.Body.ScrollingEnabled = true
			if not moved then
				edit()
			end
		end)
	end)

	render()
	return s
end

function Window:_closePopup()
	if self.Popup then
		self.Popup.Blocker:Destroy()
		self.Popup.Frame:Destroy()
		self.Popup = nil
	end
end

function Window:_popup(anchor, width, height, build)
	self:_closePopup()
	local gui = self.Lib.Gui
	local vp = gui.AbsoluteSize
	if vp.X <= 0 then
		vp = Vector2.new(800, 600)
	end
	local s = self.Scale
	width = math.min(width, vp.X / s - 8)
	local blocker = button(self.Frame, T.Clear, {
		Size = UDim2.fromOffset(10000, 10000),
		Position = UDim2.fromOffset(-5000, -5000),
		ZIndex = 90
	})
	local pop = frame(self.Frame, T.PopupBg, {ZIndex = 91, Size = UDim2.fromOffset(width, height)})
	stroke(pop, T.Border)
	local abs = anchor.AbsolutePosition
	local ah = anchor.AbsoluteSize.Y
	local px = clamp(abs.X, 4, math.max(vp.X - width * s - 4, 4))
	local py = abs.Y + ah
	if py + height * s > vp.Y - 4 then
		py = math.max(abs.Y - height * s, 4)
	end
	local origin = self.Frame.AbsolutePosition
	pop.Position = UDim2.fromOffset((px - origin.X) / s, (py - origin.Y) / s)
	blocker.MouseButton1Click:Connect(function()
		self:_closePopup()
	end)
	self.Popup = {Blocker = blocker, Frame = pop}
	build(pop)
	return pop
end

local function popupItem(parent, str, selected, order, onClick, left)
	local normal = selected and T.Header or T.Clear
	local b = button(parent, normal, {
		Size = UDim2.new(1, 0, 0, FH),
		Text = str,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order
	})
	pad(b, left or 4, 4, 0, 0)
	bind(b, normal, T.HeaderHover, T.HeaderActive)
	b.MouseButton1Click:Connect(onClick)
	return b
end

function Container:Text(str, color, wrap)
	local row = self:_row(0)
	local lbl = label(row, str, {
		Size = UDim2.new(wrap == false and 0 or 1, 0, 0, 0),
		AutomaticSize = wrap == false and Enum.AutomaticSize.XY or Enum.AutomaticSize.Y,
		TextWrapped = wrap ~= false,
		TextColor3 = color or T.Text,
		TextYAlignment = Enum.TextYAlignment.Top
	})
	if self.Inline then
		row.Size = UDim2.new(0, 0, 0, FH)
		row.AutomaticSize = Enum.AutomaticSize.X
		lbl.AutomaticSize = Enum.AutomaticSize.X
		lbl.Size = UDim2.new(0, 0, 1, 0)
		lbl.TextWrapped = false
		lbl.TextYAlignment = Enum.TextYAlignment.Center
	else
		row.AutomaticSize = Enum.AutomaticSize.Y
	end
	local obj = {Frame = row, Label = lbl}
	function obj:Set(v)
		lbl.Text = tostring(v)
	end
	function obj:SetColor(c)
		lbl.TextColor3 = c
	end
	function obj:Get()
		return lbl.Text
	end
	return obj
end

function Container:TextDisabled(str)
	return self:Text(str, T.TextDisabled)
end

function Container:LabelText(name, value)
	local row = self:_row(FH, true)
	local v = label(row, tostring(value), {Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right})
	label(row, name, {Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left})
	local obj = {Frame = row}
	function obj:Set(x)
		v.Text = tostring(x)
	end
	return obj
end

function Container:Bullet(str)
	return self:Text("• " .. str)
end

function Container:Separator(str)
	local row = self:_row(str and FH or 5, true)
	if not str then
		frame(row, T.Separator, {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0)})
		return {Frame = row}
	end
	local w = textWidth(str)
	frame(row, T.Separator, {Size = UDim2.new(0, 20, 0, 3), Position = UDim2.new(0, 0, 0.5, -1)})
	label(row, str, {Size = UDim2.new(0, w + 2, 1, 0), Position = UDim2.fromOffset(24, 0)})
	frame(row, T.Separator, {Size = UDim2.new(1, -(w + 32), 0, 3), Position = UDim2.new(0, w + 30, 0.5, -1)})
	return {Frame = row}
end

function Container:Spacing(h)
	local row = self:_row(h or 6, true)
	return {Frame = row}
end

function Container:Button(str, callback, color)
	local row = self:_row(FH)
	local n, h, p = T.Button, T.ButtonHover, T.ButtonActive
	if color then
		n, h, p = colorTokens(color)
	end
	local btn = button(row, n, {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = str
	})
	pad(btn, 4, 4, 0, 0)
	if not self.Inline then
		btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local rw = row.AbsoluteSize.X
			if rw > 0 and btn.AbsoluteSize.X > rw + 0.5 and btn.AutomaticSize ~= Enum.AutomaticSize.None then
				btn.AutomaticSize = Enum.AutomaticSize.None
				btn.Size = UDim2.new(1, 0, 1, 0)
			end
		end)
	end
	local st = bind(btn, n, h, p)
	btn.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(callback)
		end
	end)
	local obj = {Frame = row, Button = btn}
	function obj:SetText(v)
		btn.Text = v
	end
	function obj:SetColor(c)
		st.Normal, st.Hover, st.Press = colorTokens(c)
		st.Refresh()
	end
	return obj
end

function Container:SmallButton(str, callback, color)
	local obj = self:Button(str, callback, color)
	obj.Frame.Size = UDim2.new(obj.Frame.Size.X.Scale, 0, 0, FH - 4)
	return obj
end

function Container:ArrowButton(direction, callback)
	local rot = {Right = 0, Down = 90, Left = 180, Up = 270}
	local row = self:_row(FH)
	local btn = button(row, T.Button, {Size = UDim2.new(0, FH, 1, 0)})
	bind(btn, T.Button, T.ButtonHover, T.ButtonActive)
	icon(btn, "Right", {
		Size = UDim2.fromOffset(FH - 8, FH - 8),
		Position = UDim2.fromOffset(4, 4),
		Rotation = rot[direction] or 0
	})
	btn.MouseButton1Click:Connect(function()
		if callback then
			task.spawn(callback)
		end
	end)
	return {Frame = row, Button = btn}
end

function Container:Checkbox(str, default, callback)
	local row = self:_row(FH)
	local hit = new("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X
	}, row)
	list(hit, 4, true)
	local box = frame(hit, T.Frame, {Size = UDim2.fromOffset(FH, FH), LayoutOrder = 1})
	local mark = icon(box, "Check", {
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		ImageColor3 = T.CheckMark,
		Visible = false
	})
	local nameLabel = label(hit, str, {Size = UDim2.new(0, textWidth(str) + 4, 1, 0), LayoutOrder = 2})
	clampHit(self, row, hit, nameLabel, FH + 4)
	local state = {Value = default and true or false}
	function state.Set(v, fire)
		state.Value = v and true or false
		mark.Visible = state.Value
		if fire and callback then
			task.spawn(callback, state.Value)
		end
	end
	function state.Get()
		return state.Value
	end
	local over, down = false, false
	local function refresh()
		if down then
			paint(box, T.FrameActive)
		elseif over and not TOUCH then
			paint(box, T.FrameHover)
		else
			paint(box, T.Frame)
		end
	end
	hit.MouseEnter:Connect(function()
		over = true
		refresh()
	end)
	hit.MouseLeave:Connect(function()
		over = false
		down = false
		refresh()
	end)
	hit.MouseButton1Down:Connect(function()
		down = true
		refresh()
	end)
	hit.MouseButton1Up:Connect(function()
		down = false
		refresh()
	end)
	hit.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			down = false
			over = false
			refresh()
		end
	end)
	hit.MouseButton1Click:Connect(function()
		state.Set(not state.Value, true)
	end)
	state.Frame = row
	mark.Visible = state.Value
	return state
end

function Container:RadioGroup(items, default, callback, inline)
	local sub = self:_sub(inline ~= false)
	local state = {Value = default or items[1], Dots = {}}
	local function render()
		for name, dot in state.Dots do
			dot.Visible = name == state.Value
		end
	end
	for _, name in items do
		local row = sub:_row(FH)
		local hit = new("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X
		}, row)
		list(hit, 4, true)
		local ring = frame(hit, T.Frame, {Size = UDim2.fromOffset(FH, FH), LayoutOrder = 1})
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, ring)
		local dot = frame(ring, {T.CheckMark, 0}, {Size = UDim2.fromOffset(FH - 8, FH - 8), Position = UDim2.fromOffset(4, 4)})
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
		state.Dots[name] = dot
		label(hit, name, {Size = UDim2.new(0, textWidth(name) + 4, 1, 0), LayoutOrder = 2})
		hit.MouseEnter:Connect(function()
			if not TOUCH then
				paint(ring, T.FrameHover)
			end
		end)
		hit.MouseLeave:Connect(function()
			paint(ring, T.Frame)
		end)
		hit.MouseButton1Click:Connect(function()
			state.Set(name, true)
		end)
	end
	function state.Set(v, fire)
		state.Value = v
		render()
		if fire and callback then
			task.spawn(callback, v)
		end
	end
	function state.Get()
		return state.Value
	end
	render()
	return state
end

function Container:Slider(name, min, max, default, callback, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local track = new("TextButton", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(iw, -4, 1, 0)
	}, row)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local s = makeSlider(win, track, {
		Min = min,
		Max = max,
		Int = opts.Int,
		Format = opts.Format,
		Value = clamp(default or min, min, max),
		OnChange = callback and function(v)
			task.spawn(callback, v)
		end or nil
	})
	function s.Get()
		return s.Value
	end
	s.Frame = row
	return s
end

function Container:SliderInt(name, min, max, default, callback, format)
	return self:Slider(name, min, max, default, callback, {Int = true, Format = format})
end

function Container:SliderFloat(name, min, max, default, callback, format)
	return self:Slider(name, min, max, default, callback, {Format = format})
end

function Container:InputText(name, default, callback, placeholder)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local box = new("TextBox", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Size = UDim2.new(iw, -4, 1, 0),
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		PlaceholderText = placeholder or "",
		PlaceholderColor3 = T.TextDisabled,
		Text = default or "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left
	}, row)
	pad(box, 4, 4, 0, 0)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	box.MouseEnter:Connect(function()
		if not TOUCH and not box:IsFocused() then
			paint(box, T.FrameHover)
		end
	end)
	box.MouseLeave:Connect(function()
		if not box:IsFocused() then
			paint(box, T.Frame)
		end
	end)
	box.Focused:Connect(function()
		paint(box, T.FrameActive)
	end)
	box.FocusLost:Connect(function(enter)
		paint(box, T.Frame)
		if callback then
			task.spawn(callback, box.Text, enter)
		end
	end)
	local obj = {Frame = row, Box = box}
	function obj:Set(v, fire)
		box.Text = tostring(v)
		if fire and callback then
			task.spawn(callback, box.Text, false)
		end
	end
	function obj:Get()
		return box.Text
	end
	return obj
end

function Container:InputNumber(name, default, callback, step, min, max)
	local win = self.Win
	step = step or 1
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(iw, -4, 1, 0)}, row)
	local box = new("TextBox", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Size = UDim2.new(1, -(FH * 2 + 8), 1, 0),
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		Text = tostring(default or 0),
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left
	}, holder)
	pad(box, 4, 4, 0, 0)
	local state = {Value = default or 0}
	local function apply(v, fire)
		if min then
			v = math.max(v, min)
		end
		if max then
			v = math.min(v, max)
		end
		state.Value = v
		box.Text = tostring(v)
		if fire and callback then
			task.spawn(callback, v)
		end
	end
	local minus = button(holder, T.Button, {Size = UDim2.fromOffset(FH, FH), Position = UDim2.new(1, -(FH * 2 + 4), 0, 0), Text = "-"})
	local plus = button(holder, T.Button, {Size = UDim2.fromOffset(FH, FH), Position = UDim2.new(1, -FH, 0, 0), Text = "+"})
	bind(minus, T.Button, T.ButtonHover, T.ButtonActive)
	bind(plus, T.Button, T.ButtonHover, T.ButtonActive)
	minus.MouseButton1Click:Connect(function()
		apply(state.Value - step, true)
	end)
	plus.MouseButton1Click:Connect(function()
		apply(state.Value + step, true)
	end)
	box.Focused:Connect(function()
		paint(box, T.FrameActive)
	end)
	box.FocusLost:Connect(function()
		paint(box, T.Frame)
		local n = tonumber(box.Text)
		if n then
			apply(n, true)
		else
			box.Text = tostring(state.Value)
		end
	end)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	state.Frame = row
	state.Set = apply
	function state.Get()
		return state.Value
	end
	return state
end

local function listPopup(win, box, entries, isSelected, onPick, search, keepOpen)
	local visible = math.min(#entries, 7)
	local top = search and (FH + 2) or 0
	local height = visible * FH + 4 + top
	win:_popup(box, box.AbsoluteSize.X / win.Scale, height, function(pop)
		local scroll = new("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, top),
			Size = UDim2.new(1, 0, 1, -top),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = SB,
			ScrollBarImageColor3 = T.Scroll
		}, pop)
		pad(scroll, 2, 2, 2, 2)
		list(scroll, 0).VerticalAlignment = Enum.VerticalAlignment.Top
		local filter = ""
		local fill
		fill = function()
			for _, child in scroll:GetChildren() do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end
			local order = 0
			for _, item in entries do
				local text = tostring(item)
				if filter == "" or string.find(string.lower(text), filter, 1, true) then
					order = order + 1
					local selected = isSelected(item)
					local b = popupItem(scroll, text, selected and not keepOpen, order, function()
						onPick(item)
						if keepOpen then
							fill()
						else
							win:_closePopup()
						end
					end, keepOpen and 20 or 4)
					if keepOpen and selected then
						icon(b, "Check", {
							Size = UDim2.fromOffset(FH - 6, FH - 6),
							Position = UDim2.fromOffset(-17, 3),
							ImageColor3 = T.CheckMark
						})
					end
				end
			end
		end
		if search then
			local input = new("TextBox", {
				BackgroundColor3 = T.Frame[1],
				BackgroundTransparency = T.Frame[2],
				BorderSizePixel = 0,
				Size = UDim2.new(1, -4, 0, FH),
				Position = UDim2.fromOffset(2, 2),
				Font = FONT,
				TextSize = TS,
				TextColor3 = T.Text,
				PlaceholderText = "搜索...",
				PlaceholderColor3 = T.TextDisabled,
				Text = "",
				ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left
			}, pop)
			pad(input, 4, 4, 0, 0)
			input:GetPropertyChangedSignal("Text"):Connect(function()
				filter = string.lower(input.Text)
				fill()
			end)
		end
		fill()
	end)
end

local function comboBox(self, name, text)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local box = button(row, T.Frame, {
		Size = UDim2.new(iw, -4, 1, 0),
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true
	})
	pad(box, 4, FH, 0, 0)
	local arrowBox = frame(box, T.Button, {Size = UDim2.fromOffset(FH, FH), Position = UDim2.new(1, 0, 0, 0)})
	icon(arrowBox, "Right", {Size = UDim2.fromOffset(FH - 8, FH - 8), Position = UDim2.fromOffset(4, 4), Rotation = 90})
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	bind(box, T.Frame, T.FrameHover, T.FrameActive)
	return row, box
end

function Container:Combo(name, items, default, callback, opts)
	opts = opts or {}
	local win = self.Win
	local state = {Value = nil, Items = items}
	if type(default) == "number" then
		state.Value = items[default]
	else
		state.Value = default or items[1]
	end
	local row, box = comboBox(self, name, tostring(state.Value or ""))
	function state.Set(v, fire)
		state.Value = v
		box.Text = tostring(v)
		if fire and callback then
			task.spawn(callback, v)
		end
	end
	function state.Get()
		return state.Value
	end
	function state.SetItems(newItems)
		state.Items = newItems
	end
	box.MouseButton1Click:Connect(function()
		listPopup(win, box, state.Items, function(item)
			return item == state.Value
		end, function(item)
			state.Set(item, true)
		end, opts.Search, false)
	end)
	state.Frame = row
	return state
end

function Container:MultiCombo(name, items, defaults, callback, opts)
	opts = opts or {}
	local win = self.Win
	local state = {Items = items, Selected = {}}
	for _, v in defaults or {} do
		state.Selected[v] = true
	end
	local row, box = comboBox(self, name, "")
	local function values()
		local out = {}
		for _, item in state.Items do
			if state.Selected[item] then
				table.insert(out, item)
			end
		end
		return out
	end
	local function render()
		local v = values()
		if #v == 0 then
			box.Text = "无"
		elseif #v <= 2 then
			box.Text = table.concat(v, ", ")
		else
			box.Text = string.format("已选 %d 项", #v)
		end
	end
	function state.Get()
		return values()
	end
	function state.Set(list_, fire)
		state.Selected = {}
		for _, v in list_ do
			state.Selected[v] = true
		end
		render()
		if fire and callback then
			task.spawn(callback, values())
		end
	end
	box.MouseButton1Click:Connect(function()
		listPopup(win, box, state.Items, function(item)
			return state.Selected[item] == true
		end, function(item)
			state.Selected[item] = not state.Selected[item] or nil
			render()
			if callback then
				task.spawn(callback, values())
			end
		end, opts.Search, true)
	end)
	render()
	state.Frame = row
	return state
end

function Container:Selectable(str, selected, callback)
	local row = self:_row(FH, true)
	local state = {Value = selected and true or false}
	local btn = button(row, state.Value and T.Header or T.Clear, {
		Size = UDim2.fromScale(1, 1),
		Text = str,
		TextXAlignment = Enum.TextXAlignment.Left
	})
	pad(btn, 4, 4, 0, 0)
	local st = bind(btn, state.Value and T.Header or T.Clear, T.HeaderHover, T.HeaderActive)
	function state.Set(v, fire)
		state.Value = v and true or false
		st.Normal = state.Value and T.Header or T.Clear
		st.Refresh()
		if fire and callback then
			task.spawn(callback, state.Value)
		end
	end
	function state.Get()
		return state.Value
	end
	btn.MouseButton1Click:Connect(function()
		state.Set(not state.Value, true)
	end)
	state.Frame = row
	return state
end

function Container:ListBox(name, items, default, callback, rows)
	if name and name ~= "" then
		self:Text(name)
	end
	rows = rows or 5
	local row = self:_row(rows * FH + 4, true)
	local box = frame(row, T.Frame, {Size = UDim2.fromScale(1, 1)})
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, box)
	pad(scroll, 2, 2, 2, 2)
	list(scroll, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	local state = {Value = default or items[1], Sts = {}}
	local function render()
		for item, st in state.Sts do
			st.Normal = item == state.Value and T.Header or T.Clear
			st.Refresh()
		end
	end
	for i, item in items do
		local b = button(scroll, T.Clear, {
			Size = UDim2.new(1, 0, 0, FH),
			Text = tostring(item),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = i
		})
		pad(b, 4, 4, 0, 0)
		state.Sts[item] = bind(b, T.Clear, T.HeaderHover, T.HeaderActive)
		b.MouseButton1Click:Connect(function()
			state.Set(item, true)
		end)
	end
	function state.Set(v, fire)
		state.Value = v
		render()
		if fire and callback then
			task.spawn(callback, v)
		end
	end
	function state.Get()
		return state.Value
	end
	render()
	state.Frame = row
	return state
end

function Container:ProgressBar(fraction, overlay, name)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local track = frame(row, T.Frame, {Size = UDim2.new(name and iw or 1, name and -4 or 0, 1, 0)})
	local fill = frame(track, T.Histogram, {Size = UDim2.new(clamp(fraction or 0, 0, 1), 0, 1, 0)})
	local text = label(track, overlay or string.format("%d%%", (fraction or 0) * 100), {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2
	})
	if name then
		label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	end
	local obj = {Frame = row, Value = clamp(fraction or 0, 0, 1)}
	function obj:Set(f, txt)
		f = clamp(f, 0, 1)
		obj.Value = f
		fill.Size = UDim2.new(f, 0, 1, 0)
		text.Text = txt or string.format("%d%%", f * 100)
	end
	return obj
end

function Container:ColorEdit(name, default, callback)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local state = {Value = default or Color3.new(1, 1, 1)}
	local swatch = button(row, {state.Value, 0}, {Size = UDim2.new(iw, -4, 1, 0)})
	local hex = label(swatch, "", {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center})
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local function toHex(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function render()
		swatch.BackgroundColor3 = state.Value
		hex.Text = toHex(state.Value)
		local lum = state.Value.R * 0.3 + state.Value.G * 0.59 + state.Value.B * 0.11
		hex.TextColor3 = lum > 0.55 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	end
	function state.Set(c, fire)
		state.Value = c
		render()
		if fire and callback then
			task.spawn(callback, c)
		end
	end
	function state.Get()
		return state.Value
	end
	swatch.MouseButton1Click:Connect(function()
		local width = math.max(swatch.AbsoluteSize.X / win.Scale, 190)
		local PAL = 90
		local height = PAL + 6 + 3 * (FH + 2) + FH + 8
		win:_popup(swatch, width, height, function(pop)
			pad(pop, 4, 4, 4, 4)
			local h, sat, val = state.Value:ToHSV()
			local sliders = {}
			local names = {"R", "G", "B"}
			local keys = {"R", "G", "B"}
			local innerW = width - 8
			local svW = innerW - 20

			local sv = new("TextButton", {
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Size = UDim2.fromOffset(svW, PAL),
				ClipsDescendants = true
			}, pop)
			local white = new("Frame", {BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, sv)
			new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})}, white)
			local black = new("Frame", {BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, sv)
			new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})}, black)
			local cursor = new("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(8, 8),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = 3
			}, sv)
			stroke(cursor, {Color3.new(1, 1, 1), 0}, 1)
			new("UICorner", {CornerRadius = UDim.new(1, 0)}, cursor)

			local hue = new("TextButton", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				Size = UDim2.fromOffset(14, PAL),
				Position = UDim2.fromOffset(svW + 6, 0)
			}, pop)
			new("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
					ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
					ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
					ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
				})
			}, hue)
			local hueMark = frame(hue, {Color3.new(1, 1, 1), 0}, {Size = UDim2.new(1, 0, 0, 2), AnchorPoint = Vector2.new(0, 0.5)})

			local function syncSliders()
				local c = state.Value
				for i = 1, 3 do
					sliders[i].Set(math.floor(c[keys[i]] * 255 + 0.5))
				end
			end

			local function refreshPalette()
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				cursor.Position = UDim2.fromScale(sat, 1 - val)
				hueMark.Position = UDim2.fromScale(0, h)
			end

			local function applyHSV()
				state.Set(Color3.fromHSV(h, sat, val), true)
				syncSliders()
				refreshPalette()
			end

			local function dragArea(target, fn)
				target.InputBegan:Connect(function(input)
					if not isPress(input) then
						return
					end
					win.Body.ScrollingEnabled = false
					fn(input.Position.X, input.Position.Y)
					beginDrag(input, function(pos)
						fn(pos.X, pos.Y)
					end, function()
						win.Body.ScrollingEnabled = true
					end)
				end)
			end

			dragArea(sv, function(x, y)
				local ap, as = sv.AbsolutePosition, sv.AbsoluteSize
				sat = clamp((x - ap.X) / math.max(as.X, 1), 0, 1)
				val = 1 - clamp((y - ap.Y) / math.max(as.Y, 1), 0, 1)
				applyHSV()
			end)
			dragArea(hue, function(_, y)
				local ap, as = hue.AbsolutePosition, hue.AbsoluteSize
				h = clamp((y - ap.Y) / math.max(as.Y, 1), 0, 1)
				applyHSV()
			end)

			for i = 1, 3 do
				local track = new("TextButton", {
					BackgroundColor3 = T.Frame[1],
					BackgroundTransparency = T.Frame[2],
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					Size = UDim2.new(1, 0, 0, FH),
					Position = UDim2.fromOffset(0, PAL + 6 + (i - 1) * (FH + 2))
				}, pop)
				sliders[i] = makeSlider(win, track, {
					Min = 0,
					Max = 255,
					Int = true,
					Format = names[i] .. " %d",
					Value = math.floor(state.Value[keys[i]] * 255 + 0.5),
					OnChange = function()
						local c = Color3.fromRGB(sliders[1].Value, sliders[2].Value, sliders[3].Value)
						state.Set(c, true)
						local nh, ns, nv = c:ToHSV()
						if ns > 0 then
							h = nh
						end
						sat, val = ns, nv
						refreshPalette()
					end
				})
			end
			local input = new("TextBox", {
				BackgroundColor3 = T.Frame[1],
				BackgroundTransparency = T.Frame[2],
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, FH),
				Position = UDim2.fromOffset(0, PAL + 6 + 3 * (FH + 2)),
				Font = FONT,
				TextSize = TS,
				TextColor3 = T.Text,
				Text = toHex(state.Value),
				ClearTextOnFocus = false
			}, pop)
			input.FocusLost:Connect(function()
				local ok, c = pcall(function()
					return Color3.fromHex(input.Text)
				end)
				if ok and c then
					state.Set(c, true)
					h, sat, val = c:ToHSV()
					syncSliders()
					refreshPalette()
				end
			end)
			refreshPalette()
		end)
	end)
	render()
	state.Frame = row
	return state
end

local function openEdit(track, initial, commit)
	local box = new("TextBox", {
		BackgroundColor3 = T.FrameActive[1],
		BackgroundTransparency = T.FrameActive[2],
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		Text = initial,
		ClearTextOnFocus = false,
		ZIndex = 5
	}, track)
	box.FocusLost:Connect(function()
		commit(box.Text)
		box:Destroy()
	end)
	box:CaptureFocus()
end

local function makeDrag(self, name, min, max, default, callback, speed, int, format)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local track = new("TextButton", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(iw, -4, 1, 0)
	}, row)
	local text = label(track, "", {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center})
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local state = {Value = default or min or 0}
	local function fmt(v)
		if format then
			return string.format(format, v)
		end
		return int and string.format("%d", v) or string.format("%.3f", v)
	end
	local function apply(v, fire)
		if min then
			v = math.max(v, min)
		end
		if max then
			v = math.min(v, max)
		end
		if int then
			v = math.floor(v + 0.5)
		else
			v = math.floor(v * 1000000 + 0.5) / 1000000
		end
		local changed = v ~= state.Value
		state.Value = v
		text.Text = fmt(v)
		if fire and changed and callback then
			task.spawn(callback, v)
		end
	end
	local hovered = false
	track.MouseEnter:Connect(function()
		hovered = true
		if not TOUCH then
			paint(track, T.FrameHover)
		end
	end)
	track.MouseLeave:Connect(function()
		hovered = false
		paint(track, T.Frame)
	end)
	track.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local base = state.Value
		local moved = false
		paint(track, T.FrameActive)
		win.Body.ScrollingEnabled = false
		beginDrag(input, function(pos)
			if not moved then
				if (pos - start).Magnitude < 5 then
					return
				end
				moved = true
			end
			apply(base + (pos.X - start.X) / win.Scale * speed, true)
		end, function()
			paint(track, hovered and not TOUCH and T.FrameHover or T.Frame)
			win.Body.ScrollingEnabled = true
			if not moved then
				openEdit(track, int and string.format("%d", state.Value) or tostring(state.Value), function(txt)
					local n = tonumber(txt)
					if n then
						apply(n, true)
					end
				end)
			end
		end)
	end)
	state.Set = apply
	function state.Get()
		return state.Value
	end
	state.Frame = row
	apply(state.Value)
	return state
end

function Container:DragFloat(name, min, max, default, callback, speed, format)
	return makeDrag(self, name, min, max, default, callback, speed or 0.01, false, format)
end

function Container:DragInt(name, min, max, default, callback, speed, format)
	return makeDrag(self, name, min, max, default, callback, speed or 0.2, true, format)
end

function Container:InputMultiline(name, default, callback, rows)
	if name and name ~= "" then
		self:Text(name)
	end
	rows = rows or 4
	local row = self:_row(rows * FH, true)
	local box = new("TextBox", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		Text = default or "",
		ClearTextOnFocus = false,
		MultiLine = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top
	}, row)
	pad(box, 4, 4, 3, 3)
	box.Focused:Connect(function()
		paint(box, T.FrameActive)
	end)
	box.FocusLost:Connect(function(enter)
		paint(box, T.Frame)
		if callback then
			task.spawn(callback, box.Text, enter)
		end
	end)
	local obj = {Frame = row, Box = box}
	function obj:Set(v)
		box.Text = tostring(v)
	end
	function obj:Get()
		return box.Text
	end
	return obj
end

function Container:Keybind(name, default, callback, onPress)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local btn = button(row, T.Frame, {Size = UDim2.new(iw, -4, 1, 0)})
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	bind(btn, T.Frame, T.FrameHover, T.FrameActive)
	local state = {Value = default, Frame = row, OnPress = onPress}
	local waiting = false
	local function render()
		if waiting then
			btn.Text = "按下按键..."
		else
			btn.Text = state.Value and state.Value.Name or "无"
		end
	end
	function state.Set(key, fire)
		state.Value = key
		waiting = false
		render()
		if fire and callback then
			task.spawn(callback, key)
		end
	end
	function state.Get()
		return state.Value
	end
	local function cancel()
		waiting = false
		render()
	end
	btn.MouseButton1Click:Connect(function()
		if waiting then
			cancel()
			Library.Waiting = nil
			return
		end
		if Library.Waiting then
			Library.Waiting.Cancel()
		end
		waiting = true
		render()
		Library.Waiting = {
			Cancel = cancel,
			Fn = function(key)
				Library.Waiting = nil
				if key == Enum.KeyCode.Escape then
					state.Set(nil, true)
				else
					state.Set(key, true)
				end
			end
		}
	end)
	Library.Binds[state] = true
	render()
	return state
end

function Container:Table(columns, rows, opts)
	opts = opts or {}
	local n = #columns
	local holder = self:_row(0, true)
	holder.AutomaticSize = Enum.AutomaticSize.Y
	list(holder, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	local TABLE_HEAD = tok(48, 48, 51, 0)
	local ALT = tok(255, 255, 255, 0.94)
	local head = frame(holder, TABLE_HEAD, {Size = UDim2.new(1, 0, 0, FH), LayoutOrder = 1})
	for i, name in columns do
		label(head, name, {
			Size = UDim2.new(1 / n, 0, 1, 0),
			Position = UDim2.fromScale((i - 1) / n, 0),
			TextXAlignment = Enum.TextXAlignment.Left
		}).Parent = head
	end
	local body
	if opts.Height then
		body = new("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, opts.Height),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = SB,
			ScrollBarImageColor3 = T.Scroll,
			LayoutOrder = 2
		}, holder)
	else
		body = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2
		}, holder)
	end
	list(body, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	stroke(holder, tok(79, 79, 89, 0))
	local obj = {Frame = holder, Count = 0}
	function obj:AddRow(cells)
		obj.Count = obj.Count + 1
		local r = frame(body, obj.Count % 2 == 0 and ALT or T.Clear, {Size = UDim2.new(1, 0, 0, FH), LayoutOrder = obj.Count})
		for i = 1, n do
			local cell = cells[i]
			local text, color = cell, T.Text
			if type(cell) == "table" then
				text, color = cell[1], cell[2] or T.Text
			end
			label(r, tostring(text == nil and "" or text), {
				Size = UDim2.new(1 / n, -4, 1, 0),
				Position = UDim2.new((i - 1) / n, 4, 0, 0),
				TextColor3 = color,
				TextTruncate = Enum.TextTruncate.AtEnd
			})
		end
		return r
	end
	function obj:Clear()
		for _, child in body:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		obj.Count = 0
	end
	function obj:SetRows(newRows)
		obj:Clear()
		for _, r in newRows do
			obj:AddRow(r)
		end
	end
	for _, r in rows or {} do
		obj:AddRow(r)
	end
	return obj
end

local function makePlot(self, name, values, height, vmin, vmax, overlay, histogram)
	local win = self.Win
	local row = self:_row(height or 40, true)
	local iw = self.ItemWidth or win.ItemWidth
	local area = frame(row, T.Frame, {Size = UDim2.new(name and iw or 1, name and -4 or 0, 1, 0), ClipsDescendants = true})
	local canvas = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, area)
	local overlayLabel
	if overlay then
		overlayLabel = label(area, overlay, {
			Size = UDim2.new(1, 0, 0, FH),
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 3
		})
	end
	if name then
		label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	end
	local obj = {Frame = row, Values = values or {}, Overlay = overlayLabel}
	local function draw()
		for _, child in canvas:GetChildren() do
			child:Destroy()
		end
		local v = obj.Values
		local n = #v
		if n == 0 then
			return
		end
		local lo, hi = vmin, vmax
		if lo == nil or hi == nil then
			lo, hi = math.huge, -math.huge
			for _, x in v do
				lo = math.min(lo, x)
				hi = math.max(hi, x)
			end
			if histogram then
				lo = math.min(lo, 0)
			end
			if hi == lo then
				hi = lo + 1
			end
		end
		local range = hi - lo
		if histogram then
			for i, x in v do
				local r = clamp((x - lo) / range, 0, 1)
				frame(canvas, T.Histogram, {
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.new((i - 1) / n, 0, 1, 0),
					Size = UDim2.new(1 / n, -1, r, 0)
				})
			end
			return
		end
		local w = area.AbsoluteSize.X / win.Scale
		local h = area.AbsoluteSize.Y / win.Scale
		if w <= 0 or n < 2 then
			return
		end
		local function point(i)
			local r = clamp((v[i] - lo) / range, 0, 1)
			return (i - 1) / (n - 1) * w, h - 3 - r * (h - 6)
		end
		for i = 1, n - 1 do
			local x1, y1 = point(i)
			local x2, y2 = point(i + 1)
			local dx, dy = x2 - x1, y2 - y1
			local len = math.sqrt(dx * dx + dy * dy)
			frame(canvas, {Color3.fromRGB(156, 156, 156), 0}, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
				Size = UDim2.fromOffset(len + 1, 1),
				Rotation = math.deg(math.atan2(dy, dx))
			})
		end
	end
	if not histogram then
		area:GetPropertyChangedSignal("AbsoluteSize"):Connect(draw)
	end
	function obj:Set(newValues)
		obj.Values = newValues
		draw()
	end
	function obj:Push(value, maxCount)
		table.insert(obj.Values, value)
		while #obj.Values > (maxCount or 60) do
			table.remove(obj.Values, 1)
		end
		draw()
	end
	draw()
	return obj
end

function Container:PlotLines(name, values, height, min, max, overlay)
	return makePlot(self, name, values, height, min, max, overlay, false)
end

function Container:PlotHistogram(name, values, height, min, max, overlay)
	return makePlot(self, name, values, height, min, max, overlay, true)
end

function Container:Avatar(user, size, opts)
	opts = opts or {}
	size = size or 64
	local row = self:_row(size, true)
	local holder = frame(row, T.Frame, {Size = UDim2.fromOffset(size, size)})
	stroke(holder, T.Border)
	if opts.Circle then
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, holder)
	end
	local img = new("ImageLabel", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Image = ""}, holder)
	local info
	if opts.ShowName ~= false then
		info = label(row, "", {
			Size = UDim2.new(1, -(size + 8), 1, 0),
			Position = UDim2.fromOffset(size + 8, 0),
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Center
		})
	end
	local obj = {Frame = row, Image = img}
	function obj:Set(target)
		task.spawn(function()
			local ok = pcall(function()
				local id = target
				if id == nil then
					id = Players.LocalPlayer.UserId
				elseif type(id) == "string" then
					id = Players:GetUserIdFromNameAsync(id)
				elseif typeof(id) == "Instance" then
					id = id.UserId
				end
				local content = Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180)
				img.Image = content
				obj.UserId = id
				if info then
					local name = Players:GetNameFromUserIdAsync(id)
					local display = name
					local plr = Players:GetPlayerByUserId(id)
					if plr then
						display = plr.DisplayName
					end
					info.Text = display .. "\n@" .. name
				end
			end)
			if not ok and info then
				info.Text = "无法加载头像"
			end
		end)
	end
	obj:Set(user)
	return obj
end

function Container:RangeSlider(name, min, max, low, high, callback, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local track = new("TextButton", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(iw, -4, 1, 0)
	}, row)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local fill = frame(track, {T.Grab[1], 0.6}, {Size = UDim2.new(0, 0, 1, -2), Position = UDim2.new(0, 0, 0, 1)})
	local gl = frame(track, T.Grab, {Size = UDim2.new(0, GW, 1, -2)})
	local gh = frame(track, T.Grab, {Size = UDim2.new(0, GW, 1, -2)})
	local text = label(track, "", {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3})
	local state = {Low = clamp(low or min, min, max), High = clamp(high or max, min, max), Frame = row}

	local function fmt(v)
		if opts.Format then
			return string.format(opts.Format, v)
		end
		return opts.Int and string.format("%d", v) or string.format("%.2f", v)
	end

	local function norm(v)
		if opts.Int then
			return math.floor(v + 0.5)
		end
		return math.floor(v * 1000000 + 0.5) / 1000000
	end

	local function render()
		local range = math.max(max - min, 1e-9)
		local rl = clamp((state.Low - min) / range, 0, 1)
		local rh = clamp((state.High - min) / range, 0, 1)
		gl.Position = UDim2.new(rl, -rl * GW, 0, 1)
		gh.Position = UDim2.new(rh, -rh * GW, 0, 1)
		fill.Position = UDim2.new(rl, GW / 2, 0, 1)
		fill.Size = UDim2.new(math.max(rh - rl, 0), 0, 1, -2)
		text.Text = fmt(state.Low) .. " - " .. fmt(state.High)
	end

	function state.Set(a, b, fire)
		a = norm(clamp(a, min, max))
		b = norm(clamp(b, min, max))
		if a > b then
			a, b = b, a
		end
		local changed = a ~= state.Low or b ~= state.High
		state.Low, state.High = a, b
		render()
		if fire and changed and callback then
			task.spawn(callback, a, b)
		end
	end

	function state.Get()
		return state.Low, state.High
	end

	local function valueAt(x)
		local scale = win.Scale
		local abs = track.AbsolutePosition.X
		local w = track.AbsoluteSize.X
		local r = clamp((x - abs - GW / 2 * scale) / math.max(w - GW * scale, 1), 0, 1)
		return min + (max - min) * r
	end

	track.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local v = valueAt(input.Position.X)
		local pickLow = math.abs(v - state.Low) < math.abs(v - state.High) or (v <= state.Low)
		win.Body.ScrollingEnabled = false
		paint(track, T.FrameActive)
		local function update(x)
			local value = valueAt(x)
			if pickLow then
				state.Set(math.min(value, state.High), state.High, true)
			else
				state.Set(state.Low, math.max(value, state.Low), true)
			end
		end
		update(input.Position.X)
		beginDrag(input, function(pos)
			update(pos.X)
		end, function()
			paint(track, T.Frame)
			win.Body.ScrollingEnabled = true
		end)
	end)
	render()
	return state
end

function Container:InputVector(name, count, defaults, callback, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(iw, -4, 1, 0)}, row)
	list(holder, 2, true)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local state = {Values = {}, Frame = row}
	local boxes = {}
	local function fmt(v)
		if opts.Int then
			return string.format("%d", v)
		end
		return tostring(math.floor(v * 1000 + 0.5) / 1000)
	end
	for i = 1, count do
		state.Values[i] = (defaults and defaults[i]) or 0
		local box = new("TextBox", {
			BackgroundColor3 = T.Frame[1],
			BackgroundTransparency = T.Frame[2],
			BorderSizePixel = 0,
			Size = UDim2.new(1 / count, -2 * (count - 1) / count, 1, 0),
			Font = FONT,
			TextSize = TS,
			TextColor3 = T.Text,
			Text = fmt(state.Values[i]),
			ClearTextOnFocus = false,
			LayoutOrder = i,
			TextXAlignment = Enum.TextXAlignment.Center
		}, holder)
		boxes[i] = box
		box.Focused:Connect(function()
			paint(box, T.FrameActive)
		end)
		box.FocusLost:Connect(function()
			paint(box, T.Frame)
			local n = tonumber(box.Text)
			if n then
				if opts.Int then
					n = math.floor(n + 0.5)
				end
				state.Values[i] = n
				if callback then
					task.spawn(callback, table.clone(state.Values))
				end
			end
			box.Text = fmt(state.Values[i])
		end)
	end
	function state.Set(values, fire)
		for i = 1, count do
			state.Values[i] = values[i] or state.Values[i]
			boxes[i].Text = fmt(state.Values[i])
		end
		if fire and callback then
			task.spawn(callback, table.clone(state.Values))
		end
	end
	function state.Get()
		return table.clone(state.Values)
	end
	return state
end

function Container:InputVector2(name, defaults, callback, opts)
	return self:InputVector(name, 2, defaults, callback, opts)
end

function Container:InputVector3(name, defaults, callback, opts)
	return self:InputVector(name, 3, defaults, callback, opts)
end

local ThumbCache = {}

local function loadThumb(img, userId)
	if ThumbCache[userId] then
		img.Image = ThumbCache[userId]
		return
	end
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and content then
			ThumbCache[userId] = content
			if img.Parent then
				img.Image = content
			end
		end
	end)
end

function Container:PlayerCombo(name, callback, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local state = {Value = nil, Frame = row}
	local box = button(row, T.Frame, {
		Size = UDim2.new(iw, -4, 1, 0),
		Text = "选择玩家",
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true
	})
	pad(box, FH + 2, FH, 0, 0)
	local mini = new("ImageLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(FH - 4, FH - 4),
		Position = UDim2.fromOffset(-(FH - 2), 2),
		Visible = false
	}, box)
	local arrowBox = frame(box, T.Button, {Size = UDim2.fromOffset(FH, FH), Position = UDim2.new(1, 0, 0, 0)})
	icon(arrowBox, "Right", {Size = UDim2.fromOffset(FH - 8, FH - 8), Position = UDim2.fromOffset(4, 4), Rotation = 90})
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	bind(box, T.Frame, T.FrameHover, T.FrameActive)

	local function render()
		if state.Value then
			box.Text = state.Value.Name
			mini.Visible = true
			loadThumb(mini, state.Value.UserId)
		else
			box.Text = "选择玩家"
			mini.Visible = false
		end
	end

	function state.Set(player, fire)
		state.Value = player
		render()
		if fire and callback then
			task.spawn(callback, player)
		end
	end
	function state.Get()
		return state.Value
	end

	table.insert(Library.Conns, Players.PlayerRemoving:Connect(function(plr)
		if state.Value == plr then
			state.Set(nil, true)
		end
	end))

	box.MouseButton1Click:Connect(function()
		local players = {}
		for _, plr in Players:GetPlayers() do
			if opts.IncludeSelf ~= false or plr ~= Players.LocalPlayer then
				table.insert(players, plr)
			end
		end
		table.sort(players, function(a, b)
			return a.Name:lower() < b.Name:lower()
		end)
		local visible = math.max(math.min(#players, 7), 1)
		local height = visible * (FH + 2) + 4
		win:_popup(box, box.AbsoluteSize.X / win.Scale, height, function(pop)
			local scroll = new("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = SB,
				ScrollBarImageColor3 = T.Scroll
			}, pop)
			pad(scroll, 2, 2, 2, 2)
			list(scroll, 0).VerticalAlignment = Enum.VerticalAlignment.Top
			if #players == 0 then
				label(scroll, "没有玩家", {Size = UDim2.new(1, 0, 0, FH), TextColor3 = T.TextDisabled})
			end
			for i, plr in players do
				local selected = plr == state.Value
				local normal = selected and T.Header or T.Clear
				local b = button(scroll, normal, {
					Size = UDim2.new(1, 0, 0, FH + 2),
					Text = plr.Name,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = i
				})
				pad(b, FH + 6, 4, 0, 0)
				bind(b, normal, T.HeaderHover, T.HeaderActive)
				local thumb = new("ImageLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromOffset(FH - 2, FH - 2),
					Position = UDim2.fromOffset(-(FH + 2), 1)
				}, b)
				loadThumb(thumb, plr.UserId)
				b.MouseButton1Click:Connect(function()
					win:_closePopup()
					state.Set(plr, true)
				end)
			end
		end)
	end)
	render()
	return state
end

local LEVELS = {
	Info = Color3.fromRGB(255, 255, 255),
	Warn = Color3.fromRGB(240, 190, 60),
	Error = Color3.fromRGB(240, 90, 90),
	Success = Color3.fromRGB(80, 220, 120),
	Debug = Color3.fromRGB(128, 160, 220)
}

function Container:Console(height, opts)
	opts = opts or {}
	local row = self:_row(height or 120, true)
	local back = frame(row, T.Inset, {Size = UDim2.fromScale(1, 1)})
	stroke(back, T.Border)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, back)
	pad(scroll, 4, 4, 2, 2)
	list(scroll, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	local obj = {Frame = row, Count = 0, Max = opts.MaxLines or 200, AutoScroll = opts.AutoScroll ~= false}
	local order = 0
	function obj:Log(text, level)
		order = order + 1
		obj.Count = obj.Count + 1
		local prefix = opts.Timestamp == false and "" or ("[" .. os.date("%H:%M:%S") .. "] ")
		label(scroll, prefix .. tostring(text), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = LEVELS[level or "Info"] or LEVELS.Info,
			LayoutOrder = order
		})
		if obj.Count > obj.Max then
			for _, child in scroll:GetChildren() do
				if child:IsA("TextLabel") then
					child:Destroy()
					obj.Count = obj.Count - 1
					break
				end
			end
		end
		if obj.AutoScroll then
			task.defer(function()
				scroll.CanvasPosition = Vector2.new(0, 1e6)
			end)
		end
	end
	function obj:Info(t)
		obj:Log(t, "Info")
	end
	function obj:Warn(t)
		obj:Log(t, "Warn")
	end
	function obj:Error(t)
		obj:Log(t, "Error")
	end
	function obj:Success(t)
		obj:Log(t, "Success")
	end
	function obj:Clear()
		for _, child in scroll:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		obj.Count = 0
	end
	return obj
end

function Container:SortableList(name, items, callback, opts)
	opts = opts or {}
	local win = self.Win
	if name and name ~= "" then
		self:Text(name)
	end
	local rows = opts.Rows or 5
	local holder = self:_row(rows * FH + 4, true)
	local back = frame(holder, T.Frame, {Size = UDim2.fromScale(1, 1)})
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, back)
	pad(scroll, 2, 2, 2, 2)
	list(scroll, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	local obj = {Frame = holder, Entries = {}}

	local function relayout()
		for i, e in obj.Entries do
			e.Frame.LayoutOrder = i
			e.Number.Text = tostring(i)
		end
	end

	local function values()
		local out = {}
		for _, e in obj.Entries do
			table.insert(out, e.Text)
		end
		return out
	end

	local function add(text)
		local e = {Text = text}
		local rowF = frame(scroll, T.Clear, {Size = UDim2.new(1, 0, 0, FH)})
		local handle = button(rowF, T.Button, {Size = UDim2.fromOffset(FH, FH)})
		for i = 0, 2 do
			frame(handle, {T.Text, 0.2}, {Size = UDim2.new(1, -8, 0, 1), Position = UDim2.fromOffset(4, 5 + i * 4)})
		end
		bind(handle, T.Button, T.ButtonHover, T.ButtonActive)
		e.Number = label(rowF, "", {
			Size = UDim2.fromOffset(18, FH),
			Position = UDim2.fromOffset(FH + 2, 0),
			TextColor3 = T.TextDisabled,
			TextXAlignment = Enum.TextXAlignment.Right
		})
		label(rowF, tostring(text), {
			Size = UDim2.new(1, -(FH + 28), 1, 0),
			Position = UDim2.fromOffset(FH + 26, 0)
		})
		e.Frame = rowF
		table.insert(obj.Entries, e)
		handle.InputBegan:Connect(function(input)
			if not isPress(input) then
				return
			end
			win.Body.ScrollingEnabled = false
			scroll.ScrollingEnabled = false
			paint(rowF, T.Header)
			beginDrag(input, function(pos)
				local top = scroll.AbsolutePosition.Y
				local rel = (pos.Y - top) / win.Scale + scroll.CanvasPosition.Y - 2
				local target = clamp(math.floor(rel / FH) + 1, 1, #obj.Entries)
				local current
				for i, x in obj.Entries do
					if x == e then
						current = i
					end
				end
				if current and target ~= current then
					table.remove(obj.Entries, current)
					table.insert(obj.Entries, target, e)
					relayout()
				end
			end, function()
				paint(rowF, T.Clear)
				scroll.ScrollingEnabled = true
				win.Body.ScrollingEnabled = true
				if callback then
					task.spawn(callback, values())
				end
			end)
		end)
	end

	function obj.Set(newItems, fire)
		for _, e in obj.Entries do
			e.Frame:Destroy()
		end
		obj.Entries = {}
		for _, text in newItems do
			add(text)
		end
		relayout()
		if fire and callback then
			task.spawn(callback, values())
		end
	end
	function obj.Get()
		return values()
	end
	obj.Set(items or {})
	return obj
end

function Container:TreeView(nodes, callback, opts)
	opts = opts or {}
	local holder = self:_row((opts.Rows or 6) * FH + 4, true)
	local back = frame(holder, T.Frame, {Size = UDim2.fromScale(1, 1)})
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, back)
	pad(scroll, 2, 2, 2, 2)
	list(scroll, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	local obj = {Frame = holder, Nodes = nodes or {}, Selected = nil}
	local rebuild

	local function addRows(list_, depth, order)
		for _, node in list_ do
			order = order + 1
			local hasKids = node.Children and #node.Children > 0
			local selected = node == obj.Selected
			local normal = selected and T.Header or T.Clear
			local b = button(scroll, normal, {
				Size = UDim2.new(1, 0, 0, FH),
				Text = tostring(node.Text),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = order
			})
			pad(b, FH + depth * 14 + 2, 4, 0, 0)
			bind(b, normal, T.HeaderHover, T.HeaderActive)
			if hasKids then
				icon(b, "Right", {
					Size = UDim2.fromOffset(FH - 8, FH - 8),
					Position = UDim2.fromOffset(-(FH + 2) + 2, 4),
					Rotation = node.Open and 90 or 0
				})
			end
			b.MouseButton1Click:Connect(function()
				if hasKids then
					node.Open = not node.Open
				end
				obj.Selected = node
				rebuild()
				if callback then
					task.spawn(callback, node)
				end
			end)
			if hasKids and node.Open then
				order = addRows(node.Children, depth + 1, order)
			end
		end
		return order
	end

	function rebuild()
		for _, child in scroll:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		addRows(obj.Nodes, 0, 0)
	end

	function obj.SetNodes(newNodes)
		obj.Nodes = newNodes
		obj.Selected = nil
		rebuild()
	end
	function obj.Select(node)
		obj.Selected = node
		rebuild()
	end
	function obj.Get()
		return obj.Selected
	end
	rebuild()
	return obj
end

local KEYWORDS = {}
for _, k in {"and", "break", "continue", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"} do
	KEYWORDS[k] = true
end
local BUILTINS = {}
for _, k in {"game", "workspace", "script", "print", "warn", "error", "pairs", "ipairs", "next", "type", "typeof", "tostring", "tonumber", "table", "string", "math", "task", "require", "pcall", "Instance", "Vector3", "Vector2", "CFrame", "Color3", "UDim2", "Enum", "self"} do
	BUILTINS[k] = true
end

local function escapeRich(str)
	return (str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function highlight(source)
	local out = {}
	local i, n = 1, #source
	local function push(text, color)
		if color then
			table.insert(out, '<font color="' .. color .. '">' .. escapeRich(text) .. "</font>")
		else
			table.insert(out, escapeRich(text))
		end
	end
	while i <= n do
		local c = source:sub(i, i)
		if source:sub(i, i + 1) == "--" then
			local e = source:find("\n", i, true) or n + 1
			push(source:sub(i, e - 1), "#6a9955")
			i = e
		elseif c == '"' or c == "'" then
			local j = i + 1
			while j <= n do
				local d = source:sub(j, j)
				if d == "\\" then
					j = j + 2
				elseif d == c or d == "\n" then
					break
				else
					j = j + 1
				end
			end
			push(source:sub(i, j), "#ce9178")
			i = j + 1
		elseif c:match("%d") then
			local num = source:match("^%d+%.?%d*", i)
			push(num, "#b5cea8")
			i = i + #num
		elseif c:match("[%a_]") then
			local word = source:match("^[%w_]+", i)
			if KEYWORDS[word] then
				push(word, "#569cd6")
			elseif BUILTINS[word] then
				push(word, "#4ec9b0")
			else
				push(word)
			end
			i = i + #word
		else
			push(c)
			i = i + 1
		end
	end
	return table.concat(out)
end

function Container:CodeBox(text, height, opts)
	opts = opts or {}
	local win = self.Win
	local holder = self:_row(height or 120, true)
	local back = frame(holder, T.Inset, {Size = UDim2.fromScale(1, 1)})
	stroke(back, T.Border)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, back)
	pad(scroll, 4, 4, 3, 3)
	local inner = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY
	}, scroll)
	list(inner, 6, true).VerticalAlignment = Enum.VerticalAlignment.Top
	local numbers
	if opts.LineNumbers ~= false then
		numbers = label(inner, "", {
			Size = UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			TextColor3 = T.TextDisabled,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 1
		})
	end
	local code = label(inner, "", {
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		RichText = true,
		TextWrapped = false,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2
	})
	local obj = {Frame = holder, Text = text or ""}
	function obj.Set(v)
		obj.Text = tostring(v)
		if opts.Highlight ~= false then
			code.Text = highlight(obj.Text)
		else
			code.RichText = false
			code.Text = obj.Text
		end
		if numbers then
			local lines = {}
			local count = select(2, obj.Text:gsub("\n", "\n")) + 1
			for i = 1, count do
				lines[i] = tostring(i)
			end
			numbers.Text = table.concat(lines, "\n")
		end
	end
	function obj.Get()
		return obj.Text
	end
	if opts.Copy ~= false and setclipboard then
		local copy = button(back, T.Button, {
			Size = UDim2.fromOffset(34, FH - 3),
			Position = UDim2.new(1, -40, 0, 3),
			Text = "复制",
			TextSize = TS - 2,
			ZIndex = 5
		})
		bind(copy, T.Button, T.ButtonHover, T.ButtonActive)
		copy.MouseButton1Click:Connect(function()
			pcall(setclipboard, obj.Text)
		end)
	end
	obj.Set(text or "")
	return obj
end

function Container:Radar(size, range, opts)
	opts = opts or {}
	size = size or 130
	range = range or 100
	local holder = self:_row(size + 4, true)
	local area = frame(holder, T.Frame, {
		Size = UDim2.fromOffset(size, size),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 2),
		ClipsDescendants = true
	})
	new("UICorner", {CornerRadius = UDim.new(1, 0)}, area)
	stroke(area, T.Border)
	for _, f in {0.34, 0.67} do
		local ring = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(f, f),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5)
		}, area)
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, ring)
		stroke(ring, T.Separator)
	end
	frame(area, T.Separator, {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0)})
	frame(area, T.Separator, {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0.5, 0, 0, 0)})
	local me = frame(area, {T.CheckMark, 0}, {
		Size = UDim2.fromOffset(6, 6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 3
	})
	new("UICorner", {CornerRadius = UDim.new(1, 0)}, me)
	local info = label(holder, "", {Size = UDim2.new(0.3, 0, 0, FH), TextColor3 = T.TextDisabled})
	local obj = {Frame = holder, Range = range, Pool = {}}
	local function refreshInfo()
		info.Text = string.format("范围 %d", obj.Range)
	end

	function obj.SetPoints(points)
		for i, pt in points do
			local dot = obj.Pool[i]
			if not dot then
				dot = frame(area, {Color3.fromRGB(240, 90, 90), 0}, {
					Size = UDim2.fromOffset(5, 5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					ZIndex = 2
				})
				new("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
				obj.Pool[i] = dot
			end
			local rx, ry = pt.X / obj.Range, pt.Y / obj.Range
			local mag = math.sqrt(rx * rx + ry * ry)
			dot.BackgroundTransparency = 0
			if mag > 1 then
				rx, ry = rx / mag, ry / mag
				dot.BackgroundTransparency = 0.55
			end
			dot.Position = UDim2.fromScale(0.5 + rx * 0.47, 0.5 - ry * 0.47)
			dot.BackgroundColor3 = pt.Color or Color3.fromRGB(240, 90, 90)
			dot.Visible = true
		end
		for i = #points + 1, #obj.Pool do
			obj.Pool[i].Visible = false
		end
	end

	function obj.SetRange(r)
		obj.Range = r
		refreshInfo()
	end

	function obj.Update()
		pcall(function()
			local me_ = Players.LocalPlayer
			local root = me_.Character and me_.Character:FindFirstChild("HumanoidRootPart")
			local cam = workspace.CurrentCamera
			if not root or not cam then
				return
			end
			local look = cam.CFrame.LookVector
			local fwd = Vector3.new(look.X, 0, look.Z)
			if fwd.Magnitude < 0.01 then
				return
			end
			fwd = fwd.Unit
			local right = Vector3.new(-fwd.Z, 0, fwd.X) * -1
			local points = {}
			for _, plr in Players:GetPlayers() do
				if plr ~= me_ and plr.Character then
					local r = plr.Character:FindFirstChild("HumanoidRootPart")
					if r then
						local off = r.Position - root.Position
						local color = Color3.fromRGB(240, 90, 90)
						if plr.Team then
							color = plr.TeamColor.Color
						end
						table.insert(points, {X = off:Dot(right), Y = off:Dot(fwd), Color = color})
					end
				end
			end
			obj.SetPoints(points)
		end)
	end

	if opts.Players ~= false then
		local acc = 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not holder.Parent then
				conn:Disconnect()
				return
			end
			acc = acc + dt
			if acc >= (opts.Interval or 0.1) then
				acc = 0
				obj.Update()
			end
		end)
		table.insert(Library.Conns, conn)
	end
	refreshInfo()
	return obj
end

function Container:Gauge(name, value, size, opts)
	opts = opts or {}
	size = size or 110
	local R = size / 2 - 4
	local cx, cy = size / 2, size / 2
	local holder = self:_row(cy + 30, true)
	local area = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, cy + 30),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0)
	}, holder)
	local N = 30
	local segs = {}
	for i = 1, N do
		local theta = math.pi * (1 - (i - 0.5) / N)
		local x = cx + R * math.cos(theta)
		local y = cy - R * math.sin(theta)
		local dx, dy = -math.sin(theta), -math.cos(theta)
		segs[i] = frame(area, T.Frame, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(math.pi * R / N + 1.5, 7),
			Rotation = math.deg(math.atan2(dy, dx))
		})
	end
	local valueLabel = label(area, "", {
		Size = UDim2.fromOffset(size, FH),
		Position = UDim2.fromOffset(0, cy - FH + 4),
		TextXAlignment = Enum.TextXAlignment.Center
	})
	label(area, name or "", {
		Size = UDim2.fromOffset(size, FH),
		Position = UDim2.fromOffset(0, cy + 6),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = T.TextDisabled
	})
	local obj = {Frame = holder, Value = 0}
	function obj.Set(v, text)
		v = clamp(v, 0, 1)
		obj.Value = v
		local filled = math.floor(v * N + 0.5)
		local color = opts.Color or T.Histogram[1]
		if opts.Auto then
			color = v < 0.3 and Color3.fromRGB(240, 90, 90) or (v < 0.6 and Color3.fromRGB(240, 190, 60) or Color3.fromRGB(80, 220, 120))
		end
		for i = 1, N do
			if i <= filled then
				segs[i].BackgroundColor3 = color
				segs[i].BackgroundTransparency = 0
			else
				paint(segs[i], T.Frame)
			end
		end
		valueLabel.Text = text or string.format("%d%%", v * 100)
	end
	obj.Set(value or 0)
	return obj
end

function Container:SlideConfirm(text, callback, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH + 4, true)
	local track = frame(row, T.Frame, {Size = UDim2.fromScale(1, 1)})
	local fill = frame(track, T.Header, {Size = UDim2.new(0, FH + 8, 1, 0)})
	label(track, text or "滑动确认", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = T.TextDisabled
	})
	local KW = FH + 8
	local knob = button(track, T.Button, {Size = UDim2.new(0, KW, 1, 0), ZIndex = 3})
	icon(knob, "Right", {
		Size = UDim2.fromOffset(FH - 6, FH - 6),
		Position = UDim2.new(0.5, -(FH - 6) / 2, 0.5, -(FH - 6) / 2),
		ZIndex = 4
	})
	bind(knob, T.Button, T.ButtonHover, T.ButtonActive)
	local ratio = 0
	local function setRatio(r)
		ratio = r
		knob.Position = UDim2.new(r, -r * KW, 0, 0)
		fill.Size = UDim2.new(r, KW * (1 - r), 1, 0)
	end
	knob.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		win.Body.ScrollingEnabled = false
		beginDrag(input, function(pos)
			local ap, as = track.AbsolutePosition, track.AbsoluteSize
			local usable = math.max(as.X - KW * win.Scale, 1)
			setRatio(clamp((pos.X - ap.X - KW / 2 * win.Scale) / usable, 0, 1))
		end, function()
			win.Body.ScrollingEnabled = true
			if ratio >= 0.95 then
				fill.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
				if callback then
					task.spawn(callback)
				end
				task.delay(0.4, function()
					fill.BackgroundColor3 = T.Header[1]
					setRatio(0)
				end)
			else
				setRatio(0)
			end
		end)
	end)
	setRatio(0)
	return {Frame = row}
end

function Container:HoldButton(text, duration, callback, color)
	duration = duration or 1
	local row = self:_row(FH)
	local n, h, p = T.Button, T.ButtonHover, T.ButtonActive
	if color then
		n, h, p = colorTokens(color)
	end
	local btn = button(row, n, {Size = UDim2.new(0, textWidth(text) + 16, 1, 0), ClipsDescendants = true})
	local fill = frame(btn, {Color3.new(1, 1, 1), 0.7}, {Size = UDim2.new(0, 0, 1, 0), ZIndex = 2})
	label(btn, text, {Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3})
	bind(btn, n, h, p)
	btn.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local start = os.clock()
		local done = false
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local r = clamp((os.clock() - start) / duration, 0, 1)
			fill.Size = UDim2.new(r, 0, 1, 0)
			if r >= 1 and not done then
				done = true
				conn:Disconnect()
				fill.Size = UDim2.new(0, 0, 1, 0)
				if callback then
					task.spawn(callback)
				end
			end
		end)
		beginDrag(input, function() end, function()
			conn:Disconnect()
			fill.Size = UDim2.new(0, 0, 1, 0)
		end)
	end)
	return {Frame = row, Button = btn}
end

function Container:Monitor(height, opts)
	opts = opts or {}
	local plot = makePlot(self, nil, {}, height or 48, 0, opts.Max or 120, "", false)
	local obj = {Frame = plot.Frame, Plot = plot}
	local frames, elapsed = 0, 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not plot.Frame.Parent then
			conn:Disconnect()
			return
		end
		frames = frames + 1
		elapsed = elapsed + dt
		if elapsed >= (opts.Interval or 0.5) then
			local fps = frames / elapsed
			frames, elapsed = 0, 0
			local ping = 0
			pcall(function()
				ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			obj.Fps, obj.Ping = fps, ping
			plot:Push(fps, opts.History or 60)
			plot.Overlay.Text = string.format("FPS %d   Ping %dms", fps, ping)
		end
	end)
	table.insert(Library.Conns, conn)
	return obj
end

function Container:CommandPalette(commands, text)
	local win = self.Win
	for _, c in commands or {} do
		table.insert(win.Registry, {Name = c.Name, Callback = c.Callback, Group = c.Group or "命令"})
	end
	return self:Button(text or "命令面板", function()
		win.Lib:Palette()
	end)
end

function Container:ConfigManager(opts)
	opts = opts or {}
	local win = self.Win
	local lib = win.Lib
	local folder = opts.Folder or "ImGuiConfigs"
	local canFile = writefile and readfile and isfile and isfolder and makefolder and listfiles and true or false
	lib.Mem = lib.Mem or {}
	lib.Mem[folder] = lib.Mem[folder] or {}
	local obj = {Folder = folder}

	local function snapshot()
		local data = {}
		for _, e in win.Tracked do
			local ok, v = pcall(e.Get)
			if ok then
				data[e.Key] = v
			end
		end
		return data
	end

	local function apply(data)
		local count = 0
		for _, e in win.Tracked do
			if data[e.Key] ~= nil then
				if pcall(e.Set, data[e.Key]) then
					count = count + 1
				end
			end
		end
		return count
	end

	local function ensure()
		if canFile and not isfolder(folder) then
			makefolder(folder)
		end
	end

	function obj.List()
		local out = {}
		if canFile then
			ensure()
			for _, f in listfiles(folder) do
				local n = tostring(f):match("([^/\\]+)%.json$")
				if n then
					table.insert(out, n)
				end
			end
		else
			for n in lib.Mem[folder] do
				table.insert(out, n)
			end
		end
		table.sort(out)
		return out
	end

	function obj.Save(name)
		local json = HttpService:JSONEncode(snapshot())
		if canFile then
			ensure()
			writefile(folder .. "/" .. name .. ".json", json)
		else
			lib.Mem[folder][name] = json
		end
		return json
	end

	function obj.Read(name)
		if canFile then
			local path = folder .. "/" .. name .. ".json"
			if isfile(path) then
				return readfile(path)
			end
			return nil
		end
		return lib.Mem[folder][name]
	end

	function obj.Load(name)
		local json = obj.Read(name)
		if not json then
			return false
		end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(json)
		end)
		if not ok or type(data) ~= "table" then
			return false
		end
		apply(data)
		return true
	end

	function obj.Delete(name)
		if canFile then
			local path = folder .. "/" .. name .. ".json"
			if isfile(path) and delfile then
				delfile(path)
			end
		else
			lib.Mem[folder][name] = nil
		end
	end

	function obj.Export()
		return HttpService:JSONEncode(snapshot())
	end

	function obj.Import(json)
		local ok, data = pcall(function()
			return HttpService:JSONDecode(json)
		end)
		if ok and type(data) == "table" then
			return apply(data)
		end
		return 0
	end

	win._noTrack = true
	local nameBox
	local combo
	local function refresh(select)
		local names = obj.List()
		combo.SetItems(names)
		if select then
			combo.Set(select, false)
		elseif #names == 0 then
			combo.Set("", false)
		end
	end
	combo = self:Combo("配置列表", obj.List(), nil, function(v)
		nameBox:Set(v)
	end)
	nameBox = self:InputText("配置名称", opts.Default or "default", nil, "名称")
	local r1 = self:Row()
	r1:Button("保存", function()
		local name = nameBox:Get()
		if name == "" then
			lib:Notify({Title = "配置", Content = "请输入配置名称", Type = "Warn"})
			return
		end
		obj.Save(name)
		refresh(name)
		lib:Notify({Title = "配置", Content = "已保存：" .. name, Type = "Success"})
	end)
	r1:Button("读取", function()
		local name = nameBox:Get()
		if obj.Load(name) then
			lib:Notify({Title = "配置", Content = "已读取：" .. name, Type = "Success"})
		else
			lib:Notify({Title = "配置", Content = "找不到配置：" .. name, Type = "Error"})
		end
	end)
	r1:Button("删除", function()
		local name = nameBox:Get()
		lib:Confirm("删除配置", "确定删除配置“" .. name .. "”吗？", function()
			obj.Delete(name)
			refresh()
			lib:Notify({Title = "配置", Content = "已删除：" .. name})
		end)
	end, Color3.fromRGB(170, 60, 60))
	r1:Button("刷新", function()
		refresh()
	end)
	local r2 = self:Row()
	r2:Button("导出到剪贴板", function()
		local json = obj.Export()
		if setclipboard then
			pcall(setclipboard, json)
			lib:Notify({Title = "配置", Content = "已复制到剪贴板", Type = "Success"})
		else
			lib:Notify({Title = "配置", Content = "当前环境不支持剪贴板", Type = "Warn"})
		end
	end)
	r2:Button("导入", function()
		lib:Prompt("导入配置", "粘贴配置内容：", "", function(text)
			local n = obj.Import(text or "")
			lib:Notify({Title = "配置", Content = n > 0 and ("已导入 " .. n .. " 项") or "内容无效", Type = n > 0 and "Success" or "Error"})
		end)
	end)
	win._noTrack = false
	obj.Combo = combo
	obj.NameBox = nameBox
	refresh()
	return obj
end

function Container:Badge(text, color)
	local row = self:_row(FH)
	local obj = {Frame = row}
	local pill = frame(row, {color or Color3.fromRGB(66, 150, 250), 0}, {
		Size = UDim2.fromOffset(textWidth(text) + 12, FH - 3),
		Position = UDim2.fromOffset(0, 1)
	})
	local txt = label(pill, text, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.new(1, 1, 1)
	})
	function obj.Set(str, c)
		txt.Text = str
		pill.Size = UDim2.fromOffset(textWidth(str) + 12, FH - 3)
		if c then
			pill.BackgroundColor3 = c
		end
	end
	return obj
end

function Container:Spinner(text, opts)
	opts = opts or {}
	local row = self:_row(FH + 4)
	local N = 8
	local R = 6
	local box = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(FH, FH + 4)
	}, row)
	local dots = {}
	for i = 1, N do
		local a = (i - 1) / N * math.pi * 2
		local d = frame(box, T.CheckMark and {T.CheckMark, 0} or T.Grab, {
			Size = UDim2.fromOffset(3, 3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(FH / 2 + math.sin(a) * R, (FH + 4) / 2 - math.cos(a) * R)
		})
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, d)
		dots[i] = d
	end
	local txt = label(row, text or "加载中...", {
		Size = UDim2.new(1, -(FH + 4), 1, 0),
		Position = UDim2.fromOffset(FH + 4, 0),
		TextColor3 = T.TextDisabled
	})
	local obj = {Frame = row, Active = true}
	local phase = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not row.Parent then
			conn:Disconnect()
			return
		end
		if not obj.Active then
			return
		end
		phase = (phase + dt * (opts.Speed or 8)) % N
		for i = 1, N do
			local k = (phase - (i - 1)) % N
			dots[i].BackgroundColor3 = T.Grab[1]
			dots[i].BackgroundTransparency = clamp(k / N, 0, 0.9)
		end
	end)
	table.insert(Library.Conns, conn)
	function obj.SetText(str)
		txt.Text = str
	end
	function obj.SetActive(v)
		obj.Active = v and true or false
		box.Visible = obj.Active
	end
	return obj
end

function Container:Skeleton(lines, opts)
	opts = opts or {}
	lines = lines or 3
	local h = lines * (FH - 3) + (lines - 1) * 4
	local row = self:_row(h, true)
	local bars = {}
	for i = 1, lines do
		local w = i == lines and 0.6 or 1
		bars[i] = frame(row, T.Frame, {
			Size = UDim2.new(w, 0, 0, FH - 3),
			Position = UDim2.fromOffset(0, (i - 1) * (FH + 1))
		})
	end
	local obj = {Frame = row, Active = true}
	local t0 = 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not row.Parent then
			conn:Disconnect()
			return
		end
		if not obj.Active then
			return
		end
		t0 = t0 + dt
		for i, b in bars do
			b.BackgroundTransparency = 0.45 + 0.25 * math.sin(t0 * 3 - i * 0.6)
		end
	end)
	table.insert(Library.Conns, conn)
	function obj.SetActive(v)
		obj.Active = v and true or false
		row.Visible = obj.Active
	end
	return obj
end

function Container:Prompt(title, message, default, onSubmit, onCancel, opts)
	return self.Win.Lib:Prompt(title, message, default, onSubmit, onCancel, opts)
end

function Container:Confirm(title, message, onYes, onNo, opts)
	return self.Win.Lib:Confirm(title, message, onYes, onNo, opts)
end

function Container:Notify(o)
	return self.Win.Lib:Notify(o)
end

function Container:Row()
	local sub = self:_sub(true)
	return sub
end

function Container:Collapsing(str, open)
	local row = self:_row(FH, true)
	local btn = button(row, T.Header, {Size = UDim2.fromScale(1, 1)})
	bind(btn, T.Header, T.HeaderHover, T.HeaderActive)
	local arrow = icon(btn, "Right", {Size = UDim2.fromOffset(FH - 8, FH - 8), Position = UDim2.fromOffset(4, 4)})
	label(btn, str, {Size = UDim2.new(1, -(FH + 4), 1, 0), Position = UDim2.fromOffset(FH + 4, 0)})
	local sub, body = self:_sub(false, 0)
	sub.Header = btn
	sub.Open = open ~= false
	local function render()
		body.Visible = sub.Open
		spin(arrow, sub.Open and 90 or 0)
	end
	function sub:SetOpen(v)
		sub.Open = v
		render()
	end
	btn.MouseButton1Click:Connect(function()
		sub.Open = not sub.Open
		render()
	end)
	render()
	return sub
end

function Container:Tree(str, open)
	local row = self:_row(FH, true)
	local btn = button(row, T.Clear, {Size = UDim2.fromScale(1, 1)})
	bind(btn, T.Clear, T.Clear, T.Clear)
	local arrow = icon(btn, "Right", {Size = UDim2.fromOffset(FH - 8, FH - 8), Position = UDim2.fromOffset(4, 4)})
	label(btn, str, {Size = UDim2.new(1, -(FH + 4), 1, 0), Position = UDim2.fromOffset(FH + 4, 0)})
	local sub, body = self:_sub(false, 21)
	sub.Open = open and true or false
	local function render()
		body.Visible = sub.Open
		spin(arrow, sub.Open and 90 or 0)
	end
	function sub:SetOpen(v)
		sub.Open = v
		render()
	end
	btn.MouseButton1Click:Connect(function()
		sub.Open = not sub.Open
		render()
	end)
	render()
	return sub
end

function Container:TabBar()
	local bar = self:_sub(true, 0, 2)
	local underline = self:_row(1, true)
	frame(underline, T.TabActive, {Size = UDim2.fromScale(1, 1)})
	local pages = self:_sub(false, 0)
	local tb = {Tabs = {}, Current = nil}
	function tb:Select(name)
		for n, t in tb.Tabs do
			local on = n == name
			t.Page.Visible = on
			t.St.Normal = on and T.TabActive or T.Tab
			t.St.Refresh()
		end
		tb.Current = name
	end
	function tb:Tab(name)
		local row = bar:_row(FH)
		local btn = button(row, T.Tab, {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = name
		})
		pad(btn, 6, 6, 0, 0)
		local st = bind(btn, T.Tab, T.TabHover, T.TabActive)
		local page, pageFrame = pages:_sub(false, 0)
		pageFrame.Visible = false
		page.Page = pageFrame
		tb.Tabs[name] = {Page = pageFrame, St = st}
		btn.MouseButton1Click:Connect(function()
			tb:Select(name)
		end)
		if not tb.Current then
			tb:Select(name)
		end
		return page
	end
	return tb
end

function Window:_track(kind, name, get, set)
	local key = kind .. ":" .. tostring(name)
	local n = (self.TrackCount[key] or 0) + 1
	self.TrackCount[key] = n
	if n > 1 then
		key = key .. "#" .. n
	end
	table.insert(self.Tracked, {Key = key, Get = get, Set = set})
end

function Window:_register(name, callback, group)
	table.insert(self.Registry, {Name = tostring(name), Callback = callback or function() end, Group = group or ""})
end

local function wrap(method, build)
	local original = Container[method]
	Container[method] = function(self, ...)
		local obj = original(self, ...)
		if not self.Win._noTrack then
			build(self.Win, obj, ...)
		end
		return obj
	end
end

wrap("Button", function(win, o, str, cb)
	win:_register(str, cb, "按钮")
end)
wrap("Checkbox", function(win, o, str)
	win:_track("Checkbox", str, function()
		return o.Value
	end, function(v)
		o.Set(v, true)
	end)
	win:_register(str, function()
		o.Set(not o.Value, true)
	end, "开关")
end)
for _, method in {"Slider", "Combo", "InputNumber", "DragFloat", "DragInt", "ListBox", "Selectable"} do
	wrap(method, function(win, o, name)
		win:_track(method, name, function()
			return o.Value
		end, function(v)
			o.Set(v, true)
		end)
	end)
end
wrap("MultiCombo", function(win, o, name)
	win:_track("MultiCombo", name, function()
		return o.Get()
	end, function(v)
		o.Set(v, true)
	end)
end)
wrap("InputText", function(win, o, name)
	win:_track("InputText", name, function()
		return o:Get()
	end, function(v)
		o:Set(v, true)
	end)
end)
wrap("RangeSlider", function(win, o, name)
	win:_track("RangeSlider", name, function()
		return {o.Low, o.High}
	end, function(v)
		o.Set(v[1], v[2], true)
	end)
end)
wrap("ColorEdit", function(win, o, name)
	win:_track("ColorEdit", name, function()
		local c = o.Value
		return {c.R, c.G, c.B}
	end, function(v)
		o.Set(Color3.new(v[1], v[2], v[3]), true)
	end)
end)
wrap("RadioGroup", function(win, o, items)
	win:_track("RadioGroup", table.concat(items, "/"), function()
		return o.Value
	end, function(v)
		o.Set(v, true)
	end)
end)
wrap("Keybind", function(win, o, name)
	win:_track("Keybind", name, function()
		return o.Value and o.Value.Name or false
	end, function(v)
		o.Set(v and Enum.KeyCode[v] or nil, true)
	end)
end)
wrap("InputVector", function(win, o, name)
	win:_track("InputVector", name, function()
		return o.Get()
	end, function(v)
		o.Set(v, true)
	end)
end)
wrap("SortableList", function(win, o, name)
	win:_track("SortableList", name, function()
		return o.Get()
	end, function(v)
		o.Set(v, true)
	end)
end)

local INFO_FORMATS = {
	{"24小时 时:分:秒", "%H:%M:%S"},
	{"24小时 时:分", "%H:%M"},
	{"12小时 时:分", "%I:%M %p"},
	{"12小时 时:分:秒", "%I:%M:%S %p"}
}

function Window:InfoBar(o)
	if self.InfoBar_ then
		return self.InfoBar_
	end
	o = o or {}
	local win = self
	local strip = frame(self.TitleBar, T.Frame, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, not self.Closable and -4 or -(FH + 2), 0.5, 0),
		Size = UDim2.fromOffset(10, FH - 4),
		ZIndex = 3
	})
	local text = label(strip, "", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = T.Text,
		ZIndex = 4
	})
	local obj = {
		Frame = strip,
		Items = {},
		Format = o.Format or "%H:%M:%S",
		Version = o.Version or "v1.0.0",
		Shown = true,
		Last = ""
	}
	local fps, frames, elapsed, ping = 0, 0, 0, 0

	local function add(id, name, fn, enabled)
		table.insert(obj.Items, {Id = id, Name = name, Fn = fn, Enabled = enabled})
	end
	add("time", "当前时间", function()
		return os.date(obj.Format)
	end, true)
	add("date", "当前日期", function()
		return os.date("%Y-%m-%d")
	end, false)
	add("version", "当前版本", function()
		return obj.Version
	end, true)
	add("fps", "帧率", function()
		return string.format("FPS %d", fps)
	end, false)
	add("ping", "延迟", function()
		return string.format("%dms", ping)
	end, false)
	add("players", "玩家数", function()
		local max = 0
		pcall(function()
			max = Players.MaxPlayers
		end)
		return string.format("%d/%d", #Players:GetPlayers(), max)
	end, false)
	add("uptime", "服务器时长", function()
		local t = 0
		pcall(function()
			t = workspace.DistributedGameTime
		end)
		return string.format("%02d:%02d", math.floor(t / 60) % 100, math.floor(t) % 60)
	end, false)

	if o.Items then
		for _, it in obj.Items do
			it.Enabled = false
		end
		for _, id in o.Items do
			for _, it in obj.Items do
				if it.Id == id then
					it.Enabled = true
				end
			end
		end
	end

	function obj.Find(id)
		for _, it in obj.Items do
			if it.Id == id then
				return it
			end
		end
	end

	function obj.Refresh()
		if not strip.Parent then
			return
		end
		local parts = {}
		for _, it in obj.Items do
			if it.Enabled then
				local ok, v = pcall(it.Fn)
				if ok and v ~= nil and tostring(v) ~= "" then
					table.insert(parts, tostring(v))
				end
			end
		end
		local avail = win.Frame.Size.X.Offset - FH * 2 - 12 - textWidth(win.TitleLabel.Text)
		local str = table.concat(parts, "  |  ")
		while #parts > 1 and textWidth(str) + 14 > avail do
			table.remove(parts)
			str = table.concat(parts, "  |  ")
		end
		local show = obj.Shown and #parts > 0 and textWidth(str) + 14 <= avail
		strip.Visible = show and true or false
		if str ~= obj.Last then
			obj.Last = str
			text.Text = str
			strip.Size = UDim2.fromOffset(textWidth(str) + 14, FH - 4)
		end
	end

	function obj.Add(id, name, source, enabled)
		local fn = source
		if type(source) ~= "function" then
			fn = function()
				return source
			end
		end
		add(id, name, fn, enabled ~= false)
		obj.Refresh()
	end

	function obj.SetEnabled(id, v)
		local it = obj.Find(id)
		if it then
			it.Enabled = v and true or false
			obj.Refresh()
		end
	end

	function obj.SetFormat(fmt)
		obj.Format = fmt
		obj.Refresh()
	end

	function obj.SetVersion(v)
		obj.Version = v
		obj.Refresh()
	end

	function obj.SetVisible(v)
		obj.Shown = v and true or false
		obj.Refresh()
	end

	local acc, lastSec = 0, 0
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not strip.Parent then
			conn:Disconnect()
			return
		end
		frames = frames + 1
		elapsed = elapsed + dt
		acc = acc + dt
		if elapsed >= 0.5 then
			fps = frames / elapsed
			frames, elapsed = 0, 0
			pcall(function()
				ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
		end
		if acc >= 0.25 then
			acc = 0
			obj.Refresh()
		end
	end)
	table.insert(Library.Conns, conn)
	self.InfoBar_ = obj
	obj.Refresh()
	return obj
end

function Container:InfoBarPicker(opts)
	opts = opts or {}
	local win = self.Win
	local bar = win:InfoBar(opts)
	local obj = {Bar = bar}
	obj.Master = self:Checkbox("显示标题栏信息条", bar.Shown, function(v)
		bar.SetVisible(v)
	end)
	local names = {}
	for _, f in INFO_FORMATS do
		table.insert(names, f[1])
	end
	local current = names[1]
	for _, f in INFO_FORMATS do
		if f[2] == bar.Format then
			current = f[1]
		end
	end
	for _, it in bar.Items do
		self:Checkbox("显示" .. it.Name, it.Enabled, function(v)
			bar.SetEnabled(it.Id, v)
		end)
	end
	obj.Format = self:Combo("时间格式", names, current, function(v)
		for _, f in INFO_FORMATS do
			if f[1] == v then
				bar.SetFormat(f[2])
			end
		end
	end)
	obj.Version = self:InputText("版本文字", bar.Version, function(v)
		bar.SetVersion(v)
	end, "例如 v1.0.0")
	return obj
end

local function imageId(v)
	if type(v) == "number" then
		return "rbxassetid://" .. v
	end
	v = tostring(v or "")
	if v:match("^%d+$") then
		return "rbxassetid://" .. v
	end
	return v
end

function Container:SliderVector(name, count, min, max, defaults, callback, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(iw, -4, 1, 0)}, row)
	list(holder, 2, true)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local state = {Values = {}, Sliders = {}, Frame = row}
	for i = 1, count do
		local track = new("TextButton", {
			BackgroundColor3 = T.Frame[1],
			BackgroundTransparency = T.Frame[2],
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1 / count, -2 * (count - 1) / count, 1, 0),
			LayoutOrder = i
		}, holder)
		state.Values[i] = clamp((defaults and defaults[i]) or min, min, max)
		state.Sliders[i] = makeSlider(win, track, {
			Min = min,
			Max = max,
			Int = opts.Int,
			Format = opts.Format or (not opts.Int and "%.2f" or nil),
			Value = state.Values[i],
			OnChange = function(v)
				state.Values[i] = v
				if callback then
					task.spawn(callback, table.clone(state.Values))
				end
			end
		})
	end
	function state.Set(values, fire)
		for i = 1, count do
			if values[i] ~= nil then
				state.Sliders[i].Set(values[i], false)
				state.Values[i] = state.Sliders[i].Value
			end
		end
		if fire and callback then
			task.spawn(callback, table.clone(state.Values))
		end
	end
	function state.Get()
		return table.clone(state.Values)
	end
	return state
end

function Container:SliderVector2(name, min, max, defaults, callback, opts)
	return self:SliderVector(name, 2, min, max, defaults, callback, opts)
end

function Container:SliderVector3(name, min, max, defaults, callback, opts)
	return self:SliderVector(name, 3, min, max, defaults, callback, opts)
end

function Container:Image(image, height, opts)
	opts = opts or {}
	local row = self:_row(height or 100, true)
	local back = frame(row, T.Frame, {Size = UDim2.fromScale(1, 1)})
	stroke(back, T.Border)
	local img = new("ImageButton", {
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		Image = imageId(image),
		ScaleType = opts.Fill and Enum.ScaleType.Crop or Enum.ScaleType.Fit
	}, back)
	if opts.Callback then
		img.MouseButton1Click:Connect(function()
			task.spawn(opts.Callback)
		end)
	end
	local obj = {Frame = row, Image = img}
	function obj.Set(v)
		img.Image = imageId(v)
	end
	return obj
end

function Container:Viewport(target, height, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(height or 150, true)
	local vf = new("ViewportFrame", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Ambient = Color3.fromRGB(170, 170, 170),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1)
	}, row)
	stroke(vf, T.Border)
	local cam = new("Camera", {FieldOfView = 50}, vf)
	vf.CurrentCamera = cam
	local obj = {Frame = row, Yaw = 0.6, Pitch = 0.15, Zoom = 1, Radius = 5, Center = Vector3.new(0, 0, 0), Dragging = false}
	local function update()
		local d = obj.Radius * 2.2 * obj.Zoom
		local dir = Vector3.new(
			math.sin(obj.Yaw) * math.cos(obj.Pitch),
			math.sin(obj.Pitch),
			math.cos(obj.Yaw) * math.cos(obj.Pitch)
		)
		cam.CFrame = CFrame.new(obj.Center + dir * d, obj.Center)
	end

	function obj.SetModel(inst)
		if obj.Model then
			obj.Model:Destroy()
			obj.Model = nil
		end
		obj.Source = inst
		if not inst then
			update()
			return
		end
		local clone
		pcall(function()
			inst.Archivable = true
			for _, d in inst:GetDescendants() do
				pcall(function()
					d.Archivable = true
				end)
			end
			clone = inst:Clone()
		end)
		if not clone then
			return
		end
		for _, d in clone:GetDescendants() do
			if d:IsA("BaseScript") then
				d:Destroy()
			end
		end
		pcall(function()
			if clone:IsA("Model") then
				clone:PivotTo(CFrame.new(0, 0, 0))
			end
		end)
		clone.Parent = vf
		pcall(function()
			if clone:IsA("Model") then
				local cf, size = clone:GetBoundingBox()
				obj.Center = cf.Position
				obj.Radius = math.max(size.Magnitude / 2, 0.5)
			else
				obj.Center = clone.Position
				obj.Radius = math.max(clone.Size.Magnitude / 2, 0.5)
			end
		end)
		obj.Model = clone
		update()
	end

	function obj.Refresh()
		if obj.Source then
			obj.SetModel(obj.Source)
		end
	end

	function obj.SetZoom(z)
		obj.Zoom = clamp(z, 0.3, 3)
		update()
	end

	vf.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local last = Vector2.new(input.Position.X, input.Position.Y)
		obj.Dragging = true
		win.Body.ScrollingEnabled = false
		beginDrag(input, function(pos)
			local d = pos - last
			last = pos
			obj.Yaw = obj.Yaw - d.X * 0.012
			obj.Pitch = clamp(obj.Pitch + d.Y * 0.01, -1.2, 1.2)
			update()
		end, function()
			obj.Dragging = false
			win.Body.ScrollingEnabled = true
		end)
	end)
	vf.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			obj.SetZoom(obj.Zoom - input.Position.Z * 0.1)
		end
	end)

	for i, sign in {"+", "-"} do
		local zb = button(vf, T.Button, {
			Size = UDim2.fromOffset(FH, FH),
			Position = UDim2.new(1, -(FH + 3), 0, 3 + (i - 1) * (FH + 3)),
			Text = sign,
			ZIndex = 3
		})
		bind(zb, T.Button, T.ButtonHover, T.ButtonActive)
		zb.MouseButton1Click:Connect(function()
			obj.SetZoom(obj.Zoom + (sign == "+" and -0.15 or 0.15))
		end)
	end

	if opts.AutoRotate then
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not row.Parent then
				conn:Disconnect()
				return
			end
			if not obj.Dragging then
				obj.Yaw = obj.Yaw + dt * opts.AutoRotate
				update()
			end
		end)
		table.insert(Library.Conns, conn)
	end

	update()
	if target == nil or target == "Player" then
		task.spawn(function()
			pcall(function()
				local plr = Players.LocalPlayer
				local char = plr.Character or plr.CharacterAdded:Wait()
				if row.Parent then
					obj.SetModel(char)
				end
			end)
		end)
	elseif target then
		obj.SetModel(target)
	end
	return obj
end

local function makeEditor(self, text, height, opts)
	local holder = self:_row(height or 140, true)
	local back = frame(holder, T.Inset, {Size = UDim2.fromScale(1, 1)})
	stroke(back, T.Border)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.XY,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, back)
	pad(scroll, 4, 4, 3, 3)
	local inner = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY
	}, scroll)
	list(inner, 6, true).VerticalAlignment = Enum.VerticalAlignment.Top
	local numbers = label(inner, "1", {
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		TextColor3 = T.TextDisabled,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 1
	})
	local box = new("TextBox", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(240, FH),
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		Text = text or "",
		ClearTextOnFocus = false,
		MultiLine = true,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2
	}, inner)
	local overlay = label(box, "", {
		Size = UDim2.fromScale(1, 1),
		RichText = true,
		TextWrapped = false,
		TextYAlignment = Enum.TextYAlignment.Top,
		ZIndex = 2
	})
	local obj = {Frame = holder, Box = box, Text = text or ""}
	local useHighlight = not opts or opts.Highlight ~= false

	local function render()
		local count = select(2, box.Text:gsub("\n", "\n")) + 1
		local lines = {}
		for i = 1, count do
			lines[i] = tostring(i)
		end
		numbers.Text = table.concat(lines, "\n")
	end

	local function showOverlay()
		if useHighlight then
			overlay.Text = highlight(box.Text)
			overlay.Visible = true
			box.TextTransparency = 1
		end
	end

	box:GetPropertyChangedSignal("Text"):Connect(function()
		obj.Text = box.Text
		render()
		if opts and opts.OnChange then
			task.spawn(opts.OnChange, box.Text)
		end
	end)
	box.Focused:Connect(function()
		box.TextTransparency = 0
		overlay.Visible = false
	end)
	box.FocusLost:Connect(function(enter)
		showOverlay()
		if opts and opts.Callback then
			task.spawn(opts.Callback, box.Text, enter)
		end
	end)

	function obj.Set(v)
		box.Text = tostring(v)
		obj.Text = box.Text
		render()
		if not box:IsFocused() then
			showOverlay()
		end
	end
	function obj.Get()
		return box.Text
	end
	function obj.SetReadOnly(v)
		box.TextEditable = not v
	end
	render()
	showOverlay()
	return obj
end

function Container:CodeEditor(text, height, opts)
	return makeEditor(self, text, height, opts or {})
end

function Container:ScriptEditor(opts)
	opts = opts or {}
	local lib = self.Win.Lib
	local folder = opts.Folder or "ImGuiScripts"
	local canFile = writefile and readfile and isfile and isfolder and makefolder and true or false
	local docs = {{Name = "脚本 1", Text = opts.Text or ""}}
	local current = 1
	local counter = 1
	local obj = {Docs = docs}

	local strip = self:_row(FH + 2, true)
	local sc = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0
	}, strip)
	list(sc, 2, true)

	local editor
	local renderTabs

	local function switchTo(i)
		docs[current].Text = editor.Get()
		current = i
		editor.Set(docs[i].Text)
		renderTabs()
	end

	function renderTabs()
		for _, c in sc:GetChildren() do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
		for i, d in docs do
			local normal = i == current and T.TabActive or T.Tab
			local b = button(sc, normal, {
				Size = UDim2.fromOffset(textWidth(d.Name) + 14, FH),
				Text = d.Name,
				LayoutOrder = i
			})
			bind(b, normal, T.TabHover, T.TabActive)
			b.MouseButton1Click:Connect(function()
				if i ~= current then
					switchTo(i)
				end
			end)
		end
		local add = button(sc, T.Button, {Size = UDim2.fromOffset(FH, FH), Text = "+", LayoutOrder = 1000})
		bind(add, T.Button, T.ButtonHover, T.ButtonActive)
		add.MouseButton1Click:Connect(function()
			counter = counter + 1
			docs[current].Text = editor.Get()
			table.insert(docs, {Name = "脚本 " .. counter, Text = ""})
			current = #docs
			editor.Set("")
			renderTabs()
		end)
		if #docs > 1 then
			local del = button(sc, tok(170, 60, 60, 0), {Size = UDim2.fromOffset(FH, FH), Text = "x", LayoutOrder = 1001})
			bind(del, {Color3.fromRGB(170, 60, 60), 0}, {Color3.fromRGB(200, 80, 80), 0}, {Color3.fromRGB(220, 100, 100), 0})
			del.MouseButton1Click:Connect(function()
				table.remove(docs, current)
				current = math.min(current, #docs)
				editor.Set(docs[current].Text)
				renderTabs()
			end)
		end
	end

	editor = makeEditor(self, docs[1].Text, opts.Height or 150, {
		Highlight = true,
		OnChange = function(t)
			docs[current].Text = t
		end
	})
	renderTabs()

	local bar = self:Row()
	bar:SmallButton("执行", function()
		local src = editor.Get()
		if opts.OnExecute then
			task.spawn(opts.OnExecute, src)
			return
		end
		if not loadstring then
			lib:Notify({Title = "脚本", Content = "当前环境不支持 loadstring", Type = "Warn"})
			return
		end
		local fn, err = loadstring(src)
		if not fn then
			lib:Notify({Title = "脚本", Content = tostring(err), Type = "Error"})
			return
		end
		task.spawn(function()
			local ok, e = pcall(fn)
			if ok then
				lib:Notify({Title = "脚本", Content = "已执行", Type = "Success"})
			else
				lib:Notify({Title = "脚本", Content = tostring(e), Type = "Error"})
			end
		end)
	end, Color3.fromRGB(70, 160, 90))
	bar:SmallButton("打开", function()
		if not canFile then
			lib:Notify({Title = "脚本", Content = "当前环境不支持文件读写", Type = "Warn"})
			return
		end
		lib:Prompt("打开脚本", "文件名（不含后缀）：", docs[current].Name, function(name)
			local path = folder .. "/" .. name .. ".lua"
			if isfile(path) then
				editor.Set(readfile(path))
				docs[current].Text = editor.Get()
				docs[current].Name = name
				renderTabs()
			else
				lib:Notify({Title = "脚本", Content = "找不到文件：" .. name, Type = "Error"})
			end
		end)
	end)
	bar:SmallButton("保存", function()
		if not canFile then
			lib:Notify({Title = "脚本", Content = "当前环境不支持文件读写", Type = "Warn"})
			return
		end
		if not isfolder(folder) then
			makefolder(folder)
		end
		writefile(folder .. "/" .. docs[current].Name .. ".lua", editor.Get())
		lib:Notify({Title = "脚本", Content = "已保存：" .. docs[current].Name, Type = "Success"})
	end)
	bar:SmallButton("复制", function()
		if setclipboard then
			pcall(setclipboard, editor.Get())
			lib:Notify({Title = "脚本", Content = "已复制", Type = "Success"})
		end
	end)
	bar:SmallButton("清空", function()
		editor.Set("")
		docs[current].Text = ""
	end)

	obj.Editor = editor
	function obj.Get()
		return editor.Get()
	end
	function obj.Set(v)
		editor.Set(v)
		docs[current].Text = editor.Get()
	end
	return obj
end

function Container:IconGrid(items, opts)
	opts = opts or {}
	local cell = opts.Cell or 34
	if not items then
		items = {}
		for name, id in ICONS do
			table.insert(items, {Name = name, Image = id})
		end
		table.sort(items, function(a, b)
			return a.Name < b.Name
		end)
	end
	local obj = {Items = items, Selected = nil, Query = ""}
	local box
	if opts.Search ~= false then
		local srow = self:_row(FH, true)
		box = new("TextBox", {
			BackgroundColor3 = T.Frame[1],
			BackgroundTransparency = T.Frame[2],
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Font = FONT,
			TextSize = TS,
			TextColor3 = T.Text,
			PlaceholderText = "搜索图标...",
			PlaceholderColor3 = T.TextDisabled,
			Text = "",
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left
		}, srow)
		pad(box, 4, 4, 0, 0)
	end
	local holder = self:_row(opts.Height or 120, true)
	local back = frame(holder, T.Inset, {Size = UDim2.fromScale(1, 1)})
	stroke(back, T.Border)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, back)
	pad(scroll, 4, 4, 4, 4)
	new("UIGridLayout", {
		CellSize = UDim2.fromOffset(cell, cell),
		CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, scroll)
	local status = self:_row(FH)
	local statusLabel = label(status, "未选择", {Size = UDim2.fromScale(1, 1), TextColor3 = T.TextDisabled})

	local function render()
		for _, c in scroll:GetChildren() do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
		local q = string.lower(obj.Query)
		local shown = 0
		for i, item in obj.Items do
			local name = tostring(item.Name or item.Text or i)
			if q == "" or string.find(string.lower(name), q, 1, true) then
				shown = shown + 1
				if shown > 500 then
					break
				end
				local normal = obj.Selected == item and T.Header or T.Frame
				local b = button(scroll, normal, {Text = "", LayoutOrder = i})
				bind(b, normal, T.HeaderHover, T.HeaderActive)
				if item.Image then
					new("ImageLabel", {
						BackgroundTransparency = 1,
						Image = imageId(item.Image),
						ImageColor3 = item.Color or T.Text,
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.new(1, -10, 1, -10),
						Position = UDim2.fromOffset(5, 5)
					}, b)
				else
					label(b, item.Text or string.sub(name, 1, 2), {
						Size = UDim2.fromScale(1, 1),
						TextXAlignment = Enum.TextXAlignment.Center,
						TextColor3 = item.Color or T.Text
					})
				end
				b.MouseButton1Click:Connect(function()
					obj.Selected = item
					statusLabel.Text = name
					statusLabel.TextColor3 = T.Text
					if opts.Callback then
						task.spawn(opts.Callback, item)
					end
					render()
				end)
			end
		end
	end

	if box then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			obj.Query = box.Text
			render()
		end)
	end
	function obj.SetItems(newItems)
		obj.Items = newItems
		obj.Selected = nil
		render()
	end
	function obj.Get()
		return obj.Selected
	end
	obj.Frame = holder
	render()
	return obj
end

function Container:Explorer(root, opts)
	opts = opts or {}
	root = root or game
	local win = self.Win
	local lib = win.Lib
	local obj = {Root = root, Open = {}, Selected = nil, Query = ""}

	local srow = self:_row(FH, true)
	local box = new("TextBox", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		PlaceholderText = "搜索名称...",
		PlaceholderColor3 = T.TextDisabled,
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left
	}, srow)
	pad(box, 4, 4, 0, 0)

	local holder = self:_row(opts.Height or 170, true)
	local back = frame(holder, T.Inset, {Size = UDim2.fromScale(1, 1)})
	stroke(back, T.Border)
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, back)
	list(scroll, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	local status = self:_row(FH)
	local statusLabel = label(status, "未选择", {Size = UDim2.fromScale(1, 1), TextColor3 = T.TextDisabled, TextTruncate = Enum.TextTruncate.AtEnd})

	local function children(inst)
		local ok, kids = pcall(function()
			return inst:GetChildren()
		end)
		if not ok then
			return {}
		end
		table.sort(kids, function(a, b)
			return string.lower(a.Name) < string.lower(b.Name)
		end)
		return kids
	end

	local function hasKids(inst)
		local ok, r = pcall(function()
			return #inst:GetChildren() > 0
		end)
		return ok and r
	end

	local function collect()
		local out = {}
		if obj.Query ~= "" then
			local q = string.lower(obj.Query)
			local ok, all = pcall(function()
				return root:GetDescendants()
			end)
			if ok then
				for _, inst in all do
					local okName, nm = pcall(function()
						return string.lower(inst.Name)
					end)
					if okName and string.find(nm, q, 1, true) then
						table.insert(out, {Inst = inst, Depth = 0})
						if #out >= 300 then
							break
						end
					end
				end
			end
			return out
		end
		local function walk(inst, depth)
			for _, c in children(inst) do
				if #out >= 800 then
					return
				end
				local kids = hasKids(c)
				table.insert(out, {Inst = c, Depth = depth, Kids = kids})
				if kids and obj.Open[c] then
					walk(c, depth + 1)
				end
			end
		end
		walk(root, 0)
		return out
	end

	local render

	function obj.Select(inst)
		obj.Selected = inst
		local ok, full = pcall(function()
			return inst:GetFullName()
		end)
		statusLabel.Text = ok and full or tostring(inst)
		statusLabel.TextColor3 = T.Text
		if opts.Callback then
			task.spawn(opts.Callback, inst)
		end
	end

	function render()
		for _, c in scroll:GetChildren() do
			if c:IsA("TextButton") then
				c:Destroy()
			end
		end
		for i, node in collect() do
			local inst = node.Inst
			local normal = obj.Selected == inst and T.Header or T.Clear
			local b = button(scroll, normal, {Size = UDim2.new(1, 0, 0, FH), Text = "", LayoutOrder = i})
			bind(b, normal, T.HeaderHover, T.HeaderActive)
			local x = node.Depth * 12
			if node.Kids then
				local ab = button(b, T.Clear, {Size = UDim2.fromOffset(FH, FH), Position = UDim2.fromOffset(x, 0), ZIndex = 3})
				new("ImageLabel", {
					BackgroundTransparency = 1,
					Image = ICONS.Right,
					ImageColor3 = T.Text,
					Size = UDim2.fromOffset(FH - 8, FH - 8),
					Position = UDim2.fromOffset(4, 4),
					Rotation = obj.Open[inst] and 90 or 0,
					ZIndex = 4
				}, ab)
				ab.MouseButton1Click:Connect(function()
					obj.Open[inst] = not obj.Open[inst] or nil
					render()
				end)
			end
			local okName, nm = pcall(function()
				return inst.Name
			end)
			local okClass, cn = pcall(function()
				return inst.ClassName
			end)
			label(b, okName and nm or "?", {
				Size = UDim2.new(0.6, -(x + FH), 1, 0),
				Position = UDim2.fromOffset(x + FH, 0),
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 2
			})
			label(b, okClass and cn or "", {
				Size = UDim2.new(0.4, -6, 1, 0),
				Position = UDim2.new(0.6, 0, 0, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = T.TextDisabled,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 2
			})
			b.MouseButton1Click:Connect(function()
				obj.Select(inst)
				render()
			end)
		end
	end

	local token = 0
	box:GetPropertyChangedSignal("Text"):Connect(function()
		token = token + 1
		local mine = token
		task.delay(0.25, function()
			if token == mine then
				obj.Query = box.Text
				render()
			end
		end)
	end)

	local bar = self:Row()
	bar:SmallButton("复制路径", function()
		if obj.Selected and setclipboard then
			local ok, full = pcall(function()
				return obj.Selected:GetFullName()
			end)
			if ok then
				pcall(setclipboard, full)
				lib:Notify({Title = "浏览器", Content = "已复制路径", Type = "Success"})
			end
		end
	end)
	bar:SmallButton("刷新", function()
		render()
	end)
	bar:SmallButton("收起全部", function()
		obj.Open = {}
		render()
	end)

	obj.Frame = holder
	obj.Refresh = render
	function obj.SetRoot(r)
		root = r
		obj.Root = r
		obj.Open = {}
		obj.Selected = nil
		render()
	end
	render()
	return obj
end

wrap("SliderVector", function(win, o, name)
	win:_track("SliderVector", name, function()
		return o.Get()
	end, function(v)
		o.Set(v, true)
	end)
end)

function Window:SetPosition(x, y)
	self.Frame.Position = UDim2.fromOffset(x, y)
end

function Window:SetSize(w, h)
	self.Frame.Size = UDim2.fromOffset(w, h)
end

function Window:SetResizable(v)
	self.Resizable = v and true or false
	self.Grip.Visible = self.Resizable and not self.Collapsed
end

local function makePane(parent, win)
	local sc = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll
	}, parent)
	pad(sc, 4, 6, 4, 4)
	list(sc, GAP).VerticalAlignment = Enum.VerticalAlignment.Top
	return makeContainer(win, sc), sc
end

function Container:Splitter(direction, ratio, height, opts)
	opts = opts or {}
	local win = self.Win
	local horizontal = direction ~= "v"
	local row = self:_row(height or 160, true)
	local back = frame(row, T.Inset, {Size = UDim2.fromScale(1, 1)})
	stroke(back, T.Border)
	local HW = 8
	local aFrame = new("Frame", {BackgroundTransparency = 1, ClipsDescendants = true}, back)
	local bFrame = new("Frame", {BackgroundTransparency = 1, ClipsDescendants = true}, back)
	local handle = button(back, T.Frame, {ZIndex = 3})
	local dots = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = horizontal and UDim2.fromOffset(2, 18) or UDim2.fromOffset(18, 2),
		ZIndex = 4
	}, handle)
	for i = 0, 2 do
		local d = frame(dots, T.TextDisabled and {T.TextDisabled, 0} or T.Separator, {
			Size = UDim2.fromOffset(2, 2),
			Position = horizontal and UDim2.fromOffset(0, i * 8) or UDim2.fromOffset(i * 8, 0),
			ZIndex = 4
		})
	end
	bind(handle, T.Frame, T.FrameHover, T.FrameActive)
	local obj = {
		Ratio = clamp(ratio or 0.5, 0.1, 0.9),
		Min = opts.Min or 0.15,
		Max = opts.Max or 0.85,
		Frame = row
	}
	obj.A = makePane(aFrame, win)
	obj.B = makePane(bFrame, win)
	obj.A.ItemWidth = 0.5
	obj.B.ItemWidth = 0.5

	local function layout()
		local r = obj.Ratio
		if horizontal then
			aFrame.Position = UDim2.fromOffset(0, 0)
			aFrame.Size = UDim2.new(r, -HW / 2, 1, 0)
			handle.Position = UDim2.new(r, -HW / 2, 0, 0)
			handle.Size = UDim2.new(0, HW, 1, 0)
			bFrame.Position = UDim2.new(r, HW / 2, 0, 0)
			bFrame.Size = UDim2.new(1 - r, -HW / 2, 1, 0)
		else
			aFrame.Position = UDim2.fromOffset(0, 0)
			aFrame.Size = UDim2.new(1, 0, r, -HW / 2)
			handle.Position = UDim2.new(0, 0, r, -HW / 2)
			handle.Size = UDim2.new(1, 0, 0, HW)
			bFrame.Position = UDim2.new(0, 0, r, HW / 2)
			bFrame.Size = UDim2.new(1, 0, 1 - r, -HW / 2)
		end
	end

	function obj.Set(r)
		obj.Ratio = clamp(r, obj.Min, obj.Max)
		layout()
	end
	function obj.Get()
		return obj.Ratio
	end

	handle.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		win.Body.ScrollingEnabled = false
		beginDrag(input, function(pos)
			local ap, as = back.AbsolutePosition, back.AbsoluteSize
			local r
			if horizontal then
				r = (pos.X - ap.X) / math.max(as.X, 1)
			else
				r = (pos.Y - ap.Y) / math.max(as.Y, 1)
			end
			obj.Set(r)
		end, function()
			win.Body.ScrollingEnabled = true
		end)
	end)
	layout()
	return obj
end

function Container:SideTabs(tabWidth, height, opts)
	opts = opts or {}
	local win = self.Win
	tabWidth = tabWidth or 78
	local row = self:_row(height or 170, true)
	local back = frame(row, T.Inset, {Size = UDim2.fromScale(1, 1)})
	stroke(back, T.Border)
	local strip = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, tabWidth, 1, 0),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0
	}, back)
	list(strip, 1).VerticalAlignment = Enum.VerticalAlignment.Top
	frame(back, T.Separator, {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromOffset(tabWidth, 0)})
	local pages = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(tabWidth + 1), 1, 0),
		Position = UDim2.fromOffset(tabWidth + 1, 0)
	}, back)
	local obj = {Tabs = {}, Order = {}, Current = nil, Frame = row}

	function obj.Select(name)
		for n, t in obj.Tabs do
			local on = n == name
			t.Page.Visible = on
			t.Bar.Visible = on
			t.St.Normal = on and T.TabActive or T.Clear
			t.St.Refresh()
		end
		obj.Current = name
	end

	function obj.Tab(name)
		local btn = button(strip, T.Clear, {
			Size = UDim2.new(1, 0, 0, FH + 6),
			Text = name,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = #obj.Order + 1
		})
		pad(btn, 8, 4, 0, 0)
		local st = bind(btn, T.Clear, T.TabHover, T.TabActive)
		local bar = frame(btn, T.Grab, {Size = UDim2.new(0, 2, 1, 0), Visible = false, ZIndex = 3})
		local pageHolder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false}, pages)
		local page = makePane(pageHolder, win)
		page.ItemWidth = 0.5
		obj.Tabs[name] = {Page = pageHolder, St = st, Bar = bar}
		table.insert(obj.Order, name)
		btn.MouseButton1Click:Connect(function()
			obj.Select(name)
			if opts.Callback then
				task.spawn(opts.Callback, name)
			end
		end)
		if not obj.Current then
			obj.Select(name)
		end
		return page
	end
	return obj
end

function Container:Accordion(opts)
	opts = opts or {}
	local obj = {Sections = {}}
	local owner = self
	function obj.Section(title, open)
		local sub = owner:Collapsing(title, open)
		table.insert(obj.Sections, sub)
		sub.Header.MouseButton1Click:Connect(function()
			if sub.Open and not opts.Multiple then
				for _, other in obj.Sections do
					if other ~= sub and other.Open then
						other:SetOpen(false)
					end
				end
			end
		end)
		if open and not opts.Multiple then
			for _, other in obj.Sections do
				if other ~= sub and other.Open then
					other:SetOpen(false)
				end
			end
		end
		return sub
	end
	function obj.Open(index)
		for i, sec in obj.Sections do
			sec:SetOpen(i == index)
		end
	end
	return obj
end

function Container:Card(title, opts)
	opts = opts or {}
	local win = self.Win
	self._n = self._n + 1
	local card = frame(self.Content, T.PopupBg, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._n
	})
	stroke(card, T.Border)
	local l = list(card, 0)
	l.VerticalAlignment = Enum.VerticalAlignment.Top
	local header = button(card, opts.Color and {opts.Color, 0.3} or T.Frame, {
		Size = UDim2.new(1, 0, 0, FH),
		LayoutOrder = 1
	})
	local collapsible = opts.Collapsible ~= false
	local arrow
	if collapsible then
		arrow = new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = ICONS.Right,
			ImageColor3 = T.Text,
			Size = UDim2.fromOffset(FH - 8, FH - 8),
			Position = UDim2.fromOffset(4, 4),
			Rotation = 90
		}, header)
	end
	local titleLabel = label(header, title or "", {
		Size = UDim2.new(1, -(FH + 4), 1, 0),
		Position = UDim2.fromOffset(collapsible and FH or 6, 0)
	})
	local body = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2
	}, card)
	pad(body, 6, 6, 5, 5)
	list(body, GAP).VerticalAlignment = Enum.VerticalAlignment.Top
	local content = makeContainer(win, body)
	content.Open = opts.Open ~= false
	content.Frame = card
	local function render()
		body.Visible = content.Open
		if arrow then
			spin(arrow, content.Open and 90 or 0)
		end
	end
	if collapsible then
		bind(header, opts.Color and {opts.Color, 0.3} or T.Frame, T.HeaderHover, T.HeaderActive)
		header.MouseButton1Click:Connect(function()
			content.Open = not content.Open
			render()
		end)
	else
		header.Active = false
	end
	function content:SetOpen(v)
		content.Open = v and true or false
		render()
	end
	function content:SetTitle(str)
		titleLabel.Text = str
	end
	render()
	return content
end

function Library:ContextMenu(target, items, opts)
	opts = opts or {}
	local lib = self
	local function open(x, y)
		local gui = lib.Gui
		local vp = gui.AbsoluteSize
		if vp.X <= 0 then
			vp = Vector2.new(800, 600)
		end
		local entries = type(items) == "function" and items() or items
		local width = opts.Width or 120
		local height = 4
		for _, it in entries do
			if not it.Separator then
				width = math.max(width, textWidth(it.Text or "") + 26)
				height = height + FH
			else
				height = height + 5
			end
		end
		width = math.min(width, vp.X - 8)
		local blocker = button(gui, T.Clear, {Size = UDim2.fromScale(1, 1), ZIndex = 1500})
		local menu = frame(blocker, T.PopupBg, {
			Size = UDim2.fromOffset(width, height),
			Position = UDim2.fromOffset(clamp(x, 4, vp.X - width - 4), clamp(y, 4, math.max(vp.Y - height - 4, 4))),
			ZIndex = 1501,
			Active = true
		})
		stroke(menu, T.Border)
		pad(menu, 0, 0, 2, 2)
		list(menu, 0).VerticalAlignment = Enum.VerticalAlignment.Top
		local function close()
			if blocker.Parent then
				blocker:Destroy()
			end
		end
		for i, it in entries do
			if it.Separator then
				local holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 5), LayoutOrder = i, ZIndex = 1502}, menu)
				frame(holder, T.Separator, {Size = UDim2.new(1, -8, 0, 1), Position = UDim2.fromOffset(4, 2), ZIndex = 1503})
			else
				local b = button(menu, T.Clear, {
					Size = UDim2.new(1, 0, 0, FH),
					Text = it.Text or "",
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = it.Disabled and T.TextDisabled or (it.Color or T.Text),
					LayoutOrder = i,
					ZIndex = 1502
				})
				pad(b, 10, 6, 0, 0)
				if not it.Disabled then
					bind(b, T.Clear, T.HeaderHover, T.HeaderActive)
					b.MouseButton1Click:Connect(function()
						close()
						if it.Callback then
							task.spawn(it.Callback)
						end
					end)
				end
			end
		end
		blocker.MouseButton1Click:Connect(close)
		return {Close = close}
	end

	target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			open(input.Position.X, input.Position.Y)
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local start = Vector2.new(input.Position.X, input.Position.Y)
			local cancelled = false
			local conn
			conn = target.InputEnded:Connect(function(i)
				if i == input then
					cancelled = true
					conn:Disconnect()
				end
			end)
			task.delay(opts.Hold or 0.5, function()
				if not cancelled then
					conn:Disconnect()
					local now = Vector2.new(input.Position.X, input.Position.Y)
					if (now - start).Magnitude < 10 then
						open(start.X, start.Y)
					end
				end
			end)
		end
	end)
	return {Open = open}
end

function Container:ContextMenu(obj, items, opts)
	local target = obj and (obj.Frame or obj.Button) or nil
	if target then
		return self.Win.Lib:ContextMenu(target, items, opts)
	end
end

function Window:TitleMenu(items, opts)
	return self.Lib:ContextMenu(self.TitleLabel, items, opts)
end

function Container:Columns(count, opts)
	opts = opts or {}
	local win = self.Win
	count = math.max(count or 2, 1)
	local gap = opts.Gap or 6
	local weights = opts.Weights or {}
	local total = 0
	for i = 1, count do
		total = total + (weights[i] or 1)
	end
	self._n = self._n + 1
	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._n
	}, self.Content)
	local l = list(holder, gap, true)
	l.VerticalAlignment = Enum.VerticalAlignment.Top
	local cols = {Frame = holder}
	for i = 1, count do
		local colFrame = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new((weights[i] or 1) / total, -gap * (count - 1) * (weights[i] or 1) / total, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = i
		}, holder)
		if opts.Border then
			stroke(colFrame, T.Separator)
			pad(colFrame, 4, 4, 4, 4)
		end
		list(colFrame, GAP).VerticalAlignment = Enum.VerticalAlignment.Top
		cols[i] = makeContainer(win, colFrame)
		if count >= 3 then
			cols[i].ItemWidth = 0.45
		elseif count == 2 then
			cols[i].ItemWidth = 0.5
		end
	end
	return cols
end

function Container:Child(height, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(height or 120, true)
	local back = frame(row, opts.Border == false and T.Clear or T.Inset, {Size = UDim2.fromScale(1, 1)})
	if opts.Border ~= false then
		stroke(back, T.Border)
	end
	local pane, sc = makePane(back, win)
	pane.Frame = row
	pane.Scroll = sc
	function pane.ScrollTo(y)
		sc.CanvasPosition = Vector2.new(0, y)
	end
	return pane
end

function Container:Indent(amount)
	return (self:_sub(false, amount or 14))
end

function Container:Flex(opts)
	opts = opts or {}
	local win = self.Win
	local horizontal = opts.Direction ~= "column"
	self._n = self._n + 1
	local f = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, opts.Height or 0),
		AutomaticSize = opts.Height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		LayoutOrder = self._n
	}, self.Content)
	local l = list(f, opts.Gap or PADX, horizontal, opts.Wrap)
	local hmap = {start = Enum.HorizontalAlignment.Left, center = Enum.HorizontalAlignment.Center, ["end"] = Enum.HorizontalAlignment.Right}
	local vmap = {start = Enum.VerticalAlignment.Top, center = Enum.VerticalAlignment.Center, ["end"] = Enum.VerticalAlignment.Bottom}
	l.HorizontalAlignment = hmap[opts.Horizontal or (horizontal and opts.Justify) or "start"] or Enum.HorizontalAlignment.Left
	l.VerticalAlignment = vmap[opts.Vertical or (not horizontal and opts.Justify) or (horizontal and opts.Align) or "start"] or Enum.VerticalAlignment.Top
	if opts.Justify == "between" then
		pcall(function()
			if horizontal then
				l.HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween
			else
				l.VerticalFlex = Enum.UIFlexAlignment.SpaceBetween
			end
		end)
	end
	local c = makeContainer(win, f, horizontal)
	c.Frame = f
	return c
end

function Container:Toolbar()
	local win = self.Win
	self._n = self._n + 1
	local bar = frame(self.Content, T.Menubar, {
		Size = UDim2.new(1, 0, 0, FH + 4),
		LayoutOrder = self._n
	})
	local scroller = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0
	}, bar)
	pad(scroller, 3, 3, 1, 1)
	list(scroller, 3, true)
	local c = makeContainer(win, scroller, true)
	c.Frame = bar
	return c
end

function Container:VSeparator()
	local row = self:_row(FH)
	frame(row, T.Separator, {Size = UDim2.new(0, 1, 1, -4), Position = UDim2.fromOffset(3, 2)})
	local spacer = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(6, 1)}, row)
	return {Frame = row}
end

function Container:Pager(opts)
	opts = opts or {}
	local pagesC = self:_sub(false, 0)
	local nav = self:_row(FH + 4, true)
	local prev = button(nav, T.Button, {Size = UDim2.fromOffset(FH + 8, FH), Position = UDim2.fromOffset(0, 2), Text = "<"})
	local nextBtn = button(nav, T.Button, {
		Size = UDim2.fromOffset(FH + 8, FH),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Text = ">"
	})
	bind(prev, T.Button, T.ButtonHover, T.ButtonActive)
	bind(nextBtn, T.Button, T.ButtonHover, T.ButtonActive)
	local dots = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 8),
		AutomaticSize = Enum.AutomaticSize.X
	}, nav)
	list(dots, 5, true)
	local titleLabel = label(nav, "", {
		Size = UDim2.new(1, -(FH + 8) * 2 - 8, 1, 0),
		Position = UDim2.fromOffset(FH + 12, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = T.TextDisabled,
		Visible = opts.Label == true
	})
	local obj = {Pages = {}, Titles = {}, Current = 1, Frame = nav}
	local dotFrames = {}

	local function go(i)
		local n = #obj.Pages
		if n == 0 then
			return
		end
		if opts.Loop then
			i = (i - 1) % n + 1
		end
		i = clamp(i, 1, n)
		obj.Current = i
		for k, page in obj.Pages do
			page.Visible = k == i
		end
		for k, d in dotFrames do
			paint(d, k == i and T.Grab or T.Frame)
		end
		prev.Visible = opts.Loop or i > 1
		nextBtn.Text = (i == n and opts.Finish) and "完成" or ">"
		nextBtn.Visible = opts.Loop or i < n or opts.Finish ~= nil
		nextBtn.Size = UDim2.fromOffset((i == n and opts.Finish) and textWidth("完成") + 16 or FH + 8, FH)
		titleLabel.Text = string.format("%d / %d  %s", i, n, obj.Titles[i] or "")
		if opts.Callback then
			task.spawn(opts.Callback, i)
		end
	end

	function obj.Page(title)
		local page, pageFrame = pagesC:_sub(false, 0)
		table.insert(obj.Pages, pageFrame)
		table.insert(obj.Titles, title or "")
		local d = frame(dots, T.Frame, {Size = UDim2.fromOffset(8, 8), LayoutOrder = #obj.Pages})
		table.insert(dotFrames, d)
		go(#obj.Pages == 1 and 1 or obj.Current)
		return page
	end
	function obj.Go(i)
		go(i)
	end
	function obj.Next()
		go(obj.Current + 1)
	end
	function obj.Prev()
		go(obj.Current - 1)
	end
	prev.MouseButton1Click:Connect(function()
		go(obj.Current - 1)
	end)
	nextBtn.MouseButton1Click:Connect(function()
		if obj.Current >= #obj.Pages and opts.Finish and not opts.Loop then
			task.spawn(opts.Finish)
		else
			go(obj.Current + 1)
		end
	end)
	return obj
end

function Container:Drawer(side, width, opts)
	opts = opts or {}
	local win = self.Win
	side = side or "right"
	width = width or 180
	local right = side ~= "left"
	local wrapper = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -FH),
		Position = UDim2.fromOffset(0, FH),
		ClipsDescendants = true,
		ZIndex = 20,
		Visible = false
	}, win.Frame)
	local blocker = button(wrapper, {Color3.new(0, 0, 0), 0.55}, {Size = UDim2.fromScale(1, 1), ZIndex = 20})
	local panel = frame(wrapper, T.PopupBg, {
		Size = UDim2.new(0, width, 1, 0),
		AnchorPoint = Vector2.new(right and 1 or 0, 0),
		ZIndex = 21
	})
	stroke(panel, T.Border)
	local pane = makePane(panel, win)
	pane.ItemWidth = 0.5
	local openPos = right and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
	local closePos = right and UDim2.new(1, width, 0, 0) or UDim2.new(0, -width, 0, 0)
	panel.Position = closePos
	local obj = {Content = pane, IsOpen = false, Frame = wrapper}
	local token = 0

	function obj.Open()
		if obj.IsOpen then
			return
		end
		obj.IsOpen = true
		token = token + 1
		wrapper.Visible = true
		if Settings.Anim then
			TweenService:Create(panel, POP, {Position = openPos}):Play()
		else
			panel.Position = openPos
		end
	end

	function obj.Close(instant)
		if not obj.IsOpen then
			return
		end
		obj.IsOpen = false
		token = token + 1
		local mine = token
		if Settings.Anim and not instant then
			TweenService:Create(panel, POP, {Position = closePos}):Play()
			task.delay(0.16, function()
				if token == mine then
					wrapper.Visible = false
				end
			end)
		else
			panel.Position = closePos
			wrapper.Visible = false
		end
	end

	function obj.Toggle()
		if obj.IsOpen then
			obj.Close()
		else
			obj.Open()
		end
	end

	if opts.Modal ~= false then
		blocker.MouseButton1Click:Connect(function()
			obj.Close()
		end)
	else
		blocker.Visible = false
	end
	win.Drawers = win.Drawers or {}
	table.insert(win.Drawers, obj)
	return obj
end

function Container:Popover(trigger, width, height, builder)
	local win = self.Win
	local target = trigger and (trigger.Button or trigger.Frame)
	if not target then
		return
	end
	local function open()
		win:_popup(target, width or 160, height or 120, function(pop)
			local pane = makePane(pop, win)
			if builder then
				builder(pane, function()
					win:_closePopup()
				end)
			end
		end)
	end
	if trigger.Button then
		trigger.Button.MouseButton1Click:Connect(open)
	else
		target.InputBegan:Connect(function(input)
			if isPress(input) then
				open()
			end
		end)
	end
	return {Open = open}
end

function Window:StatusBar(text)
	if self.StatusObj then
		return self.StatusObj
	end
	local bar = frame(self.Frame, T.Menubar, {
		Size = UDim2.new(1, 0, 0, FH),
		Position = UDim2.new(0, 0, 1, -FH),
		ZIndex = 4
	})
	frame(bar, T.Separator, {Size = UDim2.new(1, 0, 0, 1), ZIndex = 5})
	self.StatusBar_ = bar
	self.StatusH = FH
	self:_layout()
	local left = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), ZIndex = 5}, bar)
	list(left, 6, true)
	pad(left, 6, 0, 0, 0)
	local rightLabel = label(bar, "", {
		Size = UDim2.new(1, -24, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = T.TextDisabled,
		ZIndex = 5
	})
	local obj = {Frame = bar, Segs = {}, Order = {}}
	function obj.Add(id, str, color)
		local sep
		if #obj.Order > 0 then
			sep = frame(left, T.Separator, {Size = UDim2.new(0, 1, 0.6, 0), LayoutOrder = #obj.Order * 2, ZIndex = 5})
		end
		local lbl = label(left, str, {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			TextColor3 = color or T.Text,
			LayoutOrder = #obj.Order * 2 + 1,
			ZIndex = 5
		})
		obj.Segs[id] = {Label = lbl, Sep = sep}
		table.insert(obj.Order, id)
		return lbl
	end
	function obj.Set(id, str, color)
		local seg = obj.Segs[id]
		if seg then
			seg.Label.Text = str
			if color then
				seg.Label.TextColor3 = color
			end
		end
	end
	function obj.SetRight(str)
		rightLabel.Text = str
	end
	function obj.Remove(id)
		local seg = obj.Segs[id]
		if seg then
			seg.Label:Destroy()
			if seg.Sep then
				seg.Sep:Destroy()
			end
			obj.Segs[id] = nil
			for i, v in obj.Order do
				if v == id then
					table.remove(obj.Order, i)
					break
				end
			end
		end
	end
	if text then
		obj.Add("main", text)
	end
	self.StatusObj = obj
	return obj
end

function Container:SubPanel(name, builder, opts)
	opts = opts or {}
	local win = self.Win
	local lib = win.Lib
	local row = self:_row(FH, true)
	local btn = button(row, T.Header, {Size = UDim2.fromScale(1, 1)})
	local st = bind(btn, T.Header, T.HeaderHover, T.HeaderActive)
	label(btn, name, {Size = UDim2.new(1, -(FH + 4), 1, 0), Position = UDim2.fromOffset(6, 0)})
	local arrow = new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = ICONS.Right,
		ImageColor3 = T.Text,
		Size = UDim2.fromOffset(FH - 8, FH - 8),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 4)
	}, btn)
	local obj = {Frame = row, Button = btn, IsOpen = false}
	local sub

	local function refresh()
		st.Normal = obj.IsOpen and T.HeaderHover or T.Header
		st.Refresh()
		spin(arrow, obj.IsOpen and 180 or 0)
	end

	local function place()
		local vp = lib.Gui.AbsoluteSize
		if vp.X <= 0 then
			vp = Vector2.new(800, 600)
		end
		local w = sub.Frame.Size.X.Offset * win.Scale
		local pa, ps = win.Frame.AbsolutePosition, win.Frame.AbsoluteSize
		local x = pa.X + ps.X + 6
		if x + w > vp.X - 4 then
			x = pa.X - w - 6
		end
		x = clamp(x, 4, math.max(vp.X - w - 4, 4))
		local y = clamp(row.AbsolutePosition.Y, 4, math.max(vp.Y - 80, 4))
		sub.Frame.Position = UDim2.fromOffset(x, y)
	end

	local function build()
		if sub then
			return
		end
		sub = lib:CreateWindow({
			Title = opts.Title or name,
			Size = Vector2.new(opts.Width or 160, opts.Height or 150),
			Scale = win.Scale,
			ItemWidth = opts.ItemWidth or 0.5,
			Resizable = opts.Resizable,
			OnClose = function()
				obj.IsOpen = false
				refresh()
			end
		})
		sub.Parent = win
		sub.Tracked = win.Tracked
		sub.TrackCount = win.TrackCount
		sub.Registry = win.Registry
		sub.Visible = false
		sub.Frame.Visible = false
		obj.Window = sub
		if builder then
			builder(sub, obj)
		end
		win:Focus()
	end

	function obj.Open()
		build()
		if opts.Group then
			lib.PanelGroups = lib.PanelGroups or {}
			local g = lib.PanelGroups[opts.Group] or {}
			lib.PanelGroups[opts.Group] = g
			local known = false
			for _, o in g do
				if o == obj then
					known = true
				elseif o.IsOpen then
					o.Close()
				end
			end
			if not known then
				table.insert(g, obj)
			end
		end
		obj.IsOpen = true
		sub:SetVisible(true)
		place()
		sub:Focus()
		refresh()
	end

	function obj.Close()
		if sub and obj.IsOpen then
			obj.IsOpen = false
			sub:SetVisible(false)
			refresh()
		end
	end

	function obj.Toggle()
		if obj.IsOpen then
			obj.Close()
		else
			obj.Open()
		end
	end

	btn.MouseButton1Click:Connect(obj.Toggle)
	if opts.Prebuild ~= false then
		build()
	end
	refresh()
	return obj
end

function Container:Switch(name, default, callback)
	local row = self:_row(FH)
	local hit = new("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X
	}, row)
	list(hit, 6, true)
	local track = frame(hit, T.Frame, {Size = UDim2.fromOffset(30, FH - 5), LayoutOrder = 1})
	local K = FH - 9
	local knob = frame(track, {Color3.new(1, 1, 1), 0}, {
		Size = UDim2.fromOffset(K, K),
		Position = UDim2.fromOffset(2, 2)
	})
	local nameLabel = label(hit, name, {Size = UDim2.new(0, textWidth(name) + 4, 1, 0), LayoutOrder = 2})
	clampHit(self, row, hit, nameLabel, 36)
	local state = {Value = default and true or false, Frame = row}
	local ready = false
	local function render()
		local pos = UDim2.fromOffset(state.Value and (30 - K - 2) or 2, 2)
		if ready and Settings.Anim then
			TweenService:Create(knob, FADE, {Position = pos}):Play()
		else
			knob.Position = pos
		end
		paint(track, state.Value and {T.CheckMark, 0} or T.Frame)
	end
	function state.Set(v, fire)
		state.Value = v and true or false
		render()
		if fire and callback then
			task.spawn(callback, state.Value)
		end
	end
	function state.Get()
		return state.Value
	end
	hit.MouseButton1Click:Connect(function()
		if UIHooks.Click then
			UIHooks.Click()
		end
		state.Set(not state.Value, true)
	end)
	render()
	ready = true
	return state
end

function Container:Segmented(name, items, default, callback)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local hasName = name and name ~= ""
	local holder = new("Frame", {
		BackgroundTransparency = 1,
		Size = hasName and UDim2.new(iw, -4, 1, 0) or UDim2.fromScale(1, 1)
	}, row)
	list(holder, 2, true)
	if hasName then
		label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	end
	local n = #items
	local state = {Value = default or items[1], Frame = row, Sts = {}}
	local function render()
		for item, st in state.Sts do
			st.Normal = item == state.Value and T.TabActive or T.Tab
			st.Refresh()
		end
	end
	for i, item in items do
		local b = button(holder, T.Tab, {
			Size = UDim2.new(1 / n, -2 * (n - 1) / n, 1, 0),
			Text = tostring(item),
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = i
		})
		state.Sts[item] = bind(b, T.Tab, T.TabHover, T.TabActive)
		b.MouseButton1Click:Connect(function()
			state.Set(item, true)
		end)
	end
	function state.Set(v, fire)
		state.Value = v
		render()
		if fire and callback then
			task.spawn(callback, v)
		end
	end
	function state.Get()
		return state.Value
	end
	render()
	return state
end

function Container:Knob(name, min, max, default, callback, opts)
	opts = opts or {}
	local win = self.Win
	local size = opts.Size or 44
	local row = self:_row(size + 4, true)
	local area = button(row, T.Frame, {Size = UDim2.fromOffset(size, size), Position = UDim2.fromOffset(2, 2)})
	new("UICorner", {CornerRadius = UDim.new(1, 0)}, area)
	stroke(area, T.Border)
	local R = size / 2
	local N = 20
	local dots = {}
	for i = 1, N do
		local ang = math.rad(-135 + 270 * (i - 1) / (N - 1))
		local d = frame(area, T.Separator, {
			Size = UDim2.fromOffset(3, 3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(R + math.sin(ang) * (R - 5), R - math.cos(ang) * (R - 5))
		})
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, d)
		dots[i] = d
	end
	local pointer = frame(area, {T.CheckMark, 0}, {
		Size = UDim2.fromOffset(7, 7),
		AnchorPoint = Vector2.new(0.5, 0.5)
	})
	new("UICorner", {CornerRadius = UDim.new(1, 0)}, pointer)
	label(row, name, {Size = UDim2.new(1, -(size + 10), 0, FH), Position = UDim2.fromOffset(size + 8, 4)})
	local valueLabel = label(row, "", {
		Size = UDim2.new(1, -(size + 10), 0, FH),
		Position = UDim2.fromOffset(size + 8, 4 + FH),
		TextColor3 = T.TextDisabled
	})
	local state = {Value = default or min, Min = min, Max = max, Frame = row}
	local function fmt(v)
		if opts.Format then
			return string.format(opts.Format, v)
		end
		if opts.Int then
			return string.format("%d", v)
		end
		return string.format("%.2f", v)
	end
	local function render()
		local r = max > min and clamp((state.Value - min) / (max - min), 0, 1) or 0
		local lit = math.floor(r * N + 0.5)
		for i = 1, N do
			paint(dots[i], i <= lit and {T.CheckMark, 0} or T.Separator)
		end
		local ang = math.rad(-135 + 270 * r)
		pointer.Position = UDim2.fromOffset(R + math.sin(ang) * (R - 14), R - math.cos(ang) * (R - 14))
		valueLabel.Text = fmt(state.Value)
	end
	function state.Set(v, fire)
		v = clamp(v, min, max)
		if opts.Int then
			v = math.floor(v + 0.5)
		else
			v = math.floor(v * 1000000 + 0.5) / 1000000
		end
		local changed = v ~= state.Value
		state.Value = v
		render()
		if fire and changed and callback then
			task.spawn(callback, v)
		end
	end
	function state.Get()
		return state.Value
	end
	area.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local base = state.Value
		win.Body.ScrollingEnabled = false
		beginDrag(input, function(pos)
			local d = (pos.X - start.X) - (pos.Y - start.Y)
			state.Set(base + d / (150 * win.Scale) * (max - min), true)
		end, function()
			win.Body.ScrollingEnabled = true
		end)
	end)
	render()
	return state
end

function Library:Numpad(initial, onSubmit, opts)
	opts = opts or {}
	local gui = self.Gui
	local text = ""
	if initial ~= nil then
		text = opts.Int and string.format("%d", initial) or tostring(initial)
	end
	local W = 204
	local blocker = button(gui, tok(0, 0, 0, 0.5), {Size = UDim2.fromScale(1, 1), ZIndex = 1200})
	local box = frame(blocker, T.WindowBg, {
		Size = UDim2.fromOffset(W, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 1201,
		Active = true
	})
	stroke(box, T.Border)
	pad(box, 6, 6, 6, 6)
	list(box, 6).VerticalAlignment = Enum.VerticalAlignment.Top
	label(box, opts.Title or "输入数值", {Size = UDim2.new(1, 0, 0, FH), LayoutOrder = 1})
	local display = label(box, "", {
		Size = UDim2.new(1, 0, 0, FH + 6),
		BackgroundTransparency = T.FrameActive[2],
		BackgroundColor3 = T.FrameActive[1],
		TextXAlignment = Enum.TextXAlignment.Right,
		LayoutOrder = 2
	})
	pad(display, 6, 6, 0, 0)
	local function show()
		display.Text = text == "" and "0" or text
	end
	local grid = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 5 * 28 + 4 * 4),
		LayoutOrder = 3
	}, box)
	new("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -3, 0, 28),
		CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, grid)
	local function close()
		if blocker.Parent then
			blocker:Destroy()
		end
	end
	local function submit()
		local n = tonumber(text)
		if not n then
			return
		end
		if opts.Min then
			n = math.max(n, opts.Min)
		end
		if opts.Max then
			n = math.min(n, opts.Max)
		end
		if opts.Int then
			n = math.floor(n + 0.5)
		end
		close()
		if onSubmit then
			task.spawn(onSubmit, n)
		end
	end
	local function press(k)
		if k == "清空" then
			text = ""
		elseif k == "退格" then
			text = string.sub(text, 1, -2)
		elseif k == "+/-" then
			if string.sub(text, 1, 1) == "-" then
				text = string.sub(text, 2)
			else
				text = "-" .. text
			end
		elseif k == "." then
			if not opts.Int and not string.find(text, ".", 1, true) then
				if text == "" or text == "-" then
					text = text .. "0"
				end
				text = text .. "."
			end
		elseif k == "确定" then
			submit()
			return
		else
			if text == "0" then
				text = k
			elseif text == "-0" then
				text = "-" .. k
			else
				text = text .. k
			end
		end
		show()
	end
	local keys = {"7", "8", "9", "4", "5", "6", "1", "2", "3", "+/-", "0", ".", "清空", "退格", "确定"}
	for i, k in keys do
		local n, h, pr = T.Button, T.ButtonHover, T.ButtonActive
		if k == "确定" then
			n, h, pr = colorTokens(Color3.fromRGB(60, 150, 85))
		elseif k == "清空" or k == "退格" then
			n, h, pr = T.Frame, T.FrameHover, T.FrameActive
		end
		local b = button(grid, n, {Text = k, LayoutOrder = i})
		bind(b, n, h, pr)
		b.MouseButton1Click:Connect(function()
			press(k)
		end)
	end
	blocker.MouseButton1Click:Connect(close)
	show()
	return {Close = close}
end

function Container:NumberPad(name, default, callback, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local btn = button(row, T.Frame, {Size = UDim2.new(iw, -4, 1, 0)})
	bind(btn, T.Frame, T.FrameHover, T.FrameActive)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local state = {Value = default or 0, Frame = row}
	local function show()
		btn.Text = opts.Int and string.format("%d", state.Value) or tostring(state.Value)
	end
	function state.Set(v, fire)
		if opts.Min then
			v = math.max(v, opts.Min)
		end
		if opts.Max then
			v = math.min(v, opts.Max)
		end
		state.Value = v
		show()
		if fire and callback then
			task.spawn(callback, v)
		end
	end
	function state.Get()
		return state.Value
	end
	btn.MouseButton1Click:Connect(function()
		win.Lib:Numpad(state.Value, function(n)
			state.Set(n, true)
		end, {Int = opts.Int, Min = opts.Min, Max = opts.Max, Title = name})
	end)
	show()
	return state
end

function Container:Autocomplete(name, items, default, callback, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local box = new("TextBox", {
		BackgroundColor3 = T.Frame[1],
		BackgroundTransparency = T.Frame[2],
		BorderSizePixel = 0,
		Size = UDim2.new(iw, -4, 1, 0),
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		PlaceholderText = opts.Placeholder or "输入搜索...",
		PlaceholderColor3 = T.TextDisabled,
		Text = default or "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left
	}, row)
	pad(box, 4, 4, 0, 0)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local state = {Value = default or "", Items = items, Frame = row}
	local drop
	local choosing = false
	local function closeDrop()
		if drop then
			drop:Destroy()
			drop = nil
		end
	end
	local function choose(item)
		choosing = true
		box.Text = tostring(item)
		state.Value = box.Text
		closeDrop()
		if callback then
			task.spawn(callback, state.Value, true)
		end
		box:ReleaseFocus()
		choosing = false
	end
	local function open()
		closeDrop()
		local q = string.lower(box.Text)
		local starts, contains = {}, {}
		for _, it in state.Items do
			local lname = string.lower(tostring(it))
			if q == "" or string.sub(lname, 1, #q) == q then
				table.insert(starts, it)
			elseif string.find(lname, q, 1, true) then
				table.insert(contains, it)
			end
		end
		local matches = {}
		for _, it in starts do
			table.insert(matches, it)
		end
		for _, it in contains do
			table.insert(matches, it)
		end
		local count = math.min(#matches, opts.Max or 6)
		if count == 0 then
			return
		end
		local s = win.Scale
		local abs = box.AbsolutePosition
		local origin = win.Frame.AbsolutePosition
		drop = frame(win.Frame, T.PopupBg, {
			Size = UDim2.fromOffset(box.AbsoluteSize.X / s, count * FH),
			Position = UDim2.fromOffset((abs.X - origin.X) / s, (abs.Y + box.AbsoluteSize.Y - origin.Y) / s),
			ZIndex = 95
		})
		stroke(drop, T.Border)
		for i = 1, count do
			local item = matches[i]
			local b = button(drop, T.Clear, {
				Size = UDim2.new(1, 0, 0, FH),
				Position = UDim2.fromOffset(0, (i - 1) * FH),
				Text = tostring(item),
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 96
			})
			pad(b, 4, 4, 0, 0)
			bind(b, T.Clear, T.HeaderHover, T.HeaderActive)
			b.InputBegan:Connect(function(input)
				if isPress(input) then
					choose(item)
				end
			end)
		end
	end
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if box:IsFocused() then
			open()
		end
	end)
	win.Body:GetPropertyChangedSignal("CanvasPosition"):Connect(closeDrop)
	box.Focused:Connect(function()
		paint(box, T.FrameActive)
		open()
	end)
	box.FocusLost:Connect(function()
		paint(box, T.Frame)
		task.delay(0.2, closeDrop)
		if not choosing then
			state.Value = box.Text
			if callback then
				task.spawn(callback, state.Value, false)
			end
		end
	end)
	function state.Set(v, fire)
		state.Value = tostring(v)
		box.Text = state.Value
		if fire and callback then
			task.spawn(callback, state.Value, false)
		end
	end
	function state.Get()
		return state.Value
	end
	function state.SetItems(newItems)
		state.Items = newItems
	end
	return state
end

local ALERT_COLORS = {
	Info = Color3.fromRGB(66, 150, 250),
	Success = Color3.fromRGB(80, 220, 120),
	Warn = Color3.fromRGB(240, 190, 60),
	Error = Color3.fromRGB(240, 90, 90)
}

function Container:Alert(text, kind, opts)
	opts = opts or {}
	self._n = self._n + 1
	local color = ALERT_COLORS[kind or "Info"] or ALERT_COLORS.Info
	local card = frame(self.Content, T.Frame, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._n
	})
	local edge = frame(card, {color, 0}, {Size = UDim2.new(0, 3, 1, 0), ZIndex = 2})
	local closable = opts.Closable == true
	local content = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(3, 0),
		Size = UDim2.new(1, -3, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y
	}, card)
	pad(content, 8, closable and FH + 4 or 8, 4, 4)
	list(content, 2).VerticalAlignment = Enum.VerticalAlignment.Top
	local titleLabel
	if opts.Title then
		titleLabel = label(content, opts.Title, {
			Size = UDim2.new(1, 0, 0, FH - 2),
			TextColor3 = color,
			LayoutOrder = 1
		})
	end
	label(content, text or "", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2
	})
	local obj = {Frame = card}
	if closable then
		local x = button(card, T.Clear, {
			Size = UDim2.fromOffset(FH, FH),
			Position = UDim2.new(1, -(FH + 1), 0, 1),
			Text = "x",
			TextColor3 = color,
			ZIndex = 3
		})
		bind(x, T.Clear, T.HeaderHover, T.HeaderActive)
		x.MouseButton1Click:Connect(function()
			card.Visible = false
			if opts.OnClose then
				task.spawn(opts.OnClose)
			end
		end)
	end
	function obj.Set(str, k)
		for _, c in content:GetChildren() do
			if c:IsA("TextLabel") and c ~= titleLabel then
				c.Text = str
			end
		end
		if k and ALERT_COLORS[k] then
			edge.BackgroundColor3 = ALERT_COLORS[k]
			if titleLabel then
				titleLabel.TextColor3 = ALERT_COLORS[k]
			end
		end
	end
	function obj.Show()
		card.Visible = true
	end
	function obj.Close()
		card.Visible = false
	end
	return obj
end

function Container:Stat(title, value, opts)
	opts = opts or {}
	self._n = self._n + 1
	local card = frame(self.Content, T.Inset, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._n
	})
	stroke(card, T.Border)
	pad(card, 8, 8, 5, 5)
	list(card, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	label(card, title, {Size = UDim2.new(1, 0, 0, FH - 3), TextColor3 = T.TextDisabled, LayoutOrder = 1})
	local valueLabel = label(card, tostring(value), {
		Size = UDim2.new(1, 0, 0, 26),
		TextSize = 22,
		TextColor3 = opts.Color or T.Text,
		LayoutOrder = 2
	})
	local deltaLabel = label(card, "", {Size = UDim2.new(1, 0, 0, FH - 3), LayoutOrder = 3})
	local obj = {Frame = card}
	local function setDelta(d, sub)
		local str = ""
		if d ~= nil then
			local n = tonumber(d)
			if n then
				str = (n >= 0 and "+" or "") .. tostring(n) .. (opts.DeltaSuffix or "%")
				deltaLabel.TextColor3 = n >= 0 and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(240, 90, 90)
			else
				str = tostring(d)
				deltaLabel.TextColor3 = T.TextDisabled
			end
		end
		if sub then
			str = str .. (str ~= "" and "  " or "") .. sub
		end
		deltaLabel.Text = str
		deltaLabel.Visible = str ~= ""
	end
	function obj.Set(v, d, sub)
		valueLabel.Text = tostring(v)
		setDelta(d, sub)
	end
	setDelta(opts.Delta, opts.Sub)
	return obj
end

function Container:Lock(opts)
	opts = opts or {}
	local win = self.Win
	local lib = win.Lib
	self._n = self._n + 1
	local card = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._n
	}, self.Content)
	new("UISizeConstraint", {MinSize = Vector2.new(0, 96)}, card)
	local body = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y
	}, card)
	list(body, GAP).VerticalAlignment = Enum.VerticalAlignment.Top
	local content = makeContainer(win, body)
	content.Frame = card
	local overlay = button(card, {T.PopupBg[1], opts.Preview == false and 0.02 or 0.4}, {
		Size = UDim2.fromScale(1, 1),
		ZIndex = 30
	})
	stroke(overlay, T.Border)
	local inner = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y
	}, overlay)
	local il = list(inner, 4)
	il.HorizontalAlignment = Enum.HorizontalAlignment.Center
	local iconHolder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 18), LayoutOrder = 1}, inner)
	local shackle = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(8, 10),
		Position = UDim2.fromOffset(4, 0)
	}, iconHolder)
	new("UICorner", {CornerRadius = UDim.new(1, 0)}, shackle)
	local shackleStroke = new("UIStroke", {Color = T.Grab[1], Thickness = 2}, shackle)
	local lockBody = frame(iconHolder, T.Grab, {Size = UDim2.fromOffset(16, 10), Position = UDim2.fromOffset(0, 8)})
	new("UICorner", {CornerRadius = UDim.new(0, 2)}, lockBody)
	label(inner, opts.Title or "功能已锁定", {
		Size = UDim2.new(1, 0, 0, FH),
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2
	})
	if opts.Hint then
		label(inner, opts.Hint, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = T.TextDisabled,
			LayoutOrder = 3
		})
	end
	local unlockHolder = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 4
	}, inner)
	list(unlockHolder, 4).VerticalAlignment = Enum.VerticalAlignment.Top
	local uc = makeContainer(win, unlockHolder)

	content.Locked = true
	local passBox

	local function unlock()
		if not content.Locked then
			return
		end
		content.Locked = false
		overlay.Visible = false
		if passBox then
			passBox.Text = ""
		end
		if not opts.Silent then
			lib:Notify({Title = "解锁", Content = (opts.Title or "功能") .. " 已解锁", Type = "Success"})
		end
		if opts.OnUnlock then
			task.spawn(opts.OnUnlock)
		end
	end

	local function lockAgain()
		content.Locked = true
		overlay.Visible = true
	end

	local function checkKey(text)
		local key = opts.Key
		if type(key) == "function" then
			local ok, r = pcall(key, text)
			return ok and r
		elseif type(key) == "table" then
			for _, k in key do
				if k == text then
					return true
				end
			end
			return false
		end
		return key ~= nil and text == tostring(key)
	end

	local mode = opts.Mode or (opts.Key ~= nil and "password" or (opts.Condition and "auto" or "button"))
	if mode == "password" then
		local prow = uc:_row(FH, true)
		passBox = new("TextBox", {
			BackgroundColor3 = T.Frame[1],
			BackgroundTransparency = T.Frame[2],
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Font = FONT,
			TextSize = TS,
			TextColor3 = T.Text,
			PlaceholderText = opts.Placeholder or "输入密钥",
			PlaceholderColor3 = T.TextDisabled,
			Text = "",
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center
		}, prow)
		local function try()
			if checkKey(passBox.Text) then
				unlock()
			else
				lib:Notify({Title = "解锁", Content = "密钥错误", Type = "Error"})
				if opts.OnFail then
					task.spawn(opts.OnFail, passBox.Text)
				end
			end
		end
		passBox.FocusLost:Connect(function(enter)
			if enter then
				try()
			end
		end)
		uc:Button("解锁", try)
	elseif mode == "slide" then
		uc:SlideConfirm("滑动解锁", unlock)
	elseif mode == "hold" then
		uc:HoldButton("长按解锁", opts.Duration or 1.2, unlock)
	elseif mode == "button" then
		uc:Button("解锁", unlock)
	end

	if opts.Condition then
		local acc = 0
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if not card.Parent then
				conn:Disconnect()
				return
			end
			acc = acc + dt
			if acc >= 0.5 then
				acc = 0
				if content.Locked then
					local ok, r = pcall(opts.Condition)
					if ok and r then
						unlock()
					end
				end
			end
		end)
		table.insert(Library.Conns, conn)
	end

	table.insert(Library.ThemeHooks, function()
		overlay.BackgroundColor3 = T.PopupBg[1]
		shackleStroke.Color = T.Grab[1]
	end)

	content.Unlock = unlock
	content.Lock = lockAgain
	function content.IsLocked()
		return content.Locked
	end
	if opts.Relock then
		content:SmallButton("重新锁定", lockAgain)
	end
	if opts.Unlocked then
		unlock()
	end
	return content
end

wrap("Switch", function(win, o, name)
	win:_track("Switch", name, function()
		return o.Value
	end, function(v)
		o.Set(v, true)
	end)
	win:_register(name, function()
		o.Set(not o.Value, true)
	end, "开关")
end)
for _, method in {"Segmented", "Knob", "NumberPad", "Autocomplete"} do
	wrap(method, function(win, o, name)
		win:_track(method, name, function()
			return o.Value
		end, function(v)
			o.Set(v, true)
		end)
	end)
end

local function daysIn(y, m)
	return os.date("*t", os.time({year = y, month = m + 1, day = 0, hour = 12})).day
end

local function weekdayOf(y, m, d)
	return os.date("*t", os.time({year = y, month = m, day = d, hour = 12})).wday
end

local function parseDate(v)
	if type(v) == "table" then
		return {Year = v.Year or v[1], Month = v.Month or v[2], Day = v.Day or v[3]}
	elseif type(v) == "string" then
		local y, m, d = v:match("(%d+)-(%d+)-(%d+)")
		if y then
			return {Year = tonumber(y), Month = tonumber(m), Day = tonumber(d)}
		end
	end
	local now = os.date("*t")
	return {Year = now.year, Month = now.month, Day = now.day}
end

local CAL_HEIGHT = FH * 8 + 14

local function buildCalendar(parent, state, onPick)
	local view = {Year = state.Year, Month = state.Month}
	local now = os.date("*t")
	local prev = button(parent, T.Button, {Size = UDim2.fromOffset(FH + 6, FH), Position = UDim2.fromOffset(4, 4), Text = "<"})
	local nextB = button(parent, T.Button, {
		Size = UDim2.fromOffset(FH + 6, FH),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 4),
		Text = ">"
	})
	bind(prev, T.Button, T.ButtonHover, T.ButtonActive)
	bind(nextB, T.Button, T.ButtonHover, T.ButtonActive)
	local title = label(parent, "", {
		Size = UDim2.new(1, -2 * (FH + 10), 0, FH),
		Position = UDim2.fromOffset(FH + 10, 4),
		TextXAlignment = Enum.TextXAlignment.Center
	})
	local grid = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(4, 0),
		Size = UDim2.new(1, -8, 1, 0)
	}, parent)
	for i, d in {"日", "一", "二", "三", "四", "五", "六"} do
		label(grid, d, {
			Size = UDim2.new(1 / 7, 0, 0, FH - 3),
			Position = UDim2.new((i - 1) / 7, 0, 0, FH + 8),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = T.TextDisabled
		})
	end
	local cells = {}
	local function render()
		for _, c in cells do
			c:Destroy()
		end
		cells = {}
		title.Text = string.format("%d年%d月", view.Year, view.Month)
		local first = weekdayOf(view.Year, view.Month, 1)
		for d = 1, daysIn(view.Year, view.Month) do
			local idx = first - 1 + d - 1
			local selected = state.Year == view.Year and state.Month == view.Month and state.Day == d
			local today = now.year == view.Year and now.month == view.Month and now.day == d
			local normal = selected and T.Button or (today and T.Header or T.Clear)
			local b = button(grid, normal, {
				Size = UDim2.new(1 / 7, -2, 0, FH - 1),
				Position = UDim2.new((idx % 7) / 7, 1, 0, 2 * FH + 10 + math.floor(idx / 7) * FH),
				Text = tostring(d)
			})
			bind(b, normal, T.HeaderHover, T.HeaderActive)
			b.MouseButton1Click:Connect(function()
				state.Year, state.Month, state.Day = view.Year, view.Month, d
				onPick(state)
				render()
			end)
			table.insert(cells, b)
		end
	end
	prev.MouseButton1Click:Connect(function()
		view.Month = view.Month - 1
		if view.Month < 1 then
			view.Month = 12
			view.Year = view.Year - 1
		end
		render()
	end)
	nextB.MouseButton1Click:Connect(function()
		view.Month = view.Month + 1
		if view.Month > 12 then
			view.Month = 1
			view.Year = view.Year + 1
		end
		render()
	end)
	render()
end

local function dateString(v)
	return string.format("%04d-%02d-%02d", v.Year, v.Month, v.Day)
end

function Container:Calendar(default, callback)
	local row = self:_row(CAL_HEIGHT, true)
	local back = frame(row, T.Inset, {Size = UDim2.new(1, 0, 0, CAL_HEIGHT)})
	new("UISizeConstraint", {MaxSize = Vector2.new(260, CAL_HEIGHT)}, back)
	stroke(back, T.Border)
	local state = parseDate(default)
	local obj = {Frame = row, Value = state}
	function obj.Get()
		return {Year = state.Year, Month = state.Month, Day = state.Day}
	end
	function obj.GetString()
		return dateString(state)
	end
	buildCalendar(back, state, function()
		if callback then
			task.spawn(callback, obj.Get(), dateString(state))
		end
	end)
	return obj
end

function Container:DatePicker(name, default, callback)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = self.ItemWidth or win.ItemWidth
	local btn = button(row, T.Frame, {Size = UDim2.new(iw, -4, 1, 0)})
	bind(btn, T.Frame, T.FrameHover, T.FrameActive)
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	local state = {Value = parseDate(default), Frame = row}
	local function show()
		btn.Text = dateString(state.Value)
	end
	function state.Set(v, fire)
		state.Value = parseDate(v)
		show()
		if fire and callback then
			task.spawn(callback, state.Get(), dateString(state.Value))
		end
	end
	function state.Get()
		return {Year = state.Value.Year, Month = state.Value.Month, Day = state.Value.Day}
	end
	function state.GetString()
		return dateString(state.Value)
	end
	btn.MouseButton1Click:Connect(function()
		win:_popup(btn, 196, CAL_HEIGHT, function(pop)
			buildCalendar(pop, state.Value, function()
				show()
				if callback then
					task.spawn(callback, state.Get(), dateString(state.Value))
				end
				win:_closePopup()
			end)
		end)
	end)
	show()
	return state
end

function Container:Curve(name, points, height, callback, opts)
	opts = opts or {}
	local win = self.Win
	if name and name ~= "" then
		self:Text(name)
	end
	local row = self:_row(height or 110, true)
	local area = button(row, T.Frame, {Size = UDim2.fromScale(1, 1)})
	stroke(area, T.Border)
	for _, f in {0.25, 0.5, 0.75} do
		frame(area, T.Separator, {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, f, 0)})
		frame(area, T.Separator, {Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(f, 0, 0, 0)})
	end
	local pts = {}
	for _, pt in points or {{0, 0}, {1, 1}} do
		table.insert(pts, {clamp(pt[1], 0, 1), clamp(pt[2], 0, 1)})
	end
	table.sort(pts, function(a, b)
		return a[1] < b[1]
	end)
	local obj = {Frame = row, Points = pts, Selected = nil, Smooth = opts.Smooth ~= false}
	local lines, dots = {}, {}

	local function eval(t)
		local n = #pts
		if t <= pts[1][1] then
			return pts[1][2]
		end
		if t >= pts[n][1] then
			return pts[n][2]
		end
		for i = 1, n - 1 do
			local a, b = pts[i], pts[i + 1]
			if t >= a[1] and t <= b[1] then
				local u = (t - a[1]) / math.max(b[1] - a[1], 0.00001)
				if obj.Smooth then
					u = (1 - math.cos(math.pi * u)) / 2
				end
				return a[2] + (b[2] - a[2]) * u
			end
		end
		return pts[n][2]
	end
	obj.Evaluate = eval

	local function size()
		local as = area.AbsoluteSize
		local sc = win.Scale
		if as.X <= 0 or as.Y <= 0 then
			return 280, height or 110
		end
		return as.X / sc, as.Y / sc
	end

	local function redraw()
		local W, H = size()
		local N = 48
		for i = 1, N do
			local x1, x2 = (i - 1) / N, i / N
			local p1 = Vector2.new(x1 * W, (1 - eval(x1)) * H)
			local p2 = Vector2.new(x2 * W, (1 - eval(x2)) * H)
			local mid = (p1 + p2) / 2
			local d = p2 - p1
			local line = lines[i]
			if not line then
				line = frame(area, T.Grab, {AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 2})
				lines[i] = line
			end
			line.Size = UDim2.fromOffset(d.Magnitude + 1.5, 2)
			line.Position = UDim2.fromOffset(mid.X, mid.Y)
			line.Rotation = math.deg(math.atan2(d.Y, d.X))
		end
		for i, pt in pts do
			if dots[i] then
				dots[i].Position = UDim2.new(pt[1], 0, 1 - pt[2], 0)
			end
		end
	end

	local function fire()
		if callback then
			local out = {}
			for i, pt in pts do
				out[i] = {pt[1], pt[2]}
			end
			task.spawn(callback, out)
		end
	end

	local function paintDots()
		for i, d in dots do
			paint(d, i == obj.Selected and T.GrabActive or T.Grab)
		end
	end

	local function rebuildDots()
		for _, d in dots do
			d:Destroy()
		end
		dots = {}
		for i = 1, #pts do
			local d = button(area, T.Grab, {
				Size = UDim2.fromOffset(12, 12),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = 4
			})
			stroke(d, T.Border)
			dots[i] = d
			d.InputBegan:Connect(function(input)
				if not isPress(input) then
					return
				end
				obj.Selected = i
				paintDots()
				win.Body.ScrollingEnabled = false
				beginDrag(input, function(pos)
					local ap, as = area.AbsolutePosition, area.AbsoluteSize
					local nx = clamp((pos.X - ap.X) / math.max(as.X, 1), 0, 1)
					local ny = 1 - clamp((pos.Y - ap.Y) / math.max(as.Y, 1), 0, 1)
					local p = pts[i]
					if opts.FixedEnds ~= false and (i == 1 or i == #pts) then
						nx = p[1]
					else
						local lo = i > 1 and pts[i - 1][1] + 0.001 or 0
						local hi = i < #pts and pts[i + 1][1] - 0.001 or 1
						nx = clamp(nx, lo, hi)
					end
					p[1], p[2] = nx, ny
					redraw()
					fire()
				end, function()
					win.Body.ScrollingEnabled = true
				end)
			end)
		end
		paintDots()
		redraw()
	end

	area.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local last = start
		beginDrag(input, function(pos)
			last = pos
		end, function()
			if (last - start).Magnitude < 6 then
				local ap, as = area.AbsolutePosition, area.AbsoluteSize
				local nx = clamp((start.X - ap.X) / math.max(as.X, 1), 0.01, 0.99)
				local ny = 1 - clamp((start.Y - ap.Y) / math.max(as.Y, 1), 0, 1)
				table.insert(pts, {nx, ny})
				table.sort(pts, function(a, b)
					return a[1] < b[1]
				end)
				for i, pt in pts do
					if pt[1] == nx and pt[2] == ny then
						obj.Selected = i
					end
				end
				rebuildDots()
				fire()
			end
		end)
	end)
	area:GetPropertyChangedSignal("AbsoluteSize"):Connect(redraw)

	function obj.Get()
		local out = {}
		for i, pt in pts do
			out[i] = {pt[1], pt[2]}
		end
		return out
	end
	function obj.Set(newPts, doFire)
		for i = #pts, 1, -1 do
			table.remove(pts, i)
		end
		for _, pt in newPts do
			table.insert(pts, {clamp(pt[1], 0, 1), clamp(pt[2], 0, 1)})
		end
		table.sort(pts, function(a, b)
			return a[1] < b[1]
		end)
		obj.Selected = nil
		rebuildDots()
		if doFire then
			fire()
		end
	end

	local bar = self:Row()
	bar:SmallButton("删除选中", function()
		local i = obj.Selected
		if i and #pts > 2 and not (opts.FixedEnds ~= false and (i == 1 or i == #pts)) then
			table.remove(pts, i)
			obj.Selected = nil
			rebuildDots()
			fire()
		end
	end)
	bar:SmallButton("重置", function()
		obj.Set({{0, 0}, {1, 1}}, true)
	end)
	bar:SmallButton("平滑/折线", function()
		obj.Smooth = not obj.Smooth
		redraw()
		fire()
	end)
	rebuildDots()
	return obj
end

function Container:Gradient(name, stops, callback)
	local win = self.Win
	if name and name ~= "" then
		self:Text(name)
	end
	local list_ = {}
	for _, st in stops or {{0, Color3.fromRGB(66, 150, 250)}, {1, Color3.fromRGB(150, 90, 250)}} do
		table.insert(list_, {T = clamp(st[1], 0, 1), C = st[2]})
	end
	local function sorted()
		table.sort(list_, function(a, b)
			return a.T < b.T
		end)
	end
	sorted()
	local row = self:_row(FH + 16, true)
	local bar = frame(row, {Color3.new(1, 1, 1), 0}, {Size = UDim2.new(1, -10, 0, FH), Position = UDim2.fromOffset(5, 0)})
	stroke(bar, T.Border)
	local grad = new("UIGradient", {}, bar)
	local obj = {Frame = row, Stops = list_, Selected = 1}
	local markers = {}
	local edit

	local function sequence()
		sorted()
		local n = #list_
		local times = {}
		for i = 1, n do
			times[i] = clamp(list_[i].T, 0, 1)
		end
		for i = 2, n do
			if times[i] <= times[i - 1] then
				times[i] = times[i - 1] + 0.0001
			end
		end
		if times[n] > 1 then
			times[n] = 1
			for i = n - 1, 1, -1 do
				if times[i] >= times[i + 1] then
					times[i] = times[i + 1] - 0.0001
				end
			end
		end
		if times[1] < 0 then
			times[1] = 0
		end
		local kps = {}
		if times[1] > 0 then
			table.insert(kps, ColorSequenceKeypoint.new(0, list_[1].C))
		end
		for i = 1, n do
			table.insert(kps, ColorSequenceKeypoint.new(times[i], list_[i].C))
		end
		if times[n] < 1 then
			table.insert(kps, ColorSequenceKeypoint.new(1, list_[n].C))
		end
		return ColorSequence.new(kps)
	end

	local function fire()
		if callback then
			local out = {}
			for i, st in list_ do
				out[i] = {st.T, st.C}
			end
			task.spawn(callback, out)
		end
	end

	local function layoutMarkers()
		for i, st in list_ do
			if markers[i] then
				markers[i].Position = UDim2.new(st.T, -5 + (1 - 2 * st.T) * 5 / 1, 0, FH + 1)
			end
		end
	end

	local function paintMarkers()
		for i, m in markers do
			paint(m, i == obj.Selected and T.GrabActive or T.Button)
		end
	end

	local function update()
		grad.Color = sequence()
		layoutMarkers()
	end

	local rebuild
	function rebuild()
		for _, m in markers do
			m:Destroy()
		end
		markers = {}
		sorted()
		for i, st in list_ do
			local m = button(bar, T.Button, {Size = UDim2.fromOffset(10, 14), ZIndex = 4})
			stroke(m, T.Border)
			markers[i] = m
			m.InputBegan:Connect(function(input)
				if not isPress(input) then
					return
				end
				obj.Selected = i
				paintMarkers()
				if edit then
					edit.Set(st.C, false)
				end
				win.Body.ScrollingEnabled = false
				beginDrag(input, function(pos)
					local ap, as = bar.AbsolutePosition, bar.AbsoluteSize
					st.T = clamp((pos.X - ap.X) / math.max(as.X, 1), 0, 1)
					update()
					fire()
				end, function()
					win.Body.ScrollingEnabled = true
					local current = st
					sorted()
					for k, v in list_ do
						if v == current then
							obj.Selected = k
						end
					end
					rebuild()
				end)
			end)
		end
		paintMarkers()
		update()
	end

	edit = self:ColorEdit("色标颜色", list_[1].C, function(c)
		local st = list_[obj.Selected]
		if st then
			st.C = c
			update()
			fire()
		end
	end)

	local function evaluate(t)
		sorted()
		if t <= list_[1].T then
			return list_[1].C
		end
		for i = 1, #list_ - 1 do
			local a, b = list_[i], list_[i + 1]
			if t <= b.T then
				return a.C:Lerp(b.C, (t - a.T) / math.max(b.T - a.T, 0.00001))
			end
		end
		return list_[#list_].C
	end
	obj.Evaluate = evaluate

	local btns = self:Row()
	btns:SmallButton("添加色标", function()
		sorted()
		local best, gap = 1, -1
		for i = 1, #list_ - 1 do
			local g = list_[i + 1].T - list_[i].T
			if g > gap then
				best, gap = i, g
			end
		end
		local t = (list_[best].T + (list_[best + 1] and list_[best + 1].T or 1)) / 2
		table.insert(list_, {T = t, C = evaluate(t)})
		sorted()
		for k, v in list_ do
			if v.T == t then
				obj.Selected = k
			end
		end
		rebuild()
		edit.Set(list_[obj.Selected].C, false)
		fire()
	end)
	btns:SmallButton("删除色标", function()
		if #list_ > 2 then
			table.remove(list_, obj.Selected)
			obj.Selected = math.min(obj.Selected, #list_)
			rebuild()
			edit.Set(list_[obj.Selected].C, false)
			fire()
		end
	end)

	function obj.Get()
		local out = {}
		for i, st in list_ do
			out[i] = {st.T, st.C}
		end
		return out
	end
	function obj.GetData()
		local out = {}
		for i, st in list_ do
			out[i] = {st.T, st.C.R, st.C.G, st.C.B}
		end
		return out
	end
	function obj.SetData(data, doFire)
		for i = #list_, 1, -1 do
			table.remove(list_, i)
		end
		for _, d in data do
			table.insert(list_, {T = clamp(d[1], 0, 1), C = Color3.new(d[2], d[3], d[4])})
		end
		if #list_ < 2 then
			return
		end
		obj.Selected = 1
		rebuild()
		edit.Set(list_[1].C, false)
		if doFire then
			fire()
		end
	end
	rebuild()
	return obj
end

function Container:Canvas(height, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(height or 120, true)
	local area = button(row, T.Inset, {Size = UDim2.fromScale(1, 1), ClipsDescendants = true})
	stroke(area, T.Border)
	local obj = {
		Frame = row,
		Strokes = {},
		Color = opts.Color or Color3.fromRGB(255, 255, 255),
		Size = opts.Size or 3
	}
	local total = 0

	local function dims()
		local as = area.AbsoluteSize
		local sc = win.Scale
		if as.X <= 0 or as.Y <= 0 then
			return 280, height or 120
		end
		return as.X / sc, as.Y / sc
	end

	local function segment(st, i)
		if total >= 1500 then
			return
		end
		local W, H = dims()
		local a = st.Points[i]
		local b = st.Points[i + 1] or a
		local p1, p2 = Vector2.new(a[1] * W, a[2] * H), Vector2.new(b[1] * W, b[2] * H)
		local mid, d = (p1 + p2) / 2, p2 - p1
		local f = frame(area, {st.Color, 0}, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(d.Magnitude + st.Size, st.Size),
			Position = UDim2.fromOffset(mid.X, mid.Y),
			Rotation = math.deg(math.atan2(d.Y, d.X)),
			ZIndex = 2
		})
		table.insert(st.Frames, f)
		total = total + 1
	end

	area.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local st = {Color = obj.Color, Size = obj.Size, Points = {}, Frames = {}}
		table.insert(obj.Strokes, st)
		local ap, as = area.AbsolutePosition, area.AbsoluteSize
		local function norm(pos)
			return {clamp((pos.X - ap.X) / math.max(as.X, 1), 0, 1), clamp((pos.Y - ap.Y) / math.max(as.Y, 1), 0, 1)}
		end
		local first = Vector2.new(input.Position.X, input.Position.Y)
		table.insert(st.Points, norm(first))
		segment(st, 1)
		local lastPos = first
		win.Body.ScrollingEnabled = false
		beginDrag(input, function(pos)
			if (pos - lastPos).Magnitude < 3 then
				return
			end
			lastPos = pos
			table.insert(st.Points, norm(pos))
			segment(st, #st.Points - 1)
		end, function()
			win.Body.ScrollingEnabled = true
			if opts.Callback then
				task.spawn(opts.Callback, obj.GetStrokes())
			end
		end)
	end)

	function obj.SetColor(c)
		obj.Color = c
	end
	function obj.SetSize(n)
		obj.Size = n
	end
	function obj.Undo()
		local st = table.remove(obj.Strokes)
		if st then
			for _, f in st.Frames do
				f:Destroy()
				total = total - 1
			end
		end
	end
	function obj.Clear()
		for _, st in obj.Strokes do
			for _, f in st.Frames do
				f:Destroy()
			end
		end
		obj.Strokes = {}
		total = 0
	end
	function obj.GetStrokes()
		local out = {}
		for i, st in obj.Strokes do
			out[i] = {Color = st.Color, Size = st.Size, Points = st.Points}
		end
		return out
	end
	function obj.Load(strokes)
		obj.Clear()
		for _, data in strokes do
			local st = {Color = data.Color, Size = data.Size, Points = data.Points, Frames = {}}
			table.insert(obj.Strokes, st)
			for i = 1, math.max(#st.Points - 1, 1) do
				segment(st, i)
			end
		end
	end

	local bar = self:Row()
	bar:SmallButton("撤销", function()
		obj.Undo()
	end)
	bar:SmallButton("清空", function()
		obj.Clear()
	end)
	for _, sw in {{"白", Color3.fromRGB(255, 255, 255)}, {"红", Color3.fromRGB(240, 70, 70)}, {"绿", Color3.fromRGB(70, 200, 110)}, {"蓝", Color3.fromRGB(66, 150, 250)}, {"黄", Color3.fromRGB(240, 200, 60)}} do
		bar:SmallButton(sw[1], function()
			obj.SetColor(sw[2])
		end, sw[2])
	end
	self:Segmented("笔刷", {"细", "中", "粗"}, "中", function(v)
		obj.SetSize(v == "细" and 2 or (v == "中" and 3 or 6))
	end)
	return obj
end

function Library:Radial(items, x, y, opts)
	opts = opts or {}
	local gui = self.Gui
	local vp = gui.AbsoluteSize
	if vp.X <= 0 then
		vp = Vector2.new(800, 600)
	end
	local n = #items
	local R = opts.Radius or 64
	local B = opts.Size or 46
	local margin = R + B / 2 + 4
	x = clamp(x, margin, math.max(vp.X - margin, margin))
	y = clamp(y, margin, math.max(vp.Y - margin, margin))
	local blocker = button(gui, tok(0, 0, 0, 0.45), {Size = UDim2.fromScale(1, 1), ZIndex = 1600})
	local function close()
		if blocker.Parent then
			blocker:Destroy()
		end
	end
	local center = button(blocker, T.PopupBg, {
		Size = UDim2.fromOffset(30, 30),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Text = "x",
		ZIndex = 1601
	})
	new("UICorner", {CornerRadius = UDim.new(1, 0)}, center)
	stroke(center, T.Border)
	bind(center, T.PopupBg, T.HeaderHover, T.HeaderActive)
	center.MouseButton1Click:Connect(close)
	for i, it in items do
		local ang = -math.pi / 2 + 2 * math.pi * (i - 1) / n
		local nT, hT, pT = T.Button, T.ButtonHover, T.ButtonActive
		if it.Color then
			nT, hT, pT = colorTokens(it.Color)
		end
		local b = button(blocker, nT, {
			Size = UDim2.fromOffset(B, B),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(x + math.cos(ang) * R, y + math.sin(ang) * R),
			Text = it.Text or "",
			TextWrapped = true,
			TextSize = TS - 1,
			ZIndex = 1602
		})
		new("UICorner", {CornerRadius = UDim.new(1, 0)}, b)
		stroke(b, T.Border)
		bind(b, nT, hT, pT)
		b.MouseButton1Click:Connect(function()
			close()
			if it.Callback then
				task.spawn(it.Callback)
			end
		end)
	end
	blocker.MouseButton1Click:Connect(close)
	return {Close = close}
end

function Library:RadialMenu(target, items, opts)
	opts = opts or {}
	local lib = self
	target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			lib:Radial(items, input.Position.X, input.Position.Y, opts)
		elseif input.UserInputType == Enum.UserInputType.Touch then
			local start = Vector2.new(input.Position.X, input.Position.Y)
			local cancelled = false
			local conn
			conn = target.InputEnded:Connect(function(i)
				if i == input then
					cancelled = true
					conn:Disconnect()
				end
			end)
			task.delay(opts.Hold or 0.45, function()
				if not cancelled then
					conn:Disconnect()
					local now = Vector2.new(input.Position.X, input.Position.Y)
					if (now - start).Magnitude < 10 then
						lib:Radial(items, start.X, start.Y, opts)
					end
				end
			end)
		end
	end)
end

function Container:RadialMenu(obj, items, opts)
	local target = obj and (obj.Frame or obj.Button) or nil
	if target then
		return self.Win.Lib:RadialMenu(target, items, opts)
	end
end

function Container:Form(opts)
	opts = opts or {}
	local lib = self.Win.Lib
	local owner = self
	local form = {Fields = {}}
	local red = Color3.fromRGB(240, 90, 90)

	local function errorLabel()
		owner._n = owner._n + 1
		return label(owner.Content, "", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextColor3 = red,
			TextYAlignment = Enum.TextYAlignment.Top,
			Visible = false,
			LayoutOrder = owner._n
		})
	end

	local function add(name, widget, get, rules)
		table.insert(form.Fields, {Name = name, Widget = widget, Get = get, Rules = rules or {}, Err = errorLabel()})
		return widget
	end

	function form.AddText(name, default, rules)
		rules = rules or {}
		local w = owner:InputText(name, default or "", nil, rules.Placeholder)
		return add(name, w, function()
			return w:Get()
		end, rules)
	end

	function form.AddNumber(name, default, rules)
		rules = rules or {}
		local w = owner:InputNumber(name, default or 0, nil, rules.Step, rules.Min, rules.Max)
		return add(name, w, function()
			return w.Get()
		end, rules)
	end

	function form.AddCheck(name, default, rules)
		local w = owner:Checkbox(name, default)
		return add(name, w, function()
			return w.Get()
		end, rules)
	end

	function form.AddCombo(name, items, default, rules)
		local w = owner:Combo(name, items, default)
		return add(name, w, function()
			return w.Get()
		end, rules)
	end

	local function check(field)
		local v = field.Get()
		local r = field.Rules
		if r.Required and (v == nil or v == "") then
			return r.Message or (field.Name .. " 不能为空")
		end
		if r.MustBeTrue and v ~= true then
			return r.Message or ("请勾选 " .. field.Name)
		end
		if type(v) == "string" then
			if r.MinLen and #v < r.MinLen then
				return r.Message or (field.Name .. " 至少 " .. r.MinLen .. " 个字符")
			end
			if r.MaxLen and #v > r.MaxLen then
				return r.Message or (field.Name .. " 最多 " .. r.MaxLen .. " 个字符")
			end
			if r.Pattern and not string.match(v, r.Pattern) then
				return r.Message or (field.Name .. " 格式不正确")
			end
		end
		if type(v) == "number" then
			if r.Min and v < r.Min then
				return r.Message or (field.Name .. " 不能小于 " .. r.Min)
			end
			if r.Max and v > r.Max then
				return r.Message or (field.Name .. " 不能大于 " .. r.Max)
			end
		end
		if r.Validate then
			local ok, res = pcall(r.Validate, v)
			if ok and res ~= true and res ~= nil then
				return tostring(res == false and (r.Message or (field.Name .. " 无效")) or res)
			end
		end
		return nil
	end

	function form.GetValues()
		local out = {}
		for _, f in form.Fields do
			out[f.Name] = f.Get()
		end
		return out
	end

	function form.Validate()
		local ok = true
		for _, f in form.Fields do
			local err = check(f)
			f.Err.Visible = err ~= nil
			f.Err.Text = err or ""
			if err then
				ok = false
			end
		end
		return ok, form.GetValues()
	end

	function form.ClearErrors()
		for _, f in form.Fields do
			f.Err.Visible = false
		end
	end

	function form.AddSubmit(text)
		return owner:Button(text or "提交", function()
			local ok, values = form.Validate()
			if ok then
				if opts.OnSubmit then
					task.spawn(opts.OnSubmit, values)
				end
			else
				lib:Notify({Title = "表单", Content = "请检查标红的字段", Type = "Warn"})
			end
		end)
	end

	return form
end

wrap("DatePicker", function(win, o, name)
	win:_track("DatePicker", name, function()
		return o.GetString()
	end, function(v)
		o.Set(v, true)
	end)
end)
wrap("Curve", function(win, o, name)
	win:_track("Curve", name, function()
		return o.Get()
	end, function(v)
		o.Set(v, true)
	end)
end)
wrap("Gradient", function(win, o, name)
	win:_track("Gradient", name, function()
		return o.GetData()
	end, function(v)
		o.SetData(v, true)
	end)
end)

function Window:_layout()
	local top = FH + (self.MenuH or 0)
	local bottom = self.StatusH or 0
	self.Body.Position = UDim2.fromOffset(0, top)
	self.Body.Size = UDim2.new(1, 0, 1, -(top + bottom))
	if self.MenuBar_ then
		self.MenuBar_.Position = UDim2.fromOffset(0, FH)
	end
end

function Window:MenuBar()
	if self.MenuObj then
		return self.MenuObj
	end
	local win = self
	local bar = frame(self.Frame, T.Menubar, {Size = UDim2.new(1, 0, 0, FH), Position = UDim2.fromOffset(0, FH)})
	list(bar, 0, true)
	self.MenuBar_ = bar
	self.MenuH = FH
	self:_layout()
	local menu = {Bar = bar}
	function menu:Menu(name, items)
		local btn = button(bar, T.Menubar, {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = name
		})
		pad(btn, 8, 8, 0, 0)
		bind(btn, T.Menubar, T.HeaderHover, T.HeaderActive)
		btn.MouseButton1Click:Connect(function()
			local widest = 110
			local count = 0
			for _, it in items do
				if type(it) == "table" then
					widest = math.max(widest, textWidth(it.Text) + 28)
					count = count + 1
				else
					count = count + 0.3
				end
			end
			win:_popup(btn, widest, math.ceil(count * FH) + 4, function(pop)
				pad(pop, 2, 2, 2, 2)
				list(pop, 0).VerticalAlignment = Enum.VerticalAlignment.Top
				for i, it in items do
					if type(it) == "string" then
						local sep = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 6), LayoutOrder = i}, pop)
						frame(sep, T.Separator, {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0)})
					else
						local b = popupItem(pop, it.Text, false, i, function()
							win:_closePopup()
							if it.Callback then
								task.spawn(it.Callback)
							end
						end, 20)
						if it.Checked ~= nil and it.Checked then
							icon(b, "Check", {
								Size = UDim2.fromOffset(FH - 6, FH - 6),
								Position = UDim2.fromOffset(-17, 3),
								ImageColor3 = T.CheckMark
							})
						end
					end
				end
			end)
		end)
		return btn
	end
	self.MenuObj = menu
	return menu
end

function Window:SetTitle(str)
	self.TitleLabel.Text = str
end

function Window:SetItemWidth(w)
	self.ItemWidth = clamp(w, 0.2, 0.9)
end

local POP = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Window:SetVisible(v)
	v = v and true or false
	local was = self.Visible
	self.Visible = v
	self._tok = (self._tok or 0) + 1
	local token = self._tok
	if v then
		self.Frame.Visible = true
		if Settings.Anim and not was then
			self.UIScale.Scale = self.Scale * 0.92
			TweenService:Create(self.UIScale, POP, {Scale = self.Scale}):Play()
		else
			self.UIScale.Scale = self.Scale
		end
	else
		self:_closePopup()
		if Settings.Anim and was then
			TweenService:Create(self.UIScale, POP, {Scale = self.Scale * 0.92}):Play()
			task.delay(0.14, function()
				if self._tok == token and not self.Visible then
					self.Frame.Visible = false
					self.UIScale.Scale = self.Scale
				end
			end)
		else
			self.Frame.Visible = false
		end
	end
	self.Lib:_updateBlur()
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Window:_titleColor()
	if self.Collapsed then
		paint(self.TitleBar, T.TitleCollapsed)
	elseif Library.Focused == self then
		paint(self.TitleBar, T.TitleActive)
	else
		paint(self.TitleBar, T.Title)
	end
end

function Window:SetCollapsed(v)
	if self.NoCollapse and v then
		return
	end
	self.Collapsed = v and true or false
	self:_closePopup()
	self.Body.Visible = not self.Collapsed
	self.Grip.Visible = not self.Collapsed and self.Resizable
	if self.MenuBar_ then
		self.MenuBar_.Visible = not self.Collapsed
	end
	if self.StatusBar_ then
		self.StatusBar_.Visible = not self.Collapsed
	end
	if self.Drawers and self.Collapsed then
		for _, d in self.Drawers do
			d.Close(true)
		end
	end
	spin(self.Arrow, self.Collapsed and 0 or 90)
	if self.Collapsed then
		self.ExpandedSize = self.Frame.Size
		self.Frame.Size = UDim2.fromOffset(self.Frame.Size.X.Offset, FH)
		paint(self.Frame, T.Clear)
	else
		self.Frame.Size = self.ExpandedSize or self.Frame.Size
		paint(self.Frame, T.WindowBg)
	end
	self:_titleColor()
end

function Window:Focus()
	Library.TopZ = Library.TopZ + 1
	self.Frame.ZIndex = Library.TopZ
	Library.Focused = self
	for _, w in Library.Windows do
		w:_titleColor()
	end
end

function Window:Destroy()
	self:_closePopup()
	self.Frame:Destroy()
	for i, w in Library.Windows do
		if w == self then
			table.remove(Library.Windows, i)
			break
		end
	end
end

function Library:CreateWindow(o)
	o = o or {}
	local gui = self.Gui
	local vp = gui.AbsoluteSize
	if vp.X <= 0 then
		vp = Vector2.new(800, 600)
	end
	local scale = o.Scale or 1
	local size = o.Size or Vector2.new(320, 340)
	size = Vector2.new(math.min(size.X, (vp.X - 12) / scale), math.min(size.Y, (vp.Y - 12) / scale))
	local index = #Library.Windows
	local pos = o.Position or Vector2.new(8 + index * 20, 24 + index * 20)

	local win = setmetatable({
		Lib = self,
		Scale = scale,
		ItemWidth = o.ItemWidth or 0.58,
		Visible = true,
		Collapsed = false,
		Resizable = o.Resizable ~= false and not o.NoResize,
		Closable = o.Closable ~= false and not o.NoClose,
		NoCollapse = o.NoCollapse and true or false,
		NoMove = o.NoMove and true or false,
		MenuH = 0,
		Tracked = {},
		TrackCount = {},
		Registry = {},
		_n = 0
	}, Window)
	win.Win = win

	local f = frame(gui, T.WindowBg, {
		Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(size.X, size.Y),
		Name = o.Title or "Window"
	})
	win.UIScale = new("UIScale", {Scale = scale}, f)
	stroke(f, T.Border)
	win.Frame = f

	local title = frame(f, T.TitleActive, {Size = UDim2.new(1, 0, 0, FH)})
	win.TitleBar = title
	local arrowBtn = button(title, T.Clear, {Size = UDim2.fromOffset(FH, FH)})
	local arrow = icon(arrowBtn, "Right", {
		Size = UDim2.fromOffset(FH - 8, FH - 8),
		Position = UDim2.fromOffset(4, 4),
		Rotation = 90
	})
	win.Arrow = arrow
	local close = button(title, T.Clear, {
		Size = UDim2.fromOffset(FH, FH),
		Position = UDim2.new(1, -FH, 0, 0)
	})
	icon(close, "Close", {Size = UDim2.fromOffset(FH - 6, FH - 6), Position = UDim2.fromOffset(3, 3)})
	close.Visible = win.Closable
	arrowBtn.Visible = not win.NoCollapse
	local drag = button(title, T.Clear, {
		Size = UDim2.new(1, -FH * 2, 1, 0),
		Position = UDim2.fromOffset(FH, 0),
		Text = o.Title or "Window",
		TextXAlignment = Enum.TextXAlignment.Left
	})
	win.TitleLabel = drag

	local body = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, FH),
		Size = UDim2.new(1, 0, 1, -FH),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never
	}, f)
	pad(body, PADX, PADX + 2, PADX, PADX)
	list(body, GAP).VerticalAlignment = Enum.VerticalAlignment.Top
	win.Body = body
	win.Content = body

	local grip = button(f, T.Clear, {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -16, 1, -16),
		ZIndex = 5
	})
	local gripIcon = icon(grip, "Grip", {
		Size = UDim2.fromScale(1, 1),
		ImageColor3 = T.GripIdle[1],
		ImageTransparency = T.GripIdle[2],
		ZIndex = 5
	})
	grip.Visible = win.Resizable
	win.Grip = grip

	f.InputBegan:Connect(function(input)
		if isPress(input) then
			win:Focus()
		end
	end)

	drag.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		win:Focus()
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local origin = Vector2.new(f.Position.X.Offset, f.Position.Y.Offset)
		local moved = false
		beginDrag(input, function(p)
			local d = p - start
			if d.Magnitude > 5 then
				moved = true
			end
			if not moved or win.NoMove then
				return
			end
			local view = gui.AbsoluteSize
			local x = clamp(origin.X + d.X, -(f.AbsoluteSize.X - 50), view.X - 50)
			local y = clamp(origin.Y + d.Y, 0, view.Y - FH * win.Scale)
			f.Position = UDim2.fromOffset(x, y)
		end, function()
			if not moved then
				win:SetCollapsed(not win.Collapsed)
			end
		end)
	end)

	arrowBtn.MouseButton1Click:Connect(function()
		win:SetCollapsed(not win.Collapsed)
	end)

	close.MouseButton1Click:Connect(function()
		win:SetVisible(false)
		if o.OnClose then
			task.spawn(o.OnClose)
		end
	end)

	grip.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local origin = Vector2.new(f.Size.X.Offset, f.Size.Y.Offset)
		body.ScrollingEnabled = false
		gripIcon.ImageTransparency = T.GripActive[2]
		beginDrag(input, function(p)
			local d = (p - start) / win.Scale
			local view = gui.AbsoluteSize
			local maxX = (view.X - f.AbsolutePosition.X) / win.Scale
			local maxY = (view.Y - f.AbsolutePosition.Y) / win.Scale
			local w = clamp(origin.X + d.X, 160, math.max(maxX, 160))
			local h = clamp(origin.Y + d.Y, 80, math.max(maxY, 80))
			f.Size = UDim2.fromOffset(w, h)
		end, function()
			body.ScrollingEnabled = true
			gripIcon.ImageTransparency = T.GripIdle[2]
		end)
	end)

	table.insert(Library.Windows, win)
	win:Focus()
	if o.Collapsed then
		win:SetCollapsed(true)
	end
	if o.InfoBar then
		win:InfoBar(o.InfoBar == true and {} or o.InfoBar)
	end
	if o.NoScrollbar then
		win.Body.ScrollBarThickness = 0
	end
	if o.NoBackground then
		f.BackgroundTransparency = 1
	end
	Library:_fxWindow(win)
	if o.Glass then
		win:_glass(true)
	end
	if o.Border then
		win:SetBorderEffect(o.Border)
	end
	if o.Backdrop then
		win:Backdrop(o.Backdrop)
	end
	if o.Particles then
		win:Particles(o.Particles)
	end
	return win
end

Library.Dialogs = {}

local KIND_COLORS = {
	Info = Color3.fromRGB(66, 150, 250),
	Success = Color3.fromRGB(80, 220, 120),
	Warn = Color3.fromRGB(240, 190, 60),
	Error = Color3.fromRGB(240, 90, 90),
	Question = Color3.fromRGB(160, 130, 250)
}

local MODAL_DIM = tok(204, 204, 204, 0.65)

function Library:SetModalDim(color, transparency)
	Library.ModalDim = {color or MODAL_DIM[1], transparency or MODAL_DIM[2]}
end

local function kindColor(o)
	return o.Color or KIND_COLORS[o.Type or "Info"] or KIND_COLORS.Info
end

local function makeProgress(parent, order, spec)
	spec = spec or {}
	local track = frame(parent, T.Frame, {
		Size = UDim2.new(1, 0, 0, spec.Height or FH),
		LayoutOrder = order,
		ClipsDescendants = true
	})
	local fillTok = spec.Color and {spec.Color, 0} or T.Histogram
	local fill = frame(track, fillTok, {Size = UDim2.new(clamp(spec.Value or 0, 0, 1), 0, 1, 0)})
	local text = label(track, "", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2
	})
	local obj = {Frame = track, Fill = fill, Value = clamp(spec.Value or 0, 0, 1), Indeterminate = false, Text = spec.Text}
	local sweep
	local function render()
		if obj.Text then
			text.Text = obj.Text
		elseif obj.Indeterminate or spec.ShowText == false then
			text.Text = ""
		else
			text.Text = string.format("%d%%", obj.Value * 100 + 0.5)
		end
	end
	function obj:Set(v, txt)
		obj.Value = clamp(v, 0, 1)
		obj.Text = txt
		if not obj.Indeterminate then
			local goal = UDim2.new(obj.Value, 0, 1, 0)
			if Settings.Anim and track.Parent then
				TweenService:Create(fill, FADE, {Size = goal}):Play()
			else
				fill.Size = goal
			end
		end
		render()
	end
	function obj:SetIndeterminate(on, txt)
		on = on and true or false
		if txt ~= nil then
			obj.Text = txt
		end
		if on == obj.Indeterminate then
			render()
			return
		end
		obj.Indeterminate = on
		if on then
			fill.Size = UDim2.new(0.3, 0, 1, 0)
			fill.Position = UDim2.fromScale(-0.3, 0)
			sweep = TweenService:Create(fill, TweenInfo.new(1.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {Position = UDim2.fromScale(1, 0)})
			sweep:Play()
		else
			if sweep then
				pcall(function()
					sweep:Cancel()
				end)
				sweep = nil
			end
			fill.Position = UDim2.new()
			fill.Size = UDim2.new(obj.Value, 0, 1, 0)
		end
		render()
	end
	obj.Destroy = function()
		if sweep then
			pcall(function()
				sweep:Cancel()
			end)
		end
	end
	if spec.Indeterminate then
		obj:SetIndeterminate(true)
	end
	render()
	return obj
end

local function actionButton(parent, spec, order, height)
	local n, h, p = T.Button, T.ButtonHover, T.ButtonActive
	if spec.Color then
		n, h, p = colorTokens(spec.Color)
	end
	local b = button(parent, n, {
		Size = UDim2.new(0, 0, 0, height),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = spec.Text or "确定",
		LayoutOrder = order
	})
	pad(b, 10, 10, 0, 0)
	local st = bind(b, n, h, p)
	local ctl = {Button = b, Enabled = true, Loading = false, Text = spec.Text or "确定", Suffix = ""}
	local function refreshText()
		b.Text = (ctl.Loading and "… " or "") .. ctl.Text .. ctl.Suffix
	end
	function ctl:SetEnabled(v)
		ctl.Enabled = v and true or false
		if ctl.Enabled then
			st.Normal, st.Hover, st.Press = n, h, p
			b.TextColor3 = T.Text
		else
			local dim = {n[1], 0.85}
			st.Normal, st.Hover, st.Press = dim, dim, dim
			b.TextColor3 = T.TextDisabled
		end
		if st.Refresh then
			st.Refresh()
		end
	end
	function ctl:SetText(t)
		ctl.Text = t
		refreshText()
	end
	function ctl:SetSuffix(t)
		ctl.Suffix = t or ""
		refreshText()
	end
	function ctl:SetLoading(on)
		ctl.Loading = on and true or false
		refreshText()
	end
	return ctl
end

local function dialogContainer(lib, hostFrame, content)
	local win = setmetatable({
		Lib = lib,
		Scale = 1,
		ItemWidth = 0.5,
		Visible = true,
		Collapsed = false,
		Tracked = {},
		TrackCount = {},
		Registry = {},
		_noTrack = true,
		_n = 0
	}, Window)
	win.Win = win
	win.Frame = hostFrame
	win.Content = content
	win.Body = new("ScrollingFrame", {Visible = false, Size = UDim2.new()}, hostFrame)
	return makeContainer(win, content, false), win
end

function Library:Dialog(o)
	o = o or {}
	local lib = self
	local gui = self.Gui
	local vp = gui.AbsoluteSize
	if vp.X <= 0 then
		vp = Vector2.new(800, 600)
	end
	local width = math.min(o.Width or 260, vp.X - 24)
	local depth = #self.Dialogs + 1
	local modal = o.Modal ~= false
	local color = o.Type and kindColor(o) or nil
	local holder
	if modal then
		holder = button(gui, Library.ModalDim or MODAL_DIM, {Size = UDim2.fromScale(1, 1), ZIndex = 1000 + depth * 2})
		holder.AutoButtonColor = false
	else
		holder = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 1000 + depth * 2}, gui)
	end
	local dlg = frame(holder, T.PopupBg, {
		Active = true,
		Size = UDim2.new(0, width, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = o.Position or UDim2.fromScale(0.5, 0.5)
	})
	stroke(dlg, T.Border)
	local layout = list(dlg, 0)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top

	local handle = {Frame = dlg, Open = true, Buttons = {}, Checked = nil, Selected = nil}
	local hostLayer = new("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2}, holder)
	local head = frame(dlg, T.TitleActive, {Size = UDim2.new(1, 0, 0, FH), LayoutOrder = 1})
	local titleBtn = button(head, T.Clear, {
		Size = UDim2.new(1, -FH, 1, 0),
		Text = o.Title or "提示",
		TextXAlignment = Enum.TextXAlignment.Left
	})
	pad(titleBtn, 6, 0, 0, 0)
	local closable = o.Closable ~= false
	handle.Closable = closable
	local closeBtn = button(head, T.Clear, {
		Size = UDim2.fromOffset(FH, FH),
		Position = UDim2.new(1, -FH, 0, 0)
	})
	icon(closeBtn, "Close", {Size = UDim2.fromOffset(FH - 6, FH - 6), Position = UDim2.fromOffset(3, 3)})
	closeBtn.Visible = closable
	bind(closeBtn, T.Clear, T.HeaderHover, T.HeaderActive)

	local bodyF = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2
	}, dlg)
	pad(bodyF, PADX, PADX, PADX, PADX)
	local inner = list(bodyF, GAP)
	inner.VerticalAlignment = Enum.VerticalAlignment.Top
	local order = 0
	local function nextOrder()
		order = order + 1
		return order
	end

	local msgRow = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = nextOrder()
	}, bodyF)
	local textLeft = 0
	local msgCol = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -textLeft, 0, 0),
		Position = UDim2.fromOffset(textLeft, 0),
		AutomaticSize = Enum.AutomaticSize.Y
	}, msgRow)
	list(msgCol, 2).VerticalAlignment = Enum.VerticalAlignment.Top
	local msgLabel = label(msgCol, o.Message or "", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextColor3 = (o.Type and o.Type ~= "Info" and o.Type ~= "Question") and kindColor(o) or T.Text,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 1
	})
	msgLabel.Visible = (o.Message or "") ~= ""
	local detailLabel = label(msgCol, o.Detail or "", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = T.TextDisabled,
		LayoutOrder = 2
	})
	detailLabel.Visible = (o.Detail or "") ~= ""
	if not msgLabel.Visible and not detailLabel.Visible then
		msgRow.Visible = false
	end

	local progress
	if o.Progress then
		local spec = o.Progress
		if type(spec) ~= "table" then
			spec = {}
		end
		progress = makeProgress(bodyF, nextOrder(), spec)
		handle.ProgressBar = progress
	end

	local cont, pseudo
	local needHost = o.Build or o.Check or o.Options
	if needHost then
		local cf = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = nextOrder()
		}, bodyF)
		list(cf, GAP).VerticalAlignment = Enum.VerticalAlignment.Top
		cont, pseudo = dialogContainer(lib, hostLayer, cf)
		handle.Container = cont
		if o.Options then
			local items = o.Options
			handle.Selected = o.Selected or items[1]
			cont:RadioGroup(items, handle.Selected, function(v)
				handle.Selected = v
			end, o.OptionsInline == true)
		end
		if o.Check then
			local spec = type(o.Check) == "table" and o.Check or {Text = tostring(o.Check)}
			handle.Checked = spec.Default and true or false
			cont:Checkbox(spec.Text or "不再提示", handle.Checked, function(v)
				handle.Checked = v
			end)
		end
	end

	local inputBox, errLabel
	local function validate()
		local ok, msg = true, nil
		local vf = inputBox and type(o.Input) == "table" and o.Input.Validate
		if vf then
			local r1, r2 = vf(inputBox.Text)
			if r1 == false or r1 == nil then
				ok, msg = false, r2 or "输入无效"
			end
		end
		if errLabel then
			errLabel.Text = msg or ""
			errLabel.Visible = msg ~= nil and inputBox.Text ~= ""
		end
		for _, ctl in handle.Buttons do
			if ctl.Spec.Submit then
				ctl:SetEnabled(ok and not ctl.Locked)
			end
		end
		return ok
	end
	if o.Input then
		local spec = type(o.Input) == "table" and o.Input or {}
		local ib = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = nextOrder()
		}, bodyF)
		list(ib, 2).VerticalAlignment = Enum.VerticalAlignment.Top
		inputBox = new("TextBox", {
			BackgroundColor3 = T.Frame[1],
			BackgroundTransparency = T.Frame[2],
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, FH),
			Font = FONT,
			TextSize = TS,
			TextColor3 = T.Text,
			PlaceholderText = spec.Placeholder or "",
			PlaceholderColor3 = T.TextDisabled,
			Text = spec.Default or "",
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1
		}, ib)
		pad(inputBox, 4, 4, 0, 0)
		if spec.MaxLength then
			inputBox:GetPropertyChangedSignal("Text"):Connect(function()
				if #inputBox.Text > spec.MaxLength then
					inputBox.Text = string.sub(inputBox.Text, 1, spec.MaxLength)
				end
			end)
		end
		errLabel = label(ib, "", {
			Size = UDim2.new(1, 0, 0, FH - 4),
			TextColor3 = KIND_COLORS.Error,
			LayoutOrder = 2,
			Visible = false
		})
		inputBox.Focused:Connect(function()
			paint(inputBox, T.FrameActive)
		end)
		inputBox.FocusLost:Connect(function(enter)
			paint(inputBox, T.Frame)
			if enter and handle.Default and handle.Default.Enabled then
				handle.Default.Activate()
			end
		end)
		inputBox:GetPropertyChangedSignal("Text"):Connect(validate)
		handle.Input = inputBox
	end

	if o.Build then
		o.Build(cont, handle)
	end

	local timeoutBar
	if o.Timeout and o.Timeout > 0 then
		timeoutBar = frame(dlg, T.Histogram, {
			Size = UDim2.new(1, 0, 0, 2),
			LayoutOrder = 3
		})
	end

	local function finish(reason)
		if not handle.Open then
			return false
		end
		handle.Open = false
		for i, d in lib.Dialogs do
			if d == handle then
				table.remove(lib.Dialogs, i)
				break
			end
		end
		if progress then
			progress.Destroy()
		end
		if holder.Parent then
			holder:Destroy()
		end
		if o.OnClose then
			task.spawn(o.OnClose, reason)
		end
		return true
	end
	handle.Close = function(_, reason)
		finish(reason or "api")
	end

	local specs = o.Buttons
	if specs == nil then
		specs = {{Text = "确定"}}
	end
	if #specs > 0 then
		frame(bodyF, T.Separator, {Size = UDim2.new(1, 0, 0, 1), LayoutOrder = nextOrder()})
		local buttons = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = nextOrder()
		}, bodyF)
		local stretch = o.Stretch
		if stretch == nil then
			stretch = o.ButtonAlign == nil and #specs <= 3
		end
		o.Stretch = stretch
		local bl = list(buttons, GAP, true, true)
		bl.HorizontalAlignment = o.ButtonAlign == "Left" and Enum.HorizontalAlignment.Left or (o.ButtonAlign == "Center" and Enum.HorizontalAlignment.Center or (stretch and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right))
		bl.VerticalAlignment = Enum.VerticalAlignment.Top
		for i, spec in specs do
			local ctl = actionButton(buttons, spec, i, FH)
			ctl.Spec = spec
			if o.Stretch then
				ctl.Button.AutomaticSize = Enum.AutomaticSize.None
				ctl.Button.Size = UDim2.new(1 / #specs, -GAP * (#specs - 1) / #specs - 0.5, 0, FH)
			end
			handle.Buttons[i] = ctl
			if spec.Default then
				handle.Default = ctl
			end
			if spec.Cancel then
				handle.Cancel = ctl
			end
			if spec.Disabled then
				ctl.Locked = true
				ctl:SetEnabled(false)
			end
			if spec.Countdown and spec.Countdown > 0 then
				ctl.Locked = true
				ctl:SetEnabled(false)
				local left = spec.Countdown
				local function tick()
					if not handle.Open then
						return
					end
					if left <= 0 then
						ctl.Locked = false
						ctl:SetSuffix("")
						ctl:SetEnabled(true)
						validate()
						return
					end
					ctl:SetSuffix(" (" .. left .. ")")
					left = left - 1
					task.delay(1, tick)
				end
				tick()
			end
			ctl.Activate = function()
				if not ctl.Enabled or ctl.Loading or not handle.Open then
					return
				end
				if spec.Submit and not validate() then
					handle:Shake()
					return
				end
				local typed = inputBox and inputBox.Text
				local keep = spec.Close == false
				if not keep then
					finish("button")
				end
				if spec.Callback then
					task.spawn(spec.Callback, typed, handle.Checked, handle.Selected, handle)
				end
			end
			ctl.Button.MouseButton1Click:Connect(ctl.Activate)
		end
		if not handle.Default and o.DefaultButton then
			handle.Default = handle.Buttons[o.DefaultButton]
		end
	end
	if inputBox then
		validate()
	end
	if o.CancelButton then
		handle.Cancel = handle.Buttons[o.CancelButton]
	end

	function handle:SetTitle(v)
		titleBtn.Text = v
	end
	function handle:SetMessage(v)
		msgLabel.Text = v
		msgLabel.Visible = v ~= ""
		msgRow.Visible = msgLabel.Visible or detailLabel.Visible
	end
	function handle:SetDetail(v)
		detailLabel.Text = v
		detailLabel.Visible = v ~= ""
		msgRow.Visible = msgLabel.Visible or detailLabel.Visible
	end
	function handle:SetProgress(v, txt)
		if progress then
			progress:Set(v, txt)
			if v >= 1 and o.Progress and type(o.Progress) == "table" and o.Progress.AutoClose then
				task.delay(o.Progress.CloseDelay or 0.6, function()
					finish("complete")
				end)
			end
		end
	end
	function handle:SetIndeterminate(on, txt)
		if progress then
			progress:SetIndeterminate(on, txt)
		end
	end
	function handle:SetButtonText(i, t)
		if handle.Buttons[i] then
			handle.Buttons[i]:SetText(t)
		end
	end
	function handle:SetButtonEnabled(i, v)
		local c = handle.Buttons[i]
		if c then
			c.Locked = not v
			c:SetEnabled(v)
		end
	end
	function handle:SetButtonLoading(i, v)
		if handle.Buttons[i] then
			handle.Buttons[i]:SetLoading(v)
		end
	end
	function handle:GetInput()
		return inputBox and inputBox.Text or nil
	end
	function handle:GetChecked()
		return handle.Checked
	end
	function handle:Shake()
		local base = dlg.Position
		task.spawn(function()
			for _, dx in {-6, 6, -4, 4, 0} do
				pcall(function()
					TweenService:Create(dlg, TweenInfo.new(0.04), {Position = UDim2.new(base.X.Scale, base.X.Offset + dx, base.Y.Scale, base.Y.Offset)}):Play()
				end)
				task.wait(0.04)
			end
		end)
	end

	closeBtn.MouseButton1Click:Connect(function()
		finish("close")
	end)
	if modal then
		holder.MouseButton1Click:Connect(function()
			if o.DismissOnOutside then
				finish("outside")
			elseif o.ShakeOnOutside then
				handle:Shake()
			end
		end)
	end
	if o.Draggable ~= false then
		titleBtn.InputBegan:Connect(function(input)
			if not isPress(input) then
				return
			end
			local abs = dlg.AbsolutePosition
			local sz = dlg.AbsoluteSize
			local center = Vector2.new(abs.X + sz.X / 2, abs.Y + sz.Y / 2)
			local start = Vector2.new(input.Position.X, input.Position.Y)
			local moved = false
			beginDrag(input, function(p)
				local d = p - start
				if d.Magnitude > 5 then
					moved = true
				end
				if not moved then
					return
				end
				local view = gui.AbsoluteSize
				local x = clamp(center.X + d.X, 30, view.X - 30)
				local y = clamp(center.Y + d.Y, FH, view.Y - FH)
				dlg.Position = UDim2.fromOffset(x, y)
			end)
		end)
	end
	if timeoutBar then
		pcall(function()
			TweenService:Create(timeoutBar, TweenInfo.new(o.Timeout, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
		end)
		task.delay(o.Timeout, function()
			if handle.Open then
				if o.OnTimeout then
					task.spawn(o.OnTimeout)
				end
				finish("timeout")
			end
		end)
	end
	table.insert(self.Dialogs, handle)
	return handle
end

function Library:Message(title, message, kind, onOk, opts)
	opts = opts or {}
	return self:Dialog({
		Title = title,
		Message = message,
		Detail = opts.Detail,
		Type = kind or "Info",
		Width = opts.Width,
		Buttons = {{Text = opts.Ok or "确定", Callback = onOk, Default = true}},
		DismissOnOutside = true
	})
end

function Library:Prompt(title, message, default, onSubmit, onCancel, opts)
	opts = opts or {}
	return self:Dialog({
		Title = title,
		Message = message,
		Width = opts.Width,
		Type = opts.Type,
		Detail = opts.Detail,
		Input = {Default = default, Placeholder = opts.Placeholder, Validate = opts.Validate, MaxLength = opts.MaxLength},
		Buttons = {
			{Text = opts.Yes or "确定", Callback = onSubmit, Submit = true, Default = true},
			{Text = opts.No or "取消", Callback = onCancel, Cancel = true}
		}
	})
end

function Library:Confirm(title, message, onYes, onNo, opts)
	opts = opts or {}
	return self:Dialog({
		Title = title,
		Message = message,
		Width = opts.Width,
		Type = opts.Type or "Question",
		Detail = opts.Detail,
		Check = opts.Check,
		Timeout = opts.Timeout,
		OnTimeout = onNo,
		Buttons = {
			{Text = opts.Yes or "确定", Callback = onYes, Color = opts.YesColor, Default = true, Countdown = opts.Countdown},
			{Text = opts.No or "取消", Callback = onNo, Cancel = true}
		}
	})
end

function Library:Choose(title, message, options, onPick, opts)
	opts = opts or {}
	return self:Dialog({
		Title = title,
		Message = message,
		Width = opts.Width,
		Type = opts.Type,
		Options = options,
		Selected = opts.Selected,
		Buttons = {
			{Text = opts.Yes or "确定", Callback = function(_, _, sel)
				if onPick then
					onPick(sel)
				end
			end, Default = true},
			{Text = opts.No or "取消", Cancel = true}
		}
	})
end

function Library:Progress(title, message, opts)
	opts = opts or {}
	local cancel = opts.OnCancel
	local buttons = {}
	if cancel ~= nil or opts.Cancelable then
		buttons[1] = {Text = opts.CancelText or "取消", Callback = cancel}
	end
	return self:Dialog({
		Title = title,
		Message = message,
		Detail = opts.Detail,
		Width = opts.Width,
		Type = opts.Type,
		Closable = opts.Closable == true,
		Progress = {
			Value = opts.Value or 0,
			Indeterminate = opts.Indeterminate,
			Text = opts.Text,
			Color = opts.Color,
			AutoClose = opts.AutoClose ~= false
		},
		Buttons = buttons
	})
end

local TOAST_POS = {
	TopRight = {Vector2.new(1, 0), UDim2.new(1, -8, 0, 8), Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Top},
	TopLeft = {Vector2.new(0, 0), UDim2.new(0, 8, 0, 8), Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top},
	TopCenter = {Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8), Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top},
	BottomRight = {Vector2.new(1, 1), UDim2.new(1, -8, 1, -8), Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom},
	BottomLeft = {Vector2.new(0, 1), UDim2.new(0, 8, 1, -8), Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Bottom},
	BottomCenter = {Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -8), Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom}
}

function Library:Notify(o)
	if type(o) == "string" then
		o = {Content = o}
	end
	o = o or {}
	local gui = self.Gui
	self.ToastHosts = self.ToastHosts or {}
	self.ToastById = self.ToastById or {}
	local posName = TOAST_POS[o.Position] and o.Position or "TopRight"
	local pp = TOAST_POS[posName]
	local vp = gui.AbsoluteSize
	local width = o.Width or 230
	if vp.X > 0 then
		width = math.min(width, vp.X - 16)
	end
	local host = self.ToastHosts[posName]
	if not host or not host.Parent then
		host = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, width, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			AnchorPoint = pp[1],
			Position = pp[2],
			ZIndex = 900
		}, gui)
		local l = list(host, 4)
		l.VerticalAlignment = pp[4]
		l.HorizontalAlignment = pp[3]
		l.SortOrder = Enum.SortOrder.LayoutOrder
		self.ToastHosts[posName] = host
		self.ToastHost = host
	end
	if o.Id and self.ToastById[o.Id] and self.ToastById[o.Id].Alive then
		self.ToastById[o.Id]:Update(o)
		return self.ToastById[o.Id]
	end
	local maxToasts = o.MaxToasts or 5
	local alive = {}
	for _, c in host:GetChildren() do
		if c:IsA("Frame") then
			table.insert(alive, c)
		end
	end
	if #alive >= maxToasts then
		table.sort(alive, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		local oldest = alive[1]
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end
	self.ToastN = (self.ToastN or 0) + 1
	local orderNum = self.ToastN

	local function tint(kind, color)
		if color then
			return {color, 0.45}
		end
		if kind and kind ~= "Info" and KIND_COLORS[kind] then
			return {KIND_COLORS[kind], 0.45}
		end
		return T.TitleActive
	end
	local toast = new("Frame", {
		BackgroundColor3 = T.PopupBg[1],
		BackgroundTransparency = T.PopupBg[2],
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = orderNum,
		ZIndex = 901
	}, host)
	stroke(toast, T.Border)
	local hasTitle = o.Title ~= nil and o.Title ~= ""
	local content = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 902
	}, toast)
	local contentPad = pad(content, 6, 6, hasTitle and (FH + 4) or 5, 6)
	list(content, GAP).VerticalAlignment = Enum.VerticalAlignment.Top
	local titleRow = frame(toast, tint(o.Type, o.Color), {
		Size = UDim2.new(1, 0, 0, FH),
		ZIndex = 903,
		Visible = hasTitle
	})
	local titleLabel = label(titleRow, o.Title or "", {
		Size = UDim2.new(1, -(FH + 6), 1, 0),
		Position = UDim2.fromOffset(6, 0),
		ZIndex = 904
	})
	local xBtn = button(titleRow, T.Clear, {
		Size = UDim2.fromOffset(FH, FH),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		ZIndex = 904
	})
	icon(xBtn, "Close", {Size = UDim2.fromOffset(FH - 6, FH - 6), Position = UDim2.fromOffset(3, 3), ZIndex = 905})
	bind(xBtn, T.Clear, T.HeaderHover, T.HeaderActive)
	xBtn.Visible = o.Closable ~= false
	local contentLabel = label(content, o.Content or "", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 1,
		ZIndex = 903
	})
	contentLabel.Visible = o.Content ~= nil and o.Content ~= ""

	local progress
	if o.Progress then
		local spec = type(o.Progress) == "table" and o.Progress or {}
		spec.Color = spec.Color or ((o.Type and o.Type ~= "Info") and kindColor(o) or nil)
		spec.Height = spec.Height or FH - 4
		progress = makeProgress(content, 2, spec)
	end

	local toastObj = {Frame = toast, Alive = true, Id = o.Id}
	local timerToken = 0
	local bar = frame(toast, {kindColor(o), 0.3}, {
		Size = UDim2.new(1, 0, 0, 2),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		ZIndex = 904
	})
	local function close(reason)
		if not toastObj.Alive then
			return
		end
		toastObj.Alive = false
		if progress then
			progress.Destroy()
		end
		if toast.Parent then
			toast:Destroy()
		end
		if o.OnClose then
			task.spawn(o.OnClose, reason or "close")
		end
	end
	local function schedule(duration)
		timerToken = timerToken + 1
		local mine = timerToken
		bar.Visible = false
		if duration and duration > 0 then
			bar.Visible = true
			bar.Size = UDim2.new(1, 0, 0, 2)
			pcall(function()
				TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
			end)
			task.delay(duration, function()
				if mine == timerToken then
					close("timeout")
				end
			end)
		end
	end

	if o.Buttons and #o.Buttons > 0 then
		local row = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 3,
			ZIndex = 903
		}, content)
		local bl = list(row, GAP, true, true)
		bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
		bl.VerticalAlignment = Enum.VerticalAlignment.Top
		for i, spec in o.Buttons do
			local ctl = actionButton(row, spec, i, FH - 2)
			ctl.Button.ZIndex = 903
			ctl.Button.MouseButton1Click:Connect(function()
				if spec.Close ~= false then
					close("button")
				end
				if spec.Callback then
					task.spawn(spec.Callback, toastObj)
				end
			end)
		end
	end

	xBtn.MouseButton1Click:Connect(function()
		close("close")
	end)
	local hit = button(toast, T.Clear, {Size = UDim2.fromScale(1, 1), ZIndex = 901})
	hit.MouseButton1Click:Connect(function()
		if o.Callback then
			task.spawn(o.Callback, toastObj)
		end
		if o.CloseOnClick ~= false then
			close("click")
		end
	end)

	local function sticky()
		return o.Duration == 0 or (o.Progress and o.Duration == nil)
	end
	function toastObj:Close()
		close("api")
	end
	function toastObj:SetTitle(v)
		titleLabel.Text = v
		titleRow.Visible = true
		contentPad.PaddingTop = UDim.new(0, FH + 4)
	end
	function toastObj:SetContent(v)
		contentLabel.Text = v
		contentLabel.Visible = v ~= ""
	end
	function toastObj:SetType(kind, color)
		local c = color or KIND_COLORS[kind] or KIND_COLORS.Info
		paint(titleRow, tint(kind, color))
		bar.BackgroundColor3 = c
		if progress then
			progress.Fill.BackgroundColor3 = c
		end
	end
	function toastObj:SetProgress(v, txt)
		if progress then
			progress:Set(v, txt)
			if v >= 1 and o.CloseOnComplete ~= false then
				toastObj:SetType("Success")
				schedule(o.CompleteDelay or 1.5)
			end
		end
	end
	function toastObj:Update(n)
		if n.Title ~= nil then
			toastObj:SetTitle(n.Title)
		end
		if n.Content ~= nil then
			toastObj:SetContent(n.Content)
		end
		if n.Type or n.Color then
			toastObj:SetType(n.Type, n.Color)
		end
		if n.Progress and progress then
			local v = type(n.Progress) == "table" and n.Progress.Value or n.Progress
			local t = type(n.Progress) == "table" and n.Progress.Text or nil
			toastObj:SetProgress(v or 0, t)
		end
		if n.Duration ~= nil and n.Duration > 0 then
			schedule(n.Duration)
		end
	end
	function toastObj:Pin()
		timerToken = timerToken + 1
		bar.Visible = false
	end
	if o.Id then
		self.ToastById[o.Id] = toastObj
	end
	if not sticky() then
		schedule(o.Duration or 3)
	else
		bar.Visible = false
	end
	if progress and o.Progress and type(o.Progress) == "table" and o.Progress.Value and o.Progress.Value >= 1 then
		toastObj:SetProgress(1)
	end
	return toastObj
end

function Container:Stepper(steps, current, callback, opts)
	opts = opts or {}
	local n = #steps
	local row = self:_row(FH * 2 + 6, true)
	local state = {Value = clamp(current or 1, 1, n), Errors = {}}
	local lines, circles, labels = {}, {}, {}
	local CS = FH + 2
	for i = 1, n - 1 do
		lines[i] = frame(row, T.Separator, {
			Size = UDim2.new(1 / n, -CS, 0, 2),
			Position = UDim2.new((i - 0.5) / n, CS / 2, 0, CS / 2 - 1)
		})
	end
	local function render()
		for i = 1, n do
			local c = circles[i]
			local done = i < state.Value
			local cur = i == state.Value
			local err = state.Errors[i]
			if err then
				c.Button.BackgroundColor3 = KIND_COLORS.Error
				c.Button.BackgroundTransparency = 0
				c.Button.Text = "!"
			elseif done then
				c.Button.BackgroundColor3 = T.ButtonHover[1]
				c.Button.BackgroundTransparency = 0
				c.Button.Text = "✓"
			elseif cur then
				c.Button.BackgroundColor3 = T.ButtonHover[1]
				c.Button.BackgroundTransparency = 0
				c.Button.Text = tostring(i)
			else
				paint(c.Button, T.Frame)
				c.Button.Text = tostring(i)
			end
			c.Stroke.Transparency = cur and 0 or 0.5
			labels[i].TextColor3 = (cur or done) and T.Text or T.TextDisabled
		end
		for i = 1, n - 1 do
			if i < state.Value then
				lines[i].BackgroundColor3 = T.ButtonHover[1]
				lines[i].BackgroundTransparency = 0
			else
				paint(lines[i], T.Separator)
			end
		end
	end
	function state.Set(v, fire)
		v = clamp(v, 1, n)
		if v == state.Value then
			render()
			return
		end
		state.Value = v
		render()
		if fire and callback then
			task.spawn(callback, v, steps[v])
		end
	end
	function state.Get()
		return state.Value
	end
	function state.Next()
		state.Set(state.Value + 1, true)
	end
	function state.Prev()
		state.Set(state.Value - 1, true)
	end
	function state.SetError(i, on)
		state.Errors[i] = on and true or nil
		render()
	end
	for i = 1, n do
		local b = button(row, T.Frame, {
			Size = UDim2.fromOffset(CS, CS),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new((i - 0.5) / n, 0, 0, 0),
			Text = tostring(i),
			ZIndex = 2
		})
		if Settings.Round > 0 then
			local r = b:FindFirstChild("__R")
			if r then
				r.CornerRadius = UDim.new(1, 0)
			end
		end
		local st = stroke(b, T.Border)
		circles[i] = {Button = b, Stroke = st}
		labels[i] = label(row, steps[i], {
			Size = UDim2.new(1 / n, -2, 0, FH),
			Position = UDim2.new((i - 1) / n, 1, 0, CS + 2),
			TextXAlignment = Enum.TextXAlignment.Center
		})
		b.MouseButton1Click:Connect(function()
			if opts.Clickable ~= false then
				state.Set(i, true)
			end
		end)
	end
	render()
	state.Frame = row
	return state
end

local TIMELINE_DOT = {Info = KIND_COLORS.Info, Success = KIND_COLORS.Success, Warn = KIND_COLORS.Warn, Error = KIND_COLORS.Error}

function Container:Timeline(items, opts)
	opts = opts or {}
	local sub, subFrame = self:_sub(false, 0, 0)
	local obj = {Frame = subFrame, Items = {}}
	local function add(item)
		if type(item) == "string" then
			item = {Title = item}
		end
		local idx = #obj.Items + 1
		local color = item.Color or TIMELINE_DOT[item.Type or "Info"] or KIND_COLORS.Info
		if item.Done == false then
			color = nil
		end
		local f = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = idx
		}, sub.Content)
		local line = frame(f, T.Separator, {
			Size = UDim2.new(0, 2, 1, -(FH - 2)),
			Position = UDim2.fromOffset(6, FH - 4)
		})
		local dot = frame(f, color and {color, 0} or T.Frame, {
			Size = UDim2.fromOffset(10, 10),
			Position = UDim2.fromOffset(2, 4)
		})
		if Settings.Round > 0 then
			new("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
		end
		if not color then
			stroke(dot, T.Border)
		end
		local body = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 0, 0),
			Position = UDim2.fromOffset(20, 0),
			AutomaticSize = Enum.AutomaticSize.Y
		}, f)
		pad(body, 0, 0, 0, 6)
		list(body, 1).VerticalAlignment = Enum.VerticalAlignment.Top
		local head = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, FH - 2), LayoutOrder = 1}, body)
		local timeW = item.Time and textWidth(item.Time) + 6 or 0
		label(head, item.Title or "", {
			Size = UDim2.new(1, -timeW, 1, 0),
			TextColor3 = color or T.TextDisabled
		})
		if item.Time then
			label(head, item.Time, {
				Size = UDim2.new(0, timeW, 1, 0),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = T.TextDisabled
			})
		end
		if item.Text and item.Text ~= "" then
			label(body, item.Text, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextColor3 = T.TextDisabled,
				LayoutOrder = 2
			})
		end
		if obj.Items[idx - 1] then
			obj.Items[idx - 1].Line.Visible = true
		end
		line.Visible = false
		obj.Items[idx] = {Frame = f, Line = line}
		return f
	end
	function obj:Add(item)
		return add(item)
	end
	function obj:Clear()
		for _, it in obj.Items do
			it.Frame:Destroy()
		end
		obj.Items = {}
	end
	for _, item in items or {} do
		add(item)
	end
	return obj
end

function Container:Breadcrumb(path, callback, opts)
	opts = opts or {}
	local row = self:_row(FH, true)
	local sc = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0
	}, row)
	list(sc, 0, true)
	local obj = {Frame = row, Path = {}}
	local function render()
		for _, c in sc:GetChildren() do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
		local n = #obj.Path
		for i, name in obj.Path do
			local last = i == n
			local b = button(sc, T.Clear, {
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = name,
				TextColor3 = last and T.Text or T.CheckMark,
				LayoutOrder = i * 2 - 1
			})
			pad(b, 4, 4, 0, 0)
			if not last then
				bind(b, T.Clear, T.HeaderHover, T.HeaderActive)
				b.MouseButton1Click:Connect(function()
					local cut = {}
					for j = 1, i do
						cut[j] = obj.Path[j]
					end
					obj.Path = cut
					render()
					if callback then
						task.spawn(callback, i, name, cut)
					end
				end)
			else
				b.AutoButtonColor = false
			end
			if not last then
				label(sc, opts.Separator or ">", {
					Size = UDim2.new(0, textWidth(opts.Separator or ">") + 4, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					TextColor3 = T.TextDisabled,
					LayoutOrder = i * 2
				})
			end
		end
		task.defer(function()
			sc.CanvasPosition = Vector2.new(100000, 0)
		end)
	end
	function obj:Set(p)
		obj.Path = {}
		for i, v in p do
			obj.Path[i] = tostring(v)
		end
		render()
	end
	function obj:Push(name)
		table.insert(obj.Path, tostring(name))
		render()
	end
	function obj:Pop()
		table.remove(obj.Path)
		render()
	end
	function obj:Get()
		return obj.Path
	end
	obj:Set(path or {})
	return obj
end

function Container:Grid(columns, opts)
	opts = opts or {}
	columns = math.max(1, columns or 2)
	self._n = self._n + 1
	local gap = opts.Gap or GAP
	local f = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self._n
	}, self.Content)
	new("UIGridLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		CellPadding = UDim2.fromOffset(gap, gap),
		CellSize = UDim2.new(1 / columns, -gap * (columns - 1) / columns - 0.5, 0, opts.CellHeight or FH),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top
	}, f)
	local g = makeContainer(self.Win, f, false)
	g.ItemWidth = columns >= 3 and 0.45 or 0.5
	g.Frame = f
	function g:Cell(o)
		o = o or {}
		g._n = g._n + 1
		local cell = frame(f, o.Color and {o.Color, 0.6} or T.Frame, {
			LayoutOrder = g._n,
			ClipsDescendants = true
		})
		if o.Border ~= false then
			stroke(cell, T.Border)
		end
		pad(cell, 4, 4, 2, 2)
		list(cell, 2).VerticalAlignment = Enum.VerticalAlignment.Top
		local c = makeContainer(g.Win, cell, false)
		c.ItemWidth = 0.5
		c.Frame = cell
		return c
	end
	return g
end

function Container:StickyHeader(text, opts)
	opts = opts or {}
	local win = self.Win
	local row = self:_row(FH)
	local header = frame(row, T.Header, {Size = UDim2.fromScale(1, 1)})
	label(header, text, {
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.fromOffset(6, 0)
	})
	win.Stickies = win.Stickies or {}
	local entry = {Row = row, Text = text}
	table.insert(win.Stickies, entry)
	if not win.StickyOverlay and win.Body and win.Frame then
		local overlay = frame(win.Frame, T.Header, {
			Size = UDim2.new(1, -(SB + 2), 0, FH),
			Visible = false,
			ZIndex = 30
		})
		local ot = label(overlay, "", {
			Size = UDim2.new(1, -8, 1, 0),
			Position = UDim2.fromOffset(PADX + 6, 0),
			ZIndex = 31
		})
		win.StickyOverlay = {Frame = overlay, Label = ot}
		local function shown(r)
			local p = r
			while p and p ~= win.Frame do
				if p:IsA("GuiObject") and not p.Visible then
					return false
				end
				p = p.Parent
			end
			return true
		end
		local function update()
			local body = win.Body
			local top = body.AbsolutePosition.Y
			local best
			for i = #win.Stickies, 1, -1 do
				local e = win.Stickies[i]
				if e.Row.Parent and shown(e.Row) and e.Row.AbsolutePosition.Y < top - 1 then
					best = e
					break
				end
			end
			overlay.Visible = best ~= nil
			if best then
				ot.Text = best.Text
				local origin = win.Frame.AbsolutePosition
				overlay.Position = UDim2.fromOffset(0, (top - origin.Y) / win.Scale)
			end
		end
		win.Body:GetPropertyChangedSignal("CanvasPosition"):Connect(update)
		win.StickyOverlay.Update = update
	end
	local obj = {Frame = row}
	function obj:SetText(v)
		entry.Text = v
		for _, d in header:GetChildren() do
			if d:IsA("TextLabel") then
				d.Text = v
			end
		end
	end
	return obj
end

function Container:Resizable(height, opts)
	opts = opts or {}
	local win = self.Win
	local minH = opts.Min or 60
	local maxH = opts.Max or 400
	local h = clamp(height or 120, minH, maxH)
	local row = self:_row(h + 10, true)
	local area = frame(row, T.Inset, {Size = UDim2.new(1, 0, 1, -10), ClipsDescendants = true})
	stroke(area, T.Border)
	local pane, sc = makePane(area, win)
	pane.ItemWidth = 0.5
	local handle = button(row, T.Frame, {
		Size = UDim2.new(1, 0, 0, 10),
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Text = "· · ·",
		TextColor3 = T.TextDisabled,
		TextSize = TS - 2
	})
	bind(handle, T.Frame, T.FrameHover, T.FrameActive)
	local function apply(v)
		h = clamp(v, minH, maxH)
		row.Size = UDim2.new(1, 0, 0, h + 10)
	end
	handle.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		local start = Vector2.new(input.Position.X, input.Position.Y)
		local origin = h
		if win.Body then
			win.Body.ScrollingEnabled = false
		end
		beginDrag(input, function(pos)
			apply(origin + (pos.Y - start.Y) / win.Scale)
		end, function()
			if win.Body then
				win.Body.ScrollingEnabled = true
			end
			if opts.OnResize then
				task.spawn(opts.OnResize, h)
			end
		end)
	end)
	pane.Frame = row
	pane.SetHeight = function(_, v)
		apply(v)
	end
	pane.GetHeight = function()
		return h
	end
	return pane
end

local ICON_SET = {}
for _, v in ICONS do
	ICON_SET[v] = true
end

local THEME_TOKENS = {}
for k in T do
	table.insert(THEME_TOKENS, k)
end
table.sort(THEME_TOKENS)

local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
local PD = {fh = 0.46, fa = 0.33, b = 0.6, h = 0.69, tab = 0.14}
local PL = {fh = 0.6, fa = 0.33, b = 0.4, h = 0.31, tab = 0.07}

local function accentSet(A, pr)
	return {
		FrameHover = {A, pr.fh},
		FrameActive = {A, pr.fa},
		Button = {A, pr.b},
		ButtonHover = {A, 0},
		ButtonActive = {A:Lerp(BLACK, 0.1), 0},
		Header = {A, pr.h},
		HeaderHover = {A, 0.2},
		HeaderActive = {A, 0},
		Tab = {A:Lerp(BLACK, 0.3), pr.tab},
		TabHover = {A, 0.2},
		TabActive = {A:Lerp(BLACK, 0.2), 0},
		Grab = {A, 0},
		GrabActive = {A:Lerp(WHITE, 0.35), 0},
		GripIdle = {A, 0.8},
		GripActive = {A, 0.05},
		CheckMark = A
	}
end

local DEFAULT_ACCENT = Color3.fromRGB(66, 150, 250)

local THEMES = {
	["Iris 深色"] = {
		Accent = DEFAULT_ACCENT,
		Profile = PD,
		Build = function(A)
			local dim = A:Lerp(BLACK, 0.5)
			return {
				Frame = {dim, 0.46},
				TitleActive = {dim, 0}
			}
		end
	},
	["经典 ImGui"] = {
		Accent = Color3.fromRGB(102, 102, 230),
		Profile = PD,
		Build = function(A)
			return {
				WindowBg = tok(0, 0, 0, 0.15),
				PopupBg = tok(20, 20, 26, 0.1),
				Title = tok(10, 10, 10, 0),
				TitleActive = {A:Lerp(BLACK, 0.4), 0},
				Menubar = tok(36, 36, 46, 0),
				Frame = tok(110, 110, 110, 0.6),
				Border = tok(128, 128, 128, 0.5)
			}
		end
	},
	["浅色"] = {
		Accent = DEFAULT_ACCENT,
		Profile = PL,
		Build = function(A)
			return {
				Inset = tok(0, 0, 0, 0.07),
				WindowBg = tok(240, 240, 240, 0.06),
				PopupBg = tok(255, 255, 255, 0.02),
				Title = tok(245, 245, 245, 0),
				TitleActive = tok(209, 209, 209, 0),
				TitleCollapsed = tok(255, 255, 255, 0.49),
				Menubar = tok(219, 219, 219, 0),
				Frame = tok(255, 255, 255, 0),
				Separator = tok(99, 99, 99, 0.38),
				Border = tok(0, 0, 0, 0.7),
				Text = Color3.fromRGB(0, 0, 0),
				TextDisabled = Color3.fromRGB(153, 153, 153),
				Scroll = Color3.fromRGB(204, 204, 204)
			}
		end
	},
	["纯黑 OLED"] = {
		Accent = DEFAULT_ACCENT,
		Profile = PD,
		Build = function(A)
			return {
				WindowBg = tok(4, 4, 4, 0.04),
				PopupBg = tok(8, 8, 8, 0.04),
				Title = tok(0, 0, 0, 0),
				TitleActive = {A:Lerp(BLACK, 0.6), 0},
				Menubar = tok(14, 14, 14, 0),
				Frame = tok(32, 32, 32, 0.2),
				Separator = tok(80, 80, 80, 0.5),
				Border = tok(70, 70, 70, 0.4),
				TextDisabled = Color3.fromRGB(120, 120, 120),
				Scroll = Color3.fromRGB(70, 70, 70)
			}
		end
	}
}

local THEME_NAMES = {"Iris 深色", "经典 ImGui", "浅色", "纯黑 OLED"}

local function buildTheme(name, accent, opacity)
	local def = THEMES[name] or THEMES["Iris 深色"]
	local A = accent or def.Accent
	local out = {}
	if name == "Iris 深色" and A == DEFAULT_ACCENT then
		for k, v in DARK do
			out[k] = typeof(v) ~= "Color3" and {v[1], v[2]} or v
		end
	else
		for k, v in DARK do
			out[k] = typeof(v) ~= "Color3" and {v[1], v[2]} or v
		end
		for k, v in accentSet(A, def.Profile) do
			out[k] = v
		end
		for k, v in def.Build(A) do
			out[k] = v
		end
	end
	opacity = clamp(opacity or 1, 0.2, 1)
	for _, k in {"WindowBg", "PopupBg"} do
		out[k] = {out[k][1], 1 - (1 - out[k][2]) * opacity}
	end
	return out
end

local function ckey(c)
	return string.format("%d,%d,%d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function tkey(c, t)
	return ckey(c) .. string.format(",%.2f", t)
end

Library.ThemeHooks = {}
Library.Themes = THEME_NAMES
Library.BuildTheme = buildTheme

function Library:ApplyTheme()
	local bgMap, fgMap, strokeMap, gripMap = {}, {}, {}, {}
	for _, n in THEME_TOKENS do
		local v = T[n]
		if typeof(v) ~= "Color3" then
			local k = tkey(v[1], v[2])
			if not bgMap[k] then
				bgMap[k] = n
			end
			if n == "Border" or n == "Separator" then
				strokeMap[k] = strokeMap[k] or n
			end
			if n == "GripIdle" or n == "GripActive" then
				gripMap[k] = gripMap[k] or n
			end
		else
			local k = ckey(v)
			if not fgMap[k] then
				fgMap[k] = n
			end
		end
	end
	local new = buildTheme(Settings.Theme, Settings.Accent, Settings.Opacity)
	for k, v in new do
		if typeof(v) ~= "Color3" then
			T[k][1], T[k][2] = v[1], v[2]
		else
			T[k] = v
		end
	end
	local gui = Library.Gui
	if not gui then
		return
	end
	for _, o in gui:GetDescendants() do
		if o.Name == "__FX" or (o.Parent and o.Parent.Name == "__FX") then
			continue
		end
		if o:IsA("GuiObject") then
			local n = bgMap[tkey(o.BackgroundColor3, o.BackgroundTransparency)]
			if n then
				paint(o, T[n])
			end
			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				local f = fgMap[ckey(o.TextColor3)]
				if f then
					o.TextColor3 = T[f]
				end
				if o:IsA("TextBox") then
					local pf = fgMap[ckey(o.PlaceholderColor3)]
					if pf then
						o.PlaceholderColor3 = T[pf]
					end
				end
			elseif (o:IsA("ImageLabel") or o:IsA("ImageButton")) and ICON_SET[o.Image] then
				local g = gripMap[tkey(o.ImageColor3, o.ImageTransparency)]
				if g then
					o.ImageColor3 = T[g][1]
					o.ImageTransparency = T[g][2]
				else
					local f = fgMap[ckey(o.ImageColor3)]
					if f then
						o.ImageColor3 = T[f]
					end
				end
			end
			if o:IsA("ScrollingFrame") then
				local f = fgMap[ckey(o.ScrollBarImageColor3)]
				if f then
					o.ScrollBarImageColor3 = T[f]
				end
			end
		elseif o:IsA("UIStroke") then
			local n = strokeMap[tkey(o.Color, o.Transparency)]
			if n then
				o.Color = T[n][1]
				o.Transparency = T[n][2]
			end
		end
	end
	for _, w in Library.Windows do
		w:_titleColor()
	end
	for _, h in Library.ThemeHooks do
		pcall(h)
	end
end

local applyPending = false

function Library:QueueTheme()
	if applyPending then
		return
	end
	applyPending = true
	task.delay(0.06, function()
		applyPending = false
		Library:ApplyTheme()
	end)
end

function Library:SetTheme(name, accent)
	if not THEMES[name] then
		return
	end
	Settings.Theme = name
	Settings.Accent = accent
	Library:QueueTheme()
end

function Library:SetAccent(color)
	Settings.Accent = color
	Library:QueueTheme()
end

function Library:SetOpacity(v)
	Settings.Opacity = clamp(v, 0.2, 1)
	Library:QueueTheme()
end

function Library:SetFont(name)
	local ok, f = pcall(function()
		return Enum.Font[name]
	end)
	if not ok or not f then
		return
	end
	FONT = f
	Settings.Font = name
	for _, o in Library.Gui:GetDescendants() do
		if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
			o.Font = f
		end
	end
end

function Library:SetNumpad(v)
	Settings.Numpad = v and true or false
end

function Library:SetAnimation(v)
	Settings.Anim = v and true or false
end

function Container:ThemePicker(opts)
	opts = opts or {}
	local lib = self.Win.Lib
	local obj = {}
	obj.Theme = self:Combo("主题", THEME_NAMES, Settings.Theme, function(v)
		lib:SetTheme(v, nil)
	end)
	local swatches = {
		{"蓝", Color3.fromRGB(66, 150, 250)},
		{"紫", Color3.fromRGB(150, 90, 250)},
		{"粉", Color3.fromRGB(245, 100, 170)},
		{"红", Color3.fromRGB(230, 70, 70)},
		{"橙", Color3.fromRGB(240, 150, 50)},
		{"绿", Color3.fromRGB(70, 200, 110)},
		{"青", Color3.fromRGB(50, 200, 210)}
	}
	local row = self:Row()
	for _, sw in swatches do
		row:SmallButton(sw[1], function()
			lib:SetAccent(sw[2])
			if obj.Custom then
				obj.Custom.Set(sw[2], false)
			end
		end, sw[2])
	end
	obj.Custom = self:ColorEdit("强调色", Settings.Accent or DEFAULT_ACCENT, function(c)
		lib:SetAccent(c)
	end)
	obj.Opacity = self:SliderInt("窗口透明度", 30, 100, math.floor(Settings.Opacity * 100), function(v)
		lib:SetOpacity(v / 100)
	end)
	obj.Anim = self:Checkbox("界面动画", Settings.Anim, function(v)
		lib:SetAnimation(v)
	end)
	obj.Numpad = self:Checkbox("数字键盘（滑条点击输入）", Settings.Numpad, function(v)
		lib:SetNumpad(v)
	end)
	obj.Font = self:Combo("字体", {"Code", "RobotoMono", "SourceSans", "Ubuntu", "Arial", "Gotham"}, Settings.Font or "Code", function(v)
		lib:SetFont(v)
	end)
	return obj
end

local TipState = {Token = 0}

local function hideTip()
	TipState.Token = TipState.Token + 1
	if TipState.Frame then
		TipState.Frame:Destroy()
		TipState.Frame = nil
	end
end

local function showTip(target, text)
	hideTip()
	local gui = Library.Gui
	local vp = gui.AbsoluteSize
	local w = math.min(textWidth(text) + 14, vp.X - 16)
	local tipFrame = frame(gui, T.PopupBg, {
		Size = UDim2.fromOffset(w, FH + 4),
		ZIndex = 3000
	})
	stroke(tipFrame, T.Border)
	label(tipFrame, text, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3001
	})
	local ap, as = target.AbsolutePosition, target.AbsoluteSize
	local x = clamp(ap.X + as.X / 2 - w / 2, 4, vp.X - w - 4)
	local y = ap.Y - FH - 10
	if y < 4 then
		y = ap.Y + as.Y + 6
	end
	tipFrame.Position = UDim2.fromOffset(x, y)
	TipState.Frame = tipFrame
	local token = TipState.Token
	task.delay(3, function()
		if TipState.Token == token then
			hideTip()
		end
	end)
end

function Library:SetTooltip(target, text, delay)
	delay = delay or (TOUCH and 0.45 or 0.5)
	local pending = 0
	local function cancel()
		pending = pending + 1
		hideTip()
	end
	local function arm()
		pending = pending + 1
		local mine = pending
		task.delay(delay, function()
			if pending == mine and target.Parent then
				showTip(target, text)
			end
		end)
	end
	target.MouseEnter:Connect(function()
		if not TOUCH then
			arm()
		end
	end)
	target.MouseLeave:Connect(cancel)
	target.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			arm()
		end
	end)
	target.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			pending = pending + 1
			task.delay(1.2, hideTip)
		end
	end)
end

function Container:Tooltip(obj, text)
	local target = obj and (obj.Frame or obj.Button) or nil
	if target then
		self.Win.Lib:SetTooltip(target, text)
	end
	return obj
end

local debounceTokens = {}

local function debounce(key, fn)
	debounceTokens[key] = (debounceTokens[key] or 0) + 1
	local mine = debounceTokens[key]
	task.delay(0.08, function()
		if debounceTokens[key] == mine then
			fn()
		end
	end)
end

function Library:Fit()
	local vp = Library.Gui.AbsoluteSize
	if vp.X <= 0 or vp.Y <= 0 then
		return
	end
	for _, w in Library.Windows do
		local s = w.Scale
		local f = w.Frame
		local sz = f.Size
		local nw = math.min(sz.X.Offset, (vp.X - 12) / s)
		local nh = sz.Y.Offset
		if not w.Collapsed then
			nh = math.min(nh, (vp.Y - 12) / s)
		end
		f.Size = UDim2.fromOffset(nw, nh)
		if w.ExpandedSize then
			w.ExpandedSize = UDim2.fromOffset(math.min(w.ExpandedSize.X.Offset, nw), math.min(w.ExpandedSize.Y.Offset, (vp.Y - 12) / s))
		end
		local pos = f.Position
		f.Position = UDim2.fromOffset(clamp(pos.X.Offset, -(nw * s - 50), vp.X - 50), clamp(pos.Y.Offset, 0, vp.Y - FH * s))
	end
end

function Library:SetUIScale(v)
	v = clamp(v, 0.7, 1.5)
	Settings.Scale = v
	local vp = Library.Gui.AbsoluteSize
	if vp.X <= 0 then
		vp = Vector2.new(800, 600)
	end
	for _, w in Library.Windows do
		w.Scale = v
		w.UIScale.Scale = v
		local sz = w.Frame.Size
		w.Frame.Size = UDim2.fromOffset(math.min(sz.X.Offset, (vp.X - 12) / v), math.min(sz.Y.Offset, (vp.Y - 12) / v))
	end
	Library:Fit()
end

function Library:SetTextSize(n)
	n = clamp(math.floor(n + 0.5), 10, 17)
	local old = TS
	if n == old then
		return
	end
	TS = n
	Settings.TextSize = n
	for _, o in Library.Gui:GetDescendants() do
		if (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) and o.TextSize == old then
			o.TextSize = n
		end
	end
end

function Library:SetRounding(r)
	r = clamp(math.floor(r + 0.5), 0, 12)
	Settings.Round = r
	for _, o in Library.Gui:GetDescendants() do
		if (o:IsA("Frame") or o:IsA("TextButton") or o:IsA("TextBox")) and o.BackgroundTransparency < 1 then
			local c = o:FindFirstChild("__R")
			if r > 0 then
				if c then
					c.CornerRadius = UDim.new(0, r)
				elseif not o:FindFirstChildOfClass("UICorner") then
					local nc = Instance.new("UICorner")
					nc.Name = "__R"
					nc.CornerRadius = UDim.new(0, r)
					nc.Parent = o
				end
			elseif c then
				c:Destroy()
			end
		end
	end
end

function Library:SetBorder(n)
	n = clamp(math.floor(n + 0.5), 0, 4)
	local old = Settings.Border
	Settings.Border = n
	for _, o in Library.Gui:GetDescendants() do
		if o:IsA("UIStroke") and o.Thickness == old then
			o.Thickness = n
		end
	end
end

function Library:_updateBlur()
	if Settings.Blur <= 0 and not Library.Blur then
		return
	end
	if not Library.Blur then
		pcall(function()
			local b = Instance.new("BlurEffect")
			b.Name = "ImGuiBlur"
			b.Size = 0
			b.Parent = game:GetService("Lighting")
			Library.Blur = b
		end)
	end
	if not Library.Blur then
		return
	end
	local any = false
	for _, w in Library.Windows do
		if w.Visible then
			any = true
		end
	end
	local target = any and Settings.Blur or 0
	if Settings.Anim then
		TweenService:Create(Library.Blur, FADE, {Size = target}):Play()
	else
		Library.Blur.Size = target
	end
end

function Library:SetBlur(n)
	Settings.Blur = clamp(n, 0, 40)
	Library:_updateBlur()
end

function Library:SetSounds(on, volume)
	Settings.Sounds = on and true or false
	if not Settings.Sounds then
		UIHooks.Click = nil
		return
	end
	if not Library.ClickSound then
		pcall(function()
			local snd = Instance.new("Sound")
			snd.Name = "ImGuiClick"
			snd.SoundId = "rbxassetid://6895079853"
			snd.Volume = volume or 0.6
			snd.Parent = game:GetService("SoundService")
			Library.ClickSound = snd
		end)
	end
	if Library.ClickSound then
		if volume then
			Library.ClickSound.Volume = volume
		end
		UIHooks.Click = function()
			pcall(function()
				Library.ClickSound:Play()
			end)
		end
	end
end

function Library:SetAnimSpeed(m)
	m = clamp(m, 0.25, 3)
	Settings.Speed = m
	FADE = TweenInfo.new(0.12 / m, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	SPIN = TweenInfo.new(0.16 / m, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	POP = TweenInfo.new(0.14 / m, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Library:ExportTheme()
	local data = {
		Theme = Settings.Theme,
		Opacity = Settings.Opacity,
		Font = Settings.Font,
		Scale = Settings.Scale,
		TextSize = Settings.TextSize,
		Round = Settings.Round,
		Border = Settings.Border,
		Blur = Settings.Blur,
		Sounds = Settings.Sounds,
		Speed = Settings.Speed,
		Anim = Settings.Anim,
		Numpad = Settings.Numpad
	}
	if Settings.Accent then
		data.Accent = {Settings.Accent.R, Settings.Accent.G, Settings.Accent.B}
	end
	return HttpService:JSONEncode(data)
end

function Library:ImportTheme(json)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(data) ~= "table" then
		return false
	end
	if data.Theme and THEMES[data.Theme] then
		Settings.Theme = data.Theme
	end
	Settings.Accent = type(data.Accent) == "table" and Color3.new(data.Accent[1], data.Accent[2], data.Accent[3]) or nil
	if data.Opacity then
		Settings.Opacity = clamp(data.Opacity, 0.2, 1)
	end
	Library:ApplyTheme()
	if data.Font then
		Library:SetFont(data.Font)
	end
	if data.Scale then
		Library:SetUIScale(data.Scale)
	end
	if data.TextSize then
		Library:SetTextSize(data.TextSize)
	end
	if data.Round then
		Library:SetRounding(data.Round)
	end
	if data.Border then
		Library:SetBorder(data.Border)
	end
	if data.Blur then
		Library:SetBlur(data.Blur)
	end
	if data.Sounds ~= nil then
		Library:SetSounds(data.Sounds)
	end
	if data.Speed then
		Library:SetAnimSpeed(data.Speed)
	end
	if data.Anim ~= nil then
		Library:SetAnimation(data.Anim)
	end
	if data.Numpad ~= nil then
		Library:SetNumpad(data.Numpad)
	end
	return true
end

Library.FX = {}

local WHITE3 = Color3.new(1, 1, 1)
local RAINBOW_LIST = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(255, 200, 70),
	Color3.fromRGB(110, 230, 120),
	Color3.fromRGB(70, 210, 240),
	Color3.fromRGB(110, 130, 255),
	Color3.fromRGB(220, 110, 250)
}

local PALETTES = {
	Aurora = {Color3.fromRGB(60, 220, 170), Color3.fromRGB(80, 120, 255), Color3.fromRGB(180, 90, 255)},
	Sunset = {Color3.fromRGB(255, 120, 80), Color3.fromRGB(255, 70, 140), Color3.fromRGB(150, 80, 255)},
	Ocean = {Color3.fromRGB(40, 200, 255), Color3.fromRGB(40, 100, 230), Color3.fromRGB(40, 220, 190)},
	Rainbow = RAINBOW_LIST
}

local function colorSeq(colors)
	local n = #colors
	local kps = {}
	for i = 1, n + 1 do
		kps[i] = ColorSequenceKeypoint.new((i - 1) / n, colors[((i - 1) % n) + 1])
	end
	return ColorSequence.new(kps)
end

local function numSeq(points)
	local kps = {}
	for i, p in points do
		kps[i] = NumberSequenceKeypoint.new(p[1], p[2])
	end
	return NumberSequence.new(kps)
end

local function loopTween(list, inst, dur, props, reverse, style)
	local ok, tw = pcall(function()
		return TweenService:Create(inst, TweenInfo.new(dur, style or Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, reverse or false, 0), props)
	end)
	if ok and tw then
		tw:Play()
		table.insert(list, tw)
	end
	return tw
end

local function cancelAll(list)
	for _, tw in list do
		pcall(function()
			tw:Cancel()
		end)
	end
end

local function resolveColors(opts, default)
	if opts and opts.Palette and PALETTES[opts.Palette] then
		return PALETTES[opts.Palette]
	end
	if opts and opts.Colors and #opts.Colors >= 2 then
		return opts.Colors
	end
	return default
end

function Library:Effect(target, kind, opts)
	opts = opts or {}
	local speed = opts.Speed or 1
	local h = {Kind = kind, Target = target, Tweens = {}, Parts = {}, Active = true}
	local seq = colorSeq(resolveColors(opts, RAINBOW_LIST))
	if kind == "Shimmer" then
		local ov = frame(target, {opts.Color or WHITE3, 0}, {Size = UDim2.fromScale(1, 1), ZIndex = 20, Name = "__FX"})
		local g = new("UIGradient", {
			Rotation = 20,
			Offset = Vector2.new(-1.6, 0),
			Transparency = numSeq({{0, 1}, {0.4, 1}, {0.5, 0.72}, {0.6, 1}, {1, 1}})
		}, ov)
		loopTween(h.Tweens, g, 2.2 / speed, {Offset = Vector2.new(1.6, 0)})
		table.insert(h.Parts, ov)
	elseif kind == "FlowBorder" or kind == "Pulse" then
		local st = target:FindFirstChildOfClass("UIStroke")
		if st then
			h.Restore = {Stroke = st, Color = st.Color, Transparency = st.Transparency, Thickness = st.Thickness}
		else
			st = new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1.5, Color = WHITE3}, target)
			table.insert(h.Parts, st)
		end
		if kind == "FlowBorder" then
			st.Color = WHITE3
			st.Transparency = 0
			st.Thickness = math.max(st.Thickness, opts.Thickness or 1.5)
			local g = new("UIGradient", {Color = seq}, st)
			loopTween(h.Tweens, g, 3.5 / speed, {Rotation = 360})
			table.insert(h.Parts, g)
		else
			local base = h.Restore and h.Restore.Transparency or 0.3
			st.Color = (resolveColors(opts, {T.CheckMark, T.CheckMark}))[1]
			st.Thickness = math.max(st.Thickness, opts.Thickness or 1.5)
			st.Transparency = base
			loopTween(h.Tweens, st, 1.2 / speed, {Transparency = 0.9}, true, Enum.EasingStyle.Sine)
		end
	elseif kind == "RainbowText" then
		local g = new("UIGradient", {Color = seq}, target)
		loopTween(h.Tweens, g, 4 / speed, {Rotation = 360})
		table.insert(h.Parts, g)
	else
		return nil
	end
	function h:Stop()
		if not h.Active then
			return
		end
		h.Active = false
		cancelAll(h.Tweens)
		for _, p in h.Parts do
			pcall(function()
				p:Destroy()
			end)
		end
		if h.Restore and h.Restore.Stroke.Parent then
			local r = h.Restore
			r.Stroke.Color = r.Color
			r.Stroke.Transparency = r.Transparency
			r.Stroke.Thickness = r.Thickness
		end
	end
	return h
end

local PARTICLES = {
	Snow = {Color = WHITE3, Size = {2, 5}, Duration = {6, 12}, Drift = 0.06, Alpha = {0.05, 0.45}},
	Rain = {Color = Color3.fromRGB(150, 195, 255), Line = true, Size = {8, 14}, Duration = {0.7, 1.3}, Drift = -0.03, Alpha = {0.3, 0.65}},
	Bubbles = {Color = Color3.fromRGB(170, 220, 255), Size = {4, 11}, Duration = {6, 12}, Up = true, Drift = 0.04, Alpha = {0.55, 0.8}, Hollow = true},
	Petals = {Color = Color3.fromRGB(255, 170, 200), Size = {4, 7}, Duration = {7, 13}, Drift = 0.16, Alpha = {0.1, 0.4}, Spin = true},
	Stars = {Color = WHITE3, Size = {1, 3}, Twinkle = true, Alpha = {0.1, 0.5}},
	Fireflies = {Color = Color3.fromRGB(255, 230, 120), Size = {2, 4}, Wander = true, Twinkle = true, Alpha = {0.1, 0.5}}
}

local PARTICLE_NAMES = {["雪"] = "Snow", ["雨"] = "Rain", ["气泡"] = "Bubbles", ["花瓣"] = "Petals", ["星空"] = "Stars", ["萤火虫"] = "Fireflies"}

local function rand(a, b)
	return a + math.random() * (b - a)
end

local function makeParticles(parent, kind, opts, zindex)
	kind = PARTICLE_NAMES[kind] or kind
	local cfg = PARTICLES[kind]
	if not cfg then
		return nil
	end
	opts = opts or {}
	local layer = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		ZIndex = zindex or 0,
		Name = "__FX"
	}, parent)
	local h = {Layer = layer, Kind = kind, Alive = true, Tweens = {}}
	local count = opts.Count or (TOUCH and 18 or 30)
	local color = opts.Color or cfg.Color
	local function track(tw)
		table.insert(h.Tweens, tw)
		if #h.Tweens > count * 4 then
			table.remove(h.Tweens, 1)
		end
	end
	for _ = 1, count do
		local size = rand(cfg.Size[1], cfg.Size[2])
		local f = new("Frame", {
			BackgroundColor3 = color,
			BackgroundTransparency = rand(cfg.Alpha[1], cfg.Alpha[2]),
			BorderSizePixel = 0,
			Size = cfg.Line and UDim2.fromOffset(1, size) or UDim2.fromOffset(size, size),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(math.random(), math.random())
		}, layer)
		if not cfg.Line then
			new("UICorner", {CornerRadius = UDim.new(1, 0)}, f)
		end
		if cfg.Hollow then
			f.BackgroundTransparency = 1
			new("UIStroke", {Color = color, Transparency = rand(cfg.Alpha[1], cfg.Alpha[2]), Thickness = 1}, f)
		end
		local function launch(first)
			if not h.Alive or not f.Parent then
				return
			end
			local x0 = math.random()
			local dur = rand(cfg.Duration[1], cfg.Duration[2])
			local y0 = cfg.Up and 1.05 or -0.05
			local y1 = cfg.Up and -0.05 or 1.05
			if first then
				y0 = math.random()
				dur = dur * math.abs(y1 - y0) / 1.1
			end
			f.Position = UDim2.fromScale(x0, y0)
			local ok, tw = pcall(function()
				return TweenService:Create(f, TweenInfo.new(math.max(dur, 0.2), Enum.EasingStyle.Linear), {
					Position = UDim2.fromScale(x0 + (cfg.Drift or 0) * (math.random() > 0.5 and 1 or -1), y1)
				})
			end)
			if not ok or not tw then
				return
			end
			track(tw)
			if tw.Completed then
				tw.Completed:Connect(function()
					launch(false)
				end)
			end
			tw:Play()
		end
		if cfg.Twinkle then
			loopTween(h.Tweens, f, rand(1, 3.5), {BackgroundTransparency = 0.92}, true, Enum.EasingStyle.Sine)
		end
		if cfg.Wander then
			local x, y = math.random(), math.random()
			f.Position = UDim2.fromScale(x, y)
			loopTween(h.Tweens, f, rand(3, 6), {Position = UDim2.fromScale(clamp(x + rand(-0.12, 0.12), 0, 1), clamp(y + rand(-0.12, 0.12), 0, 1))}, true, Enum.EasingStyle.Sine)
		elseif not cfg.Twinkle then
			launch(true)
		end
		if cfg.Spin then
			loopTween(h.Tweens, f, rand(2, 5), {Rotation = 360})
		end
	end
	function h:Stop()
		if not h.Alive then
			return
		end
		h.Alive = false
		cancelAll(h.Tweens)
		if layer.Parent then
			layer:Destroy()
		end
	end
	return h
end

function Window:Particles(kind, opts)
	if self.FXParticles then
		self.FXParticles:Stop()
		self.FXParticles = nil
	end
	if not kind or kind == "None" or kind == "无" then
		return nil
	end
	self.FXParticles = makeParticles(self.Frame, kind, opts, 0)
	return self.FXParticles
end

function Window:Backdrop(kind, opts)
	opts = opts or {}
	if self.FXBackdrop then
		cancelAll(self.FXBackdrop.Tweens)
		self.FXBackdrop.Layer:Destroy()
		self.FXBackdrop = nil
	end
	if not kind or kind == "None" or kind == "无" then
		return
	end
	local colors = PALETTES[kind] or resolveColors(opts, PALETTES.Aurora)
	local layer = frame(self.Frame, {WHITE3, opts.Alpha or 0.82}, {Size = UDim2.fromScale(1, 1), ZIndex = 0, Name = "__FX"})
	local g = new("UIGradient", {Color = colorSeq(colors)}, layer)
	local tweens = {}
	loopTween(tweens, g, 14 / (opts.Speed or 1), {Rotation = 360})
	self.FXBackdrop = {Layer = layer, Tweens = tweens}
end

function Window:SetBorderEffect(kind, opts)
	if self.FXBorder then
		self.FXBorder:Stop()
		self.FXBorder = nil
	end
	if not kind or kind == "None" or kind == "无" then
		if self.GlassRim then
			self:_glassRim()
		end
		return nil
	end
	local map = {Flow = "FlowBorder", ["流光"] = "FlowBorder", Pulse = "Pulse", ["呼吸"] = "Pulse", Rainbow = "FlowBorder", ["彩虹"] = "FlowBorder"}
	local real = map[kind] or kind
	if self.GlassRim then
		self.GlassRim:Destroy()
		self.GlassRim = nil
		local st = self.Frame:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = T.Border[1]
			st.Transparency = T.Border[2]
		end
	end
	self.FXBorder = Library:Effect(self.Frame, real, opts)
	return self.FXBorder
end

function Window:_glassRim()
	if self.GlassRim then
		self.GlassRim:Destroy()
		self.GlassRim = nil
	end
	local st = self.Frame:FindFirstChildOfClass("UIStroke")
	if st and not self.FXBorder then
		st.Color = WHITE3
		st.Transparency = 0
		self.GlassRim = new("UIGradient", {
			Rotation = 45,
			Color = ColorSequence.new({ColorSequenceKeypoint.new(0, WHITE3), ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 195, 255))}),
			Transparency = numSeq({{0, 0.1}, {0.45, 0.8}, {1, 0.35}})
		}, st)
	end
end

function Window:_glass(on)
	if self.GlassParts then
		for _, tw in self.GlassParts.Tweens do
			pcall(function()
				tw:Cancel()
			end)
		end
		for _, l in self.GlassParts.Layers do
			l:Destroy()
		end
		self.GlassParts = nil
	end
	if self.GlassRim then
		self.GlassRim:Destroy()
		self.GlassRim = nil
		local st = self.Frame:FindFirstChildOfClass("UIStroke")
		if st and not self.FXBorder then
			st.Color = T.Border[1]
			st.Transparency = T.Border[2]
		end
	end
	if not on then
		return
	end
	local layers, tweens = {}, {}
	local defs = {
		{Rot = 35, Seq = {{0, 0.82}, {0.5, 0.95}, {1, 0.9}}, From = -0.35, To = 0.35, Dur = 7},
		{Rot = 125, Seq = {{0, 0.95}, {0.3, 0.9}, {0.6, 0.97}, {1, 0.92}}, From = 0.3, To = -0.3, Dur = 9}
	}
	for _, d in defs do
		local l = frame(self.Frame, {WHITE3, 0}, {Size = UDim2.fromScale(1, 1), ZIndex = 0, Name = "__FX"})
		local g = new("UIGradient", {Rotation = d.Rot, Transparency = numSeq(d.Seq), Offset = Vector2.new(d.From, 0)}, l)
		loopTween(tweens, g, d.Dur, {Offset = Vector2.new(d.To, 0)}, true, Enum.EasingStyle.Sine)
		table.insert(layers, l)
	end
	self.GlassParts = {Layers = layers, Tweens = tweens}
	self:_glassRim()
end

function Library:_fxWindow(win)
	local fx = Library.FX
	if fx.Glass then
		win:_glass(true)
	end
	if fx.Border then
		win:SetBorderEffect(fx.Border, fx.BorderOpts)
	end
	if fx.Backdrop then
		win:Backdrop(fx.Backdrop, fx.BackdropOpts)
	end
	if fx.Particle then
		win:Particles(fx.Particle, fx.ParticleOpts)
	end
end

function Library:SetGlass(on, opts)
	opts = opts or {}
	local fx = Library.FX
	on = on and true or false
	if on and not fx.Glass then
		fx.Prev = {Opacity = Settings.Opacity, Blur = Settings.Blur, Round = Settings.Round}
		Library:SetOpacity(opts.Opacity or 0.6)
		Library:SetBlur(opts.Blur or 10)
		if Settings.Round < 6 then
			Library:SetRounding(8)
		end
	elseif not on and fx.Glass and fx.Prev then
		Library:SetOpacity(fx.Prev.Opacity)
		Library:SetBlur(fx.Prev.Blur)
		Library:SetRounding(fx.Prev.Round)
		fx.Prev = nil
	end
	fx.Glass = on
	for _, w in Library.Windows do
		w:_glass(on)
	end
end

function Library:SetBorderEffect(kind, opts)
	local none = not kind or kind == "None" or kind == "无"
	Library.FX.Border = (not none) and kind or nil
	Library.FX.BorderOpts = opts
	for _, w in Library.Windows do
		w:SetBorderEffect(kind, opts)
	end
end

function Library:Particles(kind, opts)
	local none = not kind or kind == "None" or kind == "无"
	Library.FX.Particle = (not none) and kind or nil
	Library.FX.ParticleOpts = opts
	for _, w in Library.Windows do
		w:Particles(kind, opts)
	end
end

function Library:Backdrop(kind, opts)
	local none = not kind or kind == "None" or kind == "无"
	Library.FX.Backdrop = (not none) and kind or nil
	Library.FX.BackdropOpts = opts
	for _, w in Library.Windows do
		w:Backdrop(kind, opts)
	end
end

function Library:ScreenParticles(kind, opts)
	if Library.FX.Screen then
		Library.FX.Screen:Stop()
		Library.FX.Screen = nil
	end
	if not kind or kind == "None" or kind == "无" then
		return nil
	end
	Library.FX.Screen = makeParticles(Library.Gui, kind, opts, 0)
	return Library.FX.Screen
end

function Library:SetRipple(on)
	Settings.Ripple = on and true or false
end

function Container:Banner(text, kind, opts)
	opts = opts or {}
	local row = self:_row(FH + 8)
	local panel = frame(row, T.Frame, {Size = UDim2.fromScale(1, 1)})
	stroke(panel, T.Border)
	local lbl = label(panel, text, {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center
	})
	local obj = {Frame = row, Label = lbl, Panel = panel}
	local function apply(k)
		if obj.Effect then
			obj.Effect:Stop()
			obj.Effect = nil
		end
		if k == "Rainbow" or k == "RainbowText" then
			obj.Effect = self.Win.Lib:Effect(lbl, "RainbowText", opts)
		elseif k == "Shimmer" then
			obj.Effect = self.Win.Lib:Effect(panel, "Shimmer", opts)
		elseif k == "Pulse" then
			obj.Effect = self.Win.Lib:Effect(panel, "Pulse", opts)
		else
			obj.Effect = self.Win.Lib:Effect(panel, "FlowBorder", opts)
		end
	end
	function obj:SetEffect(k)
		apply(k)
	end
	function obj:SetText(v)
		lbl.Text = v
	end
	apply(kind or "Flow")
	return obj
end

function Container:AppearancePanel()
	local win = self.Win
	local lib = win.Lib
	local obj = self:ThemePicker()
	self:Separator("界面")
	obj.Scale = self:Slider("界面缩放", 0.7, 1.5, Settings.Scale or win.Scale, function(v)
		lib:SetUIScale(v)
	end, {Format = "%.2f"})
	obj.TextSize = self:SliderInt("字号", 10, 17, TS, function(v)
		debounce("ts", function()
			lib:SetTextSize(v)
		end)
	end)
	obj.Round = self:SliderInt("圆角", 0, 12, Settings.Round, function(v)
		debounce("round", function()
			lib:SetRounding(v)
		end)
	end)
	obj.Border = self:SliderInt("边框粗细", 0, 4, Settings.Border, function(v)
		debounce("border", function()
			lib:SetBorder(v)
		end)
	end)
	obj.Blur = self:SliderInt("背景模糊", 0, 30, Settings.Blur, function(v)
		lib:SetBlur(v)
	end)
	obj.Speed = self:Slider("动画速度", 0.25, 3, Settings.Speed, function(v)
		lib:SetAnimSpeed(v)
	end, {Format = "%.2f"})
	obj.Sounds = self:Checkbox("点击音效", Settings.Sounds, function(v)
		lib:SetSounds(v)
	end)
	self:Separator("视觉特效")
	obj.Glass = self:Checkbox("液态玻璃", Library.FX.Glass or false, function(v)
		lib:SetGlass(v)
	end)
	obj.Ripple = self:Checkbox("点击波纹", Settings.Ripple, function(v)
		lib:SetRipple(v)
	end)
	obj.BorderFx = self:Combo("边框特效", {"无", "流光", "呼吸"}, "无", function(v)
		lib:SetBorderEffect(v)
	end)
	obj.BackdropFx = self:Combo("背景渐变", {"无", "Aurora", "Sunset", "Ocean"}, "无", function(v)
		lib:Backdrop(v)
	end)
	local particleKind = "无"
	local particleCount = TOUCH and 18 or 30
	obj.ParticleFx = self:Combo("背景粒子", {"无", "雪", "雨", "星空", "气泡", "花瓣", "萤火虫"}, "无", function(v)
		particleKind = v
		lib:Particles(v, {Count = particleCount})
	end)
	obj.ParticleCount = self:SliderInt("粒子数量", 5, 60, particleCount, function(v)
		particleCount = v
		debounce("particles", function()
			if particleKind ~= "无" then
				lib:Particles(particleKind, {Count = v})
			end
		end)
	end)
	local row = self:Row()
	row:Button("导出主题", function()
		local json = lib:ExportTheme()
		if setclipboard then
			pcall(setclipboard, json)
			lib:Notify({Title = "主题", Content = "已复制到剪贴板", Type = "Success"})
		else
			lib:Notify({Title = "主题", Content = "当前环境不支持剪贴板", Type = "Warn"})
		end
	end)
	row:Button("导入主题", function()
		lib:Prompt("导入主题", "粘贴主题内容：", "", function(text)
			if lib:ImportTheme(text or "") then
				lib:Notify({Title = "主题", Content = "已应用", Type = "Success"})
			else
				lib:Notify({Title = "主题", Content = "内容无效", Type = "Error"})
			end
		end)
	end)
	return obj
end

function Library:Palette(extra)
	local gui = self.Gui
	local vp = gui.AbsoluteSize
	if vp.X <= 0 then
		vp = Vector2.new(800, 600)
	end
	local commands = {}
	for _, w in Library.Windows do
		for _, c in w.Registry do
			table.insert(commands, c)
		end
	end
	for _, c in extra or {} do
		table.insert(commands, c)
	end
	local width = math.min(300, vp.X - 24)
	local blocker = button(gui, tok(0, 0, 0, 0.5), {Size = UDim2.fromScale(1, 1), ZIndex = 1000})
	local box = frame(blocker, T.WindowBg, {
		Size = UDim2.new(0, width, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 36),
		ZIndex = 1001,
		Active = true
	})
	stroke(box, T.Border)
	pad(box, 4, 4, 4, 4)
	list(box, 4).VerticalAlignment = Enum.VerticalAlignment.Top
	local input = new("TextBox", {
		BackgroundColor3 = T.FrameActive[1],
		BackgroundTransparency = T.FrameActive[2],
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, FH + 2),
		Font = FONT,
		TextSize = TS,
		TextColor3 = T.Text,
		PlaceholderText = "输入功能名称...",
		PlaceholderColor3 = T.TextDisabled,
		Text = "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		ZIndex = 1002
	}, box)
	pad(input, 6, 6, 0, 0)
	local results = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, FH),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = SB,
		ScrollBarImageColor3 = T.Scroll,
		LayoutOrder = 2,
		ZIndex = 1002
	}, box)
	list(results, 0).VerticalAlignment = Enum.VerticalAlignment.Top
	local matches = {}
	local function close()
		if blocker.Parent then
			blocker:Destroy()
		end
	end
	local function run(cmd)
		close()
		if cmd and cmd.Callback then
			task.spawn(cmd.Callback)
		end
	end
	local function fill()
		for _, child in results:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		matches = {}
		local terms = {}
		for term in string.gmatch(string.lower(input.Text), "%S+") do
			table.insert(terms, term)
		end
		for _, c in commands do
			local name = string.lower(c.Name)
			local ok = true
			for _, term in terms do
				if not string.find(name, term, 1, true) then
					ok = false
					break
				end
			end
			if ok then
				table.insert(matches, c)
			end
		end
		results.Size = UDim2.new(1, 0, 0, math.max(math.min(#matches, 7), 1) * FH)
		for i, c in matches do
			local normal = i == 1 and T.Header or T.Clear
			local b = button(results, normal, {
				Size = UDim2.new(1, 0, 0, FH),
				Text = c.Name,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = i,
				ZIndex = 1003
			})
			pad(b, 6, 6, 0, 0)
			bind(b, normal, T.HeaderHover, T.HeaderActive)
			label(b, c.Group or "", {
				Size = UDim2.fromScale(1, 1),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = T.TextDisabled,
				ZIndex = 1004
			})
			b.MouseButton1Click:Connect(function()
				run(c)
			end)
		end
		if #matches == 0 then
			label(results, "没有匹配的功能", {Size = UDim2.new(1, 0, 0, FH), TextColor3 = T.TextDisabled, ZIndex = 1003})
		end
	end
	input:GetPropertyChangedSignal("Text"):Connect(fill)
	input.FocusLost:Connect(function(enter)
		if enter then
			run(matches[1])
		end
	end)
	blocker.MouseButton1Click:Connect(close)
	fill()
	input:CaptureFocus()
	return {Close = close}
end

function Library:SetPaletteKey(key)
	Library.PaletteKey = key
end

function Library:SetVisible(v)
	for _, w in Library.Windows do
		w:SetVisible(v)
	end
end

function Library:Toggle()
	local any = false
	for _, w in Library.Windows do
		if w.Visible then
			any = true
		end
	end
	Library:SetVisible(not any)
end

function Library:SetToggleKey(key)
	Library.ToggleKey = key
end

function Library:Destroy()
	for _, c in Library.Conns do
		c:Disconnect()
	end
	Library.Conns = {}
	if Library.Blur then
		pcall(function()
			Library.Blur:Destroy()
		end)
		Library.Blur = nil
	end
	if Library.ClickSound then
		pcall(function()
			Library.ClickSound:Destroy()
		end)
		Library.ClickSound = nil
	end
	if Library.Gui then
		Library.Gui:Destroy()
	end
	Library.Windows = {}
	if env.__IMGUI_LIB == Library then
		env.__IMGUI_LIB = nil
	end
end

local function resolveParent()
	local ok, parent = pcall(function()
		return gethui and gethui()
	end)
	if ok and parent then
		return parent
	end
	ok, parent = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and parent then
		return parent
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local gui = new("ScreenGui", {
	Name = "ImGuiLib",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, nil)
pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
	end
end)
gui.Parent = resolveParent()
Library.Gui = gui

table.insert(Library.Conns, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	Library:Fit()
end))

table.insert(Library.Conns, UIS.InputChanged:Connect(function(input)
	if not Drag then
		return
	end
	local isMove = input.UserInputType == Enum.UserInputType.MouseMovement and Drag.Input.UserInputType == Enum.UserInputType.MouseButton1
	if input == Drag.Input or isMove then
		Drag.Fn(Vector2.new(input.Position.X, input.Position.Y))
	end
end))

table.insert(Library.Conns, UIS.InputEnded:Connect(function(input)
	if not Drag then
		return
	end
	local isRelease = input.UserInputType == Enum.UserInputType.MouseButton1 and Drag.Input.UserInputType == Enum.UserInputType.MouseButton1
	if input == Drag.Input or isRelease then
		local d = Drag
		Drag = nil
		if d.End then
			d.End()
		end
	end
end))

table.insert(Library.Conns, UIS.InputBegan:Connect(function(input, processed)
	if Library.Waiting then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			Library.Waiting.Fn(input.KeyCode)
		end
		return
	end
	if processed then
		return
	end
	if Library.ToggleKey and input.KeyCode == Library.ToggleKey then
		Library:Toggle()
		return
	end
	if Library.PaletteKey and input.KeyCode == Library.PaletteKey then
		Library:Palette()
		return
	end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	local topDlg = Library.Dialogs[#Library.Dialogs]
	if topDlg then
		if input.KeyCode == Enum.KeyCode.Escape then
			if topDlg.Cancel then
				topDlg.Cancel.Activate()
			elseif topDlg.Frame.Parent and topDlg.Closable ~= false then
				topDlg:Close("escape")
			end
			return
		elseif input.KeyCode == Enum.KeyCode.Return and topDlg.Default then
			topDlg.Default.Activate()
			return
		end
	end
	for st in Library.Binds do
		if not st.Frame.Parent then
			Library.Binds[st] = nil
		elseif st.Value and st.Value == input.KeyCode and st.OnPress then
			task.spawn(st.OnPress)
		end
	end
end))

Library.Theme = T
env.__IMGUI_LIB = Library

return Library
