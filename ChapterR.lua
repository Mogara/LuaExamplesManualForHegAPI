--[[
	国战技能速查手册（R区）
	技能索引：
	仁德
]]--
--[[
	仁德
	相关武将：标-刘备、阵-君刘备
	描述：出牌阶段，你可以将至少一张手牌交给一名角色，若如此做，当你以此法交给其他角色的手牌首次达到三张或更多时，你回复1点体力。 
	引用：
	状态：
]]
LuaRendeCard = sgs.CreateSkillCard{
	name = "LuaRendeCard",
	skill_name = "LuaRende",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
	
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end ,		
	extra_cost = function(self,room,card_use)
		local target = card_use.to:first()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, card_use.from:objectName(), target:objectName(), "rende", "")
		room:obtainCard(target, self, reason, false)
	end,

	on_use = function(self, room, source)
		local old_value = source:getMark("rende")
		local new_value = old_value + self:getSubcards():length()
		room:setPlayerMark(source, "rende", new_value)

		if (old_value < 3 and new_value >= 3 and source:isWounded()) then
			local recover = sgs.RecoverStruct()
			recover.card = self
			recover.who = source
			room:recover(source, recover)
		end
	end,
}

LuaRendeVS = sgs.CreateViewAsSkill{
	name = "LuaRende",

	view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
	end,
	enabled_at_play = function(self, player)
        return not player:isKongcheng()
	end,
	view_as = function(self,cards)
        if #cards == 0 then return nil end
        local card = LuaRendeCard:clone()
		for _,c in ipairs(cards)do
			card:addSubcard(c)
		end
        card:setShowSkill(self:objectName())
        return card
	end,
}

LuaRende = sgs.CreateTriggerSkill{
	name = "LuaRende",
	events = {sgs.EventPhaseChanging},
	view_as_skill = LuaRendeVS,

	can_trigger = function(self,event,room,target,data)
        if target:getMark("rende") > 0 then
			local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:setPlayerMark(target, "rende", 0)
			end
		end
	end,
}
