-- ~/.config/conky/anim.lua
-- Animación: ARCH PULSE (Centrado)

local frames = {
-- Frame 1: Apagado (Gris oscuro)
[[
${color1}                                                     ${color}
${color2}                                   /\                  ${color}
${color2}                                  /  \                 ${color}
${color2}                                 /    \                ${color}
${color2}                                /      \               ${color}
${color2}                               /   ,,   \              ${color}
${color2}                              /   |  |   \             ${color}
${color2}                             /_-''    ''-_\            ${color}
]],
-- Frame 2: Encendido (Blanco brillante + Acento)
[[
${color3}                                                     ${color}
${color3}                                   /\                  ${color}
${color3}                                  /  \                 ${color}
${color3}                                 /    \                ${color}
${color3}                                /      \               ${color}
${color3}                               /   ,,   \              ${color}
${color3}                              /   |  |   \             ${color}
${color3}                             /_-''    ''-_\            ${color}
]]
}

function conky_get_anim()
    local t = 0
    if os and os.time then t = os.time() else
        local s = conky_parse('${time %S}')
        t = tonumber(s) or 0
    end
    
    -- Cambio cada segundo (Efecto latido lento)
    local idx = (t % #frames) + 1
    return frames[idx]
end

-- En anim.lua
function conky_draw_proc(n)
    -- AJUSTE DE POSICIÓN: Mover todo a la derecha
    local col_cpu = 400  -- Antes estaba en ~280/320. Ahora en 400 (alineado con el eje central)
    local col_mem = 500  -- Antes en 420. Ahora en 550 (bien a la derecha)
    
    local line = string.format("${top name %d} ${goto %d}${top cpu %d} ${goto %d}${top mem %d}", n, col_cpu, n, col_mem, n)
    return conky_parse(line)
end

function conky_draw_proc_header()
    -- IMPORTANTE: Usar los mismos valores que arriba
    local col_cpu = 400
    local col_mem = 500
    local line = string.format("${color2}NAME ${goto %d}CPU%% ${goto %d}MEM%%${color}", col_cpu, col_mem)
    return conky_parse(line)
end

