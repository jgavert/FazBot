local _G = getfenv(0)
local print, tostring, tremove, tinsert = _G.print, _G.tostring, _G.table.remove, _G.table.insert

local function ItemArrayToString(t)
  local num = #t
  if num == 0 then
    return "{ }"
  end
  local string = '{ ' .. t[1]:GetName()
  if t then
    for i = 2,num,1 do
      local item = t[i]
      string = string .. ', ' .. item:GetName()
    end
    string = string .. ' }'
  end
  return string
end


local function StringArrayToString(t)
  local num = #t
  if num == 0 then
    return "{ }"
  end
  local string = '{ ' .. t[1]
  if t then
    for i = 2,num,1 do
      local item = t[i]
      string = string .. ', ' .. item
    end
    string = string .. ' }'
  end
  return string
end

-- This is purely for ItemDefinitions
local function IsRecipe(item)
  local item = item:GetComponents()
  if #item > 1 then
    return true
  end
  return false
end



local function HasItem(unit, item)
  --Echo("HasItem called: " .. item:GetName())
  local inventory = unit:GetInventory(true)
  local ItemToFind = item
  for slot = 1, #inventory, 1 do
    local curItem = inventory[slot]
    local curItemDef = HoN.GetItemDefinition(curItem:GetTypeName())
    --Echo(tostring(curItem))
    if curItem then
      --Echo(curItem:GetName())
      local bRecipeCheck = curItemDef:GetTypeID() ~= item:GetTypeID() or curItem:IsRecipe()
      if curItem:GetTypeID() == item:GetTypeID() and not bRecipeCheck then
        --Echo("Was true")
        return true
      end
    end
  end
  --Echo("Was false")
  return false
end


local function RemainingComponentsOfItem(unit, item)
  local remainingItems = unit:GetItemComponentsRemaining(item)
  return remainingItems
end


local function GetNextComponent(unit, item)
  --Echo("Getting the remaining components of " .. item:GetName())
  local RemainingComponents = RemainingComponentsOfItem(unit, item)
  --Echo("Remaining components: "  .. RemainingComponents)
  local numOfComponents = #RemainingComponents
  if numOfComponents == 0 then
    return nil
  end
  local components = RemainingComponentsOfItem(unit, RemainingComponents[1])
  return components[1]
end

local function hasFullInventory(unit)
  local inventory = unit:GetInventory(false)
  return (#inventory == 6 )
end

local function foundElementInList(item, list)
  for slot = 1,#list,1 do
    local current = list[slot]
    if item == current then
      return true
    end
  end
  return false
end

local function sellCheapestItem(unit, ignoreItems)
  if not ignoreItems then
    ignoreItems = {}
  end
  local inventory = unit:GetInventory(false)
  local index = -1
  local cost = 9999
  for slot = 1,#inventory,1 do
    local item = inventory[slot]
    local itemname = HoN.GetItemDefinition(item:GetTypeName())
    if item and not foundElementInList(itemname, ignoreItems) then
      local itemCost = item:GetTotalCost()
      if itemCost < cost then
        index = slot
        cost = itemCost
      end
    end
  end
  if index == -1 then
    return
  end

  unit:SellBySlot(index)
end

local function CountItemAmount(unit, item)
  --Echo("HasItem called: " .. item:GetName())
  local inventory = unit:GetInventory(true)
  local ItemToFind = item
  local count = 0
  for slot = 1, #inventory, 1 do
    local curItem = inventory[slot]
    local curItemDef = HoN.GetItemDefinition(curItem:GetTypeName())
    --Echo(tostring(curItem))
    if curItem then
      --Echo(curItem:GetName())
      local bRecipeCheck = curItemDef:GetTypeID() ~= item:GetTypeID() or curItem:IsRecipe()
      if curItem:GetTypeID() == item:GetTypeID() and not bRecipeCheck then
        count = count + 1
      end
    end
  end
  --Echo("Was false")
  return count
end

--Idea is to just remove what we see in the inventory
--first see if we have already done lots of items, then remove the first
--till we got our first item that we have, after that
--we remove only the amount of items we find in inventory
local function checkInventory(unit, ItemsToBuy)
  --Echo(ItemArrayToString(ItemsToBuy))
  local inventory = ItemsToBuy
  local invSize = #inventory
  local emptyBeginning = 0
  local hadEvenOneItem = false

  for slot = 1,invSize,1 do
    local curItem = HoN.GetItemDefinition(inventory[slot])
    local hadItem = HasItem(unit, curItem)
    Echo("CurItem: " .. inventory[slot] .. ", and had it? " .. tostring(hadItem))
    if hadItem then
      hadEvenOneItem = true
      break
    else
      emptyBeginning = emptyBeginning + 1
    end
  end
  -- remove the already bought items from the start
  -- only if we had even one item from the list
  if hadEvenOneItem then
    for slot = 1,emptyBeginning,1 do
      Echo("Removing: " .. ItemsToBuy[1])
      tremove(ItemsToBuy, 1)
    end
  end

  --Enter dragon
  --Lets just get inventory and traverse through the itemsbuy list >_>
  local inventory = unit:GetInventory(true)
  for slot = 1,#inventory,1 do
    local curItem = inventory[slot]:GetTypeName()
    local found = false
    local foundIndx = -1
    for slott = 1,#ItemsToBuy,1 do
      if ItemsToBuy[slott] == curItem then
        found = true
        foundIndx = slott
      end
    end
    tremove(ItemsToBuy, foundIndx)
  end



  --Echo(ItemArrayToString(ItemsToBuy))
  return ItemsToBuy
end


function ShopUtils()
  local functions = {}
  functions.HasItem = HasItem
  functions.HasItemsInInventory = HasItemsInInventory
  functions.GetNextComponent = GetNextComponent
  functions.ItemArrayToString = ItemArrayToString
  functions.RemainingComponentsOfItem = RemainingComponentsOfItem
  functions.IsRecipe = IsRecipe
  functions.hasFullInventory = hasFullInventory
  functions.sellCheapestItem = sellCheapestItem
  functions.checkInventory = checkInventory
  functions.StringArrayToString = StringArrayToString
  return functions
end 
