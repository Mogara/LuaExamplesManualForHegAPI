--[[
	国战技能速查手册（Z区）
	技能索引：
	再起、章武、鸩毒、贞烈、制衡、直谏、直言、资粮、纵玄、
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
	状态：2.0 验证通过
]]

LuaZhenlie = sgs.CreateTriggerSkill{
	name = "LuaZhenlie",
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
	直言
	相关武将：身份-虞翻
	描述：结束阶段开始时，你可以令一名角色摸一张牌，然后展示之，若此牌为装备牌，该角色先回复1点体力再使用此牌。
	引用：
	状态：1.2.0 验证通过
]]

luazhiyan = sgs.CreateTriggerSkill{
	name = "luazhiyan",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.EventPhaseStart,
	
	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish) then return "" end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), self:objectName().."-invoke", true, true)
		if to then
			room:broadcastSkillInvoke(self:objectName(), player)
			local to_data = sgs.QVariant()
			to_data:setValue(to)
			player:setTag(self:objectName(), to_data)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local to = player:getTag(self:objectName()):toPlayer()
		player:removeTag(self:objectName())
		local ids = room:getNCards(1, false)
		local card = sgs.Sanguosha:getCard(ids:first())
		room:obtainCard(to, card, false)
		if to:isAlive() then
			room:showCard(to, ids:first())
			if not card:isKindOf("EquipCard") then return false end
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(to, recover)
			if to:isAlive() and room:getCardOwner(ids:first()):objectName() == to:objectName() and not to:isLocked(card) then
				room:useCard(sgs.CardUseStruct(card, to, to))
			end
		end
		return false 
	end,
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

--[[
	纵玄
	相关武将：身份-虞翻
	描述：每当你的牌因弃置而置入弃牌堆前，你可以将其中至少一张牌以任意顺序置于牌堆顶。
	引用：
	状态：1.2.0 验证通过
	备注：
	相关翻译 {
		["@LuaZongxuan"] = "请选择至少一张牌置于牌堆顶", 
		["LuaZongxuan#up"] = "弃置",
		["LuaZongxuan#down"] = "置于牌堆顶",
	}
]]

luazongxuan = sgs.CreateTriggerSkill{
	name = "luazongxuan",
	can_preshow = true,
	events = sgs.BeforeCardsMove,

	on_record = function(self, event, room, player, data)
		if not (player and player:isAlive()) then return end
		if not player:hasSkill(self:objectName()) then player:removeTag("zongxuanCards_strings") return end
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
			local card_ids = {}
			if move.to_place == sgs.Player_PlaceTable then
				for i = 0, move.card_ids:length()-1, 1 do
					local card_id = move.card_ids:at(i)	
					if room:getCardOwner(card_id):objectName() == move.from:objectName() and move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip then
						table.insert(card_ids, tostring(card_id))
					end
				end
			end
			if #card_ids > 0 then
				local zongxuanCards_strings = player:getTag("zongxuanCards_strings"):toString()
				zongxuanCards_strings = zongxuanCards_strings.."|"..table.concat(card_ids, "+")
				player:setTag("zongxuanCards_strings", sgs.QVariant(zongxuanCards_strings))
			end
		end
	end,
	
	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
		local zongxuanCards_strings = player:getTag("zongxuanCards_strings"):toString()
		if zongxuanCards_strings == "" then return "" end
		local move, zongxuan_table  = data:toMoveOneTime(), zongxuanCards_strings:split("|")
		
		if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then		
			local zongxuanCards_string, zongxuan_ids = zongxuan_table[#zongxuan_table], {}
			if move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile then
				for _, idstring in ipairs(zongxuanCards_string:split("+")) do
					if room:getCardPlace(tonumber(idstring)) == sgs.Player_PlaceTable then table.insert(zongxuan_ids, idstring) end
				end
				room:setPlayerProperty(player, "zongxuan_toget", sgs.QVariant(table.concat(zongxuan_ids, "+")))
				if #zongxuan_ids > 0 then return self:objectName() end
			end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		local zongxuanCards_strings = player:getTag("zongxuanCards_strings"):toString():split("|")
		table.remove(zongxuanCards_strings)
		player:setTag("zongxuanCards_strings", sgs.QVariant(table.concat(zongxuanCards_strings, "|")))

		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local zongxuanCards = player:property("zongxuan_toget"):toString():split("+")
		local card_ids, to_top = sgs.IntList(), sgs.IntList()
		for _, idstring in ipairs(zongxuanCards) do 
			card_ids:append(tonumber(idstring))
		end

		local AsMove = room:askForMoveCards(player, card_ids, sgs.IntList(), false, self:objectName(), "", self:objectName(), 1, card_ids:length(), false, false)
		if AsMove.bottom:isEmpty() then return false end

		local move = data:toMoveOneTime()
		for _, id in sgs.qlist(AsMove.bottom) do
			to_top:prepend(id)
			move.from_places:removeAt(move.card_ids:indexOf(id))
			move.card_ids:removeOne(id)
		end
		data:setValue(move)
		
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(), "")
		local move = sgs.CardsMoveStruct(to_top, player, nil, sgs.Player_PlaceTable, sgs.Player_DrawPile, reason)
		local moves = sgs.CardsMoveList()
		moves:append(move)
		room:moveCardsAtomic(moves, false)
		return false
	end,	
}
