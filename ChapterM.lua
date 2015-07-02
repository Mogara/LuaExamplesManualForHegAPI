--[[
	国战技能速查手册（M区）
	技能索引：
	马术、猛进、秘计、名士
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

LuaMengjin = sgs.CreateTriggerSkill{
	name = "LuaMengjin",
	events = {sgs.SlashMissed},
	frequency = sgs.Skill_Frequent,

    can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local effect = data:toSlashEffect()
		if effect.to:isAlive() and player:canDiscard(effect.to, "he") then
			return self:objectName()
		end
	end,

	on_cost = function(self,event,room,pangde,data)
		local effect = data:toSlashEffect()
		if pangde:askForSkillInvoke(self:objectName(), data) then
			room:doAnimate(1, pangde:objectName(), effect.to:objectName())
			room:broadcastSkillInvoke(self:objectName(), pangde)
            return true
		end
	end,
	
    on_effect = function(self,event,room,pangde,data)
        local effect = data:toSlashEffect()
		local to_throw = room:askForCardChosen(pangde, effect.to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
		room:throwCard(sgs.Sanguosha:getCard(to_throw), effect.to, pangde)
	end,
}

--[[
	秘计
	相关武将：身份-王异
	描述：结束阶段开始时，若你已受伤，你可摸一至X张牌（X为你已损失的体力值），然后将等量的手牌交给其他角色。     
	引用：
	状态：1.2.0 验证通过
]]
luamiji = sgs.CreateTriggerSkill{
	name = "luamiji",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.ChoiceMade},
	
	on_record = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and event == sgs.ChoiceMade then
			local str = data:toString()
			if str:startsWith("Yiji:") then
				player:addMark(self:objectName(), #table.remove(str:split(":")):split("+"))
			end
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:isWounded() then return self:objectName() end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		player:setMark(self:objectName(), 0)
		local x = player:getLostHp()
		player:drawCards(x, self:objectName())
		while player:isAlive() and not player:isKongcheng() and x > player:getMark(self:objectName()) do
			room:askForYiji(player, player:handCards(), self:objectName(), false, false, false, x - player:getMark(self:objectName()), room:getOtherPlayers(player))
		end
		return false 
	end,
}

--[[
	名士
	相关武将：标-孔融
	描述：锁定技，每当你受到伤害时，若来源有暗置的武将牌，你令此伤害-1。     
	引用：
	状态：
]]

LuaMingshi = sgs.CreateTriggerSkill{
	name = "LuaMingshi",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local damage = data:toDamage()
		if damage.from and not damage.from:hasShownAllGenerals() then
			return self:objectName()
		end
	end,
	on_cost = function(self,event,room,player,data)
		local invoke = player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
		if invoke then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,

	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
        room:notifySkillInvoked(player, self:objectName())

		local log = sgs.LogMessage()
		log.type = "#Mingshi"
		log.from = player
		log.arg = damage.damage
		damage.damage = damage.damage - 1
		log.arg2 = damage.damage
		room:sendLog(log)

		if damage.damage < 1 then
			return true
		end
        data:setValue(damage)
	end,
}
