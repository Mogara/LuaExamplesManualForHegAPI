--[[
	国战技能速查手册（S区）
	技能索引：
	尚义、涉猎、神速、慎行、神智、生息、失北、守成、授钺、淑慎、双刃、双雄、司敌、死谏、随势  
]]--
--[[
	尚义
	相关武将：阵-蒋钦
	描述：出牌阶段限一次，你可以令一名其他角色观看你的所有手牌，你选择一项：1.观看该角色的手牌并可以弃置其中的一张黑色牌；2.观看该角色暗置的所有武将牌。 
	引用：
	状态：
]]

--[[
	涉猎
	相关武将：身份-神·吕蒙
	描述：摸牌阶段开始时，你可放弃摸牌，亮出牌堆顶的五张牌，然后获得其中每种花色的牌各一张，将其余的牌置入弃牌堆。 
	引用：
	状态：1.2.1验证通过
	相关翻译{
		["LuaShelie#up"] = "置入弃牌堆",
		["LuaShelie#down"] = "获得",
		["@LuaShelie"] = "请选择花色各不同的卡牌",
	}
]]

function LuaShelieAsMovePattern(selected, to_select)
	for _, id in ipairs(selected) do
		if sgs.Sanguosha:getCard(to_select):getSuit() == sgs.Sanguosha:getCard(id):getSuit() then
			return false
		end
	end
	return true
end

LuaShelie = sgs.CreateTriggerSkill{
	name = "LuaShelie",
	can_preshow = true,
	frequency = sgs.Skill_NotFrequent,
	events = sgs.EventPhaseStart,

	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Draw) then return "" end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
	end,

	on_effect = function(self, event, room, player, data)
		local card_ids, suits = room:getNCards(5), {}
		for _, id in sgs.qlist(card_ids) do table.insert(suits, sgs.Sanguosha:getCard(id):getSuit()) end
		local AsMove = room:askForMoveCards(player, card_ids, sgs.IntList(), true, self:objectName(), "LuaShelieAsMovePattern", self:objectName(), #table.toSet(suits), #table.toSet(suits), false, true)

		local dummy = sgs.Sanguosha:cloneCard("jink")
		dummy:deleteLater()
		if not AsMove.bottom:isEmpty() then
			dummy:addSubcards(AsMove.bottom)
			player:obtainCard(dummy)
		end
		dummy:clearSubcards()
		if not AsMove.top:isEmpty() then
			dummy:addSubcards(AsMove.top)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
			room:throwCard(dummy, reason, nil)
		end

		return true
	end
}

--[[
	神速
	相关武将：标-夏侯渊
	描述：你可以跳过判定阶段和摸牌阶段，视为使用一张【杀】；你可以跳过出牌阶段并弃置一张装备牌，视为使用一张【杀】。 
	引用：
	状态：
]]

luaShensuCard = sgs.CreateSkillCard{
	name = "luaShensuCard" ,
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end

		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("luaShensu")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end ,
	
	on_use = function(self, room, source, targets)
		for _, target in ipairs(targets) do
			if not source:canSlash(target, nil, false) then
				targets:removeOne(target)
            end
		end
		if #targets > 0 then
			local index = "2"
			if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then			
				index = "1"
			end					
			local targets_list = sgs.VariantList()
			for _, target in ipairs(targets) do
				local d = sgs.QVariant()
				d:setValue(target)
				targets_list:append(d)
			end
			source:setTag("shensu_invoke" .. index, sgs.QVariant(targets_list))
			source:setFlags("shensu" .. index)
		end
	end,
}

luaShensuVS = sgs.CreateViewAsSkill{
	name = "luaShensu",
	view_filter = function(self, selected, to_select)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then 
			return false
		else
			return #selected == 0 and to_select:isKindOf("EquipCard") and not sgs.Self:isJilei(to_select)
		end
	end ,
		
	view_as = function(self, cards)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") then
			if #cards == 0 then
				local card = luaShensuCard:clone()
				return card
			end
		else
			if #cards == 1 then
				local card = luaShensuCard:clone()
				for _, cd in ipairs(cards) do
					card:addSubcard(cd)
				end
				return card
			end
		end
		return nil
	end,		
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@luaShensu")
	end
}

