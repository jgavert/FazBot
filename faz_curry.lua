local _G = getfenv(0)
local herobot = _G.object

herobot.heroName = 'Hero_Vanya'

-- EXPERIMENTAL --
runfile 'bots/utils/shoputils/shop_utils.lua'
-- EXPERIMENTAL --
local ShopFns = ShopUtils()

runfile 'bots/core_herobot.lua'
runfile 'bots/utils/inventory.lua'
local InventoryFns = Utils_Inventory
runfile 'bots/utils/drawings.lua'
local DrawingsFns = Utils_Drawings
runfile 'bots/utils/chat.lua'
local ChatFns = Utils_Chat
runfile 'bots/utils/courier_controlling.lua'
local CourierControlling = Utils_CourierControlling
runfile 'bots/utils/metadata_manager.lua'
local MetadataManager = Utils_MetadataManager
runfile "bots/utils/masks.lua"
local MASKS = Utils_Masks
runfile "bots/utils/priority_actions.lua"
local PriorityActions = Utils_PriorityActions
runfile "bots/utils/warding.lua"
local Warding = Utils_Warding
runfile "bots/utils/rune_control.lua"
local RuneControl = Utils_RuneControl

local print, tostring, tremove = _G.print, _G.tostring, _G.table.remove

herobot.brain.goldTreshold = 0

herobot.data.canUpgradeCourier = true
herobot.data.creepWavePos = nil
herobot.data.currentAction = nil


--------------------------------------------------
--            Hero skill and buylist            --
--------------------------------------------------

local levelupOrder = {1, 2, 1, 0, 1,
                      0, 1, 0, 0, 2,
                      2, 2, 4, 3, 3,
                      3, 4, 4, 4, 4,
                      4, 4, 4, 4, 4}

local itemsToBuy = {
  'Item_MinorTotem',
  'Item_MinorTotem',
  'Item_MinorTotem',
  'Item_MinorTotem',
  'Item_MinorTotem',
  'Item_MinorTotem',
  'Item_Steamboots',
  'Item_LifeSteal5',
  'Item_Dawnbringer',
  'Item_Lightning2',
  'Item_DaemonicBreastplate',
  'Item_Immunity',
  'Item_Pierce',
  'Item_Pierce',
  'Item_Pierce',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer',
  'Item_Dawnbringer'
}

-- UNUSED ITEMLISTS
local potentialItems = {
  'Item_Gloves3',
  'Item_Evasion',
  'Item_Brutalizer',
  'Item_Pierce'
}

local buffItems = {
  'Item_LifeSteal5',
  'Item_DaemonicBreastplate'
}

local carryItems = {
  'Item_Dawnbringer',
  'Item_Lightning2',
  'Item_Immunity'
}


function herobot:SkillBuildWhatNext()
  --herobot.chat:AllChat("Leveled up! My team was " .. herobot.brain.hero:GetTeam())
  local nlev = self.brain.hero:GetLevel()
  return self.brain.hero:GetAbility( levelupOrder[nlev] )
end

--local nextChat = HoN.GetGameTime() + 1000

local tpStone = HoN.GetItemDefinition("Item_HomecomingStone")

--------------------------------------------------
--              Item Handling code              --
--------------------------------------------------
local function getNextItemToBuy()
  return HoN.GetItemDefinition(itemsToBuy[1]) or tpStone
end

-- Update the treshold for when to buy next, what will be the money treshold?
local function updateTreshold(bot)
  local nextItem = getNextItemToBuy()
  --Echo(nextItem:GetName())
  local nextComponent = ShopFns.GetNextComponent(herobot.brain.hero, nextItem)
  if not nextComponent then
    tremove(itemsToBuy, 1)
    if ShopFns.hasFullInventory(herobot.brain.hero) then
      herobot.invfull = true
    else
      herobot.invfull = false
    end
    updateTreshold(bot)
    return 
  end
  local costOfComponent = nextComponent:GetCost()
  bot.brain.goldTreshold = costOfComponent -- nextItem:GetCost()
  --bot.brain.goldTreshold = 99999999999 -- nextItem:GetCost()
end

