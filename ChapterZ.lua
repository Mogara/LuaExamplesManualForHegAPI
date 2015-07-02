--[[
	国战技能速查手册（Z区）
	技能索引：
	再起、章武、鸩毒、贞烈、制衡、直谏、资粮  
]]--
--[[
	再起
	相关武将：标-孟获
	描述：摸牌阶段开始时，若你已受伤，你可以放弃摸牌，亮出牌堆顶的X张牌（X为你已损失的体力值），然后回复等同于其中♥牌数量的体力，再将这些♥牌置入弃牌堆，最后获得其余的牌。
	引用：
	状态：
]]

LuaZaiqi = sgs.CreatePhaseChangeSkill{
	name = "LuaZaiqi",
	frequency = sgs.Skill_Frequent,

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end

		if player:getPhase() == sgs.Player_Draw and player:isWounded() then
			return self:objectName()
		end
	end,

	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self) then
			room:broadcastSkillInvoke(self:objectName(), 1, player)
			return true
		end
	end,
	on_phasechange = function(self, menghuo)
		local room = menghuo:getRoom()
		local has_heart = false
		local x = menghuo:getLostHp()
		local ids = room:getNCards(x, false)
		local move = sgs.CardsMoveStruct(ids, menghuo, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, menghuo:objectName(), "LuaZaiqi", ""))
		room:moveCardsAtomic(move, true)

		room:getThread():delay()
		room:getThread():delay()

		local card_to_throw,card_to_gotback = sgs.IntList(),sgs.IntList()
		for i = 0, x - 1, 1 do
			if sgs.Sanguosha:getCard(ids:at(i)):getSuit() == sgs.Card_Heart then
				card_to_throw:append(ids:at(i))
            else
				card_to_gotback:append(ids:at(i))
			end
		end
		if not card_to_throw:isEmpty() then
			local dummy = sgs.DummyCard(card_to_throw)
			local recover = sgs.RecoverStruct()
			recover.who = menghuo;
			recover.recover = card_to_throw:length()
			room:recover(menghuo, recover)
			reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, menghuo:objectName(), "LuaZaiqi", "")
			room:throwCard(dummy, reason, nil)
            has_heart = true
		end
		if not card_to_gotback:isEmpty() then
			local dummy2 = sgs.DummyCard(card_to_gotback)
            reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, menghuo:objectName())
            room:obtainCard(menghuo, dummy2, reason)
		end
		if has_heart then
            room:broadcastSkillInvoke(self:objectName(), 2, menghuo)
		end
		return true
	end,
}

--[[
	章武
	相关武将：阵-君刘备
	描述：锁定技，每当【飞龙夺凤】置入弃牌堆或其他角色的装备区后，你获得之；锁定技，每当你失去【飞龙夺凤】时，你展示此牌，然后将此牌移动的目标区域改为牌堆底，若如此做，当此牌置于牌堆底后，你摸两张牌。 
	引用：
	状态：
]]
--[[
	鸩毒
	相关武将：阵-何太后
	描述：其他角色的出牌阶段开始时，你可以弃置一张手牌，令该角色视为以方法Ⅰ使用一张【酒】，然后你对其造成1点伤害。 
	引用：
	状态：
]]

--[[
	贞烈
	相关武将：身份-王异
	描述：当你成为其他角色使用【杀】或非延时类锦囊牌的目标后，你可失去1点体力，令此牌对你无效，然后你弃置其一张牌。 
	引用：
	状态：1.2.0 验证通过
]]

luazhenlie = sgs.CreateTriggerSkill{
	name = "luazhenlie",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.TargetConfirmed,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getHp() > 0 then
			local use = data:toCardUse()
			if use.from and use.from:objectName() ~= player:objectName() and use.to:contains(player) then
				if use.card:isKindOf("Slash") or use.card:isNDTrick() then return self:objectName() end
			end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:loseHp(player)
			if player:isAlive() then return true end
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local nullified_list = use.nullified_list
		table.insert(nullified_list, player:objectName())
		use.nullified_list = nullified_list
		data:setValue(use)
		if player:canDiscard(use.from, "he") then
			local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
			room:throwCard(id, use.from, player)
		end
		return false 
	end,
}

--[[
	制衡
	相关武将：标-孙权
	描述：出牌阶段限一次，你可以弃置一至X张牌（X为你的体力上限），摸等量的牌。 
	引用：
	状态：
]]

