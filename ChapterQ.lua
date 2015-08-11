--[[
	国战技能速查手册（Q区）
	技能索引：
	奇才、奇策、戚乱、奇袭、千幻、潜袭、谦逊、强袭、琴音、倾城、倾国、青囊、巧变、驱虎    
]]--
--[[
	奇才
	相关武将：标-黄月英
	描述：锁定技，你使用锦囊牌无距离限制。
	引用：
	状态：
]]

LuaQicai = sgs.CreateTargetModSkill{
	name = "LuaQicai",
	pattern = "TrickCard",
	distance_limit_func = function(self, from, card)
		if not sgs.Sanguosha:matchExpPattern("TrickCard", from, card) then return 0 end
		if from:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end,
}

--[[
	奇策
	相关武将：身份-荀攸
	描述：出牌阶段限一次，你可将所有手牌（至少一张）当做任意一张非延迟锦囊牌使用。
	适用：2.0以后版本（每夜版20150812及以后）
]]

LuaQice = sgs.CreateZeroCardViewAsSkill{   
	name = "LuaQice",
	guhuo_type = "t",
	
	view_as = function(self)
		local card = sgs.Sanguosha:cloneCard(sgs.Self:getTag(self:objectName()):toString(), sgs.Card_SuitToBeDecided, -1)
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		card:setShowSkill(self:objectName())
		card:setCanRecast(false)
		return card
	end,

	enabled_at_play = function(self, player)
		return not player:isKongcheng() and player:usedTimes("ViewAsSkill_LuaQiceCard") == 0
	end,
}

--[[
	戚乱
	相关武将：阵-何太后
	描述：一名角色的回合结束后，若你于此回合内杀死过角色，你可以摸三张牌。  
	引用：
	状态：
]]
--[[
	奇袭
	相关武将：标-甘宁
	描述：你可以将一张黑色牌当【过河拆桥】使用。  
	引用：
	状态：
]]

LuaQixi = sgs.CreateOneCardViewAsSkill{
	name = "LuaQixi",
	response_or_use = true,

	view_filter = function(self, to_select)
		return to_select:isBlack()
	end,
	view_as = function(self,card)
		local dismantlement = sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber())
		dismantlement:addSubcard(card:getId())
		dismantlement:setSkillName(self:objectName())
		dismantlement:setShowSkill(self:objectName())
        return dismantlement
	end,
}

--[[
	千幻
	相关武将：阵-于吉
	描述：每当与你势力相同的一名角色受到伤害后，若该角色存活，你可以将牌堆顶的一张牌置于武将牌上，称为“幻”，若此“幻”与另一张“幻”花色相同，你将此“幻”置入弃牌堆；每当与你势力相同的一名角色成为基本牌或锦囊牌唯一的目标时，你可以将一张“幻”置入弃牌堆，取消之。 
	引用：
	状态：
]]
--[[
	潜袭
	相关武将：势-马岱
	描述：准备阶段开始时，你可以进行判定，然后令一名距离为1的角色不能使用或打出与结果颜色相同的手牌，直到回合结束。 
	引用：
	状态：
]]
--[[
	谦逊
	相关武将：标-陆逊
	描述：锁定技，每当你成为【顺手牵羊】或【乐不思蜀】的目标时，你取消之。 
	引用：
	状态：
]]

LuaQianxun = sgs.CreateTriggerSkill{
	name = "LuaQianxun",
	events = {sgs.TargetConfirming},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local use = data:toCardUse()
		if not use.card or use.card:getTypeId() ~= sgs.Card_TypeTrick or (not use.card:isKindOf("Snatch") and not use.card:isKindOf("Indulgence")) or not use.to:contains(player) then
			return false end
        return self:objectName()
	end,

	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,

	on_effect = function(self, event, room, player, data)
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		local use = data:toCardUse()
		sgs.Room_cancelTarget(use, player)
		data:setValue(use)
        return false
	end,
}

--[[
	强袭
	相关武将：标-典韦
	描述：出牌阶段限一次，你可以失去1点体力或弃置一张武器牌，并选择你攻击范围内的一名其他角色，对该角色造成1点伤害。  
	引用：
	状态：
]]

luaQiangxiCard = sgs.CreateSkillCard{
	name = "luaQiangxiCard", 
	filter = function(self, targets, to_select) 
		if #targets ~= 0 then return false end
		if to_select:objectName() == sgs.Self:objectName() then return false end
		local rangefix = 0
		if (not self:getSubcards():isEmpty()) and sgs.Self:getWeapon() and (sgs.Self:getWeapon():getId() == self:getSubcards():first()) then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - 1
		end
		return sgs.Self:distanceTo(to_select, rangefix) <= sgs.Self:getAttackRange()
	end,

	extra_cost = function(self, room, use)
		if use.card:getSubcards():isEmpty() then room:loseHp(use.from) end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, use.from:objectName(), "", use.card:getSkillName(), "")
		room:moveCardTo(self, use.from, nil, sgs.Player_PlaceTable, reason, true)
	end,

	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:damage(sgs.DamageStruct("luaQiangxi", effect.from, effect.to))
	end,
}

