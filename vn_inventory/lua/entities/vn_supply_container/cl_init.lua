include("shared.lua")

function ENT:Draw()
	self:DrawModel()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:GetPos():Distance(self:GetPos()) > 250 then return end

	local pos = self:GetPos() + self:GetUp() * (self:OBBMaxs().z + 8)
	local ang = (ply:EyePos() - pos):Angle()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos, ang, 0.11)
		draw.SimpleText("NACHSCHUB-CONTAINER", "VNINV_Title", 0, -44, Color(255, 158, 44), TEXT_ALIGN_CENTER)
		draw.SimpleText(self:GetBoxesLeft() .. " Kisten übrig", "VNINV_Item", 0, -20, Color(232, 236, 240), TEXT_ALIGN_CENTER)
		draw.SimpleText("[E] Kiste entnehmen", "VNINV_Small", 0, 4, Color(150, 162, 176), TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
