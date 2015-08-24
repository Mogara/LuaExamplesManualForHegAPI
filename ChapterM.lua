--[[
	国战技能速查手册（M区）
	技能索引：
	马术、猛进、秘计、名士
]]--
--[[
	马术
	相关武将：标-马超、标-庞德、标-马腾、势-马岱
	描述：锁定技，你与其他角色的距离-1。     
	引用：
	状态：
]]

LuaMashu = sgs.CreateDistanceSkill{
	name = "LuaMashu",
	correct_func = function(self, from, to)
		if from:hasSkill("LuaMashu") and from:hasShownSkill(self:objectName()) then
			return -1
		end
	end,
}

--[[
	猛进
	相关武将：标-庞德
	描述：每当你使用的【杀】被目标角色使用的【闪】抵消时，你可以弃置其一张牌。    
	引用：
	状态：
]]

LuaMengjin = sgs.CreateTriggerSkill{
	name = "LuaMengjin",
	events = {sgs.SlashMissed},
	frequency = sgs.Skill_Frequent,

    can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local effect = data:toSlashEffect()
		if effect.to:isAlive() and player:canDiscard(effect.to, "he") then
			return self:objectName()
		end
	end,

	on_cost = function(self,event,room,pangde,data)
		local effect = data:toSlashEffect()
		if pangde:askForSkillInvoke(self:objectName(), data) then
			room:doAnimate(1, pangde:objectName(), effect.to:objectName())
			room:broadcastSkillInvoke(self:objectName(), pangde)
            return true
		end
	end,
	
    on_effect = function(self,event,room,pangde,data)
        local effect = data:toSlashEffect()
		local to_throw = room:askForCardChosen(pangde, effect.to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
		room:throwCard(sgs.Sanguosha:getCard(to_throw), effect.to, pangde)
	end,
}

--[[
	秘计
	相关武将：身份-王异
	描述：结束阶段开始时，若你已受伤，你可以摸一至X张牌（X为你已损失的体力值），然后你可以将等量的手牌交给其他角色。     
	引用：
	状态：2.0 验证通过
	相关翻译 {
		["@LuaMiji"] = "秘计：你可将%arg张手牌分配给其他角色",
		["@LuaMiji2"] = "秘计：你须将%arg张手牌分配给其他角色",
		["~LuaMiji"] = "选择手牌→其他角色",
	}
]]

LuaMijiCard = sgs.CreateSkillCard{
	name = "LuaMijiCard",
	skill_name = "LuaMiji",
	target_fixed = false,
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodNone,

	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	
	feasible = function(self, targets, player)
		return #targets == 1
	end,

	about_to_use = function(self, room, cardUse)
		local source, target = cardUse.from, cardUse.to:at(0)
		room:removePlayerMark(source, self:getSkillName().."_num", self:subcardsLength())
		local data = sgs.QVariant()
		data:setValue(target)
		source:setTag(self:getSkillName().."_target", data)
	end,

}

LuaMijiVS = sgs.CreateViewAsSkill{   
	name = "LuaMiji",
	
	view_filter = function(self, selected, to_select)
		return sgs.Self:getMark(self:objectName().."_num") > #selected and table.contains(sgs.Self:property(self:objectName().."_hands"):toString():split("+"), tostring(to_select:getId()))
	end, 

	view_as = function(self, originalCards) 
		if #originalCards > 0 then
			local skillcard = LuaMijiCard:clone()
			for _, card in ipairs(originalCards) do
				skillcard:addSubcard(card)
			end
			skillcard:setSkillName(self:objectName())
			skillcard:setShowSkill(self:objectName())
			return skillcard
		end
	end, 

	enabled_at_play = function(self, player)
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@"..self:objectName())
	end,
}

LuaMiji = sgs.CreateTriggerSkill{
	name = "LuaMiji",
	can_preshow = true,
	events = sgs.EventPhaseStart,
	view_as_skill = LuaMijiVS,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if player:getPhase() == sgs.Player_Finish and player:isWounded() then
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
		local n = 1
		if player:getLostHp() > 1 then
			local nums = "1"
			for i = 2, player:getLostHp() do
				nums = math.floor(i/5) == i/5 and nums.."|"..i or nums.."+"..i
			end
			n = tonumber(room:askForChoice(player, self:objectName(), nums))
		end
		room:setPlayerMark(player, self:objectName().."_num", n)
		player:drawCards(n)
		local ids, get = sgs.QList2Table(player:handCards()), {}

		local pattern, prompt = "@@"..self:objectName(), "@"..self:objectName()..":::"
		while #ids > 0 and player:getMark(self:objectName().."_num") > 0 do
			room:setPlayerProperty(player, self:objectName().."_hands", sgs.QVariant(table.concat(ids, "+")))
			local u_card = room:askForUseCard(player, pattern, prompt..player:getMark(self:objectName().."_num") )
			if not u_card then
				break
			end
			local target = player:getTag(self:objectName().."_target"):toPlayer()

			for _, id in sgs.qlist(u_card:getSubcards()) do
				table.removeOne(ids, id)
				table.insert(get, target:objectName().."|"..id)
			end
			pattern = "@@"..self:objectName().."!"
			prompt = "@"..self:objectName().."2:::"
		end

		local moves = sgs.CardsMoveList()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), self:objectName(), "")
		for _, p in sgs.qlist(room:getAllPlayers()) do
			local _ids = sgs.IntList()
			for _, toget in ipairs(get) do
				if toget:split("|")[1] == p:objectName() then _ids:append(tonumber(toget:split("|")[2])) end
			end
			if not _ids:isEmpty() then
				local move = sgs.CardsMoveStruct(_ids, player, p, sgs.Player_PlaceHand, sgs.Player_PlaceHand, reason)
				moves:append(move)
			end
		end
		player:setMark(self:objectName().."_num", 0)
		if not moves:isEmpty() then room:moveCardsAtomic(moves, false) end
		
		return false 
	end,
}

--[[
	名士
	相关武将：标-孔融
	描述：锁定技，每当你受到伤害时，若来源有暗置的武将牌，你令此伤害-1。     
	引用：
	状态：
]]

LuaMingshi = sgs.CreateTriggerSkill{
	name = "LuaMingshi",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local damage = data:toDamage()
		if damage.from and not damage.from:hasShownAllGenerals() then
			return self:objectName()
		end
	end,
	on_cost = function(self,event,room,player,data)
		local invoke = player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data)
		if invoke then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,

	on_effect = function(self,event,room,player,data)
		local damage = data:toDamage()
        room:notifySkillInvoked(player, self:objectName())

		local log = sgs.LogMessage()
		log.type = "#Mingshi"
		log.from = player
		log.arg = damage.damage
		damage.damage = damage.damage - 1
		log.arg2 = damage.damage
		room:sendLog(log)

		if damage.damage < 1 then
			return true
		end
        data:setValue(damage)
	end,
}
