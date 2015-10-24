--[[
	国战技能速查手册（Y区）
	技能索引：
	燕语、业炎、疑城、遗计、遗志、英魂、鹰扬、英姿、勇决、勇略、诱敌
]]--

--[[
	燕语
	相关武将：身份-夏侯氏
	描述：出牌阶段，你可以重铸【杀】。出牌阶段结束时，若你于此阶段以此法重铸了两张或更多的【杀】，则你可以令一名男性角色摸两张牌。
	引用：
	状态：2.0
	相关翻译 {
		["LuaYanyu-invoke"] = "燕语：你可令一名男性角色摸两张牌",
	}
]]

LuaYanyuCard = sgs.CreateSkillCard{
	name = "LuaYanyuCard",
	skill_name = "LuaYanyu",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodRecast,
	can_recast = true;

	about_to_use = function(self, room, cardUse)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, cardUse.from:objectName(), self:getSkillName(), "")
		reason.m_skillName = self:getSkillName()
		room:moveCardTo(self, cardUse.from, nil, sgs.Player_DiscardPile, reason, true)
		cardUse.from:broadcastSkillInvoke("@recast")

		local log = sgs.LogMessage()
		log.type = "#UseCard_Recast"
		log.from = cardUse.from
		log.card_str = tostring(cardUse.card:getSubcards():first())
		room:sendLog(log)

		if cardUse.from:ownSkill(self:showSkill()) and not cardUse.from:hasShownSkill(self:showSkill()) then
			cardUse.from:showGeneral(cardUse.from:inHeadSkills(self:showSkill()))
		end
		cardUse.from:addMark(self:getSkillName())
		cardUse.from:drawCards(1)
	end,
}

LuaYanyuVS = sgs.CreateOneCardViewAsSkill{   
	name = "LuaYanyu",
	filter_pattern = "Slash",

	view_as = function(self, originalCard)
		local skillcard = sgs.Self:isCardLimited(originalCard, sgs.Card_MethodRecast) and nil or LuaYanyuCard:clone()
		skillcard:addSubcard(originalCard)
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,

	enabled_at_play = function(self, player)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		return not player:isCardLimited(slash, sgs.Card_MethodRecast)
	end,
}

LuaYanyu = sgs.CreateTriggerSkill{
	name = "LuaYanyu",
	events = {sgs.EventPhaseEnd, sgs.EventPhaseStart},
	view_as_skill = LuaYanyuVS,

	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			player:setMark(self:objectName(), 0)
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			if player:getMark(self:objectName()) >= 2 then return self:objectName() end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:isMale() then targets:append(p) end
		end 
		local target = room:askForPlayerChosen(player, targets, self:objectName(), self:objectName().."-invoke", true, true)
		if target then
			local target_data = sgs.QVariant()
			target_data:setValue(target)
			player:setTag(self:objectName(), target_data)
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local target = player:getTag(self:objectName()):toPlayer()
		if target and target:isAlive() then
			target:drawCards(2)
		end
		return false 
	end,
}

--[[
	宴诛
	相关武将：身份-孙休
	描述：出牌阶段限一次，你可以令一名有牌的其他角色选择一项：令你获得其装备区里所有的牌，然后你失去技能“宴诛”，直到游戏结束；或弃置一张牌。
	引用：
	状态：2.0
	相关翻译 {
		["@LuaYanzhu-discard"] = "宴诛：弃置一张牌，或令 %src 获得你装备区所有牌并失去“宴诛”。<br/>提示：若你装备区没有牌，则你必须弃置一张牌" ,
	}
]]

LuaYanzhuCard = sgs.CreateSkillCard{
	name = "LuaYanzhuCard",
	skill_name = "LuaYanzhu",
	target_fixed = false,
	handling_method = sgs.Card_MethodNone,

	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isNude()
	end,
	
	feasible = function(self, targets, player)
		return #targets == 1
	end,

	on_use = function(self, room, source, targets)
		if not room:askForDiscard(targets[1], self:getSkillName(), 1, 1, not targets[1]:getEquips():isEmpty(), true, "@"..self:getSkillName().."-discard:"..source:objectName()) then 
			local dummy = sgs.Sanguosha:cloneCard("jink")
			dummy:addSubcards(targets[1]:getEquips())
			room:obtainCard(source, dummy)
			dummy:deleteLater()
			room:handleAcquireDetachSkills(source, "-"..self:getSkillName())
		end
	end,
}

