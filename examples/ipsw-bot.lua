local ipsw = {} -- todo: update api to v4

local api = require('telegram-bot-lua.core').configure('') -- Insert your token here.
local tools = require('telegram-bot-lua.tools')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function ipsw.init()
    ipsw.data = {}
    local jstr, res = https.request('https://api.ipsw.me/v2.1/firmwares.json')
    if res == 200 then
        ipsw.data = json.decode(jstr)
    end
    ipsw.devices = {}
    for k, v in pairs(ipsw.data.devices) do
        if k:lower():match('^appletv') then
            if not ipsw.devices['Apple TV'] then
                ipsw.devices['Apple TV'] = {}
            end
            table.insert(ipsw.devices['Apple TV'], k)
            table.sort(ipsw.devices['Apple TV'])
        elseif k:lower():match('^ipad') then
            if not ipsw.devices['iPad'] then
                ipsw.devices['iPad'] = {}
            end
            table.insert(ipsw.devices['iPad'], k)
            table.sort(ipsw.devices['iPad'])
        elseif k:lower():match('^ipod') then
            if not ipsw.devices['iPod'] then
                ipsw.devices['iPod'] = {}
            end
            table.insert(ipsw.devices['iPod'], k)
            table.sort(ipsw.devices['iPod'])
        elseif k:lower():match('^iphone') then
            if not ipsw.devices['iPhone'] then
                ipsw.devices['iPhone'] = {}
            end
            table.insert(ipsw.devices['iPhone'], k)
            table.sort(ipsw.devices['iPhone'])
        elseif k:lower():match('^mac') then
            if not ipsw.devices['Mac'] then
                ipsw.devices['Mac'] = {}
            end
            table.insert(ipsw.devices['Mac'], k)
            table.sort(ipsw.devices['Mac'])
        end
    end
end

function ipsw.get_info(input)
    local device = input
    local version = 'latest'
    if input:match('^.- .-$') then
        device = input:match('^(.-) ')
        version = input:match(' (.-)$')
    end
    local jstr, res = https.request(string.format('https://api.ipsw.me/v2.1/%s/%s/info.json', url.escape(device),
        url.escape(version)))
    if res ~= 200 or jstr == '[]' then
        return false
    end
    return json.decode(jstr)
end

function ipsw.get_model_keyboard(device)
    local keyboard = {
        ['inline_keyboard'] = {{}}
    }
    local total = 0
    for _, v in pairs(ipsw.devices[device]) do
        total = total + 1
    end
    local count = 0
    local rows = math.floor(total / 20)
    if rows ~= total then
        rows = rows + 1
    end
    local row = 1
    for k, v in pairs(ipsw.data.devices) do
        if k:lower():match(device:lower():gsub(' ', '')) then
            count = count + 1
            if count == rows * row then
                row = row + 1
                table.insert(keyboard.inline_keyboard, {})
            end
            table.insert(keyboard.inline_keyboard[row], {
                ['text'] = v.name:match('^.- (.-)$'),
                ['callback_data'] = 'model:' .. device .. ':' .. k
            })
        end
    end
    table.insert(keyboard.inline_keyboard, {{
        ['text'] = tools.symbols.back .. ' Back',
        ['callback_data'] = 'back'
    }})
    return keyboard
end

function ipsw.get_firmware_keyboard(device, model)
    local keyboard = {
        ['inline_keyboard'] = {{}}
    }
    local total = 0
    for _, v in pairs(ipsw.data.devices[model].firmwares) do
        total = total + 1
    end
    local count = 0
    local rows = math.floor(total / 12)
    if device:lower() == 'ipad' then
      rows = math.floor(total / 18)
    end
    if rows ~= total then
        rows = rows + 1
    end
    local row = 1
    for k, v in pairs(ipsw.data.devices[model].firmwares) do
        count = count + 1
        if count == rows * row then
            row = row + 1
            table.insert(keyboard.inline_keyboard, {})
        end
        table.insert(keyboard.inline_keyboard[row], {
            ['text'] = v.version,
            ['callback_data'] = 'firmware:' .. device .. ':' .. model .. ':' .. v.buildid
        })
    end
    table.insert(keyboard.inline_keyboard, {{
        ['text'] = tools.symbols.back .. ' Back',
        ['callback_data'] = 'back:device:' .. device
    }})
    return keyboard
end

function api.on_callback_query(callback_query)
    ipsw.init()
    local message = callback_query.message
    if callback_query.data == 'back' then
        return api.edit_message_text(message.chat.id, message.message_id,
            'This tool was created by @wrxck, and makes use of the IPSW.me API.\nBefore we begin, please select your device type:',
            nil, nil, nil,
            api.inline_keyboard():row(
                api.row():callback_data_button('iPod Touch', 'device:iPod'):callback_data_button('iPhone',
                    'device:iPhone'):callback_data_button('iPad', 'device:iPad')):row(api.row():callback_data_button(
                      'Apple TV', 'device:Apple TV'):callback_data_button(
                        'Mac', 'device:Mac')))
    elseif callback_query.data:match('^back:') then
        callback_query.data = callback_query.data:match('^back:(.-)$')
    end
    if callback_query.data:match('^device:.-$') then
        callback_query.data = callback_query.data:match('^device:(.-)$')
        return api.edit_message_text(message.chat.id, message.message_id, 'Please select your model:', nil, nil, nil,
            ipsw.get_model_keyboard(callback_query.data))
    elseif callback_query.data:match('^model:.-:.-$') then
        local device, model = callback_query.data:match('^model:(.-):(.-)$')
        return api.edit_message_text(message.chat.id, message.message_id, 'Please select your firmware version:', nil, nil, nil, ipsw.get_firmware_keyboard(device, model))
    elseif callback_query.data:match('^firmware:.-:.-:.-$') then
        local device, model, firmware = callback_query.data:match('^firmware:(.-):(.-):(.-)$')
        firmware = model .. ' ' .. firmware
        local jdat = ipsw.get_info(firmware)
        return api.edit_message_text(message.chat.id, message.message_id, string.format(
            '<b>%s</b> iOS %s\n\n<i>Uploaded on %s at %s</i>\n\n<code>MD5 sum: %s\nSHA1 sum: %s\nFile size: %s GB</code>\n\n<i>%s This firmware is %s being signed!</i>',
            jdat[1].device, jdat[1].version, jdat[1].uploaddate:match('^(.-)T'), jdat[1].uploaddate:match('T(.-)Z$'),
            jdat[1].md5sum, jdat[1].sha1sum, tools.round(jdat[1].size / 1000000000, 2),
            jdat[1].signed == false and utf8.char(10060) or utf8.char(9989),
            jdat[1].signed == false and 'no longer' or 'still'), 'html', nil, nil,
            api.inline_keyboard():row(api.row():url_button(jdat[1].filename, jdat[1].url)):row(
                api.row():callback_data_button(tools.symbols.back .. ' Back', 'back:model:' .. device .. ':' .. model)))
    end
end

function api.on_message(message)
    ipsw.init()
    return api.send_message(message.chat.id,
        'This tool was created by @wrxck, and makes use of the IPSW.me API.\nBefore we begin, please select your device type:',
        nil, 'html', nil, nil, false, false, nil,
        api.inline_keyboard():row(
            api.row():callback_data_button('iPod Touch', 'device:iPod'):callback_data_button('iPhone', 'device:iPhone')
                :callback_data_button('iPad', 'device:iPad')):row(
            api.row():callback_data_button('Apple TV', 'device:Apple TV'):callback_data_button('Mac', 'device:Mac')))
end

api.run()
