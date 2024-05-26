--[[
    Modified standard example to work as timer. Not really accurate to be honest
    because while loop in api.run has some slow calculations. But anyway it can be useful
]]

local api = require('advanced-telegram-bot-lua.core').configure('') -- Enter your token
local json = require('dkjson')
local socket = require('socket')

function api.on_message(message)
    if message.text then
        api.send_message(message, message.text, nil, nil, nil, nil, false, false, nil,
            api.inline_keyboard():row(api.row():callback_data_button('Button', 'callback_data')))
    end
end

function api.on_callback_query(callback_query)
    api.answer_callback_query(callback_query.id, json.encode(callback_query.from))
end

local start_time = socket.gettime()
local last_time = socket.gettime()

api.run(nil, nil, nil, nil, nil, function()
    if socket.gettime() - last_time > 5 then
        last_time = socket.gettime()
        print("Elapsed: ", math.floor(socket.gettime() - start_time))
    end
end)
