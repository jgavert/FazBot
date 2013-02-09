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


local function IsRecipe(item)
  local item = item:GetComponents()
  if #item > 1 then
    return true
  end
  return false
end

local function HasItem(unit, item)
  local inventory = unit:GetInventory(true)
  local ItemToFind = item
  for slot = 1, 12, 1 do
    local curItem = inventory[slot]
    local bRecipeCheck = curItem:GetTypeID() ~= item:GetTypeID() or curItem:IsRecipe()
    if curItem:GetTypeID() == item:GetTypeID() and not bRecipeCheck then
      return true
    end
  end
  return false
end

-- example Dawnbringer
-- returns a list where components of firesword is first, then recipe for it
-- then frost swords components following that is the recipe for it and same for lightbringer
local function RemainingComponentsOfItem(unit, item)
  --Echo(tostring(item:GetTypeID()) ..  '\n')
  if HasItem(unit, item) then
    return {}
  end
  local components = item:GetComponents()
  local numOfComponents = #components
  local finalComponents = {}

  for slot = 1, numOfComponents, 1 do
    local curComponent = components[slot]
    --Echo(tostring(curComponent:GetTypeID() == item:GetTypeID()))
    if not (curComponent:GetTypeID() == item:GetTypeID()) and IsRecipe(curComponent) then
      local componentsRecursion = RemainingComponentsOfItem(unit, curComponent)
      local num = #componentsRecursion

      for recurComp = 1, numOfComponents, 1 do
        local this = componentsRecursion[recurComp]
        if not (curComponent:GetTypeID() == item:GetTypeID()) then
          tinsert(finalComponents, this)
        end
      end
      --Echo(curComponent:GetName() .. " -> " .. ItemArrayToString(finalComponents))
    else
      tinsert(finalComponents, curComponent)
    end
  end
  
  local finalNum = #finalComponents

  for slot = 1, finalNum, 1 do
    local curComponent = finalComponents[slot]
    if HasItem(unit, curComponent) then
      tremove(finalComponents,curComponent)
    end
  end
  return finalComponents
end

local function GetNextComponent(unit, item)
  local RemainingComponents = RemainingComponentsOfItem(unit, item)
  local numOfComponents = #RemainingComponents
  if numOfComponents == 0 then
    return nil
  end
  return RemainingComponents[1]
end

function ShopUtils()
  local functions = {}
  functions.HasItem = HasItem
  functions.HasItemsInInventory = HasItemsInInventory
  functions.GetNextComponent = GetNextComponent
  functions.ItemArrayToString = ItemArrayToString
  functions.RemainingComponentsOfItem = RemainingComponentsOfItem
  functions.IsRecipe = IsRecipe
  return functions
end 
