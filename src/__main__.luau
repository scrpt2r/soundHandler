-- soundHandler.__main__
-- 2026-05-10

local soundHandler = {}
soundHandler.__index = soundHandler

function soundHandler.new()
    local self = setmetatable({}, soundHandler)

    return self
end

function soundHandler:destroy()

end

return soundHandler
