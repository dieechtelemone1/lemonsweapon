-- VN Inventory - Gitter-Oberfläche, Kistenmenü und Fernglas.

local inventory = {}

surface.CreateFont("VNINV_Title", { font = "Roboto", size = 22, weight = 600, antialias = true })
surface.CreateFont("VNINV_Item",  { font = "Roboto", size = 17, weight = 600, antialias = true })
surface.CreateFont("VNINV_Label", { font = "Roboto", size = 12, weight = 500, antialias = true })
surface.CreateFont("VNINV_Small", { font = "Roboto", size = 13, weight = 500, antialias = true })

local colBG      = Color(18, 20, 24, 200)
local colHeader  = Color(26, 29, 34, 215)
local colSlot    = Color(255, 255, 255, 14)
local colSlotOut = Color(255, 255, 255, 22)
local colHover   = Color(255, 158, 44, 60)
local colAccent  = Color(255, 158, 44)
local colText    = Color(232, 236, 240)
local colDim     = Color(150, 162, 176)
local colBad     = Color(235, 70, 60)

local COLUMNS = 8
local SLOT = 58
local PAD = 4

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

local function StyleFrame(frame, title)
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:MakePopup()

	frame.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, colBG)
		draw.RoundedBox(6, 0, 0, w, 36, colHeader)

		surface.SetDrawColor(colAccent)
		for i = 0, 2 do
			for j = 0, 2 do
				surface.DrawRect(13 + i * 5, 13 + j * 5, 3, 3)
			end
		end

		draw.SimpleText(title, "VNINV_Title", 34, 8, colText)
	end

	local close = frame:Add("DButton")
	close:SetText("")
	close:SetSize(26, 22)
	close.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and colBad or Color(255, 255, 255, 20))
		draw.SimpleText("X", "VNINV_Small", w * 0.5, h * 0.5 - 1, colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	close.DoClick = function() frame:Remove() end

	frame.PerformLayout = function(self, w)
		close:SetPos(w - 33, 7)
	end

	return frame
end

-- Ein Gitterfeld: leer oder mit Modell-Symbol, Anzahl und Namen.
local function BuildSlot(parent, item, count, onClick)
	local slot = parent:Add("DButton")
	slot:SetSize(SLOT, SLOT)
	slot:SetText("")

	slot.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, self:IsHovered() and item and colHover or colSlot)

		surface.SetDrawColor(colSlotOut)
		surface.DrawOutlinedRect(0, 0, w, h)

		if not item then return end

		if count and count > 1 then
			draw.SimpleText(count, "VNINV_Label", 4, 2, colAccent)
		end

		draw.SimpleText(item.name, "VNINV_Label", w * 0.5, h - 13, colText, TEXT_ALIGN_CENTER)
	end

	if item then
		local icon = slot:Add("DModelPanel")
		icon:SetSize(SLOT - 16, SLOT - 26)
		icon:SetPos(8, 2)
		icon:SetModel(item.dropModel)
		icon:SetMouseInputEnabled(false)
		icon.LayoutEntity = function() end

		local ent = icon:GetEntity()
		if IsValid(ent) then
			local mins, maxs = ent:GetRenderBounds()
			local size = math.max(maxs:Length(), mins:Length())
			icon:SetCamPos(Vector(size, size, size * 0.7))
			icon:SetLookAt((mins + maxs) * 0.5)
			icon:SetFOV(32)
		end

		slot:SetTooltip(item.desc ~= "" and item.desc or item.name)
		slot.DoClick = onClick
	end

	return slot
end

local function BuildGrid(frame, top)
	local grid = frame:Add("DIconLayout")
	grid:Dock(FILL)
	grid:DockMargin(10, top, 10, 10)
	grid:SetSpaceX(PAD)
	grid:SetSpaceY(PAD)

	return grid
end

local function FrameWidth()
	return COLUMNS * (SLOT + PAD) + 20 - PAD
end

local invFrame

