--[[
	国战技能速查手册（B区）
	技能索引：
	八阵、暴凌、悲歌、闭月、不屈
]]--
--[[
	八阵
	相关武将：标-卧龙诸葛亮
	描述：锁定技，若你的装备区里没有防具牌，你视为装备着【八卦阵】。 
	引用：
	状态：
]]

LuaBazhen = sgs.CreateTriggerSkill{
	name = "LuaBazhen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardAsked},

	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local pattern = data:toStringList()[1]
		if pattern ~= "jink" then return false end
		local qinggang = player:getTag("Qinggang"):toStringList()
		if #qinggang ~= 0 or player:getMark("Armor_Nullified") > 0 or player:getMark("Equips_Nullified_to_Yourself") > 0 then return false end
		--if player:hasArmorEffect("bazhen") then --这个东西在源代码里，无法100%还原
		if not player:getArmor() and not player:hasArmorEffect("bazhen") then
			return "EightDiagram"
		end
	end,
    on_cost = function(self, event, room, player, data)
		return false
	end,
}

--[[
	暴凌
	相关武将：势-董卓
	描述：主将技，锁定技，出牌阶段结束时，若此武将牌已明置且你有副将，你移除副将的武将牌，然后加3点体力上限，回复
		  3点体力，获得“崩坏”。 
	引用：
	状态：
]]

--[[
	悲歌
	相关武将：标-蔡文姬
	描述：每当一名角色受到【杀】造成的伤害后，你可以弃置一张牌并选择该角色，令其进行判定，若结果为：♥—该角色回复1点
	      体力；♦—该角色摸两张牌；♣—来源弃置两张牌；♠—来源叠置。 
	引用：
	状态：
]]

--[[
	闭月
	相关武将：标-貂蝉
	描述：结束阶段开始时，你可以摸一张牌。 
	引用：
	状态：
]]

LuaBiyue = sgs.CreatePhaseChangeSkill{
	name = "LuaBiyue",
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self,event,room,player)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
			return self:objectName()
		end
	end,
	on_cost = function(self,event,room,player)
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
	end,
	on_phasechange = function(self,player)
		player:drawCards(1)
	end,
}

--[[
	不屈
	相关武将：标-周泰
	描述：每当你扣减1点体力后，若你的体力值为0，你可以将牌堆顶的一张牌置于武将牌上，称为“创”，若所有“创”的点数
	      均不同，你不进入濒死状态。 
	引用：
	状态：
]]

--不屈
function LuaRemove(zhoutai)
		local room = zhoutai:getRoom()
		local buqu = zhoutai:getPile("luabuqu")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "" , "LuaBuqu", "")
		local need = 1 - zhoutai:getHp()
		if need <= 0 then
            for _, card_id in sgs.qlist(buqu) do
				local log = sgs.LogMessage()
				log.type = "$BuquRemove"
                log.from = zhoutai
				log.card_str = sgs.Sanguosha:getCard(card_id):toString()
				room:sendLog(log)
                room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
			end
		else
			local to_remove = buqu:length() - need
			for i = 1, to_remove, 1 do
				room:fillAG(buqu, zhoutai)
				--int aidelay = Config.AIDelay;
				--Config.AIDelay = 0;
				local card_id = room:askForAG(zhoutai, buqu, false, "LuaBuqu")
				--Config.AIDelay = aidelay;
				local log = sgs.LogMessage()
				log.type = "$BuquRemove"
				log.from = zhoutai
				log.card_str = sgs.Sanguosha:getCard(card_id):toString()
				room:sendLog(log)

				buqu:removeOne(card_id)
				room:throwCard(sgs.Sanguosha:getCard(card_id), reason, nil)
				room:clearAG(zhoutai)
			end
		end
	end
	

LuaBuquRemove = sgs.CreateTriggerSkill{
	name = "#LuaBuqu-remove",
	events = {sgs.HpRecover},
	frequency = sgs.Skill_Compulsory,

	can_trigger = function(self,event,room,zhoutai,data)
		if not zhoutai or not zhoutai:isAlive() or not zhoutai:hasSkill("LuaBuqu") then return false end
		if zhoutai:getPile("luabuqu"):length() > 0 then
            LuaRemove(zhoutai)
		end
	end,
}