luaQiangxi = sgs.CreateViewAsSkill{
	name = "luaQiangxi",
	view_filter = function(self, selected, to_select)
		if #selected == 0 and not sgs.Self:isJilei(to_select) then
			return to_select:isKindOf("Weapon")
		end
		return false
	end,
	view_as = function(self, cards) 
		if #cards == 0 then
			local card = luaQiangxiCard:clone()
			card:setShowSkill(self:objectName())
			return card
		elseif #cards == 1 then
			local card = luaQiangxiCard:clone()
			card:addSubcard(cards[1])
			card:setShowSkill(self:objectName())
			return card
		else
			return nil
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luaQiangxiCard")
	end,
}

--[[
	琴音
	相关武将：身份-神·周瑜
	描述：弃牌阶段结束时，若你于此阶段内弃置过你的至少两张手牌，你可选择一项：1.令所有角色各回复1点体力；2.令所有角色各失去1点体力。
	引用：
	状态：1.2.1验证通过
]]

LuaQinyin = sgs.CreateTriggerSkill{
	name = "LuaQinyin",
	can_preshow = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging},
	
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().from == sgs.Player_Discard then player:setMark(self:objectName(), 0) end
		elseif event == sgs.CardsMoveOneTime and player:getPhase() == sgs.Player_Discard then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				for i = 0, move.card_ids:length()-1, 1 do
					if move.from_places:at(i) == sgs.Player_PlaceHand then player:addMark(self:objectName()) end
				end
			end	
		end
	end,

	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard and player:getMark(self:objectName()) >= 2 then
				return self:objectName()
			end
		end
		return ""
	end,
	
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self:objectName(), data) then
			return true 
		end
		return false 
	end,
	
	on_effect = function(self, event, room, player, data)
		local choices = {"loseHp"}
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:isWounded() then
				table.insert(choices, "recoverHp")
				break
			end
		end
		local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
		if choice == "recoverHp" then
			room:broadcastSkillInvoke(self:objectName(), 1, player)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(p, recover)
			end
		elseif choice == "loseHp" then
			room:broadcastSkillInvoke(self:objectName(), 2, player)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				room:loseHp(p)
			end
		end
		return false 
	end,
}

--[[
	倾城
	相关武将：标-邹氏
	描述：出牌阶段，你可以弃置一张装备牌并选择一名两张武将牌均明置的其他角色，暗置其一张武将牌。 
	引用：
	状态：
]]

LuaQingchengCard = sgs.CreateSkillCard{
	name = "LuaQingchengCard",
    handling_method = sgs.Card_MethodDiscard,
	filter = function(self, targets, to_select, Self)
		if (to_select:isLord() or to_select:getGeneralName():match("sujiang")) and to_select:getGeneral2() and to_select:getGeneral2Name():match("sujiang") then return false end
		return #targets == 0 and to_select:objectName() ~= Self:objectName() and to_select:hasShownAllGenerals()
	end,
	on_effect = function(self, effect)
		local player,to = effect.from, effect.to
		local room = player:getRoom()
		local choices = {}
		if not to:isLord() and not to:getGeneralName():match("sujiang") then
			table.insert(choices, to:getGeneral():objectName())
		end
		if to:getGeneral2() and not to:getGeneral2Name():match("sujiang") then
			table.insert(choices, to:getGeneral2():objectName())
		end
		if #choices == 0 then return end
		local choice = choices[1]
		if #choices == 2 then
			choice = room:askForGeneral(player, table.concat(choices,"+"), "", true, "LuaQingcheng")
		end
		to:hideGeneral(choice == to:getGeneral():objectName())
	end,
}

LuaQingcheng = sgs.CreateOneCardViewAsSkill{
	name = "LuaQingcheng",
	filter_pattern = "EquipCard!",

	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he")
	end,
	view_as = function(self, ocard)
		local card = LuaQingchengCard:clone()
		card:addSubcard(ocard)
		card:setShowSkill(self:objectName())
		return card
	end,
}

--[[
	倾国
	相关武将：标-甄姬
	描述：你可以将一张黑色手牌当【闪】使用或打出。 
	引用：
	状态：
]]

luaQingguo = sgs.CreateOneCardViewAsSkill{
	name = "luaQingguo", 
	response_pattern = "jink",
	filter_pattern = ".|black|.|hand",
	view_as = function(self, card) 
		local jink = sgs.Sanguosha:cloneCard("jink",card:getSuit(),card:getNumber())
		jink:setSkillName(self:objectName())
		jink:setShowSkill(self:objectName())
		jink:addSubcard(card:getId())
		return jink
	end, 
}

