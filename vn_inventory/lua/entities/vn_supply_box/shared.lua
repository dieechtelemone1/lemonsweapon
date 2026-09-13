ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Nachschub-Kiste"
ENT.Author = "VN"
ENT.Category = "VN"

ENT.Spawnable = false
ENT.DisableDuplicator = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Amount")
end
