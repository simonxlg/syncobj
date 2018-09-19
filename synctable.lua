-----------------------
-- synctable
-- Author simon_xlg 285909195@qq.com
-----------------------
local pairs = pairs
local setmetatable = setmetatable
local synctable = {}

local new
local make
new = function(root,tab,tag)
	local _tab = {}
	local _root = root
	local ret = make(_root,_tab,tag)
	if not _root then 
		_root = ret
	end
	for k,v in pairs(tab) do
		if type(v) == "table"  then
			_tab[k] = new(_root,v,tag.."."..k)
		else
			_tab[k] = v
		end
	end
	return ret
end

make = function(root,tab,tag)
	local proxy = {
			__data = tab,
			__tag = tag,
			__root = root,
		}
	if not root then 
		proxy.__root = proxy
		proxy.__pairs ={}
	end
	setmetatable(proxy,{
		__newindex = function(s, k, v)
						local root = s.__root
						local tag = s.__tag
						local data = s.__data
						if not data[k] and type(v) == "table"  then
							data[k] = new(root,v,tag.."."..k)
						else
							data[k] = v
						end
						root.__pairs[s.__tag.."."..k] = v or "nil"
					end,
			__index = function (s, k)
						return s.__data[k]
					end
	})
	return proxy
end

function synctable.create(tab)
	local _tag = "root"
	return new(nil,tab,_tag)
end

function synctable.diff(tab)
	local diff = tab.__pairs
	tab.__pairs = {}
	return diff
end

function synctable.patch(obj,diff)
	for k,v in pairs(diff) do
		local arr = {}
		for w in k:gmatch("([^.]+)") do table.insert(arr,w) end
		local curr = obj
		local len = #arr
		for i=2,len-3 do
			curr = obj[arr[i]]
		end
		curr[arr[len]] = v
	end
	return obj
end

return synctable
