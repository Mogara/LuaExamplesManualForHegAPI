--[[
	国战技能速查手册（H区）
	技能索引：
	好施、鹤翼、横江、横征、弘法、红颜、护援、怀异、魂殇、火计、祸首、祸水      
]]--
--[[
	好施
	相关武将：标-鲁肃
	描述：摸牌阶段，你可以额外摸两张牌，然后若你的手牌数大于5，你将一半（向下取整）的手牌交给手牌最少的一名其他角色。  
	引用：
	状态：
]]


LuaHaoshiCard = sgs.CreateSkillCard{
	name = "LuaHaoshiCard",
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodNone,
    m_skillName = "_haoshi",
	filter = function(self,targets,to_select,Self)
		if #targets > 0 or to_select:objectName() == Self:objectName() then
			return false
		end
		return to_select:getHandcardNum() == Self:getMark("luahaoshi")
	end,
	on_use = function(self,room,source,targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(),
			targets[1]:objectName(), "Luahaoshi", "")
		room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, reason)
	end,
}

LuaHaoshiVS = sgs.CreateViewAsSkill{
	name = "Luahaoshi",
	response_pattern = "@@Luahaoshi!",

	view_filter = function(self,selected,to_select)
		if to_select:isEquipped() then return false end
		local length = math.floor(sgs.Self:getHandcardNum() / 2)
		return #selected < length
	end,
	view_as = function(self,cards)
		if #cards ~= math.floor(sgs.Self:getHandcardNum() / 2) then return nil end
		local card = LuaHaoshiCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
        return card
	end,
}

Luahaoshi = sgs.CreateDrawCardsSkill{
	name = "Luahaoshi",
	view_as_skill = LuaHaoshiVS,
	can_preshow = true,
	on_cost = function(self,event,room,player)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	draw_num_func = function(self,player,n)
        player:setFlags("luahaoshi")
        return n + 2
	end,
}

LuaHaoshiGive = sgs.CreateTriggerSkill{
	name = "#Luahaoshi-give",
	events = {sgs.AfterDrawNCards},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self,event,room,lusu)
		if not lusu or not lusu:isAlive() or not lusu:hasShownSkill("Luahaoshi") then return false end
		if lusu:hasFlag("luahaoshi") then
			lusu:setFlags("-luahaoshi")
			if lusu:getHandcardNum() <= 5 then return false end
            return self:objectName()
		end
	end,
	on_effect = function(self,event,room,lusu)
		local other_players = room:getOtherPlayers(lusu)
		local least = 1000
		for _, player in sgs.qlist(other_players) do
            least = math.min(player:getHandcardNum(), least)
		end
		room:setPlayerMark(lusu, "luahaoshi", least)
		if not room:askForUseCard(lusu, "@@Luahaoshi!", "@haoshi", -1, sgs.Card_MethodNone) then
			--force lusu to give his half cards
			local beggar
			for _, player in sgs.qlist(other_players) do
				if player:getHandcardNum() == least then
                    beggar = player
                    break
				end
			end
			local n = math.floor(lusu:getHandcardNum() / 2)
			local to_give = lusu:handCards():mid(0, n)
			local haoshi_card = LuaHaoshiCard:clone()
			for _, card_id in sgs.qlist(to_give) do
				haoshi_card:addSubcard(card_id)
			end
			local targets = {beggar}
			haoshi_card:on_use(room, player, targets)
		end
	end,
}

--[[
	鹤翼
	相关武将：阵-曹洪
	描述：阵法技，与你处于同一队列的其他角色视为拥有“飞影”。  
	引用：
	状态：
]]

LuaHeyiSummonCard = sgs.CreateArraySummonCard{
	name = "LuaHeyi",
    mute = true,
}

LuaHeyiVS = sgs.CreateArraySummonSkill{
	name = "LuaHeyi",
	array_summon_card = LuaHeyiSummonCard,
}

