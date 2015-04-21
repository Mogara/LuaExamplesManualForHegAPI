--[[
	国战技能速查手册（M区）
	技能索引：
	马术、猛进、名士
]]--
--[[
	马术
	相关武将：标-马超、标-庞德、标-马腾、势-马岱
	描述：锁定技，你与其他角色的距离-1。     
	引用：
	状态：
]]

LuaMashu = sgs.CreateDistanceSkill{
	name = "LuaMashu",
	correct_func = function(self, from, to)
		if from:hasSkill("LuaMashu") and from:hasShownSkill(self:objectName()) then
			return -1
		end
	end,
}

--[[
	猛进
	相关武将：标-庞德
	描述：每当你使用的【杀】被目标角色使用的【闪】抵消时，你可以弃置其一张牌。    
	引用：
	状态：
]]
--[[
	名士
	相关武将：标-孔融
	描述：锁定技，每当你受到伤害时，若来源有暗置的武将牌，你令此伤害-1。     
	引用：
	状态：
]]