--[[
	青囊
	相关武将：标-华佗
	描述：出牌阶段限一次，你可以弃置一张手牌并选择已受伤的一名角色，令其回复1点体力。
	引用：
	状态：
]]


LuaQingnangCard = sgs.CreateSkillCard{
	name = "LuaQingnangCard",
	filter = function(self,targets,to_select)
		return #targets == 0 and to_select:isWounded()
	end,
	on_effect = function(self,effect)
		local recover = sgs.RecoverStruct()
		recover.card = self
		recover.who = effect.from
		effect.to:getRoom():recover(effect.to, recover)
	end,
}

LuaQingnang = sgs.CreateOneCardViewAsSkill{
	name = "LuaQingnang",
	filter_pattern = ".|.|.|hand!",

	enabled_at_play = function(self,player)
		return player:canDiscard(player, "h") and not player:hasUsed("#LuaQingnang")
	end,
	view_as = function(self, ocard)
		local qingnang_card = LuaQingnangCard:clone()
		qingnang_card:addSubcard(ocard:getId())
		qingnang_card:setShowSkill(self:objectName())
		return qingnang_card
	end,
}

--[[
	巧变
	相关武将：标-张郃
	描述：你可以弃置一张手牌，跳过一个阶段（准备阶段和结束阶段除外）。若以此法跳过摸牌阶段，你可以选择有手牌的一至两名其他角色，然后获得这些角色的各一张手牌；若以此法跳过出牌阶段，你可以将一名角色判定区/装备区里的一张牌置入另一名角色的判定区/装备区。  
	引用：
	状态：
]]

luaQiaobianCard = sgs.CreateSkillCard{
	name = "luaQiaobianCard",
	--target_fixed = false,
	--will_throw = false,
	filter = function(self, targets, to_select)
		local phase = sgs.Self:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			if to_select:objectName() ~= sgs.Self:objectName() then
				if not to_select:isKongcheng() then
					return #targets < 2
				end
			end
		elseif phase == sgs.Player_Play then
			if #targets == 0 then
				if to_select:getJudgingArea():length() > 0 then
					return true
				end
				return to_select:getEquips():length() > 0
			end
		end
		return false
	end,
	
	feasible = function(self, targets)
		local phase = sgs.Self:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			if #targets > 0 then
				return #targets <= 2
			end
		elseif phase == sgs.Player_Play then
			return #targets == 1
		end
		return false
	end,
	
	on_use = function(self, room, source, targets)
		local phase = source:getMark("qiaobianPhase")
		if phase == sgs.Player_Draw then
			if #targets == 0 then return end			
			local moves = sgs.CardsMoveList()
			local move1 = sgs.CardsMoveStruct()
			move1.card_ids:append(room:askForCardChosen(source, targets[1], "h", "luaQiaobian"))
			move1.to = source
			move1.to_place = sgs.Player_PlaceHand
			moves:append(move1)
			if #targets == 2 then
				local move2 = sgs.CardsMoveStruct()
				move2.card_ids:append(room:askForCardChosen(source, targets[2], "h", "luaQiaobian"))
				move2.to = source
				move2.to_place = sgs.Player_PlaceHand
				moves:append(move2)
			end
			room:moveCardsAtomic(moves, false)
					
		elseif phase == sgs.Player_Play then		
			if #targets == 0 then return end	

			local from = targets[1]
			if from:getCards("ej"):isEmpty() then return end

			local card_id = room:askForCardChosen(source, from, "ej", "luaQiaobian")
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)

			local equip_index = -1
			if place == sgs.Player_PlaceEquip then
				local equip = card:getRealCard():toEquipCard()
				equip_index = equip:location()
			end
			local tos = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if equip_index ~= -1 then
					if not p:getEquip(equip_index) then
						tos:append(p)
					end
				else
					if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
						tos:append(p)
					end
				end
			end
			
			local tag = sgs.QVariant()
			tag:setValue(from)
			room:setTag("QiaobianTarget", tag)
			local to = room:askForPlayerChosen(source, tos, "luaQiaobian", "@qiaobian-to:::" .. card:objectName())
			if to then
				room:doAnimate(1, from:objectName(), to:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), "luaQiaobian", "")
				room:moveCardTo(card, from, to, place, reason)

				if place == sgs.Player_PlaceDelayedTrick then
					local use = sgs.CardUseStruct()
					use.card = card
					use.from = nil
					use.to:append(to)
					local _data = sgs.QVariant()
					_data:setValue(use)
					room:getThread():trigger(sgs.TargetConfirming, room, to, _data)
					local new_use = _data:toCardUse()
					if new_use.to:isEmpty() then card:onNullified(to) end

					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:getThread():trigger(sgs.TargetConfirmed, room, p, _data)
					end
				end
			end
			room:removeTag("QiaobianTarget")
		end
	end,
}

