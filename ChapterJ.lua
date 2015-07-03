--[[
	国战技能速查手册（J区）
	技能索引：
	激昂、急救、急袭、激诏、集智、奸雄、奸雄·界限、节命、结姻、精策、酒诗、据守、巨象  
]]--
--[[
	激昂
	相关武将：势-孙策
	描述：每当你使用一张【决斗】或红色【杀】指定目标后，或成为一张【决斗】或红色【杀】的目标后，你可以摸一张牌。   
	引用：
	状态：
]]
--[[
	急救
	相关武将：标-华佗
	描述：你于回合外可以将一张红色牌当【桃】使用。   
	引用：
	状态：
]]

LuaJijiu = sgs.CreateOneCardViewAsSkill{
	name = "LuaJijiu",
	filter_pattern = ".|red",
	response_or_use = true,
	enabled_at_play = function(self)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:match("peach") and not player:hasFlag("Global_PreventPeach") and player:getPhase() == sgs.Player_NotActive
	end,
	view_as = function(self,ocard)
		local peach = sgs.Sanguosha:cloneCard("peach",ocard:getSuit(), ocard:getNumber())
		peach:addSubcard(ocard:getId())
		peach:setSkillName(self:objectName())
		peach:setShowSkill(self:objectName())
        return peach
	end
}

--[[
	急袭
	相关武将：阵-邓艾
	描述：主将技，此武将牌上单独的阴阳鱼个数-1；主将技，你可以将一张“田”当【顺手牵羊】使用。 
	引用：
	状态：
]]

LuaJixi = sgs.CreateOneCardViewAsSkill{
	name = "LuaJixi",
	relate_to_place = "head",
	filter_pattern = ".|.|.|LuaField",
	expand_pile = "LuaField",

	enabled_at_play = function(self, player)
		return not player:getPile("LuaField"):isEmpty()
	end,
	view_as = function(self, ocard)
		local shun = sgs.Sanguosha:cloneCard("Snatch", ocard:getSuit(), ocard:getNumber())
		shun:addSubcard(ocard)
		shun:setSkillName(self:objectName())
        shun:setShowSkill(self:objectName())
		return shun
	end,
}

--[[
	激诏
	相关武将：阵-君刘备
	描述：限定技，当你处于濒死状态时，你可以将手牌补至X张（X为你的体力上限），然后将体力值回复至2点，最后失去“授钺”并获得“仁德”。 
	引用：
	状态：
]]
--[[
	集智
	相关武将：标-黄月英
	描述：每当你使用非转化的非延时类锦囊牌时，你可以摸一张牌。  
	引用：
	状态：
]]

LuaJizhi = sgs.CreateTriggerSkill{
	name = "LuaJizhi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardUsed},

    can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local use = data:toCardUse()
        if use.card and use.card:isNDTrick() then
            if not use.card:isVirtualCard() or use.card:getSubcards():isEmpty() then
				return self:objectName()
            elseif use.card:getSubcards():length() == 1 then
                if sgs.Sanguosha:getCard(use.card:getEffectiveId()):objectName() == use.card:objectName() then
					return self:objectName()
				end
			end
		end
	end,

	on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
	end,

	on_effect = function(self, event, room, player, data)
        player:drawCards(1)
	end,
}

--[[
	奸雄
	相关武将：标-曹操
	描述：每当你受到伤害后，你可以获得造成此伤害的牌。   
	引用：
	状态：
]]

Luajianxiong = sgs.CreateTriggerSkill{
	name = "Luajianxiong",
	events = {sgs.Damaged},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isAlive() or player:hasSkill(self:objectName()) then return false end
		if card and room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceTable then
			return self:objectName()
		end
	end,
	on_cost = function(self,event,room,player,data)
		return player:askForSkillInvoke(self:objectName(), data)
	end,
	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
		local card = damage.card
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		player:obtainCard(card)
	end,
}

--[[
	奸雄
	相关武将：身份-曹操·界限突破
	描述：每当你受到伤害后，你可以选择一项：获得对你造成伤害的牌，或摸一张牌。   
	引用：
	状态：1.2.0 验证通过
]]

LuaJianxiongJx = sgs.CreateTriggerSkill{
	name = "LuaJianxiongJx",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.Damaged,
	
	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName())) then return "" end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local choices = {"draw"}

		local card = damage.card
		if card then
			local ids = sgs.IntList()
			if card:isVirtualCard() then
				ids = card:getSubcards()
			else
				ids:append(card:getEffectiveId())
			end
			if ids:length() > 0 then
				local all_place_table = true
				for _,id in sgs.qlist(ids) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
						break
					end
				end
				if all_place_table then table.insert(choices, "obtain") end
			end
		end

		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), data)
		if choice == "obtain" then
			player:obtainCard(card)
		else
			player:drawCards(1, self:objectName())
		end
		return false 
	end,
}

