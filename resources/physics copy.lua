
function physics.start()
    dbg.print("Physics start called - a no-op in Quick!")
end

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

    node.physicsMt = getmetatable(node)
    if node.physicsMt == nil then
        node.physicsMt = {}
        setmetatable(node, node.physicsMt)
    end
    
    --object.angularVelocity() -> node:get/setAngularVelocity() etc
    --use raw set and get to avoid stack overflow calling metmethods recursively!
    rawset(node, "mt__index_orig", rawget(node.physicsMt, "__index"))
    rawset(node.physicsMt, "__index", rawget(physics.porter, "index"))
    
    rawset(node, "mt__newindex_orig", rawget(node.physicsMt, "__newindex"))
    rawset(node.physicsMt, "__newindex", rawget(physics.porter, "newIndex"))
    
    -- object:setLinearVelocity() -> node.physics:setLinearVelocity() etc.
    node.setLinearVelocity = physics.porter.setLinerVelocity
    
    -- Node event listeners for physics. May want to move these to be registered for all
    -- events after call to createXXX. Or may be able to do better via metatable
    -- or overriding call in QNode or soemthing...
    node.addEventListener_orig = node.addEventListener
    node.addEventListener = physics.porter.addEventListener
    
    node.removeEventListener_orig = node.removeEventListener
    node.removeEventListener = physics.porter.removeEventListener
end


physics.porter = {}

physics.porter.index = function (table, key)
    if key == "angularVelocity" then
        return table:getAngularVelocity()
    elseif table.mt__index_orig then
        return table.mt__index_orig(table, key)
    else
        return nil
    end
end

physics.porter.newIndex = function(table, key, value)
    if key == "angularVelocity" then
        table:setAngularVelocity(value)
    elseif table.mt__newindex_orig then
        return table.mt__newindex_orig(table, key, value)
    else
        table[key] = value
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