luaShensu = sgs.CreateTriggerSkill{
	name = "luaShensu" ,
	events = {sgs.EventPhaseChanging} ,
	view_as_skill = luaShensuVS ,
	can_preshow = true ,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) or not sgs.Slash_IsAvailable(player) then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Draw) then
			player:removeTag("shensu_invoke1")
			return self:objectName()
		elseif change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) and player:canDiscard(player, "he") then
			player:removeTag("shensu_invoke2")
			return self:objectName()
		end
	end,		
	on_cost = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Judge and room:askForUseCard(player, "@@luaShensu1", "@shensu1", 1) then
			if player:hasFlag("shensu1") and not player:getTag("shensu_invoke1"):toList():isEmpty() then
                player:skip(sgs.Player_Judge)
                player:skip(sgs.Player_Draw)
                return true
			end
		elseif change.to == sgs.Player_Play and room:askForUseCard(player, "@@luaShensu2", "@shensu2", 2, sgs.Card_MethodDiscard) then
			if player:hasFlag("shensu2") and not player:getTag("shensu_invoke2"):toList():isEmpty() then
				player:skip(sgs.Player_Play)
				return true
			end
		end
	end,
	
	on_effect = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		local target_list = sgs.VariantList()
		if change.to == sgs.Player_Judge then
			target_list = player:getTag("shensu_invoke1"):toList()
			player:removeTag("shensu_invoke1")
		else
			target_list = player:getTag("shensu_invoke2"):toList()
			player:removeTag("shensu_invoke2")
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("_shensu")
		local carduse = sgs.CardUseStruct()
		carduse.card = slash
		carduse.from = player
		for i = 0, target_list:length() - 1, 1 do
            carduse.to:append(target_list:at(i):toPlayer())
        end
        room:useCard(carduse)
        return false
	end,
}

luaShensuSlash = sgs.CreateTargetModSkill{
	name = "#luaShensu-slash" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("luaShensu") and (card:getSkillName() == "luaShensu") then
			return 1000
		else
			return 0
		end
	end,
}

--[[
	慎行
	相关武将：身份-顾雍
	描述：出牌阶段，你可以弃置两张牌，摸一张牌。
	引用：
	状态：1.2.0 验证通过
]]

luashenxingCard = sgs.CreateSkillCard{
	name = "luashenxingCard",
	skill_name = "luashenxing",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
		room:drawCards(source, 1, "luashenxing")
	end,
}

luashenxing = sgs.CreateViewAsSkill{
	name = "luashenxing", 
	n = 2,

	view_filter = function(self, selected, to_select)
		return true
	end,

	view_as = function(self, originalCards) 
		if #originalCards == 2 then
			local skillcard = luashenxingCard:clone()
			for _, card in ipairs(originalCards) do
				skillcard:addSubcard(card)
			end
			skillcard:setSkillName(self:objectName())
			skillcard:setShowSkill(self:objectName())
			return skillcard
		end
	end, 

	enabled_at_play = function(self, player)
		return player:getCardCount(true) >= 2 and player:canDiscard(player, "he")
	end, 
}

--[[
	神智
	相关武将：标-甘夫人
	描述：准备阶段开始时，你可以弃置所有手牌，然后若你以此法弃置的手牌数不小于X（X为你的体力值），你回复1点体力。 
	引用：
	状态：
]]

