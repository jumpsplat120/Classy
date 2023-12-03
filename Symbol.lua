local Object, Symbol, private, file_path

--".Symbol" is 7 characters, so we -8 to get just
--the directory.
file_path = (...):sub(1, -8)

private = require(file_path .. ".instances")
Object  = require(file_path)

Symbol = Object:extend()

function Symbol:new(id)
    private[self].id = id and tostring(id) or math.uuid()
end

function Symbol.__get:id() 
    return private[self].id
end

function Symbol:__tostring()
    if self.is_instance then return self:tostringHelper(private[self].id) end

    return self:tostringHelper("Class")
end

Symbol.__type = "symbol"

return Symbol
