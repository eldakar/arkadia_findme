arkadia_findme.labels = arkadia_findme.labels or {
    state = false,
    handler_data = nil,
    sortedKeys = {},
    currentitem = 0,
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
    timer = nil,
    magic_popup = ""
}


function arkadia_findme.labels:init()
    self.sortedKeys = {}
    self.currentitem = 0
    db:create("magiclabels", {labels={"id","name","type","zone","date","author","description", "partysize"}})
    self.mydb = db:get_database("magiclabels")

    self.handler_data  = scripts.event_register:register_singleton_event_handler(self.handler_data, "amapCompassDrawingDone", function() self:do_move() end)

    self:createMagicAlias()
end

function arkadia_findme.labels:load_magic_nodes()
    local results = db:fetch(self.mydb.labels, db:AND(
        db:eq(self.mydb.labels.zone, amap.curr.area),
        db:OR(
            db:eq(self.mydb.labels.type, 10),
            db:eq(self.mydb.labels.type, 9)
        )
    ))
    self.magic_nodes = {}
    if #results < 1 then
        return
    end
    self.magic_nodes_names = {}
    for k, v in pairs(results) do
        self.magic_nodes[results[k].id] = 100
        self.magic_nodes_names[results[k].id] = results[k].name
    end
end

function arkadia_findme.labels:load_magic_multinodes()
    local results = db:fetch(self.mydb.labels,
            db:eq(self.mydb.labels.type, 11)
    )
    self.magic_multinodes = {}
    if #results < 1 then
        return
    end
    for k, v in pairs(results) do
        self.magic_multinodes[results[k].id] = 100
    end
end

function arkadia_findme.labels:hide_nodes()
    for k, v in pairs(self.magic_nodes) do
        unHighlightRoom(k)
    end
end

function arkadia_findme.labels:hide_multinodes()
    for k, v in pairs(self.magic_multinodes) do
        unHighlightRoom(k)
    end
end