--[[
	节命
	相关武将：标-荀彧
	描述：每当你受到1点伤害后，你可以令一名角色将手牌补至X张（X为该角色的体力上限且至多为5）。   
	引用：
	状态：
]]

luaJieming = sgs.CreateTriggerSkill{
	name = "luaJieming" ,
	events = {sgs.Damaged} ,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local damage = data:toDamage()
		local trigger_list = {}
		for i = 1, damage.damage, 1 do
			table.insert(trigger_list, self:objectName())
		end
		return table.concat(trigger_list,",")
	end,
	on_cost = function(self, event, room, player, data)
		if player:isDead() then return false end
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "jieming-invoke", true, true)
		if  target then
			room:notifySkillInvoked(player, self:objectName())
			if target:objectName() == player:objectName() then
				room:broadcastSkillInvoke(self:objectName(), 2, player)
			else
				room:broadcastSkillInvoke(self:objectName(), 1, player)
			end
			local target_list = player:getTag("jieming_target"):toList()
			local d = sgs.QVariant()
			d:setValue(target)
			target_list:append(d)
			player:setTag("jieming_target", sgs.QVariant(target_list))
			return true
		end
	end,
		
	on_effect = function(self, event, room, player, data)
		local target_list = player:getTag("jieming_target"):toList()
		target = target_list:last():toPlayer()
		local d = sgs.QVariant()
		d:setValue(target)
		target_list:removeOne(d)
		player:setTag("jieming_target", sgs.QVariant(target_list))
		local to
		for _, p in sgs.qlist(room:getPlayers()) do
			if p:objectName() == target:objectName() then to = p break end
		end
		if to then
			local upper = math.min(5, to:getMaxHp())
			local x = upper - to:getHandcardNum()
			if x <= 0 then
			else
				to:drawCards(x)
			end
		end
	end,
}

--[[
	结姻
	相关武将：标-孙尚香
	描述：出牌阶段限一次，你可以弃置两张手牌并选择一名已受伤的其他男性角色，令你与其各回复1点体力。   
	引用：
	状态：
]]

--结姻

LuaJieyinCard = sgs.CreateSkillCard{
	name = "LuaJieyinCard",
	filter = function(self,targets,to_select,player)
		return #targets == 0 and to_select:isMale() and to_select:isWounded() and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self,effect)
		local room = effect.from:getRoom()
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		local targets = sgs.SPlayerList()
		targets:append(effect.from)
		targets:append(effect.to)
		room:sortByActionOrder(targets)
		for _, target in sgs.qlist(targets) do
			room:recover(target, recover, true)
		end
	end,
}

LuaJieyin = sgs.CreateViewAsSkill{
	name = "LuaJieyin",
	enabled_at_play = function(self,player)
		return player:getHandcardNum() >= 2 and not player:hasUsed("#LuaJieyinCard")
	end,
	view_filter = function(self,selected,to_select)
		if #selected > 1 or sgs.Self:isJilei(to_select) then
			return false
		end
        return not to_select:isEquipped()
	end,
	view_as = function(self,cards)
        if #cards ~= 2 then return nil end
		local jieyin_card = LuaJieyinCard:clone()
		jieyin_card:addSubcard(cards[1])
		jieyin_card:addSubcard(cards[2])
		jieyin_card:setSkillName(self:objectName())
        jieyin_card:setShowSkill(self:objectName())
        return jieyin_card
	end,
}

--[[
	精策
	相关武将：身份-郭淮
	描述：出牌阶段结束时，若你于此回合内使用过的牌数不小于你的体力值，你可摸两张牌。  
	引用：
	状态：
]]

luajingce = sgs.CreateTriggerSkill{
	name = "luajingce",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd, sgs.PreCardUsed},

	on_record = function(self, event, room, player, data)
		if not (player and player:isAlive()) then return end
		if event == sgs.PreCardUsed then
			local card
			if event == sgs.PreCardUsed or event == sgs.CardUsed then
				card = data:toCardUse().card
			elseif event == sgs.CardResponded then
				local response = data:toCardResponse()
				card = response.m_isUse and response.m_card
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and card:getTypeId() ~= sgs.Card_TypeSkill then
				if player:getPhase() <= sgs.Player_Play then player:addMark(self:objectName()) end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			player:setMark(self:objectName(), 0)
		end
	end,
	
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			if player:getMark(self:objectName()) >= player:getHp() then
				return self:objectName()
			end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		player:drawCards(2, self:objectName())
		return false 
	end,
}

--[[
	酒诗
	相关武将：身份-曹植
	描述：每当你需要使用【酒】时，若你处于平置状态，你可以叠置，视为使用一张【酒】；若你因受到伤害而扣减体力前你处于叠置状态，此伤害结算结束后你可以叠置。  
	引用：
	状态：
]]