LuaHeyi = sgs.CreateTriggerSkill{
	name = "LuaHeyi",
	is_battle_array = true,
	battle_array_type = sgs.Formation,
	view_as_skill = LuaHeyiVS,
	events = {sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved, sgs.Death, sgs.RemoveStateChanged},
	can_preshow = false,

	can_trigger = function(self,event,room,player,data)
		if not player then return false end
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (p:getMark("LuaFeiying") > 0) then
						room:setPlayerMark(p, "LuaFeiying", 0)
						room:detachSkillFromPlayer(p, "LuaFeiying", true, true)
					end
				end
				return false
			end
			if death.who:getMark("LuaFeiying") > 0 then
				room:setPlayerMark(death.who, "LuaFeiying", 0)
				room:detachSkillFromPlayer(death.who, "LuaFeiying", true, true)
			end
		end
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if (p:getMark("LuaFeiying") > 0) then
				room:setPlayerMark(p, "LuaFeiying", 0)
				room:detachSkillFromPlayer(p, "LuaFeiying", true, true)
			end
		end
		if room:alivePlayerCount() < 4 then return false end

		local caohongs = room:findPlayersBySkillName(self:objectName())
		for _, caohong in sgs.qlist(caohongs) do
			if caohong:hasShownSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getOtherPlayers(caohong)) do
					if caohong:inFormationRalation(p) then
						room:setPlayerMark(p, "LuaFeiying", 1)
                        room:attachSkillToPlayer(p, "LuaFeiying")
					end
				end
			end
		end
	end,
}

LuaHeyiFeiying = sgs.CreateDistanceSkill{
	name = "#LuaHeyi_feiying",

	correct_func = function(self, from, to)
		if to:getMark("LuaFeiying") > 0 then
            return 1
		else
			return 0
		end
	end,
}

LuaHeyiEffect = sgs.CreateTriggerSkill{
	name = "#LuaHeyi_effect",
	events = {sgs.EventPhaseStart, sgs.GeneralShown},
	frequency = sgs.Skill_Compulsory,
	priority = 8,
	can_preshow = false,

	can_trigger = function(self,event,room,player,data)
		if event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart then
				local caohong = room:findPlayerBySkillName("LuaHeyi")
				if caohong and caohong:isAlive() and caohong:hasShownSkill("LuaHeyi") and player:inFormationRalation(caohong) then
					return self:objectName(), caohong
				end
			end
		elseif event == sgs.GeneralShown then
			if player and player:isAlive() and player:hasShownSkill("LuaHeyi") and data:toBool() == player:inHeadSkills("LuaHeyi") then
                return self:objectName(), player
			end
		end
	end,

    on_cost = function(self,event,room,player,data,ask_who)
		if ask_who:hasShownSkill("LuaHeyi") then
			room:broadcastSkillInvoke("LuaHeyi", ask_who)
		end
	end,
}

LuaFeiying = sgs.CreateTriggerSkill{
	name = "LuaFeiying",
	frequency = sgs.Skill_Compulsory,
	can_preshow = false,
}

