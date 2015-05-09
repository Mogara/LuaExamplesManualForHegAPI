--[[
	国战技能速查手册（G区）
	技能索引：
	刚烈、固政、观星、闺秀、鬼才、鬼道、国色   
]]--
--[[
	刚烈
	相关武将：标-夏侯惇
	描述：每当你受到伤害后，你可以进行判定，若结果不为♥，来源选择一项：1.弃置两张手牌；2.受到你造成的1点伤害。 
	引用：
	状态：
]]

Luaganglie = sgs.CreateTriggerSkill{
	name = "Luaganglie",
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then	return false end
		local damage = data:toDamage()
		local source = damage.from
		if source and source:isAlive() then
			return self:objectName() .. "->" .. damage.from:objectName()
		end
	end,
	
	on_cost = function(self, event, room, from, data, player)
		d = sgs.QVariant()
		d:setValue(from)
		return room:askForSkillInvoke(player, self:objectName(), d)
	end,
	
	on_effect = function(self, event, room, from, data, player)
		room:notifySkillInvoked(player,self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|heart"
		judge.who = player
		judge.reason = self:objectName()
		judge.good = false
		room:judge(judge)				

		if judge.card:isGood() then
            if from:getHandcardNum() < 2 or not room:askForDiscard(from, self:objectName(), 2, 2, true) then
                room:damage(sgs.DamageStruct(self:objectName(), player, from))
			end
		end
	end,
}


--[[
	固政
	相关武将：标-张昭&张纮
	描述：将弃牌堆里的该角色于此阶段内弃置的一张手牌交给该角色，若如此做，你可以获得弃牌堆里的其余于此阶段内弃置的牌。 
	引用：
	状态：
]]

LuaGuzhengRecord = sgs.CreateTriggerSkill{
	name = "#Luaguzheng-record",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,event,room,erzhang,data)
		if not erzhang or not erzhang:isAlive() or not erzhang:hasSkill("LuaGuzheng") then return false end
		local current = room:getCurrent()
		local move = data:toMoveOneTime()
		if erzhang:objectName() == current:objectName() then return false end

		if current:getPhase() == sgs.Player_Discard then
			local QguzhengToGet = erzhang:getTag("LuaGuzhengToGet"):toList()
			local guzhengToGet = sgs.IntList()
			for _, id in sgs.qlist(QguzhengToGet) do
				guzhengToGet:append(id:toInt())
			end
			local QguzhengOther = erzhang:getTag("LuaGuzhengOther"):toList()
			local guzhengOther = sgs.IntList()
			for _, id in sgs.qlist(QguzhengOther) do
				guzhengOther:append(id:toInt())
			end

			if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				for _, card_id in sgs.qlist(move.card_ids) do
					if move.from:objectName() == current:objectName() then
						if not guzhengToGet:contains(card_id) then
							QguzhengToGet:append(sgs.QVariant(card_id))
						end
					else
						if not guzhengOther:contains(card_id) then
							QguzhengOther:append(sgs.QVariant(card_id))
						end
					end
				end
			end
            erzhang:setTag("LuaGuzhengToGet",sgs.QVariant(QguzhengToGet))
            erzhang:setTag("LuaGuzhengOther",sgs.QVariant(QguzhengOther))
		end
	end,
}

LuaGuzhengCard = sgs.CreateSkillCard{
	name = "LuaGuzhengCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_use = function(self,room,source)
		source:setTag("guzheng_card", sgs.QVariant(self:getSubcards():first()))
		source:setFlags("guzheng_invoke")
	end,
}

LuaGuzhengVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaGuzheng",
	response_pattern = "@@LuaGuzheng",
	view_filter = function(self,to_select)
		local l = sgs.Self:property("guzheng_toget"):toString():split("+")
        return table.contains(l, tostring(to_select:getId()))
	end,
	view_as = function(self,originalCard)
		local gz = LuaGuzhengCard:clone()
		gz:addSubcard(originalCard)
		return gz
	end,
}

