include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:GetPos():Distance(self:GetPos()) > 200 then return end

	local pos = self:GetPos() + self:GetUp() * 18
	local ang = (ply:EyePos() - pos):Angle()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.09)
		draw.SimpleText("NACHSCHUB", "VNINV_Item", 0, -20, Color(255, 158, 44), TEXT_ALIGN_CENTER)
		draw.SimpleText("+" .. self:GetAmount() .. " Vorrat", "VNINV_Small", 0, 2, Color(232, 236, 240), TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
