--[[
	国战技能速查手册（L区）
	技能索引：
	雷击、离间、礼让、连环、烈弓、烈刃、流离、龙胆、乱击、乱武、洛神、裸衣          
]]--
--[[
	雷击
	相关武将：标-张角
	描述：每当你使用或打出【闪】时，你可以令一名角色进行判定，若结果为♠，你对其造成2点雷电伤害。     
	引用：
	状态：
]]

LuaLeiji = sgs.CreateTriggerSkill{
	name = "LuaLeiji",
	events = {sgs.CardResponded},

	can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local card_star = data:toCardResponse().m_card
		if card_star:isKindOf("Jink") then
			return self:objectName()
		end
	end,

	on_cost = function(self,event,room,player,data)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "leiji-invoke", true, true)
		if target then
			local d = sgs.QVariant()
			d:setValue(target)
			player:setTag("leiji-target", d)
            room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,

    on_effect = function(self,event,room,player,data)
		local card_star = data:toCardResponse().m_card
		if card_star:isKindOf("Jink") then
			local target = player:getTag("leiji-target"):toPlayer()
			player:removeTag("leiji-target")
			if target then

				judge = sgs.JudgeStruct()
				judge.pattern = ".|spade"
				judge.good = false
				judge.negative = true
				judge.reason = self:objectName()
				judge.who = target

				room:judge(judge)

				if judge:isBad() then
					room:damage(sgs.DamageStruct(self:objectName(), player, target, 2, sgs.DamageStruct_Thunder))
				end
			end
		end
	end,
}

--[[
	离间
	相关武将：标-貂蝉
	描述：出牌阶段限一次，你可以弃置一张牌并选择两名其他男性角色，令其中一名男性角色视为对另一名男性角色使用一张【决斗】。     
	引用：
	状态：
]]

LuaLijianCard = sgs.CreateSkillCard{
	name = "LuaLijianCard",
	mute = true,

	filter = function(self,targets,to_select,Self)
		if not to_select:isMale() then return false end
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		if #targets == 1 and (to_select:isCardLimited(duel, sgs.Card_MethodUse) or to_select:isProhibited(targets[1], duel)) then return false end
		duel:deleteLater()
		return #targets < 2 and to_select:objectName() ~= Self:objectName()
	end,
	
	feasible = function(self,targets)
		return #targets == 2
	end,

	about_to_use = function(self,room,use)
		local diaochan = use.from
		local log = sgs.LogMessage()
		log.from = diaochan
		for _, p in sgs.qlist(use.to) do
			log.to:append(p)
		end
		log.type = "#UseCard"
		log.card_str = self:toString()
		room:sendLog(log)
		local data = sgs.QVariant()
		data:setValue(use)
		local thread = room:getThread()

		thread:trigger(sgs.PreCardUsed, room, diaochan, data)
		room:broadcastSkillInvoke("LuaLijian", diaochan)

		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, diaochan:objectName(), "", "LuaLijian", "")
		room:moveCardTo(self, diaochan, nil, sgs.Player_PlaceTable, reason, true)

		if diaochan:ownSkill("LuaLijian") and not diaochan:hasShownSkill("LuaLijian") then
			diaochan:showGeneral(diaochan:inHeadSkills("LuaLijian"))
		end
	
		local table_ids = room:getCardIdsOnTable(self)
		if not table_ids:isEmpty() then
			local dummy = sgs.DummyCard(table_ids)
			room:moveCardTo(dummy, diaochan, nil, sgs.Player_DiscardPile, reason, true)
		end

		thread:trigger(sgs.CardUsed, room, diaochan, data)
		thread:trigger(sgs.CardFinished, room, diaochan, data)
	end,
	on_use = function(self,room,player,targets)
		local to = targets[1]
		local from = targets[2]

		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName(string.format("_%s", self:getSkillName()))
		if not from:isCardLimited(duel, sgs.Card_MethodUse) and not from:isProhibited(to, duel) then
			room:useCard(sgs.CardUseStruct(duel, from, to))
		else
			duel:deleteLater()
		end
	end,
}


LuaLijian = sgs.CreateOneCardViewAsSkill{
	name = "LuaLijian",
	filter_pattern = ".!",
	enabled_at_play = function(self,player)
		return player:getAliveSiblings():length() > 1
			and player:canDiscard(player, "he") and not player:hasUsed("#LuaLijianCard")
	end,
	view_as = function(self,ocard)
		local lijian_card = LuaLijianCard:clone()
		lijian_card:addSubcard(ocard)
		lijian_card:setShowSkill(self:objectName())
		return lijian_card
	end,
}

