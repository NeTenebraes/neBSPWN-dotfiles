local GRID_X     = 230
local GRID_MEM   = 340
local BOX_WIDTH  = 48

local frames = {
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
    local t = os.time()
    local idx = (t % #frames) + 1
    return frames[idx]
end

function conky_col()
    return "${goto " .. GRID_X .. "}"
end

function conky_draw_proc_boxed(n)
    local border = "${color1}│${color}"
    local name = conky_parse("${top name " .. n .. "}"):sub(1,15)
    local cpu  = conky_parse("${top cpu " .. n .. "}")
    local mem  = conky_parse("${top mem " .. n .. "}")
    local content = string.format(" %-15s %10s%% %10s%%", name:upper(), cpu, mem)
    local padding = BOX_WIDTH - #content - 1
    if padding < 0 then padding = 0 end
    return border .. "${color}" .. content .. string.rep(" ", padding) .. "${color1}│"
end

function conky_draw_box_header()
    local border = "${color1}│${color}"
    local title = string.format(" %-15s %10s  %10s", "NAME", "CPU%", "MEM%")
    local padding = BOX_WIDTH - #title - 1
    return border .. "${color2}" .. title .. string.rep(" ", padding) .. "${color1}│"
end

function conky_draw_box_border(type)
    local color1 = "${color1}"
    local horiz = "─"
    if type == "top" then
        return color1 .. "┌" .. horiz .. " PROCESSES " .. string.rep(horiz, BOX_WIDTH - 13) .. "┐"
    elseif type == "bottom" then
        return color1 .. "└" .. string.rep(horiz, BOX_WIDTH - 1) .. "┘"
    end
end

function conky_draw_net_speed()
    local handle = io.popen("ip route get 1.1.1.1 2>/dev/null | awk '{print $5; exit}'")
    local iface = handle:read("*a"):gsub("\n", ""):gsub("^%s*(.-)%s*$", "%1")
    handle:close()
    if iface == "" or iface == nil then 
        return "${color2}DOWN   :: ${color}0B ${goto " .. GRID_X .. "}${color2}UP       :: ${color}0B" 
    end
    return conky_parse(string.format("${color2}DOWN   :: ${color}${downspeed %s} ${goto %d}${color2}UP       :: ${color}${upspeed %s}", iface, GRID_X, iface))
end

function conky_draw_bar(percent_expr, len_expr)
    local percent = tonumber(conky_parse(percent_expr)) or 0
    local l = tonumber(len_expr) or 20
    local filled_len = math.floor((percent / 100) * l)
    filled_len = math.max(0, math.min(filled_len, l))
    return string.rep("█", filled_len) .. string.rep("·", l - filled_len)
end

function conky_draw_storage()
    local handle = io.popen("lsblk -rno MOUNTPOINT,SIZE,FSUSE%,FSTYPE | grep '^/'")
    local result = handle:read("*a")
    handle:close()
    local output = ""
    local disks = {}
    for line in result:gmatch("[^\r\n]+") do
        local parts = {}
        for part in line:gmatch("%S+") do table.insert(parts, part) end
        if #parts >= 4 then
            table.insert(disks, { mount = parts[1], fstype = parts[4], label = parts[1] == "/" and "ROOT" or parts[1]:match("([^/]+)$"):upper() })
        end
    end
    for i = 1, #disks, 2 do
        local d1 = disks[i]
        local d2 = disks[i+1]
        output = output .. string.format("${color2}%s ${color3}%s${color}", d1.label:sub(1,4), d1.fstype:upper()) .. " ${fs_used " .. d1.mount .. "}/${fs_size " .. d1.mount .. "}"
        if d2 then
            output = output .. "${goto " .. GRID_X .. "}" .. string.format("${color2}%s ${color3}%s${color}", d2.label:sub(1,4), d2.fstype:upper()) .. " ${fs_used " .. d2.mount .. "}/${fs_size " .. d2.mount .. "}"
        end
        output = output .. "\n${color1}" .. conky_draw_bar("${fs_used_perc " .. d1.mount .. "}", 18)
        if d2 then
            output = output .. "${goto " .. GRID_X .. "}" .. conky_draw_bar("${fs_used_perc " .. d2.mount .. "}", 18)
        end
        output = output .. "${color}\n\n"
    end
    return conky_parse(output)
end

function conky_check_fw()
    local handle = io.popen("systemctl is-active ufw 2>/dev/null")
    local result = handle:read("*a"):gsub("\n", ""):gsub("^%s*(.-)%s*$", "%1")
    handle:close()
    if result == "active" then return "${color}PROTECTED" end
    return "${color3}DISABLED${color}"
end

function conky_check_vpn()
    local handle = io.popen("ip addr | grep -E 'tun|wg|tap|mullvad' | grep 'state UP' | wc -l")
    local result = tonumber(handle:read("*a"))
    handle:close()
    if result and result > 0 then return "${color}ACTIVE" end
    return "${color3}INACTIVE${color}"
end

function conky_get_ping()
    local handle = io.popen("ping -c 1 1.1.1.1 | grep 'time=' | awk -F'=' '{print $4}'")
    local result = handle:read("*a"):gsub("\n", "")
    handle:close()
    return result == "" and "N/A" or result
end

function conky_get_ssh()
    local handle = io.popen("ss -tnp | grep -c ':22'")
    local result = handle:read("*a"):gsub("\n", "")
    handle:close()
    return result
end