--[[
	横江
	相关武将：势-臧霸
	描述：每当你受到1点伤害后，你可以令当前回合角色本回合手牌上限-1，然后其回合结束时，若你于此回合发动过“横江”，且其未于弃牌阶段内弃置牌，你摸一张牌。 
	引用：
	状态：
]]
--[[
	横征
	相关武将：势-董卓
	描述：摸牌阶段开始时，若你的体力值为1或你没有手牌，你可以放弃摸牌，获得每名其他角色区域里的一张牌。  
	引用：
	状态：
]]
--[[
	弘法
	相关武将：势-君张角
	描述：君主技，此武将牌明置时，你获得“黄巾天兵符”。准备阶段开始时，若“黄巾天兵符”上没有牌，则从牌堆顶亮出X张牌置于“黄巾天兵符”上，称为“天兵”（X为全场存活的群势力角色数）。
		★黄巾天兵符★
		你执行的效果中的“群势力角色的数量”+X（X为不大于“天兵”数量的自然数）；每当你失去体力时，你可以防止此失去体力，将一张“天兵”置入弃牌堆；与你势力相同的角色可以将一张“天兵”当【杀】使用或打出。  
	引用：LuaHongfa
	状态：未测试
]]
LuaHongfa = sgs.CreateTriggerSkill{
	name = "LuaHongfa$",
	events = {sgs.ConfirmPlayerNum, sgs.EventPhaseStart, sgs.PreHpLost, sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved, sgs.Death},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.ConfirmPlayerNum then
			if not player or player:isDead() or not player:hasLordSkill(objectName()) then
				return ""
			end
			if player:getPile("heavenly_army"):isEmpty() then
				return ""
			end
			local player_num = sgs.PlayerNumStruct()
			if player_num.m_toCalculate ~= "qun" then
				return ""
			end
			return self:objectName()
		elseif event == sgs.EventPhaseStart then
			if not player or not player:isAlive() or not player:hasLordSkill(objectName()) then
				return ""
			end
			if player:getPhase() ~= sgs.Player_Start then
				return ""
			end
			if not player:getPile("heavenly_army"):isEmpty() then
				return ""
			end
			return self:objectName()
		elseif event == sgs.PreHpLost then
			if not player or not player:isAlive() or not player:hasLordSkill(objectName()) then
				return ""
			end
			if player:getPile("heavenly_army"):isEmpty() then
				return ""
			end
			return self:objectName()
		else
			if player == nil then
				return ""
			end
			if event == sgs.GeneralShown and player:hasShownGeneral1() then
				if player and player:isAlive() and player:hasLordSkill(self:objectName()) then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:willBeFriendWith(player) then
							room:attachSkillToPlayer(p, "hongfa_slash")
						end
					end
				else
					local lord = room:getLord(player:getKingdom())
					if lord and lord:isAlive() and lord:hasLordSkill(self:objectName())
						room:attachSkillToPlayer(player, "hongfa_slash")
					end
				end
			elseif player and player:isAlive() and player:hasLordSkill(self:objectName()) then
				if event == sgs.Death then
					local death = sgs.DeathStruct()
					if death.who:objectName() ~= player:objectName() then
						return ""
					end
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:detachSkillFromPlayer(p, "hongfa_slash")
				end
			end
			return ""
		end
		return ""
	end
	on_cost = function(self, event, room, player, data)
		if event == sgs.ConfirmPlayerNum then
			local player_num = sgs.PlayerNumStruct()
			if player_num.m_type == sgs.MaxCardsType_Max then
				player_num.m_num == player_num.m_num + player:getPile("heavenly_army"):length()
			elseif player_num.m_type == sgs.MaxCardsType_Normal then
				local d = sgs.QVariant()
				d:setValue(data)
				player:setTag("LuaHongfaTianbingData", d)
				local prompt = string.format("@LuaHongfa-tianbing:%1", player_num.m_reason)
				local card = room:askForExchange(player, "LuaHongfa2", player:getPile("heavenly_army"):length(), 0, prompt,"heavenly_army")
				player:removeTag("LuaHongfaTianbingData")
				if card then
					player:showGeneral(player:inHeadSkills(self:objectName()))
					player_num.m_num = player_num.m_num + card:subcardsLength()
					room:notifySkillInvoked(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName(),2)
					card:deleteLater()
				end
			end
			data:setValue(player_num)
			return false
		elseif event == sgs.EventPhaseStart then
			return true
		elseif event == sgs.PreHpLost then
			player:removeTag("LuaHongfa_prevent")
			local card = room:askForExchange(player, "LuaHongfa1", 1, 0, "@LuaHongfa-prevent", "heavenly_army")
			if card then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				local d = sgs.QVariant()
				d:setValue(card:getEffectiveId())
				player:setTag("LuaHongfa_prevent", d)
				card:deleteLater()
				return true
			end
		end
		return false
	end
	on_effect = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart then
			local num = player:getPlayerNumWithSameKingdom("LuaHongfa", QString(), sgs.MaxCardsType_Normal)
			local tianbing = room:getNCards(num)
			player:addToPile("heavenly_army", tianbing)
			return false
		else
			local card_id = sgs.QList2Table(player:getTag("LuaHongfa_prevent"):toInt())
			player:removeTag("LuaHongfa_prevent")
			if card_id ~= -1 then
				local reason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
				return true
			end
		end
		return false
	end
}
--[[
	红颜
	相关武将：标-小乔
	描述：锁定技，你的♠牌视为♥牌。  
	引用：
	状态：
]]

LuaHongyanVS = sgs.CreateFilterSkill{
	name = "LuaHongyan",
	view_filter = function(self, to_select)
		local room = sgs.Sanguosha:currentRoom()
		if room then
			for _, p in sgs.qlist(room:getPlayers()) do
				if p:ownSkill(self:objectName()) and p:hasShownSkill(self:objectName()) then
					return to_select:getSuit() == sgs.Card_Spade
				end
			end
		else
			for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
				if p:ownSkill(self:objectName()) and p:hasShownSkill(self:objectName()) then
					return to_select:getSuit() == sgs.Card_Spade
				end
			end
		end
		return false
	end,
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
        return new_card
	end,
}

LuaHongyan = sgs.CreateTriggerSkill{
	name = "LuaHongyan",
	events = {sgs.FinishRetrial},
	frequency = sgs.Skill_Compulsory,
	view_as_skill = LuaHongyanVS,
	can_trigger = function(self,event,room,xiaoqiao,data)
		if not xiaoqiao or xiaoqiao:isDead() or not xiaoqiao:hasSkill(self:objectName()) then return false end
		local judge = data:toJudge()
		if judge.who:objectName() == xiaoqiao:objectName() and judge.card:getSuit() == sgs.Card_Spade then
			return self:objectName()
		end
	end,
	
	on_cost = function(self,event,room,xiaoqiao,data)
        return xiaoqiao:hasShownSkill(self:objectName()) or xiaoqiao:askForSkillInvoke(self:objectName(), data)
	end,
	on_effect = function(self,event,room,xiaoqiao,data)
		local judge = data:toJudge()
		local cards = sgs.CardList()
		cards:append(judge.card)
        room:filterCards(xiaoqiao, cards, true)
        judge:updateResult()
        return false
	end,
}