--[[
	礼让
	相关武将：标-孔融
	描述：每当你的一张被弃置的牌置入弃牌堆后，你可以将之交给一名其他角色。  
	引用：
	状态：
]]

LuaLirang = sgs.CreateTriggerSkill{
	name = "LuaLirang",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Frequent,

    can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local move = data:toMoveOneTime()
		if not move.from or move.from:objectName() ~= player:objectName() then return false end
        if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
			if move.to_place == sgs.Player_PlaceTable then
				local i = 0
				local lirang_card = sgs.VariantList()
				for _, card_id in sgs.qlist(move.card_ids) do
					if room:getCardPlace(card_id) == sgs.Player_PlaceTable and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
						lirang_card:append(sgs.QVariant(card_id))
					end
                    i = i + 1
				end
				if not lirang_card:isEmpty() then
                    player:setTag("lirang_to_judge", sgs.QVariant(lirang_card))
				end
			elseif move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile then
				local lirang_card = player:getTag("lirang_to_judge"):toList()
				player:removeTag("lirang_to_judge")
				local lirangs = sgs.VariantList()
				for _, id in sgs.qlist(lirang_card) do
					if room:getCardPlace(id:toInt()) == sgs.Player_DiscardPile then
						lirangs:append(id)
					end
				end
				if lirangs:isEmpty() then return false end
				player:setTag("lirang", sgs.QVariant(lirangs))
				return self:objectName()
			end
		end
	end,

	on_cost = function(self,event,room,player,data)
		if not player:hasShownSkill(self:objectName()) and not player:askForSkillInvoke(self:objectName()) then
			player:removeTag("lirang")
            return false
		end
		if not player:hasShownSkill(self:objectName()) then
			player:setMark("lirang_notcancelable", 1)
		end
        return true
	end,

	on_effect = function(self,event,room,player,data)
        local move = data:toMoveOneTime()
        if move.from:objectName() ~= player:objectName() then return false end
		if move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
			local Qlirang_card = player:getTag("lirang"):toList()
			player:removeTag("lirang")
			local lirang_copy, lirang_card = sgs.IntList(), sgs.IntList()
			for _, id in sgs.qlist(Qlirang_card) do
				lirang_card:append(id:toInt())
				if room:getCardPlace(id:toInt()) == sgs.Player_DiscardPile then
					lirang_copy:append(id:toInt())
				end
			end

			if lirang_card:isEmpty() then return false end

			local preview_reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), "")
			local lirang_preview = sgs.CardsMoveStruct(lirang_card, nil, player, sgs.Player_DiscardPile, sgs.Player_PlaceHand, preview_reason)
			local lirang_preview_l = sgs.CardsMoveList()
			lirang_preview_l:append(lirang_preview)
			local _player = sgs.SPlayerList()
			_player:append(player)

			room:setPlayerFlag(player, "lirang_InTempMoving")
			room:notifyMoveCards(true, lirang_preview_l, false, _player)
			room:notifyMoveCards(false, lirang_preview_l, false, _player)
			room:setPlayerFlag(player, "-lirang_InTempMoving")

			local original_lirang = sgs.IntList()
			for _, id in sgs.qlist(lirang_card) do
				original_lirang:append(id)
			end
			local lirang_reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEWGIVE, player:objectName())
			local lirang_cancelable = true
			if player:getMark("lirang_notcancelable") > 0 then
				player:setMark("lirang_notcancelable", 0)
				lirang_cancelable = false
			end
			while room:askForYiji(player, lirang_card, self:objectName(), true, true, lirang_cancelable, -1,
				sgs.SPlayerList(), lirang_reason, "@lirang-distribute", lirang_cancelable) do
				lirang_cancelable = true
				local ids = sgs.IntList()
				for _, id in sgs.qlist(original_lirang) do
					if room:getCardPlace(id) ~= sgs.Player_DiscardPile then
						ids:append(id)
						lirang_card:removeOne(id)
					end
				end
				local lirang_give_preview = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, preview_reason)

				local original_lirang = sgs.IntList()
				for _, id in sgs.qlist(lirang_card) do
					original_lirang:append(id)
				end

				local lirang_give_preview_l = sgs.CardsMoveList()
				lirang_give_preview_l:append(lirang_give_preview)

				room:notifyMoveCards(true, lirang_give_preview_l, false, _player)
				room:notifyMoveCards(false, lirang_give_preview_l, false, _player)
				if player:isDead() then break end
			end

			if not lirang_card:isEmpty() then
				local lirang_return_preview = sgs.CardsMoveStruct(lirang_card, player, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile, preview_reason)
				local lirang_return_preview_l = sgs.CardsMoveList()
				lirang_return_preview_l:append(lirang_return_preview)
				room:notifyMoveCards(true, lirang_return_preview_l, true, _player)
				room:notifyMoveCards(false, lirang_return_preview_l, false, _player)
			end
		end
	end,
}

