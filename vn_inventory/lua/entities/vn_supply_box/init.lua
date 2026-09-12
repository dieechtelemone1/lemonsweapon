AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/props_junk/wood_crate001a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	if self:GetAmount() <= 0 then
		self:SetAmount(VN_LOG.BoxSupply)
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end
end

-- Die Kiste wird eingelagert, sobald sie eine Versorgungskiste berührt. So
-- kann man sie tragen, schieben oder einfach draufwerfen.
function ENT:StartTouch(ent)
	if not VN_INV.CrateType(ent) then return end
	if ent:GetSupply() >= VN_LOG.MaxSupply then return end

	local before = ent:GetSupply()
	ent:AddSupply(self:GetAmount())

	local carrier = self.LastCarrier
	if IsValid(carrier) then
		VN_INV.Notify(carrier, string.format("%s eingelagert: +%d Vorrat.",
			ent:GetCrateName(), ent:GetSupply() - before))
	end

	self:EmitSound("physics/wood/wood_crate_impact_hard2.wav")
	self:Remove()
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	self.LastCarrier = activator
	VN_INV.Notify(activator, "Kiste an eine Versorgungskiste bringen, um sie einzulagern.")
end

-- Wer die Kiste zuletzt angefasst hat, bekommt die Rückmeldung beim Einlagern.
hook.Add("PhysgunPickup", "vn_supply_box_carrier", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "vn_supply_box" then
		ent.LastCarrier = ply
	end
end)

hook.Add("GravGunOnPickedUp", "vn_supply_box_carrier", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "vn_supply_box" then
		ent.LastCarrier = ply
	end
end)
