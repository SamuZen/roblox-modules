--Original Source: https://gist.github.com/mrunderhill89/623d125af27d382bdb00

local BehaviourTree = {}
BehaviourTree.__index = BehaviourTree

BehaviourTree.RESULTS = {
	SUCCESS = 'success',
	FAIL = 'fail',
	RUNNING = 'running',
}

local debug = false

--[[
	Wrap function values to our results list so that we can use functions
	not tuned to our behavior tree
]]--
function BehaviourTree:wrap(value)
	for k, v in pairs(BehaviourTree.RESULTS) do
		if value == k then
			return v
		end
		if value == v then
			return v
		end
	end
	if value == false then return BehaviourTree.RESULTS.FAIL end
	return BehaviourTree.RESULTS.SUCCESS
end

function BehaviourTree:makeEmpty()
	local node = {}
	setmetatable(node, BehaviourTree)
	node.children = {}
	node.parent = nil
	return node
end

function BehaviourTree:setAction(action)
	self.run = action
	assert(type(self.run) == 'function', 'beheviour tree node need a run function, got ' .. type(self.run)..' instead.')
end

--[[
	Creates a new behavior tree node.
	Lua makes it possible to change the type of a node
	just by replacing a function on a per-instance basis,
	making it easy to create new node types while only having to use
	one class. Just specify what run function you want the node to use, and 
	it should work just fine.
--]]
function BehaviourTree.make(action)
	local node = {}
	setmetatable(node, BehaviourTree)
	node.children = {}
	node.Parent = nil
	--Ideally, actions should return a value from the results enum above and take a single table for arguments
	--Though you should be able to use void and boolean functions, as well.
	node.run = action
	assert(type(node.run) == 'function', 'beheviour tree node need a run function, got ' .. type(node.run)..' instead.')
	return node	
end

--[[
	Get the root Parent
]]--
function BehaviourTree:getRoot()
	if self.Parent == nil then return self end
	local parent = self.Parent
	while parent.Parent ~= nil do
		parent = parent.Parent
	end
	return parent
end

--[[
	Save some data on root
]]--
function BehaviourTree:setData(key, value)
	local root = self:getRoot()
	if root.data == nil then root.data = {} end
	root.data[key] = value
end

--[[
	Get data from root
]]--
function BehaviourTree:getData(key)
	local root = self:getRoot()
	if root.data ~= nil then
		if key == nil then return root.data end
		return root.data[key]
	end
	return nil
end

--[[
	Adds a child to the behavior tree, and set the child's parent.
--]]
function BehaviourTree:addChild(child)
	if child == nil then
		warn('debug')
	end
	child.Parent = self
	table.insert(self.children, child)
end

--[[
	Iterate through the node's children in a loop.
	Halt and return fail if any child fails.
	Otherwise, return success when done.
]]--
function BehaviourTree:sequence(args)
	if debug then warn(`sequence: {self.name or ""}`) end
	for k, v in ipairs(self.children) do
		local result = BehaviourTree:wrap(v:run(args))
		if debug then print(`{v.name or ""}: {result}`) end

		if result == BehaviourTree.RESULTS.FAIL then
			return BehaviourTree.RESULTS.FAIL
		end
		if result == BehaviourTree.RESULTS.RUNNING then
			return BehaviourTree.RESULTS.RUNNING
		end
	end
	if debug then warn(`sequence: {self.name or ""} SUCCESS`) end
	return BehaviourTree.RESULTS.SUCCESS
end

--[[
	Iterate through the node's children in a loop.
	Halt and return fail if any child fails.
	Otherwise, return success when done.
]]--
function BehaviourTree:sequenceWithMemory(args)
	if debug then warn(`{self.name or ""}`) end
	if self.current == nil or self.current > #self.children or self.children[self.current] == nil then
		self.current = 1
	end
	for i = self.current, #self.children, 1 do
		self.current = i
		local result = BehaviourTree:wrap(self.children[i]:run(args))
		if result == BehaviourTree.RESULTS.FAIL then
			self.current = 1
			return BehaviourTree.RESULTS.FAIL
		end
		if result == BehaviourTree.RESULTS.RUNNING then
			return BehaviourTree.RESULTS.RUNNING
		end
	end
	self.current = 1
	return BehaviourTree.RESULTS.SUCCESS