LuaZhihengCard = sgs.CreateSkillCard{
	name = "LuaZhihengCard",
	target_fixed = true,
	on_use = function(self, room, source)
		if source:isAlive() then
			source:drawCards(self:getSubcards():length())
		end
	end,
}

LuaZhiheng = sgs.CreateViewAsSkill{
	name ="LuaZhiheng",
	
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select) and #selected < sgs.Self:getMaxHp()
	end,

	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local zhiheng_card = LuaZhihengCard:clone()
		for _, c in ipairs(cards) do
			zhiheng_card:addSubcard(c)
		end
		zhiheng_card:setSkillName(self:objectName())
		zhiheng_card:setShowSkill(self:objectName())
		return zhiheng_card
	end,
	
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he") and not player:hasUsed("#LuaZhihengCard")
	end,
}

--[[
	直谏
	相关武将：标-张昭&张纮
	描述：出牌阶段，你可以将手牌中的一张装备牌置入一名其他角色的装备区，摸一张牌。
	引用：
	状态：
]]

LuaZhijianCard = sgs.CreateSkillCard{
	name = "LuaZhijianCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, erzhang)
		if #targets ~= 0 or to_select:objectName() == erzhang:objectName() then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil
	end,
	extra_cost = function(self,room,card_use)
		local erzhang = card_use.from;
		room:moveCardTo(self, erzhang, card_use.to:first(), sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, erzhang:objectName(), "LuaZhijian", ""))
		local log = sgs.LogMessage()
		log.type = "$ZhijianEquip"
		log.from = card_use.to:first()
		log.card_str = self:getEffectiveId()
		room:sendLog(log)
	end,
	on_effect = function(self, effect)
		effect.from:drawCards(1)
	end,
}

LuaZhijian = sgs.CreateOneCardViewAsSkill{
	name = "LuaZhijian",
	filter_pattern = "EquipCard|.|.|hand",
	view_as = function(self, card)
		local zhijian_card = LuaZhijianCard:clone()
		zhijian_card:addSubcard(card)
		zhijian_card:setShowSkill(self:objectName())
		return zhijian_card
	end
}

--[[
	资粮
	相关武将：阵-邓艾
	描述：副将技，每当与你势力相同的一名角色受到伤害后，你可以将一张“田”交给该角色。
	引用：
	状态：
]]

LuaZiliangCard = sgs.CreateSkillCard{
	name = "LuaZiliangCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self, room, source)
		source:setTag("ziliang", sgs.QVariant(self:getSubcards():first()))
	end,
}

LuaZiliangVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaZiliang",
	response_pattern = "@@LuaZiliang",
	filter_pattern = ".|.|.|LuaField",
	expand_pile = "LuaField",

	view_as = function(self, ocard)
		local c = LuaZiliangCard:clone()
		c:addSubcard(ocard)
        c:setShowSkill(self:objectName())
		return c
	end,
}

LuaZiliang = sgs.CreateTriggerSkill{
	name = "LuaZiliang",
	events = {sgs.Damaged},
	relate_to_place = "deputy",
	view_as_skill = LuaZiliangVS,

    can_trigger = function(self,event,room,player,data)
		local skill_list,player_list = {},{}
		local players = room:findPlayersBySkillName(self:objectName())
		if not player or player:isDead() then return false end
		for _, p in sgs.qlist(players) do
			if not p:getPile("LuaField"):isEmpty() and p:isFriendWith(player) then
				table.insert(skill_list, self:objectName())
				table.insert(player_list, p:objectName())
			end
		end
		return table.concat(skill_list, "|"), table.concat(player_list, "|")
	end,

    on_cost = function(self,event,room,p,data,player)
        player:removeTag("ziliang")
        player:setTag("ziliang_aidata", data)
		return room:askForUseCard(player, "@@LuaZiliang", "@ziliang-give", -1, sgs.Card_MethodNone)
	end,

	on_effect = function(self,event,room,p,data,player)
		local id = player:getTag("ziliang"):toInt()
		if p:objectName() == player:objectName() then
			local log = sgs.LogMessage()
			log.type = "$MoveCard"
			log.from = player
			log.to:append(player)
			log.card_str = id
			room:sendLog(log)
		else
			room:doAnimate(1, player:objectName(), p:objectName())
		end
        room:obtainCard(p, id)
	end,
}