LuaBuqu = sgs.CreateTriggerSkill{
	name = "LuaBuqu",
	events = {sgs.PostHpReduced,sgs.AskForPeachesDone},
	frequency = sgs.Skill_Frequent,

	can_trigger = function(self,event,room,zhoutai,data)
		if not zhoutai or not zhoutai:isAlive() or not zhoutai:hasSkill(self:objectName()) then return false end
		if event == sgs.PostHpReduced and zhoutai:getHp() < 1 then
			return self:objectName()
		elseif event == sgs.AskForPeachesDone then
			local buqu = zhoutai:getPile("luabuqu")
			if zhoutai:getHp() > 0 then return false end
			if room:getTag("LuaBuqu"):toString() ~= zhoutai:objectName() then return false end
			room:removeTag("LuaBuqu")

			local duplicate_numbers = {}
			local numbers = {}
			for _, card_id in sgs.qlist(buqu) do
				local card = sgs.Sanguosha:getCard(card_id)
				local number = card:getNumber()

				if table.contains(numbers, number) and not table.contains(duplicate_numbers, number) then
                    table.insert(duplicate_numbers,number)
                else
                    table.insert(numbers,number)
				end
			end

			if #duplicate_numbers == 0 then
				room:broadcastSkillInvoke(self:objectName(), zhoutai)
				room:setPlayerFlag(zhoutai, "-Global_Dying")
				return self:objectName()
			else
				local log = sgs.LogMessage()
				log.type = "#BuquDuplicate"
				log.from = zhoutai
				log.arg = #duplicate_numbers
                room:sendLog(log)

				for i = 1, #duplicate_numbers, 1 do
					local number = duplicate_numbers[i]

					local log = sgs.LogMessage()
                    log.type = "#BuquDuplicateGroup"
                    log.from = zhoutai
                    log.arg = i
					local number_string = {"-","A","2","3","4","5","6","7","8","9","10","J","Q","K"}
					log.arg2 = number_string[number]
					room:sendLog(log)
					for _, card_id in sgs.qlist(buqu) do
						local card = sgs.Sanguosha:getCard(card_id)
						if card:getNumber() == number then
							local log = sgs.LogMessage()
							log.type = "$BuquDuplicateItem"
							log.from = zhoutai
							log.card_str = card_id
							room:sendLog(log)
						end
					end
				end
			end
		end
	end,

	on_cost = function(self,event,room,zhoutai,data)
		if event == sgs.AskForPeachesDone then
			return true
		end
		if zhoutai:askForSkillInvoke(self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), zhoutai)
			local buqu = zhoutai:getPile("luabuqu")
			local need = 1 - zhoutai:getHp()
			local n = need - buqu:length()
			if n > 0 then
				local card_ids = room:getNCards(n, false)
                zhoutai:addToPile("luabuqu", card_ids)
			end
			return true
		end
	end,

	on_effect = function(self,event,room,zhoutai,data)
		if event == sgs.AskForPeachesDone then
			return true
		end
		if zhoutai:getHp() < 1 then
			room:setTag("LuaBuqu", sgs.QVariant(zhoutai:objectName()))
			local buqunew = zhoutai:getPile("luabuqu")
			
			local duplicate_numbers = {}
			local numbers = {}
			for _, card_id in sgs.qlist(buqunew) do
				local card = sgs.Sanguosha:getCard(card_id)
				local number = card:getNumber()

				if table.contains(numbers, number) and not table.contains(duplicate_numbers, number) then
                    table.insert(duplicate_numbers,number)
                else
                    table.insert(numbers,number)
				end
			end
			if #duplicate_numbers == 0 then
				room:removeTag("LuaBuqu")
                return true
			end
		end
	end,
}

LuaBuquClear = sgs.CreateTriggerSkill{
	name = "#LuaBuquClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventLoseSkill},

	can_trigger = function(self,event,room,zhoutai,data)
		if data:toString() == "LuaBuqu" then
			if zhoutai:getHp() <= 0 then
				room:enterDying(zhoutai, nil)
			end
		end
	end,
}