LuaShenzhi = sgs.CreatePhaseChangeSkill{
	name = "LuaShenzhi",
	frequency = sgs.Skill_Frequent,
	can_preshow = false,
		--This skill can't be frequent in game actually.
		--because the frequency = Frequent has no effect in UI currently, we use this to reduce the AI delay


	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if player:getPhase() ~= sgs.Player_Start or player:isKongcheng() then return false end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,

	on_phasechange = function(self, ganfuren)
		local handcard_num = 0
		for _, card in sgs.qlist(ganfuren:getHandcards()) do
			if not ganfuren:isJilei(card) then
				handcard_num = handcard_num + 1
			end
		end
		ganfuren:throwAllHandCards()
		if handcard_num >= ganfuren:getHp() then
			local recover = sgs.RecoverStruct()
			recover.who = ganfuren
			ganfuren:getRoom():recover(ganfuren, recover)
		end
        return false
	end,
}

--[[
	生息
	相关武将：阵-蒋琬&费祎
	描述：出牌阶段结束时，若你未于此阶段内造成过伤害，你可以摸两张牌。 
	引用：
	状态：
]]

--[[
	失北
	相关武将：身份-沮授
	描述：锁定技，每当你于一名角色的回合内受到伤害后，若为你本回合第一次受到伤害，你回复1点体力，否则你失去1点体力。
	引用：
	状态：2.0
]]

LuaShibei = sgs.CreateTriggerSkill{
	name = "LuaShibei",
	can_preshow = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.EventPhaseStart},
	
	on_record = function(self, event, room, player, data)
		if not (player and player:isAlive()) then return end
		if event == sgs.Damaged then
			local current = room:getCurrent()
			if current and current:isAlive() and current:getPhase() ~= sgs.Player_NotActive then
				player:addMark(self:objectName().."_count")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					p:setMark(self:objectName().."_count", 0)
				end
			end
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(self:objectName()) and event == sgs.Damaged) then return "" end
		return self:objectName()
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		if player:getMark(self:objectName().."_count") == 1 then
			local recover = sgs.RecoverStruct()
			recover.recover = 1
			recover.who = player
			room:recover(player, recover)
		else
			room:loseHp(player)
		end
		return false 
	end,
}

--[[
	守成
	相关武将：阵-蒋琬&费祎
	描述：每当与你势力相同的一名角色于回合外失去最后的手牌时，你可以令该角色摸一张牌。 
	引用：
	状态：
]]
--[[
	授钺
	相关武将：阵-君刘备
	描述：君主技，锁定技，你拥有“五虎将大旗”。
		★五虎将大旗★
		存活的蜀势力角色拥有的下列五个技能分别调整为：
		武圣——你可以将一张牌当【杀】使用或打出。
		咆哮——你使用【杀】无次数限制；每当你使用【杀】指定一名角色为目标后，你无视该角色的防具。
			◆你使用【杀】指定A为目标后触发【咆哮②】，你无视A的防具的效果持续到：
			1、此【杀】因对A无效而终止使用结算。
			2、此【杀】的效果被A使用的【闪】抵消。
			3、此【杀】对A进行使用结算造成的伤害，在伤害结算中防止此伤害。
			4、此【杀】对A进行使用结算造成的伤害，在伤害结算中计算出最终的伤害值。
		龙胆——你可以将一张【杀】当【闪】，或一张【闪】当【杀】使用或打出，当你以此法使用或打出牌时，你摸一张牌。
		烈弓——每当你于出牌阶段内使用【杀】指定一名角色为目标后，若该角色的手牌数不小于你的体力值或不大于你的攻击范围，你可以令其不能使用【闪】响应此【杀】；你的攻击范围+1。
		铁骑——每当你使用【杀】指定一名角色为目标后，你可以进行判定，若结果不为♠，该角色不能使用【闪】响应此【杀】。 
	引用：
	状态：
]]
--[[
	淑慎
	相关武将：标-甘夫人
	描述：每当你回复1点体力后，你可以令与你势力相同的一名其他角色摸一张牌。 
	引用：
	状态：
]]

