if gg.PACKAGE == "com.grh.gwvmm" then
--------------------------------------------------
-- 📁 المسارات
--------------------------------------------------
local SAVE_ID_FILE     = "/sdcard/.gg_install_id.txt"
local SAVE_TIME_FILE   = "/sdcard/.gg_activate_time.txt"
local SAVE_LAST_FILE   = "/sdcard/.gg_last_run.txt"
local SAVE_FIRST_RUN   = "/sdcard/.gg_first_run.txt"
local SAVE_WARN_FILE   = "/sdcard/.gg_warned.txt"

--------------------------------------------------
-- ⏳ الإعدادات
--------------------------------------------------
local EXPIRE_DAYS = 10
local EXPIRE_SECONDS = EXPIRE_DAYS * 86400
local TIME_MARGIN = 3600 -- ساعة سماح
local function hiddenSecret()
  local enc = {23,20,6,24,20,31,20,10,6,20,29,16,7,10,14,16,2,10,105,106,105,110}
  local key = 85
  local s = {}
  for i = 1, #enc do
    s[i] = string.char(bit32.bxor(enc[i], key))
  end
  return table.concat(s)
end

local BASE_SECRET = hiddenSecret()

--------------------------------------------------
-- 🔑 SECRET ديناميكي (يتغير كل 20 يوم)
--------------------------------------------------
local function getDynamicSecret()
  local cycle = math.floor(os.time() / EXPIRE_SECONDS)
  return BASE_SECRET .. "_" .. cycle
end

--------------------------------------------------
-- 🔢 Hash (مطابق لأداة التوليد)
--------------------------------------------------
function simpleHash(text)
  local hash = 5381

  for i = 1, #text do
    local c = string.byte(text, i)
    hash = ((hash * 33) ~ c + (c << 5)) % 2147483647
  end

  hash = (hash ~ (hash >> 16)) * 2246822519
  hash = hash % 1000000007

  return tostring(math.abs(hash))
end

--------------------------------------------------
-- 🆔 توليد ID
--------------------------------------------------
function randomID()
  local t = {}
  for i = 1, 16 do
    t[i] = string.format("%x", math.random(0, 15))
  end
  return table.concat(t)
end

--------------------------------------------------
-- ♻️ إعادة ضبط كاملة (كود جديد)
--------------------------------------------------
local function fullReset(msg)
  os.remove(SAVE_TIME_FILE)
  os.remove(SAVE_LAST_FILE)
  os.remove(SAVE_FIRST_RUN)
  os.remove(SAVE_WARN_FILE)
  gg.alert(msg .. "\n\n🔁 تم إنشاء معرف جديد\n📋 انسخه واطلب كودًا جديدًا")
end

--------------------------------------------------
-- 🔒 فحص التلاعب بالتاريخ
--------------------------------------------------
local function checkTimeIntegrity()
  local now = os.time()
  local f = io.open(SAVE_LAST_FILE, "r")

  if f then
    local last = tonumber(f:read("*l"))
    f:close()
    if last and now + TIME_MARGIN < last then
      fullReset("⛔ تم اكتشاف إرجاع التاريخ للخلف")
      os.exit()
    end
  end

  f = io.open(SAVE_LAST_FILE, "w")
  f:write(now)
  f:close()
end

checkTimeIntegrity()

--------------------------------------------------
-- 🆔 Install ID (جهاز فقط)
--------------------------------------------------
local function getInstallID()
  local f = io.open(SAVE_ID_FILE, "r")
  if f then
    local id = f:read("*l")
    f:close()
    return id
  end
  math.randomseed(os.time())
  local id = randomID()
  f = io.open(SAVE_ID_FILE, "w")
  f:write(id)
  f:close()
  return id
end

--------------------------------------------------
-- 💾 وقت التفعيل
--------------------------------------------------
local function saveActivationTime()
  local f = io.open(SAVE_TIME_FILE, "w")
  f:write(os.time())
  f:close()
end

local function getActivationTime()
  local f = io.open(SAVE_TIME_FILE, "r")
  if not f then return nil end
  local t = tonumber(f:read("*l"))
  f:close()
  return t
end