luajiushiVS = sgs.CreateZeroCardViewAsSkill{   
	name = "luajiushi",
	
	view_as = function(self)
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		analeptic:setSkillName(self:objectName())
		analeptic:setShowSkill(self:objectName())
		return analeptic
	end,

	enabled_at_play = function(self, player)
		return sgs.Analeptic_IsAvailable(player) and player:faceUp()
	end,

	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic") and player:faceUp()
	end
}

luajiushi = sgs.CreateTriggerSkill{
	name = "luajiushi",
	can_preshow = false,
	events = {sgs.PreCardUsed, sgs.PreDamageDone, sgs.DamageComplete},
	view_as_skill = luajiushiVS,
	
	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive()) then return "" end
		if event == sgs.PreDamageDone then
			player:setTag("PredamagedFace", sgs.QVariant(not player:faceUp()))
		elseif event == sgs.PreCardUsed and player:hasSkill(self:objectName()) then
			if data:toCardUse().card:getSkillName() == self:objectName() then return self:objectName() end
		elseif event == sgs.DamageComplete and player:hasSkill(self:objectName()) then
			local facedown = player:getTag("PredamagedFace"):toBool()
			player:removeTag("PredamagedFace")
			if facedown and not player:faceUp() then return self:objectName() end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if event == sgs.PreCardUsed or player:askForSkillInvoke(self:objectName(), data) then
			if event == sgs.DamageComplete then room:broadcastSkillInvoke(self:objectName(), player) end
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		player:turnOver()
		return false 
	end,
}

--[[
	据守
	相关武将：标-曹仁
	描述：结束阶段开始时，你可以摸三张牌，然后你叠置。   
	引用：
	状态：
]]

luaJushou = sgs.CreatePhaseChangeSkill{
	name = "luaJushou",  
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if player:getPhase() == sgs.Player_Finish then return self:objectName() end
	end,
	on_cost = function(self, event, room, player, data)
		return player:askForSkillInvoke(self:objectName(), data)
	end,
	
	on_phasechange = function(self, player)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		player:drawCards(3, self:objectName())
		player:turnOver()
		return false
	end,
}

--[[
	巨象
	相关武将：标-祝融
	描述：锁定技，【南蛮入侵】对你无效；锁定技，每当其他角色使用的【南蛮入侵】因结算完毕而置入弃牌堆后，你获得之。 
	引用：
	状态：
]]

LuaSavageAssaultAvoid2 = sgs.CreateTriggerSkill{
	name = "#LuaSavageAssaultAvoid-for-zhurong",
    events = {sgs.CardEffected},
    frequency = sgs.Skill_Compulsory,

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill("LuaJuxiang") then return false end
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("LuaJuxiang") or player:askForSkillInvoke("LuaJuxiang") then
			player:showGeneral(player:inHeadSkills("LuaJuxiang"))
			room:broadcastSkillInvoke("LuaJuxiang", 1, player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
		room:notifySkillInvoked(player, "LuaJuxiang")
		local log = sgs.LogMessage()
		log.type = "#SkillNullify"
		log.from = player
		log.arg = "LuaJuxiang"
		log.arg2 = "savage_assault"
		room:sendLog(log)
		return true
	end,
}

LuaJuxiang = sgs.CreateTriggerSkill{
	name = "LuaJuxiang",
	events = {sgs.CardUsed,sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	
	can_trigger = function(self, event, room, player, data)
		if not player then return false end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				if use.card:isVirtualCard() and use.card:subcardsLength() ~= 1 then return false end
				if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId())
					and sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):isKindOf("SavageAssault") then
                    room:setCardFlag(use.card:getEffectiveId(), "real_SA")
				end
			end
		else
			if player:isDead() or not player:hasSkill(self:objectName()) then return false end
			local move = data:toMoveOneTime()
			if move.card_ids:length() == 1 and move.from_places:contains(sgs.Player_PlaceTable) and move.to_place == sgs.Player_DiscardPile
				and move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE and room:getCardPlace(move.card_ids:at(0)) == sgs.Player_DiscardPile then
				local card = sgs.Sanguosha:getCard(move.card_ids:first())
				if card:hasFlag("real_SA") and player:objectName() ~= move.from:objectName() then
					return self:objectName()
				end
			end
		end
	end,

	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or player:askForSkillInvoke(self) then
			room:broadcastSkillInvoke(self:objectName(), 2, player)
			return true
		end
	end,

	on_effect = function(self, event, room, player, data)
        local move = data:toMoveOneTime()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        local sa = sgs.DummyCard(move.card_ids)
        player:obtainCard(sa)
	end,
}
