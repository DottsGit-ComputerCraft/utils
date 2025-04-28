-- Capture command-line arguments
local args = { ... }
local numArgs = #args
 
-- Check if any arguments were provided
if numArgs == 0 then
    printError("Usage: lua <program1.lua> [program2.lua] ...")
    printError("Please specify at least one program file to execute.")
    return -- Exit the script
end
 
-- === Handle Single Argument ===
if numArgs == 1 then
    local programToRun = args[1]
    print("Executing single program: " .. programToRun)
 
    -- Execute the program using shell.run
    -- This behaves exactly like typing 'programToRun' in the shell
    local success = shell.run(programToRun)
 
    if not success then
        printError("Failed to execute: " .. programToRun)
        -- shell.run usually prints its own error, but we note it failed.
    else
        -- Optional: Indicate completion if needed, though shell.run is blocking
        -- print("Execution finished for: " .. programToRun)
    end
 
-- === Handle Multiple Arguments (Parallel Execution) ===
else -- numArgs > 1
    print("Preparing parallel execution for " .. numArgs .. " programs:")
 
    -- Create a table to hold the functions for each parallel task
    local tasks = {}
 
    -- Loop through each argument (program name)
    for i, programName in ipairs(args) do
        print("  Queueing: " .. programName)
 
        -- Create a function for this specific program.
        -- This function will be executed by the parallel API.
        local taskFunc = function()
            -- Each parallel task simply runs its assigned program
            -- Use pcall (protected call) around shell.run for robustness
            -- in case a specific program crashes or doesn't exist.
            local ok, err = pcall(shell.run, programName)
            if not ok then
                -- Log error without stopping other parallel tasks
                printError("Error in parallel task (" .. programName .. "): " .. tostring(err))
            elseif err == false then
                 -- shell.run can return false on non-crash failure (e.g. file not found)
                 printError("Failed to run parallel task: " .. programName)
            end
            -- The return value here isn't critical for waitForAny if just launching
        end
 
        -- Add the function to our list of tasks
        table.insert(tasks, taskFunc)
    end
 
    -- Launch all the tasks in parallel.
    -- parallel.waitForAll starts all functions and returns when the *first* one finishes.
    -- All tasks will be running concurrently in the background.
    print("Launching parallel tasks...")
    parallel.waitForAll(unpack(tasks)) -- unpack turns the table into separate arguments
 
    -- Note: This script (lua.lua) will continue (and potentially exit)
    -- after the *first* parallel task finishes. The other tasks will
    -- continue running in the background until they complete or error.
    print("Parallel launch initiated. Tasks are running concurrently.")
 
end -- End of argument count check