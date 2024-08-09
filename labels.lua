arkadia_findme.labels = arkadia_findme.labels or {
    state = false,
    handler_data = nil,
    magic_popup = "",
    mydb = nil,
    magic_nodes = {},
    magic_nodes_names = {},
    magic_multinodes = {},
    magic_movers = {},
    magic_paths = {},
    visited_nodes = {},
    coloring=false,
    party = 1,
    magic_data = false,
    timer = nil
}

function arkadia_findme.labels:init()
    db:create("magiclabels", {labels={"id","name","type","zone","date","author","description", "partysize"}})
    arkadia_findme.labels.mydb = db:get_database("magiclabels")
    arkadia_findme.labels.handler_data  = scripts.event_register:register_singleton_event_handler(arkadia_findme.labels.handler_data, "amapCompassDrawingDone", function() arkadia_findme.labels:do_move() end)
    arkadia_findme.labels:createMagicAlias()
end

function arkadia_findme.labels:load_magic_nodes()
    local results = db:fetch(arkadia_findme.labels.mydb.labels, db:AND(
        db:eq(arkadia_findme.labels.mydb.labels.zone, amap.curr.area),
        db:OR(
            db:eq(arkadia_findme.labels.mydb.labels.type, 10),
            db:eq(arkadia_findme.labels.mydb.labels.type, 9)
        )
    ))
    arkadia_findme.labels.magic_nodes = {}
    if #results < 1 then
        return
    end
    arkadia_findme.labels.magic_nodes_names = {}
    for k, v in pairs(results) do
        arkadia_findme.labels.magic_nodes[results[k].id] = 100
        arkadia_findme.labels.magic_nodes_names[results[k].id] = results[k].name
    end
end

function arkadia_findme.labels:load_magic_multinodes()
    local results = db:fetch(arkadia_findme.labels.mydb.labels,
            db:eq(arkadia_findme.labels.mydb.labels.type, 11)
    )
    arkadia_findme.labels.magic_multinodes = {}
    if #results < 1 then
        return
    end
    for k, v in pairs(results) do
        arkadia_findme.labels.magic_multinodes[results[k].id] = 100
    end
end

function arkadia_findme.labels:hide_nodes()
    for k, v in pairs(arkadia_findme.labels.magic_nodes) do
        unHighlightRoom(k)
    end
end

function arkadia_findme.labels:hide_multinodes()
    for k, v in pairs(arkadia_findme.labels.magic_multinodes) do
        unHighlightRoom(k)
    end
end

