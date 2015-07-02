--[[
	国战技能速查手册（X区）
	技能索引：
	享乐、骁果、枭姬、行殇、雄异、眩惑、恂恂
]]--
--[[
	享乐
	相关武将：标-刘禅
	描述：锁定技，每当你成为其他角色使用【杀】的目标时，你令该角色选择是否弃置一张基本牌，若其不如此做或其已死亡，此次对你结算的此【杀】对你无效。 
	引用：
	状态：
]]

LuaXiangle = sgs.CreateTriggerSkill{
	name = "LuaXiangle",
	events = {sgs.TargetConfirming},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.to:contains(player) then
			return self:objectName()
		end
	end,

	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName(), data) then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,

	on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
		local d = sgs.QVariant()
		d:setValue(player)
		if not room:askForCard(use.from, ".Basic", "@xiangle-discard:" .. player:objectName(), d) then
			use.nullified_list:append(player:objectName())
			data:setValue(use)
		end
	end,
}

--[[
	骁果
	相关武将：标-乐进
	描述：其他角色的结束阶段开始时，你可以弃置一张基本牌，令该角色选择一项：1.弃置一张装备牌；2.受到你造成的1点伤害。 
	引用：
	状态：
]]

luaXiaoguo = sgs.CreateTriggerSkill{
	name = "luaXiaoguo" ,
	events = {sgs.EventPhaseStart} ,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() then return false end
		if player:getPhase() == sgs.Player_Finish then
			local yuejin = room:findPlayerBySkillName(self:objectName())
			if yuejin and yuejin:objectName() ~= player:objectName() and yuejin:canDiscard(yuejin, "h") then
				yuejin:gainMark("@fog")
				return self:objectName(), yuejin
			end
		end
	end,
	on_cost = function(self, event, room, player, data, yuejin)
		if room:askForCard(yuejin, ".Basic", "@xiaoguo", sgs.QVariant(), self:objectName()) then
			room:doAnimate(1, yuejin:objectName(), player:objectName())
			room:broadcastSkillInvoke(self:objectName(), 1, yuejin)
			room:notifySkillInvoked(yuejin, self:objectName())
			return true
		end
	end,

	on_effect = function(self, event, room, player, data, yuejin)
		if not room:askForCard(player, ".Equip", "@xiaoguo-discard", sgs.QVariant()) then
			room:broadcastSkillInvoke(self:objectName(), 2, yuejin)
			room:damage(sgs.DamageStruct(self:objectName(), yuejin, player))
		else
			room:broadcastSkillInvoke(self:objectName(), 3, yuejin)
		end
		return false
	end,
}

--[[
	枭姬
	相关武将：标-孙尚香
	描述：每当你失去装备区里的装备牌后，你可以摸两张牌。 
	引用：
	状态：
]]


--枭姬
LuaXiaoji = sgs.CreateTriggerSkill{
	name = "LuaXiaoji",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self,event,room,sunshangxiang,data)
		if not sunshangxiang or sunshangxiang:isDead() or not sunshangxiang:hasSkill(self:objectName()) then return false end
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == sunshangxiang:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			return self:objectName()
		end
	end,
	
	on_cost = function(self,event,room,sunshangxiang,data)
		if sunshangxiang:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), sunshangxiang)
			return true
		end
	end,
	on_effect = function(self,event,room,sunshangxiang,data)
        sunshangxiang:drawCards(2)
	end,
}

--[[
	行殇
	相关武将：标-曹丕
	描述：每当其他角色死亡时，你可以获得其所有牌。 
	引用：
	状态：
]]


luaXingshang = sgs.CreateTriggerSkill{
	name = "luaXingshang",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Death},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() or player:isNude() then return false end
		return self:objectName()
	end,
	on_cost = function(self, event, room, player, data)
		return room:askForSkillInvoke(player, self:objectName(), data)
	end,
	
	on_effect = function(self, event, room, player, data)
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() or player:isNude() then return false end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcards(death.who:getCards("he"))
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
		room:obtainCard(player, dummy, reason, false)
		return false
	end,
}

--[[
	雄异
	相关武将：标-马腾
	描述：限定技，出牌阶段，你可以令与你势力相同的所有角色各摸三张牌，然后若你的势力是角色最少的势力，你回复1点体力。 
	引用：
	状态：
]]

