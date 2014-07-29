
physics.porter = {}

function physics.start()
    dbg.print("Physics start called - a no-op in Quick!")
end

physics.porter.metaOverrideFlag = false

function physics.addBody(node, p1, p2)
    --TODO: looks like there are more overloads to support as you can have body "elements" and set them here...
    local bodyType = "dynamic"
    local values = nil
    if p1 then
        if type(p1) == "string" then
            bodyType = p1
            values = p2
        else
            values = p1
        end
    end
    if values then
        dbg.assert(values.filter == nil, "physics: filter not supported")
        dbg.assert(values.shape == nil, "physics: shape not supported")
        dbg.assert(values.box == nil, "physics: box not supported")
        dbg.assert(values.chain == nil, "physics: chain not supported")
        dbg.assert(values.connectFirstAndLastChainVertex == nil, "physics: connectFirstAndLastChainVertex not supported")
        dbg.assert(values.outline == nil, "physics: outline not supported")
        
        dbg.assert(values.type == nil, "physics: 'type' in values table is not valid and will be ignored") --hint in case original code is buggy
    end

    local qValues = {friction=values.friction,
                     density=values.density,
                     restitution=values.bounce,
                     radius=values.radius,
                     type=bodyType}
    
    physics:addNode(node, qValues)
    
    -- metatable to allow index lookup calls to call functions
    -- e.g. node.angularVelocity -> node.physics:setAngularVelocity() or node.physics:getAngularVelocity
    --use raw set and get to avoid potential stack overflow if there are chains of metmethods!
    
    if metaOverrideFlag == false then
        metaOverrideFlag = true
        local nodeMt = getmetatable(node)
        
        physics.porter.nodeMt__index = rawget(nodeMt, "__index")
        rawset(nodeMt, "__index", physics.porter.__index)
        
        physics.porter.nodeMt__newindex = rawget(nodeMt, "__newindex")
        rawset(nodeMt, "__newindex", physics.porter.__newindex)
    end
    
    --TODO: we're setting these for ever node, but there's prob a global metatable to set them in
    --once. Setitng them above likely would just sets them for the first object in its personal
    --values metatable...
    
    -- object:setLinearVelocity() -> node.physics:setLinearVelocity() etc.
    node.setLinearVelocity = physics.porter.setLinearVelocity
    
    -- Node event listeners for physics. May want to move these to be registered for all
    -- events after call to createXXX. Or may be able to do better via metatable
    -- or overriding call in QNode or soemthing...
    node.addEventListener_orig = node.addEventListener
    node.addEventListener = physics.porter.addEventListener
    
    node.removeEventListener_orig = node.removeEventListener
    node.removeEventListener = physics.porter.removeEventListener
end

--TODO: move metatable stuff to display.newXXX() and in newXXX, return a dummy table
-- with a new metatable whose __index redirects to using node apart from in
-- unusual cases like setting position when phsyics is running.

physics.porter.__index = function (table, key)
    if key == "angularVelocity" then
        return table:getAngularVelocity() --might infinite loop if user called with non-physics node!
    else 
        local orig = physics.porter.nodeMt__index
        if orig then
            if(type(orig) == "function") then
                return orig(table, key)
            else
                return orig[key]
            end
        else
            return nil
        end
    end
end

physics.porter.__newindex = function(table, key, value)
    if key == "angularVelocity" then
        table:setAngularVelocity(value)
    --[[elseif key == "x" and table.physics then
        setTransform(value, table.y, table.rotation)
    elseif key == "y" and table.physics then
        setTransform(table.x, value, table.rotation)
    elseif key == "rotation" and table.physics then
        setTransform(table.x, table.y, value)]]--
    else
        local orig = physics.porter.nodeMt__newindex
        if orig then
            if(type(orig) == "function") then
                orig(table, key, value)
            else
                orig[key] = value
            end
        else
            table[key] = value
        end
    end
end


physics.porter.setLinearVelocity = function(self,x,y)
    self.physics:setLinearVelocity(x,y)
end

physics.porter.addEventListener = function(self, eventName, listener)        
    if eventName == "preCollision" then
        eventName = "collisionPreSolve"
    end
    if eventName == "postCollision" then
        eventName = "collisionPostSolve"
        -- Docs are a little unclear... Corona's imply this happens *after* regular collision
        -- event and Quick's before. However I think both are actually before so no issue.
    end
    
    self:addEventListener_orig(eventName, listener)
end
    
physics.porter.removeEventListener = function(self, eventName, listener)    
    if eventName == "preCollision" then
        eventName = "collisionPreSolve"
    end
    if eventName == "postCollision" then
        eventName = "collisionPostSolve"
    end
    
    self:removeEventListener_orig(eventName, listener)
end

return physics
