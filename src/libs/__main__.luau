--// Services
local contentProvider = game:GetService("ContentProvider")
local players = game:GetService("Players")
local runService = game:GetService("RunService")

--// Libs
local libs = script.Parent
local _global = libs:WaitForChild("global")

--// Variables
local player = players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// Lib Decleration
local soundHandler = {}
soundHandler.__index = soundHandler

--// Lib Private Functions
function loadFrom(from: Folder | SoundGroup): { [string]: Sound }
	local finalTable = {}
	local assetsToLoad = {}

	for _, v in from:GetDescendants() do
		if not v:IsA("Sound") then
			continue
		end

		table.insert(assetsToLoad, v)

		local type_ = v:GetAttribute("category") :: string

		if not type_ then
			type_ = "sound"
		end

		finalTable[type_] = finalTable[type_] or {}
		finalTable[type_][v.Name] = v
	end

	task.spawn(function()
		contentProvider:PreloadAsync(assetsToLoad)
	end)

	return finalTable
end

local function formatTime(t: number): string
	local minutes = math.floor(t / 60)
	local seconds = t % 60
	return string.format("%d:%05.2f", minutes, seconds)
end

--// Lib Public Funcitons
function soundHandler.new(sounds: Folder)
	if not sounds then
		warn("Sound Handler:", "There should be a Folder or a SoundGroup to get path to sounds.")
		return
	end

	local self = setmetatable({
		_playQueue = {},
		_resumeQueue = {},

		_sounds = {},
		_connections = {},
		_debugConnections = {},
		_debugEntries = {},

		_debugEnabled = false,

		_debugGui = nil,
		_debugStatsLabel = nil,
		_debugScroll = nil,
	}, soundHandler)

	self._sounds = loadFrom(sounds)

	return self
end

function soundHandler:play(sound: string, looped: boolean?, type_: "sound" | "sfx")
	if not sound then
		warn("Sound Handler:", "Handler needs a 1st argument", '"' .. "sound" .. '"', "typeof: string")
		return
	end

	if not type_ then
		type_ = "sound"
	end

	if not self._sounds[type_][sound] then
		warn(
			"Sound Handler:",
			"There is no",
			type_,
			"in cache called:",
			'"' .. sound .. '".',
			"Or the given type is not relevant to the",
			'"' .. sound .. '".',
			"audios type."
		)
		return
	end

	if self._resumeQueue[sound] then
		warn("Sound Handler:", "The", '"' .. sound .. '"', type_, "is paused already. Call: self:resume() to play it.")
		return
	end

	local sound_ = self._sounds[type_][sound] :: Sound
	self._playQueue[sound] = sound_

	if sound_.Looped or looped then
		sound_.Looped = true
	end

	if self._connections[sound] then
		self._connections[sound]:Disconnect()
		self._connections[sound] = nil
	end

	sound_:Play()

	if sound_.Looped then
		self:_refreshDebugUI()
		return
	end

	self._connections[sound] = sound_.Ended:Connect(function(soundId)
		self:stop(sound, type_)
	end)

	self:_refreshDebugUI()
end

function soundHandler:stop(sound: string, type_: "sound" | "sfx")
	if not sound then
		warn("Sound Handler:", "Handler needs a 1st argument", '"' .. "sound" .. '"', "typeof: string")
		return
	end

	if not type_ then
		type_ = "sound"
	end

	if not self._sounds[type_][sound] then
		warn(
			"Sound Handler:",
			"There is no",
			type_,
			"in cache called:",
			'"' .. sound .. '".',
			"Or the given type is not relevant to the",
			'"' .. sound .. '".',
			"audios type."
		)
		return
	end

	if self._resumeQueue[sound] then
		warn("Sound Handler:", "The", '"' .. sound .. '"', type_, "is paused already. Call: self:resume() to play it.")
		return
	end

	if not self._playQueue[sound] then
		warn("Sound Handler:", "The", '"' .. sound .. '"', type_, "has already stopped playing or never played before.")
		return
	end

	if self._connections[sound] then
		self._connections[sound]:Disconnect()
		self._connections[sound] = nil
	end

	self._playQueue[sound]:Stop()
	self._playQueue[sound] = nil

	self:_refreshDebugUI()