LuaXiongyiCard = sgs.CreateSkillCard{
	name = "LuaXiongyiCard",
	mute = true,
	target_fixed = true,

	about_to_use = function(self,room,use)
		room:setPlayerMark(use.from, "@arise", 0)
		room:broadcastSkillInvoke("LuaXiongyi", use.from)
		room:doSuperLightbox("mateng", "LuaXiongyi")
		self:cardOnUse(room, use)
	end,
	on_use = function(self,room,source)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:isFriendWith(source) then
				room:doAnimate(1, source:objectName(), p:objectName())
				targets:append(p)
			end
		end
		room:sortByActionOrder(targets)
		for _, player in sgs.qlist(targets) do
			room:cardEffect(self, source, player)
		end

		local kingdom_list = sgs.Sanguosha:getKingdoms()
		table.insert(kingdom_list, "careerist")
		local invoke = true
		local n = source:getPlayerNumWithSameKingdom("xiongyi", nil, 0)
		for _, kingdom in ipairs(kingdom_list) do
			if kingdom == "god" then continue end
			if source:getRole() == "careerist" then
				if kingdom == "careerist" then continue end
			elseif source:getKingdom() == kingdom then
				continue
			end
			local other_num = source:getPlayerNumWithSameKingdom("LuaXiongyi", kingdom, 0)
			if other_num > 0 and other_num < n then
				invoke = false
				break
			end
		end
		if invoke and source:isWounded() then
			local recover = sgs.RecoverStruct()
			recover.who = source
			room:recover(source, recover)
		end
	end,

	on_effect = function(self, effect)
		effect.to:drawCards(3)
	end,
}


LuaXiongyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaXiongyi",
	enabled_at_play = function(self, player)
		return player:getMark("@arise") >= 1
	end,
	view_as = function(self)
		local card = LuaXiongyiCard:clone()
        card:setShowSkill(self:objectName())
		return card
	end,
}

LuaXiongyi = sgs.CreateTriggerSkill{
	name = "LuaXiongyi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@arise",
	view_as_skill = LuaXiongyiVS,
}

--[[
	眩惑
	相关武将：身份-法正
	描述：摸牌阶段，你可以放弃摸牌，改为令一名其他角色摸两张牌，然后该角色需对其攻击范围内，由你指定的另一名角色使用一张【杀】，否则你获得其两张牌。 
	引用：
	状态：1.2.0 验证通过
]]

luaxuanhuo = sgs.CreateTriggerSkill{
	name = "luaxuanhuo",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = sgs.EventPhaseStart,
	
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Draw then
			if true then return self:objectName() end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), self:objectName().."-invoke", true, true)
		if target then
			local target_data = sgs.QVariant()
			target_data:setValue(target)
			player:setTag(self:objectName(), target_data)
			room:broadcastSkillInvoke(self:objectName(), 1, player)
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local target = player:getTag(self:objectName()):toPlayer()
		player:removeTag(self:objectName())
		target:drawCards(2, self:objectName())

		if player:isAlive() and target:isAlive() then
			local victims, victim = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(target)) do
				if target:canSlash(p) then victims:append(p) end
			end
			if not victims:isEmpty() then
				victim = room:askForPlayerChosen(player, victims, self:objectName().."_slash", "@"..self:objectName().."-slash2:"..target:objectName())
				local log = sgs.LogMessage()
				log.type = "#CollateralSlash";
				log.from = player
				log.to:append(victim)
				room:sendLog(log)
			end

			if not victim or not room:askForUseSlashTo(target, victim, self:objectName().."-slash::"..victim:objectName()) then		
				room:broadcastSkillInvoke(self:objectName(), 2, player)
				if not target:isNude() then
					local dummy = sgs.Sanguosha:cloneCard("jink")

					room:setPlayerFlag(target, "Global_InTempMoving")
					local first_id = room:askForCardChosen(player, target, "he", self:objectName())
					local original_place = room:getCardPlace(first_id)
					dummy:addSubcard(first_id)
					target:addToPile("#"..self:objectName(), dummy, false)
					if not target:isNude() then
						local second_id = room:askForCardChosen(player, target, "he", self:objectName())
						dummy:addSubcard(second_id)
					end
					room:moveCardTo(sgs.Sanguosha:getCard(first_id), target, original_place, false)
					room:setPlayerFlag(target, "-Global_InTempMoving")

					player:obtainCard(dummy, false)
					dummy:deleteLater()
				end
			end
		end
		return true
	end,
}

--[[
	恂恂
	相关武将：势-李典
	描述：摸牌阶段开始时，你可以放弃摸牌，观看牌堆顶的四张牌，然后获得其中的两张牌，将其余的牌以任意顺序置于牌堆底。 
	引用：
	状态：
]]
