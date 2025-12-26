local posix = require("posix")

-- Function to set non-blocking mode for a file descriptor
local function setNonBlocking(fd)
    local flags = posix.fcntl(fd, posix.F_GETFL, 0)
    posix.fcntl(fd, posix.F_SETFL, flags + posix.O_NONBLOCK)
end

-- Open stdin in non-blocking mode
setNonBlocking(0)  -- 0 is the file descriptor for stdin

-- Read input with non-blocking
function inkey()
    --posix.sleep(1)
    local input, err = io.read(1)  -- Read one character
    if input then
        return input
        --print("You entered:", input)
    elseif err == "timeout" then
        return ""
        -- No input yet, do something else or continue waiting
        --posix.sleep(5)  -- Sleep for 1 second (adjust as needed)
    else
        return ""
        --print("no input")
        --break
    end
end