LuaYanzhu = sgs.CreateZeroCardViewAsSkill{   
	name = "LuaYanzhu",
	
	view_as = function(self)
		local skillcard = LuaYanzhuCard:clone()
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,

	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaYanzhuCard")
	end,
}

--[[
	业炎
	相关武将：身份-神·周瑜
	描述：限定技，出牌阶段，你可选择一项：1．选择一至三名角色，对这些角色各造成1点火焰伤害；2．弃置四张花色各不相同的手牌并选择一至两名角色，失去3点体力，然后对这些角色造成至多共3点火焰伤害（其中一名角色分配的点数须不小于2）。
	引用：
	状态：1.2.1验证通过
]]

LuaYeyanCard = sgs.CreateSkillCard{
	name = "LuaYeyanCard",
	skill_name = "LuaYeyan",
	target_fixed = false,
	will_throw = true,

	filter = function(self, targets, to_select, player)
		if self:subcardsLength() == 4 then
			local n = 0
			for _, target in ipairs(targets) do
				if target:objectName() == to_select:objectName() then n = n+1 end
			end
			return (#table.toSet(targets) < 2 or table.contains(targets, to_select)) and (3 - #targets) + n or 0
		end
		return #targets < 3
	end,
	
	feasible = function(self, targets, player)
		if self:subcardsLength() == 4 then
			return #targets - #table.toSet(targets) >= 1
		end
		return #targets > 0
	end,

	about_to_use = function(self, room, cardUse)
		room:removePlayerMark(cardUse.from, "@yeyan")
		local index = self:subcardsLength() == 4 and 2 or 1
		room:broadcastSkillInvoke(self:objectName(), index, cardUse.from);
		room:doSuperLightbox(cardUse.from:getGeneralName(), self:getSkillName())
		self:cardOnUse(room, cardUse)
	end,

	on_use = function(self, room, source, targets)
		if self:subcardsLength() == 4 then room:loseHp(source, 3) end

		local targets2 = sgs.SPlayerList()
		for _, tar in ipairs(table.toSet(targets)) do targets2:append(tar) end
		room:sortByActionOrder(targets2)

		for _, target in sgs.qlist(targets2) do
			local point = 0
			for _, tar in ipairs(targets) do 
				if tar == target then point = point +1 end
			end
			room:damage(sgs.DamageStruct(self:objectName(), source, target, point, sgs.DamageStruct_Fire))
		end
	end,
}

LuaYeyan = sgs.CreateViewAsSkill{   
	name = "LuaYeyan",
	limit_mark = "@yeyan",
	
	view_filter = function(self, selected, to_select)
		for _, card in ipairs(selected) do 
			if to_select:getSuit() == card:getSuit() then return false end
		end
		return #selected < 4 and not to_select:isEquipped()
	end, 

	view_as = function(self, originalCards) 
		if #originalCards == 0 or #originalCards == 4 then
			local skillcard = LuaYeyanCard:clone()
			for _, card in ipairs(originalCards) do
				skillcard:addSubcard(card)
			end
			skillcard:setSkillName(self:objectName())
			skillcard:setShowSkill(self:objectName())
			return skillcard
		end
	end, 

	enabled_at_play = function(self, player)
		return player:getMark("@yeyan") > 0
	end,
}

--[[
	疑城
	相关武将：阵-徐盛
	描述：每当与你势力相同的一名角色成为【杀】的目标后，你可以令该角色摸一张牌，然后其弃置一张牌。 
	引用：
	状态：
]]
--[[
	遗计
	相关武将：标-郭嘉
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，然后将其中的一张牌交给一名角色，将另一张牌交给一名角色。 
	引用：
	状态：
]]

luaYiji = sgs.CreateTriggerSkill{
	name = "luaYiji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)	
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local trigger_list = {}
		for i = 1, damage.damage, 1 do
			table.insert(trigger_list, self:objectName())
		end
		return table.concat(trigger_list,",")
	end,
	on_cost = function(self, event, room, player, data)
		return room:askForSkillInvoke(player, self:objectName(), data)
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		local _guojia = sgs.SPlayerList()
		_guojia:append(player)
		local yiji_cards = room:getNCards(2, false)
		local move = sgs.CardsMoveStruct(yiji_cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
		local moves = sgs.CardsMoveList()
		moves:append(move)
		room:notifyMoveCards(true, moves, false, _guojia)
		room:notifyMoveCards(false, moves, false, _guojia)
		local origin_yiji = sgs.IntList()
		for _, id in sgs.qlist(yiji_cards) do
			origin_yiji:append(id)
		end
		while room:askForYiji(player, yiji_cards, self:objectName(), true, false, true, -1, room:getAlivePlayers()) do
			local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
			for _, id in sgs.qlist(origin_yiji) do
				if room:getCardPlace(id) ~= sgs.Player_DrawPile then
					move.card_ids:append(id)
					yiji_cards:removeOne(id)
				end
			end
			origin_yiji = sgs.IntList()
			for _, id in sgs.qlist(yiji_cards) do
				origin_yiji:append(id)
			end	
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			if not player:isAlive() then return end
		end
		if not yiji_cards:isEmpty() then
			local move = sgs.CardsMoveStruct(yiji_cards, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			for _, id in sgs.qlist(yiji_cards) do
				player:obtainCard(sgs.Sanguosha:getCard(id), false)
			end
		end
	end,
}

--[[
	遗志
	相关武将：阵-姜维
	描述：副将技，此武将牌上单独的阴阳鱼个数-1；副将技，若你的主将有“观星”，此“观星”描述中的X视为5，否则你视为拥有“观星”。 
	引用：
	状态：
	备注：阴阳鱼减少不在技能里
]]

LuaYizhi = sgs.CreateTriggerSkill{
	name = "LuaYizhi",
	relate_to_place = "deputy",
	frequency = sgs.Skill_Compulsory;
	events = {sgs.GameStart,sgs.EventPhaseStart},
	can_preshow = false,
	can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self) then return false end
		if event == sgs.GameStart then
			local guanxing = sgs.Sanguosha:getSkill("luaGuanxing")
			if guanxing and guanxing:inherits("TriggerSkill") then
				local guanxing_trigger = sgs.Sanguosha:getTriggerSkill("luaGuanxing")
				room:getThread():addTriggerSkill(guanxing_trigger)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if not player:hasSkill("luaGuanxing") then
                return "luaGuanxing"
			end
		end
	end,
	on_cost = function(self,event,room,player,data)
		return false
	end,
}

--[[
	英魂
	相关武将：标-孙坚、势-孙策
	描述：准备阶段开始时，若你已受伤，你可以选择一项：1.令一名其他角色摸X张牌，然后该角色弃置一张牌；2.令一名其他角色摸一张牌，然后该角色弃置X张牌。（X为你已损失的体力值） 
	引用：
	状态：
]]

LuaYinghun = sgs.CreatePhaseChangeSkill{
	name = "LuaYinghun",
	can_preshow = false,
	can_trigger = function(self,event,room,target,data)
		if not target or target:isDead() or not target:hasSkill(self:objectName()) then return false end
		if target:getPhase() == sgs.Player_Start and target:isWounded() then
			return self:objectName()
		end
	end,
	on_cost = function(self,event,room,player,data)
		local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yinghun-invoke", true, true)
		if to then
			local d = sgs.QVariant()
			d:setValue(to)
			player:setTag("yinghun_target",d)
			return true
		end
	end,
	on_phasechange = function(self,sunjian)
		local room = sunjian:getRoom()
		local to = sunjian:getTag("yinghun_target"):toPlayer()
		if to then
			local x = sunjian:getLostHp()

			if x == 1 then
				room:broadcastSkillInvoke(self:objectName(), 1, sunjian)

				to:drawCards(1)
				room:askForDiscard(to, self:objectName(), 1, 1, false, true)
			else
				to:setFlags("YinghunTarget")
				local choice = room:askForChoice(sunjian, self:objectName(), "d1tx+dxt1")
				to:setFlags("-YinghunTarget")
				if choice == "d1tx" then
					room:broadcastSkillInvoke(self:objectName(), 2, sunjian)

					to:drawCards(1)
					room:askForDiscard(to, self:objectName(), x, x, false, true)
				else
					room:broadcastSkillInvoke(self:objectName(), 1, sunjian)

					to:drawCards(x)
					room:askForDiscard(to, self:objectName(), 1, 1, false, true)
				end
			end
		end
		return false
	end,
}

--[[
	鹰扬
	相关武将：势-孙策
	描述：每当你拼点的牌亮出后，你可以令此牌的点数于此次拼点中+3或-3。 
	引用：
	状态：
]]
--[[
	英姿
	相关武将：标-周瑜、势-孙策
	描述：摸牌阶段，你可以额外摸一张牌。 
	引用：
	状态：
]]

LuaYingzi = sgs.CreateDrawCardsSkill{
	name = "LuaYingzi",
	frequency = sgs.Skill_Frequent,
	can_preshow = true,

	on_cost = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
	end,
	draw_num_func = function(self,player,n)
		return n + 1
	end,
}

--[[
	勇决
	相关武将：势-糜夫人
	描述：每当与你势力相同的一名角色使用的【杀】因结算完毕而置入弃牌堆时，若此【杀】为该角色于出牌阶段内使用的首张牌，其可以将此牌移动的目标区域改为其手牌。 
	引用：
	状态：
]]

--[[
	勇略
	相关武将：身份-韩浩&史焕
	描述：每当你攻击范围内的一名角色的判定阶段开始时，你可以弃置其判定区的一张牌：若如此做，视为对该角色使用一张【杀】（无距离限制）：若此【杀】未造成伤害，此【杀】结算后你摸一张牌。
	引用：
	状态：2.0
]]

LuaYonglve = sgs.CreateTriggerSkill{
	name = "LuaYonglve",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.PreDamageDone, sgs.CardFinished},
	
	on_record = function(self, event, room, player, data)
		if event == sgs.PreDamageDone then
			local damage = data:toDamage()
			if damage.card and damage.card:getSkillName() == self:objectName() then
				damage.card:setFlags(self:objectName().."_damage")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == self:objectName() and not use.card:hasFlag(self:objectName().."_damage") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if use.card:hasFlag(self:objectName().."|"..p:objectName()) then
						p:drawCards(1, self:objectName())
					end
				end
			end
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Judge then
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, hanshi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:objectName() ~= hanshi:objectName() and hanshi:inMyAttackRange(player) and not player:getJudgingArea():isEmpty() then
					table.insert(trigger_list_skill, self:objectName())
					table.insert(trigger_list_who, hanshi:objectName())
				end
			end
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data, hanshi)
		local to_data = sgs.QVariant()
		to_data:setValue(player)
		if hanshi:askForSkillInvoke(self:objectName(), to_data) then
			room:broadcastSkillInvoke(self:objectName(), hanshi)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data, hanshi)
		local id = room:askForCardChosen(hanshi, player, "j", self:objectName(), false, sgs.Card_MethodDiscard)
		room:throwCard(id, nil, hanshi)
		if hanshi:isAlive() and player:isAlive() and hanshi:canSlash(player, false) then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName(self:objectName())
			slash:setFlags(self:objectName().."|"..hanshi:objectName())
			room:useCard(sgs.CardUseStruct(slash, hanshi, player))
		end
		return false 
	end,
}

--[[
	诱敌
	相关武将：身份-朱桓
	描述：结束阶段开始时，你可以令一名其他角色弃置你一张牌：若此牌不为【杀】，你获得其一张牌。
	引用：
	状态：2.0
	相关翻译 {
		["LuaYoudi-invoke"] = "你可以发动“诱敌”<br/>操作提示：选择一名其他角色→确定"
	}
]]

LuaYoudi = sgs.CreateTriggerSkill{
	name = "LuaYoudi",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.EventPhaseStart,

	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish and not player:isNude()) then return "" end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), self:objectName().."-invoke", true, true)
		if target then
			local target_data = sgs.QVariant()
			target_data:setValue(target)
			player:setTag(self:objectName(), target_data)
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local target = player:getTag(self:objectName()):toPlayer()
		if target and target:isAlive() and target:canDiscard(player, "he") then
			local id = room:askForCardChosen(target, player, "he", self:objectName(), false, sgs.Card_MethodDiscard)
			room:throwCard(id, player, target, self:objectName())
			if not sgs.Sanguosha:getCard(id):isKindOf("Slash") and not target:isNude() and player:isAlive() then
				local id2 = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodNone)
				room:obtainCard(player, id2, false)
			end
		end
		return false 
	end,
}
