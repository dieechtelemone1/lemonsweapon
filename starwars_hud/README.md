# Star Wars Cockpit HUD

Ein HUD-Ersatz für Garry's Mod im Cockpit-/Sci-Fi-Look.

## Anzeigen

- **Vitals** (unten links): Health-Balken + Zahl, Shield/Armor-Balken + Zahl
- **Munition** (unten rechts): Waffenname, Magazin, Reserve
- **Identität** (oben mittig): Spielername, Job/Team in Teamfarbe (DarkRP-kompatibel)
- **Chronometer** (oben rechts): Uhrzeit
- **Ecken-Brackets** am Bildschirmrand und ein eigenes Zielkreuz

## Installation

Ordner `starwars_hud` nach `garrysmod/addons/` kopieren, GMod neu starten.
Auf einem Server muss das Addon ebenfalls in `garrysmod/addons/` liegen –
die Datei liegt unter `lua/autorun/client/` und wird automatisch an Clients gesendet.

## Konsolenbefehle

| Befehl | Standard | Bedeutung |
| --- | --- | --- |
| `sw_hud_enable 0/1` | `1` | HUD komplett an/aus (aus = Standard-HUD von GMod) |
| `sw_hud_crosshair 0/1` | `1` | Eigenes Zielkreuz statt Standard-Fadenkreuz |

## Anpassen

Farben stehen als `col*`-Variablen oben in
`lua/autorun/client/cl_starwars_hud.lua` – dort lässt sich das Orange
(`colAccent`) z. B. gegen Blau oder Rot tauschen.
