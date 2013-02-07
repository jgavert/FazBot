local _G = getfenv(0)
local herobot = _G.object

herobot.heroName = 'Hero_Vanya'

runfile 'bots/core_herobot.lua'
runfile 'bots/utils/inventory.lua'
runfile 'bots/utils/drawings.lua'
runfile 'bots/utils/chat.lua'
runfile 'bots/utils/courier_deliver.lua'
runfile 'bots/utils/courier_upgrader.lua'

local ChatFns = ChatUtils()
local DrawingsFns = Drawings()
local CourierDeliverFns = CourierDeliver()
local CourierUpgraderFns = CourierUpgrader()

local print, tostring, tremove = _G.print, _G.tostring, _G.table.remove

herobot.brain.goldTreshold = 0

local itemsToBuy = {
  'Item_MarkOfTheNovice'
}

local tpStone = HoN.GetItemDefinition("Item_HomecomingStone")
local function getNextItemToBuy()
  return HoN.GetItemDefinition(itemsToBuy[1]) or tpStone
end


local levelupOrder = {1, 2, 1, 0, 1,
                      0, 1, 0, 0, 2,
                      2, 2, 4, 3, 3,
                      3, 4, 4, 4, 4,
                      4, 4, 4, 4, 4}

function herobot:SkillBuildWhatNext()
  --herobot.chat:AllChat("Leveled up! My team was " .. herobot.brain.hero:GetTeam())
  local nlev = self.brain.hero:GetLevel()
  return self.brain.hero:GetAbility( levelupOrder[nlev] )
end

local nextChat = HoN.GetGameTime() + 1000

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

function herobot:onthinkCustom(tGameVariables)
  --Echo("Alive!")
  --if not self.brain.myLane then
  --  self.brain.myLane = self.metadata:GetMiddleLane()
  --end
  if not self:IsDead() then

    --local easyCamp = Vector3.Create(7847.6655, 5150.0581, 0.0)
    local easyCamp = Vector3.Create(7500.6655, 7500.0581, 0.0)
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

function herobot:PerformShop()
--[[  if inventoryDebugPrint < HoN.GetGameTime() then
    self.teamBrain.courier:PurchaseRemaining(tpStone)
    local invTps = self.brain.hero:FindItemInInventory(tpStone:GetName())
    if invTps then
      Echo(tostring(#invTps))
    end
    if #invTps > 0 then
      local tp = invTps[1]
      Echo("courier can access: "..tostring(self.teamBrain.courier:CanAccess(tp)))
      Echo("Slot: "..tostring(tp:GetSlot()))
      self.teamBrain.courier:SwapItems(1, tp:GetSlot())
    end
    local inventory = self.brain.hero:GetInventory(true)
    printInventory(inventory)
    local inventory = self.teamBrain.courier:GetInventory(true)
    printInventory(inventory)
    inventoryDebugPrint = inventoryDebugPrint + 5000
    --self.brain.goldTreshold = self.brain.goldTreshold + 100
    --Echo("My current treshold: "..tostring(self.brain.goldTreshold))
  end ]]
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

function herobot:GetCreepPosOnMyLane()
  local lane = self.brain.myLane
  if not lane or #lane < 1 then
    Echo('No lane')
    return nil
  end
  return self.teamBrain:GetFrontOfCreepWavePosition(lane.laneName)
end

function herobot:PrintStates()
  local unit = self.brain.hero
  local behavior = unit:GetBehavior()
  if behavior then
    --Echo(behavior:GetType())
  end
end
