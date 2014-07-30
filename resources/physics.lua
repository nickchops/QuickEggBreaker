
--TODO: prob want to replace "physics" and set up original one as __index metatable of it...

physics.porter = {}
local xGravity,yGravity = physics:getGravity()
physics:setGravity(xGravity,-yGravity)

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
                     type=values.bodyType or bodyType}
    
    physics:addNode(node.__node, qValues)
    
    -- object:setLinearVelocity() -> node.physics:setLinearVelocity() etc.
    node.setLinearVelocity = physics.porter.setLinearVelocity
end

physics.porter.setLinearVelocity = function(self,x,y)
    self.physics:setLinearVelocity(x,y)
end

physics.porter.getGravity_orig = physics.getGravity
function physics:getGravity()
    local x,y = physics.porter.getGravity_orig(physics)
    return x, -y
end

physics.porter.setGravity_orig = physics.setGravity
function physics:setGravity()
    physics.porter.setGravity_orig(physics, x, -y)
end

return physics
