local Object, Symbol, private, file_path

--".Symbol" is 7 characters, so we -8 to get just the directory.
file_path = (...):sub(1, -8)

Object  = require(file_path)
private = require(file_path .. ".instances")

Symbol  = Object:init()

function Symbol:new(id)
    private[self].id = id and tostring(id) or math.uuid()
end

function Symbol.__get:id() 
    return private[self].id
end

function Symbol:__tostring()
    return Object:tostring(private[self].id)
end

Symbol.__type = "symbol"

return Object:create(Symbol)
