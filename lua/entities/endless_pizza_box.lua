local util_AddNetworkString = SERVER and util.AddNetworkString
local something_interesting = CLIENT and steamworks.FileInfo
local language_Add = CLIENT and language.Add
local chat_AddText = CLIENT and chat.AddText
local net_Send = SERVER and net.Send
local net_WriteUInt = net.WriteUInt
local net_ReadUInt = net.ReadUInt
local table_insert = table.insert
local table_Random = table.Random
local timer_Simple = timer.Simple
local util_Effect = util.Effect
local math_random = math.random
local EffectData = EffectData
local net_Start = net.Start
local IsValid = IsValid
local CurTime = CurTime
local ipairs = ipairs
local Vector = Vector
local pairs = pairs

AddCSLuaFile()

local phrases = {
	["ru"] = {
		[0] = "Бесконечная Коробка Пиццы",
		[1] = "В вас больше не влезет, стоит остановиться.",
		[2] = "Вы 'лопнули'",
		[3] = "Другое",
	},
	["en"] = {
		[0] = "Endless Pizza Box",
		[1] = "You won't fit anymore, it's worth stopping.",
		[2] = "You 'exploded'",
		[3] = "Other",
	}
}

if CLIENT then
	ENT.Author = "DefaultOS & PrikolMen:-b"

	for tag, text in pairs(phrases["en"]) do
		language_Add("pika.endless_pizza_box_"..tag, text)
	end

	local main1 = Color(254, 84, 54)
	local main2 = Color(200, 200, 200)

	net.Receive("pika.endless_pizza_box", function()
		local text = net_ReadUInt(2)
		if (text == 2) then
			local effectdata = EffectData()
			effectdata:SetOrigin(LocalPlayer():GetPos())
			effectdata:SetStart(Vector(255, 0, 0))
			util_Effect("balloon_pop", effectdata)
		else
			chat_AddText(main1, "[", "#pika.endless_pizza_box_0", "] ", main2,"#pika.endless_pizza_box_"..text)
		end
	end)
else
	util_AddNetworkString("pika.endless_pizza_box")
end

hook.Add("LanguageChanged", "pika.endless_pizza_box", function(_, lang)
    if (lang == "ru") then
		for tag, text in pairs(phrases[lang]) do
			PLang:AddPhrase(text, lang, "pika.endless_pizza_box_"..tag)
		end
    else
		for tag, text in pairs(phrases["en"]) do
			PLang:AddPhrase(text, "en", "pika.endless_pizza_box_"..tag)
		end
    end
end)

ENT.Base = "base_anim"
ENT.PrintName = "#pika.endless_pizza_box_0"
ENT.Category = "#pika.endless_pizza_box_3"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = true

-- Custom Data
ENT["Pieces"] = {2, 1, 3, 4, 5, 6, 7, 8}
ENT["UseTimeout"] = 0
ENT["HP"] = 25

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/pikasoft/scp-458.mdl")

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		self:SetHealth(self["HP"])
		self:SetMaxHealth(self["HP"])
	else
		something_interesting("2623390511", function(tbl)
			if IsValid(self) then
				self["Fuck You"] = tbl["ownername"]	-- Special for you <3
			end
		end)
	end
end

function ENT:Think()
	if SERVER then
		self:NextThink(CurTime())
		return true
	end
end

local snd = Sound("pikasoft/nom.ogg")
function ENT:EatPiece(ply, id)
	self:SetBodygroup(id, 1)
	if (ply["pika.endless_pizza_box_voice"] == nil) then
		ply["pika.endless_pizza_box_voice"] = {math_random(50, 80), math_random(80, 110)}
	end

	local sndTbl = ply["pika.endless_pizza_box_voice"]

	ply:EmitSound(snd, sndTbl[1], sndTbl[2], 0.5)
	ply:SetHealth(ply:Health() + 5)
	ply[self:GetClass().."_Timeout"] = CurTime() + math_random(5, 10)

	local hp = ply:Health()
	if (hp > 200) then
		if not ply["pika.endless_pizza_box_marker"] then
			ply["pika.endless_pizza_box_marker"] = true
			net_Start("pika.endless_pizza_box")
				net_WriteUInt(1, 2)
			net_Send(ply)
		elseif (hp > 250) then
			local effectdata = EffectData()
			effectdata:SetOrigin(ply:GetPos())
			effectdata:SetStart(Vector(255, 0, 0))
			util_Effect("balloon_pop", effectdata)

			net_Start("pika.endless_pizza_box")
				net_WriteUInt(2, 2)
			net_Send(ply)

			ply:SendLua("achievements.BalloonPopped()")
			
			ply:KillSilent()
			ply["pika.endless_pizza_box_marker"] = false
		end
	end
end

function ENT:IsAllEated()
	for num, id in ipairs(self["Pieces"]) do
		if (self:GetBodygroup(id) != 1) then return false end
	end

	return true
end

function ENT:GetNonEatedPieces()
	local nonEated = {}

	for num, id in ipairs(self["Pieces"]) do
		if (self:GetBodygroup(id) == 1) then continue end
		table_insert(nonEated, id)
	end

	return nonEated
end

function ENT:Use(ply)
	local time = CurTime()
	if (self["UseTimeout"] > time) or ((ply[self:GetClass().."_Timeout"] or 0) > time) then return end
	if not self["Opened"] then
		self:ResetSequence("Open")
		self["Opened"] = true
		self["UseTimeout"] = time + self:SequenceDuration(self:GetSequence()) 
	else
		self:EatPiece(ply, table_Random(self:GetNonEatedPieces()))

		if self:IsAllEated() then
			self:ResetSequence("Close")
			self["Opened"] = false
			
			local duration = self:SequenceDuration(self:GetSequence())
			timer_Simple(duration, function()
				if IsValid(self) then
					for id, tbl in pairs(self["Pieces"]) do
						self:SetBodygroup(id, 0)
					end
				end
			end)

			self["UseTimeout"] = time + duration
		end
	end
end