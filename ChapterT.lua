--[[
	国战技能速查手册（T区）
	技能索引：
	天妒、天覆、天香、天义、挑衅、铁骑、突袭、屯田  
]]--
--[[
	天妒
	相关武将：标-郭嘉
	描述：每当你的判定牌生效后，你可以获得此牌。 
	引用：
	状态：
]]
luaTiandu = sgs.CreateTriggerSkill{
	name = "luaTiandu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.FinishJudge},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local judge = data:toJudge()
		if room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
			return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
		return player:askForSkillInvoke(self:objectName(), data)
	end,
	
	on_effect = function(self, event, room, player, data)
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		local judge = data:toJudge()
		player:obtainCard(judge.card)
	end,
}

--[[
	天覆
	相关武将：阵-姜维
	描述：主将技，阵法技，若当前回合角色为你所在队列里的角色，你视为拥有“看破”。 
	引用：
	状态：
]]
--[[
	天香
	相关武将：标-小乔
	描述：每当你受到伤害时，你可以弃置一张♥手牌并选择一名其他角色，将此伤害转移给该角色，若如此做，当该角色因此而受到的伤害结算结束时，其摸X张牌（X为其已损失的体力值）。 
	引用：
	状态：
]]


--天香
LuaTianxiangCard = sgs.CreateSkillCard{
	name = "LuaTianxiangCard",
	on_effect = function(self,effect)
		effect.to:setFlags("tianxiang_target")
		effect.from:setFlags("tianxiang_invoke")
	end,
}

LuaTianxiangVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaTianxiang",
	response_pattern = "@@LuaTianxiang",

	view_as = function(self, card)
		local tianxiangCard = LuaTianxiangCard:clone()
		tianxiangCard:addSubcard(card)		
		tianxiangCard:setSkillName(self:objectName())
		tianxiangCard:setShowSkill(self:objectName())
        return tianxiangCard
	end,
	
	view_filter = function(self, to_select)
		if sgs.Self:isJilei(to_select) then return false end
		local pat
		if sgs.Self:hasSkill("hongyan") and not sgs.Self:hasShownSkill("hongyan") then
			pat = ".|heart,spade|.|hand"
        else
			pat = ".|heart|.|hand"
		end
		return sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
    end,
}

LuaTianxiang = sgs.CreateTriggerSkill{
	name = "LuaTianxiang",
	events = {sgs.DamageInflicted},
	view_as_skill = LuaTianxiangVS,
	can_preshow = true,

	can_trigger = function(self,event,room,xiaoqiao,data)
		if not xiaoqiao or xiaoqiao:isDead() or not xiaoqiao:hasSkill(self:objectName()) then return false end
		if xiaoqiao:canDiscard(xiaoqiao, "h") then
			return self:objectName()
		end
	end,
	on_cost = function(self,event,room,xiaoqiao,data)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
            p:setFlags("-tianxiang_target")
		end
		xiaoqiao:setFlags("-tianxiang_invoke");
		xiaoqiao:setTag("TianxiangDamage",data)
        room:askForUseCard(xiaoqiao, "@@LuaTianxiang", "@tianxiang-card", -1, sgs.Card_MethodDiscard)
		xiaoqiao:removeTag("TianxiangDamage")
		if xiaoqiao:hasFlag("tianxiang_invoke") then
			return true
		end
	end,
	
	on_effect = function(self,event,room,xiaoqiao,data)
		local target
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag("tianxiang_target") then
				target = p
				break
			end
		end
		xiaoqiao:setFlags("-tianxiang_invoke")
		target:setFlags("-tianxiang_target")

		local damage = data:toDamage()
		damage.transfer = true
		damage.to = target
		damage.transfer_reason = "LuaTianxiang"

		local d = sgs.QVariant()
		d:setValue(damage)
        xiaoqiao:setTag("TransferDamage", d)
        return true
	end,
}

