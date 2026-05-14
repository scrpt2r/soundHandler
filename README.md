# soundHandler

A modular audio framework built for Roblox developers.

## Structure

```
soundHandler.luau/ ← entry point
  ├─ libs ← utils/usages
  ├─ __main__.luau ← constructor
```

## Usage

```lua
local soundService = game:GetService("SoundService")
local testSound = soundService:WaitForChild("testSounds") -- SoundGroup for storing the sounds. Could be a Folder. Doesnt affect our system.

local soundHandler = require(script.Parent:WaitForChild("soundHandler")) -- require the soundHandler lib.
local testSound_ = soundHandler.new(testSound) -- our handler.

--// IMPORTANT: before setting the sounds or play them pls set the sounds attribute: named as "category", to: "sound" or "sfx".

testSound_:debug(true) -- you will activate the debug section. CLOSE IT BEFORE PUBLISHING THE GAME.

testSound_:play("test4", true, "sound") -- test4 play as looped and "sound" category. Second argument is looped control.
print(testSound_) -- prints handler: self (to check connections and queues).

task.wait(5)

testSound_:play("test2") -- test2 plays too (if the category is not given it automaticly sets looped to false and category to "sound").
print(testSound_) -- prints handler: self (to check connections and queues).

task.wait(2)

testSound_:stop("test4") -- now test4 stops.
print(testSound_) -- prints handler: self (to check connections and queues).

task.wait(5)

testSound_:stop("test2") -- now test2 stops and all clear (connections, queues).
print(testSound_) -- prints handler: self (to check connections and queues).
```

```lua
local soundService = game:GetService("SoundService")
local testSound = soundService:WaitForChild("testSounds") -- SoundGroup for storing the sounds. Could be a Folder. Doesnt affect our system.

local soundHandler = require(script.Parent:WaitForChild("soundHandler")) -- require the soundHandler lib.
local testSound_ = soundHandler.new(testSound) -- our handler.

--// IMPORTANT: before setting the sounds or play them pls set the sounds attribute: named as "category", to: "sound" or "sfx".

testSound_:debug(false) -- you will deactivate the debug section.

testSound_:play("test4") -- test4 play as un looped and "sound" category. If not given looped sets as false and category sets as "sound".
print(testSound_) -- prints handler: self (to check connections and queues).

task.wait(5)

testSound_:pause("test4") -- pauses sound so it could get resumed later. connections does not work if its paused.
print(testSound_) -- prints handler: self (to check connections and queues).

task.wait(6)

testSound_:resume("test4") -- resumes back from the paused position.
print(testSound_) -- prints handler: self (to check connections and queues).
```