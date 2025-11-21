Market = {}

local protocol = runinsandbox('marketprotocol')

-- UI Components
local marketWindow
local categoryList
local itemsPanel
local categoryTitle
local balanceLabel
local refreshButton

-- State
local selectedCategory = 0
local selectedCategoryWidget = nil
local playerBalance = 0

-- Categories (estilo Store)
local categories = {
  {id = 0, name = "All Items"},
  {id = 1, name = "Weapons"},
  {id = 2, name = "Armors"},
  {id = 3, name = "Shields"},
  {id = 4, name = "Helmets"},
  {id = 5, name = "Potions"},
  {id = 6, name = "Runes"},
  {id = 7, name = "Tools"},
  {id = 8, name = "Special Items"}
}

-- Store Items (produtos da loja)
local storeItems = {
  -- Weapons
  {
    name = "Sword",
    description = "A basic sword for warriors. Good for beginners.",
    price = 500,
    itemId = 2376,
    category = 1
  },
  {
    name = "Two Handed Sword",
    description = "Powerful two-handed sword. High damage output.",
    price = 950,
    itemId = 2377,
    category = 1
  },
  {
    name = "Axe",
    description = "Standard battle axe. Balanced weapon.",
    price = 500,
    itemId = 2386,
    category = 1
  },
  
  -- Armors
  {
    name = "Plate Armor",
    description = "Heavy plate armor. Excellent protection.",
    price = 4000,
    itemId = 2463,
    category = 2
  },
  {
    name = "Chain Armor",
    description = "Medium armor with good defense.",
    price = 700,
    itemId = 2464,
    category = 2
  },
  {
    name = "Leather Armor",
    description = "Light armor for mobility.",
    price = 300,
    itemId = 2467,
    category = 2
  },
  
  -- Shields
  {
    name = "Wooden Shield",
    description = "Basic wooden shield for protection.",
    price = 150,
    itemId = 2512,
    category = 3
  },
  {
    name = "Steel Shield",
    description = "Durable steel shield. Great defense.",
    price = 800,
    itemId = 2509,
    category = 3
  },
  
  -- Helmets
  {
    name = "Helmet",
    description = "Standard helmet for head protection.",
    price = 580,
    itemId = 2458,
    category = 4
  },
  {
    name = "Chain Helmet",
    description = "Chain helmet with moderate defense.",
    price = 350,
    itemId = 2457,
    category = 4
  },
  
  -- Potions
  {
    name = "Health Potion (100x)",
    description = "Restores health. Essential for hunting.",
    price = 5000,
    itemId = 236,
    category = 5
  },
  {
    name = "Mana Potion (100x)",
    description = "Restores mana. Perfect for mages.",
    price = 5000,
    itemId = 268,
    category = 5
  },
  
  -- Tools
  {
    name = "Rope (10x)",
    description = "Used to climb up. Essential tool.",
    price = 200,
    itemId = 2120,
    category = 7
  },
  {
    name = "Shovel",
    description = "Dig holes and find treasures.",
    price = 100,
    itemId = 2554,
    category = 7
  }
}

function init()
  print('[Market] init() starting...')
  
  connect(g_game, {
    onGameStart = Market.online,
    onGameEnd = Market.offline
  })
  print('[Market] Connected game events')

  -- Load UI using displayUI
  print('[Market] Loading market.otui with displayUI...')
  
  if marketWindow then
    print('[Market] Window already exists, skipping')
    return
  end
  
  marketWindow = g_ui.displayUI('market')
  
  if not marketWindow then
    print('[Market] ❌ ERROR: Failed to load market.otui')
    return
  end
  
  print('[Market] ✅ UI loaded successfully with displayUI!')
  
  marketWindow:hide()
  print('[Market] Window hidden')

  -- Get components
  categoryList = marketWindow:recursiveGetChildById('categoryList')
  itemsPanel = marketWindow:recursiveGetChildById('itemsPanel')
  categoryTitle = marketWindow:recursiveGetChildById('categoryTitle')
  balanceLabel = marketWindow:recursiveGetChildById('balanceLabel')
  refreshButton = marketWindow:recursiveGetChildById('refreshButton')
  
  if not categoryList then print('[Market] WARNING: categoryList not found') end
  if not itemsPanel then print('[Market] WARNING: itemsPanel not found') end
  
  print('[Market] Components loaded')

  -- Connect button events
  if refreshButton then
    refreshButton.onClick = Market.onRefreshClick
  end
  
  print('[Market] Button events connected')

  -- Populate categories
  print('[Market] Calling populateCategories()...')
  Market.populateCategories()
  
  -- Show all items by default
  print('[Market] Calling showStoreItems()...')
  Market.showStoreItems()

  -- Register hotkey
  g_keyboard.bindKeyDown('Ctrl+M', Market.toggle)
  print('[Market] Hotkey registered (Ctrl+M)')

  print('[Market] ✅ Initialization complete!')
end

