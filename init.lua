local Object, private

Object  = {}
private = require(... .. ".instances")

--Helper function that creates the table for an object.
function Object:init()
    return {
        __get = {},
        __set = {}
    }
end

--What is used internally when creating an object instance. This creates the
--private table, creates the actual instance, as well as handles non traditional
--return values.
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

--Is called when the key doesn't exist on the table. 99% of the time that will be
--a reference to one of the class instance's methods.
function Object:index(key)
    local mt, result

    assert(key ~= "new", "Calling the 'new' constructor directly is invalid. Instead, call the class directly.")
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

--Quick solution for concating two objects. Often that's really all we want, is just
--"hey, join A and B, and if they're not strings, make them."
function Object:concat(value)
    return tostring(self) .. tostring(value) 
end

--Called anytime a new value is set on a table. Easier than index; either uses an
--existing setter or sets the value onto the actual table.
function Object:newindex(key, value)
    local mt = getmetatable(self)

    assert(self ~= Object, "'Object:newindex' is not meant to be called directly.")

    if mt.__set[key] then
        return mt.__set[key](self, value)
    end

    --We use rawset to avoid creating a metatable loop.
    rawset(self, key, value)
end

--Both used as the metatable tostring method, and as the "stringhelper" function.
--If arguments are passed, converts them into the "standardized" version. Both used
--as the __tostring metamethod, and exposed as an actual method which can be accessed
--on any object.
function Object:tostring(...)
    local args, count, vars
    
    args   = { ... }
    count  = select("#", ...)

    --If arguments were provided, we use those. If the metatable is Object, then
    --it's a class.
    if count > 0 then
        vars = tostring(args[1])

        for i = 2, count, 1 do
            vars = vars .. ", " .. tostring(args[i])
        end
    elseif getmetatable(self) == Object then
        vars = "Class"
    end

    --If vars hasn't been defined, then we have no args, so we set it to an
    --empty string. Otherwise, we need to add a space in front of the args
    --for readability.
    vars = vars and (" " .. vars) or ""

    return "[<" .. (self.type or "object") .. ">" .. vars .. "]"
end

--Returns true if an instance implements all of the provided classes. One of two
--method that any classes actually "inherit", the way a traditional class lib works.
function Object:implements(...)
    local mt = getmetatable(self)

	for _, v in ipairs({ ... }) do
        if not mt.__implemented[v] then
            return false
        end
    end

    return true
end

--Takes classes and smushes them together into a Class. This is what's
--used when returning the class from it's file.
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

    for i = 1, #args, 1 do
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

        --Add everything else.
        for k, v in pairs(args[i]) do
            if k == "__get" then goto continue end
            if k == "__set" then goto continue end
            
            class[k] = v

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

return Object