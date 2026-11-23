local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

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
	obj.Parent = parent
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
		Thickness = thickness or 1,
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

local function bind(btn, normal, hover, press)
	local over, down = false, false
	local st = {Normal = normal, Hover = hover, Press = press}
	local function refresh()
		if down then
			paint(btn, st.Press)
		elseif over and not TOUCH then
			paint(btn, st.Hover)
		else
			paint(btn, st.Normal)
		end
	end
	btn.MouseEnter:Connect(function()
		over = true
		refresh()
	end)
	btn.MouseLeave:Connect(function()
		over = false
		down = false
		refresh()
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
	return st
end

local function colorTokens(c)
	return {c, 0}, {c:Lerp(Color3.new(1, 1, 1), 0.15), 0}, {c:Lerp(Color3.new(1, 1, 1), 0.3), 0}
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local Library = {Windows = {}, Conns = {}, TopZ = 1}
Library.__index = Library

local Container = {}
Container.__index = Container

local Window = {}
Window.__index = Window
setmetatable(Window, {__index = Container})

local Drag

local function beginDrag(input, fn, onEnd)
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
	return makeContainer(self.Win, f, inline), f
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
	label(hit, str, {Size = UDim2.new(0, textWidth(str) + 4, 1, 0), LayoutOrder = 2})
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
	local iw = win.ItemWidth
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
	local iw = win.ItemWidth
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
	function obj:Set(v)
		box.Text = tostring(v)
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
	local iw = win.ItemWidth
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

function Container:Combo(name, items, default, callback)
	local win = self.Win
	local row = self:_row(FH, true)
	local iw = win.ItemWidth
	local state = {Value = nil, Items = items}
	if type(default) == "number" then
		state.Value = items[default]
	else
		state.Value = default or items[1]
	end
	local box = button(row, T.Frame, {
		Size = UDim2.new(iw, -4, 1, 0),
		Text = tostring(state.Value or ""),
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true
	})
	pad(box, 4, FH, 0, 0)
	local arrowBox = frame(box, T.Button, {Size = UDim2.fromOffset(FH, FH), Position = UDim2.new(1, 0, 0, 0)})
	icon(arrowBox, "Right", {Size = UDim2.fromOffset(FH - 8, FH - 8), Position = UDim2.fromOffset(4, 4), Rotation = 90})
	label(row, name, {Size = UDim2.new(1 - iw, -4, 1, 0), Position = UDim2.new(iw, 4, 0, 0)})
	bind(box, T.Frame, T.FrameHover, T.FrameActive)
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
		local entries = state.Items
		local visible = math.min(#entries, 7)
		local height = visible * FH + 4
		win:_popup(box, box.AbsoluteSize.X / win.Scale, height, function(pop)
			local scroll = new("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 5,
				ScrollBarImageColor3 = T.Scroll
			}, pop)
			pad(scroll, 2, 2, 2, 2)
			list(scroll, 0).VerticalAlignment = Enum.VerticalAlignment.Top
			for i, item in entries do
				popupItem(scroll, tostring(item), item == state.Value, i, function()
					win:_closePopup()
					state.Set(item, true)
				end)
			end
		end)
	end)
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
		ScrollBarThickness = 5,
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
	local iw = win.ItemWidth
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
	local iw = win.ItemWidth
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
		local width = math.max(swatch.AbsoluteSize.X / win.Scale, 180)
		win:_popup(swatch, width, FH * 4 + 8 + 12, function(pop)
			pad(pop, 4, 4, 4, 4)
			local sliders = {}
			local names = {"R", "G", "B"}
			local keys = {"R", "G", "B"}
			local function push()
				state.Set(Color3.fromRGB(sliders[1].Value, sliders[2].Value, sliders[3].Value), true)
			end
			for i = 1, 3 do
				local track = new("TextButton", {
					BackgroundColor3 = T.Frame[1],
					BackgroundTransparency = T.Frame[2],
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					Size = UDim2.new(1, 0, 0, FH),
					Position = UDim2.fromOffset(0, (i - 1) * (FH + 2))
				}, pop)
				sliders[i] = makeSlider(win, track, {
					Min = 0,
					Max = 255,
					Int = true,
					Format = names[i] .. " %d",
					Value = math.floor(state.Value[keys[i]] * 255 + 0.5),
					OnChange = push
				})
			end
			local input = new("TextBox", {
				BackgroundColor3 = T.Frame[1],
				BackgroundTransparency = T.Frame[2],
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, FH),
				Position = UDim2.fromOffset(0, 3 * (FH + 2)),
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
					sliders[1].Set(math.floor(c.R * 255 + 0.5))
					sliders[2].Set(math.floor(c.G * 255 + 0.5))
					sliders[3].Set(math.floor(c.B * 255 + 0.5))
				end
			end)
		end)
	end)
	render()
	state.Frame = row
	return state
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
		arrow.Rotation = sub.Open and 90 or 0
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
		arrow.Rotation = sub.Open and 90 or 0
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

function Window:_layout()
	local top = FH + (self.MenuH or 0)
	self.Body.Position = UDim2.fromOffset(0, top)
	self.Body.Size = UDim2.new(1, 0, 1, -top)
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

function Window:SetVisible(v)
	self.Visible = v and true or false
	self.Frame.Visible = self.Visible
	if not self.Visible then
		self:_closePopup()
	end
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
	self.Collapsed = v and true or false
	self:_closePopup()
	self.Body.Visible = not self.Collapsed
	self.Grip.Visible = not self.Collapsed and self.Resizable
	if self.MenuBar_ then
		self.MenuBar_.Visible = not self.Collapsed
	end
	self.Arrow.Rotation = self.Collapsed and 0 or 90
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
		Resizable = o.Resizable ~= false,
		MenuH = 0,
		_n = 0
	}, Window)
	win.Win = win

	local f = frame(gui, T.WindowBg, {
		Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(size.X, size.Y),
		Name = o.Title or "Window"
	})
	new("UIScale", {Scale = scale}, f)
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
	close.Visible = o.Closable ~= false
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
		ScrollBarThickness = 6,
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
			if not moved then
				return
			end
			local view = gui.AbsoluteSize
			local x = clamp(origin.X + d.X, -(f.AbsoluteSize.X - 50), view.X - 50)
			local y = clamp(origin.Y + d.Y, 0, view.Y - FH * scale)
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
			local d = (p - start) / scale
			local view = gui.AbsoluteSize
			local maxX = (view.X - f.AbsolutePosition.X) / scale
			local maxY = (view.Y - f.AbsolutePosition.Y) / scale
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
	return win
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
	if processed or not Library.ToggleKey then
		return
	end
	if input.KeyCode == Library.ToggleKey then
		Library:Toggle()
	end
end))

Library.Theme = T
env.__IMGUI_LIB = Library

return Library
