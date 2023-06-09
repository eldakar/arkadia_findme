arkadia_findme = arkadia_findme or {
    state = {},
    handler_data = nil,
    pre_zlok_room = 0,
    mydb = nil
}
--findme.highlight_current_room
--findme.search_depth
function arkadia_findme:createHelpAlias()
    fmHelp = tempAlias("^/findme$", [[
        cecho("<gray>+------------------------------------------------------------+<reset>\n")
        cecho("<gray>|  <yellow>                   .: Baza lokacji :.                     <gray>|<reset>\n")
        cecho("<gray>|                                                            |<reset>\n")
        cecho("<gray>|  - rozszerzone odnajdywanie sie na mapce                   |<reset>\n")
        cecho("<gray>|  - mozliwosc dodawania lokacji w trakcie gry               |<reset>\n")
        cecho("<gray>|  - wyszukiwanie lokacji w poblizu zgubienia sie            |<reset>\n")
        cecho("<gray>|  - rozpoznawanie czy postac sie zgubila                    |<reset>\n")
        cecho("<gray>|  - wyswietlanie stanu pokoju na mapce                      |<reset>\n")
        cecho("<gray>|  - (wylaczone) heatmap opisania regionu                    |<reset>\n")
        cecho("<gray>|                                                            |<reset>\n")
        cecho("<gray>|  <yellow>Aliasy                                                    <gray>|<reset>\n")
        cecho("<gray>|  <white>/findme<reset> - ta pomoc                                        |<reset>\n")
        cecho("<gray>|  <white>/rinfo<reset>  - wyswietla stan opisania pokoju                  |<reset>\n")
        cecho("<gray>|  <green>/zlok<reset>   - podmieniony alias mudleta, korzysta z tej bazy  |<reset>\n")
        cecho("<gray>|  <green>/wroc<reset>   - cofa mapke do lokacji w ktorej uzylismy /zlok   |<reset>\n")
        cecho("<gray>|  <red>/radd<reset>   - dodaje opis pokoju do bazy, nadpisuje poprzedni |<reset>\n")
        cecho("<gray>|  <red>/rwipe<reset>  - usuwa wszystkie wpisy pokoju                    |<reset>\n")
        cecho("<gray>|                                                            |<reset>\n")
        cecho("<gray>|  <yellow>Opcje                                                     <gray>|<reset>\n")
        cecho("<gray>|  <light_slate_blue>arkadia_findme.highlight_current_room = true/false        <reset>|<reset>\n")
        cecho("<gray>|            czy kolorowac stan zapisu pokoju na mapce       |<reset>\n")
        cecho("<gray>|  <light_slate_blue>arkadia_findme.search_depth = 0 do 4                      <reset>|<reset>\n")
        cecho("<gray>|            Ustaw poziom wymaganych informacji              |<reset>\n")    
        cecho("<gray>|            0 - short + exits + region + pora roku + dzien  |<reset>\n")
        cecho("<gray>|            1 - short + exits + region                      |<reset>\n")
        cecho("<gray>|            2 - short + region                              |<reset>\n")
        cecho("<gray>|            3 - short + exits                               |<reset>\n")
        cecho("<gray>|            4 - short                                       |<reset>\n")
        cecho("<gray>|  <light_slate_blue>arkadia_findme.debug_enabled = true/false                 <reset>|<reset>\n")
        cecho("<gray>|            wyswietlaj liczbe wynikow dla kazdego poziomu   |<reset>\n")
        cecho("<gray>+------------------------------------------------------------+<reset>\n")
    ]])
end

function arkadia_findme:calculate_distance(room_from, room_to)
    local ret = 0

end

function arkadia_findme:wipe_room()
    local test_room = arkadia_findme:get_color()
    if test_room > 0 then
        local results = db:delete(self.mydb.locations, db:AND(
            db:eq(self.mydb.locations.room_id, amap.curr.id)
        ))
        return true
    end
    return false
end
function arkadia_findme:createWipeAlias()
    fmWipe = tempAlias("^/rwipe$", [[if arkadia_findme:wipe_room() then cecho("\n<CadetBlue>(skrypty):<green>(findme) Usunalem wszystkie wpisy tego pokoju.\n") end]])
end

