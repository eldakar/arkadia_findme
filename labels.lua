arkadia_findme.labels = arkadia_findme.labels or {
    state = false,
    sortedKeys = {},
    currentitem = 0,
    mydb = nil,
    trollmap = {},
    dboptions = {
        paths = {},
        previousPathRoomId = 0
    },
    magic_nodes = {},
    magic_paths = {}
}

pointtypes = {
    ["1"] = "kowal",
    ["2"] = "poczta",
    ["3"] = "costam",
    ["4"] = "wiedza"
}

interestPointTypes = {
    ["1"] = {
        ["name"] = "kowal",
        ["color"] = {20, 200, 100, 50, 50, 50, 1.3, 100, 100};
        ["visibility"] = 8
            },
    ["2"] = {
        ["name"] = "poczta",
        ["color"] = {255, 255, 100, 50, 50, 50, 1.3, 100, 100};
        ["visibility"] = 8
            },
    ["3"] = {
        ["name"] = "wiedza",
        ["color"] = {255, 255, 255, 50, 50, 50, 1.3, 100, 100};
        ["visibility"] = 0
            },
    ["4"] = {
        ["name"] = "woda",
        ["color"] = {10, 10, 255, 50, 50, 50, 1.2, 100, 100};
        ["visibility"] = 10
            },
    ["5"] = {
        ["name"] = "skrzynia",
        ["color"] = {255, 100, 0, 50, 50, 50, 1.2, 100, 100};
        ["visibility"] = 10
            },
    ["6"] = {
        ["name"] = "sklep",
        ["color"] = {0, 100, 255, 50, 50, 50, 1.2, 100, 100};
        ["visibility"] = 10
            },
    ["7"] = {
        ["name"] = "biblioteka",
        ["color"] = {200, 200, 200, 50, 50, 50, 1.2, 100, 100};
        ["visibility"] = 5
            },
    ["8"] = {
        ["name"] = "ekspedycja",
        ["color"] = {0, 255, 255, 50, 50, 50, 1.2, 100, 100};
        ["visibility"] = 5
            },
    ["9"] = {
        ["name"] = "klucz",
        ["color"] = {155, 0, 155, 200, 0, 200, 10, 70, 200};
        ["visibility"] = 5
            },
    ["10"] = {
        ["name"] = "sciezka",
        ["color"] = {100, 200, 100, 50, 50, 50, 1.2, 100, 100};
        ["visibility"] = 30
            },                        
    ["99"] = {
        ["name"] = "safelock",
        ["color"] = {255, 255, 255, 50, 50, 50, 1.8, 100, 100};
        ["visibility"] = 50
            }
}


function arkadia_findme.labels:init()
    self.sortedKeys = {}
    self.currentitem = 0
    db:create("trollhunter", {labels={"id","name","type","zone","date","author","description"}})
    self.mydb = db:get_database("trollhunter")
end

