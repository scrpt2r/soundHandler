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
local testSound = soundService:WaitForChild("testSounds") -- SoundGroup for storing the sounds

local soundHandler = require(script.Parent:WaitForChild("soundHandler")) -- require the soundHandler lib
local testSound_ = soundHandler.new(testSound) -- our handler

testSound_:play("test4") -- test4 play
print(testSound_) -- prints handler: self (to check threads and queues)

task.wait(5)

testSound_:play("test2") -- test2 plays too
print(testSound_) -- prints handler: self (to check threads and queues)

task.wait(2)

testSound_:stop("test4") -- now test4 stops
print(testSound_) -- prints handler: self (to check threads and queues)

task.wait(5)

testSound_:stop("test2") -- now test2 stops and all clear (threads, queues)
print(testSound_) -- prints handler: self (to check threads and queues)
```
