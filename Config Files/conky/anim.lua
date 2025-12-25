-- ~/.config/conky/anim.lua
-- Animación: ARCH PULSE (Responsive / Auto-centrado)

local GRID_X     = 230  -- Donde empieza la columna derecha (Host, CPU, etc)
local GRID_MEM   = 340  -- Donde empieza la columna de MEM% (solo para procesos)

local frames = {
-- Frame 1: Apagado (Gris oscuro)
-- Nota: Usamos alignc en CADA línea para que se centre automáticamente
[[
${alignc}${color1}
${alignc}${color2}/\${color}
${alignc}${color2}/  \${color}
${alignc}${color2}/    \${color}
${alignc}${color2}/      \${color}
${alignc}${color2}/   ,,   \${color}
${alignc}${color2}/   |  |   \${color}
${alignc}${color2}/_-''    ''-_\${color}
]],
-- Frame 2: Encendido (Blanco brillante + Acento)
[[
${alignc}${color3}
${alignc}${color3}/\${color}
${alignc}${color3}/  \${color}
${alignc}${color3}/    \${color}
${alignc}${color3}/      \${color}
${alignc}${color3}/   ,,   \${color}
${alignc}${color3}/   |  |   \${color}
${alignc}${color3}/_-''    ''-_\${color}
]]
}

function conky_get_anim()
    local t = 0
    if os and os.time then t = os.time() else
        local s = conky_parse('${time %S}')
        t = tonumber(s) or 0
    end
    local idx = (t % #frames) + 1
    return frames[idx]
end

function conky_col()
    return "${goto " .. GRID_X .. "}"
end

-- Función conky_draw_proc modificada
function conky_draw_proc(n)
    local line = string.format("${top name %d} ${color2}${top pid %d}${color} ${goto %d}${top cpu %d} ${goto %d}${top mem %d}", n, n, GRID_X, n, GRID_MEM, n)
    return conky_parse(line)
end


function conky_draw_proc_header()
    local line = string.format("${color2}NAME ${goto %d}CPU%% ${goto %d}MEM%%${color}", GRID_X + 15, GRID_MEM + 10)
    return conky_parse(line)
end

function conky_draw_net_speed()
    -- 1. Preguntamos al sistema cuál es la interfaz principal (la que tiene ruta a internet)
    -- Usamos 'ip route get 1.1.1.1' que es muy rápido y no genera tráfico real
    local handle = io.popen("ip route get 1.1.1.1 | awk '{print $5; exit}'")
    local iface = handle:read("*a")
    handle:close()
    
    -- Limpiamos el salto de línea que trae el comando
    iface = string.gsub(iface, "\n", "")
    iface = string.gsub(iface, "^%s*(.-)%s*$", "%1")
    
    -- Si no hay interfaz (sin internet), mostramos OFFLINE
    if iface == "" or iface == nil then
        return "${color2}SPEED  :: ${color}OFFLINE"
    end
    
    -- 2. Construimos la línea de Conky dinámicamente usando la interfaz detectada
    -- Usamos downspeed y upspeed con la variable 'iface'
    local output = string.format("${color2}SPEED  :: ${color}▼ ${downspeed %s} ▲ ${upspeed %s}", iface, iface)
    
    return conky_parse(output)
end

function conky_draw_bar(percent_expr, len_expr)
  -- percent_expr viene como texto, por ejemplo "${memperc}"
  local percent = tonumber(conky_parse(percent_expr)) or 0
  local l = tonumber(len_expr) or 20

  local fill_char  = "█"
  local empty_char = "·"

  local filled_len = math.floor((percent / 100) * l)
  if filled_len > l then filled_len = l end
  if filled_len < 0 then filled_len = 0 end

  local empty_len = l - filled_len

  local bar = string.rep(fill_char, filled_len) .. string.rep(empty_char, empty_len)

  return bar
end
