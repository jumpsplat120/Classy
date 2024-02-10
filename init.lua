local Object, private, index, newindex, varargs

Object  = {}
private = require(... .. ".instances")
varargs = require("lib.varargs")

--In index/newindex, we `while true do` because
--for newindex, we want to avoid the back and forth
--between index/newindex, and in index, we want to
--make sure we're passing the right `self` along. So,
--in a case like the following example...
--```lua
--function A:new(x, y)
--  private[self].values = { x, y }
--end
--
--function A.__get:x()
--  return private[self].values[1]
--end
--
--B = A:extend()
--
--function B.__get:y()
--  return private[self].values[2]
--end
--
--obj = B(1, 2)
--print(obj.x, obj.y)
--```
--what would happen if we just indexed all the way
--down the chain, is that obj.y would work, because
--we'd be passing `self`, but obj.x wouldn't, because
--`self` would be `getmetatable(self)`. Also, to avoid
--having to search the mt chain twice, we check both
--the getters and the raw at the same time. So if `B.x`
--existed, and `A.__get:x` existed, we'd get `B.x` since
--it's higher in the chain.
function index(self, key)
    local mt, get, raw

    mt = getmetatable(self)
    
    while mt do
        get = rawget(rawget(mt, "__get"), key)
        raw = rawget(mt, key)

        if get then return get(self) end
        if raw then return raw       end

        mt = getmetatable(mt)
    end
end

function newindex(self, key, value)
    local mt, set

    mt = getmetatable(self)
    
    while mt do
        set = rawget(rawget(mt, "__set"), key)

        if set then return set(self, value) end

        mt = getmetatable(mt)
    end

    rawset(self, key, value)
end

Object.__index    = index
Object.__newindex = newindex

Object.__get = {}
Object.__set = {}

function Object:__call(...)
    local ins, r
    
	ins = setmetatable({}, self)
    
	private[ins] = { instance = true }
    
	r = ins:new(...)
    
	return r or ins
end

function Object:extend()
    local class = {}

    for k, v in pairs(self) do
		if k:sub(1, 2) == "__" then class[k] = v end
	end

    class.__get = {}
    class.__set = {}

    return setmetatable(class, self)
end

function Object:implement(...)
    local implemented

    if not rawget(self, "__implemented") then rawset(self, "__implemented", {}) end

    implemented = rawget(self, "__implemented")

	for i, class in pairs({...}) do
        rawset(implemented, i, class)
		
        table.map(class, function(k, v)
			if k == "__get" or k == "__set" then
				local tbl = rawget(self, k)

				for kk, vv in pairs(v) do rawset(tbl, kk, vv) end

				return k, v
			end
			
            if k == "__newindex" then return k, v end
            if k == "__index"    then return k, v end
            if rawget(self, k)   then return k, v end

            rawset(self, k, v)
            
            return k, v
        end)
	end
end

function Object:implements(class)
	local mt = getmetatable(self)

	while mt do
		for _, implemented in ipairs(rawget(mt, "__implemented") or {}) do
			if class == implemented then return true end
		end

		mt = getmetatable(mt)
	end

	return false
end

function Object:is(class)
    local mt, cmt
	
    mt  = getmetatable(self)
	cmt = getmetatable(class)
	
	while mt do
		if mt == cmt then return true end

		mt = getmetatable(mt)
	end

	return false
end

function Object:tostringHelper(...)
    local args = ""

    for i, v in varargs(...) do
        if i == 1 then
            args = tostring(v)
        else
            args = args .. ", " .. tostring(v)
        end
    end

    args = args ~= "" and " " .. args or args
    
	return "[<" .. self.type .. ">" .. args .. "]"
end

function Object:__tostring()
	if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

function Object:__concat(value)
	return tostring(self) .. tostring(value)
end

function Object.__get:type()
    return getmetatable(self).__type
end

function Object.__get:is_instance()
    local p = private[self]

    if p then return p.instance end
    
	return false
end

Object.__type = "object"

return Object
