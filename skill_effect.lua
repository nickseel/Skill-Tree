
require("ability_listener")

--base abstract skill effect
SkillEffect = {}
function SkillEffect:new(subclass)
  local t = setmetatable({}, { __index = SkillEffect })
  
  t.values = {}
  t.active = false
  
  return t
end
function SkillEffect:initEffect() end
function SkillEffect:activateEffect() self.active = true end
function SkillEffect:deactivateEffect() self.active = false end
function SkillEffect:setValues(values) self.values = values end


--test skill effect, prints its value
TestSkillEffect = SkillEffect:new(true)
function TestSkillEffect:new(subclass)
  local t = setmetatable({}, { __index = TestSkillEffect })
  
  t.values = {0}
  
  if(not subclass) then t:initEffect() end
  return t
end
function TestSkillEffect:initEffect()
  registercallback("onStep", function()
    if(self.active) then
      Cyclone.terminal.write("test skill: "..tostring(self.values[1]))
    end
  end)
end
function TestSkillEffect:setValues(values)
  self.values = values
  self.active = (self.values[1] > 0)
end


--flat health bonus
FlatHealthSkillEffect = SkillEffect:new(true)
function FlatHealthSkillEffect:new(player_id, subclass)
  local t = setmetatable({}, { __index = FlatHealthSkillEffect })
  
  t.values = {0}
  t.prev_values = {0}
  t.player_id = player_id
  
  if(not subclass) then t:initEffect() end
  return t
end
function FlatHealthSkillEffect:setValues(values)
  self.prev_values = self.values
  self.values = values
  
  local player = Object.findInstance(self.player_id)
  local _prev_maxhp = player:get("maxhp_base")
  local _new_maxhp = _prev_maxhp + (self.values[1] - self.prev_values[1])
  
  local _prev_hp = player:get("hp")
  local _new_hp = min(_prev_hp, _new_maxhp)
  
  player:set("maxhp_base", _new_maxhp)
  player:set("maxhp", _new_maxhp)
  player:set("hp", _new_hp)
end


--change damage of one ability by a percentage (value of 0.5 = 50% damage increase)
ProjectileDamageSkillEffect = SkillEffect:new(true)
function ProjectileDamageSkillEffect:new(player_id, skill_index, subclass)
  local t = setmetatable({}, { __index = ProjectileDamageSkillEffect })
  
  t.values = {0}
  t.active = false
  t.player_id = player_id
  t.skill_index = skill_index or 0

  if(not subclass) then t:initEffect() end
  return t
end
function ProjectileDamageSkillEffect:initEffect()
  registercustomcallback("onAbilityDamager", function(player, skill_index, damager)
    if self.active and skill_index == self.skill_index and player:get("id") == self.player_id then
      local _prev_damage = damager:get("damage")
      local _prev_damage_fake = damager:get("damage_fake")
      local _new_damage = _prev_damage * (1 + self.values[1])
      local _new_damage_fake = _prev_damage_fake * (1 + self.values[1])
      damager:set("damage", _new_damage)
      damager:set("damage_fake", _new_damage_fake)
    end
  end)
end
function ProjectileDamageSkillEffect:setValues(values)
  self.values = values
  self.active = (self.values[1] > 0)
end


--increases speed during player ability (value of 0.5 = 50% speed increase)
--note: speed artifact breaks this so must be disabled
Artifact.find("Spirit").disabled = true
MoveSpeedDuringAbilitySkillEffect = SkillEffect:new(true)
function MoveSpeedDuringAbilitySkillEffect:new(player_id, skill_index, subclass)
  local t = setmetatable({}, { __index = MoveSpeedDuringAbilitySkillEffect })
  
  t.values = {0}
  t.active = true
  t.player_id = player_id
  t.skill_index = skill_index or 0
  
  t.prev_speed = 0

  if(not subclass) then t:initEffect() end
  return t
end
function MoveSpeedDuringAbilitySkillEffect:initEffect()
  --[[registercallback("onPlayerStep", function(player)
    Cyclone.terminal.write(player:get("pHmax"))
  end)]]
  registercustomcallback("startAbility", function(player, skill_index)
    if self.active and skill_index == self.skill_index and player:get("id") == self.player_id then
      self.prev_speed = player:get("pHmax")
      player:set("pHmax", self.prev_speed * (1 + self.values[1]))
      --Cyclone.terminal.write(player:get("pHmax"))
    end
  end)
  registercustomcallback("endAbility", function(player, skill_index)
    if self.active and skill_index == self.skill_index and player:get("id") == self.player_id then
      player:set("pHmax", self.prev_speed)
      --Cyclone.terminal.write(player:get("pHmax"))
    end
  end)
end


--reduces ability cooldown on kill (value of 0.2 = 20% cooldown refunded)
AbilityResetOnKillSkillEffect = SkillEffect:new(true)
function AbilityResetOnKillSkillEffect:new(player_id, skill_index, subclass)
  local t = setmetatable({}, { __index = AbilityResetOnKillSkillEffect })
  
  t.values = {0}
  t.active = true
  t.player_id = player_id
  t.skill_index = skill_index or 0

  if(not subclass) then t:initEffect() end
  return t
end
function AbilityResetOnKillSkillEffect:initEffect()
  --[[registercallback("onPlayerStep", function(player)
    Cyclone.terminal.write(player:get("pHmax"))
  end)]]
  registercallback("onNPCDeathProc", function(npc, player)
    if self.active and player:get("id") == self.player_id then
      local prev_timer_value = player:getAlarm(self.skill_index + 1)
      local new_timer_value = math.floor(prev_timer_value * (1 - self.values[1]))
      player:setAlarm(self.skill_index+1, new_timer_value)
      --Cyclone.terminal.write(player:get("pHmax"))
    end
  end)
end


--restores health on a crit. can be flat healing, pct healing, or pct missing health healing
HealOnCritSkillEffect = SkillEffect:new(true)
function HealOnCritSkillEffect:new(player_id, flat_healing, missing_healing, subclass)
  local t = setmetatable({}, { __index = HealOnCritSkillEffect })
  
  t.values = {0}
  t.active = false
  t.player_id = player_id
  t.flat_healing = flat_healing or false
  t.missing_healing = missing_healing or false
  
  t.frame_healing = 0
  t.heal_remainder = 0

  if(not subclass) then t:initEffect() end
  return t
end
function HealOnCritSkillEffect:initEffect()
  registercallback("onHit", function(damager, hit, x, y)
    if self.active and damager:get("parent") == self.player_id then
      if damager:get("critical") == 1 then
        local player = Object.findInstance(self.player_id)
        
        local heal = 0
        if self.flat_healing then
          heal = self.values[1]
        else
          if self.missing_healing then
            heal = (player:get("maxhp") - player:get("hp")) * self.values[1]
          else
            heal = player:get("maxhp") * self.values[1]
          end
        end
        self.frame_healing = self.frame_healing + heal
      end
    end
  end)
  registercallback("onStep", function()
    self.frame_healing = self.frame_healing + self.heal_remainder
    self.heal_remainder = self.frame_healing - math.floor(self.frame_healing)
    self.frame_healing = math.floor(self.frame_healing)
    
    if(self.frame_healing > 0) then
      local player = Object.findInstance(self.player_id)
      player:set("hp", player:get("hp") + math.min(player:get("maxhp"), self.frame_healing))
      misc.damage(self.frame_healing, player.x, player.y-15, false, Color.DAMAGE_HEAL)
    end
    
    self.frame_healing = 0
  end)
end
function HealOnCritSkillEffect:setValues(values)
  self.values = values
  self.active = (self.values[1] > 0)
end