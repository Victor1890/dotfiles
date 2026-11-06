-- Los TUIs flotantes (btop, bluetui, impala, wiremix, lazydocker...) tienen tamaño fijo en
-- píxeles: 875x600 por defecto en Omarchy (default/hypr/apps/system.lua). Con la fuente a
-- 16px la rejilla encogía a ~65x19; subimos el tamaño para recuperar ~80x24.
o.window({ tag = "floating-window" }, { size = { 1080, 760 } })

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.
