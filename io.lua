arkadia_findme.io = arkadia_findme.io or {
    mergeddb_handler = nil,
    contributordb_handler = nil,
    contributor_list = {},

    contributors_file_name = "/findmelocations_contributors.txt",
    contributors_file_uri = "https://raw.githubusercontent.com/eldakar/arkadia_findme_data/main/contributors.txt",
    databases_file_prefix = "/Database_findmelocations",
    databases_file_uri = "https://raw.githubusercontent.com/eldakar/arkadia_findme_data/main/Database_findmelocations"
}

function arkadia_findme.io:remove_file(fname)
    if not fname then
        return
    end

    arkadia_findme:debug_print("<reset>(loader) <red>---<reset> Usuwam plik: " .. fname)
    os.remove(getMudletHomeDir()..fname)
end


function arkadia_findme.io:download_db(contributorName)
    if not contributorName then
        arkadia_findme:debug_print("<reset>(loader) <tomato>IO:download_db() - brak nazwy kontrybutora")
        return
    end

    arkadia_findme:debug_print("<reset>(loader) <green>+++<reset> Sciagam baze: " .. self.databases_file_prefix .. "<yellow>" .. contributorName .. "<reset>.db")
    downloadFile(getMudletHomeDir() .. self.databases_file_prefix .. contributorName .. ".db", self.databases_file_uri .. contributorName .. ".db")
end

function arkadia_findme.io:remove_databases()
    if #self.contributor_list < 1 then
        arkadia_findme:debug_print("<reset>(loader) <tomato>IO:remove_databases() - lista kontrybuturow jest pusta")
        return
    end
    for k, v in pairs(self.contributor_list) do
        if arkadia_findme.contributor_name ~= v then
            self.remove_file(self.databases_file_prefix .. v .. ".db")
        end
    end
end

function arkadia_findme.io:get_contributors()
    local file_handle = io.open(getMudletHomeDir() .. self.contributors_file_name)
    local file_content = file_handle:read("*all")
    local contributors_table = string.split(file_content, "\n")
    if table.size(contributors_table) > 1 then
        table.remove(contributors_table, table.size(contributors_table))
    else
        arkadia_findme:debug_print("<reset>(loader) Lista kontrybutorow <red>jest pusta!<reset>")
        return false
    end
    self.contributor_list = contributors_table
    return true
end