function arkadia_findme.labels:load_magic_paths()
    arkadia_findme.labels:clear_magic_paths()

    if table.size(arkadia_findme.labels.magic_nodes) < 1 then
        return
    end
    arkadia_findme.labels.magic_paths = {}
    arkadia_findme.labels.magic_popup = ""

    for k, v in pairs(arkadia_findme.labels.magic_nodes) do
        if arkadia_findme.labels.visited_nodes[tonumber(k)] ~= true then
            getPath(amap.curr.id, k)
            if speedWalkDir and speedWalkDir[1] then
                arkadia_findme.labels.magic_nodes[k] = #speedWalkPath
                if arkadia_findme.labels.magic_nodes[k] < 40 then
                    if arkadia_findme.labels.magic_nodes_names[k] then
                        if not amap.ui["dir_to_fancy_symbol"][speedWalkDir[1]] then
                            amap.ui["dir_to_fancy_symbol"][speedWalkDir[1]] = "X"
                        end
                        arkadia_findme.labels.magic_popup = arkadia_findme.labels.magic_popup .. amap.ui["dir_to_fancy_symbol"][speedWalkDir[1]] .. " " .. string.format("%-3s",#speedWalkPath) .. " " .. arkadia_findme.labels.magic_nodes_names[k] .. "\n"
                    end
                    for kk,vv in pairs(speedWalkPath) do
                        -- dont overwrite nodes with path
                        if not arkadia_findme.labels.magic_nodes[vv] and not arkadia_findme.labels.magic_multinodes[vv] then
                            arkadia_findme.labels.magic_paths[vv] = true
                            highlightRoom(vv, 155, 0, 155, 155, 0, 155, 2, 70, 200)
                        end
                    end
                end
            end
        end
    end
end

function arkadia_findme.labels:map_info()
    return string.format("%s", arkadia_findme.labels.magic_popup)
end

function arkadia_findme.labels:clear_magic_paths()
    for k, v in pairs(arkadia_findme.labels.magic_paths) do
        unHighlightRoom(k)
    end
end


function arkadia_findme.labels:do_move()
    if arkadia_findme.labels.coloring then
        if arkadia_findme.labels.magic_nodes[tostring(amap.curr.id)] or arkadia_findme.labels.magic_multinodes[tostring(amap.curr.id)] then
            arkadia_findme.labels.visited_nodes[amap.curr.id] = true
        end
        arkadia_findme.labels:load_magic_nodes()
        arkadia_findme.labels:load_magic_paths()
    end
end

function arkadia_findme.labels:node_refresher()
    if arkadia_findme.labels.coloring then
        for k, v in pairs(arkadia_findme.labels.magic_multinodes) do
            highlightRoom(k, 200, 100, 0, 200, 100, 0, 3, 70, 200)  -- te zlote
        end
        for k, v in pairs(arkadia_findme.labels.magic_nodes) do
            highlightRoom(k, 255, 0, 255, 255, 0, 255, 3, 50, 230)  -- kluczyki do sciezek
        end
        for k, v in pairs(arkadia_findme.labels.visited_nodes) do
            highlightRoom(k, 70, 30, 0, 70, 30, 0, 3, 70, 150)      -- nadpisujemy wszystko na bury kolor
        end
        arkadia_findme.labels.timer = tempTimer(1, function() arkadia_findme.labels:node_refresher() end)
    end
end

function arkadia_findme.labels:magic_toggle()
    if arkadia_findme.labels.coloring then
        arkadia_findme:debug_print("Wyswietlanie magikow <green>WYLACZONE")
        if arkadia_findme.labels.map_info == true then
            disableMapInfo("MC")
            killMapInfo("MC")
        end
        arkadia_findme.labels.coloring=false
        arkadia_findme.labels:clear_magic_paths()
        arkadia_findme.labels:hide_nodes()
        arkadia_findme.labels:hide_multinodes()
        if arkadia_findme.labels.timer and exists(arkadia_findme.labels.timer, "timer") then killTimer(arkadia_findme.labels.timer) end
    else
        arkadia_findme:debug_print("Wyswietlanie magikow <green>WLACZONE")
        if arkadia_findme.labels.map_info == true then
            registerMapInfo("MC", function() return string.format("%s", arkadia_findme.labels.magic_popup) end)
            enableMapInfo("MC")
        end
        arkadia_findme.labels.coloring=true
        arkadia_findme.labels:load_magic_nodes()
        arkadia_findme.labels:load_magic_paths()
        arkadia_findme.labels:load_magic_multinodes()
        arkadia_findme.labels:show_multinodes()
        arkadia_findme.labels.timer = tempTimer(1, function() arkadia_findme.labels:node_refresher() end)
    end
end

function arkadia_findme.labels:createMagicAlias()
    fmAdd = tempAlias("^/rmagic$", [[arkadia_findme.labels:magic_toggle()]])
end

function arkadia_findme.labels:show_multinodes()
    for k, v in pairs(arkadia_findme.labels.magic_multinodes) do
        highlightRoom(k, 200, 100, 0, 200, 100, 0, 3, 70, 200)
    end
end

function arkadia_findme.labels:show_magic_nodes()
    for k, v in pairs(arkadia_findme.labels.magic_nodes) do
        if arkadia_findme.labels.magic_nodes[k] < 40 then
            highlightRoom(k, 25, 0, 25, 155, 0, 155, 10, 1, 150)
        else
            highlightRoom(k, 70, 0, 70, 70, 0, 70, 10, 10, 200)
        end
    end
end

function arkadia_findme.labels:get_name()
    local results = db:fetch(arkadia_findme.labels.mydb.labels, db:eq(arkadia_findme.labels.mydb.labels.id, amap.curr.id))
    if #results > 0 then
        for k, v in pairs(results) do
            arkadia_findme:debug_print("<reset>" .. results[k].id .. " " .. results[k].name .. " ")
        end
    end
end
tempAlias("^/rmagic_name$", [[arkadia_findme.labels:get_name()]])

function arkadia_findme.labels:fix_zones()
    local results = db:fetch(arkadia_findme.labels.mydb.labels, db:eq(arkadia_findme.labels.mydb.labels.zone, ""))
    if #results == 0 then
        arkadia_findme:debug_print("<tomato>Wszystkie regiony naprawione!")
        return
    end
    arkadia_findme:debug_print("<tomato>Naprawiam pokoje bez regionu: " .. #results)
    for k, v in pairs(results) do
        print(v)
        results[k].zone = getAreaTableSwap()[getRoomArea(results[k].id)]
        db:update(arkadia_findme.labels.mydb.labels, results[k])
    end
end

---------------------------------------------------------
--- EDYCJA
--- -----------------------------------------------------

function arkadia_findme.labels:set_type(typeName)
    local tempType = 9
    if typeName == "chodzi" then tempType = 11 end
    if typeName == "stoi" then tempType = 9 end
    if typeName == "pojawia" then tempType = 10 end

    local results = db:fetch(arkadia_findme.labels.mydb.labels, db:eq(arkadia_findme.labels.mydb.labels.id, amap.curr.id))
    if #results == 0 then
        arkadia_findme:debug_print("Ten pokoj nie ma wpisu ;(")
        return
    end

    for k, v in pairs(results) do
        results[k].type = tempType
        db:update(arkadia_findme.labels.mydb.labels, results[k])
    end
    arkadia_findme:debug_print("Ustawilem nowy typ wpisow!")
end
tempAlias("^/rmagic_typ chodzi$", [[arkadia_findme.labels:set_type("chodzi")]])
tempAlias("^/rmagic_typ stoi$", [[arkadia_findme.labels:set_type("stoi")]])
tempAlias("^/rmagic_typ pojawia$", [[arkadia_findme.labels:set_type("pojawia")]])
function arkadia_findme.labels:add_label(labelDescription)
    -- >:-)
    db:delete(arkadia_findme.labels.mydb.labels, db:eq(arkadia_findme.labels.mydb.labels.id, amap.curr.id))
    db:add(arkadia_findme.labels.mydb.labels, {
        id=amap.curr.id,
        name=labelDescription,
        type=9,
        zone=amap.curr.area,
        date=os.date("%c"),
        author=gmcp.char.info.name,
        description=" "
    })
    arkadia_findme:debug_print("Dodalem wpis o magii...")
end

function arkadia_findme.labels:del_label()
    db:delete(arkadia_findme.labels.mydb.labels, db:eq(arkadia_findme.labels.mydb.labels.id, amap.curr.id))
    arkadia_findme:debug_print("Usunalem wpis o magii...")
end
tempAlias("^/rmagic_del$", [[arkadia_findme.labels:del_label()]])

function arkadia_findme.labels:addfull(_id,_name,_type,_zone,_date,_author,_description)
      db:delete(arkadia_findme.labels.mydb.labels, db:eq(arkadia_findme.labels.mydb.labels.id, id))
      db:add(arkadia_findme.labels.mydb.labels, {
          id=_id,
          name=_name,
          type=_type,
          zone=_zone,
          date=_date,
          author=_author,
          description=_description
        }
      )
      print(_id,_name,_type,_zone,_date,_author,_description)
end

poiCategoryMapping = {
    ["Ekspedycja"] = "8",
    ["Klucze"] = "9",
    ["Biblioteka"] = "7"
}

function arkadia_findme.labels:importPOI()
    if mc.poi.enabled == true then
        for k,v in pairs(mc.poi.pois) do
            if tonumber(poiCategoryMapping[v.category]) then
                arkadia_findme.labels:addfull(
                    v.loc,
                    v.label,
                    poiCategoryMapping[v.category],
                    getRoomAreaName(v.area),
                    os.date("%c"),
                    "Dargoth",
                    "POI import"
                )
            end
        end
    else
        print("POI musi byc wlaczony: /cset! mc.poi.enabled=true")
    end
end

function mc.poi:get_last_kills_longer()
    arkadia_findme.labels.last_check = os.time() - 800000000
    local params = { orderBy = [[%22time%22]], startAt = arkadia_findme.labels.last_check }
    FireBaseClientFactory:getClient():getData("keyMobsKills.json", function(data) arkadia_findme.labels:update_kills(data) end, params)
end

function arkadia_findme.labels:merge_all_poi_data()
    for k, v in pairs(mc.poi.kill_data) do
        local results = db:fetch(arkadia_findme.labels.mydb.labels, db:eq(arkadia_findme.labels.mydb.labels.id, mc.poi.kill_data[k].loc))
        if #results == 0 then
            arkadia_findme.labels:addfull(
                mc.poi.kill_data[k].loc,
                mc.poi.kill_data[k].mob,
                11,
                "",
                os.date("%c"),
                "Dargoth",
                "POI import"
            )
        end
    end
end

arkadia_findme.labels:init()
