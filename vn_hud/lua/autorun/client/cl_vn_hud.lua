-- VN HUD - Star Wars style cockpit HUD
-- Health, shield, ammo, identity, chronometer and targeting reticle.

if not CLIENT then return end

local DEFAULTS = {
	vn_hud_enable = "1",
	vn_hud_crosshair = "1",
	vn_hud_vitals = "1",
	vn_hud_ammo = "1",
	vn_hud_identity = "1",
	vn_hud_chrono = "1",
	vn_hud_brackets = "1",
	vn_hud_alpha = "215",
	vn_hud_color_r = "255",
	vn_hud_color_g = "158",
	vn_hud_color_b = "44",
}

local ConEnable    = CreateClientConVar("vn_hud_enable", DEFAULTS.vn_hud_enable, true, false, "Star Wars Cockpit HUD an/aus")
local ConCrosshair = CreateClientConVar("vn_hud_crosshair", DEFAULTS.vn_hud_crosshair, true, false, "Eigenes Zielkreuz statt Standard-Fadenkreuz")
local ConVitals    = CreateClientConVar("vn_hud_vitals", DEFAULTS.vn_hud_vitals, true, false, "Vitals-Panel (Health/Shield) anzeigen")
local ConAmmo      = CreateClientConVar("vn_hud_ammo", DEFAULTS.vn_hud_ammo, true, false, "Munitions-Panel anzeigen")
local ConIdentity  = CreateClientConVar("vn_hud_identity", DEFAULTS.vn_hud_identity, true, false, "Namens-/Job-Panel anzeigen")
local ConChrono    = CreateClientConVar("vn_hud_chrono", DEFAULTS.vn_hud_chrono, true, false, "Chronometer anzeigen")
local ConBrackets  = CreateClientConVar("vn_hud_brackets", DEFAULTS.vn_hud_brackets, true, false, "Ecken-Brackets anzeigen")
local ConAlpha     = CreateClientConVar("vn_hud_alpha", DEFAULTS.vn_hud_alpha, true, false, "Deckkraft der Panel-Hintergruende (0-255)")
local ConColR      = CreateClientConVar("vn_hud_color_r", DEFAULTS.vn_hud_color_r, true, false, "Akzentfarbe Rot-Anteil")
local ConColG      = CreateClientConVar("vn_hud_color_g", DEFAULTS.vn_hud_color_g, true, false, "Akzentfarbe Gruen-Anteil")
local ConColB      = CreateClientConVar("vn_hud_color_b", DEFAULTS.vn_hud_color_b, true, false, "Akzentfarbe Blau-Anteil")

local colBG         = Color(8, 12, 18, 215)
local colTrack      = Color(255, 255, 255, 25)
local colBorder     = Color(255, 158, 44, 190)
local colBorderDim  = Color(255, 158, 44, 90)
local colAccent     = Color(255, 158, 44, 255)
local colAccentBlue = Color(88, 172, 255, 255)
local colWarn       = Color(255, 196, 60, 255)
local colDanger     = Color(235, 70, 60, 255)
local colText       = Color(232, 236, 240, 255)
local colTextDim    = Color(150, 162, 176, 255)

local function AccentRGB()
	return math.Clamp(ConColR:GetInt(), 0, 255),
		math.Clamp(ConColG:GetInt(), 0, 255),
		math.Clamp(ConColB:GetInt(), 0, 255)
end

-- The accent colour and panel opacity are user settings, so the shared colour
-- tables are mutated in place instead of being rebuilt for every draw call.
local function RefreshTheme()
	local r, g, b = AccentRGB()

	colAccent.r, colAccent.g, colAccent.b = r, g, b
	colBorder.r, colBorder.g, colBorder.b = r, g, b
	colBorderDim.r, colBorderDim.g, colBorderDim.b = r, g, b
	colBG.a = math.Clamp(ConAlpha:GetInt(), 0, 255)
end

local function CreateHUDFonts()
	surface.CreateFont("VNHUD_Value", { font = "Roboto", size = 32, weight = 800, antialias = true })
	surface.CreateFont("VNHUD_Name",  { font = "Roboto", size = 20, weight = 700, antialias = true })
	surface.CreateFont("VNHUD_Label", { font = "Roboto", size = 13, weight = 600, antialias = true })
	surface.CreateFont("VNHUD_Small", { font = "Roboto", size = 12, weight = 500, antialias = true })
end

CreateHUDFonts()
hook.Add("OnScreenSizeChanged", "vn_hud_refresh_fonts", CreateHUDFonts)

