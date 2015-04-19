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
--[[
	烈弓
	相关武将：标-黄忠
	描述：每当你于出牌阶段内使用【杀】指定一名角色为目标后，若该角色的手牌数不小于你的体力值或不大于你的攻击范围，你可以令其不能使用【闪】响应此次对其结算的此【杀】。 
	引用：
	状态：
]]
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
--[[
	龙胆
	相关武将：标-赵云
	描述：你可以将一张【杀】当【闪】使用或打出；你可以将一张【闪】当【杀】使用或打出。 
	引用：
	状态：
]]
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