end

--[[
	Time-sliced version of BT:sequence.
	Needs to be run multiple times (like in a loop) to be effective, but
	doesn't lock up the computer while running.
	
	When finished iterating, it will return either success or fail.
	If not finished, it will return wait.
	
	The index will NOT advance if the current child returns wait, which means
	a child node may be run more than once until it returns a definitive success or fail.
	This lets us chain together multiple time-sliced selectors or sequencers together.
]]--
function BehaviourTree:sliceSequence(args)
	if debug then warn(`{self.name or ""}`) end
	if self.current == nil then
		self.current = 1
	else
		local child = self.children[self.current]
		if child == nil then
			self.current = 1
			return BehaviourTree.RESULTS.SUCCESS
		end
		local result = BehaviourTree:wrap(child:run(args))
		if result == BehaviourTree.RESULTS.FAIL then
			self.current = 1
			return BehaviourTree.RESULTS.FAIL
		end
		if result == BehaviourTree.RESULTS.SUCCESS then
			self.current = self.current + 1
		end
	end

	return BehaviourTree.RESULTS.RUNNING
	
end

--[[
	Iterate through the node's children in a loop.
	Halt and return success if any child succeeds.
	Otherwise, return fail when done.
]]--
function BehaviourTree:select(args)
	if debug then warn(`select: {self.name or ""}`) end
	for k, v in ipairs(self.children) do
		
		local result = BehaviourTree:wrap(v:run(args))
		if debug then print(`{v.name or "?"}: {result}`) end

		if result == BehaviourTree.RESULTS.SUCCESS then
			return BehaviourTree.RESULTS.SUCCESS
		end
		if result == BehaviourTree.RESULTS.RUNNING then
			return BehaviourTree.RESULTS.RUNNING
		end
	end
	if debug then warn(`select: {self.name or ""} FAILED`) end
	return BehaviourTree.RESULTS.FAIL
end

--[[
	Iterate through the node's children in a loop.
	Halt and return success if any child succeeds.
	Otherwise, return fail when done.
]]--
function BehaviourTree:selectWithMemory(args)
	if debug then warn(`{self.name or ""}`) end
	if self.current == nil then
		self.current = 1
	end
	for i = self.current, #self.children, 1 do
		self.current = i
		local result = BehaviourTree:wrap(self.children[i]:run(args))
		
		if result == BehaviourTree.RESULTS.SUCCESS then
			self.current = 1
			return BehaviourTree.RESULTS.SUCCESS
		end
		if result == BehaviourTree.RESULTS.RUNNING then
			return BehaviourTree.RESULTS.RUNNING
		end
	end
	self.current = 1
	return BehaviourTree.RESULTS.FAIL
end

--[[
	Time-sliced version of BT:select.
	When finished iterating, it will return either success or fail.
	If not finished, it will return wait.
]]--
function BehaviourTree:sliceSelect(args)
	if debug then warn(`{self.name or ""}`) end
	if self.current == nil then
		self.current = 1
	else
		local child = self.children[self.current]
		if child == nil then
			self.current = 1
			return BehaviourTree.RESULTS.FAIL
		end

		local result = BehaviourTree:wrap(child:run(args))
		if result == BehaviourTree.RESULTS.SUCCESS then
			self.current = 1
			return BehaviourTree.RESULTS.SUCCESS
		end
		if result == BehaviourTree.RESULTS.FAIL then
			self.current = self.current + 1
		end
		if debug then warn('slice select is running') end
	end
	return BehaviourTree.RESULTS.RUNNING
end