function arkadia_findme:show_room()
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.room_id, amap.curr.id)
    ))

    if results == 0 then
        cecho("\n<CadetBlue>(skrypty):<green>(findme) Room Info : <yellow>" .. amap.curr.id .. "<green> wyglada na pusty ;(<reset>")
        return
    end

    cecho("\n<CadetBlue>(skrypty):<green>(findme) Room Info : <yellow>" .. amap.curr.id .. "<reset>")
    for k, v in pairs(results) do
        cecho("\n<white>" .. results[k].created_on .. " <gray>S/D: <light_slate_blue>" .. results[k].season .. " / " .. results[k].daylight .. "<reset>")
        cecho("\n  <CornflowerBlue>" .. results[k].short .. "<reset>")
        cecho("\n  <green>" .. results[k].exits .. "<reset>")
    end
    echo("\n")
end
function arkadia_findme:createInfoAlias()
    fmInfo = tempAlias("^/rinfo$", [[arkadia_findme:show_room()]])
end

function arkadia_findme:add()
    if not ateam.objs[ateam.my_id].can_see_in_room or ateam.objs[ateam.my_id].editing or ateam.objs[ateam.my_id].paralyzed then
        cecho("\n<CadetBlue>(skrypty)<tomato>: <red>Postac nie jest gotowa...\n")
        return
    end
    local test_room = arkadia_findme:get_color()
    if test_room == 2 then
        cecho("\n<CadetBlue>(skrypty)<tomato>: Ten pokoj juz istnieje w bazie, nadpisuje.\n")
        local results = db:delete(self.mydb.locations, db:AND(
            db:eq(self.mydb.locations.room_id, amap.curr.id),
            db:eq(self.mydb.locations.season, gmcp.room.time.season),
            db:eq(self.mydb.locations.daylight, tostring(gmcp.room.time.daylight))
        ))
    end

    if amap.localization.current_exit == "" then
        cecho("\n<CadetBlue>(skrypty)<tomato>: Nie mozna dodac pokoju bez widocznych wyjcs!\n")
        return
    end

    if gmcp.room.info.map then
        db:add(self.mydb.locations, {
            room_id=amap.curr.id,
            region=getAreaTableSwap()[getRoomArea(amap.curr.id)],
            area=gmcp.room.info.map.name,
            x=gmcp.room.info.map.x,
            y=gmcp.room.info.map.y,
            daylight=tostring(gmcp.room.time.daylight),
            season=gmcp.room.time.season,
            short=amap.localization.current_short,
            exits=amap.localization.current_exit,
            created_on=os.date("%c"),
            created_by=ateam.options.own_name
        })
        cecho("\n<CadetBlue>(skrypty)<tomato>: Dodalem lokacje GMCP!\n")
        arkadia_findme:set_location_color()
    else
        db:add(self.mydb.locations, {
            room_id=amap.curr.id,
            region=getAreaTableSwap()[getRoomArea(amap.curr.id)],
            area="",
            x="",
            y="",
            daylight=tostring(gmcp.room.time.daylight),
            season=gmcp.room.time.season,
            short=amap.localization.current_short,
            exits=amap.localization.current_exit,
            created_on=os.date("%c"),
            created_by=ateam.options.own_name
        })
        cecho("\n<CadetBlue>(skrypty)<tomato>: Dodalem lokacje bez GMCP!\n")
        arkadia_findme:set_location_color()
    end
end
function arkadia_findme:createAddAlias()
    fmAdd = tempAlias("^/radd$", [[arkadia_findme:add()]])
end

-- 0 - none
-- 1 - some, not current
-- 2 - current
function arkadia_findme:get_color()
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.room_id, amap.curr.id),
        db:eq(self.mydb.locations.season, gmcp.room.time.season),
        db:eq(self.mydb.locations.daylight, tostring(gmcp.room.time.daylight))
    ))

    if #results >= 1 then
        return 2
    end

    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.room_id, amap.curr.id)
    ))

    if #results >= 1 then
        return 1
    end

    return 0
end

function arkadia_findme:set_location_color()
    if arkadia_findme.highlight_current_room then
        local location_color = {
            [0] = {150, 50, 50, 50, 50, 50, 2.2, 100, 100},
            [1] = {150, 150, 50, 50, 50, 50, 1.7, 100, 100},
            [2] = {50, 150, 50, 50, 50, 50, 1.9, 100, 100}
        }
        local location_color_value = arkadia_findme:get_color()

        highlightRoom(
            amap.curr.id,
            location_color[location_color_value][1],
            location_color[location_color_value][2],
            location_color[location_color_value][3],
            location_color[location_color_value][4],
            location_color[location_color_value][5],
            location_color[location_color_value][6],
            location_color[location_color_value][7],
            location_color[location_color_value][8],
            location_color[location_color_value][9]
        )
    end