LuaShushen = sgs.CreateTriggerSkill{
	name = "LuaShushen",
	events = {sgs.HpRecover},
	can_preshow = true,

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local friends = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:willBeFriendWith(p) then
				friends:append(p)
			end
		end
		if friends:isEmpty() then return false end
		local trigger_list = {}
		local recover = data:toRecover()
		for i = 1, recover.recover, 1 do
			table.insert(trigger_list, self:objectName())
		end
		return table.concat(trigger_list,",")
	end,

	on_cost = function(self, event, room, player, data)
		local friends = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:willBeFriendWith(p) then
				friends:append(p)
			end
		end
		if friends:isEmpty() then return false end
		local target = room:askForPlayerChosen(player, friends, self:objectName(), "shushen-invoke", true, true)
		if target then
			room:broadcastSkillInvoke(self:objectName(), player)

			local target_list = player:getTag("LuaShushen_target"):toList()
			local d = sgs.QVariant()
			d:setValue(target)
			target_list:append(d)
			player:setTag("LuaShushen_target",sgs.QVariant(target_list))
            return true
		end
	end,

	on_effect = function(self, event, room, player, data)
        local target_list = player:getTag("LuaShushen_target"):toList()
		to = target_list:last():toPlayer()
		local d = sgs.QVariant()
		d:setValue(to)
		target_list:removeOne(d)
		player:setTag("LuaShushen_target",sgs.QVariant(target_list))

        if to then to:drawCards(1) end
	end,
}

--[[
	双刃
	相关武将：标-纪灵
	描述：出牌阶段开始时，你可以与一名角色拼点。若你赢，你视为对其或一名与其势力相同的其他角色使用一张【杀】。若你没赢，你结束出牌阶段。 
	引用：
	状态：
]]

LuaShuangren = sgs.CreatePhaseChangeSkill{
	name = "LuaShuangren",

    can_trigger = function(self,event,room,player,data)
		if not player or not player:hasSkill(self:objectName()) then return false end
		if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
			local room = player:getRoom()
			local can_invoke = false
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then
					can_invoke = true
					break
				end
			end
            return can_invoke and self:objectName()
		end
	end,

	on_cost = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() then
				targets:append(p)
			end
		end

		local victim = room:askForPlayerChosen(player, targets, "shuangren", "@shuangren", true, true)
		if victim then
			room:broadcastSkillInvoke(self:objectName(), 1, player)
			local pd = player:pindianSelect(victim, self:objectName())
			local d = sgs.QVariant()
			d:setValue(pd)
			player:setTag("shuangren_pd", d)
            return true
		end
	end,

	on_phasechange = function(self,player)
		local pd = player:getTag("shuangren_pd"):toPindian()
		player:removeTag("shuangren_pd")
		if pd then
			local target = pd.to
			local success = player:pindian(pd)
			pd = nil
			local room = player:getRoom()
			if success then
                local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if player:canSlash(p, nil, false) and (p:isFriendWith(target) or target:objectName() == p:objectName()) then
						targets:append(p)
					end
				end
				if (targets:isEmpty()) then return false end

				local slasher = room:askForPlayerChosen(player, targets, "shuangren-slash", "@dummy-slash")
				local slash = sgs.Sanguosha:cloneCard("Slash")
				slash:setSkillName("_shuangren")
				room:useCard(sgs.CardUseStruct(slash, player, slasher), false)
			else
				room:broadcastSkillInvoke(self:objectName(), 3, player)
                return true
			end
		else
            assert(false)
		end
	end,
}

--[[
	双雄
	相关武将：标-颜良&文丑
	描述：摸牌阶段开始时，你可以放弃摸牌，进行判定，当判定牌生效后，你获得此牌，然后你于此回合内可以将一张与此牌颜色不同的手牌当【决斗】使用。 
	引用：
	状态：
]]

LuaShuangxiongVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaShuangxiong",
	response_or_use = true,
	enabled_at_play = function(self,player)
		return player:getMark("shuangxiong") ~= 0 and not player:isKongcheng()
	end,
	view_filter = function(self, card)
		if card:isEquipped() then return false end
		local value = sgs.Self:getMark("shuangxiong")
		if value == 1 then
			return card:isBlack()
		elseif value == 2 then
			return card:isRed()
		end
		return false
	end,
	view_as = function(self,ocard)
		local duel = sgs.Sanguosha:cloneCard("duel", ocard:getSuit(), ocard:getNumber())
		duel:addSubcard(ocard)
		duel:setSkillName("_LuaShuangxiong")
		return duel
	end,
}

LuaShuangxiong = sgs.CreateTriggerSkill{
	name = "LuaShuangxiong",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	view_as_skill = LuaShuangxiongVS,
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() then return false end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			room:setPlayerMark(player, "shuangxiong", 0)
		elseif player:getPhase() == sgs.Player_Draw and player:hasSkill(self:objectName()) then
			return self:objectName()
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasFlag("shuangxiong") then
				room:setPlayerFlag(player, "-shuangxiong")
			end
		end
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), 1)
			return true
		end
	end,
	
	on_effect = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Draw and player:hasSkill(self:objectName()) then
			room:setPlayerFlag(player, "shuangxiong")
	
			local judge = sgs.JudgeStruct()
			judge.good = true
			judge.play_animation = false
			judge.reason = self:objectName()
			judge.who = player
	
			room:judge(judge)
			local n = judge.pattern == "red" and 1 or 2
			room:setPlayerMark(player, "shuangxiong", n)
		
			return true
		end
	end,
}
	
LuaShuangxiongGet = sgs.CreateTriggerSkill{
	name = "#LuaShuangxiong",

	events = {sgs.FinishJudge},
	frequency = sgs.Skill_Compulsory,
	can_preshow = false,
	
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() then
			local judge = data:toJudge()
			if judge.reason == "LuaShuangxiong" then
				judge.pattern = judge.card:isRed() and "red" or "black"
				if room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
					return self:objectName()
				end
			end
		end
	end,
	on_effect = function(self,room,event,player,data)
		local judge = data:toJudge()
		judge.who:obtainCard(judge.card)
	end,
}

--[[
	司敌
	相关武将：身份-曹真
	描述：当你使用或其他角色于你的回合内使用【闪】时，你可以将牌堆顶的一张牌置于武将牌上，称为“钤”；其他角色的出牌阶段开始时，你可以将一张“钤”牌置入弃牌堆。若如此做，该角色于此阶段内使用【杀】的次数上限-1。
	引用：
	状态：2.0
	相关翻译 {
		["@LuaSidi"] = "司敌：你可将一张“钤”置入弃牌堆，令 %src 此阶段使用【杀】的次数上限-1",
		["qian"] = "钤",
	}
]]

LuaSidi = sgs.CreateTriggerSkill{
	name = "LuaSidi",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardResponded, sgs.EventPhaseStart, sgs.EventPhaseChanging},
	
	on_record = function(self, event, room, player, data)
		if player and player:isAlive() and event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardResponded then
			local response = data:toCardResponse()
			local card = response.m_isUse and response.m_card
			if player and card and card:isKindOf("Jink") then
				local current = room:getCurrent()
				if current and current:isAlive() and player:objectName() ~= current:objectName() and current:getPhase() ~= sgs.Player_NotActive and current:hasSkill(self:objectName()) then 
					return self:objectName(), current
				end
				if player:isAlive() and player:hasSkill(self:objectName()) then
					return self:objectName()
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:getPhase() == sgs.Player_Play then
				local trigger_list_skill, trigger_list_who = {}, {}
				for _, caozhen in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if caozhen:getPile("qian"):length() > 0 and player:objectName() ~= caozhen:objectName() then
						table.insert(trigger_list_skill, self:objectName())
						table.insert(trigger_list_who, caozhen:objectName())
					end
				end
				return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
			end
		end

		return ""
	end,
	
	on_cost = function(self, event, room, player, data, caozhen)
		if event == sgs.CardResponded then
			if caozhen:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), 1, caozhen)
				return true 
			end
		elseif event == sgs.EventPhaseStart then
			local card = room:askForExchange(caozhen, self:objectName(), 1, 0, "@"..self:objectName()..":"..player:objectName(), "qian", ".|.|.|qian")
			if card then
				local log = sgs.LogMessage()
				log.type = "#InvokeSkill"
				log.from = caozhen
				log.arg = self:objectName()
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName(), 2, caozhen)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, caozhen:objectName(), self:objectName(), "")
				room:throwCard(card, reason, caozhen)
				return true 
			end
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data, caozhen)
		if event == sgs.CardResponded then
			local ids = room:getNCards(1, false)
			local move = sgs.CardsMoveStruct(ids, caozhen, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, caozhen:objectName(), self:objectName(), ""))
			room:moveCardsAtomic(move, true)
			caozhen:addToPile("qian", ids)
		elseif event == sgs.EventPhaseStart then
			room:addPlayerMark(player, self:objectName())
		end
		return false 
	end,
}