local function CutPanel(x, y, w, h, cut, corner, color)
	local verts

	if corner == "tl" then
		verts = {
			{ x = x + cut, y = y },
			{ x = x + w,   y = y },
			{ x = x + w,   y = y + h },
			{ x = x,       y = y + h },
			{ x = x,       y = y + cut },
		}
	elseif corner == "tr" then
		verts = {
			{ x = x,           y = y },
			{ x = x + w - cut, y = y },
			{ x = x + w,       y = y + cut },
			{ x = x + w,       y = y + h },
			{ x = x,           y = y + h },
		}
	else
		verts = {
			{ x = x + cut,     y = y },
			{ x = x + w - cut, y = y },
			{ x = x + w,       y = y + cut },
			{ x = x + w,       y = y + h },
			{ x = x,           y = y + h },
			{ x = x,           y = y + cut },
		}
	end

	draw.NoTexture()
	surface.SetDrawColor(color)
	surface.DrawPoly(verts)

	return verts
end

local function OutlinePoly(verts, color)
	surface.SetDrawColor(color)

	for i = 1, #verts do
		local a = verts[i]
		local b = verts[i + 1] or verts[1]
		surface.DrawLine(a.x, a.y, b.x, b.y)
	end
end

local function Bar(x, y, w, h, frac, color)
	frac = math.Clamp(frac, 0, 1)

	surface.SetDrawColor(colTrack)
	surface.DrawRect(x, y, w, h)

	surface.SetDrawColor(color)
	surface.DrawRect(x, y, w * frac, h)

	surface.SetDrawColor(255, 255, 255, 20)
	surface.DrawOutlinedRect(x, y, w, h)
end

local function HealthColor(frac)
	if frac > 0.5 then return colAccent end
	if frac > 0.25 then return colWarn end

	return colDanger
end

