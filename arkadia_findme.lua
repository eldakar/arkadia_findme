arkadia_findme = arkadia_findme or {
    state = {},
    handler_data = nil,
    loader_data = nil,
    pre_zlok_room = 0,
    mydb = nil,
    contributordb = nil,
    contributorsUrl = 'https://raw.githubusercontent.com/eldakar/arkadia_findme_data/main/contributors.txt',
    contributorsFile = "/findmelocations_contributors.txt",
    contributorsList = {},
    contributorsDBs = {}
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
        cecho("<gray>|  <green>/zlok2<reset>  - ALIAS DO WYSZUKIWANIA - korzysta z tej bazy     |<reset>\n")
        cecho("<gray>|  <green>/wroc<reset>   - cofa mapke do lokacji w ktorej uzylismy /zlok   |<reset>\n")
        cecho("<gray>|  <red>/radd<reset>   - dodaje opis pokoju do bazy, nadpisuje poprzedni |<reset>\n")
        cecho("<gray>|  <red>/rwipe<reset>  - usuwa wszystkie wpisy pokoju                    |<reset>\n")
        cecho("<gray>|                                                            |<reset>\n")
        cecho("<gray>|  <tomato>/rupdate<reset> - sciaga bazy kontrybutorow                      |<reset>\n")
        cecho("<gray>|   uwaga - uzywac w bezpiecznym miejscu - wymaga restartu   |<reset>\n")
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
        cecho("<gray>|  <light_slate_blue>arkadia_findme.contributor_name = nick                    <reset>|<reset>\n")
        cecho("<gray>|            ustaw nazwe, pod ktora beda sie zapisywac twoje |<reset>\n")
        cecho("<gray>|            lokacje.                                        |<reset>\n")
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
        local results = db:delete(self.contributordb.locations, db:AND(
            db:eq(self.contributordb.locations.room_id, amap.curr.id)
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
        local results = db:delete(self.contributordb.locations, db:AND(
            db:eq(self.contributordb.locations.room_id, amap.curr.id),
            db:eq(self.contributordb.locations.season, gmcp.room.time.season),
            db:eq(self.contributordb.locations.daylight, tostring(gmcp.room.time.daylight))
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
            created_by=gmcp.char.info["name"]
        })
        db:add(self.contributordb.locations, {
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
            created_by=gmcp.char.info["name"]
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
            created_by=gmcp.char.info["name"]
        })
        db:add(self.contributordb.locations, {
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
            created_by=gmcp.char.info["name"]
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

    arkadia_findme.pre_zlok_room = amap.curr.id
    
    -- depth negative : sanity check 
    -- depth 1.1 : match distinct by short + exits, within the mudlet map region
    local results = db:fetch_sql(arkadia_findme.mydb.locations, "select distinct room_id, short, exits, region from locations where short = \"" .. amap.localization.current_short .. "\" and exits = \"" .. amap.localization.current_exit .. "\" and region = \"" .. getAreaTableSwap()[getRoomArea(amap.curr.id)] .. "\" and room_id = " .. amap.curr.id)

    arkadia_findme:debug_print("----: ROOM : <red>" .. #results .. " ")
    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 0 : exact match
    local results = db:fetch(self.mydb.locations, db:AND(
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
    local results = db:fetch_sql(arkadia_findme.mydb.locations, "select distinct room_id, short from locations where short = \"" .. amap.localization.current_short .. "\"")
    --local results = db:fetch(self.mydb.locations, db:AND(db:eq(self.mydb.locations.short, amap.localization.current_short)))

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

function arkadia_findme:createUpdateAlias()
    fmZlok = tempAlias("^/rupdate$", [[
        arkadia_findme:update()
    ]])
end


-- FIX
--function amap:locate_on_next_location(skip_db)
    --cecho("\n<red>NIC NIE ROBIE<reset>")
--    return
--end
--function map_sync_gps_first_line_match(room_id, room_gps_id, line_delta, area_name)
    --cecho("\n<red>NIC NIE ROBIE<reset>")
--    return
--end
--function map_sync_gps_subsequent_line_check_match(room_id, room_gps_id)
    --cecho("\n<red>NIC NIE ROBIE<reset>")
--    return
--end

--function amap:locate(noprint, skip_db)
    --amap.history = get_new_list()
--    local tmp_loc = amap:extract_gmcp()

    --local msg = nil
    --local ret = false

    --arkadia_findme.pre_zlok_room = amap.curr.id
    -- immediately clear next dir bind
    --amap.next_dir_bind = nil

    --if tmp_loc.x then
      --  local curr_id = not amap.legacy_locate and amap:get_room_by_hash(tmp_loc.x, tmp_loc.y, tmp_loc.z, tmp_loc.area) or amap:room_exist(tmp_loc.x, tmp_loc.y, tmp_loc.z, tmp_loc.area)
        --if curr_id and curr_id > 0 then
          --  amap.curr.id = curr_id
--            amap.curr.x = tmp_loc.x
  --          amap.curr.y = tmp_loc.y
    --        amap.curr.z = tmp_loc.z
      --      amap.curr.area = tmp_loc.area
--            amap:copy_loc(amap.prev, amap.curr)
  --          centerview(curr_id)
    --        raiseEvent("amapNewLocation", amap.curr.id)
      --      amap_ui_set_dirs_trigger(getRoomExits(amap.curr.id))
--            amap:follow_mode()
  --          msg = "Ok, jestes zlokalizowany po GMCP"
    --        ret = true
      --  else
        --    msg = "Nie moge Cie zlokalizowac na podstawie tych koordynatow (prawdopodobnie lokacja z tymi koordynatami nie istnieje)"
        --end
--    else
  --      if arkadia_findme:findme() then
    --        msg = "<green>(findme) Zlokalizowalem.<reset>"
      --      ret = true            
        --elseif not skip_db and amap.localization:try_to_locate() then
--            msg = "<yellow>Zlokalizowalem po opisie lokacji i wyjsciach.<reset>"
  --          ret = true
    --    else
      --      msg = "GMCP nie zawiera koordynatow, nie moge cie zlokalizowac na mapie"
        --end
--    end

--    if not noprint then
  --      amap:print_log(msg)
    --end

--    return ret
--end


-- downloader functions
-- step 1
function arkadia_findme:downloader_clean_reference()
    -- delete all the old files
    self:debug_print("<reset>(loader) Usuwam liste kontrybutorow")
    os.remove(getMudletHomeDir().."/findmelocations_contributors.txt")
end
-- step 2
function arkadia_findme:downloader_get_reference()
    self:debug_print("<reset>(loader) Pobieram liste kontrybutorow")
    downloadFile(getMudletHomeDir().."/findmelocations_contributors.txt",'https://raw.githubusercontent.com/eldakar/arkadia_findme_data/main/contributors.txt')
end
-- step 3
function arkadia_findme:downloader_parse_reference()
    local file_handle = io.open(getMudletHomeDir().."/findmelocations_contributors.txt")
    local file_content = file_handle:read("*all")
    local contributors_table = string.split(file_content, "\n")
    if table.size(contributors_table) > 1 then
        table.remove(contributors_table, table.size(contributors_table))
    else
        self:debug_print("<reset>(loader) Lista kontrybutorow <red>jest pusta!<reset>")
        return false
    end
    self.contributorsList = contributors_table
    return true
end
-- step 4
function arkadia_findme:downloader_clean_databases()
    for k, v in pairs(self.contributorsList) do
        --if arkadia_findme.contributor == v then
        if arkadia_findme.contributor_name ~= v then
            self:debug_print("<reset>(loader) Usuwam plik: Database_findmelocations<yellow>"..v.."<reset>.db")
            os.remove(getMudletHomeDir().."/Database_findmelocations".. v ..".db")
        end
    end
end

-- step 5
function arkadia_findme:downloader_get_databases()
    for k, v in pairs(self.contributorsList) do
        if arkadia_findme.contributor_name ~= v then
            self:debug_print("<reset>(loader) Sciagam plik: Database_findmelocations<green>"..v.."<reset>.db")
            downloadFile(getMudletHomeDir().."/Database_findmelocations".. v ..".db", "https://raw.githubusercontent.com/eldakar/arkadia_findme_data/main".."/Database_findmelocations".. v ..".db")
        end
    end
end

-- step 6
function arkadia_findme:downloader_erase_masterdb()
    self:debug_print("<reset>(loader) Zeruje plik zbiorczy: <yellow>Database_findmelocations.db")
    db:close("findmelocations")
    os.remove(getMudletHomeDir().."/Database_findmelocations.db")
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
    self:debug_print("<reset>(loader) Spajam bazy, moze to potrwac do 30 sekund...")
end

-- step 7
function arkadia_findme:downloader_open_databases()
    local isCharContributor = false
    for k, v in pairs(self.contributorsList) do
        if v == arkadia_findme.contributor_name then
            isCharContributor = true
        end

        db:create("findmelocations" .. v, {
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
        local tmpdb = db:get_database("findmelocations" .. v)
        local results = db:fetch_sql(tmpdb.locations, "select * from locations")
        local integrated = 0

        for kk, vv in pairs(results) do
--TODO      
            local _results = db:fetch(self.mydb.locations, db:AND(
                db:eq(self.mydb.locations.daylight, vv.daylight),
                db:eq(self.mydb.locations.short, vv.short),
                db:eq(self.mydb.locations.exits, vv.exits),
                db:eq(self.mydb.locations.room_id, vv.room_id),
                db:eq(self.mydb.locations.season, vv.season),
                db:eq(self.mydb.locations.area, vv.area)
            ))

            if #_results == 0 then
                db:add(self.mydb.locations, {
                    room_id=vv.room_id,
                    region=vv.region,
                    area=vv.area,
                    x=vv.x,
                    y=vv.y,
                    daylight=vv.daylight,
                    season=vv.season,
                    short=vv.short,
                    exits=vv.exits,
                    created_on=vv.created_on,
                    created_by=vv.created_by
                })
                integrated = integrated + 1
            end
--TODO
        end

        self:debug_print("<reset> Baza: <yellow>" .. v .. "<reset> - zintegrowano <green>" .. integrated.. "<reset>/" .. #results)
        --db:close("findmelocations" .. v)

    end

    if not isCharContributor then
        db:create("findmelocations" .. self.contributor_name, {
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

        local tmpdb = db:get_database("findmelocations" .. self.contributor_name)
        local results = db:fetch_sql(tmpdb.locations, "select * from locations")
        local integrated = 0

        for kk, vv in pairs(results) do
--TODO      
            local _results = db:fetch(self.mydb.locations, db:AND(
                db:eq(self.mydb.locations.daylight, vv.daylight),
                db:eq(self.mydb.locations.short, vv.short),
                db:eq(self.mydb.locations.exits, vv.exits),
                db:eq(self.mydb.locations.room_id, vv.room_id),
                db:eq(self.mydb.locations.season, vv.season),
                db:eq(self.mydb.locations.area, vv.area)
            ))

            if #_results == 0 then
                db:add(self.mydb.locations, {
                    room_id=vv.room_id,
                    region=vv.region,
                    area=vv.area,
                    x=vv.x,
                    y=vv.y,
                    daylight=vv.daylight,
                    season=vv.season,
                    short=vv.short,
                    exits=vv.exits,
                    created_on=vv.created_on,
                    created_by=vv.created_by
                })
                integrated = integrated + 1
            end
--TODO
        end

        self:debug_print("<reset> Baza: <magenta>" .. self.contributor_name .. "<reset> - zintegrowano <green>" .. integrated.. "<reset>/" .. #results)

    end



    self:debug_print("<reset>(loader) NALEZY ZRESTARTOWAC MUDLET!!!")
end



function arkadia_findme:update()
    if arkadia_findme.contributor_name == "" or not arkadia_findme.contributor_name then
        self:debug_print("<reset>Blad przy inicjacji. Musisz pierw ustawic <red>/cset=arkadia_findme.contributor_name=twojnick")
        return
    end

    tempTimer(0, function() self:downloader_clean_reference() end)
    tempTimer(2, function() self:downloader_get_reference() end)
    tempTimer(4, function() self:downloader_parse_reference() end)
    tempTimer(4.5, function() self:downloader_clean_databases() end)
    tempTimer(6, function() self:downloader_get_databases() end)
    tempTimer(8, function() self:downloader_erase_masterdb() end)
    tempTimer(9, function() self:downloader_open_databases() end)
end
--self.contributorsDBs[k] = db:get_database("findmelocations".. v)




-- room_id - amap.curr.id
-- region - getAreaTableSwap()[getRoomArea(14608)]
-- area - gmcp.room.info.map.name
-- daylight - gmcp.room.time.daylight = false
-- season - gmcp.room.time.season (0,1,2,3)
-- short - amap.localization.current_short
-- exits - amap.localization.current_exit
function arkadia_findme:start()
    if arkadia_findme.contributor_name == "" or not arkadia_findme.contributor_name then
        self:debug_print("<reset>(loader) Pierwsze uruchomienie > ustawiam nazwe bazy jako <magenta>Database_findmelocations<yellow>" .. gmcp.char.info[name] .. "<magenta>.db")
        arkadia_findme.contributor_name = gmcp.char.info[name]
    end

    self:debug_print("<reset>(loader) Inicjuje modul <magenta>findme<reset> dla kontrybutora <magenta>" .. arkadia_findme.contributor_name)
    arkadia_findme:createHelpAlias()
    arkadia_findme:createZlokAlias()
    arkadia_findme:createWipeAlias()
    arkadia_findme:createInfoAlias()
    arkadia_findme:createWrocAlias()
    arkadia_findme:createAddAlias()
    arkadia_findme:createUpdateAlias()

    db:create("findmelocations" .. arkadia_findme.contributor_name, {
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
    self.contributordb = db:get_database("findmelocations" .. arkadia_findme.contributor_name)

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

--profileLoaded
-- loginSuccessful

function arkadia_findme:init()
    self.loader_data  = scripts.event_register:register_singleton_event_handler(self.loader_data, "profileLoaded", function() self:start() end)
end

arkadia_findme:init()
