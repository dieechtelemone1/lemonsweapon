AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_junk/wood_crate002a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	if self:GetBoxesLeft() <= 0 then
		self:SetBoxesLeft(VN_LOG.ContainerBoxes)
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if not activator:Alive() then return end
	if (self.nextUse or 0) > CurTime() then return end

	self.nextUse = CurTime() + 0.8

	if self:GetBoxesLeft() <= 0 then
		VN_INV.Notify(activator, "Der Container ist leer.")
		return
	end

	local box = ents.Create("vn_supply_box")
	if not IsValid(box) then return end

	box:SetAmount(VN_LOG.BoxSupply)
	box:SetPos(self:GetPos() + self:GetUp() * (self:OBBMaxs().z + 20))
	box:SetAngles(Angle(0, self:GetAngles().y, 0))
	box:Spawn()
	box.LastCarrier = activator

	self:SetBoxesLeft(self:GetBoxesLeft() - 1)

	if self:GetBoxesLeft() <= 0 then
		self:Remove()
	end
end
