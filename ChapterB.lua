--[[
	国战技能速查手册（B区）
	技能索引：
	八阵、暴凌、悲歌、笔伐、闭月、秉一、不屈、补益
]]--
--[[
	八阵
	相关武将：标-卧龙诸葛亮
	描述：锁定技，若你的装备区里没有防具牌，你视为装备着【八卦阵】。 
	引用：
	状态：
]]

LuaBazhen = sgs.CreateTriggerSkill{
	name = "LuaBazhen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardAsked},

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return false end
		local qinggang = player:getTag("Qinggang"):toStringList()
		if #qinggang ~= 0 or player:getMark("Armor_Nullified") > 0 or player:getMark("Equips_Nullified_to_Yourself") > 0 then return false end
		--if player:hasArmorEffect("bazhen") then --这个东西在源代码里，无法100%还原
		if not player:getArmor() and not player:hasArmorEffect("bazhen") then
			return "EightDiagram"
		end
	end,
	
    on_cost = function(self, event, room, player, data)
		return false
	end,
}

--[[
	暴凌
	相关武将：势-董卓
	描述：主将技，锁定技，出牌阶段结束时，若此武将牌已明置且你有副将，你移除副将的武将牌，然后加3点体力上限，回复
		  3点体力，获得“崩坏”。 
	引用：
	状态：
]]

--[[
	悲歌
	相关武将：标-蔡文姬
	描述：每当一名角色受到【杀】造成的伤害后，你可以弃置一张牌并选择该角色，令其进行判定，若结果为：♥—该角色回复1点
	      体力；♦—该角色摸两张牌；♣—来源弃置两张牌；♠—来源叠置。 
	引用：
	状态：
]]

LuaBeige = sgs.CreateTriggerSkill{
	name = "LuaBeige",
	events = {sgs.Damaged, sgs.FinishJudge},

	can_trigger = function(self,event,room,player,data)
		local skill_list,player_list = {},{}
        if not player then return false end
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not damage.card or not damage.card:isKindOf("Slash") or damage.to:isDead() then return false end

			local caiwenjis = room:findPlayersBySkillName(self:objectName())
			for _, caiwenji in sgs.qlist(caiwenjis) do
				if caiwenji:canDiscard(caiwenji, "he") then
					table.insert(skill_list, self:objectName())
					table.insert(player_list, caiwenji:objectName())
				end
			end
            return table.concat(skill_list, "|"), table.concat(player_list, "|")
		else
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				judge.pattern = tostring(judge.card:getSuit())
			end
		end
	end,

	on_cost = function(self,event,room,player,data,ask_who)
		if player and player:isAlive() and ask_who:isAlive() and ask_who:canDiscard(ask_who, "he") then
            ask_who:setTag("beige_data", data)
			local invoke = room:askForDiscard(ask_who, self:objectName(), 1, 1, true, true, "@beige", true)
            ask_who:removeTag("beige_data")

			if invoke then
                room:doAnimate(1, ask_who:objectName(), data:toDamage().to:objectName())
				room:broadcastSkillInvoke(self:objectName(), ask_who)
                return true
			end
		end
	end,
	on_effect = function(self,event,room,player,data,ask_who)
		local damage = data:toDamage()

		local judge = sgs.JudgeStruct()
		judge.good = true
		judge.play_animation = false
		judge.who = player
		judge.reason = self:objectName()

		room:judge(judge)

		local suit = tonumber(judge.pattern)
		if suit == sgs.Card_Heart then
			local recover = sgs.RecoverStruct()
			recover.who = ask_who
			room:recover(player, recover)

		elseif suit == sgs.Card_Diamond then
			player:drawCards(2)

		elseif suit == sgs.Card_Club then
			if damage.from and damage.from:isAlive() then
				room:askForDiscard(damage.from, "beige_discard", 2, 2, false, true)
			end
		elseif suit == sgs.Card_Spade then
			if damage.from and damage.from:isAlive() then
				damage.from:turnOver()
			end
		end
	end,
}
--[[
	笔伐
	相关武将：身份-陈琳
	描述：结束阶段开始时，你可以将一张手牌背面朝上置于一名其他角色的武将牌旁，若如此做，该角色的回合开始时，其观看其武将牌旁的牌，然后选择一项：1.将一张与此牌类别相同的手牌交给你，获得此牌；2.将此牌置入弃牌堆，失去1点体力
	引用：
	状态：1.2.1验证通过
]]