--[[
	连环
	相关武将：标-庞统
	描述：你可以将一张♣手牌当【铁索连环】使用；你能重铸♣手牌。    
	引用：
	状态：
]]

LuaLianhuan = sgs.CreateOneCardViewAsSkill{
	name = "LuaLianhuan",
	filter_pattern = ".|club|.|hand",
	response_or_use = true,
	view_as = function(self, originalCard)
		local chain = sgs.Sanguosha:cloneCard("iron_chain", originalCard:getSuit(), originalCard:getNumber())
        chain:addSubcard(originalCard)
        chain:setSkillName(self:objectName())
        chain:setShowSkill(self:objectName())
        return chain
	end,
}

--[[
	烈弓
	相关武将：标-黄忠
	描述：每当你于出牌阶段内使用【杀】指定一名角色为目标后，若该角色的手牌数不小于你的体力值或不大于你的攻击范围，你可以令其不能使用【闪】响应此次对其结算的此【杀】。 
	引用：
	状态：
]]

LuaLiegong = sgs.CreateTriggerSkill{
	name = "LuaLiegong",
	events = {sgs.TargetChosen},

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local use = data:toCardUse()
		if not use.card or not use.from then return false end
		if player:objectName() ~= use.from:objectName() or not use.card:isKindOf("Slash") then return false end			
		local targets = {}
		for _, p in sgs.qlist(use.to) do
			if p:getHandcardNum() >= player:getHp() or p:getHandcardNum() <= player:getAttackRange() then
				table.insert(targets, p:objectName())
			end
		end
		if #targets > 0 then
			return self:objectName().."->"..table.concat(targets,"+")
		else return false
		end
	end	,
	on_cost = function(self, event, room, target, data, player)
		local d = sgs.QVariant()
		d:setValue(target)
		return room:askForSkillInvoke(player, self:objectName(), d)
	end,
	on_effect = function(self, event, room, target, data, player)
		room:broadcastSkillInvoke(self:objectName(), 1, player)
		local use = data:toCardUse()
		local jink_list = player:getTag("Jink_"..use.card:toString()):toList()
		local log = sgs.LogMessage()
		log.type = "#NoJink"
		log.from = target
		room:sendLog(log)
		local index = use.to:indexOf(target)
		jink_list:replace(index,sgs.QVariant(0))
		player:setTag("Jink_"..use.card:toString(), sgs.QVariant(jink_list))
	end,
}

--[[
	烈弓 ——【授钺】之五虎将大旗
	相关武将：标-黄忠
	描述：烈弓的距离 +1。
	引用：
	状态：
]]

LuaLiegongRange = sgs.CreateAttackRangeSkill{
	name = "#LuaLiegong-for-lord",
	extra_func = function(self, target)
		if target:hasShownSkill("LuaLiegong") then
			local lord = target:getLord()
			if lord and lord:hasLordSkill("shouyue") and lord:hasShownGeneral1() then
                return 1
			end
		end
        return 0
	end,
}

--[[
	烈刃
	相关武将：标-祝融
	描述：每当你使用【杀】对目标角色造成伤害后，你可以与其拼点。若你赢，你获得其一张牌。    
	引用：
	状态：
]]

