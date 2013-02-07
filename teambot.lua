local _G = getfenv(0)
local teambot = _G.object

teambot.name = 'Team Berberi'

runfile 'bots/core_teambot.lua'


function teambot:onthinkCustom(tGameVariables)
  --Echo(team.name..' is thinking')
end