LuaBifaCard = sgs.CreateSkillCard{
	name = "LuaBifaCard",
	skill_name = "LuaBifa",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,

	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:getPile(self:getSkillName()):isEmpty()
	end,
	
	feasible = function(self, targets)
		return #targets == 1
	end,

	on_use = function(self, room, source, targets)
		targets[1]:addToPile(self:getSkillName(), self:getSubcards():first(), false)
		local data = sgs.QVariant()
		data:setValue(source)
		targets[1]:setTag(self:getSkillName()..self:getEffectiveId(), data)
	end,
}

LuaBifaVS = sgs.CreateOneCardViewAsSkill{   
	name = "LuaBifa",
	response_pattern = "@@LuaBifa",
	filter_pattern = ".|.|.|hand",
	
	view_as = function(self, originalCard)
		local skillcard = LuaBifaCard:clone()
		skillcard:addSubcard(originalCard)
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,
}

LuaBifa = sgs.CreateTriggerSkill{
	name = "LuaBifa",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.EventPhaseStart,
	view_as_skill = LuaBifaVS,
	
	on_record = function(self, event, room, player, data)
		if player and player:isAlive() and not player:getPile(self:objectName()):isEmpty() and player:getPhase() == sgs.Player_RoundStart then
			room:fillAG(player:getPile(self:objectName()), player)
			local bifa_id = player:getPile(self:objectName()):first()
			local chenlin = player:getTag(self:objectName()..bifa_id):toPlayer()
			local bifa_card, pattern, card = sgs.Sanguosha:getCard(bifa_id)
			if bifa_card:isKindOf("BasicCard") then
				pattern = "BasicCard"
			elseif bifa_card:isKindOf("TrickCard") then
				pattern = "TrickCard"
			elseif bifa_card:isKindOf("EquipCard") then
				pattern = "EquipCard"
			end
			if chenlin and chenlin:isAlive() and not player:isKongcheng() then
				card = room:askForCard(player, pattern, "@"..self:objectName(), data, sgs.Card_MethodNone, chenlin)
			end
			room:clearAG(player)
			if card then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), chenlin:objectName(), self:objectName(), "")
				room:moveCardTo(card, player, chenlin, sgs.Player_PlaceHand, reason, false)
				reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName(), self:objectName(), "")
				room:moveCardTo(bifa_card, nil, player, sgs.Player_PlaceHand, reason, false)	
			else
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
				room:throwCard(bifa_card, reason, nil)
				room:loseHp(player)
			end
			player:removeTag(self:objectName()..bifa_id)
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
			if not player:isKongcheng() then return self:objectName() end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if room:askForUseCard(player, "@@"..self:objectName(), self:objectName().."-SkillCard", -1, sgs.Card_MethodNone) then
			room:broadcastSkillInvoke(self:objectName(), player)
		end
		return false 
	end,
}

--[[
	闭月
	相关武将：标-貂蝉
	描述：结束阶段开始时，你可以摸一张牌。 
	引用：
	状态：
]]

LuaBiyue = sgs.CreatePhaseChangeSkill{
	name = "LuaBiyue",
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self,event,room,player)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
			return self:objectName()
		end
	end,
	on_cost = function(self,event,room,player)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
	end,
	on_phasechange = function(self,player)
		player:drawCards(1)
	end,
}

--[[
	秉一
	相关武将：身份-顾雍
	描述：结束阶段开始时，你可以展示所有手牌，若颜色均相同，你令至多X名角色各摸一张牌（X为你的手牌数）。
	引用：
	状态：1.2.0 验证通过
]]

luabingyiCard = sgs.CreateSkillCard{
	name = "luabingyiCard",
	skill_name = "luabingyi",
	target_fixed = false,
	will_throw = true,

	filter = function(self, targets, to_select, player)
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:getColor() ~= player:getHandcards():first():getColor() then return false end
		end
		return #targets < player:getHandcardNum()
	end,

	feasible = function(self, targets)
		return true
	end,

	on_use = function(self, room, source, targets)
		room:showAllCards(source)
		for _, p in ipairs(targets) do 
			room:drawCards(p, 1, "luabingyi")
		end
	end,
}

