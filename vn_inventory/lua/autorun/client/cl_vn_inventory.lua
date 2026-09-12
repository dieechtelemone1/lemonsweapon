-- VN Inventory - menus and the binocular view.

local inventory = {}

surface.CreateFont("VNINV_Title", { font = "Roboto", size = 24, weight = 700, antialias = true })
surface.CreateFont("VNINV_Item",  { font = "Roboto", size = 18, weight = 600, antialias = true })
surface.CreateFont("VNINV_Small", { font = "Roboto", size = 14, weight = 500, antialias = true })

local colBG     = Color(12, 16, 22, 245)
local colRow    = Color(255, 255, 255, 12)
local colAccent = Color(255, 158, 44)
local colText   = Color(232, 236, 240)
local colDim    = Color(150, 162, 176)

net.Receive("vn_inv_sync", function()
	inventory = {}

	for _ = 1, net.ReadUInt(8) do
		local id = net.ReadString()
		inventory[id] = net.ReadUInt(16)
	end

	hook.Run("VNInventoryUpdated")
end)

net.Receive("vn_inv_notify", function()
	chat.AddText(colAccent, "[Inventar] ", colText, net.ReadString())
end)

-- actions: Liste von { label, fn }, von rechts nach links angeordnet.
local function BuildRow(parent, item, count, actions)
	local row = parent:Add("DPanel")
	row:Dock(TOP)
	row:DockMargin(0, 0, 0, 4)
	row:SetTall(48)

	row.Paint = function(self, w, h)
		surface.SetDrawColor(colRow)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colAccent)
		surface.DrawRect(0, 0, 3, h)

		draw.SimpleText(item.name, "VNINV_Item", 14, 9, colText)
		draw.SimpleText(item.desc, "VNINV_Small", 14, 28, colDim)

		if count then
			draw.SimpleText("x" .. count, "VNINV_Item", w - row.textInset, 15, colAccent, TEXT_ALIGN_RIGHT)
		end
	end

	row.textInset = 20 + #actions * 88

	for _, action in ipairs(actions) do
		local button = row:Add("DButton")
		button:Dock(RIGHT)
		button:DockMargin(0, 8, 8, 8)
		button:SetWide(80)
		button:SetText(action.label)
		button:SetTextColor(colText)
		button.Paint = function(self, w, h)
			surface.SetDrawColor(self:IsHovered() and colAccent or Color(255, 255, 255, 25))
			surface.DrawRect(0, 0, w, h)
		end
		button.DoClick = action.fn
	end

	return row
end

local function BuildFrame(title)
	local frame = vgui.Create("DFrame")
	frame:SetSize(460, 520)
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(true)
	frame:MakePopup()

	frame.Paint = function(self, w, h)
		surface.SetDrawColor(colBG)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colAccent)
		surface.DrawRect(0, 0, w, 2)
		draw.SimpleText(title, "VNINV_Title", 16, 12, colText)
	end

	-- Docking is resolved in the order children are added, so the caller adds
	-- its header panels first and the filling scroll panel last.
	return frame
end

local function AddScroll(frame, topMargin)
	local scroll = frame:Add("DScrollPanel")
	scroll:Dock(FILL)
	scroll:DockMargin(12, topMargin or 8, 12, 12)

	return scroll
end

local invFrame

local function OpenInventory()
	if IsValid(invFrame) then invFrame:Remove() end

	local frame = BuildFrame("Inventar")
	local scroll = AddScroll(frame, 50)
	invFrame = frame

	local function Refresh()
		scroll:Clear()

		local empty = true
		for _, id in ipairs(VN_INV.Order) do
			local count = inventory[id]
			if count and count > 0 then
				empty = false
				local item = VN_INV.Get(id)

				BuildRow(scroll, item, count, {
					{
						label = "Ablegen",
						fn = function()
							net.Start("vn_inv_drop")
							net.WriteString(id)
							net.SendToServer()
						end,
					},
					{
						label = "Benutzen",
						fn = function()
							net.Start("vn_inv_use")
							net.WriteString(id)
							net.SendToServer()
						end,
					},
				})
			end
		end

		if empty then
			local label = scroll:Add("DLabel")
			label:Dock(TOP)
			label:SetTall(40)
			label:SetFont("VNINV_Item")
			label:SetTextColor(colDim)
			label:SetText("Dein Inventar ist leer.")
		end
	end

	Refresh()
	hook.Add("VNInventoryUpdated", frame, Refresh)
end

concommand.Add("vn_inv", OpenInventory, nil, "Öffnet das Inventar")

local ConKey = CreateClientConVar("vn_inv_key", tostring(KEY_I), true, false,
	"Taste zum Öffnen des Inventars (KEY_-Nummer, 0 = aus)")

