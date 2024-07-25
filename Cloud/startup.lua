print("Running api_extenions.lua")
shell.run("/Cloud/bin/api_extensions/api_extensions.lua")

print("Running rednet.lua")
shell.run("/Cloud/bin/rednet/rednet.lua")

-- TODO include cloud setup here

print("Cloud startup finished.")

local function runStartupInDirectory(directory)
    local startupPath = directory .. "/startup.lua"
    if fs.exists(startupPath) then
        print("Running " .. startupPath)
        shell.run(startupPath)
    end
end

-- FIXME this is gross, this will run all users' startup scripts regardless of current user type (miner vs _some other type_)
local cloudUsersPath = "/Cloud/Users"
if fs.exists(cloudUsersPath) and fs.isDir(cloudUsersPath) then
    local users = fs.list(cloudUsersPath)
    for _, user in ipairs(users) do
        local userPath = cloudUsersPath .. "/" .. user
        if fs.isDir(userPath) then
            runStartupInDirectory(userPath)
        end
    end
end