end

function arkadia_findme:debug_print(text)
    if arkadia_findme.debug_enabled then
        cecho("\n<CadetBlue>(skrypty):<green>(findme) " .. text)
    end
end

-- room_id - amap.curr.id
-- region - getAreaTableSwap()[getRoomArea(14608)]
-- area - gmcp.room.info.map.name
-- daylight - gmcp.room.time.daylight = false
-- season - gmcp.room.time.season (0,1,2,3)
-- short - amap.localization.current_short
-- exits - amap.localization.current_exit
function arkadia_findme:findme()
    if gmcp.room.time.season == nil then
        return false
    end
    -- depth negative : sanity check 
    -- depth 1.1 : match distinct by short + exits, within the mudlet map region
    local results = db:fetch_sql(arkadia_findme.mydb.locations, "select distinct room_id, short, exits, region from locations where short = \"" .. amap.localization.current_short .. "\" and exits = \"" .. amap.localization.current_exit .. "\" and region = \"" .. getAreaTableSwap()[getRoomArea(amap.curr.id)] .. "\" and room_id = " .. amap.curr.id)

    arkadia_findme:debug_print("----: ROOM : <red>" .. #results .. " ")
    if #results == 1 then
        --amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 0 : exact match
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.season, gmcp.room.time.season),
        db:eq(self.mydb.locations.daylight, tostring(gmcp.room.time.daylight)),
        db:eq(self.mydb.locations.short, amap.localization.current_short),
        db:eq(self.mydb.locations.exits, amap.localization.current_exit)
    ))

    arkadia_findme:debug_print("D0  : SDSE : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 1 : match by short + exits, within the mudlet map region
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.region, getAreaTableSwap()[getRoomArea(amap.curr.id)]),
        db:eq(self.mydb.locations.short, amap.localization.current_short),
        db:eq(self.mydb.locations.exits, amap.localization.current_exit)
    ))

    arkadia_findme:debug_print("D1  : -RSE : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 1.1 : match distinct by short + exits, within the mudlet map region
    local results = db:fetch_sql(arkadia_findme.mydb.locations, "select distinct room_id, short, exits, region from locations where short = \"" .. amap.localization.current_short .. "\" and exits = \"" .. amap.localization.current_exit .. "\" and region = \"" .. getAreaTableSwap()[getRoomArea(amap.curr.id)] .. "\"")

    arkadia_findme:debug_print("D1.1: -RSE : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 2 : match by short, within the mudlet map region
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.region, getAreaTableSwap()[getRoomArea(amap.curr.id)]),
        db:eq(self.mydb.locations.short, amap.localization.current_short)
    ))

    arkadia_findme:debug_print("D2  : -RS- : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 2.1 : match distinct by short, within the mudlet map region
    local results = db:fetch_sql(arkadia_findme.mydb.locations, "select distinct room_id, short, region from locations where short = \"" .. amap.localization.current_short .. "\" and region = \"" .. getAreaTableSwap()[getRoomArea(amap.curr.id)] .. "\"")

    arkadia_findme:debug_print("D2.1: -RS- : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end    

    -- depth 3 : match by short + exits, ignoring region
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.short, amap.localization.current_short),
        db:eq(self.mydb.locations.exits, amap.localization.current_exit)
    ))

    arkadia_findme:debug_print("D3  : --SE : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 3.1 : match distinct by short + exits, ignoring region
    local results = db:fetch_sql(arkadia_findme.mydb.locations, "select distinct room_id, short, exits from locations where short = \"" .. amap.localization.current_short .. "\" and exits = \"" .. amap.localization.current_exit  .. "\"")

    arkadia_findme:debug_print("D3.1: --SE : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end    

    -- depth 4 : match by short only :)
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.short, amap.localization.current_short)
    ))

    arkadia_findme:debug_print("D4  : --S- : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 5 : guess the nearest, RSE
    -- ((( depth 1.1 : match distinct by short + exits, within the mudlet map region )))
    local results = db:fetch_sql(arkadia_findme.mydb.locations, "select distinct room_id, short, exits, region from locations where short = \"" .. amap.localization.current_short .. "\" and exits = \"" .. amap.localization.current_exit .. "\" and region = \"" .. getAreaTableSwap()[getRoomArea(amap.curr.id)] .. "\"")
    arkadia_findme:debug_print("D5.1: -RSE : <red>" .. #results .. " ")
    if #results > 1 then
        local nearest = 100000
        local nearest_room_id = 0
        for k, v in pairs(results) do
            echo(results[k].room_id)
            if getPath(amap.curr.id, results[k].room_id) then
                local distance = table.getn(speedWalkDir)
                if distance < nearest then
                    nearest = distance
                    nearest_room_id = results[k].room_id
                end
                echo("->"..distance.." ")
            else
                echo("->N/A ")
            end
        end
        if nearest_room_id then
            cecho("<green>"..nearest_room_id.." ")
            amap:set_position(nearest_room_id, true)
            return true
        end
    end
end

function arkadia_findme:createZlokAlias()
    fmZlok = tempAlias("^/zlok2$", [[
        if arkadia_findme:findme() then
            cecho("\n<CadetBlue>(skrypty):<green>(findme) Zlokalizowalem.\n")
        end
    ]])
end

function arkadia_findme:createWrocAlias()
    fmWroc = tempAlias("^/wroc$", [[
        cecho("\n<CadetBlue>(skrypty):<green>(findme) OK, cofam.\n")
        amap:set_position(arkadia_findme.pre_zlok_room, true)
    ]])
end

-- FIX
function amap:locate_on_next_location(skip_db)
    cecho("\n<red>NIC NIE ROBIE<reset>")
end
function map_sync_gps_first_line_match(room_id, room_gps_id, line_delta, area_name)
    cecho("\n<red>NIC NIE ROBIE<reset>")
end
function map_sync_gps_subsequent_line_check_match(room_id, room_gps_id)
    cecho("\n<red>NIC NIE ROBIE<reset>")
end

function amap:locate(noprint, skip_db)
    amap.history = get_new_list()
    local tmp_loc = amap:extract_gmcp()

    local msg = nil
    local ret = false

    arkadia_findme.pre_zlok_room = amap.curr.id
    -- immediately clear next dir bind
    amap.next_dir_bind = nil

    if tmp_loc.x then
        local curr_id = not amap.legacy_locate and amap:get_room_by_hash(tmp_loc.x, tmp_loc.y, tmp_loc.z, tmp_loc.area) or amap:room_exist(tmp_loc.x, tmp_loc.y, tmp_loc.z, tmp_loc.area)
        if curr_id and curr_id > 0 then
            amap.curr.id = curr_id
            amap.curr.x = tmp_loc.x
            amap.curr.y = tmp_loc.y
            amap.curr.z = tmp_loc.z
            amap.curr.area = tmp_loc.area
            amap:copy_loc(amap.prev, amap.curr)
            centerview(curr_id)
            raiseEvent("amapNewLocation", amap.curr.id)
            amap_ui_set_dirs_trigger(getRoomExits(amap.curr.id))
            amap:follow_mode()
            msg = "Ok, jestes zlokalizowany po GMCP"
            ret = true
        else
            msg = "Nie moge Cie zlokalizowac na podstawie tych koordynatow (prawdopodobnie lokacja z tymi koordynatami nie istnieje)"
        end
    else
        if arkadia_findme:findme() then
            msg = "<green>(findme) Zlokalizowalem.<reset>"
            ret = true            
        elseif not skip_db and amap.localization:try_to_locate() then
            msg = "<yellow>Zlokalizowalem po opisie lokacji i wyjsciach.<reset>"
            ret = true
        else
            msg = "GMCP nie zawiera koordynatow, nie moge cie zlokalizowac na mapie"
        end
    end

    if not noprint then
        amap:print_log(msg)
    end

    return ret
end

-- room_id - amap.curr.id
-- region - getAreaTableSwap()[getRoomArea(14608)]
-- area - gmcp.room.info.map.name
-- daylight - gmcp.room.time.daylight = false
-- season - gmcp.room.time.season (0,1,2,3)
-- short - amap.localization.current_short
-- exits - amap.localization.current_exit
function arkadia_findme:init()
    arkadia_findme:createHelpAlias()
    arkadia_findme:createZlokAlias()
    arkadia_findme:createWipeAlias()
    arkadia_findme:createInfoAlias()
    arkadia_findme:createAddAlias()
    db:create("findmelocations", {
        locations={
            "room_id",
            "region",
            "area",
            "x",
            "y",
            "daylight",
            "season",
            "short",
            "exits",
            "created_on",
            "created_by"
        }})
    self.mydb = db:get_database("findmelocations")

    self.handler_data  = scripts.event_register:register_singleton_event_handler(self.handler_data, "amapCompassDrawingDone", function() self:set_location_color() end)
end

arkadia_findme:init()