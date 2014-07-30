
-- Mapping of Corona's display library to Marmalade Quick

display = {}

-- Constants --

-- TODO: Corona has a scale setting in config.lua which affect most of the
-- width and hieght values. It's like marmalade's virtual resolution.
-- Should have a function that reads config.lua and set's up these
-- values plus possibly uses Nick's VirtualResolution to implement

display.actualContentHeight = director.displayHeight
display.actualContentWidth = director.displayWidth
display.contentCenterX = director.displayWidth / 2
display.contentCenterY = director.displayHeight / 2
display.contentHeight = director.displayHeight
display.contentScaleX = 1
display.contentScaleY = 1
display.contentWidth = director.displayWidth
display.contentHeight = director.displayHeight

display.currentStage = director:getCurrentScene()--prob needs updating on scene change.
-- In Corona, this is a single program-global node, no equivalent in Quick so use scene.
-- Might want to make it a new node if it actually does anything interesting in Corona...

display.fps = 30

display.imageSuffix = nil
-- TODO: Corona allows "@2x" etc. if using newImageRect. Would need implementing here.
-- See http://docs.coronalabs.com/guide/basics/configSettings/index.html#dynamicimages
 
display.pixelHeight = director.displayHeight -- these are the fixed ones. other values should scale/move
display.pixelWidth = director.displayHeight
display.screenOriginX = 0
display.screenOriginY = 0
display.statusBarHeight = 0 --deprecated for topStatusBarContentHeight. iOS only
display.topStatusBarContentHeight = 0 --TODO: would this be zero in fullscreen?
display.viewableContentHeight = director.displayHeight
display.viewableContentWidth = director.displayWidth

function display.getCurrentStage()
    display.currentStage = director:getCurrentScene()
    return display.currentStage
end

function QScene:setFocus(node, id)
    system:setFocus(node)
    --TODO - multitouch!
end

display.defaults = {
    anchorX = 0.5,
    anchorY = 0.5}

function display.setDefault(key, value)
    if display.defaults[key] then
        display.defaults[key] = value
    end
end

function display.getDefault(key)
    return display.defaults[key]
end
-- Helper functions and switches --

function display:update(event)
    display.fps = 1 / system.deltaTime
end
system:addEventListener("update", display)

display.HiddenStatusBar = 1
display.DefaultStatusBar = 2
display.TranslucentStatusBar = 3
display.DarkStatusBar = 4
function display.setStatusBar(showOrHide)
    dbg.print("setStatusBar not supported in Quick yet")
end

--------------------------------------------------------------------
-- Creating display objects --

function display.genericParamFixes(params)
    params.w = params.width params.width = nil
    params.h = params.height params.height = nil
    params.source = params.filename params.filename = nil
    
    params.xAnchor = display.defaults.anchorX
    params.yAnchor = display.defaults.anchorY
    
    if params.baseDir then params.source = params.baseDir .. "/" .. params.source end
    
    params.yFlip = true --flip all images as Quick's y axis goes other way
    
    if params.parent then
        local parent = params.parent
        params.parent = nil
        return parent
    else
        return nil
    end
end


--Quick has no groupds but nodes can do same job (have children and be non-visual)
function display.newGroup()
    -- For all display objects:
    -- - we use a dummy object, not the actual Quick node
    -- - display is set as metatable, with __index override to redirects to real Quick node
    -- - This allows for overriding of node.somevalue get/set calls if needed, e.g. can turn
    --   image.x = 7 into a call to someFunction(image, 7)!
    local group = {}
    group.__node = director:createNode()
    setmetatable(group, display)
    return group
end

-- Used by GroupObjects (via __index) which are Nodes in Quick
function display.insert(self, child)
    if child.__offset then
        self.__node:addChild(child.__offset)
    else
        self.__node:addChild(child.__node)
    end
end

display.__index = function (table, key)
    local node = table.__node
    --physics
    if key == "angularVelocity" then
        assert(node.physics, "object.angularVelocity access without object added to physics!")
        return node.physics:getAngularVelocity()
    elseif key == "bodyType" then
        return node.physics.type
    elseif key == "density" then
        return node.physics.density
        
    elseif key == "insert" or key == "addEventListener" or key == "removeEventListener" then
        return display[key]
    
    else
        return node[key] --may return node userdata values or users custom values if they added any
    end
end

display.__newindex = function (table, key, value)
    local node = table.__node
    --physics
    if key == "angularVelocity" then
        assert(node.physics, "object.angularVelocity assignment without object added to physics!")
        node.physics:setAngularVelocity(value)
    elseif key == "bodyType" then
        node.physics:setBodyType(value)
    elseif key == "density" then
        node.physics.density = value
    elseif node.physics and (key == "x" or key == "y" or key == "rotation") then
        --In Corona, can set pos and rotation after adding to physics, but not in Quick
        --...use box2d equivalents instead!
        if key == "x" then
            node.physics:setTransform(value, node.y, node.rotation) --not optimal!
            node.x = value --have to set node value too in case it is accessed (eg in key=y below!) before update loop
        elseif key == "y" then
            node.physics:setTransform(node.x, value, node.rotation)
            node.y = value
        else
            node.physics:setTransform(node.x, node.y,-value) --rotation reversed
            node.rotation = value
        end
        
    else
        --Note: any values that aren't part of node userdata object or handled above will
        --actually be added by Quick to node's personal table of user values but this is
        --hidden from the user in Quick
        node[key] = value
        
        if key == "text" and table.__offset then
            node:sync()
            table.__offset.x=-node.wText*table.__xAnchor --anchors are dynamic for text in Corona
            local h = node.hText
            if h < 0 then h = -1 end --heights are negative if yScale is negative!! Might want to check x too...
            table.__offset.y=h*table.__yAnchor
        end
    end
