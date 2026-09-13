AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local item = VN_INV.Get(self:GetItemId())

	self:SetModel(item and item.dropModel or VN_INV.DropModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end

	if VN_INV.DropLifetime > 0 then
		timer.Simple(VN_INV.DropLifetime, function()
			if IsValid(self) then self:Remove() end
		end)
	end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if not activator:Alive() then return end
	if (self.nextUse or 0) > CurTime() then return end

	self.nextUse = CurTime() + 0.3

	local ok, reason = VN_INV.GiveItem(activator, self:GetItemId(), 1)
	if not ok then
		if reason then VN_INV.Notify(activator, reason) end
		return
	end

	self:Remove()
end