--[[
	护援
	相关武将：阵-曹洪
	描述：结束阶段开始时，你可以将一张装备牌置入一名角色的装备区，若如此做，你可以弃置该角色距离为1的一名角色的一张牌。 
	引用：
	状态：
]]

--[[
	怀异
	相关武将：身份-公孙渊
	描述：出牌阶段限一次，你可展示所有手牌，若其中不止一种颜色，你弃置其中一种颜色所有手牌，然后获得至多X名角色各一张牌（X为你以此法弃置的手牌数）；若你以此法获得的牌不少于两张，你失去一点体力。 
	引用：
	状态：2.0
	相关翻译 {
		["@LuaHuaiyi"] = "你可获得至多 %arg 名其他角色各一张牌",
	}
]]

LuaHuaiyiCard = sgs.CreateSkillCard{
	name = "LuaHuaiyiCard",
	skill_name = "LuaHuaiyi",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,

	on_use = function(self, room, source, targets)
		room:showAllCards(source)
		local same_color = true
		for _, card in sgs.qlist(source:getHandcards()) do
			if not card:sameColorWith(source:getHandcards():first()) then
				same_color = false
				break
			end
		end
		if same_color then return false end
		local choice = room:askForChoice(source, self:getSkillName(), "no_suit_red+no_suit_black")
		local dummy = sgs.Sanguosha:cloneCard("jink")
		for _, card in sgs.qlist(source:getHandcards()) do
			if (choice == "no_suit_red" and card:isRed()) or (choice == "no_suit_black" and card:isBlack()) then
				dummy:addSubcard(card)
			end
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, source:objectName(), self:getSkillName(), "")
		room:throwCard(dummy, reason, source, nil, self:getSkillName())
		local to_targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if not p:isNude() then to_targets:append(p) end
		end
		local _targets = room:askForPlayersChosen(source, to_targets, self:getSkillName(), 0, dummy:subcardsLength(), "@"..self:getSkillName()..":::"..dummy:subcardsLength(), true)	
		dummy:deleteLater()

		local moves = sgs.CardsMoveList()
		reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName(), self:getSkillName(), "")
		for _, p in sgs.qlist(_targets) do
			local id = room:askForCardChosen(source, p, "he", self:getSkillName())
			local move = sgs.CardsMoveStruct(id, source, sgs.Player_PlaceHand, reason)
			moves:append(move)
		end
		room:moveCardsAtomic(moves, false)
		if source:isAlive() and moves:length() >= 2 then room:loseHp(source) end
	end,
}

LuaHuaiyi = sgs.CreateZeroCardViewAsSkill{   
	name = "LuaHuaiyi",
	
	view_as = function(self)
		local skillcard = LuaHuaiyiCard:clone()
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,

	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaHuaiyiCard")
	end,
}


--[[
	魂殇
	相关武将：势-孙策
	描述：副将技，此武将牌上单独的阴阳鱼个数-1；副将技，准备阶段开始时，若你的体力值为1，你拥有“英姿”和“英魂”，直到回合结束。  
	引用：
	状态：
]]
--[[
	火计
	相关武将：标-卧龙诸葛亮
	描述：你可以将一张红色手牌当【火攻】使用。 
	引用：
	状态：
]]

LuaHuoji = sgs.CreateOneCardViewAsSkill{
	name = "LuaHuoji",
	filter_pattern = ".|red|.|hand",
	response_or_use = true,
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
		fireattack:setSkillName(self:objectName())
		fireattack:setShowSkill(self:objectName())
		fireattack:addSubcard(id)
		return fireattack
	end
}

--[[
	祸首
	相关武将：标-孟获
	描述：锁定技，【南蛮入侵】对你无效；锁定技，每当其他角色使用【南蛮入侵】指定目标后，你将此【南蛮入侵】造成的伤害的来源改为你。 
	引用：
	状态：
]]

