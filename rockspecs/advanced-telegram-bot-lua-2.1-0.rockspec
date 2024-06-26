package = "advanced-telegram-bot-lua"
version = "2.1-0"

source = {
    url = "git://github.com/jalhund/advanced-telegram-bot-lua.git",
    dir = "advanced-telegram-bot-lua",
    branch = "main"
}

description = {
    summary = "Advanced version of Lua library for the Telegram bot API. Based on: https://github.com/wrxck/telegram-bot-lua",
    detailed = "A simple yet extensive Lua library for the Telegram bot API, with many tools and API-friendly functions.",
    license = "GPL-3",
    homepage = "https://github.com/wrxck/telegram-bot-lua",
    maintainer = "Denis Makhortov <denismakhortovdev@gmail.com>"
}

supported_platforms = {
    "linux",
    "macosx",
    "unix",
    "bsd"
}

dependencies = {
    "dkjson >= 2.5-2",
    "lpeg >= 1.0.1-1",
    "luasec >= 0.6-1",
    "luasocket >= 3.0rc1-2",
    "multipart-post >= 1.1-1",
    "luautf8 >= 0.1.1-1",
    "html-entities >= 1.3.1-0"
}

build = {
    type = "builtin",
    modules = {
        ["telegram-bot-lua.config"] = "src/config.lua",
        ["telegram-bot-lua.core"] = "src/core.lua",
        ["telegram-bot-lua.tools"] = "src/tools.lua",
        ["telegram-bot-lua.b64url"] = "src/b64url.lua"
    }
}
