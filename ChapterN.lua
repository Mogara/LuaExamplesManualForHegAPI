--[[
	国战技能速查手册（N区）
	技能索引：
	鸟翔、涅槃 
]]--
--[[
	鸟翔
	相关武将：阵-蒋钦
	描述：阵法技，在你为围攻角色的围攻关系中，每当围攻角色使用【杀】指定被围攻角色为目标后，该被围攻角色需依次使用两张【闪】才能抵消此【杀】     
	引用：
	状态：
]]

LuaNiaoxiang = sgs.CreateTriggerSkill{
	name = "LuaNiaoxiang",
	is_battle_array = true,
	battle_array_type = sgs.Siege,
	view_as_skill = LuaNiaoxiangVS,
	events = {sgs.TargetChosen},
	can_preshow = false,

	can_trigger = function(self,event,room,player,data)
		local use = data:toCardUse()
		local skill_owners = room:findPlayersBySkillName(self:objectName())
		for _, skill_owner in sgs.qlist(skill_owners) do
			if skill_owner:isAlive() and skill_owner:hasShownSkill(self:objectName()) and use.card and use.card:isKindOf("Slash") then
				local targets = {}
				local target
				for _, to in sgs.qlist(use.to) do
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:objectName() == to:objectName() then
							target = p
							break
						end
					end
					if player:inSiegeRelation(skill_owner, target) then
						table.insert(targets, target:objectName())
					end
				end
				if #targets > 0 then return self:objectName() .. "->" .. table.concat(targets, "+") end
			end
		end
		
	end,
	on_cost = function(self,event,room,target,data,ask_who)
		if ask_who:hasShownSkill(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
	end,
	on_effect = function(self,event,room,target,data,ask_who)
		room:sendCompulsoryTriggerLog(ask_who, self:objectName(), true)
		local use = data:toCardUse()
		local x = use.to:indexOf(target)
		local jink_list = ask_who:getTag("Jink_" .. use.card:toString()):toList()
		if jink_list:at(x):toInt() == 1 then
			jink_list:replace(x ,sgs.QVariant(2))
		end
		ask_who:setTag("Jink_" .. use.card:toString(), sgs.QVariant(jink_list))
	end,
}

--[[
	涅槃
	相关武将：标-庞统
	描述：限定技，当你处于濒死状态时，你可以弃置你区域里的所有牌，然后将武将牌平置并重置副将的武将牌，摸三张牌，将体力值回复至3点。     
	引用：
	状态：
]]

LuaNiepan = sgs.CreateTriggerSkill{
	name = "LuaNiepan",
	events = {sgs.AskForPeaches},
	frequency = sgs.Skill_Limited,
	limit_mark = "@nirvana",

   can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
        if player:getMark("@nirvana") > 0 then
			local dying_data = data:toDying()
			if player:getHp() > 0 then return false end
			if dying_data.who:objectName() ~= player:objectName() then return false end
			return self:objectName()
		end
	end,

    on_cost = function(self, event, room, pangtong, data)
		if pangtong:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), pangtong)
			room:doSuperLightbox("pangtong", self:objectName())
			return true
		end
	end,
    on_effect = function(self, event, room, pangtong, data)
		room:removePlayerMark(pangtong, "@nirvana")
		pangtong:throwAllHandCardsAndEquips()
		local tricks = pangtong:getJudgingArea()
		for _, trick in sgs.qlist(tricks) do
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, pangtong:objectName())
            room:throwCard(trick, reason, nil)
		end

		local recover = sgs.RecoverStruct()
        recover.recover = math.min(3, pangtong:getMaxHp()) - pangtong:getHp()
		room:recover(pangtong, recover)

		pangtong:drawCards(3)

		if pangtong:isChained() then
			room:setPlayerProperty(pangtong, "chained", false)
		end
        if not pangtong:faceUp() then
			pangtong:turnOver()
		end
	end,
}
