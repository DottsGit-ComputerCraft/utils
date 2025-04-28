-- Capture command-line arguments
local args = { ... }
local numArgs = #args
 
-- === Handle No Arguments (Start Interactive Shell via Full Path) ===
if numArgs == 0 then
    -- No arguments provided.
    -- To avoid recursively calling THIS script (which is also named 'lua'),
    -- explicitly run the built-in lua interpreter using its full path from the ROM.
    print("Starting built-in Lua shell...") -- Optional message
    local success = shell.run("/rom/programs/lua") -- <--- CHANGE IS HERE
    if not success then
        -- This shouldn't normally fail unless the OS is very broken
        printError("Failed to launch built-in Lua shell from /rom/programs/lua")
    end
    -- Control will return here after the user exits the interactive shell.
    return -- Exit this script cleanly
 
-- === Handle Single Argument ===
elseif numArgs == 1 then
    local programToRun = args[1]
    print("Executing single program: " .. programToRun)
    local success = shell.run(programToRun)
    if not success then
        printError("Failed to execute: " .. programToRun)
    end
 
-- === Handle Multiple Arguments (Parallel Execution) ===
else -- numArgs > 1
    print("Preparing parallel execution for " .. numArgs .. " programs:")
    local tasks = {}
    for i, programName in ipairs(args) do
        print("  Queueing: " .. programName)
        local taskFunc = function()
            local ok, err = pcall(shell.run, programName)
            if not ok then
                printError("Error in parallel task (" .. programName .. "): " .. tostring(err))
            elseif err == false then
                 printError("Failed to run parallel task: " .. programName)
            end
        end
        table.insert(tasks, taskFunc)
    end
 
    print("Launching parallel tasks (waiting for all to complete)...")
    parallel.waitForAll(unpack(tasks)) -- Use waitForAll
    print("All parallel tasks have completed.")
 
end -- End of argument count check