function BehaviourTree:successIsRunning(args)
	if debug then warn(`success is running: {self.name or ""}`) end
	if self.children[1] == nil then
		return BehaviourTree.RESULTS.FAIL
	end
	local result = BehaviourTree:wrap(self.children[1]:run(args))
	
	if result == BehaviourTree.RESULTS.SUCCESS then
		return BehaviourTree.RESULTS.RUNNING
	end
	return result
end

function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

function BehaviourTree:randomSelect(args)
	if debug then warn(`{self.name or ""}`) end
	local childrenNodes = shuffle(self.children)
	for k, v in ipairs(childrenNodes) do

		local result = BehaviourTree:wrap(v:run(args))
		if result == BehaviourTree.RESULTS.SUCCESS then
			return BehaviourTree.RESULTS.SUCCESS
		end
		if result == BehaviourTree.RESULTS.RUNNING then
			return BehaviourTree.RESULTS.RUNNING
		end
	end
	return BehaviourTree.RESULTS.FAIL
end

--[[
	Time-sliced version of BT:select.
	When finished iterating, it will return either success or fail.
	If not finished, it will return wait.
]]--
function BehaviourTree:randomSliceSelect(args)
	if debug then warn(`{self.name or ""}`) end
	if self.current == nil then
		self.current = 1
	else
		local childrens = shuffle(self.children)
		local child = childrens[self.current]
		if child == nil then
			self.current = 1
			return BehaviourTree.RESULTS.FAIL
		end
		local result = BehaviourTree:wrap(child:run(args))
		if result == BehaviourTree.RESULTS.SUCCESS then
			self.current = 1
			return BehaviourTree.RESULTS.SUCCESS
		end
		if result == BehaviourTree.RESULTS.FAIL then
			self.current = self.current + 1
		end
	end
	return BehaviourTree.RESULTS.RUNNING
end

--[[
	Simply returns success if its child fails,
	or fail if the child succeeds. Any other result (like wait) is unmodified.
	
	Defaults to success if has no children or its child has
	no run function.
]]--
function BehaviourTree:invert(args)
	if debug then warn(`{self.name or ""}`) end
	if self.children[1] == nil then
		return BehaviourTree.RESULTS.SUCCESS
	end
	local result = BehaviourTree:wrap(self.children[1]:run(args))
	if result == BehaviourTree.RESULTS.SUCCESS then
		return BehaviourTree.RESULTS.FAIL
	end
	if result == BehaviourTree.RESULTS.FAIL then
		return BehaviourTree.RESULTS.SUCCESS
	end
	return result
end

function BehaviourTree:negate(args)
	if debug then warn(`{self.name or ""}`) end
	if self.children[1] == nil then
		return BehaviourTree.RESULTS.FAIL
	end
	BehaviourTree:wrap(self.children[1]:run(args))
	return BehaviourTree.RESULTS.FAIL
end

--[[
	Continuously runs its child until it fails.
]]--
function BehaviourTree:repeatUntilFail(args)
	if debug then warn(`{self.name or ""}`) end
	while BehaviourTree:wrap(self.children[1]:run(args)) ~= BehaviourTree.RESULTS.FAIL do
		
	end
	return BehaviourTree.RESULTS.SUCCESS
end

--[[
	Continuously returns wait until its child fails.
	Effectively a time-sliced version of BT:repeatUntilFail.
]]--
function BehaviourTree:waitUntilFail(args)
	if debug then warn(`{self.name or ""}`) end
	if BehaviourTree:wrap(self.children[1]:run(args)) == BehaviourTree.RESULTS.FAIL then
		return BehaviourTree.RESULTS.SUCCESS
	end
	return BehaviourTree.RESULTS.RUNNING
end

function BehaviourTree:limit(args)
	if debug then warn(`{self.name or ""}`) end
	if self.limit == nil then
		self.limit = 1
		if self.count == nil then
			
		end
	end
end

return BehaviourTree
