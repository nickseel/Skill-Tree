
function CommandoSkillTree()
  local skilltree = SkillTree:new()
  
  local skill_test = Skill:new("fun skill",
      "&y&increase fun by |0|,\nand decrease enemy fun by |1|.&!&",
      {{"10%%", "20%%", "30%%"}, {"15%%", "35%%", "90%%"}}, 3,
      nil, TestSkillEffect.new(), {{0},{1},{2},{3}}, 
      0.5, 0)
  
  local skill_health = Skill:new("Bonus Health",
      "increases max health by &y&|0|.&!&",
      {{"50", "100", "150", "200", "250"}}, 5,
      "health", FlatHealthSkillEffect.new(), {{0},{50},{100},{150},{200},{250}}, 
      1.5, 0)
  
  local skill_damage_x = Skill:new("More Metal Jackets",
      "increases &or&Full Metal Jacket&!& damage by &y&|0|.&!&",
      {{"1.5x", "2.0x", "2.5x"}}, 3,
      "skill", ProjectileDamageSkillEffect:new("commando", 2, 1.833333), {{0},{.5},{1},{1.5}}, 
      0, 1)
  
  local skill_4 = Skill:new("test4",
      "test desc 4 |0|, and more info here |1|.",
      {{"10%%", "20%%", "30%%"}, {"15%%", "35%%", "90%%"}}, 3,
      nil, nil, nil, 1, 1)
  
  local skill_5 = Skill:new("test5",
      "test desc 5 |0|, and more info here |1|.",
      {{"10%%", "20%%", "30%%"}, {"15%%", "35%%", "90%%"}}, 3,
      nil, nil, nil, 2, 1)
  
  local skill_6 = Skill:new("test6",
      "test desc 6 |0|, and more info here |1|.",
      {{"10%%", "20%%", "30%%"}, {"15%%", "35%%", "90%%"}}, 3,
      nil, nil, nil, 1.5, 2)
  
  skill_test:addChildren(skill_4)
  skill_health:addChildren(skill_4, skill_5)
  skill_5:addChildren(skill_6)
  
  skilltree:addSkill(skill_test)
  skilltree:addSkill(skill_health)
  skilltree:addSkill(skill_damage_x)
  skilltree:addSkill(skill_4)
  skilltree:addSkill(skill_5)
  skilltree:addSkill(skill_6)
  skilltree:refresh()
  
  return skilltree
end