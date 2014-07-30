
-- Main file for Mapping Corona API to Marmalade Quick API.
-- This file contains implementations of the libraries that aren't explicitly
-- included in Corona apps, most notably the 'display' library.
-- Other libs have mappings in their own lua files.
--
-- Libs with same names in Corona and Quick include: audio


--require("mobdebug").start() --uncomment for breakpoint debugging in ZeroBrane IDE

quickPorter = {}

director.addNodesToScene = true --by default Quick adds new nodes to current scene

--Quick's y goes in opoosite direction and origin is at bottom, not top
quickPorter.scene = director:createScene()
director:moveToScene(quickPorter.scene)
quickPorter.scene.yScale=-1
quickPorter.scene.y = director.displayHeight

system.ResourceDirectory = "" --project's root
-- Corona uses full paths when you use "myfile=oi.open" etc and to do this
-- you would call local path = system.pathForFile("myfile", [basedir, defaults to system.DocumentsDirectory])
-- Both file.io and Quick's APIs will look relative to root folder and can read and right
-- to that location
-- Corona restricts access to read only on Android when using io.open.
-- Marmalde does not - internally it does automatic aliasing if you try to write
-- over an existing file on Android for example.
-- There is also a restriction on Corona on Android that you can't read most file types
-- apart from .txt using oi.open! (obv you can use Corona's own APIs).
-- That might apply to Marmalade too... need to Check!


-- Helper func for functions that take param lists where some are optional
-- need to work out which are which based on type...
function getParamsFromListWithOptionals(paramList, signature)
    local p = 1
    local i = 1
    local paramsOut = {}
    local maxParams = 0
    
    for k,s in ipairs(signature) do
        paramsOut[s.name] = nil
        maxParams = maxParams + 1
    end
    
    local sig
    local vType
    repeat
        value = paramList[p]
        if value then
            vType = type(value)
            local match
            repeat
                sig = signature[i]
                if sig then
                    match = vType == sig.pType
                    if match then
                        paramsOut[sig.name] = value
                    else
                        i=i+1
                    end
                end
            until match or sig == nil
         end
         i=i+1
         p=p+1
    until p > maxParams or sig == nil --check all possible params as user is allowed to include nils
    
    return paramsOut
end

---------------------------------------------------
-- Generic Node functionality --

 --we can define new functions aviailable to all nodes using : calling
 --convention by just adding to the QNode metatable.

function QNode:removeSelf()
    self:removeFromParent()
end

function setColourGrey(colour, value)
    value = value*255
    colour[1] = value
    colour[2] = value
    colour[3] = value
end

-- TODO: this prob doesn't work using just "node." - need to use metatable or apply to each type
-- during createXXX call.
function QNode:setFillColor(p1,p2,p3,p4)
    --[[params: gray
                gray, alpha
                red, green, blue
                red, green, blue, alpha
                gradient
    ]]--
    local colour = {0,0,0}
    if type(p1) == "table" then
        dbg.assert("setFillColor: gradients not supported")
    elseif not p2 then
        setColourGrey(colour, value)
    elseif not p3 then
        setColourGrey(colour, value)
        self.alpha = p2
    else
        colour[1] = p1*255
        colour[2] = p2*255
        colour[3] = p3*255
        if p4 then
            self.alpha = p4
        end
    end
    self.color = colour
end

function QLabel:setTextColor(p1,p2,p3,p4)
    self:setFillColor(p1,p2,p3,p4)
end

-----------------------------------------------------------------------
-- Events

-- Override event from QEvent so we can change names, set missing values etc when dispatching any event
-- Lack of user-data/params parameter for events in Quick means this is the easiest way to do this
-- If we could pass arbitrary data in an event, that would be ideal
-- We could also use intermediate functions similar to node touch events. Thats prob cleaner.

function quickPorter.handleEventWithListener(event, listener)
    
    -- Physics:
    --NB - these only work for node listeners. Corona has global Runtime listeners for physics
    --     but QUick doesn't. Would need to implement in Quick or mimic by Runtime:addListener
    --     internally adding listners to every node!
    if event.name == "collision" or event.name == "collisionPreSolve" or event.name == "collisionPostSolve" then
        if event.name == "collision" then
            event.contact = {isTouching = false, isEnabled = true, bounce = 0.5, friction = 0.5 }
            --TODO: quick doesnt provide this here. May be able to easily get since pre and post use it
        else
            --TODO: need to map from Corona's .isTouching to Quick's :isTouching() etc
            --using metatables __index etc as with node's angularVelocity
        end
        
        --event.element1 --multi-element bodies not suported in Quick yet
        --event.element2
        
        if event.target == event.objectA then -- A might always be target... not sure!
            event.other = event.objectB
            --event.selfElement = event.element1
            --event.otherElement = event.element2
        else
            event.other = event.objectA
            --event.selfElement = event.element2
            --event.otherElement = event.element1
        end
    end
    if event.name == "collisionPreSolve" then
        if listener.func then
            event.name = "preCollision" -- in table, set later in display.__preColRedirect as index name must match Quick event name
        end
    elseif event.name == "collisionPostSolve" then
        if listener.func then
            event.name = "postCollision"
        end
        event.force = event.impulse or 0 -- TODO: seem to get zero sometimes...
        --TODO Corona uses force as it's frames are fixed length (unless slowdown!) force
        -- ought to be impulse/time - check how this matches up in reality. Suspect corona is just returning impulse
        event.friction = 0.5 --TODO: not yet supported in Quick!
    end
    
    return quickPorter.handleEventWithListener_orig(event, listener)
end

quickPorter.handleEventWithListener_orig = handleEventWithListener
handleEventWithListener = quickPorter.handleEventWithListener

---------------------------------------------------------
--Runtime

Runtime = {}

function Runtime:addEventListener(eventName, listener)
    if eventName == "enterFrame" then
        --Called once every frame. Equivalent to Quick's "update" event
        --except in Corona, there are no node update events
        system:addEventListener("update", listener)
    else
        dbg.assert(false, "Runtime:addEventListener passed unsupported eventName: " .. eventName)
    end
end

function Runtime:removeEventListener(eventName, listener)
    if eventName == "enterFrame" then
        system:removeEventListener("update", listener)
    else
        dbg.assert(false, "Runtime:removeEventListener passed unsupported eventName: " .. eventName)
    end
end



---------------------------------------------------------
--Timer
--Quick's timers are created with system/node:addTimer, then the timers have their own cancel etc funcitons
--Corona uses a singleton (like Quick's Tween lib) to do the same

timer = {}

function timer.performWithDelay(delay, listener, iterations)
    if iterations == nil then
        iterations = 1
    elseif iterations == -1 then
        iterations = 0
    end
    system:addTimer(listener, delay, iterations)
    --NB: delay here is called 'period' in Quick. Quick also has a param called 'delay'
    --(not used here) but that means an extra delay before period (period repeats with
    --each iteration, delay does not)
end

function timer.pause(t)
    t:pause()
end

function timer.cancel(t)
    t:cancel()
end

function timer.resume(t)
    t:resume()
end

---------------------------------------------------------
--Audio
audio.loadSound_orig = audio.loadSound
audio.loadSound = function(fileName, baseDir)
    if baseDir then fileName = baseDir .. "/" .. fileName end
    audio:loadSound_orig(fileName) --has no return value!
    local handle = {portType = "sound", fileName = fileName}
    return handle
end

audio.loadStream_orig = audio.loadStream
audio.loadStream = function(fileName, baseDir)
    if baseDir then fileName = baseDir .. "/" .. fileName end
    audio:loadStream_orig(fileName)
    local handle = {portType = "stream", fileName = fileName}
    return handle
end

function audio.play(handle, options)
    local loop = nil
    if options then
        dbg.assert(options.channel == nil, "audio.play: channel not supported")
        dbg.assert(options.duration == nil, "audio.play: channel not supported")
        dbg.assert(options.fadein == nil, "audio.play: channel not supported")
        dbg.assert(options.onComplete == nil, "audio.play: channel not supported")
        loop = options.loops
    end
    
    if handle.portType == "stream" then
        audio:playStream(handle.fileName, loop)
    else
        audio:playSound(handle.fileName, loop)
    end
end

---------------------------------------------------------
--Touch
--Not overriding touch yet. event.phase/x/y should work.

--TODO:Missing params we need to support:
--event.time (miliseconds since app started)
--event.xStart (x pos on began event for this touch)
--event.yStart

--May also need to interfere on other params if coord system/VR causes issues

--run code for files that user does not explicitly call require for
dofile("display.lua")
dofile("native.lua")
