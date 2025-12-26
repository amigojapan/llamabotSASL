#!/usr/bin/lua

--------------------------------------------------
-- Requires
--------------------------------------------------
local socket = require("socket")
local http   = require("socket.http")
local ltn12  = require("ltn12")
local mime   = require("mime")
local JSON   = require("json")

--------------------------------------------------
-- Arguments
--------------------------------------------------
local nick      = arg[1] or "llamabot"
local channel   = arg[2]
local sasl_user = arg[3]
local sasl_pass = arg[4]
local MODEL     = arg[5]

if not channel or not sasl_user or not sasl_pass then
    print("Usage: lua llamabot.lua <nick> <channel> <NickServAccount> <NickServPassword>")
    os.exit(1)
end

--------------------------------------------------
-- Server
--------------------------------------------------
local server = "irc.libera.chat"
local port   = 6667

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function send_privmsg(target, text)
    if not text then
        text = "(no response)"
    end
    client:send("PRIVMSG " .. target .. " :" .. text .. "\r\n")
end

local function stripCRLF(str)
    return str:gsub("[\r\n]+", "")
end

local function removeApostrophes(s)
    return s:gsub("[\"'%;|><%(%)%[%]{}]", "")
end

--------------------------------------------------
-- HTTP POST (Ollama, stateless)
--------------------------------------------------
local function post(uri, data)
    local body = {}
    http.request{
        method = "POST",
        url = uri,
        source = ltn12.source.string(data),
        headers = {
            ["content-type"] = "application/json",
            ["content-length"] = #data
        },
        sink = ltn12.sink.table(body)
    }
    return table.concat(body)
end

--------------------------------------------------
-- Connect
--------------------------------------------------
print("starting llamabot")

client = assert(socket.tcp())
assert(client:connect(server, port))
client:settimeout(0.5)

print("connected to", server)

--------------------------------------------------
-- SASL (required by Libera)
--------------------------------------------------
client:send("CAP LS 302\r\n")
client:send("CAP REQ :sasl\r\n")
client:send("AUTHENTICATE PLAIN\r\n")

local registered = false
local sasl_sent  = false

--------------------------------------------------
-- Main loop
--------------------------------------------------
while true do
    local line, err = client:receive("*l")

    if not line then
        if err == "closed" then
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
        -- SASL challenge
        --------------------------------------------------
        if line == "AUTHENTICATE +" and not sasl_sent then
            local auth = "\0" .. sasl_user .. "\0" .. sasl_pass
            client:send("AUTHENTICATE " .. mime.b64(auth) .. "\r\n")
            sasl_sent = true
        end

        --------------------------------------------------
        -- SASL success
        --------------------------------------------------
        if line:match(" 903 ") then
            print("SASL OK")
            client:send("CAP END\r\n")
            client:send("NICK " .. nick .. "\r\n")
            client:send("USER llama 0 * :llamabot\r\n")
        end

        --------------------------------------------------
        -- SASL failure
        --------------------------------------------------
        if line:match(" 904 ") or line:match(" 905 ") then
            print("SASL failed")
            os.exit(1)
        end

        --------------------------------------------------
        -- Welcome
        --------------------------------------------------
        if line:match(" 001 ") and not registered then
            registered = true
            client:send("JOIN " .. channel .. "\r\n")
        end

        --------------------------------------------------
        -- PRIVMSG handling
        --------------------------------------------------
        local prefix, cmd, target, message =
            line:match("^:([^ ]+) ([^ ]+) ([^ ]+) :(.+)$")

        if cmd == "PRIVMSG" then
            local msg = stripCRLF(message)

            --------------------------------------------------
            -- !askai (summary)
            --------------------------------------------------
            if msg:sub(1,6) == "!askai" then
                local prompt = removeApostrophes(msg:sub(8))
                prompt = "a summary " .. prompt .. " in 240 characters or less in one line"

                local r = post(
                    "http://localhost:11434/api/generate",
                    '{"model":"'.. MODEL..'","prompt":"'..prompt..'","stream":false}'
                )

                if not r or r == "" then
                    send_privmsg(target, "AI error: no response")
                else
                    local obj = JSON.decode(r)
                    if obj.error then
                        send_privmsg(target, "AI error: " .. obj.error)
                    else
                        send_privmsg(target, obj.response)
                    end
                end
            end

            --------------------------------------------------
            -- !tellai (direct)
            --------------------------------------------------
            if msg:sub(1,7) == "!tellai" then
                local prompt = removeApostrophes(msg:sub(9))

                local r = post(
                    "http://localhost:11434/api/generate",
                    '{"model":"'.. MODEL..'","prompt":"'..prompt..'","stream":false}'
                )
                
                if not r or r == "" then
                    send_privmsg(target, "AI error: no response")
                else
                    local obj = JSON.decode(r)
                    if obj.error then
                        send_privmsg(target, "AI error: " .. obj.error)
                    else
                        send_privmsg(target, obj.response)
                    end
                end
            end

            --------------------------------------------------
            -- !feliz cumpleaños
            --------------------------------------------------
            if msg:match("^!feliz") then
                send_privmsg(
                    target,
                    "feliz cumpleaños zcom, de cosmicadventure y amigojapan! https://www.youtube.com/watch?v=cDT12zAWDuM"
                )
            end
        end
    end
end