luabingyiVS = sgs.CreateZeroCardViewAsSkill{   
	name = "luabingyi",
	response_pattern = "@@luabingyi",

	view_as = function(self)
		local skillcard = luabingyiCard:clone()
		skillcard:setSkillName(self:objectName())
		skillcard:setShowSkill(self:objectName())
		return skillcard
	end,

	enabled_at_play = function(self, player)
		return false
	end, 
}

luabingyi = sgs.CreateTriggerSkill{
	name = "luabingyi",
	can_preshow = true,
	events = sgs.EventPhaseStart,
	view_as_skill = luabingyiVS,
	
	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish) or player:isKongcheng() then return "" end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		if room:askForUseCard(player, "@@luabingyi", "@bingyi-card:::"..player:getHandcardNum()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		return false 
	end,
}

--[[
	不屈
	相关武将：标-周泰
	描述：每当你扣减1点体力后，若你的体力值为0，你可以将牌堆顶的一张牌置于武将牌上，称为“创”，若所有“创”的点数
	      均不同，你不进入濒死状态。 
	引用：
	状态：
]]

function sortfunction(a,b)
	return sgs.Sanguosha:getCard(a):getNumber() < sgs.Sanguosha:getCard(b):getNumber()
end

function LuaRemove(zhoutai)
		local room = zhoutai:getRoom()
		local buqu = zhoutai:getPile("luabuqu")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "" , "LuaBuqu", "")
		local need = 1 - zhoutai:getHp()
		if need <= 0 then
            for _, card_id in sgs.qlist(buqu) do
				local log = sgs.LogMessage()
				log.type = "$BuquRemove"
                log.from = zhoutai
				log.card_str = sgs.Sanguosha:getCard(card_id):toString()
				room:sendLog(log)
                room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
			end
		else
			local to_remove = buqu:length() - need
			for i = 1, to_remove, 1 do
				local buqu = sgs.QList2Table(zhoutai:getPile("luabuqu"))
				local duplicate_numbers = {}
				for _, card_id in ipairs(buqu) do
					for _, id in ipairs(buqu) do
						if sgs.Sanguosha:getCard(card_id):getNumber() == sgs.Sanguosha:getCard(id):getNumber()
							and not table.contains(duplicate_numbers, id) and card_id ~= id then
							table.insert(duplicate_numbers, id)
							if not table.contains(duplicate_numbers, card_id) then
                                table.insert(duplicate_numbers, card_id)
							end
						end
					end
				end
				local buqu_list = sgs.IntList()
				if #duplicate_numbers > 0 then
					table.sort(duplicate_numbers, sortfunction(a,b))
					for _, id in ipairs(duplicate_numbers) do
						buqu_list:append(id)
					end
				else
					table.sort(buqu, sortfunction(a,b))
					for _, id in ipairs(buqu) do
						buqu_list:append(id)
					end
				end
				room:fillAG(buqu_list, zhoutai)
				local card_id = room:askForAG(zhoutai, buqu, false, "LuaBuqu")

				local log = sgs.LogMessage()
				log.type = "$BuquRemove"
				log.from = zhoutai
				log.card_str = sgs.Sanguosha:getCard(card_id):toString()
				room:sendLog(log)

				buqu:removeOne(card_id)
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
				room:clearAG(zhoutai)
			end
		end
	end
	

LuaBuquRemove = sgs.CreateTriggerSkill{
	name = "#LuaBuqu-remove",
	events = {sgs.HpRecover},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self,event,room,zhoutai,data)
		if not zhoutai or not zhoutai:isAlive() or not zhoutai:hasSkill("LuaBuqu") then return false end
		if zhoutai:getPile("luabuqu"):length() > 0 then
            LuaRemove(zhoutai)
		end
	end,
}