LuaGuzheng = sgs.CreateTriggerSkill{
	name = "LuaGuzheng",
	events = {sgs.EventPhaseEnd},
	view_as_skill = LuaGuzhengVS,
	can_trigger = function(self,event,room,player)
		local skill_list = {}
		local name_list = {}
		if not player or player:getPhase() ~= sgs.Player_Discard then return false end
		local erzhangs = room:findPlayersBySkillName(self:objectName())

		for _, erzhang in sgs.qlist(erzhangs) do
			local QguzhengToGet = erzhang:getTag("LuaGuzhengToGet"):toList()
			local guzheng_cardsToGet = sgs.IntList()
			for _, id in sgs.qlist(QguzhengToGet) do
				guzheng_cardsToGet:append(id:toInt())
			end
			local QguzhengOther = erzhang:getTag("LuaGuzhengOther"):toList()
			local guzheng_cardsOther = sgs.IntList()
			for _, id in sgs.qlist(QguzhengOther) do
				guzheng_cardsOther:append(id:toInt())
			end
			
			if player:isDead() then return false end

			local cardsToGet = sgs.IntList()
			for _, card_id in sgs.qlist(guzheng_cardsToGet) do
				if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
					cardsToGet:append(card_id)
				end
			end
			local cardsOther = sgs.IntList()
			for _, card_id in sgs.qlist(guzheng_cardsOther) do
				if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
					cardsOther:append(card_id)
				end
			end

			if cardsToGet:isEmpty() then
				erzhang:removeTag("LuaGuzhengToGet")
				erzhang:removeTag("LuaGuzhengOther")
				continue
			else
				table.insert(skill_list,self:objectName())
				table.insert(name_list,erzhang:objectName())
			end
		end
		return table.concat(skill_list,"|"),table.concat(name_list,"|")
	end,
	
	on_cost = function(self,event,room,player,data,erzhang)
		local QguzhengToGet = erzhang:getTag("LuaGuzhengToGet"):toList()
		local guzheng_cardsToGet = sgs.IntList()
		for _, id in sgs.qlist(QguzhengToGet) do
			guzheng_cardsToGet:append(id:toInt())
		end
		local QguzhengOther = erzhang:getTag("LuaGuzhengOther"):toList()
		local guzheng_cardsOther = sgs.IntList()
		for _, id in sgs.qlist(QguzhengOther) do
			guzheng_cardsOther:append(id:toInt())
		end
		local cards = sgs.IntList()
		local cardsToGet = {}
		for _, card_id in sgs.qlist(guzheng_cardsToGet) do
			if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
				table.insert(cardsToGet,card_id)
				cards:append(card_id)
			end
		end
		local cardsOther = {}
		for _, card_id in sgs.qlist(guzheng_cardsOther) do
			if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
				table.insert(cardsOther,card_id)
				cards:append(card_id)
			end
		end
		
		erzhang:removeTag("LuaGuzhengToGet")
		erzhang:removeTag("LuaGuzhengOther")
		
		if #cardsToGet == 0 then return false end
		
		local cardsList = table.concat(sgs.QList2Table(cards),"+")
		room:setPlayerProperty(erzhang, "guzheng_allCards", sgs.QVariant(cardsList))
		local toGetList = table.concat(cardsToGet,"+")
		room:setPlayerProperty(erzhang, "guzheng_toget", sgs.QVariant(toGetList))

		erzhang:removeTag("guzheng_card")
		room:setPlayerFlag(erzhang, "LuaGuzheng_InTempMoving")
		local r = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, erzhang:objectName())
		local fake_move = sgs.CardsMoveStruct(cards, nil, erzhang, sgs.Player_DiscardPile, sgs.Player_PlaceHand, r)
		local moves = sgs.CardsMoveList()
        moves:append(fake_move)
		local _erzhang = sgs.SPlayerList()
		_erzhang:append(erzhang)
		room:notifyMoveCards(true, moves, true, _erzhang)
        room:notifyMoveCards(false, moves, true, _erzhang)
		local invoke = room:askForUseCard(erzhang, "@@LuaGuzheng", "@guzheng:" .. player:objectName(), -1, sgs.Card_MethodNone)
		local fake_move2 = sgs.CardsMoveStruct(cards, erzhang, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile, r)
		local moves2 = sgs.CardsMoveList()
        moves2:append(fake_move2)
		room:notifyMoveCards(true, moves2, true, _erzhang)
        room:notifyMoveCards(false, moves2, true, _erzhang)
		room:setPlayerFlag(erzhang, "-LuaGuzheng_InTempMoving")

		if invoke and erzhang:hasFlag("guzheng_invoke") then
			erzhang:setFlags("-guzheng_invoke")
			local to_back = erzhang:getTag("guzheng_card"):toInt()
			player:obtainCard(sgs.Sanguosha:getCard(to_back))
			cards:removeOne(to_back)
			local ids = sgs.VariantList()
			for _, id in sgs.qlist(cards) do
				ids:append(sgs.QVariant(id))
			end
			erzhang:setTag("GuzhengCards",sgs.QVariant(ids))
			return true
		end
	end,
	
	on_effect = function(self,event,room,player,data,erzhang)
		local Qcards = erzhang:getTag("GuzhengCards"):toList()
		local cards = sgs.IntList()
		for _, q in sgs.qlist(Qcards) do
			cards:append(q:toInt())
		end
		erzhang:removeTag("GuzhengCards")
		if not cards:isEmpty() and room:askForSkillInvoke(erzhang, "_Guzheng", sgs.QVariant("GuzhengObtain")) then
			local dummy = sgs.DummyCard(cards)
			room:obtainCard(erzhang, dummy)
		end
	end,
}

