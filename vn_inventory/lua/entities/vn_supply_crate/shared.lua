ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Versorgungskiste"
ENT.Author = "VN"
ENT.Category = "VN"

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.CrateModel = "models/Items/item_item_crate.mdl"
ENT.CrateLabel = "VERSORGUNG"
ENT.DefaultName = "Kiste"
ENT.LabelColor = Color(255, 158, 44)

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Supply")
	self:NetworkVar("Bool", 0, "Requested")
	self:NetworkVar("String", 0, "CrateName")
end
