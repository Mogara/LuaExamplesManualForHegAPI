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
--[[
	离间
	相关武将：标-貂蝉
	描述：出牌阶段限一次，你可以弃置一张牌并选择两名其他男性角色，令其中一名男性角色视为对另一名男性角色使用一张【决斗】。     
	引用：
	状态：
]]
--[[
	礼让
	相关武将：标-孔融
	描述：每当你的一张被弃置的牌置入弃牌堆后，你可以将之交给一名其他角色。  
	引用：
	状态：
]]
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
		local index = listIndexOf(use.to, target)
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
        liuli_card:setShowSkill(self:objectName())
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
--[[
	乱武
	相关武将：标-贾诩
	描述：限定技，出牌阶段，你可以选择所有其他角色，这些角色各需对距离最小的另一名角色使用一张【杀】，否则失去1点体力。    
	引用：
	状态：
]]
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
