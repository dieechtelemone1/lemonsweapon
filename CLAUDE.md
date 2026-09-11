# Projekt-Konventionen

## Garry's Mod Addons

Jedes GMod-Addon in diesem Repo bekommt das Präfix `vn_`:

- Addon-Ordner: `vn_<name>` (z. B. `vn_hud`)
- Lua-Dateien: `cl_vn_<name>.lua`, `sv_vn_<name>.lua`, `sh_vn_<name>.lua`
- ConVars und Konsolenbefehle: `vn_<name>_<option>` (z. B. `vn_hud_enable`)
- Font- und Hook-Namen: ebenfalls `vn_`- bzw. `VNHUD_`-Präfix, damit nichts mit
  anderen Addons kollidiert

Keine `README.md` und keine `addon.json` in neuen Addons anlegen – nur die
Lua-Dateien.
