--[[
	国战技能速查手册（E区）
	技能索引：
	恩怨、
]]--

--[[
	恩怨
	相关武将：身份-法正
	描述：每当你获得一名其他角色的至少两张牌时，你可以令其摸一张牌；每当你受到1点伤害后，你可以令来源选择一项：1.将一张手牌交给你；2.失去1点体力。
	引用：
	状态：1.2.0 验证通过
]]

luaenyuan = sgs.CreateTriggerSkill{
	name = "luaenyuan",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.Damaged},
	
	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
		if event == sgs.Damaged then
			local trigger_list, damage = {}, data:toDamage()
			if damage.from and damage.from:isAlive() then
				for i = 1, damage.damage do
					table.insert(trigger_list, self:objectName())
				end
			end
			return table.concat(trigger_list, ",")
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() == player:objectName() and move.from and move.from:isAlive() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)
					and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE then
				if move.card_ids:length() >= 2 then return self:objectName() end
			end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), (event == sgs.Damaged and 2 or 1), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local card = room:askForExchange(damage.from, self:objectName(), 1, false, self:objectName().."Give::"..player:objectName(), true)
			if card then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, damage.from:objectName(), player:objectName(), self:objectName(), "")
				room:obtainCard(player, card, reason, true)
			else
				room:loseHp(damage.from)
			end
		elseif event  == sgs.CardsMoveOneTime then
			local move, source = data:toMoveOneTime()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:objectName() == move.from:objectName() then source = p end
			end
			if source then source:drawCards(1, self:objectName()) end
		end
		return false 
	end,
}