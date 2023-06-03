arkadia_findme = arkadia_findme or {
    state = {},
    handler_data = nil,
    mydb = nil
}
--findme.highlight_current_room
--findme.search_depth
function arkadia_findme:createHelpAlias()
    fmHelp = tempAlias("^/findme help$", [[
        cecho("<gray>+------------------------------------------------------------+<reset>\n")
        cecho("<gray>|  <yellow>                   .: Baza lokacji :.                     <gray>|<reset>\n")
    ]])
end

function arkadia_findme:add()
    local test_room = arkadia_findme:get_color()
    if test_room == 2 then
        cecho("\n<CadetBlue>(skrypty)<tomato>: Ten pokoj juz istnieje w bazie!\n")
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
    end
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
-- room_id - amap.curr.id
-- region - getAreaTableSwap()[getRoomArea(14608)]
-- area - gmcp.room.info.map.name
-- daylight - gmcp.room.time.daylight = false
-- season - gmcp.room.time.season (0,1,2,3)
-- short - amap.localization.current_short
-- exits - amap.localization.current_exit
function arkadia_findme:findme()
    -- depth 0 : exact match
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.season, gmcp.room.time.season),
        db:eq(self.mydb.locations.daylight, tostring(gmcp.room.time.daylight)),
        db:eq(self.mydb.locations.short, amap.localization.current_short),
        db:eq(self.mydb.locations.exits, amap.localization.current_exit)
    ))

    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end

    -- depth 1 : match by short + exits, within mudlet map region
    local results = db:fetch(self.mydb.locations, db:AND(
        db:eq(self.mydb.locations.region, getAreaTableSwap()[getRoomArea(amap.curr.id)]),
        db:eq(self.mydb.locations.short, amap.localization.current_short),
        db:eq(self.mydb.locations.exits, amap.localization.current_exit)
    ))

    if #results == 1 then
        amap:set_position(results[1].room_id, true)
        return true
    end
end

function arkadia_findme:createZlokAlias()
    fmZlok = tempAlias("^/zlok2$", [[
        if arkadia_findme:findme() then
            cecho("\n<CadetBlue>(skrypty):<green>(findme) Zlokalizowalem.")
        end
    ]])
end

function amap:locate(noprint, skip_db)
    amap.history = get_new_list()
    local tmp_loc = amap:extract_gmcp()

    local msg = nil
    local ret = false

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
        if not skip_db and amap.localization:try_to_locate() then
            msg = "Zlokalizowalem po opisie lokacji i wyjsciach."
            ret = true
        elseif arkadia_findme:findme() then
            msg = "<green>(findme) Zlokalizowalem."
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