LuaTianxiangDraw = sgs.CreateTriggerSkill{
	name = "#LuaTianxiang",
	events = {sgs.DamageComplete},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,event,room,player,data)
        if not player then return false end
		local damage = data:toDamage()
		if player:isAlive() and damage.transfer and damage.transfer_reason == "LuaTianxiang" then
			player:drawCards(player:getLostHp())
		end
	end,
}

--[[
	天义
	相关武将：标-太史慈
	描述：出牌阶段限一次，你可以与一名角色拼点。若你赢，你能额外使用一张【杀】且使用【杀】无距离限制且使用【杀】选择目标的个数上限+1，直到回合结束。若你没赢，你不能使用【杀】，直到回合结束。 
	引用：
	状态：
]]

LuaTianyiCard = sgs.CreateSkillCard{
	name = "LuaTianyiCard", 
	filter = function(self, targets, to_select)
		return #targets == 0 and (not to_select:isKongcheng()) and to_select:objectName() ~= sgs.Self:objectName()
	end,
	extra_cost = function(self, room, use)
		local pd = sgs.PindianStruct()
		pd = use.from:pindianSelect(use.to:first(), "LuaTianyi")
		local d = sgs.QVariant()
		d:setValue(pd)
		use.from:setTag("luatianyi_pd", d)
	end,
	
	on_effect = function(self, effect)
		local pd = effect.from:getTag("luatianyi_pd"):toPindian()
		effect.from:removeTag("luatianyi_pd")
		if pd then
			local success = effect.from:pindian(pd)
			pd = nil
			if success then
				effect.to:getRoom():setPlayerFlag(effect.from, "luaTianyiSuccess")
			else
				effect.to:getRoom():setPlayerCardLimitation(effect.from, "use", "Slash", true)
			end
		end
	end,
}

LuaTianyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaTianyi",
	view_as = function(self)
		local card = LuaTianyiCard:clone()
		card:setShowSkill(self:objectName())
		card:setSkillName(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaTianyiCard") and not player:isKongcheng()
	end, 
}
	
LuaTianyiTargetMod = sgs.CreateTargetModSkill{
	name = "#LuaTianyiTargetMod",
	pattern = "Slash",
	residue_func = function(self, from, card)
        if from:hasFlag("luaTianyiSuccess") then
            return 1
        else
            return 0
		end
	end,
	
	distance_limit_func = function(self, from, card)
        if from:hasFlag("luaTianyiSuccess") then
            return 1000
        else
            return 0
		end
	end,
	
	extra_target_func = function(self, from, card)
        if from:hasFlag("luaTianyiSuccess") then
            return 1
        else
            return 0
		end
	end,
}

--[[
	挑衅
	相关武将：阵-姜维
	描述：出牌阶段限一次，你可以令攻击范围内含有你的一名其他角色选择是否对你使用一张【杀】，若该角色选择否，你弃置其一张牌。 
	引用：
	状态：
]]
--[[
	铁骑
	相关武将：标-马超
	描述：每当你使用【杀】指定一名目标角色后，你可以进行判定，若结果为红色，该角色不能使用【闪】响应此次对其结算的此【杀】。 
	引用：
	状态：
]]

