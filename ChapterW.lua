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

LuaWeimu = sgs.CreateTriggerSkill{
	name = "LuaWeimu",
	events = {sgs.TargetConfirming},
	frequency = sgs.Skill_Compulsory,

    can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
        local use = data:toCardUse()
		if not use.card or use.card:getTypeId() ~= sgs.Card_TypeTrick or not use.card:isBlack() then return false end
		if not use.to:contains(player) then return false end
		return self:objectName()
	end,

	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,

	on_effect = function(self,event,room,player,data)
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        local use = data:toCardUse()

        sgs.Room_cancelTarget(use, player)
		data:setValue(use)
        return false
	end,
}

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
	备注：无双决斗部分在源码中
]]


LuaWushuang = sgs.CreateTriggerSkill{
	name = "LuaWushuang",
	events = {sgs.TargetChosen,sgs.TargetConfirmed,sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self,event,room,player,data)
		if not player then return false end
		local use = data:toCardUse()
		if event == sgs.TargetChosen then
			if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) then
				if player:isAlive() and player:hasSkill(self:objectName()) then
					local targets = {}
					for _, p in sgs.qlist(use.to) do
						table.insert(targets, p:objectName())
					end
					if #targets > 0 then return self:objectName() .. "->" .. table.concat(targets,"+") end
				end
			end
		elseif event == sgs.TargetConfirmed then
			if not use.to:contains(player) then return false end
            if use.card and use.card:isKindOf("Duel") and player:isAlive() and player:hasSkill(self:objectName()) then
				return self:objectName() .. "->" .. use.from:objectName()
			end
		elseif event == sgs.CardFinished then
			if use.card:isKindOf("Duel") then
				for _, lvbu in sgs.qlist(room:getAllPlayers()) do
					if lvbu:getMark("WushuangTarget") > 0 then
						room:setPlayerMark(lvbu, "WushuangTarget", 0)
					end
				end
			end
		end
	end,
	on_cost = function(self,event,room,target,data,ask_who)
		ask_who:setTag("WushuangData",data)			--for AI
		local d = sgs.QVariant()
		d:setValue(target)
		local invoke = ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self:objectName(), d)
        ask_who:removeTag("WushuangData")
		if invoke then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
	end,
	
	on_effect = function(self,event,room,target,data,ask_who)
		room:sendCompulsoryTriggerLog(ask_who, self:objectName(),true)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			if event ~= sgs.TargetChosen then return false end
			local x = use.to:indexOf(target)
			local jink_list = ask_who:getTag("Jink_" .. use.card:toString()):toList()
			if (jink_list:at(x):toInt() == 1) then
				jink_list:replace(x,sgs.QVariant(2))
			end
            ask_who:setTag("Jink_" .. use.card:toString(),sgs.QVariant(jink_list))
		elseif use.card:isKindOf("Duel") then
			room:setPlayerMark(ask_who, "WushuangTarget", 1)
		end
	end,
}

--[[
	悟心
	相关武将：势-君张角
	描述：摸牌阶段开始时，你可以观看牌堆顶的X张牌（X为群势力角色的数量），然后你可以改变这些牌的顺序。 
	引用：
	状态：
]]