function arkadia_findme.labels:load_magic_paths()
    self:clear_magic_paths()

    if table.size(self.magic_nodes) < 1 then
        return
    end
    self.magic_paths = {}
    self.magic_popup = ""

    for k, v in pairs(self.magic_nodes) do
        if self.visited_nodes[tonumber(k)] ~= true then
            getPath(amap.curr.id, k)
            if speedWalkDir and speedWalkDir[1] then
                self.magic_nodes[k] = #speedWalkPath
                if self.magic_nodes[k] < 40 then
                    self.magic_popup = self.magic_popup .. amap.ui["dir_to_fancy_symbol"][speedWalkDir[1]] .. " " .. string.format("%-3s",#speedWalkPath) .. " " .. self.magic_nodes_names[k] .. "\n"
                    for kk,vv in pairs(speedWalkPath) do
                        -- dont overwrite nodes with path
                        if not self.magic_nodes[vv] and not self.magic_multinodes[vv] then
                            self.magic_paths[vv] = true
                            highlightRoom(vv, 155, 0, 155, 155, 0, 155, 2, 70, 200)
                        end
                    end
                end
            end
        end
    end
end

function arkadia_findme.labels:map_info()
    return self.magic_popup, true
end


function arkadia_findme.labels:clear_magic_paths()
    for k, v in pairs(self.magic_paths) do
        unHighlightRoom(k)
    end
end


function arkadia_findme.labels:do_move()
    if self.coloring then
        if self.magic_nodes[tostring(amap.curr.id)] or self.magic_multinodes[tostring(amap.curr.id)] then
            self.visited_nodes[amap.curr.id] = true
        end
        self:load_magic_nodes()
        self:load_magic_paths()
    end
end

function arkadia_findme.labels:node_refresher()
    if self.coloring then
        for k, v in pairs(self.magic_multinodes) do
            highlightRoom(k, 200, 100, 0, 200, 100, 0, 3, 70, 200)  -- te zlote
        end
        for k, v in pairs(self.magic_nodes) do
            highlightRoom(k, 255, 0, 255, 255, 0, 255, 3, 50, 230)  -- kluczyki do sciezek
        end
        for k, v in pairs(self.visited_nodes) do
            highlightRoom(k, 70, 30, 0, 70, 30, 0, 3, 70, 150)      -- nadpisujemy wszystko na bury kolor
        end
        self.timer = tempTimer(1, function() arkadia_findme.labels:node_refresher() end)
    end
end

function arkadia_findme.labels:magic_toggle()
    if self.coloring then
        arkadia_findme:debug_print("Wyswietlanie magikow <green>WYLACZONE")
        self.coloring=false
        self:clear_magic_paths()
        self:hide_nodes()
        self:hide_multinodes()
        if arkadia_findme.labels.map_info == true then
            disableMapInfo("MagicCompass")
            killMapInfo("MagicCompass")
        end
        if self.timer and exists(self.timer, "timer") then killTimer(self.timer) end
    else
        arkadia_findme:debug_print("Wyswietlanie magikow <green>WLACZONE")
        self.coloring=true
        self:load_magic_nodes()
        self:load_magic_paths()
        self:load_magic_multinodes()
        self:show_multinodes()
        if arkadia_findme.labels.map_info == true then
            registerMapInfo("MagicCompass", function() return self:map_info() end)
            enableMapInfo("MagicCompass")
        end
--        self.timer = tempTimer(1, function self:node_refresher() end)
        self.timer = tempTimer(1, function() arkadia_findme.labels:node_refresher() end)
    end
end

function arkadia_findme.labels:createMagicAlias()
    fmAdd = tempAlias("^/rmagic$", [[arkadia_findme.labels:magic_toggle()]])
end

function arkadia_findme.labels:show_multinodes()
    for k, v in pairs(self.magic_multinodes) do
            highlightRoom(k, 200, 100, 0, 200, 100, 0, 3, 70, 200)
    end
end

function arkadia_findme.labels:show_magic_nodes()
    for k, v in pairs(self.magic_nodes) do
        if self.magic_nodes[k] < 40 then
            highlightRoom(k, 25, 0, 25, 155, 0, 155, 10, 1, 150)
        else
            highlightRoom(k, 70, 0, 70, 70, 0, 70, 10, 10, 200)
        end
    end
end

function arkadia_findme.labels:get_name()
    local results = db:fetch(self.mydb.labels, db:eq(self.mydb.labels.id, amap.curr.id))
    if #results > 0 then
        for k, v in pairs(results) do
            arkadia_findme:debug_print("<reset>" .. results[k].id .. " " .. results[k].name .. " ")
        end
    end
end
tempAlias("^/rmagic_name$", [[arkadia_findme.labels:get_name()]])

function arkadia_findme.labels:fix_zones()
    local results = db:fetch(self.mydb.labels, db:eq(self.mydb.labels.zone, ""))
    if #results == 0 then
        arkadia_findme:debug_print("<tomato>Wszystkie regiony naprawione!")
        return
    end
    arkadia_findme:debug_print("<tomato>Naprawiam pokoje bez regionu: " .. #results)
    for k, v in pairs(results) do
        print(v)
        results[k].zone = getAreaTableSwap()[getRoomArea(results[k].id)]
        db:update(self.mydb.labels, results[k])
    end
end

timerhook=0
function arkadia_findme.labels:label_popup(interestPointId)
    testlabel = Geyser.Label:new({
        name = "testlabel",
        x = "25%", y = "25%",
        width = "50%", height = "10%",
        fgColor = "black",
        message = [[<center>""</center>]]
      })
      testlabel:setColor(
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[1],
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[2],
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[3],
          200
      )
      testlabel:setFontSize(30)
      local str = "<center>" .. interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].name .. "<center>"
      testlabel:echo(str)
    killTimer(timerhook)
    timerhook = tempTimer(3, [[testlabel:hide()]] )
end

function arkadia_findme.labels:extended_popup(interestPointId)
    popup = Geyser.Container:new({
        name = "popup",
        x="25%", y="25%",
        width = "50%", height="10%",
    })

    testlabel = Geyser.Label:new({
        name = "testlabel",
        x = 0, y = 0,
        width = "100%", height = "50%",
        fgColor = "black",
        message = [[<center>""</center>]]
      }, popup)
      testlabel:setColor(
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[1],
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[2],
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[3],
          200
      )
      testlabel:setFontSize(30)
      local str = "<center>" .. interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].name .. "<center>"
      testlabel:echo(str)

      testlabel2 = Geyser.Label:new({
        name = "testlabel2",
        x = 0, y = "50%",
        width = "100%", height = "50%",
        fgColor = "black",
        message = [[<center>""</center>]]
      }, popup)
      testlabel2:setColor(
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[1],
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[2],
        interestPointTypes[interestPoints[nearByIndexes[interestPointId]].type].color[3],
          200
      )
      testlabel2:setFontSize(10)
      local str = "<left>OPIS: " .. 
        interestPoints[nearByIndexes[interestPointId]].name .. ", " ..
        interestPoints[nearByIndexes[interestPointId]].description .. ", " ..
        interestPoints[nearByIndexes[interestPointId]].zone .. "\nUSER: " ..
        interestPoints[nearByIndexes[interestPointId]].author .. ", " ..
        interestPoints[nearByIndexes[interestPointId]].date .. "<left>"
      testlabel2:echo(str)
      killTimer(timerhook)
      timerhook = tempTimer(3, [[popup:hide()]] )