end

tmpfunc = function(event)
    event.y = director.displayHeight - event.y
    event.target.__touch.original(event)
end

display.__touchRedirect = function(listenerTable, event)
    event.y = director.displayHeight - event.y
    if listenerTable.isFunction then
        listenerTable.original(event)
    else
        listenerTable.original.touch(listenerTable.original, event)
    end
end

display.__preColRedirect = function(listenerTable, event)
    event.name = "preCollision"
    listenerTable.preCollision(listenerTable, event)
end

display.__postColRedirect = function(listenerTable, event)
    event.name = "postCollision"
    listenerTable.postCollision(listenerTable, event)
end

display.addEventListener = function(self, eventName, listener)
    local node = self.__node
    if eventName == "touch" then
        -- create dummy touch function/table to call back to original and do y flipping
        if not node.__touch then node.__touch = {} end
        node.__touch.original = listener
        if type(listener) == "function" then
            node.__touch.isFunction = true
        end
        node.__touch.touch = display.__touchRedirect
        listener = node.__touch
    elseif eventName == "preCollision" then
        eventName = "collisionPreSolve"
        if type(listener) ~= "function" then
            listener.collisionPreSolve = display.__preColRedirect
        end
    elseif eventName == "postCollision" then
        eventName = "collisionPostSolve"
        -- Docs are a little unclear... Corona's imply this happens *after* regular collision
        -- event and Quick's before. However I think both are actually before so no issue.
        if type(listener) ~= "function" then
            listener.collisionPostSolve = display.__postColRedirect
        end
    end
    
    self.__node:addEventListener(eventName, listener)
end

display.removeEventListener = function(self, eventName, listener)
    local node = self.__node
    if eventName == "touch" then
        node.__touch.original = nil
        node.__touch.touch = nil
        node.__touch.isFunction = nil
        listener = node.__touch
    elseif eventName == "preCollision" then
        eventName = "collisionPreSolve"
        listener.collisionPreSolve = nil
    elseif eventName == "postCollision" then
        eventName = "collisionPostSolve"
        listener.collisionPostSolve = nil
    end
    
    self.__node:removeEventListener(eventName, listener)
end

-- Images are simple versions of sprite in Corona. Quick has no equivalent so just use sprite!
function display.newImage(p1, p2, p3, p4, p5, p6)
    -- params:[parent,] filename [,baseDir] [,x,y] [,isFullResolution]
    
    local params = {p1,p2,p3,p4,p5,p6}
    local signature = {{name="parent", pType="userdata", req=false},
                 {name="filename", pType="string", req=true},
                 {name="baseDir", pType="string", req=false},
                 {name="x", pType="number", req=false},
                 {name="y", pType="number", req=false},
                 {name="isFullResolution", pType="boolean", req=false}}
    params = getParamsFromListWithOptionals(params, signature)
    
    if not params.filename then
        dbg.assert(false, "display.newImage called without filename")
        return nil
    end
    
    local parent = display.genericParamFixes(params)
    
    params.isFullResolution = nil --not supported yet
    
    local image = {}
    image.__node = director:createSprite(params)
    setmetatable(image, display)
    
    if parent then
        parent:addChild(image.__node)
    end
    
    return image
end

--TODO: Can also use "imagesheets" to create images, example:
--[[
local options =
{
    -- Required
    width = 70,
    height = 41,
    numFrames = 2,
    -- Optional; used for dynamic resolution support
    sheetContentWidth = 70,  -- width of original 1x size of entire sheet
    sheetContentHeight = 82  -- height of original 1x size of entire sheet
}
local imageSheet = graphics.newImageSheet( "fishies.png", options )
local myImage = display.newImage( imageSheet, 1 )
]]--

function display.newText(p1, p2, p3, p4, p5, p6)
    -- params:    {parent, text, x, y, width, height, font, fontSize, align}
    -- or legacy: [parentGroup,] text, x, y, [width, height,] font, fontSize
    
    local params
    if not p2 then
        params = p1
    else
        params = {p1,p2,p3,p4,p5,p6,p7,p8}
        local signature = {{name="parent", pType="userdata", req=false},
                 {name="text", pType="string", req=true},
                 {name="x", pType="number", req=true},
                 {name="y", pType="number", req=true},
                 {name="w", pType="number", req=false}, --use Quick names so we can pass table direclty
                 {name="h", pType="number", req=false},
                 {name="font", pType="string", req=true},
                 {name="fontSize", pType="number", req=true}}
        params = getParamsFromListWithOptionals(params, signature)
    end
    
    if not params.text then dbg.assert(false, "display.newImage called without filename") return nil end
    --TODO: Quick just uses natural font size and can then scale
    --Would need to do some clever scaling, maybe with a hidden parent node here to mimic
    params.fontSize = nil
    
    local parent = display.genericParamFixes(params)
    
    local label = {}
    label.__node = director:createLabel(params)
    
    --Quick text doesn't support xAnchor or yAnchor. Cheap offset for now.
    label.__node:sync()
    label.__offset = director:createNode({x=-label.__node.wText*params.xAnchor, y=label.__node.hText*params.yAnchor})
    label.__xAnchor = params.xAnchor
    label.__yAnchor = params.yAnchor
    label.__node.yScale = -1
    label.__offset:addChild(label.__node)
    
    setmetatable(label, display)
    
    if parent then parent:addChild(label.__offset) end
    
    return label
end