hook.Add("PlayerButtonDown", "vn_inv_key", function(ply, button)
	if ply ~= LocalPlayer() then return end
	if button ~= ConKey:GetInt() then return end

	-- Bei offenem Menü schließt dieselbe Taste wieder, sonst käme man mit
	-- sichtbarem Mauszeiger nicht mehr heraus.
	if IsValid(invFrame) then
		invFrame:Remove()
		return
	end

	if ply:IsTyping() or gui.IsGameUIVisible() or vgui.CursorVisible() then return end

	OpenInventory()
end)

net.Receive("vn_inv_crate", function()
	local crate = net.ReadEntity()
	if not IsValid(crate) then return end

	local frame = BuildFrame(crate:GetCrateName())

	local status = frame:Add("DPanel")
	status:Dock(TOP)
	status:DockMargin(12, 44, 12, 0)
	status:SetTall(52)

	status.Paint = function(self, w, h)
		if not IsValid(crate) then return end

		local supply = crate:GetSupply()
		local frac = math.Clamp(supply / VN_LOG.MaxSupply, 0, 1)

		local barColor = Color(90, 200, 110)
		if supply <= 0 then
			barColor = Color(235, 70, 60)
		elseif frac < 0.3 then
			barColor = Color(255, 196, 60)
		end

		draw.SimpleText("Vorrat", "VNINV_Small", 0, 0, colDim)
		draw.SimpleText(supply .. " / " .. VN_LOG.MaxSupply, "VNINV_Small", w, 0, colDim, TEXT_ALIGN_RIGHT)

		surface.SetDrawColor(0, 0, 0, 160)
		surface.DrawRect(0, 18, w, 14)
		surface.SetDrawColor(barColor)
		surface.DrawRect(0, 18, w * frac, 14)
	end

	local request = frame:Add("DButton")
	request:Dock(TOP)
	request:DockMargin(12, 4, 12, 0)
	request:SetTall(30)
	request:SetText("Nachschub anfordern")
	request:SetTextColor(colText)
	request.Paint = function(self, w, h)
		surface.SetDrawColor(self:IsHovered() and colAccent or Color(255, 255, 255, 25))
		surface.DrawRect(0, 0, w, h)
	end
	request.DoClick = function()
		if not IsValid(crate) then frame:Remove() return end

		net.Start("vn_log_request")
		net.WriteEntity(crate)
		net.SendToServer()
	end

	local scroll = AddScroll(frame)
	local crateType = VN_INV.CrateType(crate)

	for _, id in ipairs(VN_INV.Order) do
		local item = VN_INV.Get(id)
		if item.crate == crateType then

		local row = BuildRow(scroll, item, nil, { {
			label = "Nehmen",
			fn = function()
				if not IsValid(crate) then frame:Remove() return end

				net.Start("vn_inv_take")
				net.WriteEntity(crate)
				net.WriteString(id)
				net.SendToServer()
			end,
		} })

		row.PaintOver = function(self, w, h)
			local affordable = IsValid(crate) and crate:GetSupply() >= item.cost
			draw.SimpleText(item.cost .. " Vorrat", "VNINV_Small", w - self.textInset, 30,
				affordable and colDim or Color(235, 70, 60), TEXT_ALIGN_RIGHT)
		end

		end
	end
end)

-- Fernglas -------------------------------------------------------------

local function BinocularsActive()
	local ply = LocalPlayer()
	return IsValid(ply) and ply:Alive() and ply:GetNWBool("vn_inv_binoculars", false)
end

-- A returned view table replaces the whole view, so origin and angles have to
-- be passed back through: returning only the fov puts the camera at 0,0,0.
hook.Add("CalcView", "vn_inv_binoculars", function(_, origin, angles, fov)
	if not BinocularsActive() then return end

	return {
		origin = origin,
		angles = angles,
		fov = fov * 0.25,
	}
end)

hook.Add("HUDPaint", "vn_inv_binoculars_overlay", function()
	if not BinocularsActive() then return end

	local w, h = ScrW(), ScrH()
	local r = h * 0.45
	local cx, cy = w * 0.5, h * 0.5

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, cy - r)
	surface.DrawRect(0, cy + r, w, cy - r)
	surface.DrawRect(0, 0, cx - r, h)
	surface.DrawRect(cx + r, 0, cx - r, h)

	surface.SetDrawColor(colAccent)
	surface.DrawLine(cx - 40, cy, cx - 10, cy)
	surface.DrawLine(cx + 10, cy, cx + 40, cy)
	surface.DrawLine(cx, cy - 40, cx, cy - 10)
	surface.DrawLine(cx, cy + 10, cx, cy + 40)

	draw.SimpleText("FERNGLAS", "VNINV_Small", cx, cy + r - 24, colAccent, TEXT_ALIGN_CENTER)
end)
