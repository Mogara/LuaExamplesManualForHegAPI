--[[
	国战技能速查手册（P区）
	技能索引：
	咆哮
]]--
--[[
	咆哮
	相关武将：标-张飞
	描述：你使用【杀】无次数限制。 
	引用：
	状态：咆哮的亮将与播放音效在源代码里 standard-basic.cpp
]]

LuaPaoxiao = sgs.CreateTargetModSkill{
	name = "LuaPaoxiao",
	residue_func = function(self, from, card)
        if not sgs.Sanguosha:matchExpPattern("Slash", from, card) then return 0 end
        if from:hasSkill(self:objectName()) then
            return 1000
        else
            return 0
		end
	end,
}

--[[
	咆哮 ——【授钺】之五虎将大旗
	相关武将：标-张飞
	描述：锁定技，每当你使用【杀】指定一名目标角色后，你无视其防具。
	引用：
	状态：
]]

LuaPaoxiaoArmorNullificaion = sgs.CreateTriggerSkill{
	name = "#Luapaoxiao-null",
	events = {sgs.TargetChosen},
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_preshow = false,

    can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() then return false end
        local use = data:toCardUse()
        if player:hasSkills("paoxiao|LuaPaoxiao") then
            local lord = room:getLord(player:getKingdom())
            if lord and lord:hasLordSkill("shouyue") and lord:hasShownGeneral1() then
                if use.card and use.card:isKindOf("Slash") then
                    local targets = {}
					for _, p in sgs.qlist(use.to) do
                        table.insert(targets,p:objectName())
					end
                    if #targets > 0 then
                        return self:objectName() .. "->" .. table.concat(targets,"+")
					end
				end
			end
		end
	end,
	on_cost = function(self,event,room,target,data, ask_who)
        if ask_who then
            if ask_who:hasShownSkills("LuaPaoxiao") then
                return true
            else
                ask_who:setTag("paoxiao_use", data)				--useless data?
				local invoke = ask_who:askForSkillInvoke("LuaPaoxiao", sgs.QVariant("armor_nullify:" .. target:objectName()))
                ask_who:removeTag("paoxiao_use")
                if invoke then
                    ask_who:showGeneral(ask_who:inHeadSkills("LuaPaoxiao"))
                    return true
				end
			end
		end
	end,

    on_effect = function(self,event,room,target,data, ask_who)
		local lord = room:getLord(ask_who:getKingdom())
        room:notifySkillInvoked(lord, "shouyue")
		room:broadcastSkillInvoke("shouyue")
        local use = data:toCardUse()
        target:addQinggangTag(use.card)
	end,
}
