# soundHandler

A modular audio framework built for Roblox developers.

## Please Read
This version of this module does not support looped sounds. It will be integrated in future versions.

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

testSound_:play("test4", "sound") -- test4 play as "sound" category.
print(testSound_) -- prints handler: self (to check threads and queues).

task.wait(5)

testSound_:play("test2") -- test2 plays too (if the category is not given it automaticly sets to "sound" category).
print(testSound_) -- prints handler: self (to check threads and queues).

task.wait(2)

testSound_:stop("test4") -- now test4 stops.
print(testSound_) -- prints handler: self (to check threads and queues).

task.wait(5)

testSound_:stop("test2") -- now test2 stops and all clear (threads, queues).
print(testSound_) -- prints handler: self (to check threads and queues).
```

```lua
local soundService = game:GetService("SoundService")
local testSound = soundService:WaitForChild("testSounds") -- SoundGroup for storing the sounds. Could be a Folder. Doesnt affect our system.

local soundHandler = require(script.Parent:WaitForChild("soundHandler")) -- require the soundHandler lib.
local testSound_ = soundHandler.new(testSound) -- our handler.

--// IMPORTANT: before setting the sounds or play them pls set the sounds attribute: named as "category", to: "sound" or "sfx".

testSound_:play("test4") -- test4 play as "sound" category.
print(testSound_) -- prints handler: self (to check threads and queues).

task.wait(5)

testSound_:pause("test4") -- pauses sound so it could get resumed later. threads does not work if its paused.
print(testSound_) -- prints handler: self (to check threads and queues).

task.wait(6)

testSound_:resume("test4") -- resumes back from the paused position.
print(testSound_) -- prints handler: self (to check threads and queues).
```