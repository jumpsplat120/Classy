local instances, mt

mt = {}

---@type Classy.private
instances = {}

mt.__mode = "k"

setmetatable(instances, mt)

return instances