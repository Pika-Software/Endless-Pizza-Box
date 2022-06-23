ENT.PrintName = "Endless Pizza Box"
ENT.Category = "Fun + Games"

ENT.AutomaticFrameAdvance = true
ENT.Base = "base_anim"
ENT.Spawnable = true

if (CLIENT) then
	ENT.Author = "DefaultOS & PrikolMen:-b"
end

if (SERVER) then

	AddCSLuaFile()

	ENT.Model = "models/pikasoft/scp-458.mdl"
	ENT.Pieces = {2, 1, 3, 4, 5, 6, 7, 8}
	ENT.UseTimeout = 0

	do

		local COLLISION_GROUP_WEAPON = COLLISION_GROUP_WEAPON
		local SOLID_VPHYSICS = SOLID_VPHYSICS
		local SIMPLE_USE = SIMPLE_USE

		function ENT:Initialize()
			self:SetModel( self.Model )
			self:SetCollisionGroup( COLLISION_GROUP_WEAPON )
			self:PhysicsInit( SOLID_VPHYSICS )
			self:SetUseType( SIMPLE_USE )

			if isfunction( self.SetUnbreakable ) then
				self:SetUnbreakable( true )
			end
		end

	end

	local CurTime = CurTime

	function ENT:Think()
		self:NextThink( CurTime() )
		return true
	end

	function ENT:OnTakeDamage()
		self:RemoveAllDecals()
	end

	do

		local snd = Sound("pikasoft/nom.ogg")
		local math_random = math.random
		local util_Effect = util.Effect
		local EffectData = EffectData

		function ENT:EatPiece( ply, id )
			self:SetBodygroup( id, 1 )

			if (ply[self.PrintName] == nil) then
				ply[self.PrintName] = {math_random( 50, 80 ), math_random( 80, 110 )}
			end

			ply[self.PrintName][3] = CurTime() + math_random(5, 10)
			ply:EmitSound( snd, ply[self.PrintName][1], ply[self.PrintName][2], 0.5 )

			local hp = ply:Health()
			if (hp > 200) and not ply[self.PrintName][4] then
				ply[self.PrintName][4] = true
			elseif (hp > 250) then
				ply:KillSilent()

				local fx = EffectData()
				fx:SetOrigin(pos)
				fx:SetScale(10)
				fx:SetStart(ply:GetPlayerColor() * 255)
				util.Effect("balloon_pop", fx)

				ply:SendLua( "achievements.BalloonPopped()" )
				ply[self.PrintName][4] = nil
			else
				ply:SetHealth( ply:Health() + 5 )
			end
		end

	end

	do

		local table_insert = table.insert
		local ipairs = ipairs

		function ENT:GetNonEatedPieces()
			local nonEated = {}

			for num, id in ipairs( self.Pieces ) do
				if (self:GetBodygroup(id) == 1) then continue end
				table_insert(nonEated, id)
			end

			return nonEated
		end

		function ENT:IsAllEated()
			for num, id in ipairs(self.Pieces) do
				if (self:GetBodygroup(id) != 1) then return false end
			end

			return true
		end

	end

	do

		local timer_Simple = timer.Simple
		local table_Random = table.Random
		local IsValid = IsValid
		local pairs = pairs

		function ENT:Use( ply )
			local time = CurTime()
			if (self.UseTimeout > time) or ((ply[self.PrintName] and ply[self.PrintName][3] or 0) > time) then return end
			if not self.Opened then
				self:ResetSequence( "Open" )
				self.Opened = true
				self.UseTimeout = time + self:SequenceDuration( self:GetSequence() )
			else
				self:EatPiece( ply, table_Random( self:GetNonEatedPieces() ) )

				if self:IsAllEated() then
					self:ResetSequence( "Close" )
					self.Opened = false

					local duration = self:SequenceDuration(self:GetSequence())
					timer_Simple(duration, function()
						if IsValid(self) then
							for id, tbl in pairs( self.Pieces ) do
								self:SetBodygroup(id, 0)
							end
						end
					end)

					self.UseTimeout = time + duration
				end
			end
		end

	end

end