local function DrawVitals()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local w, h = 280, 94
	local x, y = 22, ScrH() - h - 22

	OutlinePoly(CutPanel(x, y, w, h, 16, "tl", colBG), colBorderDim)
	surface.SetDrawColor(colBorder)
	surface.DrawLine(x, y + 16, x, y + h)
	surface.DrawLine(x, y + h, x + w, y + h)

	draw.SimpleText("VITALS", "VNHUD_Label", x + 16, y + 9, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	local health = math.max(ply:Health(), 0)
	local frac = health / math.max(ply:GetMaxHealth(), 1)

	draw.SimpleText("HP", "VNHUD_Small", x + 16, y + 36, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	Bar(x + 40, y + 34, 140, 14, frac, HealthColor(frac))
	draw.SimpleText(tostring(health), "VNHUD_Value", x + w - 14, y + 26, colText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local armor = math.max(ply:Armor(), 0)

	draw.SimpleText("SH", "VNHUD_Small", x + 16, y + 62, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	Bar(x + 40, y + 61, 140, 10, armor / 100, colAccentBlue)
	draw.SimpleText(tostring(armor), "VNHUD_Label", x + w - 14, y + 58, colTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

local function DrawAmmo()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end

	local clip = wep:Clip1()
	if clip < 0 then return end

	local w, h = 240, 94
	local x, y = ScrW() - w - 22, ScrH() - h - 22

	OutlinePoly(CutPanel(x, y, w, h, 16, "tr", colBG), colBorderDim)
	surface.SetDrawColor(colBorder)
	surface.DrawLine(x + w, y + 16, x + w, y + h)
	surface.DrawLine(x, y + h, x + w, y + h)

	local name = language.GetPhrase(wep:GetPrintName() or "WEAPON")

	draw.SimpleText(string.upper(name), "VNHUD_Label", x + w - 14, y + 9, colTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText(tostring(clip), "VNHUD_Value", x + w - 14, y + 28, colText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText("/ " .. ply:GetAmmoCount(wep:GetPrimaryAmmoType()), "VNHUD_Label", x + w - 14, y + 66, colTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local maxClip = wep:GetMaxClip1()
	if maxClip > 0 then
		local frac = clip / maxClip
		draw.SimpleText("MAG", "VNHUD_Small", x + 16, y + 66, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		Bar(x + 48, y + 68, w - 150, 10, frac, frac > 0.25 and colAccent or colDanger)
	end
end

local function DrawIdentity()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local w, h = 320, 44
	local x, y = ScrW() * 0.5 - w * 0.5, 18

	OutlinePoly(CutPanel(x, y, w, h, 14, "top", colBG), colBorderDim)

	draw.SimpleText(ply:Nick(), "VNHUD_Name", ScrW() * 0.5, y + 5, colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(string.upper(team.GetName(ply:Team())), "VNHUD_Small", ScrW() * 0.5, y + 27, team.GetColor(ply:Team()), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local function DrawChrono()
	local w, h = 150, 44
	local x, y = ScrW() - w - 22, 18

	OutlinePoly(CutPanel(x, y, w, h, 14, "tr", colBG), colBorderDim)

	draw.SimpleText("STANDARD TIME", "VNHUD_Small", x + w - 14, y + 8, colTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText(os.date("%H:%M:%S"), "VNHUD_Label", x + w - 14, y + 24, colText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

local function DrawBrackets()
	local size, thick, inset = 26, 2, 10
	local w, h = ScrW(), ScrH()

	surface.SetDrawColor(colBorderDim)

	surface.DrawRect(inset, inset, size, thick)
	surface.DrawRect(inset, inset, thick, size)

	surface.DrawRect(w - inset - size, inset, size, thick)
	surface.DrawRect(w - inset - thick, inset, thick, size)

	surface.DrawRect(inset, h - inset - thick, size, thick)
	surface.DrawRect(inset, h - inset - size, thick, size)

	surface.DrawRect(w - inset - size, h - inset - thick, size, thick)
	surface.DrawRect(w - inset - thick, h - inset - size, thick, size)
end

local function DrawReticle()
	if not ConCrosshair:GetBool() then return end

	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then return end
	if not IsValid(ply:GetActiveWeapon()) then return end

	local cx, cy = ScrW() * 0.5, ScrH() * 0.5
	local gap, len = 6, 8

	surface.SetDrawColor(colAccent)
	surface.DrawLine(cx - gap - len, cy, cx - gap, cy)
	surface.DrawLine(cx + gap, cy, cx + gap + len, cy)
	surface.DrawLine(cx, cy - gap - len, cx, cy - gap)
	surface.DrawLine(cx, cy + gap, cx, cy + gap + len)
end

-- A default element only stays hidden while the panel that replaces it is on,
-- so switching a panel off leaves the player with a readout rather than none.
local replacedBy = {
	CHudHealth = ConVitals,
	CHudBattery = ConVitals,
	CHudAmmo = ConAmmo,
	CHudSecondaryAmmo = ConAmmo,
	CHudCrosshair = ConCrosshair,
}

hook.Add("HUDShouldDraw", "vn_hud_hide_default", function(name)
	if not ConEnable:GetBool() then return end

	local replacement = replacedBy[name]
	if replacement and replacement:GetBool() then return false end
end)

hook.Add("HUDPaint", "vn_hud_draw", function()
	if not ConEnable:GetBool() then return end

	RefreshTheme()

	if ConBrackets:GetBool() then DrawBrackets() end
	if ConVitals:GetBool() then DrawVitals() end
	if ConAmmo:GetBool() then DrawAmmo() end
	if ConIdentity:GetBool() then DrawIdentity() end
	if ConChrono:GetBool() then DrawChrono() end

	DrawReticle()
end)

concommand.Add("vn_hud_reset", function()
	for name, value in pairs(DEFAULTS) do
		RunConsoleCommand(name, value)
	end
end, nil, "Setzt alle HUD-Einstellungen auf die Standardwerte zurueck")

hook.Add("PopulateToolMenu", "vn_hud_settings", function()
	spawnmenu.AddToolMenuOption("Options", "VN HUD", "vn_hud_options", "Einstellungen", "", "", function(panel)
		panel:ClearControls()

		panel:CheckBox("HUD aktivieren", "vn_hud_enable")
		panel:CheckBox("Eigenes Zielkreuz", "vn_hud_crosshair")

		panel:Help("Panels")
		panel:CheckBox("Vitals (unten links)", "vn_hud_vitals")
		panel:CheckBox("Munition (unten rechts)", "vn_hud_ammo")
		panel:CheckBox("Name / Job (oben mittig)", "vn_hud_identity")
		panel:CheckBox("Chronometer (oben rechts)", "vn_hud_chrono")
		panel:CheckBox("Ecken-Brackets", "vn_hud_brackets")

		panel:Help("Darstellung")
		panel:NumSlider("Deckkraft", "vn_hud_alpha", 0, 255, 0)

		panel:Help("Akzentfarbe")

		local mixer = vgui.Create("DColorMixer")
		mixer:SetTall(160)
		mixer:SetPalette(true)
		mixer:SetAlphaBar(false)
		mixer:SetWangs(true)
		mixer:SetColor(Color(AccentRGB()))

		function mixer:ValueChanged(col)
			if col.r ~= ConColR:GetInt() then RunConsoleCommand("vn_hud_color_r", col.r) end
			if col.g ~= ConColG:GetInt() then RunConsoleCommand("vn_hud_color_g", col.g) end
			if col.b ~= ConColB:GetInt() then RunConsoleCommand("vn_hud_color_b", col.b) end
		end

		panel:AddItem(mixer)
		panel:Button("Alles zuruecksetzen", "vn_hud_reset")
	end)
end)
