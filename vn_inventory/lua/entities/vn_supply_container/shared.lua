ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Nachschub-Container"
ENT.Author = "VN"
ENT.Category = "VN"

ENT.Spawnable = true
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "BoxesLeft")
end
