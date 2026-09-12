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

	local supply = self:GetSupply()
	local frac = math.Clamp(supply / VN_LOG.MaxSupply, 0, 1)

	local barColor = Color(90, 200, 110)
	if frac <= 0 then
		barColor = Color(235, 70, 60)
	elseif frac < 0.3 then
		barColor = Color(255, 196, 60)
	end

	cam.Start3D2D(pos, ang, 0.1)
		draw.SimpleText(string.upper(self:GetCrateName()), "VNINV_Title", 0, -62, self.LabelColor, TEXT_ALIGN_CENTER)
		draw.SimpleText(self.CrateLabel, "VNINV_Small", 0, -40, self.LabelColor, TEXT_ALIGN_CENTER)

		surface.SetDrawColor(0, 0, 0, 180)
		surface.DrawRect(-100, -18, 200, 14)
		surface.SetDrawColor(barColor)
		surface.DrawRect(-100, -18, 200 * frac, 14)

		draw.SimpleText(supply .. " / " .. VN_LOG.MaxSupply, "VNINV_Small", 0, -17, Color(255, 255, 255), TEXT_ALIGN_CENTER)

		if supply <= 0 then
			local label = self:GetRequested() and "NACHSCHUB ANGEFORDERT" or "LEER - [E] anfordern"
			draw.SimpleText(label, "VNINV_Item", 0, 4, Color(235, 70, 60), TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("[E] öffnen", "VNINV_Item", 0, 4, Color(232, 236, 240), TEXT_ALIGN_CENTER)
		end
	cam.End3D2D()
end
