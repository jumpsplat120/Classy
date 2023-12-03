# Classy

Pure Lua classes.

A library that started as a forked version of [Classic](https://github.com/rxi/classic) by rxi, it spun off into it's own project after many internal changes and additions. This class library contains functionality for getters and setters, and uses a scoped table for private variables.

## Usage

Simply drop the folder into any project you'd like, and start making classes!
```lua
---Dog.lua
local Object = require("Classy")

local Dog = Object:extend()

function Dog:new(desc)
  self.desc = desc
end

return Dog

---main.lua
local Dog = require("Dog")

local border_collie = Dog("A dog with medium length black hair with white spots.")

print(border_collie.desc) -- "A dog with medium length black hair with white spots."
```
The module returns the Object base class which can be extended to create any additional classes.

### Creating a new class
```lua
local Point = Object:extend()

function Point:new(x, y)
    self.values = {
        x or 0,
        y or 0
    }
end
```

### Creating a new instance
```lua
local p = Point(10, 20)
```

### Extending an existing class
```lua
local Rect = Point:extend()

function Rect:new(x, y, width, height)
    Point.new(self, x, y)

    table.insert(self.values, width  or 0)
    table.insert(self.values, height or 0)
end
```

### Checking an object's type
```lua
local p = Point(10, 20)

print(p:is(Object)) -- true
print(p:is(Point))  -- true
print(p:is(Rect))   -- false 
```

### Using mixins
```lua
local Unpacker = Object:extend()

function Unpacker:unpack()
    return table.unpack(self.values)
end

--You may pass in multiple classes at once, if needed.
Point:implement(Unpacker)
Rect:implement(Unpacker)

local p = Point(10, 15)
local r = Rect(20, 30, 40, 50)

print(p) --10, 15
print(r) --20, 30, 40, 50
```

### Checking for mixins
```lua
local p = Point(10, 20)

p:implements(Unpack) --true
p:implements(Point)  --false
p:is(Point)          --true
p:is(Unpack)         --false
```

### Creating a metamethod
```lua
function Point:__tostring()
    return self.values[1] .. ", " .. self.values[2]
end
```

### Using static variables
```lua
Point.SCALE = 2

local p = Point(10, 20)

print(Point.SCALE, p.SCALE) --2, 2

p.SCALE = "Hello!"

print(Point.SCALE, p.SCALE) --2, "Hello!"

p.SCALE = nil

print(Point.SCALE, p.SCALE) --2, 2

Point.SCALE = 4

print(Point.SCALE, p.SCALE) --4, 4
```

### Creating/Using a getter
```lua
--The instances table is a weak table that holds references to various objects
--created, assuming you follow the pattern laid out below. Generally, the idea is
--to keep all private variables in this table, and anywhere you don't want the 
--private variables to be directly accessed, you simply don't include the table. 
--Since the table is weak, when the object is removed from everywhere else, the 
--object will eventually be garbage collected from the table as well.
local private = require("Classy.instances")

function Point:new(x, y)
    local p = private[self]

    p.x = x or 0
    p.y = y or 0
end

--Note the usage of a private variable. __index only attempts to retrieve a value
--if one with the name doesn't exist; in otherwords if you have a regular value
--AND a getter that both have the same name, the getter function will *not* fire.
function Point.__get:x()
    return math.floor(private[self].x + 0.5)
end

function Point.__get:raw_x()
    return private[self].x
end

p = Point(5.6, 4.1)

print(p.x)     --6
print(p.raw_x) --5.6

--now that a value exists, __index won't fire, and subsequently the getter won't fire.
p.x = 3

print(p.x)     --3
print(p.raw_x) --5.6
```

### Creating/Using a setter
```lua
function Point.__set:x(value)
    assert(value >= 0, "Value of 'x' can not be negative.")
   
    private[self].x = value
end

p = Point(8, 3)

p.x = 5  -- 5
p.x = -4 -- Error!
```

### Adding a metafunction
```lua
function Point:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.x, p.y) end

    return self:tostringHelper("Class")
end

Point.__type = "point"

local p = Point(10, 20)

print(p) --"[<point> 10, 20]"
```

### Misc Methods

#### tostringHelper(value, value, value, ...)
Takes the values passed in to the method, and returns a string with the following formatting: 

[<`object.__type`> `arg[1]`, `arg[2]`, `...`]

Will automatically tostring the various values passed.

#### __tostring()
By default, Object has a __tostring metamethod that simply returns 

[<`object.__type`>]

or,

[<`object.__type`> Class]

if it's the class and not an instance.

#### __concat(value)
By default, Object has a `__concat` metamethod that will `tostring` itself and the other value, then concat the strings together.

#### __get:type()
By default, Object has a `type` getter, which returns the value of the metatable's __type value.

#### __get:is_instance()
By default, Object has a `is_instance` getter, which returns `true` if the value is an instance, and `false` if it's a class.

#### __type
By default, Object has a `__type` metavalue, which is just the string "object". The idea is to use it as a human readable name. This value is generally used in `__tostring`.