LuaLieren = sgs.CreateTriggerSkill{
	name = "LuaLieren",
	events = {sgs.Damage},
	
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and not player:isKongcheng()
			and not damage.to:isKongcheng() and damage.to ~= player and not damage.chain and not damage.transfer and not damage.to:hasFlag("Global_DFDebut") then
            return self:objectName() .. "->" .. damage.to:objectName()
		end
	end,

    on_cost = function(self, event, room, target, data, zhurong)
		if zhurong:askForSkillInvoke(self, data) then
			room:doAnimate(1, zhurong:objectName(), target:objectName())
			room:broadcastSkillInvoke(self:objectName(), 1, zhurong)
			local pd = zhurong:pindianSelect(target, self:objectName())
			local _data = sgs.QVariant()
			_data:setValue(pd)
            zhurong:setTag("lieren_pd", _data)
            return true
		end
	end,
	on_effect = function(self, event, room, target, data, zhurong)
		local pd = zhurong:getTag("lieren_pd"):toPindian()
        zhurong:removeTag("lieren_pd")
        if pd then
			local success = zhurong:pindian(pd)
			pd = nil
			if not success then return false end

			room:broadcastSkillInvoke(self:objectName(), 2, zhurong)
			if not target:isNude() then
				local card_id = room:askForCardChosen(zhurong, target, "he", self:objectName())
				reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, zhurong:objectName())
                room:obtainCard(zhurong, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
			end
		else
			assert(false)
		end
	end,
}

--[[
	流离
	相关武将：标-大乔
	描述：每当你成为【杀】的目标时，你可以弃置一张牌并选择你攻击范围内的一名其他角色，将此【杀】转移给该角色。   
	引用：
	状态：
]]

LuaLiuliCard = sgs.CreateSkillCard{
	name = "LuaLiuliCard" ,
	filter = function(self, targets, to_select, player)
		if #targets > 0 then return false end
		if to_select:hasFlag("LiuliSlashSource") or (to_select == player) then return false end
		local from
		for _, p in sgs.qlist(sgs.Self:getSiblings()) do
                if p:hasFlag("LiuliSlashSource") then
                    from = p
                    break
                end
            end
		local slash = sgs.Card_Parse(sgs.Self:property("liuli"):toString())
		if from and (not from:canSlash(to_select, slash, false)) then return false end
		local card_id = self:getSubcards():first()
		local range_fix = 0
		if sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == card_id) then
		local weapon = sgs.Self:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif sgs.Self:getOffensiveHorse() and (sgs.Self:getOffensiveHorse():getId() == card_id) then
			range_fix = range_fix + 1
		end
		return sgs.Self:distanceTo(to_select, range_fix) <= sgs.Self:getAttackRange()
	end,
	
	on_effect = function(self, effect)
		effect.to:setFlags("LiuliTarget")
	end,
}

LuaLiuliVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaLiuli" ,
	response_pattern = "@@LuaLiuli",
	filter_pattern = ".!",
	view_as = function(self, card)
		local liuli_card = LuaLiuliCard:clone()
		liuli_card:addSubcard(card)
		liuli_card:setSkillName(self:objectName())
		return liuli_card
	end,
}
	
LuaLiuli = sgs.CreateTriggerSkill{
	name = "LuaLiuli",
	events = {sgs.TargetConfirming} ,
	view_as_skill = LuaLiuliVS,
	can_preshow = true ,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash")
			and use.to:contains(player) and player:canDiscard(player,"he") then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			local can_invoke = false
			for _, p in sgs.qlist(players) do
				if use.from:canSlash(p, use.card, false) and player:inMyAttackRange(p) then
					can_invoke = true
					break
				end
			end
			if can_invoke then return self:objectName() end
		end
	end,

	on_cost = function(self, event, room, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local prompt = "@liuli:" .. use.from:objectName()
		room:setPlayerFlag(use.from, "LiuliSlashSource")
		d = sgs.QVariant()
		d:setValue(use.card)
		player:setTag("liuli-card", d)			--for the server (AI)		
		room:setPlayerProperty(player, "liuli", sgs.QVariant(use.card:toString()))		--for the client (UI)		
		local c = room:askForUseCard(player, "@@LuaLiuli", prompt, -1, sgs.Card_MethodDiscard)		
		player:removeTag("liuli-card")		
		room:setPlayerProperty(player, "liuli", sgs.QVariant())
		room:setPlayerFlag(use.from, "-LiuliSlashSource")		
		if c then return true end
		return false
	end,
		
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local players = room:getOtherPlayers(player)
		for _, p in sgs.qlist(players) do
			if p:hasFlag("LiuliTarget") then
				p:setFlags("-LiuliTarget")
				use.to:removeOne(player)
				use.to:append(p)
				room:sortByActionOrder(use.to)
				data:setValue(use)
				room:getThread():trigger(sgs.TargetConfirming, room, p, data)
				return false
			end
		end
		return false
	end,
}

--[[
	龙胆
	相关武将：标-赵云
	描述：你可以将一张【杀】当【闪】使用或打出；你可以将一张【闪】当【杀】使用或打出。 
	引用：
	状态：
]]

LuaLongdanVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaLongdan" ,
	response_or_use = true,
	view_filter = function(self, to_select)
		local card = to_select
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		else
			return false
		end
	end,
	
	view_as = function(self, originalCard)
		if originalCard:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", originalCard:getSuit(), originalCard:getNumber())
			jink:addSubcard(originalCard)
			jink:setSkillName(self:objectName())
			jink:setShowSkill(self:objectName())
			return jink
		elseif originalCard:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard)
			slash:setSkillName(self:objectName())
			slash:setShowSkill(self:objectName())
			return slash
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target)
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash") or (pattern == "jink")
	end,
}

