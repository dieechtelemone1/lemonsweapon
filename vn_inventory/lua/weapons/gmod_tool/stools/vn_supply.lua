TOOL.Category = "VN"
TOOL.Name = "Nachschub-Container"

TOOL.ClientConVar["boxes"] = tostring(VN_LOG and VN_LOG.ContainerBoxes or 6)

if CLIENT then
	language.Add("tool.vn_supply.name", "Nachschub-Container")
	language.Add("tool.vn_supply.desc", "Setzt einen Container ab, aus dem Nachschub-Kisten entnommen werden.")
	language.Add("tool.vn_supply.left", "Container absetzen")
	language.Add("tool.vn_supply.right", "Container entfernen")

	function TOOL.BuildCPanel(panel)
		panel:Help("Setzt einen Nachschub-Container ab. Aus ihm werden Kisten entnommen und zu den Versorgungskisten getragen.")
		panel:NumSlider("Kisten im Container", "vn_supply_boxes", 1, 20, 0)
	end
end

function TOOL:Allowed()
	local ply = self:GetOwner()
	return IsValid(ply) and VN_LOG.IsLogistics(ply)
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not self:Allowed() then
		VN_INV.Notify(self:GetOwner(), "Nur Logistik und Admins dürfen Container absetzen.")
		return false
	end

	if trace.Entity and trace.Entity:IsPlayer() then return false end

	local container = ents.Create("vn_supply_container")
	if not IsValid(container) then return false end

	container:SetBoxesLeft(math.Clamp(self:GetClientNumber("boxes", VN_LOG.ContainerBoxes), 1, 20))
	container:SetPos(trace.HitPos + trace.HitNormal * 20)
	container:SetAngles(Angle(0, self:GetOwner():EyeAngles().y, 0))
	container:Spawn()

	undo.Create("Nachschub-Container")
		undo.AddEntity(container)
		undo.SetPlayer(self:GetOwner())
	undo.Finish()

	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not self:Allowed() then return false end

	local ent = trace.Entity
	if not IsValid(ent) or ent:GetClass() ~= "vn_supply_container" then return false end

	ent:Remove()
	return true
end