local function OpenInventory()
	if IsValid(invFrame) then invFrame:Remove() end

	local rows = math.max(math.ceil(VN_INV.MaxSlots / COLUMNS), 4)

	local frame = vgui.Create("DFrame")
	frame:SetSize(FrameWidth(), rows * (SLOT + PAD) + 82)
	frame:Center()
	StyleFrame(frame, "Inventar")
	invFrame = frame

	local search = frame:Add("DTextEntry")
	search:Dock(TOP)
	search:DockMargin(10, 42, 10, 6)
	search:SetTall(24)
	search:SetPlaceholderText("Suche")
	search:SetDrawBackground(false)
	search.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, colSlot)
		self:DrawTextEntryText(colText, colAccent, colText)

		if self:GetText() == "" and not self:HasFocus() then
			draw.SimpleText("Suche", "VNINV_Small", 6, h * 0.5, colDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	local grid = BuildGrid(frame, 4)

	local function Refresh()
		grid:Clear()

		local filter = string.lower(search:GetValue())
		local used = 0

		for _, id in ipairs(VN_INV.Order) do
			local count = inventory[id]
			local item = VN_INV.Get(id)

			if count and count > 0 and (filter == "" or string.find(string.lower(item.name), filter, 1, true)) then
				used = used + 1

				BuildSlot(grid, item, count, function()
					local menu = DermaMenu()

					if item.OnUse then
						menu:AddOption("Benutzen", function()
							net.Start("vn_inv_use")
							net.WriteString(id)
							net.SendToServer()
						end)
					end

					menu:AddOption("Ablegen", function()
						net.Start("vn_inv_drop")
						net.WriteString(id)
						net.SendToServer()
					end)

					menu:Open()
				end)
			end
		end

		for _ = used + 1, rows * COLUMNS do
			BuildSlot(grid, nil)
		end
	end

	search.OnChange = Refresh
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

-- Kistenmenü -----------------------------------------------------------

net.Receive("vn_inv_crate", function()
	local crate = net.ReadEntity()
	if not IsValid(crate) then return end

	local crateType = VN_INV.CrateType(crate)

	local offered = {}
	for _, id in ipairs(VN_INV.Order) do
		local item = VN_INV.Get(id)
		if item.crate == crateType then
			offered[#offered + 1] = { id = id, item = item }
		end
	end

	local rows = math.max(math.ceil(#offered / COLUMNS), 2)

	local frame = vgui.Create("DFrame")
	frame:SetSize(FrameWidth(), rows * (SLOT + PAD) + 110)
	frame:Center()
	StyleFrame(frame, crate:GetCrateName())

	local status = frame:Add("DPanel")
	status:Dock(TOP)
	status:DockMargin(10, 42, 10, 4)
	status:SetTall(46)

	status.Paint = function(self, w, h)
		if not IsValid(crate) then return end

		local supply = crate:GetSupply()
		local frac = math.Clamp(supply / VN_LOG.MaxSupply, 0, 1)

		local bar = Color(90, 200, 110)
		if supply <= 0 then
			bar = colBad
		elseif frac < 0.3 then
			bar = Color(255, 196, 60)
		end

		draw.SimpleText("Vorrat", "VNINV_Small", 0, 0, colDim)
		draw.SimpleText(supply .. " / " .. VN_LOG.MaxSupply, "VNINV_Small", w, 0, colDim, TEXT_ALIGN_RIGHT)

		draw.RoundedBox(3, 0, 20, w, 12, Color(0, 0, 0, 120))
		draw.RoundedBox(3, 0, 20, w * frac, 12, bar)
	end

	local request = frame:Add("DButton")
	request:Dock(TOP)
	request:DockMargin(10, 0, 10, 4)
	request:SetTall(26)
	request:SetText("Nachschub anfordern")
	request:SetTextColor(colText)
	request.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, self:IsHovered() and colHover or colSlot)
	end
	request.DoClick = function()
		if not IsValid(crate) then frame:Remove() return end

		net.Start("vn_log_request")
		net.WriteEntity(crate)
		net.SendToServer()
	end

	local grid = BuildGrid(frame, 4)

	for _, entry in ipairs(offered) do
		local slot = BuildSlot(grid, entry.item, nil, function()
			if not IsValid(crate) then frame:Remove() return end

			net.Start("vn_inv_take")
			net.WriteEntity(crate)
			net.WriteString(entry.id)
			net.SendToServer()
		end)

		slot:SetTooltip(entry.item.name .. " - " .. entry.item.cost .. " Vorrat")

		slot.PaintOver = function(self, w, h)
			local affordable = IsValid(crate) and crate:GetSupply() >= entry.item.cost
			draw.SimpleText(entry.item.cost, "VNINV_Label", w - 4, 2,
				affordable and colDim or colBad, TEXT_ALIGN_RIGHT)
		end
	end

	for _ = #offered + 1, rows * COLUMNS do
		BuildSlot(grid, nil)
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
