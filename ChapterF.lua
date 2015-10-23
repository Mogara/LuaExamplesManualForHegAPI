--[[
	国战技能速查手册（F区）
	技能索引：
	法恩、反间、反馈、反馈·界限、放权、放逐、奋命、奋迅、锋矢
]]--

--[[
	法恩
	相关武将：身份-陈群
	描述：每当一名角色的武将牌翻面或横置时，你可以令其摸一张牌。
	引用：
	状态：2.0
]]

LuaFaen = sgs.CreateTriggerSkill{
	name = "LuaFaen",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.TurnedOver, sgs.ChainStateChanged},

	can_trigger = function(self, event, room, player, data)
		if not (player and player:isAlive()) then return "" end
		if event == sgs.ChainStateChanged and not player:isChained() then return "" end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, chenqun in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			table.insert(trigger_list_skill, self:objectName())
			table.insert(trigger_list_who, chenqun:objectName())
		end
		return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
	end,
	
	on_cost = function(self, event, room, player, data, chenqun)
		local to_data = sgs.QVariant()
		to_data:setValue(player)
		if chenqun:askForSkillInvoke(self:objectName(), to_data) then
			room:broadcastSkillInvoke(self:objectName(), chenqun)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data, chenqun)
		room:drawCards(player, 1, self:objectName())
		return false 
	end,
}

--[[
	反间
	相关武将：标-周瑜
	描述：出牌阶段限一次，若你有手牌，你可以令一名其他角色选择一种花色，然后该角色先获得你的一张手牌再展示之，若此牌的花色与其所选的不同，你对其造成1点伤害。 
	引用：
	状态：
]]

LuaFanjianCard = sgs.CreateSkillCard{
	name = "LuaFanjianCard",
	filter = function(self,selected,to_select,player)
		return #selected == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self,effect)
		local zhouyu = effect.from
		local target = effect.to
		local room = zhouyu:getRoom()
		local card_id = zhouyu:getRandomHandCardId()
		local card = sgs.Sanguosha:getCard(card_id)
		local suit = room:askForSuit(target, "LuaFanjian")
		local log = sgs.LogMessage()
		log.type = "#ChooseSuit"
		log.from = target
		log.arg = sgs.Card_Suit2String(suit)
		room:sendLog(log)

		room:getThread():delay()
		target:obtainCard(card)
		room:showCard(target, card_id)

		if card:getSuit() ~= suit then
			room:damage(sgs.DamageStruct("LuaFanjian", zhouyu, target))
		end
	end,
}

LuaFanjian = sgs.CreateZeroCardViewAsSkill{
	name = "LuaFanjian",

	enabled_at_play = function(self,player)
		return not player:isKongcheng() and not player:hasUsed("#LuaFanjianCard")
	end,
	view_as = function(self)
		local fj = LuaFanjianCard:clone()
		fj:setShowSkill(self:objectName())
        return fj
	end,
}

--[[
	反馈
	相关武将：标-司马懿
	描述：每当你受到伤害后，你可以获得来源的一张牌。 
	引用：
	状态：
]]

LuaFankui = sgs.CreateTriggerSkill{
	name = "LuaFankui",
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local damage = data:toDamage()
		if damage.from and not damage.from:isNude() then
			return self:objectName()
		end
	end,
	
	on_cost = function(self, event, room, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local d = sgs.QVariant()
		d:setValue(damage.from)
        if player:askForSkillInvoke(self:objectName(), d) then
            room:broadcastSkillInvoke(self:objectName(), player)
            room:doAnimate(1, player:objectName(), damage.from:objectName())
			room:notifySkillInvoked(player, self:objectName())
            return true
        end
    end,
		
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local card_id = room:askForCardChosen(player, damage.from, "he", self:objectName())
        room:obtainCard(player, sgs.Sanguosha:getCard(card_id), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName(), self:objectName(), ""), false)
	end
}

--[[
	反馈
	相关武将：身份-司马懿·界限突破
	描述：每当你受到1点伤害后，你可以获得来源的一张牌。 
	引用：
	状态：1.2.0 验证通过
]]

LuaFankuiJx = sgs.CreateTriggerSkill{
	name = "LuaFankuiJx",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.Damaged,
	
	can_trigger = function(self, event, room, player, data)
		local trigger_list = {}
		if player and player:isAlive() and player:hasSkill(self:objectName()) then	
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and not damage.from:isNude() then
				for i = 1, damage.damage do
					table.insert(trigger_list, self:objectName())
				end
			end
		end
		return table.concat(trigger_list, ",")
	end,

	on_cost = function(self, event, room, player, data, simayi)
		if player:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data, simayi)
		local card_id = room:askForCardChosen(simayi, data:toDamage().from, "he", self:objectName())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, simayi:objectName())
		room:obtainCard(simayi, sgs.Sanguosha:getCard(card_id), reason, false)
		return false 
	end,
}

--[[
	放权
	相关武将：标-刘禅
	描述：你可以跳过出牌阶段，若如此做，此回合结束时，你可以弃置一张手牌并选择一名其他角色，若如此做，该角色获得一个额外的回合。 
	引用：
	状态：
]]

