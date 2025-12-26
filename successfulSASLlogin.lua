#!/usr/bin/lua
-- usage: lua llamabot.lua groupedbotname "#channel" nick password

--------------------------------------------------
-- Requires
--------------------------------------------------
local socket = require("socket")
local mime   = require("mime")   -- base64 for SASL

--------------------------------------------------
-- Arguments
--------------------------------------------------
local nick      = arg[1] or "llamabot"
local channel   = arg[2] or "#BlindOE"
local sasl_user = arg[3]
local sasl_pass = arg[4]


if not sasl_user or not sasl_pass then
    print("sasl_user=" .. tostring(sasl_user))
    print("sasl_pass=" .. tostring(sasl_pass))
        print("Usage: lua llamabot.lua <nick> <channel> <NickServAccount> <NickServPassword>")
    os.exit(1)
end

local server = "irc.libera.chat"
local port   = 6667

--------------------------------------------------
-- Connect
--------------------------------------------------
print("starting llamabot")

local client = assert(socket.tcp())
assert(client:connect(server, port))
client:settimeout(0.5)

print("connected to", server)

--------------------------------------------------
-- IMPORTANT: start SASL immediately (restricted networks)
--------------------------------------------------
client:send("CAP LS 302\r\n")
client:send("CAP REQ :sasl\r\n")
client:send("AUTHENTICATE PLAIN\r\n")

--------------------------------------------------
-- State
--------------------------------------------------
local registered = false
local sasl_sent  = false

--------------------------------------------------
-- Main IRC loop (LINE BASED)
--------------------------------------------------
while true do
    local line, err = client:receive("*l")

    if not line then
        if err == "timeout" then
            -- just wait
        elseif err == "closed" then
            print("Connection closed")
            os.exit(1)
        end
    else
        print("<<<", line)

        --------------------------------------------------
        -- PING
        --------------------------------------------------
        if line:match("^PING :") then
            client:send("PONG :" .. line:sub(7) .. "\r\n")
        end

        --------------------------------------------------
        -- AUTHENTICATE challenge
        --------------------------------------------------
        if line == "AUTHENTICATE +" and not sasl_sent then
            print("Sending SASL credentials")
            local auth = "\0" .. sasl_user .. "\0" .. sasl_pass
            local encoded = mime.b64(auth)
            client:send("AUTHENTICATE " .. encoded .. "\r\n")
            sasl_sent = true
        end

        --------------------------------------------------
        -- SASL success
        --------------------------------------------------
        if line:match(" 903 ") then
            print("SASL authentication successful")
            client:send("CAP END\r\n")
            client:send("NICK " .. nick .. "\r\n")
            client:send("USER a a a a\r\n")
        end

        --------------------------------------------------
        -- SASL failure
        --------------------------------------------------
        if line:match(" 904 ") or line:match(" 905 ") then
            print("SASL authentication failed")
            os.exit(1)
        end

        --------------------------------------------------
        -- Welcome (001)
        --------------------------------------------------
        if line:match(" 001 ") and not registered then
            registered = true
            print("Joining channel", channel)
            client:send("JOIN " .. channel .. "\r\n")
        end
    end
end
