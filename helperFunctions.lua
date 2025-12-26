function getBeforeAndAfterSTring(str,pattern)
    str = string.lower(str)
    pattern = string.lower(pattern)

    local start, finish = string.find(str, pattern)

    if start then
        --print("Pattern found at indices:", start, finish)
        local match = string.sub(str, start, finish)
        local before = string.sub(str,1, start-1)
        local after = string.sub(str,finish+1, #str)
        --print("Matched substring:", match)
        --print("before:", before)
        --print("after:", after)
        return before, after
    else
        -- print("Pattern not found")
        return nil,nil
    end
end
function findLastNick(inputString)
    local pattern = "([%w%-_]+)!"  -- Pattern to capture the nickname before the exclamation mark

    local lastNickname
    for nickname in inputString:gmatch(pattern) do
        lastNickname = nickname
    end

    return lastNickname
end
function findLastMessage(inputString,channel)
    local marker = channel.." :" -- whould not realy on colon I heard
    local lastSubstring = ""
    
    local i = 1
    while true do
        local startIdx, endIdx = inputString:find(marker, i, true)
        if startIdx then
            lastSubstring = inputString:sub(endIdx + 1)
            i = endIdx + 1
        else
            break
        end
    end
    return lastSubstring 
end