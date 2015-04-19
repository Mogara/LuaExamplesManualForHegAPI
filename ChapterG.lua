--[[
	国战技能速查手册（G区）
	技能索引：
	刚烈、固政、观星、闺秀、鬼才、鬼道、国色   
]]--
--[[
	刚烈
	相关武将：标-夏侯惇
	描述：每当你受到伤害后，你可以进行判定，若结果不为♥，来源选择一项：1.弃置两张手牌；2.受到你造成的1点伤害。 
	引用：
	状态：
]]

Luaganglie = sgs.CreateTriggerSkill{
	name = "Luaganglie",
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then	return false end
		local damage = data:toDamage()
		local source = damage.from
		if source and source:isAlive() then
			return self:objectName() .. "->" .. damage.from:objectName()
		end
	end,
	
	on_cost = function(self, event, room, from, data, player)
		d = sgs.QVariant()
		d:setValue(from)
		return room:askForSkillInvoke(player, self:objectName(), d)
	end,
	
	on_effect = function(self, event, room, from, data, player)
		room:notifySkillInvoked(player,self:objectName())
		room:broadcastSkillInvoke(self:objectName())
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|heart"
		judge.who = player
		judge.reason = self:objectName()
		judge.good = false
		room:judge(judge)				

		if judge.card:isGood() then
            if from:getHandcardNum() < 2 or not room:askForDiscard(from, self:objectName(), 2, 2, true) then
                room:damage(sgs.DamageStruct(self:objectName(), player, from))
			end
		end
	end,
}


--[[
	固政
	相关武将：标-张昭&张纮
	描述：将弃牌堆里的该角色于此阶段内弃置的一张手牌交给该角色，若如此做，你可以获得弃牌堆里的其余于此阶段内弃置的牌。 
	引用：
	状态：
]]
--[[
	观星
	相关武将：标-诸葛亮
	描述：准备阶段开始时，你可以观看牌堆顶的X张牌（X为全场角色数且至多为5），然后将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。 
	引用：
	状态：
]]
--[[
	闺秀
	相关武将：势-糜夫人
	描述：每当你明置此武将牌时，你可以摸两张牌；当你移除此武将牌时，你可以回复1点体力。  
	引用：
	状态：
]]
--[[
	鬼才
	相关武将：标-司马懿
	描述：每当一名角色的判定牌生效前，你可以打出一张手牌代替之。 
	引用：
	状态：
]]

LuaGuicai = sgs.CreateTriggerSkill{
	name = "LuaGuicai" ,
	events = {sgs.AskForRetrial} ,
	can_trigger = function(self, event, room, player, data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if player:isKongcheng() and player:getHandPile():isEmpty() then
			return "."
		else return self:objectName()
		end
	end,
		
	on_cost = function(self, event, room, player, data)
		local judge = data:toJudge()
		local room = player:getRoom()
		local prompt_list = {
			"@guicai-card" ,
			judge.who:objectName() ,
			self:objectName() ,
			judge.reason ,
			string.format("%d", judge.card:getEffectiveId())
            }
		local prompt = table.concat(prompt_list, ":")
		local card = room:askForCard(player, ".", prompt,data, sgs.Card_MethodResponse, judge.who, true)
		if card then
			room:broadcastSkillInvoke(self:objectName(), player);
			room:retrial(card, player, judge, self:objectName())
			return true
		else
			return false
		end
	end,
		
	on_effect = function(self, event, room, player, data)
		local judge = data:toJudge()
		judge:updateResult()
		return false
	end,
}

--[[
	鬼道
	相关武将：标-张角
	描述：每当一名角色的判定牌生效前，你可以打出一张黑色牌替换之。 
	引用：
	状态：
]]
--[[
	国色
	相关武将：标-大乔
	描述：你可以将一张♦牌当【乐不思蜀】使用。 
	引用：
	状态：
]]
