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

local luaaocaiView = function(self, room, player, pattern)
	local json = require ("json")
	local ids = room:getNCards(2, false)

	room:doBroadcastNotify(sgs.CommandType.S_COMMAND_INVOKE_SKILL, json.encode({self:getSkillName(), player:objectName()}))
	room:notifySkillInvoked(player, self:getSkillName())
	room:broadcastSkillInvoke(self:getSkillName(), player)

	if player:ownSkill(self:showSkill()) and not player:hasShownSkill(self:showSkill()) then --亮将
		player:showGeneral(player:inHeadSkills(self:showSkill()))
	end

	local jsonLog = {"$ViewDrawPile", player:objectName(), "", table.concat(sgs.QList2Table(ids),"+"), "", "" }
	room:doNotify(player,sgs.CommandType.S_COMMAND_LOG_SKILL, json.encode(jsonLog))

	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:getSkillName(), "")
	local move, move2 = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand, reason), sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, reason)
	local moves, moves2 = sgs.CardsMoveList(), sgs.CardsMoveList()
	moves:append(move)
	moves2:append(move2)
	local zhugeke = sgs.SPlayerList()
	zhugeke:append(player)
	room:notifyMoveCards(true, moves, true, zhugeke)
	room:notifyMoveCards(false, moves, true, zhugeke)

	local enablepattern = {}
	for i = 1, 0, -1 do
		for _, pat in ipairs(pattern:split("+")) do
			if string.find(sgs.Sanguosha:getCard(ids:at(i)):objectName(), pat) then table.insert(enablepattern, ids:at(i)) end
		end
	end

	local log, askids, card = sgs.LogMessage(), table.concat(enablepattern, ",")
	askids = askids == "" and "none" or askids
	card = room:askForCard(player, askids, self:getSkillName(), sgs.QVariant(), sgs.Card_MethodNone)
	room:setPlayerFlag(player, "Global_luaaocaiFailed")

	room:notifyMoveCards(true, moves2, true, zhugeke)
	room:notifyMoveCards(false, moves2, true, zhugeke)
	for i = 1, 0, -1 do
		room:setCardMapping(ids:at(i), nil, sgs.Player_DrawPile)
		room:getDrawPile():prepend(ids:at(i))
	end
	room:doBroadcastNotify(sgs.CommandType.S_COMMAND_UPDATE_PILE, sgs.QVariant(room:getDrawPile():length()))

	if card then
		log.type = "$AluaaocaiUse"
		log.from = player
		log.arg = self:getSkillName()
		log.arg2 = ids:at(0) == card:getEffectiveId() and 1 or 2
		log.card_str = card:getEffectiveId()
		card:setSkillName(self:getSkillName())
	end
	return card, log
end

luaaocaiCard = sgs.CreateSkillCard{
	name = "luaaocaiCard",
	skill_name = "luaaocai",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,

	filter = function(self, targets, to_select)
		local targetlist = sgs.PlayerList()
		for i = 1, #targets do targetlist:append(targets[i]) end
		local card = sgs.Sanguosha:cloneCard(self:getUserString())
		card:deleteLater()
		return card and card:targetFilter(targetlist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, targetlist)
	end ,

	feasible = function(self, targets)
		local targetlist = sgs.PlayerList()
		for i = 1, #targets do targetlist:append(targets[i]) end
		local card = sgs.Sanguosha:cloneCard(self:getUserString())
		card:deleteLater()
		return card and card:targetsFeasible(targetlist, sgs.Self)
	end,
	
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local card, log = luaaocaiView(self, room, user, self:getUserString())
		if card then room:sendLog(log) end
		return card
	end,

	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local room = cardUse.from:getRoom()
		local card, log = luaaocaiView(self, room, cardUse.from, self:getUserString())
		if card then room:sendLog(log) end
		return card
	end,
}

luaaocaiCard2 = sgs.CreateSkillCard{
	name = luaaocaiCard.name,
	skill_name = luaaocaiCard.skill_name,
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_validate_in_response = luaaocaiCard.on_validate_in_response,
	on_validate = luaaocaiCard.on_validate,
}

luaaocai = sgs.CreateZeroCardViewAsSkill{
	name = "luaaocai",

	view_as = function(self)
		local patterns = sgs.Sanguosha:getCurrentCardUsePattern():split("+")
		for _, pat in ipairs(patterns) do
			if pat == "peach" and sgs.Self:hasFlag("Global_PreventPeach") then table.removeOne(patterns, pat) end
		end
		local targetFixed = false
		local card = sgs.Sanguosha:cloneCard(patterns[1])
		card:deleteLater()
		targetFixed = card:targetFixed() or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE

		local skillcard = targetFixed and luaaocaiCard2:clone() or luaaocaiCard:clone()
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
		if string.find(pattern, "slash") or string.find(pattern, "peach") or string.find(pattern, "jink") or string.find(pattern, "analeptic") then
			return player:getPhase() == sgs.Player_NotActive and not player:hasFlag("Global_luaaocaiFailed")
		end
		return false
	end,
}