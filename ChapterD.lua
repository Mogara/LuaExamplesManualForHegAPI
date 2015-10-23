--[[
	国战技能速查手册（D区）
	技能索引：
	缔盟、定品、短兵、断肠、断粮、断绁、度势
]]--

--[[
	缔盟
	相关武将：标-鲁肃
	描述：出牌阶段限一次，你可以选择两名其他角色并弃置X张牌（X为这两名角色手牌数的差），令这两名角色交换手牌。 
	引用：
	状态：
]]

local json = require ("json")
LuaDimengCard = sgs.CreateSkillCard{
	name = "LuaDimengCard",
	filter = function(self,targets,to_select,Self)
		if to_select:objectName() == Self:objectName() then return false end
		if #targets == 0 then return true end
		if #targets  == 1 then
			return math.abs(to_select:getHandcardNum() - targets[1]:getHandcardNum()) == self:subcardsLength()
		end
		return false
	end,
	feasible =  function(self,targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local a = targets[1]
		local b = targets[2]
		a:setFlags("DimengTarget")
		b:setFlags("DimengTarget")
		local n1 = a:getHandcardNum()
		local n2 = b:getHandcardNum()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() ~= a:objectName() and p:objectName() ~= b:objectName() then
				room:doNotify(p, sgs.CommandType.S_COMMAND_EXCHANGE_KNOWN_CARDS, json.encode({a:objectName(), b:objectName()}))
			end
		end
		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(a:handCards(), b, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), b:objectName(), "LuaDimeng", ""))
		local move2 = sgs.CardsMoveStruct(b:handCards(), a, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), a:objectName(), "LuaDimeng", ""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
		room:moveCardsAtomic(exchangeMove, false)
		
		local log = sgs.LogMessage()
        log.type = "#Dimeng"
		log.from = a
		log.to:append(b)
		log.arg = n1
		log.arg2 = n2
		room:sendLog(log)
		room:getThread():delay()		
		a:setFlags("-DimengTarget")
		b:setFlags("-DimengTarget")
	end,
}

LuaDimeng = sgs.CreateViewAsSkill{
	name = "LuaDimeng",
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isJilei(to_select)
	end ,
	view_as = function(self, cards)
		local card = LuaDimengCard:clone()
        card:setShowSkill(self:objectName())
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaDimengCard")
	end
}

--[[
	定品
	相关武将：身份-陈群
	描述：出牌阶段，你可以弃置一张与你本回合已使用或弃置的牌类别均不同的手牌，然后令一名已受伤的角色进行判定：若结果为黑色，该角色摸X张牌，且你本阶段不能对该角色发动“定品”；红色，你将武将牌翻面。（X为该角色已损失的体力值）。 
	引用：
	状态：2.0
]]

LuaDingpinCard = sgs.CreateSkillCard{
	name = "LuaDingpinCard",
	skill_name = "LuaDingpin",
	target_fixed = false,
	will_throw = true,
	handling_method = sgs.Card_MethodNone,

	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:isWounded() and not to_select:hasFlag(self:getSkillName().."black")
	end,
	
	feasible = function(self, targets, player)
		return #targets == 1
	end,

	on_use = function(self, room, source, targets)
		local target = targets[1]
		local Judge = sgs.JudgeStruct()
		Judge.pattern = ".|black"
		Judge.play_animation = false
		Judge.reason = self:getSkillName()
		Judge.who = target
		room:judge(Judge)
		if Judge:isGood() then
			room:setPlayerFlag(target, self:getSkillName().."black")
			room:drawCards(target, target:getLostHp(), self:getSkillName())
		else
			source:turnOver()
		end
	end,
}

LuaDingpinVS = sgs.CreateViewAsSkill{   
	name = "LuaDingpin",
	
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() or sgs.Self:isJilei(to_select) then return false end
		local patterns, pattern = sgs.Self:property(self:objectName().."_pattern"):toString():split("+"), ""
		for _, pat in ipairs(patterns) do
			if to_select:getTypeId() == tonumber(pat) then return false end
		end
		return #selected == 0
	end, 

	view_as = function(self, originalCards) 
		if #originalCards == 1 then
			local skillcard = LuaDingpinCard:clone()
			skillcard:addSubcard(originalCards[1])
			skillcard:setSkillName(self:objectName())
			skillcard:setShowSkill(self:objectName())
			return skillcard
		end
	end, 

	enabled_at_play = function(self, player)
		return true
	end,
}

LuaDingpin = sgs.CreateTriggerSkill{
	name = "LuaDingpin",
	events = {sgs.EventPhaseChanging, sgs.PreCardUsed, sgs.CardResponded, sgs.BeforeCardsMove},
	view_as_skill = LuaDingpinVS,
	
	on_record = function(self, event, room, player, data)
		if not (player and player:isAlive()) then return end
		if event == sgs.PreCardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			elseif event == sgs.CardResponded then
				local response = data:toCardResponse()
				card = response.m_isUse and response.m_card
			end
			if card and card:getHandlingMethod() == sgs.Card_MethodUse and card:getTypeId() ~= sgs.Card_TypeSkill then
				local patterns = player:property(self:objectName().."_pattern"):toString():split("+")
				table.insert(patterns, tostring(card:getTypeId()))
				table.toSet(patterns)
				room:setPlayerProperty(player, self:objectName().."_pattern", sgs.QVariant(table.concat(patterns, "+")))
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if not move.from or move.from:objectName() ~= player:objectName() then return end
			if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				local patterns = player:property(self:objectName().."_pattern"):toString():split("+")
				for _, id in sgs.qlist(move.card_ids) do
					table.insert(patterns, tostring(sgs.Sanguosha:getCard(id):getTypeId()))
				end
				table.toSet(patterns)
				room:setPlayerProperty(player, self:objectName().."_pattern", sgs.QVariant(table.concat(patterns, "+")))
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_RoundStart then
				room:setPlayerProperty(player, self:objectName().."_pattern", sgs.QVariant())
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasFlag(self:objectName().."black") then room:setPlayerFlag(p, "-"..self:getSkillName().."black") end
				end
			end
		end
	end,

	can_trigger = function(self, event, room, player, data)
		return false
	end
}