end

function soundHandler:pause(sound: string, type_: "sound" | "sfx")
	if not sound then
		warn("Sound Handler:", "Handler needs a 1st argument", '"' .. "sound" .. '"', "typeof: string")
		return
	end

	if not type_ then
		type_ = "sound"
	end

	if not self._sounds[type_][sound] then
		warn(
			"Sound Handler:",
			"There is no",
			type_,
			"in cache called:",
			'"' .. sound .. '".',
			"Or the given type is not relevant to the",
			'"' .. sound .. '".',
			"audios type."
		)
		return
	end

	if not self._playQueue[sound] then
		warn("Sound Handler:", "The", '"' .. sound .. '"', type_, "has already stopped playing or never played before.")
		return
	end

	if self._resumeQueue[sound] then
		warn("Sound Handler:", "The", '"' .. sound .. '"', type_, "has already paused playing or never played before.")
		return
	end

	local sound_ = self._sounds[type_][sound] :: Sound
	self._resumeQueue[sound] = sound_
	self._playQueue[sound] = nil

	sound_:Pause()

	self:_refreshDebugUI()
end

function soundHandler:resume(sound: string, type_: "sound" | "sfx")
	if not sound then
		warn("Sound Handler:", "Handler needs a 1st argument", '"' .. "sound" .. '"', "typeof: string")
		return
	end

	if not type_ then
		type_ = "sound"
	end

	if not self._sounds[type_][sound] then
		warn(
			"Sound Handler:",
			"There is no",
			type_,
			"in cache called:",
			'"' .. sound .. '".',
			"Or the given type is not relevant to the",
			'"' .. sound .. '".',
			"audios type."
		)
		return
	end

	if not self._resumeQueue[sound] then
		warn("Sound Handler:", "The", '"' .. sound .. '"', type_, "has already resumed playing or never played before.")
		return
	end

	local sound_ = self._sounds[type_][sound] :: Sound
	self._playQueue[sound] = sound_
	self._resumeQueue[sound] = nil

	sound_:Resume()

	self:_refreshDebugUI()
end

function soundHandler:debug(enabled: boolean)
	if not enabled then
		self._debugEnabled = false

		for key, conn in self._debugConnections do
			conn:Disconnect()
		end
		table.clear(self._debugConnections)
		table.clear(self._debugEntries)

		if self._debugGui then
			self._debugGui:Destroy()
			self._debugGui = nil
		end

		self._debugStatsLabel = nil
		self._debugScroll = nil
		return
	end

	self._debugEnabled = true

	if self._debugGui then
		self._debugGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SoundHandlerDebug"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 999
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui
	self._debugGui = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 300, 0, 460)
	panel.Position = UDim2.new(0, 12, 0, 12)
	panel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 90)
	stroke.Thickness = 1
	stroke.Parent = panel

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 38)
	header.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
	header.BorderSizePixel = 0
	header.ZIndex = 2
	header.Parent = panel

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 10)
	headerCorner.Parent = header

	local headerPatch = Instance.new("Frame")
	headerPatch.Size = UDim2.new(1, 0, 0, 10)
	headerPatch.Position = UDim2.new(0, 0, 1, -10)
	headerPatch.BackgroundColor3 = Color3.fromRGB(22, 22, 34)
	headerPatch.BorderSizePixel = 0
	headerPatch.ZIndex = 2
	headerPatch.Parent = header

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 8, 0, 8)
	dot.Position = UDim2.new(0, 12, 0.5, -4)
	dot.BackgroundColor3 = Color3.fromRGB(100, 220, 130)
	dot.BorderSizePixel = 0
	dot.ZIndex = 3
	dot.Parent = header

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = "SOUND HANDLER  —  DEBUG"
	titleLabel.Size = UDim2.new(1, -30, 1, 0)
	titleLabel.Position = UDim2.new(0, 28, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(200, 200, 230)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 12
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 3
	titleLabel.Parent = header

	local statsBar = Instance.new("Frame")
	statsBar.Size = UDim2.new(1, 0, 0, 26)
	statsBar.Position = UDim2.new(0, 0, 0, 38)
	statsBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	statsBar.BorderSizePixel = 0
	statsBar.Parent = panel

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -16, 1, 0)
	statsLabel.Position = UDim2.new(0, 10, 0, 0)
	statsLabel.BackgroundTransparency = 1
	statsLabel.TextColor3 = Color3.fromRGB(100, 100, 130)
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextSize = 10
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Text = "Playing: 0  |  Paused: 0  |  Connections: 0"
	statsLabel.Parent = statsBar
	self._debugStatsLabel = statsLabel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, -14, 1, -74)
	scroll.Position = UDim2.new(0, 7, 0, 68)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = panel
	self._debugScroll = scroll

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = scroll

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "_empty"
	emptyLabel.Size = UDim2.new(1, 0, 0, 40)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
	emptyLabel.Font = Enum.Font.Gotham
	emptyLabel.TextSize = 11
	emptyLabel.Text = "No sounds active."
	emptyLabel.Parent = scroll

	self._debugConnections["__heartbeat"] = runService.Heartbeat:Connect(function()
		self:_updateDebugBars()
	end)

	self:_refreshDebugUI()
