--[[
	国战技能速查手册（X区）
	技能索引：
	享乐、骁果、枭姬、行殇、雄异、恂恂
]]--
--[[
	享乐
	相关武将：标-刘禅
	描述：锁定技，每当你成为其他角色使用【杀】的目标时，你令该角色选择是否弃置一张基本牌，若其不如此做或其已死亡，此次对你结算的此【杀】对你无效。 
	引用：
	状态：
]]
--[[
	骁果
	相关武将：标-乐进
	描述：其他角色的结束阶段开始时，你可以弃置一张基本牌，令该角色选择一项：1.弃置一张装备牌；2.受到你造成的1点伤害。 
	引用：
	状态：
]]
--[[
	枭姬
	相关武将：标-孙尚香
	描述：每当你失去装备区里的装备牌后，你可以摸两张牌。 
	引用：
	状态：
]]
--[[
	行殇
	相关武将：标-曹丕
	描述：每当其他角色死亡时，你可以获得其所有牌。 
	引用：
	状态：
]]


luaXingshang = sgs.CreateTriggerSkill{
	name = "luaXingshang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Death},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() or player:isNude() then return false end
		return self:objectName()
	end,
	on_cost = function(self, event, room, player, data)
		return room:askForSkillInvoke(player, self:objectName(), data)
	end,
	
	on_effect = function(self, event, room, player, data)
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() or player:isNude() then return false end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcards(death.who:getCards("he"))
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
		room:obtainCard(player, dummy, reason, false)
		return false
	end,
}

--[[
	雄异
	相关武将：标-马腾
	描述：限定技，出牌阶段，你可以令与你势力相同的所有角色各摸三张牌，然后若你的势力是角色最少的势力，你回复1点体力。 
	引用：
	状态：
]]
--[[
	恂恂
	相关武将：势-李典
	描述：摸牌阶段开始时，你可以放弃摸牌，观看牌堆顶的四张牌，然后获得其中的两张牌，将其余的牌以任意顺序置于牌堆底。 
	引用：
	状态：
]]