-- buys the item and sells the lowest cost items to make room if full
function herobot:PerformShop()
  --Checks if the stash is full and sells cheapest thing from there if its full
  if ShopFns.hasFullInventory(herobot.brain.hero, true) then
    Echo("Lets keep the stash spacey")
    ShopFns.sellCheapestItem(herobot.brain.hero, {"Item_Steamboots"}, true) -- not really tested code, sellCheapestItem supports ignorelist
  end

  --Checks for were we just initialized
  if not self.wasInitialized then
    Echo("WARNING BOT WAS RELOADED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    --Echo("WARNING BOT WAS RELOADED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    --Echo("WARNING BOT WAS RELOADED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    --Echo("Before update: " .. ShopFns.StringArrayToString(itemsToBuy))
    itemsToBuy = ShopFns.checkInventory(herobot.brain.hero, itemsToBuy)
    --Echo("After update: " .. ShopFns.StringArrayToString(itemsToBuy))
    self.wasInitialized = true
  end
  -- Lets get the next item to buy
  local hero = self.brain.hero
  local nextItem = nil

  if #itemsToBuy == 0 then
    Echo("Nothing to buy!")
    return
  else
    nextItem = getNextItemToBuy()
  end

  -- Lets get the component (WHICH CAN BE NULL for reasons I cannot remember)
  local nextComponent = ShopFns.GetNextComponent(herobot.brain.hero, nextItem)
  -- handle null case, which basically means that nextItem is already done
  if not nextComponent then
    updateTreshold(self) -- updateTreshold basically handles this case which is why we call it here
    return 
  end

  --Echo("My next item is " .. nextItem:GetName())
  local remainingitems = ShopFns.RemainingComponentsOfItem(herobot.brain.hero, nextItem)
  local componentsString = ShopFns.ItemArrayToString(remainingitems)
  --Echo("Remaining components: "  .. componentsString)

  -- Handle if our backpack was full of completed items, logic behind this is that when we finish a big item, we check if the backpack was full. We only want to sell when we are buying.
  if herobot.invfull then
    Echo("Sold item!")
    ShopFns.sellCheapestItem(herobot.brain.hero, {"Item_Steamboots"}) -- not really tested code, sellCheapestItem supports ignorelist, here we prevent selling steamboots.
    herobot.invfull = false --after selling, set invfull to false
  end
  hero:PurchaseRemaining(nextComponent)

  -- Here we see if the item had only 1 component, we can remove it from the itemsToBuy list because we already purchased it. Check immideatly for fullinv. 
  if #remainingitems == 1 then
    tremove(itemsToBuy, 1)
    -- I think I have this in too many places....
    if ShopFns.hasFullInventory(herobot.brain.hero) then
      herobot.invfull = true
    else
      herobot.invfull = false
    end
  end

  -- Lastly update treshold to next component price.
  updateTreshold(self)
  --Echo("My current treshold: " .. tostring(self.brain.goldTreshold))
end



--------------------------------------------------
--                     UTILS                    --
--------------------------------------------------

local function canSeeEnemy(bot)
  local localUnitsSorted = bot:GetLocalUnitsSorted()
  local neutrals = localUnitsSorted.Neutrals
  --local enemies = localUnitsSorted.EnemyUnits
  local enemycreeps = localUnitsSorted.EnemyCreeps
  local enemyheroes = localUnitsSorted.EnemyHeroes
  local tBuildings = localUnitsSorted.EnemyBuildings
  --local tBuildings = HoN.GetUnitsInRadius(bot.brain.hero:GetPosition(), 900, 0x0000020 + 0x0000002)
  --for key, _ in pairs(localUnitsSorted) do
  --  Echo(tostring(key))
  --end
  for uid, unit in pairs(enemycreeps) do
    if unit:IsAlive() and unit:IsValid() then
      return true
    end
  end
  for uid, unit in pairs(enemyheroes) do
    if unit:IsAlive() and unit:IsValid() then
      return true
    end
  end
  for uid, unit in pairs(tBuildings) do
    --DrawingsFns.DrawX(unit:GetPosition(), "blue")
    if not (unit:GetTeam() == bot:GetTeam()) and not (unit:GetTeam() == 255) then
      DrawingsFns.DrawArrow(bot.brain.hero:GetPosition(), unit:GetPosition(), "olive")
      --Echo("This building is on team: " .. tostring(unit:GetTeam()))
      return true
    end
  end
  for uid, unit in pairs(neutrals) do
    if unit:IsAlive() and unit:IsValid() then
      return true
    end
  end
  return false
end

function herobot:PrintStates()
  local unit = self.brain.hero
  local behavior = unit:GetBehavior()
  if behavior then
    --Echo(behavior:GetType())
  end
end

local function printInventory(inventory)
  for i = 1, 12, 1  do
    local curItem = inventory[i]
    if curItem then
      print(tostring(i)..', '..curItem:GetName()..'\n')
    else
      print(tostring(i)..', nil\n')
    end
  end
end

--------------------------------------------------
--                    onThink                   --
--------------------------------------------------

function herobot:onthinkCustom(tGameVariables)
  --Echo("Alive!")
  --if not self.brain.myLane then
  --  self.brain.myLane = self.metadata:GetMiddleLane()
  --end,
   if not assignedToTeam then
     self.teamBrain:AddHero(self)
     assignedToTeam = true
   end 
  CourierControlling.onthink(self.teamBrain, self)
  if not self:IsDead() then

    local easyCamp = Vector3.Create(7547.6655, 7550.0581, 0.0)
    if self:GetTeam() == 1 then
      easyCamp = Vector3.Create(13000.6655, 13000.0581, 0.0)
    else
      easyCamp = Vector3.Create(2000.6655, 2000.0581, 0.0)
    end
    --DrawXPosition(easyCamp)
    local myPos = self.brain.hero:GetPosition()

    --Echo("amount of enemies " .. tostring(#enemies))
    if Vector3.Distance2DSq(myPos, easyCamp) < 300*300 or canSeeEnemy(self) then
      if not self:Harass() then 
        self:MoveToEasyCamp()
      end
    else
      self:MoveToEasyCamp()
    end
  end
  --self:PrintStates()
end


--------------------------------------------------
--                    "Harass"                  --
--------------------------------------------------

local function giveAll(bot, target)
  --Echo("Giving all")
  --local beha = bot.brain.hero:GetBehavior()
  --if beha then
    --Echo("Beha in use: "..beha:GetType())
  --  if beha:GetType() == "Attack" then
      --Echo("not giving")
  --    return
  --  end
  --end
  DrawingsFns.DrawArrow(bot.brain.hero:GetPosition(), target:GetPosition())
  if not target:IsBuilding() then
    local skills = bot.brain.skills
    if skills.abilW:CanActivate() then
      bot:OrderAbilityEntity(skills.abilW, target)
      return
    elseif skills.abilQ:CanActivate() then
      bot:OrderAbility(skills.abilQ)
      return
    elseif skills.abilE:CanActivate() then
      bot:OrderAbilityPosition(skills.abilE, target:GetPosition())
      return
    end
  end
  bot:OrderEntity(bot.brain.hero, "Attack", target)
end

function herobot:Harass()
  local localUnitsSorted = self:GetLocalUnitsSorted()
  local neutrals = localUnitsSorted.Neutrals
  --local enemies = self:GetLocalUnitsSorted().EnemyUnits
  local enemycreeps = localUnitsSorted.EnemyCreeps
  local enemyheroes = localUnitsSorted.EnemyHeroes

  local target = nil
  local lastRange = 9999

  local tBuildings = localUnitsSorted.EnemyBuildings
  --local tBuildings = HoN.GetUnitsInRadius(self.brain.hero:GetPosition(), 900, 0x0000020 + 0x0000002)

  for key, unitBuilding in pairs(tBuildings) do
    if not (unitBuilding:GetTeam() == self:GetTeam()) then
      target = unitBuilding
    end
  end
  for uid, unit in pairs(neutrals) do
    --DrawXPosition(unit:GetPosition())
  --  if unit and not unit.GetTeam() == self then
    if unit:IsAlive() then
      target = unit
    end
  --    break;
  --  end
  end
  local lastRangeHero = nil
  for uid, unit in pairs(enemycreeps) do
    --DrawXPosition(unit:GetPosition())
    local nRange = Vector3.Distance2D(self.brain.hero:GetPosition(), unit:GetPosition())
    if lastRange == nil then
      target = unit
      lastRange = nRange
    elseif nRange < lastRange then
      target = unit
      lastRange = nRange
    end
  end
  for uid, unit in pairs(enemyheroes) do
    --DrawXPosition(unit:GetPosition())
    local nRange = Vector3.Distance2D(self.brain.hero:GetPosition(), unit:GetPosition())
    if lastRangeHero == nil then
      target = unit
      lastRangeHero = nRange
    elseif nRange < lastRangeHero then
      target = unit
      lastRangeHero = nRange
    end
  end
  if target then
    --self.LastTarget = target
    --DrawingsFns.DrawArrow(self.brain.hero:GetPosition(), target:GetPosition(), 'olive')
    --ChatFns.AllChat(self,"My target is" .. target:GetTypeName())
    giveAll(self, target)
    return true
  end
  return false
end


function herobot:MoveToEasyCamp()
  --local easyCamp = Vector3.Create(7847.6655, 5150.0581, 0.0)
  local easyCamp = Vector3.Create(7500.6655, 7500.0581, 0.0)
  if self:GetTeam() == 1 then
    easyCamp = Vector3.Create(13000.6655, 13000.0581, 0.0)
  else
    easyCamp = Vector3.Create(2000.6655, 2000.0581, 0.0)
  end
  local myPos = self.brain.hero:GetPosition()
  local tBuildings = HoN.GetUnitsInRadius(myPos, 210, 0x0000020 + 0x0000002)
  --local creepsInPosition = self:GetCreepPosOnMyLane()
  

  --DrawXPosition(myPos)

  for _, unitBuilding in pairs(tBuildings) do
    local unitPos = unitBuilding:GetPosition()
    --DrawXPosition(unitPos)
    --DrawArrowPos2Pos(unitPos, myPos, "green")
    local mehilainen = Vector3.Normalize(easyCamp - myPos) * 200 + Vector3.Normalize(myPos - unitPos)*160 + myPos
    DrawingsFns.DrawArrow(myPos, mehilainen, "blue")
    self:OrderPosition(self.brain.hero, "Move", mehilainen)
    return
  end

  self:OrderPosition(self.brain.hero, "Move", easyCamp)
end


