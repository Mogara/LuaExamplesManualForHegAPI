--[[
	国战技能速查手册（F区）
	技能索引：
	反间、反馈、放权、放逐、奋命、奋迅、锋矢
]]--

--[[
	反间
	相关武将：标-周瑜
	描述：出牌阶段限一次，若你有手牌，你可以令一名其他角色选择一种花色，然后该角色先获得你的一张手牌再展示之，若此牌的花色与其所选的不同，你对其造成1点伤害。 
	引用：
	状态：
]]

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
	放权
	相关武将：标-刘禅
	描述：你可以跳过出牌阶段，若如此做，此回合结束时，你可以弃置一张手牌并选择一名其他角色，若如此做，该角色获得一个额外的回合。 
	引用：
	状态：
]]

--[[
	放逐
	相关武将：标-曹丕
	描述：每当你受到伤害后，你可以令一名其他角色摸X张牌（X为你已损失的体力值），然后其叠置。 
	引用：
	状态：
]]

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

--[[
	锋矢
	相关武将：势-张任
	描述：阵法技，在你为围攻角色的围攻关系中，每当围攻角色使用【杀】指定被围攻角色为目标后，该围攻角色令被围攻角色弃置装备区里的一张牌。 
	引用：
	状态：
]]