LuaSavageAssaultAvoid = sgs.CreateTriggerSkill{
	name = "#LuaSavageAssaultAvoid",
    events = {sgs.CardEffected},
    frequency = sgs.Skill_Compulsory,

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill("LuaHuoshou") then return false end
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("LuaHuoshou") or player:askForSkillInvoke("LuaHuoshou") then
			room:broadcastSkillInvoke("LuaHuoshou", 1, player)
			player:showGeneral(player:inHeadSkills("LuaHuoshou"))
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
		room:notifySkillInvoked(player, "LuaHuoshou")
		local log = sgs.LogMessage()
		log.type = "#SkillNullify"
		log.from = player
		log.arg = "LuaHuoshou"
		log.arg2 = "savage_assault"
		room:sendLog(log)
		return true
	end,
}

LuaHuoshou = sgs.CreateTriggerSkill{
	name = "LuaHuoshou",
	events = {sgs.TargetChosen,sgs.ConfirmDamage,sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self, event, room, player, data)
		if not player then return false end
		if event == sgs.TargetChosen then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				local menghuo = room:findPlayerBySkillName(self:objectName())
				if menghuo and menghuo:isAlive() and use.from:objectName() ~= menghuo:objectName() then
					return self:objectName(),menghuo
				end
			end
		elseif event == sgs.ConfirmDamage and room:getTag("HuoshouSource"):toPlayer() then
			local damage = data:toDamage()
			if not damage.card or not damage.card:isKindOf("SavageAssault") then return false end
			
			local menghuo = room:getTag("HuoshouSource"):toPlayer()
			if menghuo:isAlive() then
				damage.from = menghuo
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				room:removeTag("HuoshouSource")
			end
		end
	end,

	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:hasShownSkill(self) or ask_who:askForSkillInvoke(self) then
			room:broadcastSkillInvoke(self:objectName(), 2, ask_who)
			return true
		end
	end,

	on_effect = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(ask_who, self:objectName(),true)
		local d = sgs.QVariant()
		d:setValue(ask_who)
        room:setTag("HuoshouSource", d)
	end,
}

--[[
	祸水
	相关武将：标-邹氏
	描述：出牌阶段，你可以明置此武将牌；其他角色于你的回合内不能明置其武将牌。  
	引用：
	状态：
]]

LuaHuoshui = sgs.CreateTriggerSkill{
	name = "LuaHuoshui",
	events = {sgs.GeneralShown, sgs.GeneralHidden, sgs.GeneralRemoved, sgs.EventPhaseStart, sgs.Death, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	view_as_skill = LuaHuoshuiVS,

	can_trigger = function(self,event,room,player,data)
		local function doHuoshui(room, zoushi, set)
			if set and not zoushi:getTag("huoshui"):toBool() then
				for _, p in sgs.qlist(room:getOtherPlayers(zoushi)) do
					room:setPlayerDisableShow(p, "hd", "LuaHuoshui")
				end
				zoushi:setTag("huoshui", sgs.QVariant(true))
			elseif not set and zoushi:getTag("huoshui"):toBool() then
				for _, p in sgs.qlist(room:getOtherPlayers(zoushi)) do
					room:removePlayerDisableShow(p, "LuaHuoshui")
				end
				zoushi:setTag("huoshui", sgs.QVariant(false))
			end
		end
		if not player then return false end
		if event ~= sgs.Death and not player:isAlive() then return false end

		local c = room:getCurrent()
		if not c or (event ~= sgs.EventPhaseStart and c:getPhase() == sgs.Player_NotActive) or c:objectName() ~= player:objectName() then return false end

		if ((event == sgs.GeneralShown or event == sgs.EventPhaseStart or event == sgs.EventAcquireSkill) and not player:hasShownSkill(self:objectName())) then return false end
		if ((event == sgs.GeneralShown or event == sgs.GeneralHidden) and (not player:ownSkill(self:objectName()) or player:inHeadSkills(self:objectName()) ~= data:toBool())) then return false end
		if event == sgs.GeneralRemoved then
			local general = data:toString()
			local ok
			for _, sk in sgs.qlist(general:getSkillList()) do
				if sk:objectName() == self:objectName() then
					ok = true
					break
				end
			end
			if not ok then return false end
		end
		if (event == sgs.EventPhaseStart and not (player:getPhase() == sgs.Player_RoundStart or player:getPhase() == sgs.Player_NotActive)) then return false end
		if (event == sgs.Death and (data:toDeath().who:objectName() ~= player:objectName() or not player:hasShownSkill(self:objectName()))) then return false end
		if ((event == sgs.EventAcquireSkill or event == sgs.EventLoseSkill) and data:toString() ~= self:objectName()) then return false end

		local set = false
		if (event == sgs.GeneralShown or event == sgs.EventAcquireSkill or (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart)) then
			set = true
		end
		doHuoshui(room, player, set)
	end,
}
