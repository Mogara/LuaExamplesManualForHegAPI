--[[
	国战技能速查手册（C区）
	技能索引：
	称象、穿心、存嗣
]]--

--[[
	称象
	相关武将：身份-曹冲
	描述：每当你受到伤害后，你可以亮出牌堆顶的四张牌。若如此做，你获得其中任意张点数之和不大于13的牌，然后将其余的牌置入弃牌堆。
	引用：
	状态：
]]

LuaChengxiang = sgs.CreateTriggerSkill{
	name = "LuaChengxiang",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.Damaged,
	
	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local card_ids = room:getNCards(4)
		room:fillAG(card_ids)
		local to_get, to_throw = sgs.IntList(), sgs.IntList()
		local sum = 0
		while sum <= 13 and not card_ids:isEmpty() do
			local card_id = room:askForAG(player, card_ids, true, self:objectName())
			if card_id == -1 then break end
			card_ids:removeOne(card_id)
			to_get:append(card_id)
			room:takeAG(player, card_id, false)
			sum = sum +  sgs.Sanguosha:getCard(card_id):getNumber()
			for _, id in sgs.qlist(card_ids) do
				if sum + sgs.Sanguosha:getCard(id):getNumber() > 13 then
					room:takeAG(nil, id, false)
					card_ids:removeOne(id)
					to_throw:append(id)
				end
			end
		end
		room:clearAG()
		local dummy = sgs.Sanguosha:cloneCard("jink")
		if not to_get:isEmpty() then
			dummy:addSubcards(to_get)
			player:obtainCard(dummy)
		end	
		if not to_throw:isEmpty() or not card_ids:isEmpty() then
			dummy:clearSubcards()
			dummy:addSubcards(to_throw)
			dummy:addSubcards(card_ids)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), nil)
			room:throwCard(dummy, reason, nil)
		end
		dummy:deleteLater()
		return false
	end,
}


--[[
	穿心
	相关武将：势-张任
	描述：每当你于出牌阶段内使用【杀】或【决斗】对与你势力不同的目标角色造成伤害时，若该角色有副将，你可以防止此伤害，令其选择一项：1.弃置装备区里的所有牌，若如此做，其失去1点体力；2.移除副将的武将牌。 
	引用：
	状态：
]]

--[[
	存嗣
	相关武将：势-糜夫人
	描述：出牌阶段，你可以移除此武将牌并选择一名角色，令该角色获得“勇决”，然后若该角色不为你，其摸两张牌。  
	引用：
	状态：
]]