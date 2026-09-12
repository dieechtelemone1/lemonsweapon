include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:GetPos():Distance(self:GetPos()) > VN_INV.CrateRange then return end

	local pos = self:GetPos() + self:GetUp() * 22
	local ang = (ply:EyePos() - pos):Angle()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.1)
		draw.SimpleText("VERSORGUNG", "VNINV_Title", 0, -30, Color(255, 158, 44), TEXT_ALIGN_CENTER)
		draw.SimpleText("[E] öffnen", "VNINV_Item", 0, 0, Color(232, 236, 240), TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
