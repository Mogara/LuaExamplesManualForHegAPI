--[[
	国战技能速查手册（A区）
	技能索引：
	暗箭、安恤、傲才、
]]--

--[[
	暗箭
	相关武将：身份-潘璋＆马忠
	描述：当你使用【杀】对目标角色造成伤害时，若你不在其攻击范围内，你令伤害值＋1。
	引用：
	状态：1.2.0 测试通过
]]

LuaAnjian = sgs.CreateTriggerSkill{
	name = "LuaAnjian",
	can_preshow = true,
	frequency = sgs.Skill_Compulsory,
	events = sgs.DamageCaused,
	
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local damage = data:toDamage()
			if damage.chain or damage.transfer or not damage.by_user then return "" end
			if damage.card and damage.card:isKindOf("Slash") then
				if damage.from and not damage.to:inMyAttackRange(damage.from) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		local damage = data:toDamage()
		damage.damage = damage.damage + 1
		data:setValue(damage)
		return false 
	end,
}

--[[
	安恤
	相关武将：身份-步练师
	描述：出牌阶段限一次，你可选择两名手牌数不同的其他角色，令其中手牌少的角色先获得手牌多的角色的一张手牌再展 示之，然后若以此法展示的牌不为♠，你摸一张牌。 
	引用：
	状态：1.2.0 测试通过
]]

LuaAnxuCard = sgs.CreateSkillCard{
	name = "LuaAnxuCard",
	skill_name = "LuaAnxu",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,

	filter = function(self, targets, to_select, player)
		if to_select:objectName() == player:objectName() then
			return false
		elseif #targets == 0 then
			return true
		elseif #targets == 1 then 
			return to_select:objectName() ~= targets[1]:objectName() and to_select:getHandcardNum() ~= targets[1]:getHandcardNum()
		end
		return false
	end,
	
	feasible = function(self, targets)
		return #targets == 2
	end,

	on_use = function(self, room, source, targets)
		local from = targets[1]:getHandcardNum() < targets[2]:getHandcardNum() and targets[1] or targets[2]
		local to = from:objectName() == targets[1]:objectName() and targets[2] or targets[1]
		local id = room:askForCardChosen(from, to, "h", self:getSkillName(), false)
		local card = sgs.Sanguosha:getCard(id)
		from:obtainCard(card)
		room:showCard(from, id)
		if card:getSuit() ~= sgs.Card_Spade then
			room:drawCards(source, 1, self:getSkillName())
		end
	end,
}

LuaAnxu = sgs.CreateZeroCardViewAsSkill{   
	name = "LuaAnxu",
	
	view_as = function(self)
		local skillcard = LuaAnxuCard:clone()
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,

	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaAnxuCard")
	end,
}

--[[
	傲才
	相关武将：身份-SP·诸葛恪
	描述：当你于回合外需要使用／打出基本牌时，你可观看牌堆顶的两张牌，若如此做，你可使用／打出其中的一张牌。 
	引用：
	状态：1.2.0 测试通过
	备注：修改成类似OL的操作方式
]]

local LuaAocaiView = function(self, room, player, pattern)
	local json = require ("json")
	room:doBroadcastNotify(sgs.CommandType.S_COMMAND_INVOKE_SKILL, json.encode({self:getSkillName(), player:objectName()}))
	room:notifySkillInvoked(player, self:getSkillName())
	room:broadcastSkillInvoke(self:getSkillName(), player)

	if player:ownSkill(self:showSkill()) and not player:hasShownSkill(self:showSkill()) then
		player:showGeneral(player:inHeadSkills(self:showSkill()))
	end

	local ids, enablepattern = room:getNCards(2, false), {}
	local log2 = sgs.LogMessage()
	log2.type = "$ViewDrawPile"
	log2.from = player
	log2.card_str = table.concat(sgs.QList2Table(ids), "+")
	room:doNotify(player,sgs.CommandType.S_COMMAND_LOG_SKILL, log2:toVariant())

	for _, pat in ipairs(pattern:split("+")) do
		local basic = sgs.Sanguosha:cloneCard(pat)
		if basic then
			basic:deleteLater()
			if basic:isKindOf("BasicCard") then table.insert(enablepattern, basic:getClassName()) end
		end
	end

	local ids2 = room:notifyChooseCards(player, ids, self:getSkillName(), sgs.Player_DrawPile, sgs.Player_PlaceTable, 1, 0, "@"..self:getSkillName(), table.concat(enablepattern, ",").."|.|.|$"..self:getSkillName())
	room:returnToDrawPile(ids, false)

	local log, card = sgs.LogMessage()
	if ids2:length() == 1 then 
		card = sgs.Sanguosha:getCard(ids2:first())
		log.type = "$LuaAocaiUse"
		log.from = player
		log.arg = self:getSkillName()
		log.arg2 = ids:at(0) == card:getEffectiveId() and 1 or 2
		log.card_str = card:getEffectiveId()
		card:setSkillName(self:getSkillName())
	end
	room:setPlayerFlag(player, "Global_LuaAocaiFailed")
	return card, log
end

LuaAocaiCard = sgs.CreateSkillCard{
	name = "LuaAocaiCard",
	skill_name = "LuaAocai",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,

	filter = function(self, targets, to_select, player)
		local targetlist = sgs.PlayerList()
		for i = 1, #targets do targetlist:append(targets[i]) end
		local card = sgs.Sanguosha:cloneCard(self:getUserString())
		card:deleteLater()
		return card and card:targetFilter(targetlist, to_select, player) and not player:isProhibited(to_select, card, targetlist)
	end ,

	feasible = function(self, targets, player)
		local targetlist = sgs.PlayerList()
		for i = 1, #targets do targetlist:append(targets[i]) end
		local card = sgs.Sanguosha:cloneCard(self:getUserString())
		card:deleteLater()
		return card and card:targetsFeasible(targetlist, player)
	end,
	
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local card, log = LuaAocaiView(self, room, user, self:getUserString())
		if card then room:sendLog(log) end
		return card
	end,

	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local room = cardUse.from:getRoom()
		local card, log = LuaAocaiView(self, room, cardUse.from, self:getUserString())
		if card then room:sendLog(log) end
		return card
	end,
}

LuaAocai = sgs.CreateZeroCardViewAsSkill{
	name = "LuaAocai",

	view_as = function(self)
		local patterns = sgs.Sanguosha:getCurrentCardUsePattern():split("+")
		if sgs.Self:hasFlag("Global_PreventPeach") then table.removeAll(patterns, "peach") end
		local card = sgs.Sanguosha:cloneCard(patterns[1])
		local skillcard = LuaAocaiCard:clone()
		skillcard:setTargetFixed(card:targetFixed() or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
		card:deleteLater()
		skillcard:setUserString(table.concat(patterns, "+")) 
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,

	enabled_at_play = function(self, player)
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		if pattern =="peach" and player:hasFlag("Global_PreventPeach") then return false end
		for _, pat in ipairs(pattern:split("+")) do
			local basiccard = sgs.Sanguosha:cloneCard(pat)
			if basiccard then
				basiccard:deleteLater()
				if basiccard:isKindOf("BasicCard") then
					return player:getPhase() == sgs.Player_NotActive and not player:hasFlag("Global_LuaAocaiFailed")
				end
			end
		end
		return false
	end,
}