--[[
	观星
	相关武将：标-诸葛亮
	描述：准备阶段开始时，你可以观看牌堆顶的X张牌（X为全场角色数且至多为5），然后将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。 
	引用：
	状态：
	备注：配合的“遗志”是"LuaYizhi"注意不要与原生的混淆了
]]
local json = require ("json")
luaGuanxing = sgs.CreatePhaseChangeSkill{
	name = "luaGuanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	can_preshow = false,
	can_trigger = function(self, event, room, player, data)
		if player and not player:isDead() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then
			return self:objectName()
		end
	end,
	
	on_cost = function(self, event, room, player, data)
        if not player:hasSkill(self:objectName()) then
            if player:askForSkillInvoke(self:objectName()) then
                local log = sgs.LogMessage()
                log.type = "#InvokeSkill";
                log.from = player
                log.arg = self:objectName()
                room:sendLog(log)
                room:broadcastSkillInvoke("LuaYizhi", player)
                player:showGeneral(false)
                return true
			else
                return false
			end
		end
        if not player:hasSkill("LuaYizhi") then
            if player:askForSkillInvoke(self:objectName()) then
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            else
                return false
            end
        end
														--运行到这说明两个技能都拥有
        if player:askForSkillInvoke(self:objectName()) then
            local show1 = player:hasShownSkill("luaGuanxing")
            local show2 = player:hasShownSkill("LuaYizhi")
			local choices = {}
            if not show1 then
                table.insert(choices,"show_head_general")
			end
            if not show2 then
                table.insert(choices,"show_deputy_general")
			end
            if #choices == 2 then
                table.insert(choices,"show_both_generals")
			end
            if #choices ~= 3 then
                table.insert(choices,"cancel")
			end
            local choice = room:askForChoice(player, "GuanxingShowGeneral", table.concat(choices,"+"))
            if choice == "cancel" then
                if show1 then
                    room:broadcastSkillInvoke(self:objectName(), player)
                    return true
				else
                    room:broadcastSkillInvoke("LuaYizhi", player)
					self:effect(sgs.EventPhaseStart, room, player, data)
					return false
                end
            end
            if choice ~= "show_head_general" then
                player:showGeneral(false)
			end
            if (choice == "show_deputy_general" and not show1) then
                room:broadcastSkillInvoke("LuaYizhi", player)
                player:showGeneral(false)
                --onPhaseChange(player)
				self:effect(sgs.EventPhaseStart, room, player, data)
				return false
            else
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
        end
        return false
    end,
	on_phasechange = function(self,player)
		local room = player:getRoom()		
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		
		local count = room:alivePlayerCount()
		if count > 5 or (player:hasShownSkill(self:objectName()) and player:hasShownSkill("LuaYizhi")) then
			count = 5
		end
		local cards = room:getNCards(count)		
		local jsonLog = {
			"$ViewDrawPile",
			player:objectName(),
			"",
			table.concat(sgs.QList2Table(cards),"+"),
			"",
			""
		}
        room:doNotify(player, sgs.CommandType.S_COMMAND_LOG_SKILL, json.encode(jsonLog))
		room:askForGuanxing(player, cards, sgs.Room_GuanxingBothSides)
	end,
}
--[[
	闺秀
	相关武将：势-糜夫人
	描述：每当你明置此武将牌时，你可以摸两张牌；当你移除此武将牌时，你可以回复1点体力。  
	引用：
	状态：
]]
--[[
	鬼才
	相关武将：标-司马懿
	描述：每当一名角色的判定牌生效前，你可以打出一张手牌代替之。 
	引用：
	状态：
]]

LuaGuicai = sgs.CreateTriggerSkill{
	name = "LuaGuicai" ,
	events = {sgs.AskForRetrial} ,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if player:isKongcheng() and player:getHandPile():isEmpty() then
			return "."
		else return self:objectName()
		end
	end,
		
	on_cost = function(self, event, room, player, data)
		local judge = data:toJudge()
		local room = player:getRoom()
		local prompt_list = {
			"@guicai-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
            }
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".", prompt,data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:broadcastSkillInvoke(self:objectName(), player);
			room:retrial(card, player, judge, self:objectName())
			return true
		else
			return false
		end
	end,
		
	on_effect = function(self, event, room, player, data)
		local judge = data:toJudge()
		judge:updateResult()
		return false
	end,
}

--[[
	鬼道
	相关武将：标-张角
	描述：每当一名角色的判定牌生效前，你可以打出一张黑色牌替换之。 
	引用：
	状态：
]]
--[[
	国色
	相关武将：标-大乔
	描述：你可以将一张♦牌当【乐不思蜀】使用。 
	引用：
	状态：
]]

LuaGuose = sgs.CreateOneCardViewAsSkill{
	name = "LuaGuose",
	filter_pattern = ".|diamond",
	response_or_use = true,
	view_as = function(self,card)
		local indulgence = sgs.Sanguosha:cloneCard("indulgence",card:getSuit(), card:getNumber())
		indulgence:addSubcard(card:getId())
		indulgence:setSkillName(self:objectName())
		indulgence:setShowSkill(self:objectName())
        return indulgence
	end,
}