function terminate()
  disconnect(g_game, {
    onGameStart = Market.online,
    onGameEnd = Market.offline
  })

  g_keyboard.unbindKeyDown('Ctrl+M')

  if marketWindow then
    marketWindow:destroy()
    marketWindow = nil
  end

  Market = nil
  print('[Market] Terminated')
end

function Market.online()
  print('[Market] Player online, ready to use store')
  Market.updateBalance()
end

function Market.offline()
  if marketWindow then
    marketWindow:hide()
  end
  print('[Market] Player offline')
end

function Market.toggle()
  print('[Market] toggle() called')
  
  if not marketWindow then 
    print('[Market] ERROR: marketWindow is nil!')
    return 
  end
  
  print('[Market] marketWindow exists, checking visibility...')
  
  if marketWindow:isVisible() then
    print('[Market] Window is visible, hiding...')
    marketWindow:hide()
  else
    print('[Market] Window is hidden, showing...')
    marketWindow:show()
    marketWindow:raise()
    marketWindow:focus()
    Market.updateBalance()
    print('[Market] ✅ Window should be visible now!')
  end
end

function Market.updateBalance()
  -- Demo: pegar gold do player (quando integrar com servidor)
  playerBalance = 10000 -- Demo value
  
  if balanceLabel then
    balanceLabel:setText('You have: ' .. playerBalance .. ' gold')
  end
end

function Market.populateCategories()
  print('[Market] populateCategories() called')
  
  if not categoryList then 
    print('[Market] ERROR: categoryList is nil!')
    return 
  end
  
  print('[Market] Destroying old children...')
  categoryList:destroyChildren()
  
  print('[Market] Adding ' .. #categories .. ' categories...')
  for i, category in ipairs(categories) do
    -- Create category button
    local button = g_ui.createWidget('CategoryButton', categoryList)
    local label = button:getChildById('categoryName')
    if label then
      label:setText(category.name)
    end
    
    button:setPhantom(false)
    button.categoryId = category.id
    button:setFocusable(true)
    
    -- Click handler with visual selection
    button.onClick = function()
      -- Remove highlight from previous
      if selectedCategoryWidget then
        selectedCategoryWidget:setBackgroundColor('#00000055')
      end
      
      -- Highlight this one
      button:setBackgroundColor('#ffffff22')
      selectedCategoryWidget = button
      
      selectedCategory = category.id
      
      -- Update title
      if categoryTitle then
        categoryTitle:setText(category.name)
      end
      
      print('[Market] Category clicked: ' .. category.name)
      Market.showStoreItems()
    end
    
    -- Select first category by default
    if i == 1 then
      button:setBackgroundColor('#ffffff22')
      selectedCategoryWidget = button
    end
    
    print('[Market] Added category: ' .. category.name)
  end
  
  print('[Market] ✅ ' .. #categories .. ' categories populated!')
end

function Market.showStoreItems()
  if not itemsPanel then return end
  
  itemsPanel:destroyChildren()
  
  -- Filter items by category
  local filteredItems = {}
  for _, item in ipairs(storeItems) do
    if selectedCategory == 0 or item.category == selectedCategory then
      table.insert(filteredItems, item)
    end
  end
  
  -- Create item widgets
  for _, item in ipairs(filteredItems) do
    Market.createItemOffer(item)
  end
  
  print('[Market] ' .. #filteredItems .. ' items displayed')
end

function Market.createItemOffer(item)
  local offer = g_ui.createWidget('ItemOffer', itemsPanel)
  
  -- Set item icon
  local itemIcon = offer:getChildById('itemIcon')
  if itemIcon then
    itemIcon:setItemId(item.itemId)
  end
  
  -- Set item name
  local itemName = offer:getChildById('itemName')
  if itemName then
    itemName:setText(item.name)
  end
  
  -- Set description
  local itemDescription = offer:getChildById('itemDescription')
  if itemDescription then
    itemDescription:setText(item.description)
  end
  
  -- Set price
  local itemPrice = offer:getChildById('itemPrice')
  if itemPrice then
    itemPrice:setText('Price: ' .. item.price .. ' gold')
  end
  
  -- Set buy button
  local buyButton = offer:getChildById('buyButton')
  if buyButton then
    buyButton.onClick = function()
      Market.onBuyItem(item)
    end
  end
end

function Market.onBuyItem(item)
  print('[Market] Buy clicked: ' .. item.name)
  
  if playerBalance < item.price then
    displayErrorBox('Market Store', 'You don\'t have enough gold!\n\nPrice: ' .. item.price .. ' gold\nYou have: ' .. playerBalance .. ' gold')
    return
  end
  
  local message = string.format(
    'Buy %s for %d gold?\n\n%s\n\nThis is a DEMO. Server integration coming soon!',
    item.name,
    item.price,
    item.description
  )
  
  displayInfoBox('Market Store - Buy Item', message)
end

function Market.onRefreshClick()
  print('[Market] Refresh clicked')
  Market.showStoreItems()
  Market.updateBalance()
  displayInfoBox('Market Store', 'Store refreshed!')
end

print('[Market 7.72] Module loaded')
