-- VN Logistics - the Navy datapad overview.

local colBG     = Color(12, 16, 22, 245)
local colRow    = Color(255, 255, 255, 12)
local colAccent = Color(255, 158, 44)
local colText   = Color(232, 236, 240)
local colDim    = Color(150, 162, 176)
local colGood   = Color(90, 200, 110)
local colWarn   = Color(255, 196, 60)
local colBad    = Color(235, 70, 60)

local padFrame
local crates = {}

local function SupplyColor(supply)
	local frac = supply / VN_LOG.MaxSupply
	if supply <= 0 then return colBad end
	if frac < 0.3 then return colWarn end
	return colGood
end

local function BuildList(scroll)
	scroll:Clear()

	if #crates == 0 then
		local label = scroll:Add("DLabel")
		label:Dock(TOP)
		label:SetTall(40)
		label:SetFont("VNINV_Item")
		label:SetTextColor(colDim)
		label:SetText("Keine Versorgungskisten auf der Karte.")
		return
	end

	-- Open requests first: the Navy should see what the field is waiting for
	-- without scrolling past the crates that are still stocked.
	table.sort(crates, function(a, b)
		if a.requested ~= b.requested then return a.requested end
		return a.supply < b.supply
	end)

	for _, data in ipairs(crates) do
		local row = scroll:Add("DPanel")
		row:Dock(TOP)
		row:DockMargin(0, 0, 0, 4)
		row:SetTall(62)

		row.Paint = function(self, w, h)
			surface.SetDrawColor(colRow)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(data.requested and colBad or colAccent)
			surface.DrawRect(0, 0, 3, h)

			draw.SimpleText(data.name, "VNINV_Item", 14, 8, colText)

			surface.SetDrawColor(0, 0, 0, 160)
			surface.DrawRect(14, 30, 220, 12)
			surface.SetDrawColor(SupplyColor(data.supply))
			surface.DrawRect(14, 30, 220 * math.Clamp(data.supply / VN_LOG.MaxSupply, 0, 1), 12)

			draw.SimpleText(data.supply .. " / " .. VN_LOG.MaxSupply, "VNINV_Small", 244, 30, colDim)

			if data.eta > 0 then
				draw.SimpleText("Lieferung unterwegs - " .. data.eta .. "s", "VNINV_Small", 14, 46, colWarn)
			elseif data.requested then
				draw.SimpleText("Angefordert von " .. data.requester, "VNINV_Small", 14, 46, colBad)
			end
		end

		local button = row:Add("DButton")
		button:Dock(RIGHT)
		button:DockMargin(0, 12, 10, 12)
		button:SetWide(100)
		button:SetText(data.eta > 0 and "unterwegs" or "Liefern")
		button:SetTextColor(colText)
		button:SetEnabled(data.eta <= 0)
		button.Paint = function(self, w, h)
			local col = Color(255, 255, 255, 25)
			if not self:IsEnabled() then
				col = Color(255, 255, 255, 10)
			elseif self:IsHovered() then
				col = colAccent
			end

			surface.SetDrawColor(col)
			surface.DrawRect(0, 0, w, h)
		end
		button.DoClick = function()
			if not IsValid(data.entity) then return end

			net.Start("vn_log_deliver")
			net.WriteEntity(data.entity)
			net.SendToServer()
		end
	end
end

net.Receive("vn_log_open", function()
	if IsValid(padFrame) then padFrame:Remove() end

	local frame = vgui.Create("DFrame")
	frame:SetSize(560, 560)
	frame:Center()
	frame:SetTitle("")
	frame:MakePopup()
	padFrame = frame

	frame.Paint = function(self, w, h)
		surface.SetDrawColor(colBG)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(colAccent)
		surface.DrawRect(0, 0, w, 2)
		draw.SimpleText("Logistik-Datapad", "VNINV_Title", 16, 12, colText)
		draw.SimpleText("Nachschub-Übersicht aller Versorgungskisten", "VNINV_Small", 16, 38, colDim)
	end

	local scroll = frame:Add("DScrollPanel")
	scroll:Dock(FILL)
	scroll:DockMargin(12, 62, 12, 12)
	frame.list = scroll

	BuildList(scroll)

	timer.Create("vn_log_pad_refresh", 2, 0, function()
		if not IsValid(padFrame) then
			timer.Remove("vn_log_pad_refresh")
			return
		end

		net.Start("vn_log_refresh")
		net.SendToServer()
	end)
end)

net.Receive("vn_log_data", function()
	crates = {}

	for _ = 1, net.ReadUInt(8) do
		crates[#crates + 1] = {
			entity = net.ReadEntity(),
			name = net.ReadString(),
			supply = net.ReadUInt(16),
			requested = net.ReadBool(),
			requester = net.ReadString(),
			eta = net.ReadUInt(16),
		}
	end

	if IsValid(padFrame) and IsValid(padFrame.list) then
		BuildList(padFrame.list)
	end
end)
