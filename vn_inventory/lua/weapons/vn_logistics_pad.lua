SWEP.Base = "weapon_base"

SWEP.PrintName = "Logistik-Datapad"
SWEP.Author = "VN"
SWEP.Purpose = "Übersicht über alle Versorgungskisten und offenen Anforderungen."
SWEP.Instructions = "Linksklick öffnet das Datapad."
SWEP.Category = "VN"

-- Nur im Spawnmenü eingeschränkt; per Job-Loadout gegeben funktioniert es für
-- jeden, die Berechtigung prüft ohnehin der Server beim Öffnen.
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 1)

	if not SERVER then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	VN_LOG.OpenPad(owner)
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end