--------------------------------------------------
-- ⛔ فحص الانتهاء
--------------------------------------------------
local function checkExpire()
  local start = getActivationTime()
  if not start then return false end

  local now = os.time()

  if now + TIME_MARGIN < start then
    fullReset("⛔ تم التلاعب بتاريخ الجهاز")
    os.exit()
  end

  if (now - start) > EXPIRE_SECONDS then
    fullReset("⏳ انتهت مدة التفعيل (10يوم)")
    return false
  end

  return true
end

--------------------------------------------------
-- ⏱️ حساب الوقت المتبقي
--------------------------------------------------
local function getRemainingTimeFull()
  local start = getActivationTime()
  if not start then return 0,0,0 end

  local remaining = EXPIRE_SECONDS - (os.time() - start)
  if remaining < 0 then remaining = 0 end

  local d = math.floor(remaining / 86400)
  remaining = remaining % 86400
  local h = math.floor(remaining / 3600)
  remaining = remaining % 3600
  local m = math.floor(remaining / 60)

  return d, h, m
end

--------------------------------------------------
-- 🔍 فحص أولي
--------------------------------------------------
local activated = checkExpire()

--------------------------------------------------
-- 🆔 USER ID (ثابت لكل البرامج)
--------------------------------------------------
local DEVICE_ID = getInstallID()

--------------------------------------------------
-- 🔐 EXPECTED CODE
--------------------------------------------------
local SECRET = getDynamicSecret()
local EXPECTED_CODE = simpleHash(DEVICE_ID .. SECRET)

--------------------------------------------------
-- 🔐 نظام التفعيل
--------------------------------------------------
if not activated then
  gg.setVisible(true)
  while true do
    if gg.isVisible(true) then
      gg.setVisible(false)

      local c = gg.choice({
        "📋 نسخ USER ID",
        "🔑 إدخال كود التفعيل",
        "❌ خروج"
      }, nil,
      "🔐 نظام التفعيل")

      if c == 3 then os.exit() end

      if c == 1 then
        gg.copyText(DEVICE_ID)
        gg.toast("📋 تم نسخ المعرف")

      elseif c == 2 then
        local i = gg.prompt({"🌸تواصل مع الادمن:"},{""},{"text"})
        if i then
          if i[1]:gsub("%s+", "") == EXPECTED_CODE then
            saveActivationTime()
            local f = io.open(SAVE_FIRST_RUN, "w")
            f:write("1")
            f:close()
            gg.toast("✅ تم التفعيل بنجاح")
            break
          else
            gg.alert("❌ كود غير صحيح")
          end
        end
      end
    end
    gg.sleep(200)
  end
end

--------------------------------------------------
-- ⏳ عرض العداد كل تشغيل
--------------------------------------------------
local d, h, m = getRemainingTimeFull()
gg.alert(
  "⏳ الوقت المتبقي:\n\n" ..
  "🗓 " .. d .. " يوم\n" ..
  "⏰ " .. h .. " ساعة\n" ..
  "⏱ " .. m .. " دقيقة"
)

--------------------------------------------------
-- ⚠️ تنبيه عند بقاء يوم واحد
--------------------------------------------------
local warned = io.open(SAVE_WARN_FILE, "r")
if d == 1 and not warned then
  local wf = io.open(SAVE_WARN_FILE, "w")
  wf:write("1")
  wf:close()

  gg.alert(
    "⚠️ تنبيه هام\n\n" ..
    "لم يتبقَّ لكم سوى يوم واحد ⏳\n\n" ..
    "📢 تفاعلوا على منشورات الفيسبوك\n" ..
    "لكي تحصلوا على الرمز الجديد"
  )
end
if warned then warned:close() end

--------------------------------------------------
-- ✅ انتهى نظام التفعيل والحماية
--------------------------------------------------

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
            url = "https://b-servers.qdmasnmdy.workers.dev/2.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ხᥲ᥉ꪔᥲᥣᥲ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/1.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デ ꪀᥲᖇᥱᥱꪀ══━一",
            url = "https://b-servers.qdmasnmdy.workers.dev/3.xml",
            names = {"mGameInfo.xml", "mGameInfo.bak"}
        },

        {
            title = "▄︻デᥲɦᥣᥲꪔ᥆══━一",
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

    gg.alert("🌺 تم " .. selected.title .. " النسخ 🌺")
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
  else
	gg.alert('🎲قم بتحميل الجاردن الخاص بكروب سنه اولى تطوير 🎲')
end
