
-- Mapping of Corona's display library to Marmalade Quick

display = {}

-- Constants --

-- TODO: Corona has a scale setting in config.lua which affect most of the
-- width and hieght values. It's like marmalade's virtual resolution.
-- Should have a function that reads config.lua and set's up these
-- values plus possibly uses Nick's VirtualResolution to implement

display.actualContentHeight = director.displayHeight
display.actualContentWidth = director.displayWidth
display.contentCenterX = director.displayHeight / 2
display.contentCenterY = director.displayWidth / 2
display.contentHeight = director.displayHeight
display.contentScaleX = 1
display.contentScaleY = 1
display.contentWidth = director.displayWidth

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
-- Group/Node Manipualtion --

function display.newGroup()
    return director:createNode()
    --Quick has no groupds but nodes can do same job (have children and be non-visual)
    --TODO: check x and y default to zero!
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
    
    local image = director:createSprite(params)
    
    if parent then
        parent:addChild(image)
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
    
    local parent = display.genericParamFixes(params, true)
    
    local label = director:createLabel({params})
    
    if parent then parent:addChild(image) end
    
    return label
end