end

function soundHandler:_refreshDebugUI()
	if not self._debugEnabled or not self._debugGui then
		return
	end

	local allSounds: { [string]: "playing" | "paused" } = {}

	for name in self._playQueue do
		allSounds[name] = "playing"
	end
	for name in self._resumeQueue do
		allSounds[name] = "paused"
	end

	for name, entry in self._debugEntries do
		if not allSounds[name] then
			entry.frame:Destroy()
			self._debugEntries[name] = nil

			if self._debugConnections[name] then
				self._debugConnections[name]:Disconnect()
				self._debugConnections[name] = nil
			end
		end
	end

	for name, state in allSounds do
		if not self._debugEntries[name] then
			self:_createDebugEntry(name, state)
		else
			self:_updateDebugEntryState(name, state)
		end
	end

	local scroll = self._debugScroll
	if scroll then
		local emptyLabel = scroll:FindFirstChild("_empty")
		if emptyLabel then
			emptyLabel.Visible = next(allSounds) == nil
		end
	end

	self:_updateDebugStats()
end

function soundHandler:_createDebugEntry(name: string, state: "playing" | "paused")
	local soundObj = self._playQueue[name] or self._resumeQueue[name]
	if not soundObj then
		return
	end

	local isPlaying = state == "playing"
	local accentColor = isPlaying and Color3.fromRGB(80, 220, 130) or Color3.fromRGB(220, 180, 70)

	local entry = Instance.new("Frame")
	entry.Name = name
	entry.Size = UDim2.new(1, 0, 0, 62)
	entry.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	entry.BorderSizePixel = 0
	entry.Parent = self._debugScroll

	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 7)
	entryCorner.Parent = entry

	local entryStroke = Instance.new("UIStroke")
	entryStroke.Color = Color3.fromRGB(35, 35, 55)
	entryStroke.Thickness = 1
	entryStroke.Name = "EntryStroke"
	entryStroke.Parent = entry

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 3, 0.7, 0)
	accentBar.Position = UDim2.new(0, 0, 0.15, 0)
	accentBar.BackgroundColor3 = accentColor
	accentBar.BorderSizePixel = 0
	accentBar.Parent = entry

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1, 0)
	accentCorner.Parent = accentBar

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -70, 0, 16)
	nameLabel.Position = UDim2.new(0, 12, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = name
	nameLabel.Parent = entry

	local stateBadge = Instance.new("TextLabel")
	stateBadge.Name = "StateBadge"
	stateBadge.Size = UDim2.new(0, 58, 0, 16)
	stateBadge.Position = UDim2.new(1, -63, 0, 8)
	stateBadge.BackgroundTransparency = 1
	stateBadge.TextColor3 = accentColor
	stateBadge.Font = Enum.Font.GothamBold
	stateBadge.TextSize = 10
	stateBadge.TextXAlignment = Enum.TextXAlignment.Right
	stateBadge.Text = isPlaying and "▶  PLAYING" or "⏸  PAUSED"
	stateBadge.Parent = entry

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, -16, 0, 12)
	timeLabel.Position = UDim2.new(0, 12, 0, 26)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.fromRGB(90, 90, 115)
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextSize = 10
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Text = "0:00.00 / 0:00.00"
	timeLabel.Parent = entry

	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -20, 0, 5)
	progressBg.Position = UDim2.new(0, 10, 0, 48)
	progressBg.BackgroundColor3 = Color3.fromRGB(38, 38, 55)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = entry

	local progressBgCorner = Instance.new("UICorner")
	progressBgCorner.CornerRadius = UDim.new(1, 0)
	progressBgCorner.Parent = progressBg

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = accentColor
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	local loopLabel = Instance.new("TextLabel")
	loopLabel.Name = "LoopLabel"
	loopLabel.Size = UDim2.new(0, 30, 0, 12)
	loopLabel.Position = UDim2.new(1, -35, 0, 26)
	loopLabel.BackgroundTransparency = 1
	loopLabel.TextColor3 = Color3.fromRGB(80, 150, 220)
	loopLabel.Font = Enum.Font.GothamBold
	loopLabel.TextSize = 9
	loopLabel.TextXAlignment = Enum.TextXAlignment.Right
	loopLabel.Text = "↻ LOOP"
	loopLabel.Visible = soundObj.Looped
	loopLabel.Parent = entry

	self._debugEntries[name] = {
		frame = entry,
		accentBar = accentBar,
		stateBadge = stateBadge,
		timeLabel = timeLabel,
		progressFill = progressFill,
		loopLabel = loopLabel,
		entryStroke = entryStroke,
	}
