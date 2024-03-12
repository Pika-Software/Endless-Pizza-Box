AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
local flags = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
local scp458_max_heal = CreateConVar("scp458_max_health", "250", flags, "Maximum amount of health that infinite pizza can give.", 0, 0xFFFF)
local scp458_heal = CreateConVar("scp458_heal", "5", flags, "Amount of health that one piece of pizza heals.", 0, 0xFFFF)
local random, Rand
do
	local _obj_0 = math
	random, Rand = _obj_0.random, _obj_0.Rand
end
local CurTime = CurTime
ENT.Initialize = function(self)
	self:SetUseType(SIMPLE_USE)
	self:SetModel(self.Model)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysWake()
	return
end
ENT.OnTakeDamage = function(self)
	self:RemoveAllDecals()
	return 0
end
ENT.Think = function(self)
	self:NextThink(CurTime())
	return true
end
ENT.EatPiece = function(self, ply, index)
	ply:EmitSound(self.Sound, 65, random(60, 120), Rand(0.5, 1), CHAN_STATIC, 0, 1)
	self:SetBodygroup(index, 1)
	local maxHeal = scp458_max_heal:GetInt()
	if maxHeal == 0 then
		maxHeal = ply:GetMaxHealth()
	end
	local health = ply:Health()
	if health >= maxHeal then
		return
	end
	health = health + scp458_heal:GetInt()
	if health > maxHeal then
		health = maxHeal
	end
	ply:SetHealth(health)
	return
end
ENT.GetAvailablePieces = function(self)
	local avaliable, count = { }, 0
	for index = 1, 8 do
		if self:GetBodygroup(index) == 0 then
			count = count + 1
			avaliable[count] = index
		end
	end
	return avaliable, count
end
ENT.Use = function(self, ply)
	local curTime = CurTime()
	if (self.UsageTimeout or 0) > curTime or (curTime - (ply.m_dLastEatTime or 0)) < 1 then
		return
	end
	if not self.m_bOpened then
		self.m_bOpened = true
		self:ResetSequence("Open")
		self.UsageTimeout = curTime + self:SequenceDuration(self:GetSequence())
		return
	end
	local avaliable, count = self:GetAvailablePieces()
	if count > 0 then
		self:EatPiece(ply, avaliable[random(1, count)])
		self.UsageTimeout = curTime + 0.125
		ply.m_dLastEatTime = curTime
	end
	if count < 2 then
		self.m_bOpened = false
		self:ResetSequence("Close")
		local duration = self:SequenceDuration(self:GetSequence())
		self.UsageTimeout = curTime + duration
		timer.Simple(duration, function()
			if not self:IsValid() then
				return
			end
			for index = 1, 8 do
				self:SetBodygroup(index, 0)
			end
		end)
	end
	return
end