LuaBuqu = sgs.CreateTriggerSkill{
	name = "LuaBuqu",
	events = {sgs.PostHpReduced,sgs.AskForPeachesDone},
	frequency = sgs.Skill_Frequent,

	can_trigger = function(self,event,room,zhoutai,data)
		if not zhoutai or not zhoutai:isAlive() or not zhoutai:hasSkill(self:objectName()) then return false end
		if event == sgs.PostHpReduced and zhoutai:getHp() < 1 then
			return self:objectName()
		elseif event == sgs.AskForPeachesDone then
			local buqu = zhoutai:getPile("luabuqu")
			if zhoutai:getHp() > 0 then return false end
			if room:getTag("LuaBuqu"):toString() ~= zhoutai:objectName() then return false end
			room:removeTag("LuaBuqu")

			local duplicate_numbers = {}
			local numbers = {}
			for _, card_id in sgs.qlist(buqu) do
				local card = sgs.Sanguosha:getCard(card_id)
				local number = card:getNumber()

				if table.contains(numbers, number) and not table.contains(duplicate_numbers, number) then
                    table.insert(duplicate_numbers,number)
                else
                    table.insert(numbers,number)
				end
			end

			if #duplicate_numbers == 0 then
				room:broadcastSkillInvoke(self:objectName(), zhoutai)
				room:setPlayerFlag(zhoutai, "-Global_Dying")
				return self:objectName()
			end
		end
	end,

	on_cost = function(self,event,room,zhoutai,data)
		if event == sgs.AskForPeachesDone then
			return true
		end
		if zhoutai:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), zhoutai)
			local buqu = zhoutai:getPile("luabuqu")
			local need = 1 - zhoutai:getHp()
			local n = need - buqu:length()
			if n > 0 then
				local card_ids = room:getNCards(n, false)
                zhoutai:addToPile("luabuqu", card_ids)
			end
			return true
		end
	end,

	on_effect = function(self,event,room,zhoutai,data)
		if event == sgs.AskForPeachesDone then
			return true
		end
		if zhoutai:getHp() < 1 then
			room:setTag("LuaBuqu", sgs.QVariant(zhoutai:objectName()))
			local buqunew = zhoutai:getPile("luabuqu")
			
			local duplicate_numbers = {}
			local numbers = {}
			for _, card_id in sgs.qlist(buqunew) do
				local card = sgs.Sanguosha:getCard(card_id)
				local number = card:getNumber()

				if table.contains(numbers, number) and not table.contains(duplicate_numbers, number) then
                    table.insert(duplicate_numbers,number)
                else
                    table.insert(numbers,number)
				end
			end
			if #duplicate_numbers == 0 then
				room:removeTag("LuaBuqu")
                return true
			else
				local log = sgs.LogMessage()
				log.type = "#BuquDuplicate"
				log.from = zhoutai
				log.arg = #duplicate_numbers
                room:sendLog(log)

				for i = 1, #duplicate_numbers, 1 do
					local number = duplicate_numbers[i]

					local log = sgs.LogMessage()
                    log.type = "#BuquDuplicateGroup"
                    log.from = zhoutai
                    log.arg = i
					local number_string = {"-","A","2","3","4","5","6","7","8","9","10","J","Q","K"}
					log.arg2 = number_string[number]
					room:sendLog(log)
					for _, card_id in sgs.qlist(buqunew) do
						local card = sgs.Sanguosha:getCard(card_id)
						if card:getNumber() == number then
							local log = sgs.LogMessage()
							log.type = "$BuquDuplicateItem"
							log.from = zhoutai
							log.card_str = card_id
							room:sendLog(log)
						end
					end
				end
			end
		end
	end,
}

LuaBuquClear = sgs.CreateTriggerSkill{
	name = "#LuaBuquClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventLoseSkill},

	can_trigger = function(self,event,room,zhoutai,data)
		if data:toString() == "LuaBuqu" then
			if zhoutai:getHp() <= 0 then
				room:enterDying(zhoutai, nil)
			end
		end
	end,
}

--[[
	补益
	相关武将：身份-吴国太
	描述：当一名角色进入濒死状态时，你可展示其一张手牌，然后 若此牌不为基本牌：其弃置之，回复1点体力。 
	引用：
	状态：1.2.1验证通过
]]

LuaBuyi = sgs.CreateTriggerSkill{
	name = "LuaBuyi",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.Dying,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local dying = data:toDying()
			if dying.who:getHp() < 1 and not dying.who:isKongcheng() then 
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
		local dying, card = data:toDying()
		if player:objectName() == dying.who:objectName() then
			card = room:askForCardShow(dying.who, player, self:objectName())
		else
			local id = room:askForCardChosen(player, dying.who, "h", self:objectName())
			card = sgs.Sanguosha:getCard(id)
		end
		room:showCard(dying.who, card:getEffectiveId())
		if card:getTypeId() ~= sgs.Card_TypeBasic then
			if not dying.who:isJilei(card) then
				room:throwCard(card, dying.who)
			end
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(dying.who, recover)
		end
		return false 
	end,
}