end

function soundHandler:_updateDebugEntryState(name: string, state: "playing" | "paused")
	local entry = self._debugEntries[name]
	if not entry then
		return
	end

	local soundObj = self._playQueue[name] or self._resumeQueue[name]
	local isPlaying = state == "playing"
	local accentColor = isPlaying and Color3.fromRGB(80, 220, 130) or Color3.fromRGB(220, 180, 70)

	entry.accentBar.BackgroundColor3 = accentColor
	entry.stateBadge.TextColor3 = accentColor
	entry.stateBadge.Text = isPlaying and "▶  PLAYING" or "⏸  PAUSED"
	entry.progressFill.BackgroundColor3 = accentColor

	if soundObj then
		entry.loopLabel.Visible = soundObj.Looped
	end
end

function soundHandler:_updateDebugBars()
	if not self._debugEnabled then
		return
	end

	for name, entry in self._debugEntries do
		local soundObj = self._playQueue[name] or self._resumeQueue[name]
		if not soundObj then
			continue
		end

		local timePos = soundObj.TimePosition
		local timeLen = soundObj.TimeLength

		local progress = (timeLen > 0) and math.clamp(timePos / timeLen, 0, 1) or 0
		entry.progressFill.Size = UDim2.new(progress, 0, 1, 0)

		if timeLen > 0 then
			entry.timeLabel.Text = formatTime(timePos) .. " / " .. formatTime(timeLen)
		else
			entry.timeLabel.Text = formatTime(timePos) .. " / --:--"
		end
	end

	self:_updateDebugStats()
end

function soundHandler:_updateDebugStats()
	if not self._debugStatsLabel then
		return
	end

	local playCount, pauseCount, connCount = 0, 0, 0

	for _ in self._playQueue do
		playCount += 1
	end
	for _ in self._resumeQueue do
		pauseCount += 1
	end
	for key in self._connections do
		if key ~= "__heartbeat" then
			connCount += 1
		end
	end

	self._debugStatsLabel.Text =
		string.format("Playing: %d  |  Paused: %d  |  Connections: %d", playCount, pauseCount, connCount)
end

return soundHandler
