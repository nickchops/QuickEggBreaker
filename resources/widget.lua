
-- Implementation of Corona's widget library for Marmalade Quick
-- Work in progress... not much progress so far ;)
-- Pretty hacky implementation to be replaced by proper library.

widget = {}

widget.Button = {}
widget.Button.__index = function(table, key)
    if key == "x" or key == "y" then --TODO: extend to other values that are part of the .default node
        return table.default[key]
    else
        return widget.Button[key] --regular "new object" metatable behaviour to call functions of widget.Button
    end
end

widget.Button.__newindex = function(table, key, value)
    if key == "x" or key == "y" then
        table.default[key] = value
    elseif key == "onPress" then
        table.onPress = options.onPress
        table.default:addEventListener("touch", table)
    end
end

function widget.newButton(options)
    --[[ Some of the params. Plenty more to add.
    defaultFile,
	overFile,
	label,
	labelColor,
	emboss,
	onPress
    ]]--
    
    local button = {}
    setmetatable(button, widget.Button)
    
    button.default = director:createSprite({source=options.defaultFile})
    button.over = director:createSprite({source=options.overFile, visible=false})
    button.label = director:createLabel({x=0,y=0, text=options.label, color=options.labelColor})
    button:addChild(button.over)
    button:addChild(button.label)
	--TODO: options.emboss for now
    
    if options.left then
        button.default.x = options.left
    else
        button.default.x = options.x or 0
        button.default.xAnchor = options.anchorX or display.defaults.anchorX
    end
    if options.top then
        button.default.y = options.top
    else
        button.default.y = options.y or 0
        button.default.yAnchor = options.anchorY or display.defaults.anchorY
    end
    
    if options.onPress then
        button.onPress = options.onPress
        button.default:addEventListener("touch", button)
    end
end

--TODO: need system listener too for tracking touches released not over the button...
function widget.Button:touch(event)
    if event.phase == "began" then
        self.over.visible = true
        local portEvent = {name="onPress", phase="began", target=self} --not sure if target is needed
        if type(self.onPress) == "function" then
            self.onPress(portEvent)
        else
            self.onPress:onPress(portEvent)
        end
    elseif event.phase == "ended" then
        self.over.visible = false
        local portEvent = {name="onPress", phase="began", target=self}
        if type(self.onRelease) == "function" then
            self.onRelease(portEvent)
        else
            self.onRelease:onRelease(portEvent)
        end
    end
end

return widget
