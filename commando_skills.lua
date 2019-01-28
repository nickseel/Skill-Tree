
require("ability_listener")
require("skill_effect")

--[[
  ideas:
    suppressive fire lasts longer
    suppressive fire lasts until you release key
    bonus attack speed at low health
    suppressive fire is faster
]]

function CommandoSkillTree(player_id)
  addSurvivorAbilityData("Commando", {
    {CALLBACK_FIRE, {CHECK_DAMAGE, function(damage) return math.ceil(damage/2) end, 0.0},
                    {CHECK_ATTRIBUTE, "stun", --[[expected:]]0, --[[error:]]0.0}}, --z ability
                  
    {CALLBACK_HIT,  {CHECK_DAMAGE, function(damage) local a = ((damage * 11) / 6) + 0.5 if damage % 2 == 0 then a = a + 0.5 end return a end, 0.0},
                    {CHECK_ATTRIBUTE, "knockback", --[[expected:]]6, --[[error:]]0.0}}, --x ability
                  
    {}, --c ability
    
    {CALLBACK_HIT,  {CHECK_DAMAGE, function(damage) return math.ceil(damage/2) end, 0.0},
                    {CHECK_ATTRIBUTE, "stun", --[[expected:]]0.5, --[[error:]]0.0}}, --v ability
  })
  
  local skilltree = SkillTree:new()
  
  local sk_crit_healing = Skill:new("Crit Healing (title wip)",
      "Critical hits heal for &y&|0|&!& of missing health.",
      {{"2%%", "3.5%%", "5%%"}}, 3,
      nil, {HealOnCritSkillEffect:new(player_id, false, true)},
      {{{0},{0.02},{0.035},{0.05}}}, 
      0.5, 0)
  
  local sk_crit_damage = Skill:new("Lethal Precision",
      "Critical hits deal &y&|0|&!& extra damage. (&y&|1|&!& damage total)",
      {{"10%%", "20%%", "30%%", "40%%", "50%%"}, {"210%%", "220%%", "230%%", "240%%", "250%%"}}, 5,
      nil, {CritDamageSkillEffect:new(player_id)},
      {{{0},{0.1},{0.2},{0.3},{0.4},{0.5}}},
      2.5, 0)
  
  local sk_health = Skill:new("Resilient",
      "Increases max health by &y&|0|.&!&",
      {{"50", "100", "150", "200", "250"}}, 5,
      "health", {FlatHealthSkillEffect:new(player_id)},
      {{{0},{50},{100},{150},{200},{250}}}, 
      1.5, 0)
  
  local sk_attack_speed = Skill:new("Itchy Trigger Finger",
      "Increases attack speed by &y&|0|.&!&",
      {{"7%%", "14%%", "21%%", "28%%", "35%%"}}, 5,
      "health", {AttackSpeedSkillEffect:new(player_id)},
      {{{0},{0.07},{0.14},{0.21},{0.28},{0.35}}}, 
      3.5, 0)
  
  local sk_damage_fmj = Skill:new("More Metal Jackets",
      "increases &or&Full Metal Jacket&!& damage by &y&|0|.&!&",
      {{"1.15x", "1.3x", "1.45x", "1.6x"}}, 4,
      "skill", {AbilityDamageSkillEffect:new(player_id, 2)},
      {{{0},{.15},{.3},{.45},{.6}}}, 
      0, 1)
  
  local sk_roll_speed = Skill:new("Rounder Knees",
      "Increases distance travelled while in &or&Tactical Dive&!& by &y&|0|.&!&",
      {{"1.3x", "1.6x"}}, 2,
      nil, {MoveSpeedDuringAbilitySkillEffect:new(player_id, 3)},
      {{{0},{0.3},{0.6}}},
      1, 1)
  
  local sk_roll_cd = Skill:new("Acrobatics",
      "On kill, refunds &y&|0|&!& of &or&Tactical Dive's&!& remaining cooldown,\nbut the base cooldown is &y&|1|&!& longer.",
      {{"25%%", "50%%", "100%%"}, {"1.5x", "2.0x", "3.0x"}}, 3,
      nil, {AbilityResetOnKillSkillEffect:new(player_id, 3), AbilityCooldownSkillEffect:new(player_id, 3)},
      {{{0},{0.25},{0.5},{1.0}}, {{0},{0.5},{1.0},{2.0}}},
      2, 1)
  
  local sk_point_blank_fmj = Skill:new("Point Blank",
      "&or&Full Metal Jacket&!& always crits at very close range.",
      {}, 1,
      nil, {PointBlankFMJSkillEffect:new(player_id, 2)}, {{{0},{20}}},
      1.5, 2)
  
  local sk_attack_speed_for_crit = Skill:new("Steady Aim",
      "Attack speed is permanently cut by &y&|0|,&!& but &or&Double Tap&!& and\n&or&Suppressive Fire&!& always crit.",
      {{"45%%"}}, 1,
      nil, {PersistentAttackSpeedSkillEffect:new(player_id), AlwaysCritSkillEffect:new(player_id, 1, 4)},
      {{{0},{-0.45}}, {{0},{1}}},
      1, 3)
    
  
  --skill_test:addChildren(skill_roll_speed)
  --skill_health:addChildren(skill_roll_speed, skill_5)
  --skill_5:addChildren(skill_6)
  
  skilltree:addSkill(sk_crit_healing)
  skilltree:addSkill(sk_crit_damage)
  skilltree:addSkill(sk_health)
  skilltree:addSkill(sk_attack_speed)
  skilltree:addSkill(sk_damage_fmj)
  skilltree:addSkill(sk_roll_speed)
  skilltree:addSkill(sk_roll_cd)
  skilltree:addSkill(sk_point_blank_fmj)
  skilltree:addSkill(sk_attack_speed_for_crit)
  skilltree:refresh()
  
  return skilltree
end



--
--        COMMANDO SPECIFIC SKILL EFFECTS
--
--full metal jacket will always crit at close range
PointBlankFMJSkillEffect = SkillEffect:new(true)
function PointBlankFMJSkillEffect:new(player_id, skill_index, subclass)
  local t = setmetatable({}, { __index = PointBlankFMJSkillEffect })
  
  t.values = {0}
  t.active = false
  t.player_id = player_id
  t.skill_index = skill_index or 0

  if(not subclass) then t:initEffect() end
  return t
end
function PointBlankFMJSkillEffect:initEffect()
  registercustomcallback("onAbilityDamager", function(player, skill_index, damager)
    if self.active and skill_index == self.skill_index and player:get("id") == self.player_id then
      if damager:get("critical") == 0 then
        --dont modify if it was already a crit
        damager:set("FMJ_start_x", player.x)
      end
    end
  end)
  registercallback("onHit", function(damager, hit, x, y)
    if damager:get("FMJ_start_x") ~= nil then
      local dist = math.abs(damager:get("FMJ_start_x") - x)
      local player = Object.findInstance(self.player_id)
      
      if dist < self.values[1] then
        if damager:get("critical") == 0 then
          damager:set("critical", 1)
          damager:set("damage", damager:get("damage") * player:get("critical_damage"))
          damager:set("damage_fake", damager:get("damage_fake") * player:get("critical_damage"))
        end
      else
        if damager:get("critical") == 1 then
          damager:set("critical", 0)
          damager:set("damage", damager:get("damage") / player:get("critical_damage"))
          damager:set("damage_fake", damager:get("damage_fake") / player:get("critical_damage"))
        end
      end
    end
  end)
end
function PointBlankFMJSkillEffect:setValues(values)
  self.values = values
  self.active = (self.values[1] > 0)
end