end








---------------------------------------------------------
--- EDYCJA
--- -----------------------------------------------------

function arkadia_findme.labels:set_type(typeName)
    local tempType = 9
    if typeName == "chodzi" then tempType = 11 end
    if typeName == "stoi" then tempType = 9 end
    if typeName == "pojawia" then tempType = 10 end

    local results = db:fetch(self.mydb.labels, db:eq(self.mydb.labels.id, amap.curr.id))
    if #results == 0 then
        arkadia_findme:debug_print("Ten pokoj nie ma wpisu ;(")
        return
    end

    for k, v in pairs(results) do
        results[k].type = tempType
        db:update(self.mydb.labels, results[k])
    end
    arkadia_findme:debug_print("Ustawilem nowy typ wpisow!")
end
tempAlias("^/rmagic_typ chodzi$", [[arkadia_findme.labels:set_type("chodzi")]])
tempAlias("^/rmagic_typ stoi$", [[arkadia_findme.labels:set_type("stoi")]])
tempAlias("^/rmagic_typ pojawia$", [[arkadia_findme.labels:set_type("pojawia")]])
function arkadia_findme.labels:add_label(labelDescription)
    -- >:-)
    db:delete(self.mydb.labels, db:eq(self.mydb.labels.id, amap.curr.id))
    db:add(self.mydb.labels, {
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
    db:delete(self.mydb.labels, db:eq(self.mydb.labels.id, amap.curr.id))
    arkadia_findme:debug_print("Usunalem wpis o magii...")
end
tempAlias("^/rmagic_del$", [[arkadia_findme.labels:del_label()]])

function arkadia_findme.labels:addfull(_id,_name,_type,_zone,_date,_author,_description)
      db:delete(self.mydb.labels, db:eq(self.mydb.labels.id, id))
      db:add(self.mydb.labels, {
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
                self:addfull(
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
    self.last_check = os.time() - 800000000
    local params = { orderBy = [[%22time%22]], startAt = self.last_check }
    FireBaseClientFactory:getClient():getData("keyMobsKills.json", function(data) self:update_kills(data) end, params)
end

function arkadia_findme.labels:merge_all_poi_data()
    for k, v in pairs(mc.poi.kill_data) do
        local results = db:fetch(self.mydb.labels, db:eq(self.mydb.labels.id, mc.poi.kill_data[k].loc))
        if #results == 0 then
            self:addfull(
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
