---@meta Classy

---@alias Classy.PreClass table A class that hasn't yet gone through the[Object:create()](lua://Classy.Object.create)
---process is a PreClass.

---A special table that has been created using Classy. Has a `__call` metamethod that
---will automatically call `new`, using itself as the `__index` for the new instance being created. You can
---verify if a class is a Classy class by checking it's metatable and comparing it to (Object)[lua://Classy.Object].
---@class Classy.Class

---The base object class, provided by the [Classy](https://github.com/jumpsplat120/Classy)
---library. Used to create Classy classes, but is not, a true class. However, it does have a circular
---reference to itself in `__metatable`, and the suggested way to check for a [Classy class](lua://Classy.Class)
---is to `getmetatable(class) == Object`, so in that sense, it *will* read as one. It does not, however, have
---any of the other features of a Classy class, and you can not create instances from it.
---@class Classy.Object
Object = {}

---Helper function that creates the table for a class. Classes can (but do not need to) contain
---getters and setters, which fall under their own `__get` and `__set` subtable. This prevents
---the need to manually type that out, and also allows for potential updates that may modify
---the initally created table.
---@return Classy.PreClass #The inital class table. Note that this is a [preclass](lua://Classy.PreClass) until it's been passed through [Object:create()](lua://Classy.Object.create).
function Object:init() end

---Takes the main class and any mixin classes and smushes them together into a [Classy](lua://Classy.Class).
---This function *must* be called before returning from a class file, since it's what turns a table into
---an actual Classy class.
---
---Mixins passed in are parsed FILO, and will overwrite each other. This includes the first class passed in,
---so be aware if your main class shares a method name with a mixin's method. You can always call a mixin by
---using the Class and passing in `self`.
---@param ... Classy.PreClass One or more [preclasses](lua://Classy.PreClass). The first one is treated as the "main" class, and will be the one that is used when `__call`ing. The first preclass needs at minimum a `new` method to be turned into a true class.
---@return Classy.Class
function Object:create(...) end

---Used as the `__call` metamethod for [Classy classes](lua://Classy.Class). Will set the metatable of the new
---instance, and place a reference into [private](lua://Classy.private). Finally, will call `new` on the class,
---and return either the reference to the instance, or whatever was returned from `new`.
---
---This is not meant to be called directly, and will error if done so.
---@private
---@param ... any All parameters are passed through to the `new` method of the class the instance is being created from.
---@return any #While usually a class instance, if the `new` method returns a value, that will be returned instead.
function Object:call(...) end

---Used as the `__index` metamethod for [Classy classes](lua://Classy.Class). Handles getters and contains
---special logic for `type`, which reads from the `__type` metaproperty, acting like a getter, but allowing
---the user to supersede it, if they so desire. Will also prevent the user from calling `new` from an instance
---of a class, erroring if attempted.
---
---This is not meant to be called directly, and will error if done so.
---@private
---@param key any
---@return any
function Object:index(key) end

---Used as the `__concat` metamethod for [Classy classes](lua://Classy.Class). Simply attempts to tostring
---both values and concatenate them together.
---
---This is not meant to be called directly, and will error if done so.
---@private
---@param value any
---@return string
function Object:concat(value) end

---Used as the `__newindex` metamethod for [Classy classes](lua://Classy.Class). Handles setter logic.
---
---This is not meant to be called directly, and will error if done so.
---@private
---@param key any
---@param value any
function Object:newindex(key, value) end

---Used as the `__tostring` metamethod for [Classy classes](lua://Classy.Class), but also used as a helper
---method for turning an object into a string. Any values can be passed in, and they will be joined
---with commas next to the `__type` of the object in a specific format. Common usage is to use
---`self:tostring()` inside `MyClass:__tostring()`, passing in whatever values would be most appropriate for
---that class (such as the x, y, width, and height of a rectangle, for example).
---
---If the class itself calls tostring, it will instead ignore all parameters passed in, and use "Class" in
---their place.
---
---Attempts to use the `__type` metaproperty of the class, but if one does not exist, will use "object" as
---a fallback.
---
---This will error if called on Object.
---@param ... any All values passed in will be `tostring`ed.
---@return string #The output will have the format `[<instance_type> foo, bar, baz]`, angle brackets included.
function Object:tostring(...) end

---Classy does not use inheritance, but instead uses composition. Any class instance can be checked to see what
---classes/mixins it implements, which can be helpful when attempting to filter out objects that may or may not
---have the functionality you desire. Will return true only if all classes have been implemented.
---
---This will error if called on Object.
---@param ... Classy.Class
---@return boolean
function Object:implements(...) end