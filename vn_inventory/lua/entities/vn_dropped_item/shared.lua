ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Abgelegtes Item"
ENT.Author = "VN"
ENT.Category = "VN"

ENT.Spawnable = false
ENT.DisableDuplicator = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "ItemId")
end
