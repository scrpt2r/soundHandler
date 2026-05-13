--// Services
local contentProvider = game:GetService("ContentProvider")

--// Libs
local libs = script.Parent
local _global = libs:WaitForChild("global")

--// Lib Decleration
local soundHandler = {}
soundHandler.__index = soundHandler

--// Lib Private Functions
function loadFrom(from: Folder | SoundGroup)
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
		_removeThreads = {},
	}, soundHandler)

	self._sounds = loadFrom(sounds)

	return self
end

function soundHandler:play(sound: string, type_: "sound" | "sfx")
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

	if self._removeThreads[sound] then
		task.cancel(self._removeThreads[sound])
		self._removeThreads[sound] = nil
	end

	if self._resumeQueue[sound] then
		warn("Sound Handler:", "The", '"' .. sound .. '"', type_, "is paused already. Call: self:resume() to play it.")
		return
	end

	local sound_ = self._sounds[type_][sound] :: Sound
	self._playQueue[sound] = sound_

	if sound_.TimeLength == 0 then
		sound_:GetPropertyChangedSignal("TimeLength"):Wait()
	end

	sound_:Play()

	self._removeThreads[sound] = task.delay(sound_.TimeLength, function()
		self._removeThreads[sound] = nil
		self:stop(sound, type_)
	end)
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

	if self._removeThreads[sound] then
		task.cancel(self._removeThreads[sound])
		self._removeThreads[sound] = nil
	end

	self._playQueue[sound]:Stop()
	self._playQueue[sound] = nil
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

	if self._removeThreads[sound] then
		task.cancel(self._removeThreads[sound])
		self._removeThreads[sound] = nil
	end

	local sound_ = self._sounds[type_][sound] :: Sound
	self._resumeQueue[sound] = sound_
	self._playQueue[sound] = nil

	sound_:Pause()
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

	local finalTime = sound_.TimeLength - sound_.TimePosition
	self._removeThreads[sound] = task.delay(finalTime, function()
		self._removeThreads[sound] = nil
		self:stop(sound, type_)
	end)
end

return soundHandler
