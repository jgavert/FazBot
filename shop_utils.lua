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
        return true
      end
    end
  end
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

local function sellCheapestItem(unit)
  local inventory = unit:GetInventory(false)
  local index = -1
  local cost = 9999
  for slot = 1,#inventory,1 do
    local item = inventory[slot]
    if item then
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

  unit.SellBySlot(index)
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
  return functions
end 
