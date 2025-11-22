function UIItem:onDragEnter(mousePos)
  if self:isVirtual() then return false end

  local item = self:getItem()
  if not item then return false end

  self:setBorderWidth(1)
  self.currentDragThing = item
  g_mouse.pushCursor('target')
  return true
end

function UIItem:onDragLeave(droppedWidget, mousePos)
  if self:isVirtual() then return false end
  self.currentDragThing = nil
  g_mouse.popCursor('target')
  self:setBorderWidth(0)
  self.hoveredWho = nil
  return true
end

function UIItem:onDrop(widget, mousePos, forced)
  if not self:canAcceptDrop(widget, mousePos) and not forced then return false end

  local item = widget.currentDragThing
  if not item or not item:isItem() then return false end
  
  if self.selectable then
    if item:isPickupable() then
      self:setItem(Item.create(item:getId(), item:getCountOrSubType()))
      return true
    end
    return false
  end

  local toPos = self.position

  local itemPos = item:getPosition()
  if itemPos.x == toPos.x and itemPos.y == toPos.y and itemPos.z == toPos.z then return false end

  if item:getCount() > 1 then
    modules.game_interface.moveStackableItem(item, toPos)
  else
    g_game.move(item, toPos, 1)
  end

  self:setBorderWidth(0)
  return true
end

function UIItem:onDestroy()
  if self == g_ui.getDraggingWidget() and self.hoveredWho then
    self.hoveredWho:setBorderWidth(0)
  end

  if self.hoveredWho then
    self.hoveredWho = nil
  end
end

function UIItem:onHoverChange(hovered)
  UIWidget.onHoverChange(self, hovered)
    
  if self:isVirtual() or not self:isDraggable() then return end

  local draggingWidget = g_ui.getDraggingWidget()
  if draggingWidget and self ~= draggingWidget then
    local gotMap = draggingWidget:getClassName() == 'UIGameMap'
    local gotItem = draggingWidget:getClassName() == 'UIItem' and not draggingWidget:isVirtual()
    if hovered and (gotItem or gotMap) then
      self:setBorderWidth(1)
      draggingWidget.hoveredWho = self
    else
      self:setBorderWidth(0)
      draggingWidget.hoveredWho = nil
    end
  end
end

function UIItem:onMouseRelease(mousePosition, mouseButton)
  if self.cancelNextRelease then
    self.cancelNextRelease = false
    return true
  end

  if self:isVirtual() then return false end

  local item = self:getItem()
  if not item or not self:containsPoint(mousePosition) then return false end

  if modules.client_options.getOption('classicControl') and not g_app.isMobile() and
     ((g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton) or
      (g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton)) then
    g_game.look(item)
    self.cancelNextRelease = true
    return true
  elseif modules.game_interface.processMouseAction(mousePosition, mouseButton, nil, item, item, nil, nil) then
    return true
  end
  return false
end

function UIItem:canAcceptDrop(widget, mousePos)
  if not self.selectable and (self:isVirtual() or not self:isDraggable()) then return false end
  if not widget or not widget.currentDragThing then return false end

  local children = rootWidget:recursiveGetChildrenByPos(mousePos)
  for i=1,#children do
    local child = children[i]
    if child == self then
      return true
    elseif not child:isPhantom() then
      return false
    end
  end

  error('Widget ' .. self:getId() .. ' not in drop list.')
  return false
end

function UIItem:onClick(mousePos)
  if not self.selectable or not self.editable then
    return
  end

  if modules.game_itemselector then
    modules.game_itemselector.show(self)
  end
end

function UIItem:onItemChange()
  local tooltip = nil
  local item = self:getItem()
  
  if item then
    -- Create rich tooltip with all item information
    tooltip = self:createRichTooltip(item)
  end
  
  self:setTooltip(tooltip)
end

function UIItem:createRichTooltip(item)
  if not item then return nil end
  
  local lines = {}
  local itemId = item:getId()
  
  -- Get item description from server tooltip (if exists)
  local serverTooltip = item:getTooltip()
  if serverTooltip and serverTooltip:len() > 0 then
    -- Parse server tooltip for item name (usually first line)
    local firstLine = serverTooltip:match("([^\n]+)")
    if firstLine then
      table.insert(lines, firstLine)
      table.insert(lines, "")  -- Empty line separator
    end
  else
    -- Fallback: show item ID
    table.insert(lines, "Item #" .. itemId)
    table.insert(lines, "")
  end
  
  -- Item Count/Charges
  if item:isStackable() then
    local count = item:getCount()
    if count > 1 then
      table.insert(lines, "Count: " .. count)
    end
  elseif item:isFluidContainer() then
    local subType = item:getSubType()
    if subType > 0 then
      table.insert(lines, "Charges: " .. subType)
    end
  end
  
  -- Position (if item is on map)
  local pos = item:getPosition()
  if pos and pos.x > 0 and pos.y > 0 then
    table.insert(lines, "Position: (" .. pos.x .. ", " .. pos.y .. ", " .. pos.z .. ")")
  end
  
  -- Item Properties
  local properties = {}
  
  if item:isPickupable() then
    table.insert(properties, "Pickupable")
  end
  
  if item:isStackable() then
    table.insert(properties, "Stackable")
  end
  
  if item:isContainer() then
    table.insert(properties, "Container")
  end
  
  if item:isFluidContainer() then
    table.insert(properties, "Fluid Container")
  end
  
  if item:isMultiUse() then
    table.insert(properties, "Multi-use")
  end
  
  if item:isRotateable() then
    table.insert(properties, "Rotateable")
  end
  
  if item:isNotMoveable() then
    table.insert(properties, "Not Moveable")
  end
  
  if item:isHangable() then
    table.insert(properties, "Hangable")
  end
  
  if #properties > 0 then
    table.insert(lines, "")
    table.insert(lines, "Properties:")
    for _, prop in ipairs(properties) do
      table.insert(lines, "  • " .. prop)
    end
  end
  
  -- Additional server tooltip info (skip first line which we already used)
  if serverTooltip and serverTooltip:len() > 0 then
    local foundFirst = false
    for line in serverTooltip:gmatch("[^\n]+") do
      if foundFirst then
        table.insert(lines, line)
      else
        foundFirst = true
      end
    end
  end
  
  -- Join all lines
  return table.concat(lines, "\n")
end