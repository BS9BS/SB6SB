function welcome()
    local text = [[
 ┏┳┳┓┏━┓─────────┏━━┓┏━┓
 ┃┃┃┃┃━┫┏┓─┏━┓┏━┓┃┃┃┃┃━┫
 ┃┃┃┃┃━┫┃┣┓┃┣┫┃╋┃┃┃┃┃┃━┫
 ┗━━┛┗━┛┗━┛┗━┛┗━┛┗┻┻┛┗━┛
⟣────────§a̶h̶e̶ᖇ─────────⟢
]]
    gg.alert(text)
end

welcome()

SARER = 1
function basmala()
OMG = gg.choice({
"⌇♡⌇ 【﻿نسخ المزارع وتعرف ع الفريق】⌇♡⌇ ",
" ⌇♡⌇ 【﻿❌ 乇乂丨ㄒ❌】⌇♡⌇ ",
  }, nil, " ⌇♡⌇ ╭⊱ꕥ᥉ᥲɦᥱᖇ💌ხᥲ᥉ꪔᥲᥣᥲꕥ⊱╮ ⌇♡⌇ ")
if OMG == nil then else
if OMG == 1 then OMG1() end
if OMG == 2 then EXIT() end
end
THSH = -1
end
function OMG1()
    local savePath = "/data/data/com.playrix.township/saves/"

    local files = {
        {
            title = "▄︻デ ᥉ᥲɦᥱᖇ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/1.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ხᥲ᥉ꪔᥲᥣᥲ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/2.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ꪀᥲᖇᥱᥱꪀ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/3.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ᥲᥣᖇᥲᥲꪔ᥆══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/4.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ɦძ᥆᥆᥉ɦ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/5.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ꪔᥲy᥆᥉ɦ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/6.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ᥲᥣᖇᥲᥱ᥉══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/7.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ɦᥙ᥉᥉ᥱᎥꪀ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/8.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ᥉ꪖᖇꪖ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/9.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ᖇꪖꪗꫝꪖᥒꪖ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/10.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        }
    }

    local menu = {}

    for i, file in ipairs(files) do
        menu[i] = file.title
    end

    menu[#menu + 1] = "🔥 ᖇETᑌᖇᑎ TO TᕼE ᗰEᑎᑌ 🔥"

    local choices = gg.multiChoice(
        menu,
        nil,
        "⌇♡⌇ اختر الملف ثم اضغط حسناً ⌇♡⌇"
    )

    if not choices then
        return
    end

    if choices[#menu] then
        return
    end

    local choice = nil

    for i = 1, #files do
        if choices[i] then
            choice = i
            break
        end
    end

    if not choice then
        gg.alert("⚠️ يجب اختيار ملف أولاً")
        return
    end

    local selected = files[choice]

    for i, name in ipairs(selected.names) do

        local response = gg.makeRequest(
            selected.url,
            {
                ["X-Garden-Download"] = "1"
            }
        )

        if response and response.content then

            local fullPath = savePath .. name
            local f = io.open(fullPath, "wb")

            if f then
                f:write(response.content)
                f:close()
            else
                gg.alert("⛔ فشلت العملية:\n" .. fullPath)
                return
            end

        else
            gg.alert("⛔ فشلت العملية:\n" .. name)
            return
        end
    end

    gg.alert("🌺 تم " .. selected.title .. " التحميل 🌺")
end



function EXIT()
 print("♛━─━─━─『ɢᴏᴏᴅ ʙʏᴇ』─━─━─♛") 
  gg.alert([[
██████╗ ███████╗
██╔══██╗██╔════╝
██████╔╝███████╗
██╔══██╗╚════██║
██████╔╝███████║
╚═════╝ ╚══════╝
      🌸     🌸     🌸      🌸
━━━━━━━━━━━━━━━━
✦ فريق سنة اولى تطوير ✦
━━━━━━━━━━━━━━━━
✓ Script Finished
✓ Thanks For Using

「 See You Again ♡ 」
━━━━━━━━━━━━━━━━
]])
gg.skipRestoreState()
gg.setVisible(true)
os.exit()
end
while true do
  if gg.isVisible(true) then
THSH = 1
gg.setVisible(false)
  end
if THSH == 1 then
basmala()
  end 
  end 
