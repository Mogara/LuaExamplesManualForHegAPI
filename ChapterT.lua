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
--[[
	天义
	相关武将：标-太史慈
	描述：出牌阶段限一次，你可以与一名角色拼点。若你赢，你能额外使用一张【杀】且使用【杀】无距离限制且使用【杀】选择目标的个数上限+1，直到回合结束。若你没赢，你不能使用【杀】，直到回合结束。 
	引用：
	状态：
]]
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
