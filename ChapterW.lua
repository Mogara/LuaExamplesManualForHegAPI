--[[
	国战技能速查手册（W区）
	技能索引：
	完杀、忘隙、帷幕、问道、武圣、无双、悟心 
]]--
--[[
	完杀
	相关武将：标-贾诩
	描述：锁定技，不处于濒死状态的其他角色于你的回合内不能使用【桃】。 
	引用：
	状态：
]]
--[[
	忘隙
	相关武将：势-李典
	描述：每当你对其他角色造成1点伤害后，或受到其他角色造成的1点伤害后，若该角色存活，你可以令你与其各摸一张牌。 
	引用：
	状态：
]]
--[[
	帷幕
	相关武将：标-贾诩
	描述：锁定技，每当你成为黑色锦囊牌的目标时，你取消自己。 
	引用：
	状态：
]]
--[[
	问道
	相关武将：势-君张角
	描述：出牌阶段限一次，你可以弃置一张红色牌，获得弃牌堆里或场上的一张【太平要术】。 
	引用：
	状态：
]]
--[[
	武圣
	相关武将：标-关羽
	描述：你可以将一张红色牌当【杀】使用或打出。 
	引用：
	状态：
]]

--武圣
LuaWusheng = sgs.CreateOneCardViewAsSkill{
	name = "LuaWusheng",
	view_filter = function(self, card)
		local lord = sgs.Self:getLord()
        if not lord or not lord:hasLordSkill("shouyue") or not lord:hasShownGeneral1() then
            if not card:isRed() then return false end
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:addSubcard(originalCard:getId())
		slash:setSkillName(self:objectName())
		slash:setShowSkill(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}

--[[
	无双
	相关武将：标-吕布
	描述：锁定技，每当你使用【杀】指定一名角色为目标后，该角色需依次使用两张【闪】才能抵消此【杀】；锁定技，每当你使用【决斗】指定一名角色为目标后，或成为一名角色使用【决斗】的目标后，该角色每次响应此【决斗】需依次打出两张【杀】。 
	引用：
	状态：
]]
--[[
	悟心
	相关武将：势-君张角
	描述：摸牌阶段开始时，你可以观看牌堆顶的X张牌（X为群势力角色的数量），然后你可以改变这些牌的顺序。 
	引用：
	状态：
]]
