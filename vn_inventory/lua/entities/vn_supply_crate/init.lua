AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local nextCrateNumber = 0

function ENT:Initialize()
	self:SetModel(self.CrateModel)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	nextCrateNumber = nextCrateNumber + 1
	self:SetCrateName(self.DefaultName .. " " .. nextCrateNumber)
	self:SetSupply(VN_LOG.StartSupply)
	self:SetRequested(false)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end
end

function ENT:TakeSupply(amount)
	if self:GetSupply() < amount then return false end

	self:SetSupply(self:GetSupply() - amount)
	return true
end

function ENT:AddSupply(amount)
	self:SetSupply(math.min(self:GetSupply() + amount, VN_LOG.MaxSupply))
	self:SetRequested(false)
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if not activator:Alive() then return end
	if (self.nextUse or 0) > CurTime() then return end

	self.nextUse = CurTime() + 0.5

	net.Start("vn_inv_crate")
	net.WriteEntity(self)
	net.Send(activator)
end
