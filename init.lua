local Object, private

Object  = {}
private = require(... .. ".instances")

---@see Object.init
function Object:init()
    return {
        __get = {},
        __set = {}
    }
end

---@see Object.call
function Object:call(...)
    local ins, r
    
    assert(self ~= Object, "'Object:call' is not meant to be called directly.")

	ins = setmetatable({}, self)
    
	private[ins] = {}
    
    --Avoids triggering index, which would throw an error, since we don't
    --want the dev to call new directly.
	r = self.new(ins, ...)
    
	return r or ins
end

---@see Object.index
function Object:index(key)
    local mt, result
    
    assert(key ~= "new", "You can not call the 'new' method on an instance of a class.")
    assert(self ~= Object, "'Object:index' is not meant to be called directly.")

    mt = getmetatable(self)

    --A getter supercedes a method with the same name. In general though, the
    --dev shouldn't be creating getters and methods with the same name anyways.
    --It's confusing.
    result = mt.__get[key] and mt.__get[key](self) or mt[key]

    --Special case for "type". We could create a special "getter" for just type,
    --but it runs the risk of being overwritten. However, if the dev wants to
    --create a method called "type", then we want to let them use that version.
    --We only return the __type if there's no result.
    if not result and key == "type" then
        return mt.__type or "object"
    end

    return result
end

---@see Object.create
function Object:create(...)
    local args, class
    
    args  = { ... }
    class = {
        __get         = {},
        __set         = {},
        __implemented = {},
        __index    = self.index,
        __concat   = self.concat,
        __newindex = self.newindex,
        __tostring = self.tostring,
        tostring   = self.tostring,
        implements = self.implements
    }

    assert(args[1].new, "Class is missing 'new' constructor.")
    
    class.__constructor = args[1].new

    --We wrap the new constructor in an anonymous function that places an assert at the top.
    --We need to make sure that the user doesn't circumvent the constructor process, or else
    --a bunch of stuff would go sideways without being super clear why.
    args[1].new = function(self, ...)
        assert(self ~= class, "You can not call the 'new' method directly.")

        return class.__constructor(self, ...)
    end

    for i = #args, 1, -1 do
        --All classes get placed in the __implemented table for reference later.
        class.__implemented[args[i]] = true

        --Add getters.
        for k, v in pairs(args[i].__get or {}) do
            class.__get[k] = v
        end

        --Add setters.
        for k, v in pairs(args[i].__set or {}) do
            class.__set[k] = v
        end

        --Add everything else. Skip anything that needs to be skipped.
        for k, v in pairs(args[i]) do
            if k == "__get" then goto continue end
            if k == "__set" then goto continue end

            --Special case for __type, since we make presumptions about what "__type" is.
            if k == "__type" then
                assert(type(v) == "string", "Class '__type' metavalue must be of type 'string'.")
                
                class[k] = v

            --Special case for a user defined __index. We create a function that calls the user's
            --__index first, and only calls Object's __index after, if the first one returns nil.
            elseif k == "__index" then
                function class.__index(this, key)
                    return v(this, key) or self.index(this, key)
                end
            

            --Special case for a user defined __newindex. We create a function that calls the
            --user's __newindex first, and ONLY calls Object's newindex if the user's __newindex
            --returns falsey. Basically, if the user successfully sets a value, they should return
            --true.
            elseif k == "__newindex" then
                function class.__newindex(this, key, value)
                    if not v(this, key, value) then
                        self.newindex(this, key, value)
                    end
                end
            else
                class[k] = v
            end

            ::continue::
        end
    end

    --Create the class. The class itself has it's own metatable that is totally
    --different from an instance's mt. All it needs is __call, for constructing
    --instances, and __concat and __tostring for debugging. __metatable is set to
    --Object, since thats "kinda" sorta true, although that's clearly not actually
    --true. But it lets you pretty quickly check if something is a class by checking
    --if it's metatable is Object.
    return setmetatable(class, {
        __call      = self.call,
        __concat    = self.concat,
        __tostring  = self.tostring,
        __metatable = Object
    })
end

---@see Object.concat
function Object:concat(value)
    return tostring(self) .. tostring(value) 
end

---@see Object.newindex
function Object:newindex(key, value)
    local mt = getmetatable(self)

    assert(self ~= Object, "'Object:newindex' is not meant to be called directly.")

    if mt.__set[key] then
        return mt.__set[key](self, value)
    end

    --We use rawset to avoid creating a metatable loop.
    rawset(self, key, value)
end

---@see Object.tostring
function Object:tostring(...)
    local mt, args, count, vars, t

    assert(self ~= Object, "'Object:tostring' is not meant to be called on the Object class. Instead, call it via the instance you are trying to use.")
    
    mt     = getmetatable(self)
    args   = { ... }
    count  = select("#", ...)

    --If arguments were provided, we use those. If the metatable is Object, then
    --it's a class.
    if count > 0 then
        vars = tostring(args[1])

        for i = 2, count, 1 do
            vars = vars .. ", " .. tostring(args[i])
        end
    elseif mt == Object then
        vars = "Class"
    end

    --If vars hasn't been defined, then we have no args, so we set it to an
    --empty string. Otherwise, we need to add a space in front of the args
    --for readability.
    vars = vars and (" " .. vars) or ""

    --If this is a class (and not just vars that happen to be the string "Class"),
    --then we use self.__type. If there is no self.__type, then we use a fallback.
    if mt == Object then
        t = self.__type or "object"
    
    --Since the user might create a "type" method, we instead check if self's metatable
    --has a __type, and fetch it directly. This way we can circumvent them superceding the
    --.type getter, if they end up doing that.
    elseif mt.__type then
        t = mt.__type
    
    --If no type is specified, it defaults to "object"
    else
        t = "object"
    end

    return "[<" .. t .. ">" .. vars .. "]"
end

---@see Object.implements
function Object:implements(...)
    local mt = getmetatable(self)

    assert(self ~= Object, "'Object:implements' is not meant to be called on the Object class. Instead, call it via the instance you are trying to check.")

	for _, v in ipairs({ ... }) do
        if not (mt.__implemented[v] or v == mt) then
            return false
        end
    end

    return true
end

---@type Classy.Object
local Class = setmetatable(Object, {
    __tostring = function()
        return "[<object> Class]"
    end,
    __metatable = Object
})

return Class