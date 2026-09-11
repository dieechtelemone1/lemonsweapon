# VN HUD

Ein HUD-Ersatz für Garry's Mod im Star-Wars-Cockpit-Look.

## Anzeigen

- **Vitals** (unten links): Health-Balken + Zahl, Shield/Armor-Balken + Zahl
- **Munition** (unten rechts): Waffenname, Magazin + Magazin-Balken, Reserve
- **Identität** (oben mittig): Spielername, Job/Team in Teamfarbe (DarkRP-kompatibel)
- **Chronometer** (oben rechts): Uhrzeit
- **Ecken-Brackets** am Bildschirmrand und ein eigenes Zielkreuz

## Installation

Ordner `vn_hud` nach `garrysmod/addons/` kopieren, GMod neu starten.
Auf einem Server muss das Addon ebenfalls in `garrysmod/addons/` liegen –
die Datei liegt unter `lua/autorun/client/` und wird automatisch an Clients gesendet.

## Einstellungen im Spiel

**Q-Menü → Optionen → VN HUD → Einstellungen**

Dort lassen sich alle Panels einzeln an-/abschalten, die Deckkraft der Panels
einstellen und die Akzentfarbe über einen Farbwähler ändern.

## Konsolenbefehle

| Befehl | Standard | Bedeutung |
| --- | --- | --- |
| `vn_hud_enable 0/1` | `1` | HUD komplett an/aus (aus = Standard-HUD von GMod) |
| `vn_hud_crosshair 0/1` | `1` | Eigenes Zielkreuz statt Standard-Fadenkreuz |
| `vn_hud_vitals 0/1` | `1` | Vitals-Panel unten links |
| `vn_hud_ammo 0/1` | `1` | Munitions-Panel unten rechts |
| `vn_hud_identity 0/1` | `1` | Name/Job oben mittig |
| `vn_hud_chrono 0/1` | `1` | Chronometer oben rechts |
| `vn_hud_brackets 0/1` | `1` | Ecken-Brackets |
| `vn_hud_alpha 0-255` | `215` | Deckkraft der Panel-Hintergründe |
| `vn_hud_color_r/g/b` | `255/158/44` | Akzentfarbe |
| `vn_hud_reset` | – | Alle Einstellungen zurücksetzen |

Wird ein Panel abgeschaltet, blendet das HUD die passende Standard-Anzeige von
GMod wieder ein – man bleibt also nie ganz ohne Anzeige.
