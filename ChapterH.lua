--[[
	国战技能速查手册（H区）
	技能索引：
	好施、鹤翼、横江、横征、弘法、红颜、护援、魂殇、火计、祸首、祸水      
]]--
--[[
	好施
	相关武将：标-鲁肃
	描述：摸牌阶段，你可以额外摸两张牌，然后若你的手牌数大于5，你将一半（向下取整）的手牌交给手牌最少的一名其他角色。  
	引用：
	状态：
]]
--[[
	鹤翼
	相关武将：阵-曹洪
	描述：阵法技，与你处于同一队列的其他角色视为拥有“飞影”。  
	引用：
	状态：
]]
--[[
	横江
	相关武将：势-臧霸
	描述：每当你受到1点伤害后，你可以令当前回合角色本回合手牌上限-1，然后其回合结束时，若你于此回合发动过“横江”，且其未于弃牌阶段内弃置牌，你摸一张牌。 
	引用：
	状态：
]]
--[[
	横征
	相关武将：势-董卓
	描述：摸牌阶段开始时，若你的体力值为1或你没有手牌，你可以放弃摸牌，获得每名其他角色区域里的一张牌。  
	引用：
	状态：
]]
--[[
	弘法
	相关武将：势-君张角
	描述：君主技，此武将牌明置时，你获得“黄巾天兵符”。准备阶段开始时，若“黄巾天兵符”上没有牌，则从牌堆顶亮出X张牌置于“黄巾天兵符”上，称为“天兵”（X为全场存活的群势力角色数）。
		★黄巾天兵符★
		你执行的效果中的“群势力角色的数量”+X（X为不大于“天兵”数量的自然数）；每当你失去体力时，你可以防止此失去体力，将一张“天兵”置入弃牌堆；与你势力相同的角色可以将一张“天兵”当【杀】使用或打出。  
	引用：
	状态：
]]
--[[
	红颜
	相关武将：标-小乔
	描述：锁定技，你的♠牌视为♥牌。  
	引用：
	状态：
]]
--[[
	护援
	相关武将：阵-曹洪
	描述：结束阶段开始时，你可以将一张装备牌置入一名角色的装备区，若如此做，你可以弃置该角色距离为1的一名角色的一张牌。 
	引用：
	状态：
]]
--[[
	魂殇
	相关武将：势-孙策
	描述：副将技，此武将牌上单独的阴阳鱼个数-1；副将技，准备阶段开始时，若你的体力值为1，你拥有“英姿”和“英魂”，直到回合结束。  
	引用：
	状态：
]]
--[[
	火计
	相关武将：标-卧龙诸葛亮
	描述：你可以将一张红色手牌当【火攻】使用。 
	引用：
	状态：
]]

LuaHuoji = sgs.CreateOneCardViewAsSkill{
	name = "LuaHuoji",
	filter_pattern = ".|red|.|hand",
	response_or_use = true,
	view_as = function(self, card)
		local suit = card:getSuit()
		local point = card:getNumber()
		local id = card:getId()
		local fireattack = sgs.Sanguosha:cloneCard("FireAttack", suit, point)
		fireattack:setSkillName(self:objectName())
		fireattack:setShowSkill(self:objectName())
		fireattack:addSubcard(id)
		return fireattack
	end
}

--[[
	祸首
	相关武将：标-孟获
	描述：锁定技，【南蛮入侵】对你无效；锁定技，每当其他角色使用【南蛮入侵】指定目标后，你将此【南蛮入侵】造成的伤害的来源改为你。 
	引用：
	状态：
]]

LuaSavageAssaultAvoid = sgs.CreateTriggerSkill{
	name = "#LuaSavageAssaultAvoid",
    events = {sgs.CardEffected},
    frequency = sgs.Skill_Compulsory,

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill("LuaHuoshou") then return false end
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("LuaHuoshou") or player:askForSkillInvoke("LuaHuoshou") then
			room:broadcastSkillInvoke(self:objectName(), 1, player)
			player:showGeneral(player:inHeadSkills(self:objectName()))
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
		room:notifySkillInvoked(player, self:objectName())
		local log = sgs.LogMessage()
		log.type = "#SkillNullify"
		log.from = player
		log.arg = self:objectName()
		log.arg2 = "savage_assault"
		room:sendLog(log)
		return true
	end,
}

LuaHuoshou = sgs.CreateTriggerSkill{
	name = "LuaHuoshou",
	events = {sgs.TargetChosen,sgs.ConfirmDamage,sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self, event, room, player, data)
		if not player then return false end
		if event == sgs.TargetChosen then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				local menghuo = room:findPlayerBySkillName(self:objectName())
				if menghuo and menghuo:isAlive() and use.from:objectName() ~= menghuo:objectName() then
					return self:objectName(),menghuo
				end
			end
		elseif event == sgs.ConfirmDamage and room:getTag("HuoshouSource"):toPlayer() then
			local damage = data:toDamage()
			if not damage.card or not damage.card:isKindOf("SavageAssault") then return false end
			
			local menghuo = room:getTag("HuoshouSource"):toPlayer()
			if menghuo:isAlive() then
				damage.from = menghuo
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				room:removeTag("HuoshouSource")
			end
		end
	end,

	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:hasShownSkill(self) or ask_who:askForSkillInvoke(self) then
			room:broadcastSkillInvoke(self:objectName(), 2, ask_who)
			return true
		end
	end,

	on_effect = function(self, event, room, player, data, ask_who)
        room:sendCompulsoryTriggerLog(ask_who, self:objectName(),true)
		local d = sgs.QVariant()
		d:setValue(ask_who)
        room:setTag("HuoshouSource", d)
	end,
}

--[[
	祸水
	相关武将：标-邹氏
	描述：出牌阶段，你可以明置此武将牌；其他角色于你的回合内不能明置其武将牌。  
	引用：
	状态：
]]