--[[
	龙胆 ——【授钺】之五虎将大旗
	相关武将：标-赵云
	描述：“龙胆”增加描述：“你每发动一次‘龙胆’便摸一张牌”。
	引用：
	状态：
]]

LuaLongdan = sgs.CreateTriggerSkill{
	name = "LuaLongdan" ,
	events = {sgs.CardUsed,sgs.CardResponded},
	view_as_skill = LuaLongdanVS,

	can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasShownSkill(self) then return false end
        local lord = room:getLord(player:getKingdom())
        if lord and lord:hasLordSkill("shouyue") and lord:hasShownGeneral1() then
			local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
			end
            if card and card:getSkillName() == "LuaLongdan" then
                return self:objectName()
			end
		end
	end,
	on_cost = function(self,event,room,player,data)
		return true
	end,
	on_effect = function(self,event,room,player,data)
        local lord = room:getLord(player:getKingdom())
        room:notifySkillInvoked(lord, "shouyue")
        player:drawCards(1)
	end,
}

--[[
	乱击
	相关武将：标-袁绍
	描述：你可以将花色相同的两张手牌当【万箭齐发】使用。     
	引用：
	状态：
]]

LuaLuanji = sgs.CreateViewAsSkill{
	name = "LuaLuanji",
	response_or_use = true,
	view_filter = function(self,selected,to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
        elseif #selected == 1 then
			local card = selected[1]
			return not to_select:isEquipped() and to_select:getSuit() == card:getSuit()
		else
            return false
		end
	end,
	view_as = function(self,cards)
		if #cards == 2 then
			local aa = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_SuitToBeDecided, 0)
			for _, c in ipairs(cards) do
				aa:addSubcard(c)
			end
			aa:setSkillName(self:objectName())
			aa:setShowSkill(self:objectName())
			return aa
		else
			return nil
		end
	end,
}

--[[
	乱武
	相关武将：标-贾诩
	描述：限定技，出牌阶段，你可以选择所有其他角色，这些角色各需对距离最小的另一名角色使用一张【杀】，否则失去1点体力。    
	引用：
	状态：
]]

LuaLuanwuCard = sgs.CreateSkillCard{
	name = "LuaLuanwuCard",
	target_fixed = true,
	mute = true,
	about_to_use = function(self, room, use)
		room:removePlayerMark(use.from, "@chaos")
		room:broadcastSkillInvoke("LuaLuanwu", use.from)
		room:doSuperLightbox("jiaxu", "LuaLuanwu")
		
		local new_use = use
		for _, p in sgs.qlist(room:getOtherPlayers(use.from)) do
			new_use.to:append(p)
		end
		self:cardOnUse(room, new_use)

	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		local players = room:getOtherPlayers(effect.to)
		local distance_list = {}
		local nearest = 1000
		for _, p in sgs.qlist(players) do
			local distance = effect.to:distanceTo(p)
			table.insert(distance_list,distance)
			if distance ~= -1 then
				nearest = math.min(nearest, distance)
			end
		end

		local luanwu_targets = sgs.SPlayerList()
		for i = 1, #distance_list, 1 do
			if distance_list[i] == nearest and effect.to:canSlash(players:at(i - 1), nil, false) then
				luanwu_targets:append(players:at(i - 1))
			end
		end

		if (luanwu_targets:isEmpty() or not room:askForUseSlashTo(effect.to, luanwu_targets, "@luanwu-slash")) then
			room:loseHp(effect.to)
		end
	end,
}

LuaLuanwuVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaLuanwu",
	view_as = function(self)
		return LuaLuanwuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@chaos") >= 1
	end,
}

