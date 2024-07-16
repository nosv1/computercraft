print("Copying /disk/Cloud to hdd")
shell.run("rm /Cloud")
shell.run("cp /disk/Cloud /")

print("Copying /disk/startup.lua to hdd")
shell.run("rm /startup.lua")
shell.run("cp /disk/startup.lua /")
shell.run("/startup.lua")