function arkadia_findme.labels:load_magic_nodes()
    local results = db:fetch(self.mydb.labels, db:AND(
        db:eq(self.mydb.labels.zone, amap.curr.area), db:eq(self.mydb.labels.type, 9)))
    self.magic_nodes = {}
    self.magic_paths = {}
    if #results < 1 then
      --  arkadia_findme:debug_print("<tomato>Nie znalazlem zadnych kluczy...")
        return
    end
    for k, v in pairs(results) do
        self.magic_nodes[results[k].id] = 100
    end
    --arkadia_findme:debug_print("<tomato>Zaladowalem " .. #self.magic_nodes .. " kluczy!")
end

function arkadia_findme.labels:load_magic_paths()
    if table.size(self.magic_nodes) < 1 then
        --arkadia_findme:debug_print("<tomato>Nie znalazlem zadnych kluczy...")
        return
    end
    --arkadia_findme:debug_print("<tomato>Resetuje sciezki...")
    self.magic_paths = {}

    for k, v in pairs(self.magic_nodes) do
        getPath(amap.curr.id, k)
        if speedWalkDir and speedWalkDir[1] then
            self.magic_nodes[k] = #speedWalkPath
            --arkadia_findme:debug_print("<tomato>Znalazlem sciezke do <green>" .. v .. " <tomato> w ilosci krokow: <green>" .. #speedWalkDir)
                for kk,vv in pairs(speedWalkPath) do
                    self.magic_paths[vv] = true
                end
        end
    end
end

function arkadia_findme.labels:clear_magic_paths()
    for k, v in pairs(self.magic_paths) do
        unHighlightRoom(k)
    end
end

function arkadia_findme.labels:show_magic_paths()
    for k, v in pairs(self.magic_paths) do
        highlightRoom(k, 155, 0, 155, 200, 0, 200, 2, 70, 200)
    end
end

function arkadia_findme.labels:show_magic()
    self:clear_magic_paths()
    self:load_magic_nodes()
    self:load_magic_paths()
    self:show_magic_paths()
    self:show_all()
end

function arkadia_findme.labels:toggle()
end

function arkadia_findme.labels:show_all()
    interestPoints = db:fetch(self.mydb.labels)
    if interestPoints == 0 then
        return
    end
    local t = {}
    for k, v in pairs(interestPoints) do
        highlightRoom(
            interestPoints[k].id,
            interestPointTypes[interestPoints[k].type].color[1],
            interestPointTypes[interestPoints[k].type].color[2],
            interestPointTypes[interestPoints[k].type].color[3],
            interestPointTypes[interestPoints[k].type].color[4],
            interestPointTypes[interestPoints[k].type].color[5],
            interestPointTypes[interestPoints[k].type].color[6],
            interestPointTypes[interestPoints[k].type].color[7],
            interestPointTypes[interestPoints[k].type].color[8],
            interestPointTypes[interestPoints[k].type].color[9]
        )
    end
end

function arkadia_findme.labels:scan_for_nearby_labels()
    nearByLabels = {}
    nearByIndexes = {}

    for k, v in pairs(interestPoints) do
        getPath(amap.curr.id, interestPoints[k].id)
        if speedWalkDir and speedWalkDir[1] then
            if table.getn(speedWalkDir) < interestPointTypes[interestPoints[k].type].visibility then
                local a = table.insert(nearByLabels, interestPoints[k].id)
                nearByIndexes[interestPoints[k].id] = k
            end
        end
    end
end

nearByLabelNext = 1

function arkadia_findme.labels:path_to_next_nearby_label()
    self:show_zone()
    self:scan_for_nearby_labels()
    local n = table.getn(nearByLabels)
    if n <= nearByLabelNext then
        nearByLabelNext = 0
    end
    nearByLabelNext = nearByLabelNext + 1
    amap.path_display:start(nearByLabels[nearByLabelNext]);
    self:show_zone()
    highlightRoom(nearByLabels[nearByLabelNext], 
        interestPointTypes[interestPoints[nearByIndexes[nearByLabels[nearByLabelNext]]].type].color[1],
        interestPointTypes[interestPoints[nearByIndexes[nearByLabels[nearByLabelNext]]].type].color[2],
        interestPointTypes[interestPoints[nearByIndexes[nearByLabels[nearByLabelNext]]].type].color[3],
        interestPointTypes[interestPoints[nearByIndexes[nearByLabels[nearByLabelNext]]].type].color[1],
        interestPointTypes[interestPoints[nearByIndexes[nearByLabels[nearByLabelNext]]].type].color[2],
        interestPointTypes[interestPoints[nearByIndexes[nearByLabels[nearByLabelNext]]].type].color[3],
        2.5, 
        228, 
        128
    )
    arkadia_findme.labels:extended_popup(nearByLabels[nearByLabelNext])
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


function arkadia_findme.labels:add_alias(labelTypeName)
    local validType = nil
    
    for k, v in pairs(interestPointTypes) do
        if interestPointTypes[k].name == labelTypeName then
            self:add_plain(k)
            self:show_zone()
            print("/lab: " .. labelTypeName .. " dodana!")
            return
        end
    end
    print("/lab: Etykietka " .. labelTypeName .. " nie istnieje.")
end

function arkadia_findme.labels:add_plain(labeltype)
    -- TODO
    db:delete(self.mydb.labels, db:eq(self.mydb.labels.id, amap.curr.id))
    -- TODO
    db:add(self.mydb.labels, {
        id=amap.curr.id,
        name=" ",
        type=labeltype,
        zone=amap.curr.area,
        date=os.date("%c"),
        author=ateam.options.own_name,
        description=" "
    })
end

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

function arkadia_findme.labels:show(roomid)
    highlightRoom(roomid, 20, 200, 100, 50, 50, 50, 1.5, 228, 128)
end

arkadia_findme.labels:init()

function arkadia_findme.labels:printHelp()
    cecho("<gray>+-----------------------------------------------------------------------------------+<reset>\n")
    cecho("<gray>|                                                                                   |<reset>\n")
    cecho("<gray>|  Etykietki lokacji na mapie                                                       |<reset>\n")
    cecho("<gray>|                                                                                   |<reset>\n")
    cecho("<gray>|  OBSLUGA                                                                          |<reset>\n")
    cecho("<gray>|                                                                                   |<reset>\n")    
    cecho("<gray>| /lab_help                      - ta pomoc                                         |<reset>\n")
    cecho("<gray>| /lab_poi                       - migracja etykiet z bazy POI (wystarczy raz)      |<reset>\n")
    cecho("<gray>| <green>/lab_next<gray>                      - ustawia lazik do nastepnej WIDOCZNEJ etykiety    |<reset>\n")
    cecho("<gray>| <green>/lab_walk<gray>                      - bezpieczny lazik (zatrzymuje sie w labiryncie)   |<reset>\n")    
    cecho("<gray>|                                                                                   |<reset>\n")
    cecho("<gray>|                                                                                   |<reset>\n")    
    cecho("<gray>|  EDYCJA                                                                           |<reset>\n")
    cecho("<gray>|                                                                                   |<reset>\n")
    cecho("<gray>| /lab [TYP LOKACJI]             - dodaj etykietke na aktualnej lokacji             |<reset>\n")
    cecho("<gray>|      [TYP LOKACJI]             - kowal, poczta, wiedza, woda, skrzynia, sklep,    |<reset>\n")
    cecho("<gray>|                                  biblioteka, ekspedycja, klucz, sciezka, safelock |<reset>\n")    
    cecho("<gray>|      [OPIS] (TODO)             - opcjonalny, wyswietli sie w popup'ie             |<reset>\n")
    cecho("<gray>|                                                                                   |<reset>\n")
    cecho("<gray>| Typ lokacji bezposrednio zwiazany jest z jej widocznoscia. Widocznosc to          |<reset>\n")
    cecho("<gray>| maksymalna ilosc krokow do etykiety, w ktorej bedziemy mogli sie do niej poruszac |<reset>\n")
    cecho("<gray>| lazikiem, uzywajac komendy /lab_next.                                             |<reset>\n")        
    cecho("<gray>| Sciezka ma widocznosc 30 krokow, safelock 50, a kowal 8.                          |<reset>\n")
    cecho("<gray>|                                                                                   |<reset>\n")    
    cecho("<gray>+-----------------------------------------------------------------------------------+<reset>\n")
end