LuaLuanwu = sgs.CreateTriggerSkill{
	name = "LuaLuanwu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@chaos",
	view_as_skill = LuaLuanwuVS,
}

--[[
	洛神
	相关武将：标-甄姬
	描述：准备阶段开始时，你可以进行判定，若结果为黑色，你可以重复此流程。最后你获得所有的黑色判定牌。    
	引用：
	状态：
]]

luaLuoshen = sgs.CreateTriggerSkill{
	name = "luaLuoshen",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if player:getPhase() == sgs.Player_Start then return self:objectName() end
	end,
	on_cost = function(self, event, room, player, data)
		return room:askForSkillInvoke(player, self:objectName(), data)
	end,
		
	on_effect = function(self, event, room, player, data)
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
        local judge = sgs.JudgeStruct()
        judge.pattern = ".|black"
        judge.good = true;
        judge.reason = self:objectName()
        judge.play_animation = false
        judge.who = player
        judge.time_consuming = true
		room:judge(judge)

		while judge:isGood() and player:askForSkillInvoke(self:objectName()) do
			room:judge(judge)
		end
		local cards = sgs.IntList()
		card_list = player:getTag(self:objectName()):toList()
		for _, c in sgs.qlist(card_list) do
			cards:append(c:toCard():getEffectiveId())
		end
        player:removeTag(self:objectName())
        local subcards = sgs.IntList()
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        for _, id in sgs.qlist(cards) do
            if room:getCardPlace(id) == sgs.Player_PlaceTable and not subcards:contains(id) then
                subcards:append(id)
				dummy:addSubcard(id)
			end
		end
		if not subcards:isEmpty() then
			player:obtainCard(dummy)
		end
        return false
	end,
}

luaLuoshenMove = sgs.CreateTriggerSkill{
	name = "#luaLuoshen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.FinishJudge},
	can_trigger = function(self, event, room, player, data)
		if player then
			local judge = data:toJudge()
			if judge.reason == "luaLuoshen" and judge:isGood() then
				return self:objectName()
			end
		end
	end,
	on_effect = function(self, event, room, player, data)
	    local judge = data:toJudge()
		card_list = player:getTag("luaLuoshen"):toList()
		local card = sgs.QVariant()
		card:setValue(judge.card)
		card_list:append(card)
		player:setTag("luaLuoshen", sgs.QVariant(card_list))
		if room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_JUDGEDONE, player:objectName(), "", judge.reason)
			room:moveCardTo(judge.card, nil, sgs.Player_PlaceTable, reason, true)
		end
        return false
	end,
}

--[[
	裸衣
	相关武将：标-许褚
	描述：摸牌阶段，你可以少摸一张牌，若如此做，每当你于此回合内使用【杀】或【决斗】对目标角色造成伤害时，此伤害+1。     
	引用：
	状态：
]]

luaLuoyi = sgs.CreateTriggerSkill{
	name = "luaLuoyi",
	frequency = sgs.Skill_NotFrequent,
	can_preshow = true,
	events = {sgs.DrawNCards,sgs.DamageCaused,sgs.PreCardUsed},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if event == sgs.DrawNCards then
			return self:objectName()
		elseif event == sgs.PreCardUsed then
			if player:hasFlag("luoyi") then
				local use = data:toCardUse()
				if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) then
					room:setCardFlag(use.card, self:objectName())
				end
			end
		else
			if player:hasFlag("luoyi") then
				local damage = data:toDamage()
				if damage.card and damage.card:hasFlag("luoyi") and not damage.chain and not damage.transfer and damage.by_user then
					return self:objectName()
				end
			end
		end
	end,
	
	on_cost = function(self,event,room,player,data)
		if event == sgs.DamageCaused then
			room:broadcastSkillInvoke(self:objectName(), 1, player)
			return true
		elseif player:askForSkillInvoke(self:objectName()) then
            data = data:toInt() - 1
			room:broadcastSkillInvoke(self:objectName(), 2, player)
			return true
		end
        return false
	end,
	
	on_effect = function(self,event,room,player,data)
		if event == sgs.DamageCaused then
		local damage = data:toDamage()
		
			local log = sgs.LogMessage()
			log.type = "#LuoyiBuff"
            log.from = player
			log.to:append(damage.to)
            log.arg = damage.damage
            log.arg2 = damage.damage + 1
			room:sendLog(log)
			
			damage.damage = damage.damage + 1
			data:setValue(damage)
		else
            room:setPlayerFlag(player, self:objectName())
		end
	end,
}
