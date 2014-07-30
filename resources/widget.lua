
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
        rawset(table, key, value)
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
    
    button.default = director:createSprite({source=options.defaultFile, yFlip = true})
    button.over = director:createSprite({source=options.overFile, isVisible=false, yFlip = true})
    button.label = director:createLabel({x=button.default.w/2,y=button.default.h/2, text=options.label, color=options.labelColor})
    button.label.yScale = -1
    button.label.x = button.label.x - button.label.wText/2
    button.label.y = button.label.y + button.label.hText/2
    button.default:addChild(button.over)
    button.default:addChild(button.label)
	--TODO: options.emboss
    
    setmetatable(button, widget.Button)
    
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
    
    return button
end

--TODO: need system listener too for tracking touches released not over the button...
function widget.Button:touch(event)
    if event.phase == "began" then
        self.over.isVisible = true
        if self.onPress then
            local portEvent = {name="onPress", phase="began", target=self} --not sure if target is needed
            if type(self.onPress) == "function" then
                self.onPress(portEvent)
            else
                self.onPress:onPress(portEvent)
            end
        end
    elseif event.phase == "ended" then
        self.over.isVisible = false
        if self.onRelease then
            local portEvent = {name="onPress", phase="began", target=self}
            if type(self.onRelease) == "function" then
                self.onRelease(portEvent)
            else
                self.onRelease:onRelease(portEvent)
            end
        end
    end
end

return widget
