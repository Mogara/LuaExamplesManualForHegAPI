--[[
	国战技能速查手册（K区）
	技能索引：
	看破、克己、空城、苦肉、狂斧、狂骨    
]]--
--[[
	看破
	相关武将：标-卧龙诸葛亮
	描述：你可以将一张黑色手牌当【无懈可击】使用。    
	引用：
	状态：
]]
--[[
	克己
	相关武将：标-吕蒙
	描述：若你未于出牌阶段内使用或打出【杀】，你可以跳过弃牌阶段。 
	引用：
	状态：
]]
--[[
	空城
	相关武将：标-诸葛亮
	描述：锁定技，每当你成为【杀】或【决斗】的目标时，若你没有手牌，你取消之。 
	引用：
	状态：
]]

LuaKongcheng = sgs.CreateTriggerSkill{
	name = "LuaKongcheng",
	events = {sgs.TargetConfirming},
	frequency = sgs.Skill_Compulsory,

    can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
        if player:isKongcheng() then
            local use = data:toCardUse()
            if use.card and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to:contains(player) then
                return self:objectName()
			end
		end
	end,
    on_cost = function(self,event,room,player,data)
        if player:hasShownSkill(self) or player:askForSkillInvoke(self) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
	end,
    on_effect = function(self,event,room,player,data)
        room:sendCompulsoryTriggerLog(player, self:objectName(),true)
        local use = data:toCardUse()
        sgs.Room_cancelTarget(use, player)
        data:setValue(use)
	end,
}

--[[
	苦肉
	相关武将：标-黄盖
	描述：出牌阶段，你可以失去1点体力，摸两张牌。 
	引用：
	状态：
]]
--[[
	狂斧
	相关武将：标-潘凤
	描述：每当你使用【杀】对目标角色造成伤害后，你可以选择一项：1.将其装备区里的一张牌置入你的装备区；2.弃置其装备区里的一张牌。  
	引用：
	状态：
]]
--[[
	狂骨
	相关武将：标-魏延
	描述：锁定技，每当你对距离1以内的一名角色造成1点伤害后，你回复1点体力。    
	引用：
	状态：
]]