LuaFangquanCard = sgs.CreateSkillCard{
	name = "LuaFangquanCard",

	filter = function(self, selected, to_select, Self)
		return #selected == 0 and to_select:objectName() ~= Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local player = effect.to
		
		local log = sgs.LogMessage()
		log.type = "#Fangquan"
		log.to:append(player)
		room:sendLog(log)

		player:gainAnExtraTurn()
	end,
}

LuaFangquanVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaFangquan",
	filter_pattern = ".|.|.|hand!",
	response_pattern = "@@LuaFangquan",

	view_as = function(self, card)
		local fangquan = LuaFangquanCard:clone()
        fangquan:addSubcard(card)
        fangquan:setShowSkill(self:objectName())
        return fangquan
	end,
}

LuaFangquan = sgs.CreateTriggerSkill{
	name = "LuaFangquan",
	events = {sgs.EventPhaseChanging},
	view_as_skill = LuaFangquanVS,
	can_preshow = true,

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
			return self:objectName()
		elseif change.to == sgs.Player_NotActive and player:hasFlag(self:objectName()) and player:canDiscard(player, "h") then
            return self:objectName()
		end
	end,

	on_cost = function(self, event, room, player, data)
        local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			if player:askForSkillInvoke(self:objectName()) then
				player:skip(sgs.Player_Play)
				room:broadcastSkillInvoke(self:objectName(), 1, player)
                return true
			end
		else
            room:askForUseCard(player, "@@LuaFangquan", "@fangquan-discard", -1, sgs.Card_MethodDiscard)
		end
	end,

	on_effect = function(self, event, room, player, data)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Play then
            player:setFlags(self:objectName())
		end
	end,
}

--[[
	放逐
	相关武将：标-曹丕
	描述：每当你受到伤害后，你可以令一名其他角色摸X张牌（X为你已损失的体力值），然后其叠置。 
	引用：
	状态：
]]

luaFangzhu = sgs.CreateTriggerSkill{
	name = "luaFangzhu",
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		return self:objectName()
	end,
	on_cost = function(self, event, room, player, data)
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),"fangzhu-invoke",true,true)
		if target then
			if target:faceUp() then room:broadcastSkillInvoke(self:objectName(), 1, player)
			else room:broadcastSkillInvoke(self:objectName(), 2, player) end
			room:notifySkillInvoked(player, self:objectName())
			local d = sgs.QVariant()
			d:setValue(target)
			player:setTag("fangzhu-invoke", d)
			return true
		end
	end,
	
	on_effect = function(self, event, room, player, data)
		local target = player:getTag("fangzhu-invoke"):toPlayer()
		if target then
			if player:isWounded() then
				local count = player:getLostHp()
				room:drawCards(target, count, self:objectName())
			end
			target:turnOver()
		end
	end,
}

--[[
	奋命
	相关武将：势-陈武&董袭
	描述：结束阶段开始时，若你处于连环状态，你可以弃置处于连环状态的每名角色的一张牌。 
	引用：
	状态：
]]

--[[
	奋迅
	相关武将：标-丁奉
	描述：出牌阶段限一次，你可以弃置一张牌并选择一名其他角色，令你与该角色的距离视为1，直到回合结束。 
	引用：
	状态：
]]


LuaFenxunCard = sgs.CreateSkillCard{
	name = "LuaFenxunCard",

	filter = function(self,targets,to_select,Self)
		return #targets == 0 and to_select:objectName() ~= Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local d = sgs.QVariant()
		d:setValue(effect.to)
		effect.from:setTag("FenxunTarget",d)
		room:setFixedDistance(effect.from, effect.to, 1)
	end,
}

LuaFenxunVS = sgs.CreateOneCardViewAsSkill{
	name = "LuaFenxun",
	filter_pattern = ".!",
	enabled_at_play = function(self,player)
		return player:canDiscard(player, "he") and not player:hasUsed("#LuaFenxunCard")
	end,
	view_as = function(self,card)
		local first = LuaFenxunCard:clone()
		first:addSubcard(card)
		first:setSkillName(self:objectName())
        first:setShowSkill(self:objectName())
		return first
	end,
}

LuaFenxun = sgs.CreateTriggerSkill{
	name = "LuaFenxun",
	events = {sgs.EventPhaseChanging,sgs.Death},
	view_as_skill = LuaFenxunVS,
	can_trigger = function(self,event,room,dingfeng,data)
		if not dingfeng or not dingfeng:getTag("FenxunTarget"):toPlayer() then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
		else
			local death = data:toDying()
			if death.who:objectName() ~= dingfeng:objectName() then return false end
		end
		local target = dingfeng:getTag("FenxunTarget"):toPlayer()
		room:setFixedDistance(dingfeng, target, -1)
		dingfeng:removeTag("FenxunTarget")
	end,
}

--[[
	锋矢
	相关武将：势-张任
	描述：阵法技，在你为围攻角色的围攻关系中，每当围攻角色使用【杀】指定被围攻角色为目标后，该围攻角色令被围攻角色弃置装备区里的一张牌。 
	引用：
	状态：
]]