luatieqi = sgs.CreateTriggerSkill {
	name = "luatieqi",
	events = {sgs.TargetChosen},
	frequency = Frequent,
	
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local use = data:toCardUse()
		if not use.card or not use.from then return false end
		if player:objectName() ~= use.from:objectName() or not use.card:isKindOf("Slash") then return false end			
		local targets = {}
		for _, p in sgs.qlist(use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return self:objectName().."->"..table.concat(targets,"+")
		else return false
		end
	end	,
	
	on_cost = function(self, event, room, player, data, ask_who)
		local d = sgs.QVariant()
		d:setValue(player)
		return room:askForSkillInvoke(ask_who, self:objectName(), d)
	end,
	
	on_effect = function(self, event, room, player, data, ask_who)
	    local room = player:getRoom()
		local use = data:toCardUse()
		local jink_list = ask_who:getTag("Jink_"..use.card:toString()):toList()
		local judge = sgs.JudgeStruct()			
		room:broadcastSkillInvoke(self:objectName(),1,ask_who)
		local lord = room:getLord(ask_who:getKingdom())
		local has_lord = false
		if lord and lord:hasLordSkill("shouyue") and lord:hasShownGeneral1() then
			has_lord = true
			judge.pattern = ".|spade"
			judge.good = false
		else
			judge.pattern = ".|red"
			judge.good = true
		end
		judge.reason = self:objectName()
		judge.who = ask_who
		if has_lord then room:notifySkillInvoked(lord, "shouyue")
		else room:notifySkillInvoked(ask_who,self:objectName()) end
		player:setFlags("TieqiTarget") --for AI			
		room:judge(judge)			
		player:setFlags("-TieqiTarget") --for AI

        if judge:isGood() then
			local log = sgs.LogMessage()
			log.type = "#NoJink"
			log.from = player
			room:sendLog(log)
			local index = listIndexOf(use.to, player)
			jink_list:replace(index,sgs.QVariant(0))
			room:broadcastSkillInvoke(self:objectName(),2,ask_who)
		end
		ask_who:setTag("Jink_"..use.card:toString(), sgs.QVariant(jink_list))
	end,
}

--[[
	突袭
	相关武将：标-张辽
	描述：摸牌阶段开始时，你可以放弃摸牌并选择一至两名有手牌的其他角色，获得这些角色的各一张手牌。 
	引用：
	状态：
]]

luaTuxiCard = sgs.CreateSkillCard{
	name = "luaTuxiCard",
	filter = function(self, targets, to_select)
		if (#targets >= 2) or (to_select:objectName() == sgs.Self:objectName()) then return false end
		return not to_select:isKongcheng()
	end,
	on_use = function(self, room, player, targets)
		local target_list = sgs.VariantList()
		for _, p in ipairs(targets) do
			local d = sgs.QVariant()
			d:setValue(p)
			target_list:append(d)
		end
		player:setTag("tuxi_invoke", sgs.QVariant(target_list))
		player:setFlags("tuxi")
	end,
}

luaTuxiVS = sgs.CreateZeroCardViewAsSkill{
	name = "luaTuxi",
	response_pattern = "@@luaTuxi",     
	view_as = function(self)
		return luaTuxiCard:clone()
	end,
}

luaTuxi = sgs.CreatePhaseChangeSkill{
	name = "luaTuxi" ,
	view_as_skill = luaTuxiVS,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Draw then
				player:removeTag("tuxi_invoke")
				for _, player in sgs.qlist(room:getOtherPlayers(player)) do
					if not player:isKongcheng() then
						return self:objectName()
					end
				end			
			end
		end
	end,
	on_cost = function(self,event,room,player,data)
		room:askForUseCard(player, "@@luaTuxi", "@tuxi-card")
		return player:hasFlag("tuxi") and not player:getTag("jtuxi_invoke"):toList():isEmpty()
	end,
	
	on_phasechange = function(self, player)
		local targets = player:getTag("tuxi_invoke"):toList()
		
		player:removeTag("tuxi_invoke")
		local room = player:getRoom()
		local moves = sgs.CardsMoveStruct()
        moves.card_ids:append(room:askForCardChosen(player, targets:at(0):toPlayer(), "h", self:objectName()))
        moves.to = player
        moves.to_place = sgs.Player_PlaceHand
        if targets:length() == 2 then
            moves.card_ids:append(room:askForCardChosen(player, targets:at(1):toPlayer(), "h", self:objectName()))
		end
        room:moveCardsAtomic(moves, false)
        return true
	end
}

--[[
	屯田
	相关武将：阵-邓艾
	描述：每当你于回合外失去牌后，你可以进行判定，当非♥的判定牌生效后，你可以将此牌置于武将牌上，称为“田”；你与其他角色的距离-X（X为“田”的数量）。 
	引用：
	状态：
]]