--[[
	短兵
	相关武将：标-丁奉
	描述：你使用【杀】能额外选择一名距离为1的角色为目标。 
	引用：
	状态：耦合进源码，LUA无法实现
]]

--[[
	断肠
	相关武将：标-蔡文姬
	描述：锁定技，当你死亡时，你令杀死你的角色失去你选择的其一张武将牌的技能。 
	引用：
	状态：
]]

LuaDuanchang = sgs.CreateTriggerSkill{
	name = "LuaDuanchang",
	events = {sgs.Death},
	frequency = sgs.Skill_Compulsory,
	can_preshow = false,

	
	can_trigger = function(self,event,room,player,data)
		if not player or not player:hasSkill(self:objectName()) then return false end
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() and death.damage and death.damage.from then
			if not (death.damage.from:getGeneral():objectName():match("sujiang") and death.damage.from:getGeneral2():objectName():match("sujiang")) then
				return self:objectName() .. "->" .. death.damage.from:objectName()
			end
		end
	end,

	on_cost = function(self,event,room,target,data,player)
		room:broadcastSkillInvoke(self:objectName(), player)
		return true
	end,

	on_effect = function(self,event,room,target,data,player)
		room:notifySkillInvoked(player, self:objectName())
		local choice = "head_general"
		local d = sgs.QVariant()
		d:setValue(target)
		if player:getAI() then
			local choices = {}
			if not target:getGeneral():objectName():match("sujiang") then
				table.insert(choices, "head_general")
			end
            if not target:getGeneral2():objectName():match("sujiang") then
				table.insert(choices, "deputy_general")
			end

			choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"), d)
		else
			local generals = {}
			if not target:getGeneral():objectName():match("sujiang") then
				local g = target:getGeneral():objectName()
				if g:match("anjiang") then
                    g = g .. "_head"
				end
				table.insert(generals, g)
			end
            if not target:getGeneral2():objectName():match("sujiang") then
                local g = target:getGeneral2():objectName()
                if g:match("anjiang") then
					g = g .. "_deputy"
				end
                table.insert(generals, g)
			end

			local general = generals[1]
			if #generals == 2 then
				general = room:askForGeneral(player, table.concat(generals, "+"), generals[1], true, self:objectName(), d)
			end
			if general == target:getGeneral():objectName() or general == "anjiang_head" then
				choice = "head_general"
            else
				choice = "deputy_general"
			end
		end

		local log = sgs.LogMessage()
		if choice == "head_general" then
			log.type = "#DuanchangLoseHeadSkills"
		else
			log.type = "#DuanchangLoseDeputySkills"
		end
		log.from = player
		log.to:append(target)
		log.arg = self:objectName()
		room:sendLog(log)

		local duanchangList = target:property("Duanchang"):toString():split(",")

		if choice == "head_general" and not table.contains(duanchangList, "head") then
			table.insert(duanchangList, "head")
		elseif choice == "deputy_general" and not table.contains(duanchangList, "deputy") then
			table.insert(duanchangList, "deputy")
		end
		room:setPlayerProperty(target, "Duanchang", sgs.QVariant(table.concat(duanchangList, ",")))
		
		local skills = choice == "head_general" and target:getActualGeneral1():getVisibleSkillList() or target:getActualGeneral2():getVisibleSkillList()
		for _, sk in sgs.qlist(skills) do
			if not sk:isAttachedLordSkill() then
				room:detachSkillFromPlayer(target, sk:objectName(), not target:hasShownSkill(sk))
			end
		end
		if target:isAlive() then
            target:gainMark("@duanchang")
		end
	end,
}

--[[
	断粮
	相关武将：标-徐晃
	描述：你可以将一张黑色基本牌或黑色装备牌当【兵粮寸断】使用；你能对距离为2的角色使用【兵粮寸断】。 
	引用：
	状态：
]]

luaDuanliang = sgs.CreateViewAsSkill{
	name = "luaDuanliang",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and (to_select:isKindOf("BasicCard") or to_select:isKindOf("EquipCard"))
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage",cards[1]:getSuit(),cards[1]:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:setShowSkill(self:objectName())
		shortage:addSubcard(cards[1])
		return shortage
	end
}

luaDuanliangTargetMod = sgs.CreateTargetModSkill{
	name = "#luaDuanliang-target",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		else
			return 0
		end
	end,
}

--[[
	断绁
	相关武将：势-陈武&董袭
	描述：出牌阶段限一次，你可以令一名其他角色横置副将的武将牌，若如此做，你横置副将的武将牌。 
	引用：
	状态：
]]

--[[
	度势
	相关武将：标-陆逊
	描述：你可以将一张红色手牌当【以逸待劳】使用。每阶段限四次。 
	引用：
	状态：
]]

LuaDuoshi = sgs.CreateOneCardViewAsSkill{
	name = "LuaDuoshi",
	filter_pattern = ".|red|.|hand",
	response_or_use = true,

	enabled_at_play = function(self,player)
		return player:usedTimes("ViewAsSkill_LuaDuoshiCard") < 4
	end,
	view_as = function(self,card)
		local await = sgs.Sanguosha:cloneCard("await_exhausted", card:getSuit(), card:getNumber())
		await:addSubcard(card:getId())
		await:setSkillName(self:objectName())
		await:setShowSkill(self:objectName())
        return await
	end,
}