LuaSidi_Mod = sgs.CreateTargetModSkill{
	name = "#LuaSidi",
	pattern = "Slash",
	residue_func = function(self, player, card) 
		return - player:getMark("LuaSidi")
	end,
}

--[[
	死谏
	相关武将：标-田丰
	描述：每当你失去所有手牌后，你可以弃置一名其他角色的一张牌。 
	引用：
	状态：
]]

LuaSijian = sgs.CreateTriggerSkill{
	name = "LuaSijian",
	events = {sgs.CardsMoveOneTime},

    can_trigger = function(self,event,room,player,data)
		if not player or not player:hasSkill(self:objectName()) then return false end
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.is_last_handcard then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canDiscard(p, "he") then
					return self:objectName()
				end
			end
		end
	end,

	on_cost = function(self,event,room,player,data)
		local targets = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:canDiscard(p, "he") then
				targets:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, targets, self:objectName(), "sijian-invoke", true, true)
		if (to) then
			local d = sgs.QVariant()
			d:setValue(to)
			player:setTag("sijian_target", d)
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,

	on_effect = function(self,event,room,player,data)
		local to = player:getTag("sijian_target"):toPlayer()
		player:removeTag("sijian_target")
		if to and player:canDiscard(to, "he") then
			local card_id = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
			room:throwCard(card_id, to, player)
		end
	end,
}

--[[
	随势
	相关武将：标-田丰
	描述：锁定技，每当其他角色因受到伤害而进入濒死状态时，若来源与你势力相同，你摸一张牌；锁定技，每当其他与你势力相同的角色死亡时，你失去1点体力。 
	引用：
	状态：
]]

LuaSuishi = sgs.CreateTriggerSkill{
	name = "LuaSuishi",
	events = {sgs.Dying, sgs.Death},
	frequency = sgs.Skill_Compulsory,

    can_trigger = function(self,event,room,player,data)
		if not player or not player:hasSkill(self:objectName()) then return false end
		local target
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.damage and dying.damage.from then
				target = dying.damage.from
			end
			if dying.who:objectName() ~= player:objectName() and target and (target:isFriendWith(player) or player:willBeFriendWith(target)) then
				return self:objectName()
			end
		else
			local death = data:toDeath()
			target = death.who
			if target and (target:isFriendWith(player) or player:willBeFriendWith(target)) then
				return self:objectName()
			end
		end
	end,

	on_cost = function(self,event,room,player,data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), event) then
			if event == sgs.Dying then
				room:broadcastSkillInvoke(self:objectName(), 1, player)
			else
				room:broadcastSkillInvoke(self:objectName(), 2, player)
			end
            return true
		end
	end,

	on_effect = function(self,event,room,player,data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		if event == sgs.Dying then
			player:drawCards(1)
        else
			room:loseHp(player)
		end
	end,
}