luaQiaobianVS = sgs.CreateZeroCardViewAsSkill{
	name = "luaQiaobian",
	response_pattern = "@@luaQiaobian",
	view_filter = function(self, selected, to_select)
		return false
	end ,
	view_as = function(self, cards)
		return luaQiaobianCard:clone()
	end,
}

luaQiaobian = sgs.CreateTriggerSkill{
	name = "luaQiaobian",
	events = {sgs.EventPhaseChanging},
	view_as_skill = luaQiaobianVS,
	can_preshow = true,
	
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local change = data:toPhaseChange()
		local nextphase = change.to
		room:setPlayerMark(player, "qiaobianPhase", nextphase)
		local index = 0
		if nextphase == sgs.Player_Judge then
			index = 1
		elseif nextphase == sgs.Player_Draw then
			index = 2
		elseif nextphase == sgs.Player_Play then
			index = 3
		elseif nextphase == sgs.Player_Discard then
			index = 4
		end
		if index > 0 and player:canDiscard(player, "h") then return self:objectName() end
	end,
	
	on_cost = function(self, event, room, player, data)
		local change = data:toPhaseChange()
			local nextphase = change.to
            local index = 0
            if nextphase == sgs.Player_Judge then
                index = 1
            elseif nextphase == sgs.Player_Draw then
                index = 2
            elseif nextphase == sgs.Player_Play then
                index = 3
            elseif nextphase == sgs.Player_Discard then
                index = 4
            end
            local discard_prompt = string.format("#qiaobian-%d", index)

        if room:askForDiscard(player, self:objectName(), 1, 1, true, false, discard_prompt, true) then
            room:broadcastSkillInvoke(self:objectName())
			room:notifySkillInvoked(player, self:objectName())
            if not player:isAlive() then return false end
            if not player:isSkipped(change.to) then return true end
		end
	end,
	
	on_effect = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		player:skip(change.to)
		local nextphase = change.to
		local index = 0
		if nextphase == sgs.Player_Judge then
			index = 1
		elseif nextphase == sgs.Player_Draw then
			index = 2
		elseif nextphase == sgs.Player_Play then
			index = 3
		elseif nextphase == sgs.Player_Discard then
			index = 4
		end
		if index == 2 or index == 3 then
            local use_prompt = string.format("@qiaobian-%d", index)
            room:askForUseCard(player, "@@luaQiaobian", use_prompt, index)
		end
        return false
    end,
}

--[[
	驱虎
	相关武将：标-荀彧
	描述：出牌阶段限一次，你可以与一名体力值大于你的角色拼点。若你赢，该角色对其攻击范围内你选择的另一名角色造成1点伤害。若你没赢，该角色对你造成1点伤害。 
	引用：
	状态：
]]


luaQuhuCard = sgs.CreateSkillCard{
	name = "luaQuhuCard",
	filter = function(self, targets, to_select)
		return (#targets == 0) and (to_select:getHp() > sgs.Self:getHp()) and (not to_select:isKongcheng())
	end,
	extra_cost = function(self, room, use)
		local pd = sgs.PindianStruct()
		pd = use.from:pindianSelect(use.to:first(), "luaQuhu")
		local d = sgs.QVariant()
		d:setValue(pd)
		use.from:setTag("luaquhu_pd", d)
	end,
	on_effect = function(self, effect)
		local pd = effect.from:getTag("luaquhu_pd"):toPindian()
		effect.from:removeTag("luaquhu_pd")
		if pd then
			local success = effect.from:pindian(pd)
			pd = nil
			local room = effect.to:getRoom()
			if success then
				local wolves = sgs.SPlayerList()
				for _, player in sgs.qlist(room:getOtherPlayers(effect.to)) do
					if effect.to:inMyAttackRange(player) then
						wolves:append(player)
					end
				end
				if wolves:isEmpty() then
					local log = sgs.LogMessage()
					log.type = "#QuhuNoWolf"
					log.from = effect.from
					log.to:append(effect.to)
					room:sendLog(log)
					return
				end
				local wolf = room:askForPlayerChosen(effect.from, wolves, "luaQuhu", "@quhu-damage:" .. effect.to:objectName())
				room:damage(sgs.DamageStruct("luaQuhu", effect.to, wolf))
			else
				room:damage(sgs.DamageStruct("luaQuhu", effect.to, effect.from))
			end
		end
	end
}

luaQuhu = sgs.CreateZeroCardViewAsSkill{
	name = "luaQuhu",
	view_as = function(self, cards)
		local card = luaQuhuCard:clone()
		card:setShowSkill(self:objectName())
		return card
	end, 
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#luaQuhuCard")) and not player:isKongcheng()
	end, 
}
