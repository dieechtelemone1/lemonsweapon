-- Star Wars Cockpit HUD
-- Health, shield, ammo, identity, chronometer and targeting reticle.

if not CLIENT then return end

local ConEnable    = CreateClientConVar("sw_hud_enable", "1", true, false, "Star Wars Cockpit HUD an/aus")
local ConCrosshair = CreateClientConVar("sw_hud_crosshair", "1", true, false, "Eigenes Zielkreuz statt Standard-Fadenkreuz")

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

local function CreateHUDFonts()
	surface.CreateFont("SWHUD_Value", { font = "Roboto", size = 32, weight = 800, antialias = true })
	surface.CreateFont("SWHUD_Name",  { font = "Roboto", size = 20, weight = 700, antialias = true })
	surface.CreateFont("SWHUD_Label", { font = "Roboto", size = 13, weight = 600, antialias = true })
	surface.CreateFont("SWHUD_Small", { font = "Roboto", size = 12, weight = 500, antialias = true })
end

CreateHUDFonts()
hook.Add("OnScreenSizeChanged", "sw_hud_refresh_fonts", CreateHUDFonts)

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

	draw.SimpleText("VITALS", "SWHUD_Label", x + 16, y + 9, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	local health = math.max(ply:Health(), 0)
	local frac = health / math.max(ply:GetMaxHealth(), 1)

	draw.SimpleText("HP", "SWHUD_Small", x + 16, y + 36, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	Bar(x + 40, y + 34, 140, 14, frac, HealthColor(frac))
	draw.SimpleText(tostring(health), "SWHUD_Value", x + w - 14, y + 26, colText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local armor = math.max(ply:Armor(), 0)

	draw.SimpleText("SH", "SWHUD_Small", x + 16, y + 62, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	Bar(x + 40, y + 61, 140, 10, armor / 100, colAccentBlue)
	draw.SimpleText(tostring(armor), "SWHUD_Label", x + w - 14, y + 58, colTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
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

	draw.SimpleText(string.upper(name), "SWHUD_Label", x + w - 14, y + 9, colTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText(tostring(clip), "SWHUD_Value", x + w - 14, y + 28, colText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText("/ " .. ply:GetAmmoCount(wep:GetPrimaryAmmoType()), "SWHUD_Label", x + w - 14, y + 66, colTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

	local maxClip = wep:GetMaxClip1()
	if maxClip > 0 then
		local frac = clip / maxClip
		draw.SimpleText("MAG", "SWHUD_Small", x + 16, y + 66, colTextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		Bar(x + 48, y + 68, w - 150, 10, frac, frac > 0.25 and colAccent or colDanger)
	end
end

local function DrawIdentity()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local w, h = 320, 44
	local x, y = ScrW() * 0.5 - w * 0.5, 18

	OutlinePoly(CutPanel(x, y, w, h, 14, "top", colBG), colBorderDim)

	draw.SimpleText(ply:Nick(), "SWHUD_Name", ScrW() * 0.5, y + 5, colText, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(string.upper(team.GetName(ply:Team())), "SWHUD_Small", ScrW() * 0.5, y + 27, team.GetColor(ply:Team()), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local function DrawChrono()
	local w, h = 150, 44
	local x, y = ScrW() - w - 22, 18

	OutlinePoly(CutPanel(x, y, w, h, 14, "tr", colBG), colBorderDim)

	draw.SimpleText("STANDARD TIME", "SWHUD_Small", x + w - 14, y + 8, colTextDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	draw.SimpleText(os.date("%H:%M:%S"), "SWHUD_Label", x + w - 14, y + 24, colText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
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

local hidden = {
	CHudHealth = true,
	CHudBattery = true,
	CHudAmmo = true,
	CHudSecondaryAmmo = true,
}

hook.Add("HUDShouldDraw", "sw_hud_hide_default", function(name)
	if not ConEnable:GetBool() then return end

	if hidden[name] then return false end
	if name == "CHudCrosshair" and ConCrosshair:GetBool() then return false end
end)

hook.Add("HUDPaint", "sw_hud_draw", function()
	if not ConEnable:GetBool() then return end

	DrawBrackets()
	DrawVitals()
	DrawAmmo()
	DrawIdentity()
	DrawChrono()
	DrawReticle()
end)
