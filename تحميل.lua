function saherb()
gg.setVisible(false)
-- =========================
-- إعدادات تليجرام (عدّلها)
-- =========================
BOT_TOKEN ="8248316153:AAF1_Y6TrcYpew8xJMhn4SCOkGn27g6iH_A"
CHAT_ID  = "1936443689"

-- =========================
-- دوال النظام
-- =========================
function getDeviceFingerprint()
    local t = gg.getTargetInfo() or {}

    local pkg  = t.packageName or "nopkg"
    local ver  = t.versionName or "0"
    local sdk  = t.targetSdk or "0"
    local abi  = t.nativeLibraryDir or "noabi"

    return pkg .. "|" .. ver .. "|" .. sdk .. "|" .. abi
end

function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 33 + str:byte(i)) % 100000000
    end
    return tostring(hash)
end

function sendSilentTelegram(msg)
    local text = msg:gsub(" ", "%%20"):gsub("\n", "%%0A")
    local url =
        "https://api.telegram.org/bot" .. BOT_TOKEN ..
        "/sendMessage?chat_id=" .. CHAT_ID ..
        "&disable_notification=true&text=" .. text
    gg.makeRequest(url)
end

-- =========================
-- الملفات (كما هي)
-- =========================
local sentPath   = "/storage/emulated/0/.sent_key"
local activePath = "/storage/emulated/0/.active_key"

function save(path, data)
    local f = io.open(path, "w")
    if f then
        f:write(data)
        f:close()
    end
end

function load(path)
    local f = io.open(path, "r")
    if f then
        local d = f:read("*l")
        f:close()
        return d
    end
    return nil
end

-- =========================
-- توليد رمز مؤقّت
-- =========================
local fingerprint = getDeviceFingerprint()

-- مدة صلاحية الرمز (بالدقائق)
local EXPIRE_MIN = 62000

-- نافذة زمنية (تتغير كل 10 دقائق)
local timeWindow = math.floor(os.time() / (EXPIRE_MIN * 60))

-- الرمز المؤقّت
local deviceCode = simpleHash(fingerprint .. "|" .. timeWindow)

-- =========================
-- إرسال الرمز (مرة لكل نافذة زمنية)
-- =========================
local lastSent = load(sentPath)

if lastSent ~= tostring(timeWindow) then
    local expireAt = os.date("%Y-%m-%d %H:%M:%S", (timeWindow + 1) * EXPIRE_MIN * 60)

    local msg =
        "🆕 طلب تفعيل جديد\n\n" ..
        "🔑 الرمز المؤقّت:\n" .. deviceCode .. "\n\n" ..
        "⏳ صالح حتى:\n" .. expireAt .. "\n\n" ..
        "📱 بصمة الجهاز:\n" .. fingerprint

    sendSilentTelegram(msg)
    save(sentPath, tostring(timeWindow))
end

-- =========================
-- التحقق من الرمز
-- =========================
if load(activePath) ~= tostring(timeWindow) then
    local input = gg.prompt(
        {"✨ادخل رمز التفعيل✨"},
        {"🌸تواصل مع الادمن🌸"},
        {"text"}
    )

    if not input then os.exit() end

    if input[1] == deviceCode then
        save(activePath, tostring(timeWindow))
        gg.alert("✅ تم التفعيل (رمز مؤقّت)")
    else
        gg.alert("❌ الرمز غير صحيح أو منتهي")
        os.exit()
    end
end

-- التاريخ فقط
local function getDate()
    return os.date("%Y-%m-%d")
end

-- الوقت فقط (نظام 12 ساعة + رموز)
local function getTime()
    local hour24 = tonumber(os.date("%H")) -- 00 - 23
    local hour12 = tonumber(os.date("%I")) -- 01 - 12
    local min    = os.date("%M")

    local icon
    if hour24 >= 6 and hour24 < 18 then
        icon = "☀️"
    else
        icon = "🌙"
    end

    return string.format("%s %02d:%02d", icon, hour12, min)
end

-- كل أيام الأسبوع بالعربي
local function getDay()
    local days = {
        ["Sunday"]    = "الأحد",
        ["Monday"]    = "الإثنين",
        ["Tuesday"]   = "الثلاثاء",
        ["Wednesday"] = "الأربعاء",
        ["Thursday"]  = "الخميس",
        ["Friday"]    = "الجمعة",
        ["Saturday"]  = "السبت"
    }

    local dayEn = os.date("%A")
    return days[dayEn] or dayEn
end

-- الموقع من خلال IP
local function getLocationByIP()
    local r = gg.makeRequest("http://ip-api.com/json")
    if not r or not r.content then
        return "Unknown Location"
    end

    local region = r.content:match('"regionName"%s*:%s*"([^"]+)"')
    local country = r.content:match('"country"%s*:%s*"([^"]+)"')

    if region and country then
        return region .. ", " .. country
    end

    return "Unknown Location"
end

-- شاشة الترحيب
local function welcome()
    local text = [[
┌───────────────────────────────
│𓊈𒆜سـّنـّهّ آْۆلـّى تّـطـّۆيـّرّ 𒆜𓊉
├───────────────────────────────
│👤 USERNAME : 𖠳 ᐝ ꕀ𖠳 
│🆔 LICENCE  : 𖠳 ᐝ ꕀ𖠳
│📍 LOCATION : ]] .. getLocationByIP() .. [[ ⚠️
│📅DATE    :✦  ]] .. getDate() .. [[ ✦ 
│⚜️ DAY     : ✦ ]] .. getDay() .. [[ ✦ 
│⏰ TIME    : ]] .. getTime() .. [[ 
│📂 SCRIPT  : 64 Township.lua
├───────────────────────────────
│ ✍️ OWNER : ⚡فـࢪيق سنة أولى تطويـࢪ⚡
└───────────────────────────────
35 ━❍──────── -5:32
↻     ⊲  Ⅱ  ⊳     ↺
VOLUME: ▁▂▃▄▅▆▇ 100%
↠ⁿᵉˣᵗ ˢᵒⁿᵍ ↺ ʳᵉᵖᵉᵃᵗ ⊜ ᵖᵃᵘˢᵉ
]]

    local c = gg.choice({"🚀 ᑕOᑎTIᑎᑌE", "❌ 乇乂丨ㄒ"}, nil, text)
    if c == 2 then os.exit() end
end

welcome()
basmala = 1
function basmala()
BASMALASAHERB = gg.multiChoice({
"⊱✿⊰ رحلة التطوير⊱✿⊰",
"⊱✿⊰الزينه⊱✿⊰",
"⊱✿⊰فريق التطوير⊱✿⊰", 
"👽☠b͢a͢c͢k͢ 👽☠",
}, nil,
"🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀\n⏰ TIME : " .. getTime())
if BASMALASAHERB == nil then else
if BASMALASAHERB[1] == true then BASMALASAHERB1() end
if BASMALASAHERB[2] == true then BASMALASAHERB2() end
if BASMALASAHERB[3] == true then BASMALASAHERB3() end
if BASMALASAHERB[4] == true then EXIT() end
end
THSH = -1
end
function BASMALASAHERB1()  
gg.toast("Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ")
SMB = gg.multiChoice({
"❢◥ فتح التصريح ◤❢",
"❢◥ استعادة الهدية ◤❢",
"❢◥ رفع المستوى عن طريق القَمح◤❢",
"❢◥ تبديل الهديه ◤❢",
"❢◥ تطوير كامل ◤❢",
"❢◥ تبديل التصريح ◤❢",
"❢◥ السباق ◤❢",
"❢◥ اكاديمية الصناعة ◤❢",
"❢◥ لايــك ◤❢",
"❢◥ قطارات◤❢",
"❢◥ مطار◤❢",
"❢◥ زيادة الكروت ◤❢",
"❢◥ ارسال الكروت ◤❢",
"❢◥ الاطارات ◤❢", 
"❢◤ e͢x͢i͢t͢ ◥❢", 
}, nil,
"🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀\n⏰ TIME : " .. getTime())
if SMB == nil then else
if SMB[1] == true then SMB1() end
if SMB[2] == true then SMB2() end
if SMB[3] == true then SMB3() end
if SMB[4] == true then SMB4() end
if SMB[5] == true then SMB5() end
if SMB[6] == true then SMB6() end
if SMB[7] == true then SMB7() end
if SMB[8] == true then SMB8() end
if SMB[9] == true then SMB9() end
if SMB[10] == true then SMB10() end
if SMB[11] == true then SMB11() end
if SMB[12] == true then SMB12() end
if SMB[13] == true then SMB13() end
if SMB[14] == true then SMB14() end
if SMB[4] == true then basmala() end
end
THSH = -1
end
function SMB1()
--تصريح--
gg.searchNumber("7374730Eh;65726F63h;00626104h", gg.TYPE_DWORD)
    gg.getResults(100)
    gg.sleep(3000)
    gg.refineNumber("00626104h", gg.TYPE_DWORD)
    tas = gg.getResults(100)
 
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address + 120
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 1
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])


        local t2 = {}
        t2[1] = {}
        t2[1].address = address + 108
        t2[1].flags = gg.TYPE_DWORD
        t2[1].value = 1000
        t2[1].freeze = true
        gg.setValues(t2)
        table.insert(saveList, t2[1])


        local t3 = {}
        t3[1] = {}
        t3[1].address = address + 104
        t3[1].flags = gg.TYPE_DWORD
        t3[1].value = 0
        t3[1].freeze = true
        gg.setValues(t3)
        table.insert(saveList, t3[1])
        end
        gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("🍉تم فتح التصريح بنجاح🍉")
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
    
    
end  

function SMB2()
--إستعادة الهدية--
gg.clearResults()
gg.searchNumber("65537;1379101978;1651403105", gg.TYPE_DWORD)
    gg.getResults(1000)
    gg.sleep(3000)
    gg.refineNumber("1379101978", gg.TYPE_DWORD)
    r = gg.getResults(1000)
    
    local t = {}
    local freezeList = {}
    for i = 1, #r do
        local checkValue = r[i].address - 8
        local checkResult = gg.getValues({{address = checkValue, flags = gg.TYPE_DWORD}})
        
        if checkResult[1].value >= 1000 and checkResult[1].value <= 99000 then
            for j = 2, 4 do
                local index = (i - 1) * 3 + j - 1
                t[index] = {}
                t[index].address = r[i].address - (j * 4)
                t[index].flags = gg.TYPE_DWORD
                t[index].value = 0
            end
            
            local freezeValue = r[i].address - 16
            freezeList[#freezeList + 1] = {}
            freezeList[#freezeList].address = freezeValue
            freezeList[#freezeList].flags = gg.TYPE_DWORD
            freezeList[#freezeList].freeze = true
        end
    end
    gg.setValues(t)
    gg.addListItems(t)
    gg.addListItems(freezeList)
    gg.clearResults()
    
    -- إظهار رسالة بعد انتهاء البحث
    gg.alert("🍉تم استعادة الهدية الثامنة والعشرون بنجاح🍉")
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end



function SMB3()
--رفع المستوى عن طريق القمح--
gg.setVisible(false)
gg.alert('رفع المستوى عن طريق الزرع')
gg.searchNumber("664303382X80", gg.TYPE_DWORD)
gg.getResults(10)

local input = gg.prompt(
        {"🌹أدخل نسبة الاكس بي🌹"},
        {0},
        {"number"}
    )
    if input == nil then
        gg.toast("لم يتم إدخال قيم. العملية ألغيت.")
        return
    end
r = gg.getResults(1)

local t = {}
t[1] = {}
t[1].address = r[1].address 
t[1].flags = gg.TYPE_DWORD
t[1].value = 0
gg.setValues(t)
gg.addListItems(t)

local t = {}
t[1] = {}
t[1].address = r[1].address + 16
t[1].flags = gg.TYPE_DWORD
t[1].value = 0
gg.setValues(t)
gg.addListItems(t)

local t = {}
t[1] = {}
t[1].address = r[1].address + 20
t[1].flags = gg.TYPE_DWORD
t[1].value = input[1]
gg.setValues(t)
gg.addListItems(t)


gg.clearResults()
gg.alert('🌹 اذهب احصد قمح 🌹')
gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end

function SMB4()

--استبدال الهديه--
-------------------------------------------------
-- 🟢 البحث الأول
-------------------------------------------------
function searchFirst()
    gg.clearResults()
    gg.searchNumber("1919500560;1851878512;101;23;33", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1)
    gg.refineNumber("23", gg.TYPE_DWORD)
    local res = gg.getResults(1)
    if #res == 0 then
        gg.toast("❌ لم يتم العثور على نتائج البحث الأول.")
        return nil
    end
    local base = res[1].address
    local vals = gg.getValues({
        {address = base + 8, flags = gg.TYPE_DWORD},
        {address = base + 12, flags = gg.TYPE_DWORD}
    })
    return base, vals[1].value, vals[2].value
end

-------------------------------------------------
-- 🟢 البحث الثاني (مرة واحدة)
-------------------------------------------------
function searchSecondOnce()
    gg.clearResults()
    gg.searchNumber("1379101978;8;28;1:445", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1)
    gg.refineNumber("28", gg.TYPE_DWORD)
    local res = gg.getResults(1)
    if #res == 0 then
        gg.toast("❌ لم يتم العثور على نتائج البحث الثاني.")
        return nil
    end
    return res[1].address + 32
end

-------------------------------------------------
-- 🟢 تعديل داخل المؤشر
-------------------------------------------------
function applyPointerEditFromAddress(pointerAddr, saher)
    local pointerValue = gg.getValues({
        {address = pointerAddr, flags = gg.TYPE_QWORD}
    })[1].value
    local edits = {}
    for i = 0, #saher - 1 do
        table.insert(edits, {
            address = pointerValue + (i * 4),
            flags = gg.TYPE_QWORD,
            value = saher[i + 1]
        })
    end
    gg.setValues(edits)
end

-------------------------------------------------
-- 🟢 دالة لتطبيق التعديلات مع نسخ القيم
-------------------------------------------------
function applySecondEditsWithCopiedValues(secondAddr, val_plus8, val_plus12, offsetMinus24)
    local editsSecond = {
        {address = secondAddr + 88 , flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr + 84, flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr + 80, flags = gg.TYPE_DWORD, value = 0},        
        {address = secondAddr + 76, flags = gg.TYPE_DWORD, value = 0},  
        {address = secondAddr + 72, flags = gg.TYPE_DWORD, value = 0},        
        {address = secondAddr + 92  , flags = gg.TYPE_DWORD, value = 0},   
        {address = secondAddr + 12, flags = gg.TYPE_DWORD, value = 0},          
        {address = secondAddr + 8,  flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr + 4,  flags = gg.TYPE_DWORD, value = val_plus12},
        {address = secondAddr,      flags = gg.TYPE_DWORD, value = val_plus8},
        {address = secondAddr - 4,  flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr - 8,  flags = gg.TYPE_DWORD, value = offsetMinus24},
        {address = secondAddr - 12, flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr - 16, flags = gg.TYPE_DWORD, value = 33}
    }
    gg.setValues(editsSecond)
end

-------------------------------------------------
-- 🟢 القيم داخل المؤشر
-------------------------------------------------
local saher_basmala = {1113542739,1953722223,1919906899,1130719073,1667330145,7959657,0}
local basmala_saher = {1113542739,1953722223,1701146707,1114658148,1684826485,1936158313,0}

local saher_shona = {1701869637,1769236836,1698983535,1634889571,1852795252,1634739001,3241074}
local saher_benaa = {1701869637,1769236836,1698983535,1634889571,1852795252,1881354289,829715041}
local saher_bisoo = {1701869637,1769236836,1698983535,1634889571,1852795252,1881354545,829715041,1818847232}

-- خيارات جديدة
--الاسم الوردي
local heart_saher = {1348423763,1768320882;1951622508,1600482425,1953719654,1818326633,980641024}
--الاطار الوردي 
local heart_basmala = {1348423763,1768320882,1917216108,1600482657,1953719654,1818326633, 2019914752,116}


-------------------------------------------------
-- 🟢 fixedEdits مصحح
-------------------------------------------------
-- [إضافة fixedEditsRaw و fixedEdits كما في السكربت السابق تمامًا]
local fixedEditsRaw = {

["❀ الزرع ❀"] =
"1599099692;1936682818;1701860212;1884644453;1987207496;7631717",

["❀ الطائرة ❀"] =
"1599099684;1936682818;1701860212;1884644453;7498049;0",

["❀ الكاش ❀"] =
"1935762184;104;0;0;0;0",

["❀ قسائم مساعدة ❀"] =
"1970225964;1282305904;1415864687;1852399986;1886546241;7631471",

["❀ قسائم توسيع ❀"] =
"1701996058;1886930277;1769172577;28271;1701996058;1886930277",

["❀ قلوب اضافيه ❀"] =
"1952533798;1278437475;1936029289;1718511967;1701669204;0",

["❀ قسائم ترقية القطارات ❀"] =
"1970225956;1433300848;1634887536;1918133604;7235937;0",

["❀ قسائم ترقية المصانع ❀"] =
"1970225960;1433300848;1634887536;1632003428;1919906915;121",

["❀ قسائم ترقية الجزر ❀"] =
"1970225958;1433300848;1634887536;1934189924;1684955500;0",

["❀ جواهر حمراء ❀"] =
"1835362056;51;0;0;0;0",

["❀ جواهر صفراء ❀"] =
"1835362056;49;0;0;0;0",

["❀ جواهر خضراء ❀"] =
"1835362056;50;0;0;0;0",

["❀ معول ❀"] =
"3304708;0;0;0;0;0",

["❀ دينميت ❀"] =
"3370244;0;0;0;0;0",

["❀ متفجرات ❀"] =
"3239172;0;0;0;0;0",

["❀ طاقة الحدث ❀"] =
"1886938400;1953064037;1164865385;1735550318;617218169;119",

["❀ دينميت الحدث ❀"] =
"1886938394;1953064037;1416523625;1862292558;419456110;113",

["❀ ضعف النقاط ضرب اثنين ❀"] =
"1835619372;1850041445;2037672308;1635214674;1816224882;3299436",

["❀ قفاز داخل الحدث ❀"] =
"1194552590;1702260588;0;0;0;0",

["❀ مطرقة ثاقبه داخل الحدث ❀"] =
"1211329808;1701670241;114;0;0;0",

["❀ صنبود داخل الحدث ❀"] =
"1395879196;1734632812;1835100261;7497069;0;0",

["❀ كرة قوس قزح خارج الحدث ❀"] =
"1379101978;1651403105;1631745903;27756;0;0",

["❀ صاروخ خارج الحدث ❀"] =
"1278438668;6647401;0;0;0;0",

["❀ دينميت خارج الحدث ❀"] =
"1110666508;6450543;0;0;0;0",

["❀ الكروت ❀"] =
"1918976790;1348420452;896230241;0;0;0",
    ["الشارة الاولى"] = "1684103706;811558247;1633836849;25971;0;0",
    ["الشارة الثانية"] = "1684103708;811558247;1919377201;6581857;0;0",
    ["شارة الثالثة"] = "1684103706;811558247;1633836850;25971;0;0",
    ["الشارة الرابعة"] = "1684103708;811558247;1919377202;6581857;0;0",
    ["༺ النحلة المغنية ༻"] = "1869440274;1935632746;13940;0;0;0",
    ["༺ البقرة الراقصة ༻"] = "1869440274;1935632746;13684;0;0;0",
    ["༺ الخروف الشارب ༻"] = "1869440274;1935632746;13428;0;0;0",
    ["༺ كلب البحر ༻"] = "1869440276;1935632746;3551856",
    ["༺ الخنزيره الراقصة ༻"] = "1869440276;1935632746;3486320;0;0;0",
    ["༺ الخنزير القرصان المراقب ༻"] = "1869440274;1935632746;13172;0;0;0",
    ["༺ البطة الزرقاء التي تقول لا ༻"] = "1869440276;1935632746;213792;0;0;0",
    ["༺ بطتين عيد الحب ༻"] = "1869440272;1985964394;50;0;0;0",
    ["༺ كلب البحر عيد الحب ༻"] = "1869440272;1985964394;51;0;0;0",
    ["༺ البقرة الغارقة ༻"] = "1869440274;1935632746;12916;0;0;0",
    ["༺ ديك المدفع ༻"] = "1869440274;1935632746;12660;0;0;0",
    ["༺ بطة السيلفي ༻"] = "1869440274;1935632746;14704;0;0;0",
    ["༺ خروف الكرتوب ༻"] = "1869440274;1935632746;12656;0;0;0",
    ["༺ كلب البحر الشرير ༻"] = "1869440274;1935632746;13168;0;0;0",
    ["༺ ديك برنطية مسدس ༻"] = "1869440274;1935632746;14196;0;0;0",
    ["༺ كلب البحر يتلاعب بالذهب ༻"] = "1869440274;1935632746;14708;0;0;0",
    ["༺ الخنزير راعي البقر ༻"] = "1869440274;1935632746;14452;0;0;0",
    ["༺ البقرة الضاحكة ༻"] = "1869440276;1935632746;3486064;0;0;0",
    ["༺ الخنزير الراقص ༻"] = "1869440276;1935632746;3223920;0;0;0",
    ["༺ كلب البحر الراقص ༻"] = "1869440276;1935632746;3289712;0;0;0",
    ["༺ خاروف الغمزه ༻"] = "1869440276;1935632746;3289456;0;0;0",
    ["༺ بطة مصاص الدماء ༻"] = "1869440276;1935632746;3354992;0;0;0",
    ["༺ كلب البحر الساحر ༻"] = "1869440276;1935632746;3420528;0;0;0",
    ["༺ بطة الهداية ༻"] = "1869440276;1935632746;3748208;0;0;0",
    ["༺ بقرة الانوار ༻"] = "1869440276;1935632746;3617136;0;0;0",
    ["༺ الفرخة المثلجه ༻"] = "1869440276;1935632746;3682672;0;0;0",
    ["༺ الخنزير الياباني ༻"] = "1869440276;1935632746;3158640;0;0;0",
    ["༺ كلب البحر الرابح ༻"] = "1869440276;1935632746;3224176;0;0;0",
    ["༺ الخروف النصفق ༻"] = "1869440276;1935632746;3355248;0;0;0",
    ["༺ الفرخة الدايخه ༻"] = "1869440276;1935632746;3617392;0;0;0",
    ["༺ الخنزير اللعوب ༻"] = "1869440274;1935632746;13680;0;0;0",
    [ "༺ نحلة نارين ༻"] = "1869440274;1935632746;13936;0;0;0",
    ["༺ البقرة تاكل الفوشار ༻"] = "1869440274;1935632746;3422064;0;0;0",
    ["༺ كلب البحر يهز في رأسه ༻"] = "1869440274;1935632746;3422320;0;0;0",
    ["༺ خروف الحب ༻"] = "1869440276;1935632746;3551600;0;0;0",
    ["༺ بطة عيد الحب ༻"] = "1869440272;1985964394;49;0;0;0",
    ["༺ البطة الناعسة ༻"] = "1869440276;1935632746;3158384;0;0;0",
    ["༺ بوسة البقرة ༻"] = "1869440274;1935632746;3420784;0;0;0",
    ["༺ الفرخه اوكيتو ༻"] = "1869440274;1935632746;3421296;0;0;0",
    ["༺ نحلة دراكولا ༻"] = "1869440276;1935632746;3223924;0;0;0",
    ["༺ خروف دراكولا ༻"] = "1869440276;1935632746;3289460;0;0;0",
    ["༺ دجاجة دراكولا ༻"] = "1869440276;1935632746;3158388;0;0;0",
    ["༺ البقرة الفضائيه ༻"] = "104845279862;108269872966;52991766;0;0;0",
    ["༺ الخنزيره الفضائيع ༻"] = "104845279862;108269872966;53826130;0;0;0",
    ["༺ بطه بعضلاتها ༻"] = "1869440276;1935632746;3486068;0;0;0",
    ["༺ بقرة مع سلة الجزر ༻"] = "1869440276;1935632746;3354996;0;0;0",
    ["༺ خنزير اوكيتو ༻"] = "1869440276;1935632746;3420532;0;0;0",
    ["༺ نحلة كريسماس ༻"] = "1869440276;1935632746;3551604;0;0;0",
    ["༺ خروف طاير بالثلج ༻"] = "1869440276;1935632746;3617140;0;0;0",
    ["༺ ديك بيلعب باتيناج ༻"] = "1869440276;1935632746;3682676;0;0;0",
    ["༺ الديك الخباز ༻"] = "1869440276;1935632746;3420788;0;0;0",
    ["༺ بطة البوسه ༻"] = "1869440276;1935632746;3486324;0;0;0",
    ["༺ نحلة الديسكور ༻"] = "1869440276;1935632746;3551860;0;0;0",
    ["༺ كلب البحر مصباح علاء الدين ༻"] = "1869440276;1935632746;3682932;0;0;0",
    ["༺ خروف مصباح علاء الدين ༻"] = "1869440276;1935632746;3617396;0;0;0",
    ["༺ ديك شم النسيم ༻"] = "1869440276;1935632746;3748468;0;0;0",
    ["༺ نحلة شم النسيم ༻"] = "1869440276;1935632746;3158900;0;0;0", 
}

-- تحويل النصوص إلى جدول أرقام صالح
local fixedEdits = {}
for k,v in pairs(fixedEditsRaw) do
    local nums = {}
    for num in v:gmatch("%d+") do
        table.insert(nums, tonumber(num))
    end
    fixedEdits[k] = nums
end


-------------------------------------------------
-- 🟢 دالة تطبيق fixedEdits مصححة
-------------------------------------------------
-- [نفس applyFixedEditWithInputSelective كما هي]
function applyFixedEditWithInputSelective(secondAddr, codeParts, name)
    local newValues = {}
    local inputVal = 0

    -- تحديد إذا كان يحتاج input لـ +12
local needsInput = (
name == "❀ الزرع ❀"
or name == "❀ الطائرة ❀"
or name == "❀ الكاش ❀"
or name == "❀ قسائم مساعدة ❀"
or name == "❀ قسائم توسيع ❀"
or name == "❀ قلوب اضافيه ❀"
or name == "❀ قسائم ترقية القطارات ❀"
or name == "❀ قسائم ترقية المصانع ❀"
or name == "❀ قسائم ترقية الجزر ❀"
or name == "❀ جواهر حمراء ❀"
or name == "❀ جواهر صفراء ❀"
or name == "❀ جواهر خضراء ❀"
or name == "❀ معول ❀"
or name == "❀ دينميت ❀"
or name == "❀ متفجرات ❀"
or name == "❀ طاقة الحدث ❀"
or name == "❀ دينميت الحدث ❀"
or name == "❀ ضعف النقاط ضرب اثنين ❀"
or name == "❀ قفاز داخل الحدث ❀"
or name == "❀ مطرقة ثاقبه داخل الحدث ❀"
or name == "❀ صنبود داخل الحدث ❀"
or name == "❀ كرة قوس قزح خارج الحدث ❀"
or name == "❀ صاروخ خارج الحدث ❀"
or name == "❀ دينميت خارج الحدث ❀"
or name == "❀ الكروت ❀"
)

if needsInput then
        local input = gg.prompt({"🎀 ادخل الرقم المطلوب لـ "..name..":"},{0},{"number"})
        inputVal = tonumber(input[1]) or 0
    end

    -- اضافة القيم الأساسية بدون تعديل +8 و +12 للتماثيل/الجزيرة
    local offsets = {4,0,-4,-8,-12,-16}
    for i = 1, #offsets do
        local valueIndex = #codeParts - i + 1
        if valueIndex > 0 then
            table.insert(newValues, {address = secondAddr + offsets[i], flags = gg.TYPE_DWORD, value = codeParts[valueIndex]})
        end
    end

    -- تعديل +8 و +12 فقط إذا الأدوات أو الصندوق
    if needsInput then
        table.insert(newValues,{address=secondAddr+8, flags=gg.TYPE_DWORD, value=0})
        table.insert(newValues,{address=secondAddr+12, flags=gg.TYPE_DWORD, value=inputVal})
    end

    gg.setValues(newValues)
    gg.alert("✅🎀اذهب استلم الهدية الثامنة والعشرون✅🎀")
    gg.toast("🎀💎ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ💎🎀")

end

-------------------------------------------------
-- 🟢 القوائم الرئيسية
-------------------------------------------------
local mainChoices = {
    "🌸تبديل الهدية🌸",
    "💣😉 جميع اكواد التبديل 😉💣",
    "🔙 رجوع"
}

local oldChoices = {
"❀ الشونه ❀",
"❀ البناء ❀",
"❀ الزرع ❀",
"❀ الطائرة ❀",
"❀ الكاش ❀",
"❀ قسائم مساعدة ❀",
"❀ قسائم توسيع ❀",
"❀ قلوب اضافيه ❀",
"❀ قسائم ترقية القطارات ❀",
"❀ قسائم ترقية المصانع ❀",
"❀ قسائم ترقية الجزر ❀",
"❀ جواهر حمراء ❀",
"❀ جواهر صفراء ❀",
"❀ جواهر خضراء ❀",
"❀ معول ❀",
"❀ دينميت ❀",
"❀ متفجرات ❀",
"❀ طاقة الحدث ❀",
"❀ دينميت الحدث ❀",
"❀ ضعف النقاط ضرب اثنين ❀",
"❀ قفاز داخل الحدث ❀",
"❀ مطرقة ثاقبه داخل الحدث ❀",
"❀ صنبود داخل الحدث ❀",
"❀ كرة قوس قزح خارج الحدث ❀",
"❀ صاروخ خارج الحدث ❀",
"❀ دينميت خارج الحدث ❀",
"❀ الكروت ❀",
}
local offsetMinus24_values = {
    ["❀ الشونه ❀"] = 23,
    ["❀ البناء ❀"] = 24,
    -- أضف خيارات أخرى إذا احتجت
}

local newChoices = {
"❀ الاسم باللون الوردي ❀",
"❀ الإطار باللون الوردي ❀", 
"الشارة الاولى",
"الشارة الثانية",
"شارة الثالثة", 
"الشارة الرابعة", 
"༺ النحلة المغنية ༻",
 "༺ البقرة الراقصة ༻",
 "༺ الخروف الشارب ༻",
 "༺ كلب البحر ༻",
 "༺ الخنزيره الراقصة ༻",
 "༺ الخنزير القرصان المراقب ༻",
 "༺ البطة الزرقاء التي تقول لا ༻",
 "༺ بطتين عيد الحب ༻", 
"༺ كلب البحر عيد الحب ༻",
 "༺ البقرة الغارقة ༻",
 "༺ ديك المدفع ༻", 
"༺ بطة السيلفي ༻",
 "༺ خروف الكرتون ༻",
 "༺ كلب البحر الشرير ༻",
 "༺ ديك برنطية مسدس ༻",
 "༺ كلب البحر يتلاعب بالذهب ༻",
 "༺ الخنزير راعي البقر ༻", 
"༺ البقرة الضاحكة ༻",
 "༺ الخنزير الراقص ༻",
 "༺ كلب البحر الراقص ༻",
 "༺ خاروف الغمزه ༻",
 "༺ بطة مصاص الدماء ༻",
 "༺ كلب البحر الساحر ༻", 
"༺ بطة الهداية ༻",
 "༺ بقرة الانوار ༻",
 "༺ الفرخة المثلجه ༻",
 "༺ الخنزير الياباني ༻",
 "༺ كلب البحر الرابح ༻",
 "༺ الخروف المصفق ༻",
 "༺ الفرخة الدايخه ༻",
 "༺ الخنزير اللعوب ༻",
 "༺ نحلة نارين ༻", 
 "༺ البقرة تاكل الفوشار ༻",
 "༺ كلب البحر يهز في رأسه ༻",
 "༺ خروف الحب ༻", 
"༺ بطة عيد الحب ༻", 
"༺ البطة الناعسة ༻",
 "༺ بوسة البقرة ༻",
 "༺ الفرخه اوكيتو ༻",
 "༺ نحلة دراكولا ༻",
 "༺ خروف دراكولا ༻",
 "༺ دجاجة دراكولا ༻",
 "༺ البقرة الفضائيه ༻",
 "༺ الخنزيره الفضائيع ༻",
 "༺ بطه بعضلاتها ༻",
 "༺ بقرة مع سلة الجزر ༻", 
"༺ خنزير اوكيتو ༻",
 "༺ نحلة كريسماس ༻",
 "༺ خروف طاير بالثلج ༻", 
"༺ ديك بيلعب باتيناج ༻",
 "༺ الديك الخباز ༻", 
"༺ بطة البوسه ༻",
 "༺ نحلة الديسكور ༻",
 "༺ كلب البحر مصباح علاء الدين ༻",
 "༺ خروف مصباح علاء الدين ༻",
 "༺ ديك شم النسيم ༻",
 "༺ نحلة شم النسيم ༻", 
}

-------------------------------------------------
-- 🟢 رسالة تأكيد
-------------------------------------------------
function showMessages()
    gg.toast("🎀💎ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ💎🎀")
    gg.alert("✅🎀اذهب استلم الهدية الثامنة والعشرون✅🎀")
end

-------------------------------------------------
-- 🟢 الحلقة الرئيسية مع انتظار 10 ثوانٍ بين كل تعديل
-------------------------------------------------
local base, val_plus8, val_plus12 = searchFirst()
if not base then return end

local secondAddr = searchSecondOnce()
if not secondAddr then return end

while true do
    gg.sleep(100)
    if gg.isVisible(true) then
        gg.setVisible(false)
        local selectedMain = gg.choice(mainChoices, nil, "اختر نوع الأكواد:")
        if selectedMain == 1 then
            -- الأكواد القديمة
            local selectedOld = gg.multiChoice(oldChoices, nil, "اختر التعديلات القديمة:")
            if selectedOld then
                for i, isSelected in pairs(selectedOld) do
                    if isSelected then
                        local choiceName = oldChoices[i]
if choiceName == "❀ الزرع ❀"
    or choiceName == "❀ الطائرة ❀"
    or choiceName == "❀ الكاش ❀"
    or choiceName == "❀ قسائم مساعدة ❀"
    or choiceName == "❀ قسائم توسيع ❀"
    or choiceName == "❀ قلوب اضافيه ❀"
    or choiceName == "❀ قسائم ترقية القطارات ❀"
    or choiceName == "❀ قسائم ترقية المصانع ❀"
    or choiceName == "❀ قسائم ترقية الجزر ❀"
    or choiceName == "❀ جواهر حمراء ❀"
    or choiceName == "❀ جواهر صفراء ❀"
    or choiceName == "❀ جواهر خضراء ❀"
    or choiceName == "❀ معول ❀"
    or choiceName == "❀ دينميت ❀"
    or choiceName == "❀ متفجرات ❀"
    or choiceName == "❀ طاقة الحدث ❀"
    or choiceName == "❀ دينميت الحدث ❀"
    or choiceName == "❀ ضعف النقاط ضرب اثنين ❀"
    or choiceName == "❀ قفاز داخل الحدث ❀"
    or choiceName == "❀ مطرقة ثاقبه داخل الحدث ❀"
    or choiceName == "❀ صنبود داخل الحدث ❀"
    or choiceName == "❀ كرة قوس قزح خارج الحدث ❀"
    or choiceName == "❀ صاروخ خارج الحدث ❀"
    or choiceName == "❀ دينميت خارج الحدث ❀"
    or choiceName == "❀ الكروت ❀" then

        applyFixedEditWithInputSelective(secondAddr, fixedEdits[choiceName], choiceName)

elseif choiceName == "❀ الشونه ❀"
    or choiceName == "❀ البناء ❀" then
                            local input = gg.prompt({"🎀 ادخل الرقم المطلوب لـ " .. choiceName .. ":"}, {0}, {"number"})
                            if input and tonumber(input[1]) then
                                local val = tonumber(input[1])
                                local offsetMinus24 = offsetMinus24_values[choiceName] or 24
                                local editsSecond = {
                              
        {address = secondAddr + 88 , flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr + 84, flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr + 80, flags = gg.TYPE_DWORD, value = 0},        
        {address = secondAddr + 76, flags = gg.TYPE_DWORD, value = 0},  
        {address = secondAddr + 72, flags = gg.TYPE_DWORD, value = 0},        
        {address = secondAddr + 92  , flags = gg.TYPE_DWORD, value = 0},   
        {address = secondAddr + 12, flags = gg.TYPE_DWORD, value = input[1]},
        {address = secondAddr + 8, flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr + 4, flags = gg.TYPE_DWORD, value = val_plus12},
        {address = secondAddr, flags = gg.TYPE_DWORD, value = val_plus8},
        {address = secondAddr - 4, flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr - 8, flags = gg.TYPE_DWORD, value = offsetMinus24},
        {address = secondAddr - 12, flags = gg.TYPE_DWORD, value = 0},
        {address = secondAddr - 16, flags = gg.TYPE_DWORD, value = 33}
                                }
                                gg.setValues(editsSecond)
                                if choiceName == "❀ الشونه ❀" then
                                    applyPointerEditFromAddress(secondAddr, saher_basmala)
                                elseif choiceName == "❀ البناء ❀" then
                                    applyPointerEditFromAddress(secondAddr, basmala_saher)
                                end
                                showMessages()
                        end
                        end
                        gg.sleep(10000) -- انتظار 10 ثوانٍ بعد كل تعديل
                    end
                end
            end
        elseif selectedMain == 2 then
            -- الأكواد الجديدة
            local selectedNew = gg.multiChoice(newChoices, nil, "اختر الأكواد الجديدة:")
            if selectedNew then
                for i, isSelected in pairs(selectedNew) do
                    if isSelected then
                        local choiceName = newChoices[i]
                        if choiceName == "❀ الاسم باللون الوردي ❀" then
                            applySecondEditsWithCopiedValues(secondAddr, val_plus8, val_plus12, 24)
                            applyPointerEditFromAddress(secondAddr, heart_saher)
                        elseif choiceName == "❀ الإطار باللون الوردي ❀" then
                            applySecondEditsWithCopiedValues(secondAddr, val_plus8, val_plus12, 24)

                            applyPointerEditFromAddress(secondAddr, heart_basmala)
                        else
                            applyFixedEditWithInputSelective(secondAddr, fixedEdits[choiceName], choiceName)
                        end
                        showMessages()
                        gg.sleep(10000) -- انتظار 10 ثوانٍ بعد كل تعديل
                    end
                end
            end
        elseif selectedMain == 3 then
   -- رجوع للقائمة الأساسية
   return basmala()

        end
    end
    end
end  

function SMB5()

--تطوير شامل--
Sbb = gg.multiChoice({
"♬♪♫ تصفير الكاتب الاول ♬♪♫",
"♬♪♫ فتح المباني الاجتماعيه ♬♪♫",
"♬♪♫ تصفير عدد السكان ♬♪♫",
"♬♪♫ تصفير ارض الحديقة ♬♪♫",
"♬♪♫ تصفير طلبات الحديقة ♬♪♫",
"♬♪♫ تصفير برسيم بيت الحظ ♬♪♫",
"♬♪♫ زيادة صناديق السوق ♬♪♫",
"♬♪♫ زيادة صناديق المصانع ♬♪♫",
"♬♪♫ زيادة عمق المنجم ♬♪♫",
"♬♪♫ زيادة ايام المعززات بالمختبر ♬♪♫",
"♬♪♫ تصفير الطلب بالتعاون ♬♪♫",
"♬♪♫ طلب القمح بالتعاون ♬♪♫",
"♬♪♫ تصفير طلبات الهيلو ♬♪♫",
"♬♪♫ فتح انجازات التعاون ♬♪♫",
"♬♪♫  زيادة المنتج بالمصنع والشونه♬♪♫",
"♬♪♫تصفير تاجر السوق♬♪♫", 
"♬♪♫زيادة منتجات التاجر♬♪♫", 
"♬♪♫تحويل هدية 29 الى صاروخ منجم♬♪♫",
"♬♪♫تحويل هدية 29 الى تصفير الحيوانات دائم♬♪♫",
"♬♪♫تطوير حدث الثوره المتجمده♬♪♫", 
" 👽☠b͢a͢c͢k͢ 👽☠ ",
  }, nil,
"🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀\n⏰ TIME : " .. getTime())
if Sbb == nil then else
if Sbb[1] == true then Sbb1() end
if Sbb[2] == true then Sbb2() end
if Sbb[3] == true then Sbb3() end
if Sbb[4] == true then Sbb4() end
if Sbb[5] == true then Sbb5() end
if Sbb[6] == true then Sbb6() end
if Sbb[7] == true then Sbb7() end
if Sbb[8] == true then Sbb8() end
if Sbb[9] == true then Sbb9() end
if Sbb[10] == true then Sbb10() end
if Sbb[11] == true then Sbb11() end
if Sbb[12] == true then Sbb12() end
if Sbb[13] == true then Sbb13() end
if Sbb[14] == true then Sbb14() end
if Sbb[15] == true then Sbb15() end
if Sbb[16] == true then Sbb16() end
if Sbb[17] == true then Sbb17() end
if Sbb[18] == true then Sbb18() end
if Sbb[19] == true then Sbb19() end
if Sbb[20] == true then Sbb20() end
if Sbb[200] == true then basmala() end
end
THSH = -1
end
function Sbb1()
--تصفير الكاتب الاول--
BASMALASAHER = gg.multiChoice({
"🎀تصفير الكاتب الاول من الزينة🎀",
"🎀زيادة الكاتب الاول من الهدية الاخيره🎀",
"🪙عملات صفرا من الهديه الاخيره🪙", 
"🔙『  رجوع 』🔙",
}, nil,
"🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀\n⏰ TIME : " .. getTime())
if BASMALASAHER == nil then else
if BASMALASAHER[1] == true then BASMALASAHER1() end
if BASMALASAHER[2] == true then BASMALASAHER2() end
if BASMALASAHER[3] == true then BASMALASAHER3() end
if BASMALASAHER[100] == true then HOME() end
end
THSH = -1
end
function BASMALASAHER1()  
gg.setVisible(false) 
gg.alert('انتظر قليلا للبحث') 
gg.searchNumber('1900000' .. 'x4' , gg.TYPE_DWORD) 


    gg.getResults(1)
    
    gg.editAll("0", gg.TYPE_DWORD)

local foor = gg.getResults(5) 
if #foor == 0 then
        gg.alert("لم يتم العثور على نتائج.")
      return
    end

local saveList = {}
    for i = 1, #foor do


local t = {}
t[1] = {}
t[1].address = foor[1].address 
t[1].flags = gg.TYPE_DWORD
t[1].value = 0
gg.setValues(t)
gg.addListItems(t)

local t = {}
t[1] = {}
t[1].address = foor[1].address - 4
t[1].flags = gg.TYPE_DWORD
t[1].value = 0
gg.setValues(t)
gg.addListItems(t)
end
gg.alert("🎀اذهب واشتر الكاتب الأول أكثر من مرة ثم اغلق اللعبة وارجع بع منه🎀")
gg.clearResults()
gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
gg.clearResults()
end
function BASMALASAHER2()  
--الكاتب الاول--
gg.setVisible(false)
gg.alert('🍉🎀أنتظر انتهاء البحث🎀🍉')

gg.searchNumber("1379101978;8;28:433", gg.TYPE_DWORD)
gg.getResults(100)
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
gg.sleep(3000)
gg.refineNumber("28", gg.TYPE_DWORD)
local r = gg.getResults(10)

if not r or #r == 0 then
    gg.alert("❌ لم يتم العثور على نتائج.")
    return
end

local address = r[1].address -- ✅ إصلاح النقطة الأساسية

local saveList = {}

local values = {
    {offset =16 , value = "6174731Ah"},
    {offset = 20, value = "5F657574h"},
    {offset = 24, value = "74697277h"},
    {offset = 28, value = "00007265h"},
    {offset = 32, value = 0},
    {offset = 36, value = 0},
}

for i, v in ipairs(values) do
    local t = {}
    t[1] = {
        address = address + v.offset,
        flags = gg.TYPE_DWORD,
        value = v.value
    }
    gg.setValues(t)
    gg.addListItems(t)
    table.insert(saveList, t[1])
end

gg.clearResults()
gg.alert("🍉🦋أذهب واستلم الهديه 28🦋🍉")
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end
function BASMALASAHER3()  
--الجولد--
gg.setVisible(false)
gg.alert('🍉🎀أنتظر انتهاء البحث🎀🍉')

gg.searchNumber("1379101978;6;8;28:433", gg.TYPE_DWORD)
gg.getResults(100)
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
gg.sleep(3000)
gg.refineNumber("28", gg.TYPE_DWORD)
local r = gg.getResults(10)

if not r or #r == 0 then
    gg.alert("❌ لم يتم العثور على نتائج.")
    return
end

local address = r[1].address -- ✅ إصلاح النقطة الأساسية

local saveList = {}

local values = {
    {offset = 16, value = 1768907530},
    {offset = 20, value = 29550},
    {offset = 24, value = 0},
    {offset = 28, value = 0},
    {offset = 32, value = 0},
    {offset = 36, value = 0},
    {offset = 40, value = 0},
    {offset = 44, value = 900000},
}

for i, v in ipairs(values) do
    local t = {}
    t[1] = {
        address = address + v.offset,
        flags = gg.TYPE_DWORD,
        value = v.value
    }
    gg.setValues(t)
    gg.addListItems(t)
    table.insert(saveList, t[1])
end

gg.clearResults()
gg.alert("🍉🦋أذهب واستلم الهديه 28 🦋🍉")
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end

function Sbb2()
--فتح المباني الاجتماعيه--
gg.searchNumber("696E756Dh;00007974h;00000002h", gg.TYPE_DWORD)
    gg.getResults(1000)
    gg.refineNumber("00000002h", gg.TYPE_DWORD)
    tas = gg.getResults(1000)
 
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address 
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 5
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])

        end
        gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("🌹أغلق اللعبة وافتح من جديد🌹")
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
    
    
end

function Sbb3()
--تصفير عدد السكان--
gg.searchNumber("1886938386;1113878113;31093::9", gg.TYPE_DWORD)
gg.getResults(10000)
gg.refineNumber("1886938386", gg.TYPE_DWORD)
tas = gg.getResults(10000)

local saveList = {}

for i = 1, #tas do
    local address = tas[i].address

    -- 🔍 شرط التحقق: قراءة القيمة عند +368
    local check = gg.getValues({
        {address = address + 368, flags = gg.TYPE_DWORD}
    })

    -- ✅ التعديل فقط إذا كانت القيمة = 1
    if check[1].value == 1 then
        local t1 = {}
        t1[1] = {}
        t1[1].address = address + 368
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 6
        t1[1].freeze = true

        gg.setValues(t1)
        table.insert(saveList, t1[1])
    end
end

gg.clearResults()
gg.alert("🌸تم توسيع جميع الاراضي🌸")   
     gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
    
    end    
     
function Sbb4()
--تصفير ارض الحديقة--
gg. setVisible(false) 
local input = gg.prompt(
        {"🎀 ادخل عدد السكان 🎀"},
        {0},
        {"number"}
    )
    if input == nil then
        gg.toast("لم يتم إدخال قيم. العملية ألغيت.")
        return
    end

gg.searchNumber('1886351380;1952541813' .. ';' .. input[1] , gg.TYPE_DWORD) 
gg. refineNumber(input[1], gg.TYPE_DWORD) 
    tas = gg.getResults(10)
 
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address 
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 0
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])


        end
        gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("🍄 اذهب لفتح جميع الاراضي 🍄 ")
        gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
    
    end    

function Sbb5()
--تصفير طلبات الحديقة--
gg.searchNumber("40C51800h", gg.TYPE_DWORD)
    gg.getResults(100)
    gg.sleep(3000)
    gg.refineNumber("40C51800h", gg.TYPE_DWORD)
    tas = gg.getResults(100)
 
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address 
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 0
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])


end

gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("🍉تم تصفير وقت طلبات حديقة الحيوانات🍉")
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end
    
function Sbb6()
--تصفير البرسيم--
gg.alert("🌸نقوم بتحديث الكود🌸")
gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end
function Sbb7()
--زيادة عدد صناديق السوق--
gg.setVisible(false)
gg.searchNumber("1185464320", gg.TYPE_DWORD)
local r = gg.getResults(2000)

if #r == 0 then
    gg.alert("❌ لم يتم العثور على أي نتائج")
    return
end

-- إدخال عدد الصناديق
local input = gg.prompt(
    {"أدخل عدد الصناديق"},
    {0},
    {"number"}
)

if input == nil then
    gg.toast("❌ تم إلغاء العملية")
    return
end

local edits = {}

for i = 1, #r do
    -- قراءة القيمة عند -72
    local check = {}
    check[1] = {
        address = r[i].address - 72,
        flags = gg.TYPE_DWORD
    }

    local val = gg.getValues(check)[1].value

    -- شرط التحقق
    if val == 1953063702 then
        -- التعديل عند -56
        table.insert(edits, {
            address = r[i].address - 128,
            flags = gg.TYPE_DWORD,
            value = input[1]
        })
    end
end

-- إذا لم تتحقق أي نتيجة
if #edits == 0 then
    gg.alert("❌ لم يتم العثور على أي نتيجة مطابقة للشرط")
    gg.clearResults()
    return
end

gg.setValues(edits)
gg.addListItems(edits)
gg.clearResults()

gg.alert("🎉 تم الزيادة بنجاح اذهب وشاهد السوق 🎉")
gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end
function Sbb8() 
--زياده عدد صناديق المصانع--
    gg.clearResults()
gg.alert("🌸قبل البحث قم بفتح مصنع🌸")
gg.searchNumber("3408129X40", gg.TYPE_DWORD)
    gg.getResults(1000)
    gg.refineNumber("256", gg.TYPE_DWORD)
        tas = gg.getResults(1000)
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address + 256
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 0
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])

        end
        gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("🍉تم تصفير الكاش افتح الصناديق🍉")
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end

function Sbb9()
--زيادة عمق المنجم--
gg.setVisible(false)
gg.searchNumber("0000000Ah;67696414h;67696422h", gg.TYPE_DWORD)
gg.getResults(10)
gg.refineNumber("0000000Ah", gg.TYPE_DWORD)
r = gg.getResults(4)
local input = gg.prompt(
        {"أدخل نسبة زيادة العمق"},
        {0},
        {"number"}
    )
    if input == nil then
        gg.toast("لم يتم إدخال قيم. العملية ألغيت.")
        return
    end
local t1 = {}
t1[1] = {}
t1[1].address = r[1].address - 4
t1[1].flags = gg.TYPE_DWORD
t1[1].value = input[1]
gg.setValues(t1)
gg.addListItems(t1)

gg.clearResults()
gg.alert('🌹تم زيادة عمق المنجم بنجاح🌹')
gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end
function Sbb10()
--زيادة ايام المعززات--
gg.setVisible(false) -- إخفاء الواجهة عند تشغيل السكربت

-- طلب القيمة من المستخدم
local input = gg.prompt({"أدخل نسبة الوقت"}, {0}, {"number"})
if input == nil then
    return
end
local newValue = tonumber(input[1])

-- دالة البحث والتعديل مع شرط التحقق
function SA8(value)
    gg.clearResults()
    gg.searchNumber(value, gg.TYPE_DWORD)
    local results = gg.getResults(5000)

    if #results == 0 then
        return
    end

    local finalResults = {}

    for i = 1, #results do
        local base = results[i].address

        -- قراءة القيم للتحقق
        local check = gg.getValues({
            {address = base + 4,  flags = gg.TYPE_DWORD},
            {address = base - 24, flags = gg.TYPE_DWORD}
        })

        local v_plus4  = check[1].value
        local v_minus24 = check[2].value

        -- شرط التحقق
        if v_plus4 < 100 and (v_minus24 > 1000000000 or v_minus24 == 33) then
            results[i].value = newValue
            results[i].flags = gg.TYPE_DWORD
            results[i].freeze = true
            table.insert(finalResults, results[i])
        end
    end

    if #finalResults > 0 then
        gg.setValues(finalResults)
        gg.addListItems(finalResults)
    end
end

-- الأكواد المطلوب البحث عنها
local values = {259200, 86400, 172800, 7200}

-- تنفيذ البحث لكل كود
for i = 1, #values do
    SA8(values[i])
end

gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
gg.alert("🎯 البحث والتعديل اكتمل!")
end
function Sbb11()
--تصفير الطلب بالتعاون--
gg.clearResults()
gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_CODE_APP)
gg.toast("✨💗 اللهم صل على  םבםב 💗✨")                                
gg.searchNumber("10800;86400", gg.TYPE_DWORD) 
gg.toast("💗 اللهم صل وسلم وبارك على سيدنا محمد 💗")

local soso = gg.getResults(100)
for i = 1, #soso do 
    soso[i].flags = gg.TYPE_DWORD
    soso[i].value = 0
    soso[i].freeze = true
end

gg.setValues(soso)
gg.addListItems(soso)
gg.clearResults()
gg.toast("🌸 تم تصفير طلب التعاون 🌸")

gg.setRanges(gg.REGION_C_ALLOC)
end  

function Sbb12()
--طلب الزرع بالتعاون--
gg.searchNumber("16842755X36", gg.TYPE_DWORD)
gg.getResults(1000)
gg.refineNumber("16842753", gg.TYPE_DWORD)
local tas = gg.getResults(1000)

local input = gg.prompt({"🌱إدخل الرقم🌱"}, {0}, {"number"})
if not input then return end

local saveList = {}

for i = 1, #tas do
    local addr = tas[i].address

    local edits = {
        {address = addr - 4, flags = gg.TYPE_DWORD, value = input[1], freeze = true},
        {address = addr - 8, flags = gg.TYPE_DWORD, value = 0,        freeze = true}
    }

    gg.setValues(edits)
    for _, e in ipairs(edits) do
        table.insert(saveList, e)
    end
end

gg.addListItems(saveList)
gg.clearResults()
gg.toast("✨💗 اللهم صل على  םבםב 💗✨")
end 


function Sbb13()
--تصفير طلبات الهيلو--
gg.setVisible(false)
    gg.alert('🍉🎀أنتظر انتهاء البحث🎀🍉')

    gg.searchNumber("00000001h;01010000h;00000064h:25", gg.TYPE_DWORD)
    gg.getResults(500)  -- زيادة عدد النتائج
    gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")

    gg.refineNumber("01010000h", gg.TYPE_DWORD)
    local results = gg.getResults(500)

    if not results or #results == 0 then
        gg.alert("❌ لم يتم العثور على نتائج.")
        return
    end

    local freezeList = {}

    -- تعديل وتجميد كل نتيجة
    for _, result in ipairs(results) do
        local base = result.address
        local offsets = {-8, -4, 0, 4, 8, 12, 16}
        for _, offset in ipairs(offsets) do
            local item = {
                address = base + offset,
                flags = gg.TYPE_DWORD,
                value = 0
            }
            gg.setValues({item})
            table.insert(freezeList, item)
        end
    end

    gg.addListItems(freezeList, true)

    gg.clearResults()
    gg.alert("🍉تم تصفير وتجميد جميع الطلبات بنجاح🍉")
    gg.toast("🎀ʚïɞ 🄱🄰🅂🄼🄰🄻🄰  ʚïɞ🎀")
end


function Sbb14() 
--انجازات التعاون--
gg.alert("🌸قبل البحث تاكد من انجاز مهمه من كل اشعار🌸")
gg.setVisible(false)

-- القيم المسموح تعديلها
local allowed = {
    [300]=true,
    [400]=true,
    [500]=true,
    [1000]=true,
    [5000]=true,
    [10000]=true
}

-- دالة البحث + التصفية + التعديل فقط
function SearchFilterEdit(pattern)
    gg.clearResults()
    gg.searchNumber(pattern, gg.TYPE_DWORD)

    local results = gg.getResults(10000)
    if #results == 0 then
        return
    end

    local edits = {}

    for i, v in ipairs(results) do
        if allowed[v.value] then
            v.value = 1
            v.flags = gg.TYPE_DWORD
            table.insert(edits, v)
        end
    end

    if #edits > 0 then
        gg.setValues(edits) -- تعديل فقط
    end
end

-- أنماط البحث
local searches = {
    "17;34;300;8:13",
    "18;35;500;2:13",
    "19;36;500;3:13",
    "20;37;400;4:13",
    "21;38;400;5:13",
    "22;39;300::9",
    "23;40;500;9:13",
    "24;41;400;7:13",
    "16;33;500::9",
    "15;32;5000;1:13",
    "14;31;1000;6:13",
    "11;28;10000::9"
}

-- تنفيذ جميع الأبحاث
for i = 1, #searches do
    SearchFilterEdit(searches[i])
end
gg.alert("🌸تم فتح جميع انجازات التعاون🌸")
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end

function Sbb15()
--زياده المنتج بالمصنع والشون
    
function editCodesWithX24()
    gg.setVisible(false)

    local codes = {
        "631603722", "620782090", "555369734", "893494792",
        "551199242", "570450442", "713056790", "905563408",
        "687828232", "570844422", "688813832", "684173330"
    }

    for _, code in ipairs(codes) do
        gg.clearResults()
        gg.searchNumber(code .. "x24", gg.TYPE_DWORD)
        local results = gg.getResults(gg.getResultsCount())
        if #results > 0 then
            for i = 1, #results do
                results[i].value = 1
                results[i].freeze = false
            end
            gg.setValues(results)
        end
    end
end
function applyOffsets(address, inputValue)
    local offsets = {
        [4]  = 0,
        [8]  = inputValue,
        [16] = 0,
        [20] = 0,
        [24] = 0,
        [28] = 0,
        [32] = 0,
        [36] = 0,
    }

    local values = {}
    for offset, value in pairs(offsets) do
        table.insert(values, {
            address = address + offset,
            flags = gg.TYPE_DWORD,
            value = value
        })
    end
    gg.setValues(values)
end

function Sbb15(searchValue, inputValue)
    gg.clearResults()
    gg.searchNumber(searchValue, gg.TYPE_FLOAT)
    local results = gg.getResults(gg.getResultsCount())
    if #results == 0 then return end

    for i = 1, #results do
        local addr = results[i].address
        local checks = gg.getValues({
            {address = addr + 4,  flags = gg.TYPE_DWORD},
            {address = addr + 8,  flags = gg.TYPE_DWORD},
            {address = addr + 12, flags = gg.TYPE_DWORD},
            {address = addr + 16, flags = gg.TYPE_DWORD},
            {address = addr + 20, flags = gg.TYPE_DWORD},
            {address = addr + 24, flags = gg.TYPE_DWORD},
            {address = addr + 28, flags = gg.TYPE_DWORD},
            {address = addr + 32, flags = gg.TYPE_DWORD},
            {address = addr + 36, flags = gg.TYPE_DWORD},
        })

        local function isValid(v)
            return math.abs(v) > 50000000
        end

        if isValid(checks[1].value)
        and isValid(checks[2].value)
        and checks[3].value == 0
        and isValid(checks[4].value)
        and checks[5].value < 125
        and isValid(checks[6].value)
        and checks[7].value < 125
        and isValid(checks[8].value)
        and checks[9].value < 125
        then
            gg.setValues({
                {address = addr, flags = gg.TYPE_FLOAT, value = 1.0}
            })
            applyOffsets(addr, inputValue)
        end
    end

    gg.clearResults()
end

function main()
    gg.setVisible(false)
    local input = gg.prompt({"💡 أدخل القيمة:"}, {""}, {"number"})
    if input == nil or tonumber(input[1]) == nil then
        os.exit()
    end
    local inputValue = tonumber(input[1])

    editCodesWithX24()

    local values = {
        300, 600, 900, 1200, 1500, 1800, 2400, 2700, 3000, 3600, 4200, 4500,
        4800, 5400, 6000, 6300, 7200, 8100, 8400, 9000, 9600, 9900,
        10200, 10800, 11400, 12000, 12600, 14400, 16200, 18000, 21600
    }

    for i = 1, #values do
        Sbb15(values[i], inputValue)
    end
    gg.alert("🌺تم تصفير جميع المنتجات🌺")
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀!")
end
main()
end
function Sbb16()
--تصفير بائع السوق--
gg.searchNumber("3600;86400", gg.TYPE_DWORD)
    gg.getResults(100)
    gg.sleep(3000)
    gg.refineNumber("3600", gg.TYPE_DWORD)
    tas = gg.getResults(100)
 
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address 
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 0
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])
        end
        gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("🍅أُطلب منتجات من البائع على كيفك🥦")
    gg.toast("✨💗 اللهم صل على  םבםב 💗✨")
end  

function Sbb17()
    -- زيادة منتجات البائع --
    gg.clearResults()

    -- 1️⃣ البحث
    local first = gg.prompt(
        {"🥑اكتب عدد المنتج للبحث 🥑"},
        nil,
        {"number"}
    )
    if not first then
        gg.toast("تم الإلغاء")
        return
    end
    gg.searchNumber(first[1], gg.TYPE_DWORD)
    gg.toast("🌸 يبحث الآن 🌸")

    -- ⏳ انتظر 15 ثانية بعد البحث
    gg.sleep(15000)

    -- 2️⃣ الصقل الأول
    local second = gg.prompt(
        {"🥑اكتب عدد المنتج للصقل الأول 🥑"},
        nil,
        {"number"}
    )
    if not second then
        gg.toast("تم الإلغاء")
        return
    end
    gg.refineNumber(second[1], gg.TYPE_DWORD)
    gg.toast("🥑 تم الصقل الأول 🥑")

    -- ⏳ انتظر 15 ثانية بعد الصقل الأول
    gg.sleep(15000)

    -- 3️⃣ الصقل الثاني
    local third = gg.prompt(
        {"🥑اكتب عدد المنتج للصقل الثاني 🥑"},
        nil,
        {"number"}
    )
    if not third then
        gg.toast("تم الإلغاء")
        return
    end
    gg.refineNumber(third[1], gg.TYPE_DWORD)
    gg.toast("🥑 تم الصقل الثاني 🥑")

    -- 4️⃣ القيمة المطلوبة
    local valueInput = gg.prompt(
        {"🥑اكتب العدد الذي تريد استلامه 🥑"},
        {1},
        {"number"}
    )
    if not valueInput then
        gg.toast("تم الإلغاء")
        return
    end
    local mainValue = valueInput[1]

    -- 5️⃣ جلب النتائج
    local count = gg.getResultsCount()
    if count == 0 then
        gg.alert("❌ لا توجد نتائج")
        return
    end

    local results = gg.getResults(count)

    -- 🔥 تحديد أكبر قيمة (موجبة أو سالبة)
    local maxAbs = 0
    for _, v in ipairs(results) do
        if math.abs(v.value) > maxAbs then
            maxAbs = math.abs(v.value)
        end
    end

    local freezeList = {}

    -- 6️⃣ تعديل + تجميد أكبر قيمة فقط
    for _, v in ipairs(results) do
        if math.abs(v.value) == maxAbs then
            table.insert(freezeList, {
                address = v.address,
                flags   = gg.TYPE_DWORD,
                value   = mainValue,
                freeze  = true
            })

            table.insert(freezeList, {
                address = v.address - 4,
                flags   = gg.TYPE_DWORD,
                value   = 0,
                freeze  = true
            })
        end
    end

    gg.setValues(freezeList)
    gg.addListItems(freezeList)
    gg.toast("ꗟaher━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━")
   gg.toast("✨💗 استلم منتجات براحتك💗✨")
end

function Sbb18()
    gg.clearResults()
    gg.searchNumber("756F4328h;556E6F70h;61726770h;61466564h;726F7463h;00000079h::21", gg.TYPE_DWORD)
    gg.refineNumber("756F4328h", gg.TYPE_DWORD)

    local results = gg.getResults(gg.getResultCount())
    local edits = {}

    for i, v in ipairs(results) do
        local base = v.address

        -- التعديلات الأساسية
        table.insert(edits, {address = base,     flags = gg.TYPE_DWORD, value = 1599099682})
        table.insert(edits, {address = base + 4, flags = gg.TYPE_DWORD, value = 1734830404})
        table.insert(edits, {address = base + 8, flags = gg.TYPE_DWORD, value = 1348955753})
        table.insert(edits, {address = base + 12,flags = gg.TYPE_DWORD, value = 1768777074})
        table.insert(edits, {address = base + 16,flags = gg.TYPE_DWORD, value = 28021})
        table.insert(edits, {address = base + 20,flags = gg.TYPE_DWORD, value = 0})

        -- فحص +24 و +28
        local v24 = gg.getValues({{address = base + 24, flags = gg.TYPE_DWORD}})[1].value
        local v28 = gg.getValues({{address = base + 28, flags = gg.TYPE_DWORD}})[1].value

        if math.abs(v24) > 5000000 and math.abs(v28) > 5000000 then
            table.insert(edits, {address = base + 24, flags = gg.TYPE_DWORD, value = 0})
            table.insert(edits, {address = base + 28, flags = gg.TYPE_DWORD, value = 100})
        end
    end

    gg.setValues(edits)
    gg.alert("💜 اذهب واستلم هدية 29 💜")
    gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end
  function Sbb19()
  gg.clearResults()
    gg.searchNumber("756F432Ch;4C6E6F70h;5464616Fh;6E696172h;70726941h;0074726Fh::21", gg.TYPE_DWORD)
    gg.refineNumber("756F432Ch", gg.TYPE_DWORD)

    local results = gg.getResults(gg.getResultCount())
    local edits = {}

    for i, v in ipairs(results) do
        local base = v.address

        -- التعديلات الأساسية
        table.insert(edits, {address = base,     flags = gg.TYPE_DWORD, value = 1599099688})
        table.insert(edits, {address = base + 4, flags = gg.TYPE_DWORD, value = 1936682818})
        table.insert(edits, {address = base + 8, flags = gg.TYPE_DWORD, value = 1701860212})
        table.insert(edits, {address = base + 12,flags = gg.TYPE_DWORD, value = 1884644453})
        table.insert(edits, {address = base + 16,flags = gg.TYPE_DWORD, value =  1836212550})
        table.insert(edits, {address = base + 20,flags = gg.TYPE_DWORD, value = 115})

        -- فحص +24 و +28
        local v24 = gg.getValues({{address = base + 24, flags = gg.TYPE_DWORD}})[1].value
        local v28 = gg.getValues({{address = base + 28, flags = gg.TYPE_DWORD}})[1].value

        if math.abs(v24) > 5000000 and math.abs(v28) > 5000000 then
            table.insert(edits, {address = base + 24, flags = gg.TYPE_DWORD, value = 0})
            table.insert(edits, {address = base + 28, flags = gg.TYPE_DWORD, value = 100})
        end
    end

    gg.setValues(edits)
    gg.alert("💜 اذهب واستلم هدية 29 💜")
    gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end
function Sbb20()
    gg.clearResults()
gg. setVisible(false) 
local input = gg.prompt(
      {"🛳ادخل عدد النقاط لديك🛳"},
        {0},
        {"number"}
    )
    if input == nil then
        gg.toast("لم يتم إدخال قيم. العملية ألغيت.")
        return
    end

gg.searchNumber('1936617321' .. ';' .. input[1] , gg.TYPE_DWORD) 
gg. refineNumber(input[1], gg.TYPE_DWORD) 
    tas = gg.getResults(10)
 
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address 
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 65000
       
        gg.setValues(t1)
        table.insert(saveList, t1[1])


        end
        gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("❄لف العجلة الدواره مرة فقط❄")
    gg.toast("✨💗 اللهم صل على  םבםב 💗✨")
    
    end    
function SMB6()
--تبديل التصريح--
local input = gg.prompt({"🎀 ادخل رقم التصريح القادم 🎀"}, {0}, {"number"})
    
    if not input then
        gg.toast("لم يتم إدخال قيم. العملية ألغيت.")
        return
    end

    gg.clearResults()
    gg.searchNumber("7374730Eh;65726F63h;00626104h;" .. input[1], gg.TYPE_DWORD)
    gg.refineNumber("65726F63h", gg.TYPE_DWORD)
    local results = gg.getResults(100)

    if #results == 0 then
        gg.alert("لا توجد نتائج، يرجى إعادة تشغيل اللعبة والمحاولة مجدداً.")
        return
    end

    local savedValues = {}

    for i, v in ipairs(results) do
        local address = v.address
        for offset = 20, 288, 4 do
            local temp = {}
            temp.address = address + offset
            temp.flags = gg.TYPE_DWORD
            table.insert(savedValues, gg.getValues({temp})[1])
        end
    end

    gg.toast("🎀 القيم تم حفظها بنجاح 🎀")
    
    local input2 = gg.prompt({"🎀 ادخل رقم التصريح الحالي 🎀"}, {0}, {"number"})
    
    if not input2 then
        gg.toast("لم يتم إدخال قيم. العملية ألغيت.")
        return
    end

    gg.clearResults()
    gg.searchNumber("7374730Eh;65726F63h;00626104h;" .. input2[1], gg.TYPE_DWORD)
    gg.refineNumber("65726F63h", gg.TYPE_DWORD)
    local currentResults = gg.getResults(100)

    if #currentResults == 0 then
        gg.alert("لا توجد نتائج، يرجى إعادة تشغيل اللعبة والمحاولة مجدداً.")
        return
    end

    local modifiedValues = {}

    for i, v in ipairs(currentResults) do
        local address = v.address
        for j, val in ipairs(savedValues) do
            local temp = {}
            temp.address = address + (j - 1) * 4 + 20
            temp.flags = gg.TYPE_DWORD
            temp.value = val.value
            table.insert(modifiedValues, temp)
        end
    end

  
     gg.setValues(modifiedValues)
     gg.alert("💜تم تبديل التصريح بنجاح💜")
     gg.clearResults()
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end
 function SMB7()
--السباق--
BASMALAS = gg.multiChoice({
"⊱✿⊰ سباق من اللوحة⊱✿⊰",
"⊱✿⊰سباق حذف المهام⊱✿⊰",
"👽☠b͢a͢c͢k͢ 👽☠",
}, nil,
"🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀\n⏰ TIME : " .. getTime())
if BASMALAS == nil then else
if BASMALAS[1] == true then BASMALAS1() end
if BASMALAS[2] == true then BASMALAS2() end
if BASMALAS[40] == true then basmala() end
end
THSH = -1
end
function BASMALAS1()
gg.searchNumber("1952533772;3369059;65538;49", gg.TYPE_DWORD)
gg.refineNumber("65538", gg.TYPE_DWORD)
local results = gg.getResults(1000000)

local saveList = {}

for i = 1, #results do
    local res = results[i]

    local val136 = gg.getValues({{address = res.address + 136, flags = gg.TYPE_DWORD}})[1].value
    local val140 = gg.getValues({{address = res.address + 140, flags = gg.TYPE_DWORD}})[1].value

    -- تحقق من الشرط: متشابهات كلياً
    if val136 == val140 then

        -- تعديل +24
        local t1 = {}
        t1[1] = {}
        t1[1].address = res.address + 192
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 0
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])

        -- تعديل +28
        local t2 = {}
        t2[1] = {}
        t2[1].address = res.address + 196
        t2[1].flags = gg.TYPE_DWORD
        t2[1].value = 0
        t2[1].freeze = true
        gg.setValues(t2)
        table.insert(saveList, t2[1])

        -- تعديل pointer بعد +352
        local baseAddr = res.address + 328
        local pointerValue = gg.getValues({{address = baseAddr, flags = gg.TYPE_QWORD}})[1].value
        gg.setValues({
            {address = pointerValue, flags = gg.TYPE_DWORD, value = 0},
            {address = pointerValue + 4, flags = gg.TYPE_DWORD, value = 300}
        })
    end
end

if #saveList > 0 then
    gg.addListItems(saveList)
    gg.alert("🍉تم التعديل بنجاح قم بانجاز المهام🍉")
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
else
    gg.alert("❌ لا توجد نتائج تحقق الشروط.")
end

gg.clearResults()
end
function BASMALAS2()
-- 1️⃣ إدخال يدوي
  local input = gg.prompt(
    {"🔎 أدخل رقم البحث:"},
    {""},
    {"number"}
  )
  if not input then return end

  local searchText = tostring(input[1]) .. "X4"

  -- 2️⃣ البحث الأول
  gg.clearResults()
  gg.searchNumber(searchText, gg.TYPE_DWORD)
  gg.getResults(1000000)

  local results = gg.getResults(100000)
  if #results == 0 then
    gg.alert("❌ لا توجد نتائج للبحث النصي")
    return
  end

  -- 3️⃣ فلترة البحث الأول مع جميع الشروط
  local validResults = {}
  for _, r in ipairs(results) do
    if math.abs(r.value) > 500000 then

      local val296 = gg.getValues({
        {address = r.address + 296, flags = gg.TYPE_DWORD}
      })[1].value
      local cond296 = (val296 == 9 or val296 == 12 or val296 == 15 or val296 == 16 or val296 == 17 or val296 == 11)

      local val4 = gg.getValues({{address = r.address + 4, flags = gg.TYPE_DWORD}})[1].value
      local val8 = gg.getValues({{address = r.address + 8, flags = gg.TYPE_DWORD}})[1].value
      local cond4_8 = math.abs(val4) > 500000 and math.abs(val8) > 500000 and math.abs(val4 - val8) < 100

      local condNeg196 = gg.getValues({
        {address = r.address - 196, flags = gg.TYPE_DWORD}
      })[1].value == 65540

      if cond296 and cond4_8 and condNeg196 then
        table.insert(validResults, r)
      end
    end
  end

  if #validResults == 0 then
    gg.alert("❌ لم يتم العثور على أي نتيجة")
    return
  end

  -- 4️⃣ أخذ أول نتيجة صحيحة للنسخ
  local baseAddress = validResults[1].address

  -- 5️⃣ نسخ offsets -28 -24 -20
  local copied = {
    {address = baseAddress - 28, flags = gg.TYPE_DWORD},
    {address = baseAddress - 24, flags = gg.TYPE_DWORD},
    {address = baseAddress - 20, flags = gg.TYPE_DWORD}
  }

  local copiedValues = gg.getValues(copied)

  -- 6️⃣ البحث الثاني على القيم المنسوخة نفسها
  local searchList = {}
  for _, v in ipairs(copiedValues) do
    table.insert(searchList, v.value)
  end

  gg.clearResults()
  gg.searchNumber(table.concat(searchList, ";"), gg.TYPE_DWORD)
  gg.refineNumber(table.concat(searchList, ";"), gg.TYPE_DWORD)

  local count = gg.getResultsCount()
  if count == 0 then
    gg.alert("❌ لم يتم العثور على نتائج البحث الثاني")
    return
  end

  local results2 = gg.getResults(count)
  local edits = {}

-- 7️⃣ تعديل offsets قبل قراءة المؤشر
for _, r in ipairs(results2) do

    -- قراءة +24 و +28
    local v24 = gg.getValues({
        {address = r.address + 24, flags = gg.TYPE_DWORD}
    })[1].value

    local v28 = gg.getValues({
        {address = r.address + 28, flags = gg.TYPE_DWORD}
    })[1].value

    -- شرط التشابه والقيمة الكبيرة
    local cond24_28 =
        math.abs(v24) > 500000 and
        math.abs(v28) > 500000 and
        math.abs(v24 - v28) < 1000

    -- شرط -168
    local check168 = gg.getValues({
        {address = r.address - 168, flags = gg.TYPE_DWORD}
    })[1].value

    local cond168 = (check168 == 65538 or check168 == 65539 or check168 == 65540)

    -- تطبيق الشروط معًا
    if cond24_28 and cond168 then

        -- تعديل +24 و +28 (كما هو منطقك)
        gg.setValues({
            {address = r.address + 24, flags = gg.TYPE_DWORD, value = 0},
            {address = r.address + 28, flags = gg.TYPE_DWORD, value = 0}
        })

        -- قراءة المؤشر +352
        local pointerValue = gg.getValues({
            {address = r.address + 352, flags = gg.TYPE_QWORD}
        })[1].value

        if pointerValue ~= 0 then
            table.insert(edits, {
                address = pointerValue,
                flags = gg.TYPE_DWORD,
                value = 0
            })
            table.insert(edits, {
                address = pointerValue + 4,
                flags = gg.TYPE_DWORD,
                value = 300
            })
        end
    end
end

  if #edits == 0 then
    gg.alert("❌ لم يتم العثور على نتائج")
    return
  end

  -- 8️⃣ تنفيذ تعديلات المؤشر
  gg.setValues(edits)
  gg.alert("✅ تم التنفيذ بنجاح اذهب والقي نظهره على مهامك المحذوفة")

end
function SMB8()
--اكاديميه الصناعه--
-- جدول مرتب: اسم المستوى بالإيموجي → الكود الخاص به
local levels = {
    ["▄︻〔②〕══━一"] = "32162031",
    ["▄︻〔③〕══━一"] = "32162030",
    ["▄︻〔④〕══━一"] = "32162025",
    ["▄︻〔⑤〕══━一"] = "32162024",
    ["▄︻〔⑥〕══━一"] = "32162027",
    ["▄︻〔⑦〕══━一"] = "32162026",
    ["▄︻〔⑧〕══━一"] = "32162021",
    ["▄︻〔⑨〕══━一"] = "32162020",
    ["▄︻〔⑩〕══━一"] = "32162023",
    ["▄︻〔⑪〕══━一"] = "32162022",
    ["▄︻〔⑫〕══━一"] = "32162017",
    ["▄︻〔⑬〕══━一"] = "32162016",
    ["▄︻〔⑭〕══━一"] = "32162019",
    ["▄︻〔⑮〕══━一"] = "32162018",
    ["▄︻〔⑯〕══━一"] = "32162045",
    ["▄︻〔⑰〕══━一"] = "32162044",
    ["▄︻〔⑱〕══━一"] = "32162047",
    ["▄︻〔⑲〕══━一"] = "32162046",
    ["▄︻〔⑳〕══━一"] = "32162041",
    ["▄︻〔㉑〕══━一"] = "32162040",
    ["▄︻〔㉒〕══━一"] = "32162043",
    ["▄︻〔㉓〕══━一"] = "32162042",
    ["▄︻〔㉔〕══━一"] = "32162037",
    ["▄︻〔㉕〕══━一"] = "32162036",
    ["▄︻〔㉖〕══━一"] = "32162039",
    ["▄︻〔㉗〕══━一"] = "32162038",
    ["▄︻〔㉘〕══━一"] = "32162033",
    ["▄︻〔㉙〕══━一"] = "32162032",
    ["▄︻〔㉚〕══━一"] = "32162035",
    ["▄︻〔㉛〕══━一"] = "32162034",
    ["▄︻〔㉜〕══━一"] = "32161997",
    ["▄︻〔㉝〕══━一"] = "32161996",
    ["▄︻〔㉞〕══━一"] = "32161999",
    ["▄︻〔㉟〕══━一"] = "32161998",
    ["▄︻〔㊱〕══━一"] = "32161993",
    ["▄︻〔㊲〕══━一"] = "32161992",
    ["▄︻〔㊳〕══━一"] = "32161995",
    ["▄︻〔㊴〕══━一"] = "32161994",
    ["▄︻〔㊵〕══━一"] = "32161989",
    ["▄︻〔㊶〕══━一"] = "32161988",
    ["▄︻〔㊷〕══━一"] = "32161991",
    ["▄︻〔㊸〕══━一"] = "32161990",
    ["▄︻〔㊹〕══━一"] = "32161985",
    ["▄︻〔㊺〕══━一"] = "32161984",
    ["▄︻〔㊻〕══━一"] = "32161987",
    ["▄︻〔㊼〕══━一"] = "32161986",
    ["▄︻〔㊽〕══━一"] = "32162013",
    ["▄︻〔㊾〕══━一"] = "32162012",
    ["▄︻〔㊿〕══━一"] = "32162015",
    ["▄︻〔51〕══━一"] = "32162014",
    ["▄︻〔52〕══━一"] = "32162009",
    ["▄︻〔53〕══━一"] = "32162008",
}
-- ترتيب المستوى كما في الجدول الأصلي
local levelOrder = {
    "▄︻〔②〕══━一",
    "▄︻〔③〕══━一",
    "▄︻〔④〕══━一",
    "▄︻〔⑤〕══━一",
    "▄︻〔⑥〕══━一",
    "▄︻〔⑦〕══━一",
    "▄︻〔⑧〕══━一",
    "▄︻〔⑨〕══━一",
    "▄︻〔⑩〕══━一",
    "▄︻〔⑪〕══━一",
    "▄︻〔⑫〕══━一",
    "▄︻〔⑬〕══━一",
    "▄︻〔⑭〕══━一",
    "▄︻〔⑮〕══━一",
    "▄︻〔⑯〕══━一",
    "▄︻〔⑰〕══━一",
    "▄︻〔⑱〕══━一",
    "▄︻〔⑲〕══━一",
    "▄︻〔⑳〕══━一",
    "▄︻〔㉑〕══━一",
    "▄︻〔㉒〕══━一",
    "▄︻〔㉓〕══━一",
    "▄︻〔㉔〕══━一",
    "▄︻〔㉕〕══━一",
    "▄︻〔㉖〕══━一",
    "▄︻〔㉗〕══━一",
    "▄︻〔㉘〕══━一",
    "▄︻〔㉙〕══━一",
    "▄︻〔㉚〕══━一",
    "▄︻〔㉛〕══━一",
    "▄︻〔㉜〕══━一",
    "▄︻〔㉝〕══━一",
    "▄︻〔㉞〕══━一",
    "▄︻〔㉟〕══━一",
    "▄︻〔㊱〕══━一",
    "▄︻〔㊲〕══━一",
    "▄︻〔㊳〕══━一",
    "▄︻〔㊴〕══━一",
    "▄︻〔㊵〕══━一",
    "▄︻〔㊶〕══━一",
    "▄︻〔㊷〕══━一",
    "▄︻〔㊸〕══━一",
    "▄︻〔㊹〕══━一",
    "▄︻〔㊺〕══━一",
    "▄︻〔㊻〕══━一",
    "▄︻〔㊼〕══━一",
    "▄︻〔㊽〕══━一",
    "▄︻〔㊾〕══━一",
    "▄︻〔㊿〕══━一",
    "▄︻〔51〕══━一",
    "▄︻〔52〕══━一",
    "▄︻〔53〕══━一"
}

-- القائمة الرئيسية
function mainMenu()
    local choice = gg.choice(levelOrder, nil, "ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ")
    if choice == nil then
        gg.toast("❌ تم الإلغاء.")
        return
    end
    local selectedName = levelOrder[choice]
    local selectedCode = levels[selectedName]
    modifyCode(selectedName, selectedCode)
end

-- دالة التعديل
function modifyCode(levelName, code)
    gg.setVisible(false)
    gg.clearResults()
    gg.searchNumber(code .. 'x4', gg.TYPE_DWORD)
    local tas = gg.getResults(1000)

    local input = gg.prompt(
        {"⌛ أدخل نسبة تقليل الوقت لـ " .. levelName},
        {0},
        {"number"}
    )
    if input == nil then
        return
    end

    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {{address = address + 20, flags = gg.TYPE_DWORD, value = 0}}
        local t2 = {{address = address + 24, flags = gg.TYPE_DWORD, value = input[1]}}

        gg.setValues(t1)
        gg.setValues(t2)

        table.insert(saveList, t1[1])
        table.insert(saveList, t2[1])
    end

    gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("✅ تم تعديل " .. levelName)
    gg.toast("✨💗 اللهم صل على  םבםב 💗✨")
end

-- تشغيل القائمة
mainMenu()
end

function SMB9()
--لايك--
local oldRanges = gg.getRanges()

    gg.setVisible(false)
    local input = gg.prompt(
    {"👍🏻 اكتب عدد اللايكات 👍🏻", "🌸 اكتب مستوى المدينة 🌸"},
    {"0", "0"},
    {"number", "number"}
)

if input == nil then
    gg.toast("تم الإلغاء")
    return
end
    gg.setRanges(gg.REGION_OTHER)

    gg.searchNumber("600;1800;33;27:97", gg.TYPE_DWORD)
    gg.getResults(10)
    gg.sleep(3000)
    gg.refineNumber("1800", gg.TYPE_DWORD)

    local tas = gg.getResults(1000)
    if #tas == 0 then
        -- إرجاع النطاقات قبل الخروج
        gg.setRanges(oldRanges)
        gg.alert("❌ لم يتم العثور على نتائج")
        return
    end

    local saveList = {}

    for i = 1, #tas do
        local address = tas[i].address

        -- أوفست -44
        table.insert(saveList, {
            address = address - 144,
            flags = gg.TYPE_DWORD,
            value = 0,
            freeze = true
        })

        -- أوفست -40
        table.insert(saveList, {
            address = address - 140,
            flags = gg.TYPE_DWORD,
            value = 0,
            freeze = true
        })
        
        table.insert(saveList, {
            address = address - 136,
            flags = gg.TYPE_DWORD,
            value = 0,
            freeze = true
        })
    end

    gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()

    -- إرجاع النطاقات كما كانت في الجاردن
    gg.setRanges(oldRanges)

    gg.alert("🌀 ادخل أي مدينة واعملها لايك 🌀")
    gg.toast("✨💗 اللهم صل على םבםב 💗✨")
end

function SMB10()
--قطارات--
SSbb= gg.multiChoice({
"🚂 تصفير صناديق القطار🚂",
"🚂 طلب مساعدة قمح🚂",
"🚂إرسال البرسيم بعدد لا نهائي🚂",
"🚂طلب دعم 🚂",
" 👽☠b͢a͢c͢k͢ 👽☠ ",
  }, nil, "ꗟaher━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ℒℴѵℯ")
if SSbb == nil then else
if SSbb[1] == true then SSbb1() end
if SSbb[2] == true then SSbb2() end
if SSbb[3] == true then SSbb3() end
if SSbb[4] == true then SSbb4() end
if SSbb[5] == true then basmala() end
end
THSH = -1
end  

function SSbb1()
--تصفير صناديق القطار--
gg.setVisible(false)
gg.searchNumber("1801519104;51:13", gg.TYPE_DWORD)
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
gg.refineNumber("51", gg.TYPE_DWORD)
local r = gg.getResults(1000)

if not r or #r == 0 then
    gg.alert("❌ لم يتم العثور على نتائج.")
    return
end

local saveList = {}

-- الأوفستات العامة
local offsets = {
      12, 16, 20, 24, 28, 32, 36, 40, 44, 48,
    -4, -8, -12, -16, -20, -24, -28, -32, -36, -40, -44, -48,
    -52, -56, -60, -64, -68, -72, -76, -80, -84, -88, -92, -96, -100, -104, -108
}

-- الأوفستات الخاصة
local specialValues = {

    -- 🔥 تعديلك الجديد هنا: أوفست 52 → FLOAT = 1
    {52, 1, true, gg.TYPE_FLOAT},

  

  

    {-364, 1, true},
    {-660, 1, true},
    {-956, 1, true},
    {-1252, 1, true},
    {-1548, 1, true},
}

-- التطبيق
for i, result in ipairs(r) do
    local base = result.address

    -- العامة
    for _, off in ipairs(offsets) do
        local t = {}
        t[1] = {address = base + off, flags = gg.TYPE_DWORD, value = 0, freeze = true}
        gg.setValues(t)
        gg.addListItems(t)
        table.insert(saveList, t[1])
    end

    -- الخاصة
    for _, v in ipairs(specialValues) do
        local flag = v[4] or gg.TYPE_DWORD
        local t = {}
        t[1] = {address = base + v[1], flags = flag, value = v[2], freeze = v[3]}
        gg.setValues(t)
        gg.addListItems(t)
        table.insert(saveList, t[1])
    end
end

gg.clearResults()
gg.alert("🍉🦋 تم طلب القمح بجميع الصناديق 🦋🍉")
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")

end    


function SSbb2()
--طلب مساعدة بالقطار--
gg.setVisible(false)
gg.searchNumber("1801519104;51:13", gg.TYPE_DWORD)
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
gg.refineNumber("51", gg.TYPE_DWORD)
local r = gg.getResults(1000)

if not r or #r == 0 then
    gg.alert("❌ لم يتم العثور على نتائج.")
    return
end

local saveList = {}

-- الأوفستات العامة
local offsets = {
    0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48,
    -4, -8, -12, -16, -20, -24, -28, -32, -36, -40, -44, -48,
    -52, -56, -60, -64, -68, -72, -76, -80, -84, -88, -92, -96, -100, -104, -108
}

-- الأوفستات الخاصة
local specialValues = {

    -- 🔥 تعديلك الجديد هنا: أوفست 52 → FLOAT = 1
    {52, 1, true, gg.TYPE_FLOAT},

  

    {-332, 1, true},
    {-628, 1, true},
    {-924, 1, true},
    {-1220, 1, true},
    {-1516, 1, true},

    {-400, 1677751393, true}, {-404, 1701345034, true},
    {-696, 1677751393, true}, {-700, 1701345034, true},
    {-992, 1677751393, true}, {-996, 1701345034, true},
    {-1288, 1677751393, true}, {-1292, 1701345034, true},
    {-1584, 1677751393, true}, {-1588, 1701345034, true},

    {-376, 1, true}, {-380, 0, true},
    {-672, 1, true}, {-676, 0, true},
    {-968, 1, true}, {-972, 0, true},
    {-1264, 1, true}, {-1268, 0, true},
    {-1560, 1, true}, {-1564, 0, true},

    {-364, 1, false},
    {-660, 1, false},
    {-956, 1, false},
    {-1252, 1, false},
    {-1548, 1, false},
}

-- التطبيق
for i, result in ipairs(r) do
    local base = result.address

    -- العامة
    for _, off in ipairs(offsets) do
        local t = {}
        t[1] = {address = base + off, flags = gg.TYPE_DWORD, value = 0, freeze = true}
        gg.setValues(t)
        gg.addListItems(t)
        table.insert(saveList, t[1])
    end

    -- الخاصة
    for _, v in ipairs(specialValues) do
        local flag = v[4] or gg.TYPE_DWORD
        local t = {}
        t[1] = {address = base + v[1], flags = flag, value = v[2], freeze = v[3]}
        gg.setValues(t)
        gg.addListItems(t)
        table.insert(saveList, t[1])
    end
end

gg.clearResults()
gg.alert("🍉🦋 تم طلب القمح بجميع الصناديق 🦋🍉")
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")

end    

function SSbb3()
--طلب مساعدة بالقطار--
gg.setVisible(false)
gg.searchNumber("1801519104;51:13", gg.TYPE_DWORD)
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
gg.refineNumber("51", gg.TYPE_DWORD)
local r = gg.getResults(1000)

if not r or #r == 0 then
    gg.alert("❌ لم يتم العثور على نتائج.")
    return
end

local saveList = {}

-- الأوفستات العامة
local offsets = {
    0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48,
    -4, -8, -12, -16, -20, -24, -28, -32, -36, -40, -44, -48,
    -52, -56, -60, -64, -68, -72, -76, -80, -84, -88, -92, -96, -100, -104, -108
}

-- الأوفستات الخاصة
local specialValues = {

    -- 🔥 تعديلك الجديد هنا: أوفست 52 → FLOAT = 1
    {52, 1, true, gg.TYPE_FLOAT},

    {-1100, 0, true}, {-212, 0, true},
    {-508, 0, true}, {-1396, 0, true},
    {-804, 0, true},

    {-332, 1, true},
    {-628, 1, true},
    {-924, 1, true},
    {-1220, 1, true},
    {-1516, 1, true},

    {-400, 1677751393, true}, {-404, 1701345034, true},
    {-696, 1677751393, true}, {-700, 1701345034, true},
    {-992, 1677751393, true}, {-996, 1701345034, true},
    {-1288, 1677751393, true}, {-1292, 1701345034, true},
    {-1584, 1677751393, true}, {-1588, 1701345034, true},

    {-376, 1, true}, {-380, 0, true},
    {-672, 1, true}, {-676, 0, true},
    {-968, 1, true}, {-972, 0, true},
    {-1264, 1, true}, {-1268, 0, true},
    {-1560, 1, true}, {-1564, 0, true},

    {-364, 1, false},
    {-660, 1, false},
    {-956, 1, false},
    {-1252, 1, false},
    {-1548, 1, false},
}

-- التطبيق
for i, result in ipairs(r) do
    local base = result.address

    -- العامة
    for _, off in ipairs(offsets) do
        local t = {}
        t[1] = {address = base + off, flags = gg.TYPE_DWORD, value = 0, freeze = true}
        gg.setValues(t)
        gg.addListItems(t)
        table.insert(saveList, t[1])
    end

    -- الخاصة
    for _, v in ipairs(specialValues) do
        local flag = v[4] or gg.TYPE_DWORD
        local t = {}
        t[1] = {address = base + v[1], flags = flag, value = v[2], freeze = v[3]}
        gg.setValues(t)
        gg.addListItems(t)
        table.insert(saveList, t[1])
    end
end

gg.clearResults()
gg.alert("🍉🦋 تم طلب القمح بجميع الصناديق 🦋🍉")
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")

end  
function SSbb4()
--طلب دعم بالقطار --
gg.setVisible(false)
gg.searchNumber("1801519104;51:13", gg.TYPE_DWORD)
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
gg.refineNumber("51", gg.TYPE_DWORD)
local r = gg.getResults(1000)

if not r or #r == 0 then
    gg.alert("❌ لم يتم العثور على نتائج.")
    return
end

local saveList = {}

-- الأوفستات العامة
local offsets = {
    0, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48,
    -4, -8, -12, -16, -20, -24, -28, -32, -36, -40, -44, -48,
    -52, -56, -60, -64, -68, -72, -76, -80, -84, -88, -92, -96, -100, -104, -108
}

-- الأوفستات الخاصة
local specialValues = {

    -- 🔥 تعديلك الجديد هنا: أوفست 52 → FLOAT = 1
    {52, 1, true, gg.TYPE_FLOAT},



    {-332, 1, true},
    {-628, 1, true},
    {-924, 1, true},
    {-1220, 1, true},
    {-1516, 1, true},

    {-400, 7630706, true}, {-404, 1918984972, true},
    {-696, 7630706, true}, {-700, 1918984972, true},
    {-992, 7630706, true}, {-996, 1918984972, true},
    {-1288, 7630706, true}, {-1292, 1918984972, true},
    {-1584, 7630706, true}, {-1588, 1918984972, true},

    {-376, 9999, true}, {-380, 0, true},
    {-672, 9999, true}, {-676, 0, true},
    {-968, 9999, true}, {-972, 0, true},
    {-1264, 9999, true}, {-1268, 0, true},
    {-1560, 9999, true}, {-1564, 0, true},

    {-364, 1, false},
    {-660, 1, false},
    {-956, 1, false},
    {-1252, 1, false},
    {-1548, 1, false},
}

-- التطبيق
for i, result in ipairs(r) do
    local base = result.address

    -- العامة
    for _, off in ipairs(offsets) do
        local t = {}
        t[1] = {address = base + off, flags = gg.TYPE_DWORD, value = 0, freeze = true}
        gg.setValues(t)
        gg.addListItems(t)
        table.insert(saveList, t[1])
    end

    -- الخاصة
    for _, v in ipairs(specialValues) do
        local flag = v[4] or gg.TYPE_DWORD
        local t = {}
        t[1] = {address = base + v[1], flags = flag, value = v[2], freeze = v[3]}
        gg.setValues(t)
        gg.addListItems(t)
        table.insert(saveList, t[1])
    end
end

gg.clearResults()
gg.alert("🍉🦋 تم طلب القمح بجميع الصناديق 🦋🍉")
gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")

end      
function SMB11()
--مطار--
SSbm= gg.multiChoice({
"✈️تصفير صناديق المطار✈️",
"✈️طلب مساعدة قمح✈️",
"✈️إرسال البرسيم بعدد لا نهائي ✈️",
"✈️طلب دعم ✈️",
" 👽☠b͢a͢c͢k͢ 👽☠ ",
  }, nil, "ꗟaher━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ℒℴѵℯ")
if SSbm == nil then else
if SSbm[1] == true then SSbm1() end
if SSbm[2] == true then SSbm2() end
if SSbm[3] == true then SSbm3() end
if SSbm[4] == true then SSbm4() end
if SSbm[5] == true then basmala() end
end
THSH = -1
end


function SSbm1()
--تصفير منتجات الطائرة--
gg.alert("🍉🍇أنتظر انتهاء البحث🍇🍉")
gg.clearResults()
-- البحث الأول
gg.searchNumber("4294901755X72", gg.TYPE_DWORD)
gg.refineNumber("-1", gg.TYPE_DWORD)
local r = gg.getResults(50000)
local count = gg.getResultsCount()

if count == 0 then
    gg.alert("لا توجد نتائج، أغلق اللعبة وافتحها")
    return
end

-- ✅ دالة التحقق للبحث الأول
function checkFirstSearch(address)
    local checks = {
        {offset = - 68, cond = function(v) return v == 0 end},
        {offset = - 60, cond = function(v) return v < 130 end},
        {offset = - 48, cond = function(v) return v > 1000000000 end},
    }

    local temp = {}
    for i, c in ipairs(checks) do
        temp[i] = {address = address + c.offset, flags = gg.TYPE_DWORD}
    end
    temp = gg.getValues(temp)

    for i, c in ipairs(checks) do
        if not c.cond(temp[i].value) then
            return false
        end
    end

    return true
end

local saving = {}
local extracted_values = {}
local freezeValues = {}
local validResults = {}

-- ✅ تطبيق التجميد على كل النتائج الصالحة
local preOffsets = {
    {-56, 1},
    {-48, 1701345034},
    {-44, 29793},
    {-40, 0},
    {-36, 0},
    {-32, 0},
    {-28, 0}
}

for i = 1, #r do
    if checkFirstSearch(r[i].address) then
        table.insert(validResults, r[i])
        -- تعديل وتجميد القيم لكل نتيجة صالحة
        for _, pair in ipairs(preOffsets) do
            local t = {}
            t[1] = {address = r[i].address + pair[1], flags = gg.TYPE_DWORD, value = pair[2], freeze = true}
            gg.setValues(t)
            table.insert(freezeValues, t[1])
        end
    end
end

if #validResults == 0 then
    gg.alert("🚫 لم يتم العثور على أي نتائج تحقق الشروط 🚫")
    return
end

gg.addListItems(freezeValues) -- إضافة كل المجمدات

-- ✅ الاستخراج من نتيجة واحدة فقط (أول نتيجة صالحة)
local chosenResult = validResults[1]

local offsets = {-24}
for i, offset in ipairs(offsets) do
    local temp = {}
    temp[1] = {address = chosenResult.address + offset, flags = gg.TYPE_DWORD}
    temp = gg.getValues(temp)
    table.insert(saving, temp[1])
    table.insert(extracted_values, temp[1].value)
end

gg.addListItems(saving)
gg.clearResults()

-- هنا يبدأ البحث الثاني كما عندك
-- دالة التحقق من القيم قبل التعديل
function checkConditions(address)
    local offsets = {-4, -8}
    local temp = {}

    for i, offset in ipairs(offsets) do
        temp[i] = {}
        temp[i].address = address + offset
        temp[i].flags = gg.TYPE_DWORD
    end

    temp = gg.getValues(temp)

    for _, item in ipairs(temp) do
        if item.value ~= 0 then
            return false
        end
    end

    return true
end

-- بدء البحث الثاني باستخدام القيم المستخرجة
gg.alert("✨💗 اللهم صل على  םבםב 💗✨")

local search_string = table.concat(extracted_values, ";")
gg.searchNumber(search_string, gg.TYPE_DWORD)
gg.refineNumber(extracted_values[1], gg.TYPE_DWORD)

local soso = gg.getResults(10000)
local saveList = {}
local foundValid = false

for i = 1, #soso do
    local address = soso[i].address

    if checkConditions(address) then
        foundValid = true

        local offsets = {
            {-8, false}  -- تعديل قيمة الصقل فقط بدون تجميد
        }

        for _, pair in ipairs(offsets) do
            local offset, shouldFreeze = pair[1], pair[2]
            local t = {}
            t[1] = {}
            t[1].address = address + offset
            t[1].flags = gg.TYPE_DWORD
            t[1].value = 1
            t[1].freeze = shouldFreeze
            gg.setValues(t)
            if shouldFreeze then
                gg.addListItems(t)
            end
            table.insert(saveList, t[1])
        end
    end
end

gg.clearResults()

if not foundValid then
    gg.alert("لم يتم إيجاد أي عنوان يحقق الشروط. لم يتم تنفيذ أي تعديل.")
else
    gg.alert("🍉تم التعديل بنجاح🍉")
    gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end
 end    
function SSbm2() 
--طلبات مساعدات الطائره--
gg.alert("🍉🍇أنتظر انتهاء البحث🍇🍉")
gg.clearResults()
-- البحث الأول
gg.searchNumber("4294901755X72", gg.TYPE_DWORD)
gg.refineNumber("-1", gg.TYPE_DWORD)
local r = gg.getResults(50000)
local count = gg.getResultsCount()

if count == 0 then
    gg.alert("لا توجد نتائج، أغلق اللعبة وافتحها")
    return
end

-- ✅ دالة التحقق للبحث الأول
function checkFirstSearch(address)
    local checks = {
        {offset = - 68, cond = function(v) return v == 0 end},
        {offset = - 60, cond = function(v) return v < 130 end},
        {offset = - 48, cond = function(v) return v > 1000000000 end},
    }

    local temp = {}
    for i, c in ipairs(checks) do
        temp[i] = {address = address + c.offset, flags = gg.TYPE_DWORD}
    end
    temp = gg.getValues(temp)

    for i, c in ipairs(checks) do
        if not c.cond(temp[i].value) then
            return false
        end
    end

    return true
end

local saving = {}
local extracted_values = {}
local freezeValues = {}
local validResults = {}

-- ✅ تطبيق التجميد على كل النتائج الصالحة
local preOffsets = {
    {-56, 1},
    {-48, 1701345034},
    {-44, 29793},
    {-40, 0},
    {-36, 0},
    {-32, 0},
    {-28, 0}
}

for i = 1, #r do
    if checkFirstSearch(r[i].address) then
        table.insert(validResults, r[i])
        -- تعديل وتجميد القيم لكل نتيجة صالحة
        for _, pair in ipairs(preOffsets) do
            local t = {}
            t[1] = {address = r[i].address + pair[1], flags = gg.TYPE_DWORD, value = pair[2], freeze = true}
            gg.setValues(t)
            table.insert(freezeValues, t[1])
        end
    end
end

if #validResults == 0 then
    gg.alert("🚫 لم يتم العثور على أي نتائج تحقق الشروط 🚫")
    return
end

gg.addListItems(freezeValues) -- إضافة كل المجمدات

-- ✅ الاستخراج من نتيجة واحدة فقط (أول نتيجة صالحة)
local chosenResult = validResults[1]

local offsets = {-24}
for i, offset in ipairs(offsets) do
    local temp = {}
    temp[1] = {address = chosenResult.address + offset, flags = gg.TYPE_DWORD}
    temp = gg.getValues(temp)
    table.insert(saving, temp[1])
    table.insert(extracted_values, temp[1].value)
end

gg.addListItems(saving)
gg.clearResults()

-- هنا يبدأ البحث الثاني كما عندك
-- دالة التحقق من القيم قبل التعديل
function checkConditions(address)
    local offsets = {-4, -8}
    local temp = {}

    for i, offset in ipairs(offsets) do
        temp[i] = {}
        temp[i].address = address + offset
        temp[i].flags = gg.TYPE_DWORD
    end

    temp = gg.getValues(temp)

    for _, item in ipairs(temp) do
        if item.value ~= 0 then
            return false
        end
    end

    return true
end

-- بدء البحث الثاني باستخدام القيم المستخرجة
gg.alert("✨💗 اللهم صل على  םבםב 💗✨")

local search_string = table.concat(extracted_values, ";")
gg.searchNumber(search_string, gg.TYPE_DWORD)
gg.refineNumber(extracted_values[1], gg.TYPE_DWORD)

local soso = gg.getResults(10000)
local saveList = {}
local foundValid = false

for i = 1, #soso do
    local address = soso[i].address

    if checkConditions(address) then
        foundValid = true

        local offsets = {
            {-16, false}  -- تعديل قيمة الصقل فقط بدون تجميد
        }

        for _, pair in ipairs(offsets) do
            local offset, shouldFreeze = pair[1], pair[2]
            local t = {}
            t[1] = {}
            t[1].address = address + offset
            t[1].flags = gg.TYPE_DWORD
            t[1].value = 1
            t[1].freeze = shouldFreeze
            gg.setValues(t)
            if shouldFreeze then
                gg.addListItems(t)
            end
            table.insert(saveList, t[1])
        end
    end
end

gg.clearResults()

if not foundValid then
    gg.alert("لم يتم إيجاد أي عنوان يحقق الشروط. لم يتم تنفيذ أي تعديل.")
else
    gg.alert("🍉تم التعديل بنجاح🍉")
    gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end
 end    
 
function SSbm3() 
--طلبات مساعدات الطائره--
gg.alert("🍉🍇أنتظر انتهاء البحث🍇🍉")
gg.clearResults()
-- البحث الأول
gg.searchNumber("4294901755X72", gg.TYPE_DWORD)
gg.refineNumber("-1", gg.TYPE_DWORD)
local r = gg.getResults(50000)
local count = gg.getResultsCount()

if count == 0 then
    gg.alert("لا توجد نتائج، أغلق اللعبة وافتحها")
    return
end

-- ✅ دالة التحقق للبحث الأول
function checkFirstSearch(address)
    local checks = {
        {offset = - 68, cond = function(v) return v == 0 end},
        {offset = - 60, cond = function(v) return v < 130 end},
        {offset = - 48, cond = function(v) return v > 1000000000 end},
    }

    local temp = {}
    for i, c in ipairs(checks) do
        temp[i] = {address = address + c.offset, flags = gg.TYPE_DWORD}
    end
    temp = gg.getValues(temp)

    for i, c in ipairs(checks) do
        if not c.cond(temp[i].value) then
            return false
        end
    end

    return true
end

local saving = {}
local extracted_values = {}
local freezeValues = {}
local validResults = {}

-- ✅ تطبيق التجميد على كل النتائج الصالحة
local preOffsets = {
    {-56, 1},
    {-48, 1701345034},
    {-44, 29793},
    {-40, 0},
    {-36, 0},
    {-32, 0},
    {-28, 0}
}

for i = 1, #r do
    if checkFirstSearch(r[i].address) then
        table.insert(validResults, r[i])
        -- تعديل وتجميد القيم لكل نتيجة صالحة
        for _, pair in ipairs(preOffsets) do
            local t = {}
            t[1] = {address = r[i].address + pair[1], flags = gg.TYPE_DWORD, value = pair[2], freeze = true}
            gg.setValues(t)
            table.insert(freezeValues, t[1])
        end
    end
end

if #validResults == 0 then
    gg.alert("🚫 لم يتم العثور على أي نتائج تحقق الشروط 🚫")
    return
end

gg.addListItems(freezeValues) -- إضافة كل المجمدات

-- ✅ الاستخراج من نتيجة واحدة فقط (أول نتيجة صالحة)
local chosenResult = validResults[1]

local offsets = {-24}
for i, offset in ipairs(offsets) do
    local temp = {}
    temp[1] = {address = chosenResult.address + offset, flags = gg.TYPE_DWORD}
    temp = gg.getValues(temp)
    table.insert(saving, temp[1])
    table.insert(extracted_values, temp[1].value)
end

gg.addListItems(saving)
gg.clearResults()

-- هنا يبدأ البحث الثاني كما عندك
-- دالة التحقق من القيم قبل التعديل
function checkConditions(address)
    local offsets = {-4, 20, -28, -132}
    local temp = {}

    for i, offset in ipairs(offsets) do
        temp[i] = {}
        temp[i].address = address + offset
        temp[i].flags = gg.TYPE_DWORD
    end

    temp = gg.getValues(temp)

    for _, item in ipairs(temp) do
        if item.value ~= 0 then
            return false
        end
    end

    return true
end
-- بدء البحث الثاني باستخدام القيم المستخرجة
gg.alert("🍇🍉اللهم صل وسلم وبارك على سيدنا محمد واله وصحبه أجمعين🍉🍇")

local search_string = table.concat(extracted_values, ";")
gg.searchNumber(search_string, gg.TYPE_DWORD)
gg.refineNumber(extracted_values[1], gg.TYPE_DWORD)

local soso = gg.getResults(10000)
local saveList = {}
local foundValid = false

for i = 1, #soso do
    local address = soso[i].address

    if checkConditions(address) then
        foundValid = true

        local offsets = {
    {-136, true}  -- تعديل مع تجميد
}

for _, pair in ipairs(offsets) do
    local offset, shouldFreeze = pair[1], pair[2]
    local t = {}
    t[1] = {}
    t[1].address = address + offset
    t[1].flags = gg.TYPE_DWORD
    t[1].value = 0
    t[1].freeze = shouldFreeze
    gg.setValues(t)
    if shouldFreeze then
        gg.addListItems(t)
    end
    table.insert(saveList, t[1])
end
    end
end

gg.clearResults()

if not foundValid then
    gg.alert("لم يتم إيجاد أي عنوان يحقق الشروط. لم يتم تنفيذ أي تعديل.")
else
    gg.alert("🍉تم التعديل بنجاح🍉")
    gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end
 end    
function SSbm4() 
--طلب دعم بالطائره--
gg.alert("🍉🍇أنتظر انتهاء البحث🍇🍉")
gg.clearResults()
-- البحث الأول
gg.searchNumber("4294901755X72", gg.TYPE_DWORD)
gg.refineNumber("-1", gg.TYPE_DWORD)
local r = gg.getResults(50000)
local count = gg.getResultsCount()

if count == 0 then
    gg.alert("لا توجد نتائج، أغلق اللعبة وافتحها")
    return
end

-- ✅ دالة التحقق للبحث الأول
function checkFirstSearch(address)
    local checks = {
        {offset = - 68, cond = function(v) return v == 0 end},
        {offset = - 60, cond = function(v) return v < 130 end},
        {offset = - 48, cond = function(v) return v > 1000000000 end},
    }

    local temp = {}
    for i, c in ipairs(checks) do
        temp[i] = {address = address + c.offset, flags = gg.TYPE_DWORD}
    end
    temp = gg.getValues(temp)

    for i, c in ipairs(checks) do
        if not c.cond(temp[i].value) then
            return false
        end
    end

    return true
end

local saving = {}
local extracted_values = {}
local freezeValues = {}
local validResults = {}

-- ✅ تطبيق التجميد على كل النتائج الصالحة
local preOffsets = {
  {-56, 9999},
    {-48, 1918984972},
    {-44, 7630706},
    {-40, 0},
    {-36, 0},
    {-32, 0},
    {-28, 0}
}

for i = 1, #r do
    if checkFirstSearch(r[i].address) then
        table.insert(validResults, r[i])
        -- تعديل وتجميد القيم لكل نتيجة صالحة
        for _, pair in ipairs(preOffsets) do
            local t = {}
            t[1] = {address = r[i].address + pair[1], flags = gg.TYPE_DWORD, value = pair[2], freeze = true}
            gg.setValues(t)
            table.insert(freezeValues, t[1])
        end
    end
end

if #validResults == 0 then
    gg.alert("🚫 لم يتم العثور على أي نتائج تحقق الشروط 🚫")
    return
end

gg.addListItems(freezeValues) -- إضافة كل المجمدات

-- ✅ الاستخراج من نتيجة واحدة فقط (أول نتيجة صالحة)
local chosenResult = validResults[1]

local offsets = {-24}
for i, offset in ipairs(offsets) do
    local temp = {}
    temp[1] = {address = chosenResult.address + offset, flags = gg.TYPE_DWORD}
    temp = gg.getValues(temp)
    table.insert(saving, temp[1])
    table.insert(extracted_values, temp[1].value)
end

gg.addListItems(saving)
gg.clearResults()

-- هنا يبدأ البحث الثاني كما عندك
-- دالة التحقق من القيم قبل التعديل
function checkConditions(address)
    local offsets = {-4, -8}
    local temp = {}

    for i, offset in ipairs(offsets) do
        temp[i] = {}
        temp[i].address = address + offset
        temp[i].flags = gg.TYPE_DWORD
    end

    temp = gg.getValues(temp)

    for _, item in ipairs(temp) do
        if item.value ~= 0 then
            return false
        end
    end

    return true
end

-- بدء البحث الثاني باستخدام القيم المستخرجة
gg.alert("✨💗 اللهم صل على  םבםב 💗✨")

local search_string = table.concat(extracted_values, ";")
gg.searchNumber(search_string, gg.TYPE_DWORD)
gg.refineNumber(extracted_values[1], gg.TYPE_DWORD)

local soso = gg.getResults(10000)
local saveList = {}
local foundValid = false

for i = 1, #soso do
    local address = soso[i].address

    if checkConditions(address) then
        foundValid = true

        local offsets = {
            {-16, false}  -- تعديل قيمة الصقل فقط بدون تجميد
        }

        for _, pair in ipairs(offsets) do
            local offset, shouldFreeze = pair[1], pair[2]
            local t = {}
            t[1] = {}
            t[1].address = address + offset
            t[1].flags = gg.TYPE_DWORD
            t[1].value = 1
            t[1].freeze = shouldFreeze
            gg.setValues(t)
            if shouldFreeze then
                gg.addListItems(t)
            end
            table.insert(saveList, t[1])
        end
    end
end

gg.clearResults()

if not foundValid then
    gg.alert("لم يتم إيجاد أي عنوان يحقق الشروط. لم يتم تنفيذ أي تعديل.")
else
    gg.alert("🍉تم التعديل بنجاح🍉")
    gg.toast("🍉ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍉")
end
 end    
   
function SMB12()
--زيادة الكروت--
gg.setVisible(false)

gg.searchNumber("1918984974;1918984976", gg.TYPE_DWORD)
local r = gg.getResults(30000)

local input = gg.prompt(
    {"العدد"},
    {0},
    {"number"}
)

if input == nil then
    gg.toast("🌹لم يتم إدخال قيم. العملية ألغيت.🌹")
    return
end

for i, v in ipairs(r) do
    -- قراءة قيمة +28
    local read = gg.getValues({
        {
            address = v.address + 28,  -- قراءة +28 الديسمل
            flags = gg.TYPE_DWORD
        }
    })

    -- التحقق: لازم تكون القيمة أقل من 100
    if read[1].value < 100 then
        local edit = {
            {
                address = v.address + 28, -- تعديل +28
                flags = gg.TYPE_DWORD,
                value = input[1]
            }
        }

        gg.setValues(edit)
        gg.addListItems(edit)
    end
end

gg.clearResults()
gg.alert('🌸تم زيادة الكروت🌸')
gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
end
function SMB13()
--ارسال الكروت--    
gg.searchNumber("16846377X32", gg.TYPE_DWORD)
    gg.getResults(1000)
    gg.refineNumber("1684828007", gg.TYPE_DWORD)
    tas = gg.getResults(100)
 
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address 
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 0
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])
    gg.clearResults()
    gg.alert("🌸تم تحويل الكروت لسيلفر🌸")
    gg.toast("ꗟaher━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━")
gg.searchNumber("110207X36", gg.TYPE_DWORD)
    gg.getResults(1000)
    gg.refineNumber("86400", gg.TYPE_DWORD)
    tas = gg.getResults(100)
 
    local saveList = {}
    for i = 1, #tas do
        local address = tas[i].address

        local t1 = {}
        t1[1] = {}
        t1[1].address = address + 32
        t1[1].flags = gg.TYPE_DWORD
        t1[1].value = 0
        t1[1].freeze = true
        gg.setValues(t1)
        table.insert(saveList, t1[1])


        local t2 = {}
        t2[1] = {}
        t2[1].address = address + 36
        t2[1].flags = gg.TYPE_DWORD
        t2[1].value = 0
        t2[1].freeze = true
        gg.setValues(t2)
        table.insert(saveList, t2[1])


        local t3 = {}
        t3[1] = {}
        t3[1].address = address + 40
        t3[1].flags = gg.TYPE_DWORD
        t3[1].value = 0
        t3[1].freeze = true
        gg.setValues(t3)
        table.insert(saveList, t3[1])
        
        
        local t3 = {}
        t3[1] = {}
        t3[1].address = address + 44
        t3[1].flags = gg.TYPE_DWORD
        t3[1].value = 0
        t3[1].freeze = true
        gg.setValues(t3)
        table.insert(saveList, t3[1])
        
        local t3 = {}
        t3[1] = {}
        t3[1].address = address + 48
        t3[1].flags = gg.TYPE_DWORD
        t3[1].value = 0
        t3[1].freeze = true
        gg.setValues(t3)
        table.insert(saveList, t3[1])
        
        local t3 = {}
        t3[1] = {}
        t3[1].address = address + 52
        t3[1].flags = gg.TYPE_DWORD
        t3[1].value = 0
        t3[1].freeze = true
        gg.setValues(t3)
        table.insert(saveList, t3[1])
        end
        
        gg.setValues(saveList)
    gg.addListItems(saveList)
    gg.clearResults()
    gg.alert("🍉")
    gg.toast("🎀ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🎀")
    
    
end
end
function SMB14()        
gg.setVisible(false)
local SavedAddr = nil
-- 🔹 البحث والتخزين فقط (بدون تعديل)
function InitSearch()
    gg.clearResults()

    gg.searchNumber(
        "1635139872;1181901172;1701667186;1970037343;101::17",
        gg.TYPE_DWORD
    )

    local r = gg.getResults(1000)
    if #r == 0 then
        gg.toast("❌ لم يتم العثور على نتائج أساسية")
        return false
    end

    gg.clearResults()

    -- البحث القريب
    gg.searchNumber(
        "1970037256",
        gg.TYPE_DWORD,
        false,
        gg.SIGN_EQUAL,
        0,
        -1,
        2000
    )

    local near = gg.getResults(1000)
    if #near == 0 then
        gg.toast("❌ لا توجد نتائج قريبة")
        return false
    end

    SavedAddr = near
    gg.toast("✅ تم تخزين العناوين")
    return true
end

-- 🔹 تطبيق التعديلات حسب الاختيار
function ApplyValues(frameValue, plus8)
    if not SavedAddr then
        gg.toast("⚠️ لم يتم التخزين بعد")
        return
    end

    local edits = {}
    for _, v in ipairs(SavedAddr) do
        -- +0
        edits[#edits+1] = {
            address = v.address,
            flags = gg.TYPE_DWORD,
            value = 1634887184
        }
        -- +4
        edits[#edits+1] = {
            address = v.address + 4,
            flags = gg.TYPE_DWORD,
            value = 811558253
        }
        -- +8 (حسب الخيار)
        edits[#edits+1] = {
            address = v.address + 8,
            flags = gg.TYPE_DWORD,
            value = plus8
        }
    end

    gg.setValues(edits)
    gg.toast("✅ تم تطبيق الإطار")
end

-- 🔹 القائمة
function Menu()
    local m = gg.choice({
"😶‍🌫️ايطار الثروة المتجمده😶‍🌫️",
"🥶ايطار الجليد🥶",
"🐲ايطار التنين🐲", 
"🔙『  رجوع 』🔙",
    }, nil, "اختر الإطار")

    if m == 1 then
        ApplyValues(3223647, 49)
    elseif m == 2 then
        ApplyValues(3289183, 50)
    elseif m == 3 then
        ApplyValues(3354719, 51)
    elseif m == 4 then
        BASMALASAHERB1()  
    end
end


-- 🔹 التشغيل
if InitSearch() then
    while true do
        if gg.isVisible(true) then
            gg.setVisible(false)
            Menu()
        end
        gg.sleep(100)
    end
end
end
function BASMALASAHERB2()  
--------------------------------------------------
-- ▶️ البحث الأول
--------------------------------------------------
gg.clearResults()
gg.searchNumber("1379101978;1651403105;-1;8;28:433", gg.TYPE_DWORD)
gg.getResults(100)
gg.sleep(3000)
gg.refineNumber("28", gg.TYPE_DWORD)
gg.toast("✅ البحث اكتمل")

--------------------------------------------------
-- ⚙️ دالة التعديل الأساسية (نفس منطقك)
--------------------------------------------------
function applyPointer(codeData)
    local r = gg.getResults(1)
    if #r == 0 then
        gg.alert("❌ لم يتم العثور على المؤشر")
        return
    end

    local base = r[1].address

    -- حفظ القيم الأصلية
    local stored = gg.getValues({
        {address = base - 48, flags = gg.TYPE_DWORD},
        {address = base - 44, flags = gg.TYPE_DWORD}
    })
    local v48 = stored[1].value
    local v44 = stored[2].value

    -- التعديل قبل الانتقال بالمؤشر
    gg.setValues({
        {address = base + 16, flags = gg.TYPE_DWORD, value = codeData.v16 or 33},
        {address = base + 20, flags = gg.TYPE_DWORD, value = codeData.v20 or 0},
        {address = base + 24, flags = gg.TYPE_DWORD, value = codeData.value24 or 0},
        {address = base + 28, flags = gg.TYPE_DWORD, value = codeData.v28 or 0},
        {address = base + 32, flags = gg.TYPE_DWORD, value = v48},
        {address = base + 36, flags = gg.TYPE_DWORD, value = v44}
    })

    -- الانتقال من المؤشر
    local pointer = gg.getValues({
        {address = base + 32, flags = gg.TYPE_QWORD}
    })[1].value

    -- التعديل داخل المؤشر (إن وجد)
    if codeData.pointerValues then
        local edits = {}
        for i = 1, #codeData.pointerValues do
            table.insert(edits, {
                address = pointer + (i - 1) * 4,
                flags = gg.TYPE_DWORD,
                value = codeData.pointerValues[i]
            })
        end
        gg.setValues(edits)
    end

    -- تعديل مباشر بدون مؤشر (إن وجد)
    if codeData.directValues then
        local offsets = {16,20,24,28,32,36}
        local edits = {}
        for i = 1, #codeData.directValues do
            table.insert(edits, {
                address = base + offsets[i],
                flags = gg.TYPE_DWORD,
                value = codeData.directValues[i]
            })
        end
        gg.setValues(edits)
    end

    gg.alert("🎀 اذهب استلم الهديه 28 🎀")
    gg.toast("🍇ʚïɞ ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ🍇")
    gg.sleep(15000)
end

--------------------------------------------------
-- 📦 البيانات
--------------------------------------------------

-- الزينه
local shonaData = {
    {
    name = "𓊆 ★ᯓ حديقة المغامرة ᯓ★ 𓊇",
    directValues = {1667580958,1415541359,1214604658,1702065519,0,0}
},
{
    name = "𓊆 ★ᯓ سينما خارجيه ᯓ★ 𓊇",
    directValues = {1920234282,1131701605,1835363945,1633902433,1752393067,28783}
},
{
    name = "𓊆 ★ᯓ الرقم السحري ᯓ★ 𓊇",
    directValues = {2003127824,1634031967,114,0,0,0}
},
{
    name = "𓊆 ★ᯓ حوض اسماك سعيد ᯓ★ 𓊇",
    directValues = {1885423644,1096776048,1918989681,7173481,0,0}
},
{
    name = "𓊆 ★ᯓ طاهي السلطعون ᯓ★ 𓊇",
    directValues = {1634878226,1866686306,27503,0,0,0}
},
{
    name = "𓊆 ★ᯓ مكتب سانتا ᯓ★ 𓊇",
    directValues = {1851872030,1381982580,1885692773,1852795252,0,0}
},
{
    name = "𓊆 ★ᯓ كوخ رجل الثلج ᯓ★ 𓊇",
    directValues = {1634289434,1398764654,1836543854,28257,0,0}
},
{
    name = "𓊆 ★ᯓ جوقة الاعياد ᯓ★ 𓊇",
    directValues = {1919435552,1836348265,1130328929,1970433896,115,0}
},
{
    name = "𓊆 ★ᯓ محطة الاتصالات ᯓ★ 𓊇",
    directValues = {1852785438,1952671086,1635013471,1852795252,0,0}
},
{
    name = "𓊆 ★ᯓ ورشة سانتا ᯓ★ 𓊇",
    directValues = {1987003156,1197437541,7628393,0,0,0}
},
{
    name = "𓊆 ★ᯓ زقاق سحري ᯓ★ 𓊇",
    directValues = {1919435550,1836348265,1952412513,1852399986,0,0}
},
{
    name = "𓊆 ★ᯓ جسر لشخصين ᯓ★ 𓊇",
    directValues = {1919435562,1836348265,1918137185,1601071457,1684632130,25959}
},
{
    name = "𓊆 ★ᯓ متجر الاعياد ᯓ★ 𓊇",
    directValues = {1919435548,1836348265,1180660577,7498081,0,0}
},
{
    name = "𓊆 ★ᯓ الينابيع الساخنه ᯓ★ 𓊇",
    directValues = {1953450008,1970226783,1767994478,110,0,0}
},
{
    name = "𓊆 ★ᯓ زلاجة النعجات ᯓ★ 𓊇",
    directValues = {1701335828,1817407589,6644841,0,0,0}
},
{
    name = "𓊆 ★ᯓ مسار الحبل ᯓ★ 𓊇",
    directValues = {1667580956,1381986927,1885696111,7041633,0,0}
},
{
    name = "𓊆 ★ᯓ الكريسماس في القطار ᯓ★ 𓊇",
    directValues = {1919435548,1836348265,1130328929,6645345,0,0}
},
{
    name = "𓊆 ★ᯓ فرعوتي زينه ᯓ★ 𓊇",
    directValues = {1970227226,1732601203,1769238649,28257,0,0}
},
{
    name = "𓊆 ★ᯓ زينة المصرييين ᯓ★ 𓊇",
    directValues = {1768649504,2003780467,2037149535,1634300013,100,0}
},
{
    name = "𓊆 ★ᯓ تمثال النصر ᯓ★ 𓊇",
    directValues = {1919512614,1399157857,1601202536,1634038388,1701999987,0}
},
{
    name = "𓊆 ★ᯓ كنز بالدرساري ᯓ★ 𓊇",
    directValues = {1634034210,1601795189,1634497633,1634230131,25710,0}
},
{
    name = "𓊆 ★ᯓ رمح ثلاثي اطلنتي ᯓ★ 𓊇",
    directValues = {1920295708,1735289196,1853190751,7497070,0,0}
},
{
    name = "𓊆 ★ᯓ اطلال اتلانتس ᯓ★ 𓊇",
    directValues = {1634034218,1601795189,1634497633,1936290926,1769304671,29550}
},
{
    name = "𓊆 ★ᯓ حارس الكنز ᯓ★ 𓊇",
    directValues = {1667591462,1634878568,1601072999,1768187245,1818326629,0}
},
{
    name = "𓊆 ★ᯓ التابوت الحجري ᯓ★ 𓊇",
    directValues = {1634034206,1601795189,1869506916,1920295283,0,0}
},
{
    name = "𓊆 ★ᯓ صندوق الكنز ᯓ★ 𓊇",
    directValues = {1634034218,1601795189,1634038388,1701999987,1701339999,29811}
},
{
    name = "𓊆 ★ᯓ تمثال الجرعان ᯓ★ 𓊇",
    directValues = {2003784722,1632001902,29289,0,0,0}
},
{
    name = "𓊆 ★ᯓ حارس الفائق ᯓ★ 𓊇",
    directValues = {1919512618,1399157857,1970561396,1920229221,1970495845,25970}
},
{
    name = "𓊆 ★ᯓ منجم الذهب ᯓ★ 𓊇",
    directValues = {1819232024,1766088548,1919248231,115,0,0}
},
{
    name = "𓊆 ★ᯓ حارس الثروه ᯓ★ 𓊇",
    directValues = {1634886696,1601072999,1952543859,1398760821,809000784,48}
}, 

{
    name = "𓊆 ★ᯓ قطة المحبوبة ᯓ★ 𓊇",
    directValues = {1818318374,1769238117,1885300078,1752397164,1952539487,0}
},
{
    name = "𓊆 ★ᯓ أرنب محشو ᯓ★ 𓊇",
    directValues = {1818318366,1769238117,1113548142,2037280373,0,0}
},
{
    name = "𓊆 ★ᯓ سهم كيوبيد ᯓ★ 𓊇",
    directValues = {1818318378,1769238117,1130325358,1684631669,1920090483,30575}
},
{
    name = "𓊆 ★ᯓ مقعد المحبين ᯓ★ 𓊇",
    directValues = {1818318380,1769238117,1818191214,1919252079,1700945779,6841198}
},
{
    name = "𓊆 ★ᯓ ارجوحه دواره ᯓ★ 𓊇",
    directValues = {1818318380,1769238117,1398760814,1735289207,1987013727,7565925}
},
{
    name = "𓊆 ★ᯓ مشتل الازهار مع الملائكة ᯓ★ 𓊇",
    directValues = {1818318374,1769238117,1180657006,1702326124,1684365938,0}
},
{
    name = "𓊆 ★ᯓ دب كيووت ᯓ★ 𓊇",
    directValues = {1818318376,1769238117,1415538030,2036622437,1634034271,114}
},
{
    name = "𓊆 ★ᯓ شجره مجذبة ᯓ★ 𓊇",
    directValues = {1818318370,1769238117,1415538030,1634300015,31090,0}
},
{
    name = "𓊆 ★ᯓ قلب احمر ᯓ★ 𓊇",
    directValues = {1818318374,1769238117,1717527918,1702326124,1684365938,0}
},
{
    name = "𓊆 ★ᯓ زينة عيد الحب وحيد القرن ᯓ★ 𓊇",
    directValues = {1970040876,1851091059,1919902569,1635147630,1953391980,6647401}
},
{
    name = "𓊆 ★ᯓ قلب عيد الحب ᯓ★ 𓊇",
    directValues = {1634035750,1918137458,1985963365,1852140641,1701734772,0}
},
{
    name = "𓊆 ★ᯓ خروف مرسال الحب ᯓ★ 𓊇",
    directValues = {1818318374,1769238117,1885300078,1937011567,1885693288,0}
},
{
    name = "𓊆 ★ᯓ تمثال اللحن الغرامي عيد الحب ᯓ★ 𓊇",
    directValues = {1818318372,1769238117,1935631726,1852142181,6644833,0}
},
{
    name = "𓊆 ★ᯓ لحن غرامي لا نهايه له ᯓ★ 𓊇",
    directValues = {1987013650,2003784805,29285,0,0,0}
},
{
    name = "𓊆 ★ᯓ منطقة صور زوجين رائعين عيد الحب ᯓ★ 𓊇",
    directValues = {1869115432,1951625076,1600417377,1701601654,1852404846,101}
},
{
    name = "𓊆 ★ᯓ حمام عاشق ᯓ★ 𓊇",
    directValues = {1818318380,1769238117,1885300078,1868916585,1818194798,6649455}
},
{
    name = "𓊆 ★ᯓ طيار عاشف ᯓ★ 𓊇",
    directValues = {1987013650,1852397413,29543,0,0,0}
},
{
    name = "𓊆 ★ᯓ عربة نقل ᯓ★ 𓊇",
    directValues = {1818318378,1769238117,1818191214,1919252079,1633902451,29810}
},
{
    name = "𓊆 ★ᯓ مركبة حربية ᯓ★ 𓊇",
    directValues = {1836020250,1667198561,1769103720,29807,0,0}
},
{
    name = "𓊆 ★ᯓ قلب عيد الحب ᯓ★ 𓊇",
    directValues = {1818318380,1769238117,1751082350,1953653093,1632136777,7562350}
},
{
    name = "𓊆 ★ᯓ دب الفلانتين ᯓ★ 𓊇",
    directValues = {1818318378,1769238117,1415538030,2036622437,1634034271,12914}
},
{
    name = "𓊆 ★ᯓ قلوب طائرة ᯓ★ 𓊇",
    directValues = {2037147176,1701601622,1852404846,1818313317,1852796780,115}
},
{
    name = "𓊆 ★ᯓ المتزوجون ᯓ★ 𓊇",
    directValues = {1818318378,1769238117,1784636782,1299477365,1769108065,25701}
}, 
{
    name = "𓊆 ★ᯓ كيوبيد عين النسر ᯓ★ 𓊇",
    directValues = {2037147170,1701601622,1852404846,1886733157,25705,0}
},
{
    name = "𓊆 ★ᯓ نفق الغرام ᯓ★ 𓊇",
    directValues = {1987005460,1853183077,7103854,0,0,0}
},
{
    name = "𓊆 ★ᯓ قوس الحب ᯓ★ 𓊇",
    directValues = {1818318372,1769238117,1818191214,1634039407,6841202,0}
},
{
    name = "𓊆 ★ᯓ سياج عيد الحب ᯓ★ 𓊇",
    directValues = {1935754520,1601332596,1668179302,101,33,0}
},
{
    name = "𓊆 ★ᯓ ارجوحة عيد الفصح ᯓ★ 𓊇",
    directValues = {1935762714,1215456628,1869442401,27491,0,0}
},
{
    name = "𓊆 ★ᯓ ورشة عمل عيد الفصح ᯓ★ 𓊇",
    directValues = {1935762716,1601332596,1952670054,7959151,0,0}
},
{
    name = "𓊆 ★ᯓ متاهة عيد الفصح ᯓ★ 𓊇",
    directValues = {1650551840,1852404345,1700751476,1702130529,114,0,0}
},
{
    name = "𓊆 ★ᯓ متعة عيد الفصح ᯓ★ 𓊇",
    directValues = {1935762720,1752327540,1702065519,1701999711,-57540507,121}
},
{
    name = "𓊆 ★ᯓ سياج مرجاني ᯓ★ 𓊇",
    directValues = {1819558172,1769238113,1701207923,6644590,0,0}
},
{
    name = "𓊆 ★ᯓ مدرسة السحر ᯓ★ 𓊇",
    directValues = {1818314788,1702326124,808611429,1698969393,7499619,0}
},
{
    name = "𓊆 ★ᯓ فزاعة ᯓ★ 𓊇",
    directValues = {1667591448,1920226152,1634563937,110,0,0}
},
{
    name = "𓊆 ★ᯓ محطة قطبيه ᯓ★ 𓊇",
    directValues = {1634034214,1601795189,1634496368,1635013490,1852795252,0}
},
{
    name = "𓊆 ★ᯓ متجر ورق البردي ᯓ★ 𓊇",
    directValues = {1634886444,1836282982,1868000865,1852402546,1734696807,7630969}
},
{
    name = "𓊆 ★ᯓ تمثال بوسيدون ᯓ★ 𓊇",
    directValues = {1634034206,1601795189,1702063984,1852793961,0,0}
},
{
    name = "𓊆 ★ᯓ مباراة الشطرنج ᯓ★ 𓊇",
    directValues = {1701339928,1633645427,1768055154,99,0,0}
},
{
    name = "𓊆 ★ᯓ الواحة ᯓ★ 𓊇",
    directValues = {1634885912,1600350562,1769169263,115,0,0}
},
{
    name = "𓊆 ★ᯓ مستكشفو الاعماق ᯓ★ 𓊇",
    directValues = {1634034220,1601795189,1600218483,1702061426,1751347809,7565925}
},
{
    name = "𓊆 ★ᯓ تمثال الفرعون ᯓ★ 𓊇",
    directValues = {2036811044,1750103152,1868657249,1635013480,6649204,0}
},
{
    name = "𓊆 ★ᯓ رامي القرص ᯓ★ 𓊇",
    directValues = {1936286762,1416852835,2003792488,1633645157,1701405550,29806}
},
{
    name = "𓊆 ★ᯓ راية الطبخ الرائعه ᯓ★ 𓊇",
    directValues = {1701860136,1818323299,1969317186,1113553268,1701736033,114}
},
{
    name = "𓊆 ★ᯓ مصعد التزلج ᯓ★ 𓊇",
    directValues = {1634034220,1601795189,1852732786,1667199589,1701601889,7496035}
},
{
    name = "𓊆 ★ᯓ غرفة الرعب ᯓ★ 𓊇",
    directValues = {1818322976,1702326124,1834970725,1969582965,109,0}
},
{
    name = "𓊆 ★ᯓ رقم ثلاثة ᯓ★ 𓊇",
    directValues = {1634034206,1601795189,1633836851,1852796012,0,0}
},
{
    name = "𓊆 ★ᯓ منزل طائر ᯓ★ 𓊇",
    directValues = {1634034206,1601795189,1215917158,1702065519,0,0}
},
{
    name = "𓊆 ★ᯓ كلب قابل للنفخ ᯓ★ 𓊇",
    directValues = {1634034210,1601795189,1600614244,1819042146,28271,0}
},
{
    name = "𓊆 ★ᯓ شجرة قابله للنفخ ᯓ★ 𓊇",
    directValues = {1634034212,1601795189,1701147252,1818321503,7237484,0}
},
{
    name = "𓊆 ★ᯓ قوس بالون ᯓ★ 𓊇",
    directValues = {1634034214,1601795189,1751347809,1818321503,1852796780,0}
},
{
    name = "𓊆 ★ᯓ عنكبوت الي ᯓ★ 𓊇",
    directValues = {1701860140,1818323299,1969317186,1885305204,1869313377,6582120}
},
{
    name = "𓊆 ★ᯓ طائرة ᯓ★ 𓊇",
    directValues = {1701860138,1818323299,1969317186,1650424180,1819307881,28257}
},
{
    name = "𓊆 ★ᯓ طاحونة الشوكولاته ᯓ★ 𓊇",
    directValues = {1869103914,1634496355,1632003444,1919906915,1667581049,29295}
},
{
    name = "𓊆 ★ᯓ خنزير قابل للنفخ ᯓ★ 𓊇",
    directValues = {1701860136,1818323299,1969317186,1717533044,1766881644,103}
},
{
    name = "𓊆 ★ᯓ خروف قابل للنفخ ᯓ★ 𓊇",
    directValues = {1701860140,1818323299,1969317186,1717533044,1750301036,7365989}
},
{
    name = "𓊆 ★ᯓ نافورة جامدة ᯓ★ 𓊇",
    directValues = {1634034220,1601795189,1836674127,1180920176,1953396079,7235937}
},
{
    name = "𓊆 ★ᯓ المفتاح الى القلب ᯓ★ 𓊇",
    directValues = {1818318362,1769238117,1801413998,31077,0,0}
},
{
    name = "𓊆 ★ᯓ معسكر القراصنة ᯓ★ 𓊇",
    directValues = {1634034216,1601795189,1953653104,1768972153,1702125938,115}
}, 
{
    name = "𓊆 ★ᯓ افيال سعيدة ᯓ★ 𓊇",
    directValues = {1634034208,1601795189,1885695077,1953390952,115,0}
},
{
    name = "𓊆 ★ᯓ عيد الربيع ᯓ★ 𓊇",
    directValues = {1935762714,1383228788,1868718697,29550,0,0}
},
{
    name = "𓊆 ★ᯓ لعبة ركوب القارب ᯓ★ 𓊇",
    directValues = {1935762710,1601332596,1684959088,0,0,0}
},
{
    name = "𓊆 ★ᯓ نفق الغرام ᯓ★ 𓊇",
    directValues = {1987005460,1853183077,7103854,0,0,0}
},
{
    name = "𓊆 ★ᯓ مشتـل ازهار ᯓ★ 𓊇",
    directValues = {1818318374,1769238117,1180657006,1702326124,1684365938,0}
},
{
    name = "𓊆 ★ᯓ سياج عيد الفصح ᯓ★ 𓊇",
    directValues = {1935754520,1601332596,1668179302,101,0,0}
},
{
    name = "𓊆 ★ᯓ بيت الارنب ᯓ★ 𓊇",
    directValues = {1935754518,1400006004,1886221684,0,0,0}
},
{
    name = "𓊆 ★ᯓ قفلا الغرام ᯓ★ 𓊇",
    directValues = {1987005456,1668238437,107,0,0,0}
},
{
    name = "𓊆 ★ᯓ مزرعة العنب ᯓ★ 𓊇",
    directValues = {1935754524,1450337652,2036690537,6582881,0,0}
},
{
    name = "𓊆 ★ᯓ متجر الساحرة ᯓ★ 𓊇",
    directValues = {1634488340,1398762350,7368552,0,0,0}
},
{
    name = "𓊆 ★ᯓ منزل طائر ᯓ★ 𓊇",
    directValues = {1634034206,1601795189,1215917158,1702065519,1634034206,1601795189}
},
{
    name = "𓊆 ★ᯓ سكة حديد عيد الفصح ᯓ★ 𓊇",
    directValues = {1935762716,1383228788,1919707489,6578543,0,0}
},
{
    name = "𓊆 ★ᯓ بحيرة زهور الزنبق الحمراء ᯓ★ 𓊇",
    directValues = {1684369946,1768712524,1867543397,25710,0,0}
},
{
    name = "𓊆 ★ᯓ العرش القديم ᯓ★ 𓊇",
    directValues = {1919448102,1214606959,1600941153,1768187245,1818326629,0}
},
{
    name = "𓊆 ★ᯓ معرض الازياء ᯓ★ 𓊇",
    directValues = {1935754784,1852795240,1970225759,1970366836,101,1935754784}
},
{
    name = "𓊆 ★ᯓ بستان التفاح ᯓ★ 𓊇",
    directValues = {1886404888,1197434220,1701081697,110,1886404888,1197434220}
},
{
    name = "𓊆 ★ᯓ السوق المتنقل ᯓ★ 𓊇",
    directValues = {1651461402,1600482409,1802658125,29797,1651461402,1600482409}
},
{
    name = "𓊆 ★ᯓ زينة ᯓ★ 𓊇",
    directValues = {1667580956,1381986927,1885696111,7041633,1667580956,1381986927}
},
{
    name = "𓊆 ★ᯓ حوض اسماك سعيده ᯓ★ 𓊇",
    directValues = {1885423644,1096776048,1918989681,7173481,1885423644,1096776048}
},
{
    name = "𓊆 ★ᯓ سياج مرجاني ᯓ★ 𓊇",
    directValues = {1819558172,1769238113,1701207923,6644590,0,0}
},
{
    name = "𓊆 ★ᯓ مقهى المكوك ᯓ★ 𓊇",
    directValues = {1634034216,1601795189,1667330163,1752391525,1819571317,101}
},
{
    name = "𓊆 ★ᯓ حصان طروادة ᯓ★ 𓊇",
    directValues = {1869771814,1215193450,1702064751,1668178271,1953391977,0}
},
{
    name = "𓊆 ★ᯓ منطقة تخفيضات ᯓ★ 𓊇",
    directValues = {1818317588,1970361189,6648417,0,0,0}
},
{
    name = "𓊆 ★ᯓ جذع عيش الغراب ᯓ★ 𓊇",
    directValues = {1634034214,1601795189,1953718629,1935635045,1886221684,0}
},
{
    name = "𓊆 ★ᯓ منزل الازقام ᯓ★ 𓊇",
    directValues = {1634034208,1601795189,1600547941,1937076072,101,0}
},
{
    name = "𓊆 ★ᯓ حديقة مائيه قطبية ᯓ★ 𓊇",
    directValues = {1634034220,1601795189,1650811753,1600615013,1735288176,7235957}
},
{
    name = "𓊆 ★ᯓ سوق رصيف الصيد ᯓ★ 𓊇",
    directValues = {1634034212,1601795189,1752394086,1918987615,7628139,0}
}, 
{ name = "𓊆 ★ᯓ شجرة الوردية ᯓ★ 𓊇", directValues = {1634034214,1601795189,1685022834,1852138607,1852797540,0} },
{ name = "𓊆 ★ᯓ شجرة نبات الوستريا ᯓ★ 𓊇", directValues = {1634034206,1601795189,1953720695,1634300517,0,0} },
{ name = "𓊆 ★ᯓ شجرة البونسيانا ᯓ★ 𓊇", directValues = {1634034204,1601795189,1869374820,7891310,0,0} },
{ name = "𓊆 ★ᯓ شجرة الأرجواني ᯓ★ 𓊇", directValues = {1634034208,1601795189,1734439521,1701732725,121,0} },
{ name = "𓊆 ★ᯓ نخيل البلح ᯓ★ 𓊇", directValues = {1634034210,1601795189,1768843622,1634754403,28012,0} },
{ name = "𓊆 ★ᯓ شجرة الصنوبر الياباني ᯓ★ 𓊇", directValues = {1634034208,1601795189,1701734768,1701999711,101,0} },
{ name = "𓊆 ★ᯓ شجرة السكويت ᯓ★ 𓊇", directValues = {1634034204,1601795189,1970365811,6383983} },
{ name = "𓊆 ★ᯓ الجاكاراندا ᯓ★ 𓊇", directValues = {1801546258,1851880033,536895844,-1946621927,-289063440,110} }, 
{ name = "𓊆 ★ᯓ مصمم الطائرات الأول ᯓ★ 𓊇", directValues = {1635021594,1600484724,1652124774,1140881775,5,115} },
{ name = "𓊆 ★ᯓ العالم الأول ᯓ★ 𓊇", directValues = {1635021604,1600484724,1851876718,1953654116,7102824,0} },
{ name = "𓊆 ★ᯓ لاعب كرة القدم الأول ᯓ★ 𓊇", directValues = {1635021602,1600484724,1953460070,1819042146,29285,0} },
{ name = "𓊆 ★ᯓ عالم الوراثة الأول ᯓ★ 𓊇", directValues = {1635021602,1600484724,1701733735,1768122740,989885555,115} },
{ name = "𓊆 ★ᯓ السائح الأول ᯓ★ 𓊇", directValues = {1635021596,1600484724,1920298868,7631721,5,115} },
{ name = "𓊆 ★ᯓ الكيميائي الأول ᯓ★ 𓊇", directValues = {1635021596,1600484724,1835362403,7631721,27756,0} },
{ name = "𓊆 ★ᯓ الشرطي الأول ᯓ★ 𓊇", directValues = {1635021600,1600484724,1768714096,1634559331,7077998,0} },
{ name = "𓊆 ★ᯓ الموسيقي الأول ᯓ★ 𓊇", directValues = {1635021596,1600484724,1769174381,7233891,5,115} },
{ name = "𓊆 ★ᯓ رجل إطفاء الحرائق الأول ᯓ★ 𓊇", directValues = {1635021596,1600484724,1701996902,7233901,27756,0} },
{ name = "𓊆 ★ᯓ الرسام الأول ᯓ★ 𓊇", directValues = {1635021594,1600484724,1769239137,1761637491,27756,0} },
{ name = "𓊆 ★ᯓ القائد الأول ᯓ★ 𓊇", directValues = {1635021596,1600484724,1701733735,7102834,29285,0} 
}
}

-- الهيلو
local buildData = {
    {
name = "𓊆 ★ᯓ مهبط هيلو مزلقة سانتا ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1701598047,
        6842217, 112
    }
}, 
{
    name = "𓊆 ★ᯓ هيلو مزلقة سانتا ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1601332596, 1768254547, 842688615
    }
},
{
    name = "𓊆 ★ᯓ مهبط هيلو عيد الفصح ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1935762783,
        846357876, 3420720
    }
},
{
    name = "𓊆 ★ᯓ هيلو عيد الفصح ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1601332596, 1953718629, 808612453,
        1409299506
    }
},
{
        name = "𓊆 ★ᯓ مهبط الهيلو النباتي ᯓ★ 𓊇",
    value24 = 28,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1918978143,
        1953719670, 603545600
    }
},
{
    name = "𓊆 ★ᯓ هيلو الباذنجان ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1601332596, 1987207496, 7631717
    }
},
{
    name = "𓊆 ★ᯓ مهبط محطة رسو السفن ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1651462751,
        1845523567, 112
    }
},
{
    name = "𓊆 ★ᯓ هيلو إلى الموصل ᯓ★ 𓊇",
    directValues = {1768641322,1699241838,1868786028,1919251568,1651462751,29807}
},

{
    name = "𓊆 ★ᯓ مهبط هيلو قصر السلطان ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1634877791,
        6515042
    }
},
{
name = "𓊆 ★ᯓ هيلو البساط الطائر ᯓ★ 𓊇",
    directValues = {1768641324,1699241838,1868786028,1919251568,1634877791,6515042}
},
{
    name = "𓊆 ★ᯓ مهبط طائرة هيلو خمس نجوم ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1936020063,
        7631471, 0
    }
},
{
    name = "𓊆 ★ᯓ طائرة هيلو على شكل أريكة ᯓ★ 𓊇",
    directValues = {1768641324,1699241838,1868786028,1919251568,1936020063,7631471}
},

{
    name = "𓊆 ★ᯓ مهبط هيلو ميناء المتجولين ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1634882655,
        7103862, 0
    }
},

{
    name = "𓊆 ★ᯓ هيلو السفينة الطائرة ᯓ★ 𓊇",
    directValues = {1768641324,1699241838,1868786028,1919251568,1634882655,7103862}
},

{
name = "𓊆 ★ᯓ مهبط هيلو البرج المسكون ᯓ★ 𓊇",
    value24 = 34,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1818323039,
        1702326124, 808611429, 13106
    }
},
{
    name = "𓊆 ★ᯓ هيلو المرجل الطائر ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1601332596, 1819042152, 1701148527,
        842019438, 1701118003
    }
},
{
    name = "𓊆 ★ᯓ مهبط منصة الكرينفال ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1634886239,
        7104890
    }
},
{
    name = "𓊆 ★ᯓ هيلو ريشية ᯓ★ 𓊇",
    directValues = {1768641324,1699241838,1868786028,1919251568,1634886239,7104890}
},
{
    name = "𓊆 ★ᯓ مهبط رياضي ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1869632351,
        1946186866, 3369059
    }
},
{
    name = "𓊆 ★ᯓ هليكوبتر دراجة ᯓ★ 𓊇",
    directValues = {1768641322,1699241838,1868786028,1919251568,1869632351,29810}
},
{
    name = "𓊆 ★ᯓ مهبط القصر الملكي ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1852400479,
        1701995876, 6384748
    }
},
{
    name = "𓊆 ★ᯓ هيلو طائرة قرع جرس العسل ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1601332596, 1684957539, 1818587749,
        1862295916, 1763851629
    }
},

{
    name = "𓊆 ★ᯓ مهبط هيلو الديسكو ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1936286815,
        28515, 0
    }
},
{
    name = "𓊆 ★ᯓ هيلو الديسكو ᯓ★ 𓊇",
    directValues = {1768641322,1699241838,1868786028,1919251568,1936286815,28515}
}, 
{
    name = "𓊆 ★ᯓ مهبط هيلو الفضاء ᯓ★ 𓊇", 
    value24 = 29,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1918987615,
        842019443, 53
    }
},
{
    name = "𓊆 ★ᯓ هيلو طائرة الفضاء ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1601332596, 1936875885, 892481586
    }
},
{
    name = "𓊆 ★ᯓ مهبط طائرة هيلو الرقص ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1349674356, 1701011820, 1935764831,
        1919251825, 6644833
    }
},
{
    name = "𓊆 ★ᯓ هيلو طائرة الرقص ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {
        1852402515, 1818576991, 1886348137,
        1601332596, 1903386989, 1634887029,
        1845519716, 1029989733
    }
},
}

-- المطار
local helloData = {

{
    name = "𓊆 ★ᯓ طائرة عربية ᯓ★ 𓊇",
    directValues = {1768641316,1765891950,1634496626,1633641838;6447474,0}
},
{
    name = "𓊆 ★ᯓ مطار عربي ᯓ★ 𓊇",
    directValues = {1768641314,1765891950,1919905906,1918984052,25185,0}
},
{
    name = "𓊆 ★ᯓ قاعدة سرية ᯓ★ 𓊇",
    directValues = {1768641312,1765891950,1919905906,1886609268,121,0}
},
{
    name ="𓊆 ★ᯓ طائرة شبح ᯓ★ 𓊇",
    directValues = {1768641314,1765891950,1634496626,1935631726,31088,0}
},
{
    name ="𓊆 ★ᯓ طائرة روك ᯓ★ 𓊇",
    directValues = {1768641316,1765891950,1634496626,1918854510,7037807,0}
},
{
    name = "𓊆 ★ᯓ مطار روك ᯓ★ 𓊇",
    directValues = {1768641314,1765891950,1919905906,1869766516,27491,0}
},
{
    name = "𓊆 ★ᯓ طائرة النجوم ᯓ★ 𓊇",
    directValues = {1768641318,1765891950,1634496626,1834968430,1701410415,0}
},
{
    name = "𓊆 ★ᯓ مطار سينمائي ᯓ★ 𓊇",
    directValues = {1768641316,1765891950,1919905906,1869438836,6646134,0}
},
{
    name ="𓊆 ★ᯓ طائرة الحلوى ᯓ★ 𓊇",
    directValues = {1768641318,1765891950,1634496626,1935631726,1952802167,0}
},
{
    name = "𓊆 ★ᯓ مطار الحلوى ᯓ★ 𓊇",
    directValues = {1768641316, 1765891950,1919905906,2004049780,7628133,0}
},
{
    name = "𓊆 ★ᯓ تنين خارق 🐉 ᯓ★ 𓊇", 
    directValues = {1768641318,1765891950,1634496626,1398760814,842676048,0}
},
{
    name = "𓊆 ★ᯓ مطار المهرجان ᯓ★ 𓊇",
    directValues = {1768641312,1765891950,1919905906,1347641204,55,0}
},
{
    name = "𓊆 ★ᯓ طائرة الربيع ᯓ★ 𓊇",
    directValues = {1768641322,1765891950,1634496626,1767859566,1634493810,25710}
},
{
    name = "𓊆 ★ᯓ مطار الربيع ᯓ★ 𓊇",
    directValues = {1768641320,1765891950,1919905906,1919508340,1851878501,100}
},
{
    name = "𓊆 ★ᯓ مركبة اطلاق فضائية ᯓ★ 𓊇",
    directValues = {1768641318,1765891950,1634496626,1935631726,1701011824,0}
},
{
    name ="𓊆 ★ᯓ ميناء فضائي ᯓ★ 𓊇",
    directValues = {1768641316,1765891950,1919905906,1886609268,6644577,0}
},
{
    name = "𓊆 ★ᯓ طائرة فائقة ᯓ★ 𓊇",
    directValues = {1768641314,1765891950,1634496626,1398760814,13136,0}
},
{
    name = "𓊆 ★ᯓ مطار البوابة الجوية ᯓ★ 𓊇",
    directValues = {1768641312,1765891950,1919905906,1347641204,51,0}
},
    {
        name = "𓊆 ★ᯓ طائرة الموضه ᯓ★ 𓊇",
        directValues = {1768641322, 1765891950, 1634496626, 1717527918, 1768452961, 28271}
    },
    {
        name ="𓊆 ★ᯓ مطار الموضه ᯓ★ 𓊇", 
        directValues = {1768641320, 1765891950, 1919905906, 1634099060, 1869178995, 110}
    }
}, 



{
    name = "𓊆 ★ᯓ طائرة استوائية ᯓ★ 𓊇",
    directValues = {1768641314,1765891950,1634496626,1398760814,14672,0}
},
{
    name = "𓊆 ★ᯓ مطار استوائي ᯓ★ 𓊇",
    directValues = {1768641312,1765891950,1919905906,1347641204,57,0}
},

{
    name = "ᯓ★ 𓊆 طائرة السيمفونية 𓊇 ★ᯓ",
    value24 = 26,
    pointerValues = {
        1852402515, 1919500639, 1851878512,
        1818451813, 1769173857, 1937075555,
        25449
    }
},
{
    name = "ᯓ★ 𓊆 مطار السيمفونية 𓊇 ★ᯓ", 
    value24 = 25,
    pointerValues = {
        1852402515, 1919500639, 1953656688,
        1634493279, 1667855219, 1769174381,
        1881145443, 1030255713
    }
},
{
    name = "ᯓ★ 𓊆 طائرة الأعياد 𓊇 ★ᯓ",
    value24 = 27,
    pointerValues = {
        1852402515, 1919500639, 1851878512,
        1751342949, 1953720690, 846422381,
        3289648, 1769239141
    }
},
{
    name = "ᯓ★ 𓊆 مسكن سانتا 𓊇 ★ᯓ",
    value24 = 26,
    pointerValues = {
        1852402515, 1919500639, 1953656688,
        1919443807, 1836348265, 808612705,
        889205298, 151666210
    }
},
{
    name ="ᯓ★ 𓊆 طائرة مائية 𓊇 ★ᯓ",
    value24 = 26,
    pointerValues = {
        1852402515, 1919500639, 1851878512,
        1818320741, 1668180332, 1769174380,
        1912628598, 1953391971
    }
},
{
    name = "ᯓ★ 𓊆 مطار خمسة نجوم 𓊇 ★ᯓ",
    value24 = 25,
    pointerValues = {
        1852402515, 1919500639, 1953656688,
        1819042143, 1818455657, 1986622325,
        1399521381, 1951626341
    }
},
{
    name = "ᯓ★ 𓊆 طائرة على شكل طائر 𓊇 ★ᯓ",
    value24 = 24,
    pointerValues = {
        1852402515, 1919500639, 1851878512,
        1634033509, 1919251571, 858927154,
        1766662656, 1632069998
    }
},
{
    name = "ᯓ★ 𓊆 مطار الفصح 𓊇 ★ᯓ",
    value24 = 23,
    pointerValues = {
        1852402515, 1919500639, 1953656688,
        1935762783, 846357876, 3355184,
        808464674, 1043275776
    }
},
{
    name =    "ᯓ★ 𓊆 طائرة الأشباح 𓊇 ★ᯓ",
    value24 = 29,
    pointerValues = {
        1852402515, 1919500639, 1851878512,
        1634230117, 2003790956, 846095717,
        976302640, 1767309362
    }
},
{
    name =     "ᯓ★ 𓊆 محطة الأشباح 𓊇 ★ᯓ",
    value24 = 26,
    pointerValues = {
        1852402515, 1919500639, 1953656688,
        1818323039, 1702326124, 808611429,
        1006645554, 1768189545
    }
},
{
    name =     "ᯓ★ 𓊆 طائرة مصاص الدماء 𓊇 ★ᯓ",
    value24 = 27,
    pointerValues = {
        1852402515, 1919500639, 1851878512,
        1632132965, 2003790956, 846095717,
        3486256, 118
    }
},
{
    name = "ᯓ★ 𓊆 مطار دراكولا 𓊇 ★ᯓ",
    value24 = 26,
    pointerValues = {
        1852402515, 1919500639, 1953656688,
        1818314847, 1702326124, 808611429,
        1962947890, 942682222
    }

}

-- القطار
local airportData = {


-- محطة المريخ
{
    name = "𓊆 ★ᯓ محطة المريخ ᯓ★ 𓊇",
    directValues = {1768641324,1918132078,1399744865,1769234804,1834970735,7565921}
},
{
    name = "𓊆 ★ᯓ قطار مسبار المريخ ᯓ★ 𓊇",
    directValues = {1768641310,1918132078,1601071457,1936875885,0,0}
},

-- محطة الزهور
{
    name = "𓊆 ★ᯓ محطة الزهور ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1701207918,1986622579,536898657,1935758396}
},
{
    name = "𓊆 ★ᯓ قطار الزهور ᯓ★ 𓊇",
    directValues = {1768641318,1918132078,1601071457,1953719654,1818326633,0}
},

-- محطة اسطورة
{
    name = "𓊆 ★ᯓ محطة اسطورة ᯓ★ 𓊇",
    value24 = 28,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1701338990,1935764588,892481586,574450688}
},
{
    name = "𓊆 ★ᯓ القطار الاسطوري ᯓ★ 𓊇",
    directValues = {1768641322,1918132078,1601071457,1819043176,808612705,13618}
},

-- محطة المسرحية
{
    name = "𓊆 ★ᯓ محطة المسرحية ᯓ★ 𓊇",
    value24 = 28,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1752457070,1920229733,1818321769,1717924864}
},
{
    name = "𓊆 ★ᯓ قطار مسرحي سريع ᯓ★ 𓊇",
    directValues = {1768641322,1918132078,1601071457,1634035828,1667854964,27745}
},

-- مستوطنة قديمة
{
    name = "𓊆 ★ᯓ مستوطنة قديمة ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1919967086,1936287845,1769107316,21168227}
},
{
    name = "𓊆 ★ᯓ قطار بدائي سريع ᯓ★ 𓊇",
    directValues = {1768641324,1918132078,1601071457,1751478896,1869902697,6515058}
},

-- محطة عيد الفصح
{
    name = "𓊆 ★ᯓ محطة عيد الفصح ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1634033518,1919251571}
},
{
    name = "𓊆 ★ᯓ قطار عيد الفصح السريع ᯓ★ 𓊇",
    directValues = {1768641314,1918132078,1601071457,1953718629,29285,0}
},

-- مركز التسجيل
{
    name = "𓊆 ★ᯓ مركز التسجيل ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1869766510,1919839075,7105647}
},
{
    name = "𓊆 ★ᯓ قطار الموسيقى السريع ᯓ★ 𓊇",
    directValues = {1768641320,1918132078,1601071457,1801678706,1819243118,108}
},

-- محطة عيد ميلاد
{
    name = "𓊆 ★ᯓ محطة عيد ميلاد ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1751342958,1953720690,846422381,3420720}
},
{
    name = "𓊆 ★ᯓ قطار عيد ميلاد ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1634882655,1667198569,1936290408,1935764852,875704370}
},

-- محطة معسكر التدريب
{
    name = "𓊆 ★ᯓ محطة معسكر التدريب ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1869766510,1215195490,6582127,116}
},
{
    name = "𓊆 ★ᯓ العربة الخشبية ᯓ★ 𓊇",
    directValues = {1768641320,1918132078,1601071457,1768058738,1869564014,100}
},

-- محطة الكريسماس
{
    name = "𓊆 ★ᯓ محطة الكريسماس ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1751342958,1953720690,7561581}
},
{
    name = "𓊆 ★ᯓ قطار الكريسماس ᯓ★ 𓊇",
    directValues = {1768641320,1918132078,1601071457,1769105507,1634563187,115}
},

-- محطة غاتسبي
{
    name = "𓊆 ★ᯓ محطة غاتسبي ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1632067438,2036495220,169648128,118}
},
{
    name = "𓊆 ★ᯓ قطار غاتسبي ᯓ★ 𓊇",
    directValues = {1768641314,1918132078,1601071457,1937006919,31074,0}
},

-- محطة القلعة
{
    name = "𓊆 ★ᯓ محطة القلعة ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1852530542,1952999273}
},
{
    name = "𓊆 ★ᯓ قطار الفرسان ᯓ★ 𓊇",
    directValues = {1768641314,1918132078,1601071457,1734962795,29800,0}
},

-- محطة صينية
{
    name = "𓊆 ★ᯓ محطة صينية ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1970036590,1316118894,842019417,50}
},
{
    name = "𓊆 ★ᯓ قطار التنانين ᯓ★ 𓊇",
    directValues = {1768641324,1918132078,1601071457,1634628972,844713586,3289648}
},

-- محطة رعاة البقر
{
    name = "𓊆 ★ᯓ محطة رعاة البقر ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1702322030,1919251571,127533166,116}
},
{
    name = "𓊆 ★ᯓ قطار رعاة البقر ᯓ★ 𓊇",
    directValues = {1768641316,1918132078,1601071457,1953719671,7238245,0}
},

-- محطة الهالوين
{
    name = "𓊆 ★ᯓ محطة الهالوين ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {1852402515,1634882655,1951624809,1869182049,1634230126,2003790956,846095717,3420720}
},
{
    name = "𓊆 ★ᯓ قطار الهالوين ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1634882655,1751084649,1869376609,1852138871,875704370,1898935040,1836592710}
}



}

-- الميناء
local planeData = {

{
    name = "𓊆 ★ᯓ سفينة الاشباخ ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402515,1768444767,1634230128,2003790956,846095717,3289648,812545280,3223856}
},
{
    name = "𓊆 ★ᯓ ميناء الأهوال  ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402515,1918978143, 1601335138,1819042152,1701148527,842019438,807534642,1987272502}
},
{
name = "𓊆 ★ᯓ باخرة نهريه ᯓ★ 𓊇",
    directValues = {1768641324,1750294382;2002743401,2003070057,846492517,3420720}
},
{
    name = "𓊆 ★ᯓ ميناء الماء على الصالون ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {1852402515, 1918978143,1601335138,1684826487,1953719671,875704370,1151287040,117}
},

{
name = "𓊆 ★ᯓ قارب الحلوى ᯓ★ 𓊇",
    directValues = {1768641324,1750294382,1650421865,1752461929,846815588,3420720}
},
{
    name = "𓊆 ★ᯓ ميناء الحلوى ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {
1852402515,1918978143;1601335138,1953655138,2036425832,875704370}
},
{
    name = "𓊆 ★ᯓ قارب الحب ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402515, 1768444767,1635147632,1953391980,1936027241,7954756}
},
{
    name = "𓊆 ★ᯓ ميناء الرومنسية ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402515, 1918978143,1601335138,1701601654,1852404846,1631875941,121}
},
 {
    name = "𓊆 ★ᯓ سفينة العطلة ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402515,1768444767,1818320752,1668180332,1769174380,808609142,1694512434,151666291}
},
{
    name = "𓊆 ★ᯓ ميناء العطلة ᯓ★ 𓊇",
    value24 = 28,
    pointerValues = {1852402515,1918978143,1601335138,1768713313,1970037614,1702259059,892481586}
},
{
    name = "𓊆 ★ᯓ قارب الهدايا ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402515,1768444767,1751342960,1953720690,846422381,3355184,862875497,1702249777}
},
{
    name = "𓊆 ★ᯓ ميناء الكريسماس ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402515,1918978143,1601335138,1769105507,1634563187,842019443,1734934579,570455144}
},
    {
    name = "𓊆 ★ᯓ قارب التنين ᯓ★ 𓊇",
    directValues = {1768641306,1750294382,1130328169,22862,0,0}
},
{
    name = "𓊆 ★ᯓ ميناء الفوانيس ᯓ★ 𓊇",
    directValues = {1768641310,1632132974,1919902322,1498301279,0,0}
},
{
    name = "𓊆 ★ᯓ سفينة قوية ᯓ★ 𓊇",
    directValues = {1768641318,1750294382,1851748457,1768190575,1685014371,0}
},
{
    name = "𓊆 ★ᯓ ميناء الفايكنج ᯓ★ 𓊇",
    directValues = {1768641322,1632132974,1919902322,1919905375,1197697380,25711}
},
{
    name = "𓊆 ★ᯓ سفينة القطب الشمالي ᯓ★ 𓊇",
    directValues = {1768641312,1750294382,1633644649,1769235314,99,0}
},
{
    name = "𓊆 ★ᯓ ميناء القطب الشمالي ᯓ★ 𓊇",
    directValues = {1768641316,1632132974,1919902322,1668440415,6515060,0}
},
{
    name = "𓊆 ★ᯓ جندول ᯓ★ 𓊇",
    directValues = {1768641312,1750294382,1985966185,1667853925,101,0}
},
{
    name = "𓊆 ★ᯓ رصيف اللورد ᯓ★ 𓊇",
    directValues = {1768641316,1632132974,1919902322,1852143199,6644585,0}
},
{
    name = "𓊆 ★ᯓ سفينة سياحية ᯓ★ 𓊇",
    directValues = {1768641312,1750294382,1784639593,1818717813,101,1768641312}
},
{
    name = "𓊆 ★ᯓ ميناء الغابة ᯓ★ 𓊇",
    directValues = {1768641316,1632132974,1919902322,1853188703,6646887,1768641316}
},
{
    name = "𓊆 ★ᯓ عبارة كرواسون ᯓ★ 𓊇",
    directValues = {1768641310,1750294382,1885302889,1936290401,0,0}
},
{
    name = "𓊆 ★ᯓ ميناء جميل ᯓ★ 𓊇",
    directValues = {1768641314,1632132974,1919902322,1918988383,29545,0}
},
{
    name = "𓊆 ★ᯓ سفينة يونانية ᯓ★ 𓊇",
    directValues = {1768641312,1750294382,1751085161,1634495589,115,0}
},
{
    name = "𓊆 ★ᯓ ميناء قديم ᯓ★ 𓊇",
    directValues = {1768641316,1632132974,1919902322,1818585183,7561580,0}
},
{
    name = "𓊆 ★ᯓ السفينة ذات الطابع المصري ᯓ★ 𓊇",
    directValues = {1768641310,1750294382,1700753513,1953528167,0,0}
},
{
    name = "𓊆 ★ᯓ الميناء ذو الطابع المصري ᯓ★ 𓊇",
    directValues = {1768641314,1632132974,1919902322,2036819295,29808,0}
},
{
    name = "𓊆 ★ᯓ سفينه سياحية ᯓ★ 𓊇",
    directValues = {1768641306,1750294382,1398763625,14672,0,0}
},
{
    name = "𓊆 ★ᯓ ميناء استوائي ᯓ★ 𓊇",
    directValues = {1768641310,1632132974,1919902322,961565535,0,0}
},
{
    name = "𓊆 ★ᯓ السفينة اليابانية ᯓ★ 𓊇",
    directValues = {1768641310,1750294382,1784639593,1851879521,0,0}
},
{
    name = "𓊆 ★ᯓ الميناء الياباني ᯓ★ 𓊇",
    directValues = {1768641314,1632132974,1919902322,1885432415,28257,0}
},
{
    name = "𓊆 ★ᯓ سفينة الفارس ᯓ★ 𓊇",
    directValues = {1768641312,1750294382,1264545897,1751607662,116,0}
},
{
    name = "𓊆 ★ᯓ ميناء الفارس ᯓ★ 𓊇",
    directValues = {1768641316,1632132974,1919902322,1768835935,7628903,0}
},
{
    name = "𓊆 ★ᯓ سفينة القراصنة ᯓ★ 𓊇",
    directValues = {1768641306,1750294382,1398763625,12628,0,0}
},
{
    name = "𓊆 ★ᯓ ميناء القرصان ᯓ★ 𓊇",
    directValues = {1768641310,1632132974,1919902322,827609951,0,0}
} 
}
--الجزر
local bsData = {

    {
        name = "𓊆 ★ᯓ جزيرة الآزتك ᯓ★ 𓊇",
        directValues = {1768641320,1866882926,1701999730,1633645427,1667593338,115}
    },
    {
        name = "𓊆 ★ᯓ باريس صغيرة ᯓ★ 𓊇",
        directValues = {1768641318,1866882926,1701999730,1885303667,1936290401,0}
    },
    {
        name = "𓊆 ★ᯓ قرية عيد الفصح ᯓ★ 𓊇",
        directValues = {1768641320,1866882926,1701999730,1700754291,1702130529,114}
    },
    {
        name = "𓊆 ★ᯓ مسكن الجزيرة ᯓ★ ??",
        directValues = {1768641322,1866882926,1701999730,1197437811,1651733601,13177}
    },
    {
        name = "𓊆 ★ᯓ منزل الجزيرة ᯓ★ 𓊇",
        directValues = {1768641322,1866882926,1701999730,1197437811,1651733601,12665}
    },
    {
        name = "𓊆 ★ᯓ قصر الجزيرة ᯓ★ 𓊇",
        directValues = {1768641322,1866882926,1701999730,1197437811,1651733601,12921}
    },
    {
        name = "𓊆 ★ᯓ مركز القراصنة ᯓ★ 𓊇",
        directValues = {1768641322,1866882926,1701999730,1348432755,1952543337,12901}
    },
    {
        name = "𓊆 ★ᯓ كوخ القراصنة ᯓ★ 𓊇",
        directValues = {1768641322,1866882926,1701999730,1348432755,1952543337,12645}
    },
    {
        name = "𓊆 ★ᯓ حصن القراصنة ᯓ★ 𓊇",
        directValues = {1768641322,1866882926,1701999730,1348432755,1952543337,13157}
    }, 
   
    {
        name = "𓊆 ★ᯓ منزل الساحره ᯓ★ 𓊇",
            value24 = 29,
    pointerValues  = {1852402515,1919895135,1936028276,1632132979,2003790956,846095717,1597059632,49}
    },
    {
        name = "𓊆 ★ᯓ قصر الساحره ᯓ★ 𓊇",
            value24 = 29,
    pointerValues  = {1852402515,1919895135,1936028276,1632132979,2003790956,846095717,1597059632,50}
    },
    {
        name = "𓊆 ★ᯓ قلعه الساحره ᯓ★ 𓊇",
            value24 = 29,
    pointerValues  = {1852402515,1919895135,1936028276,1632132979,2003790956,846095717,1597059632,51}
    },
    {
        name = "𓊆 ★ᯓ جزيره الجليد ᯓ★ 𓊇",
            value24 = 23,
    pointerValues  = {1852402515,1919895135,1936028276,1749245811,1953720690,7561581,7804928}
    },
    {
        name = "𓊆 ★ᯓ جزيره الانسان البدائي ᯓ★ 𓊇",
            value24 = 25,
    pointerValues  = {1852402515,1919895135,1936028276,1919967091,1936287845,1769107316,382140515,116}
    },
{
    name = "𓊆 ★ᯓ جزيرة العطلات ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1852402515,1919895135,1936028276,1751342963,1953720690,1601397101,808464947}
} 

}
--الديكورات
local sbData = {
    {
        name = "𓊆 ★ᯓ أبطال الحديقة الساحرة ᯓ★ 𓊇",
        value24 = 26,
    pointerValues = {1701869637,1769236836,1698983535,1634889571,1852795252,1918988323,12660}
    },
    {
        name = "𓊆 ★ᯓ أبطال الحديقة الولد ᯓ★ 𓊇",
        value24 = 26,
    pointerValues = {1701869637,1769236836,1698983535,1634889571,1852795252,1918988323,12916}
    },
    {
        name = "𓊆 ★ᯓ أبطال الحديقة البنت ᯓ★ 𓊇",
        value24 = 27,
    pointerValues = {1701869637,1769236836,1698983535,1634889571,1852795252,1935761955,101,0}
    },
    {
        name = "𓊆 ★ᯓ ملكة جزيرة السلحفاه ᯓ★ 𓊇",
        value24 = 27,
    pointerValues = {1701869637,1769236836,1698983535,1634889571,1852795252,1634738994,3372146}
    },
    {
        name = "𓊆 ★ᯓ حارث الشمال ᯓ★ 𓊇",
        value24 = 27,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1634738995,3241074}
    },
    {
        name = "𓊆 ★ᯓ أوديسة القراصنة ᯓ★ 𓊇",
        value24 = 27,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1634738996,3241074}
    },
    {
        name = "𓊆 ★ᯓ ميجالوث الوحش الثلجي ᯓ★ 𓊇",
        value24 = 27,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1634738997,3241074}
    },
    {
        name = "𓊆 ★ᯓ منتجع فندقي أسرار كليوباترا ᯓ★ 𓊇",
        value24 = 27,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1634738998,3241074}
    },
    {
        name = "𓊆 ★ᯓ متنزه ترفيهي نباتي ᯓ★ 𓊇",
        value24 = 27,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1634738999,3241074}
    },
    {
        name = "𓊆 ★ᯓ متحف مملكة بوسيدون ᯓ★ 𓊇",
        value24 = 27,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1634739000,3241074}
    },
    {
        name = "𓊆 ★ᯓ مركز أبحاث الحالات الشاذة الطبيعية ᯓ★ 𓊇",
        value24 = 27,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1634739001,3241074}
    },
    -- قصر ذكي
    {
        name = "𓊆 ★ᯓ قصر ذكي ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881354289,829715041}
    },
    -- منزل الغزال الذهبي الريفي
    {
        name = "𓊆 ★ᯓ منزل الغزال الذهبي الريفي ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881354545,829715041,1818847232}
    },
    -- نافورة اللوتس المجمدة
    {
        name = "𓊆 ★ᯓ نافورة اللوتس المجمدة ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881354801,829715041,1818847232}
    },
    -- مسرح باندورا القديم
    {
        name = "𓊆 ★ᯓ مسرح باندورا القديم ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881355057,829715041}
    },
    -- صوبة ملكة الدبابير
    {
        name = "𓊆 ★ᯓ صوبة ملكة الدبابير ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881355313,829715041}
    },
    -- منشأة أبحاث فضائية
    {
        name = "𓊆 ★ᯓ منشأة أبحاث فضائية ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881355569,829715041}
    },
    -- مكتبة الشجرة
    {
        name = "𓊆 ★ᯓ مكتبة الشجرة ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881355825,829715041}
    },
    -- قاعدة التخييم وسط الطبيعة
    {
        name = "𓊆 ★ᯓ قاعدة التخييم وسط الطبيعة ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881356081,829715041}
    },
    -- مقهى كوني
    {
        name = "𓊆 ★ᯓ مقهى كوني ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881356337,829715041}
    },
    -- حديقة أرض القرود المائية
    {
        name = "𓊆 ★ᯓ حديقة أرض القرود المائية ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881356593,829715041}
    },
    -- ملاذ جبلي
    {
        name = "𓊆 ★ᯓ ملاذ جبلي ᯓ★ 𓊇",
        value24 = 28,
    pointerValues  = {1701869637,1769236836,1698983535,1634889571,1852795252,1881354290,829715041}
    },
    -- حديقة ترفيهية رائعة
    {
        name = "𓊆 ★ᯓ حديقة ترفيهية رائعة ᯓ★ 𓊇",
        value24 = 28,
    pointerValues = {1701869637,1769236836,1698983535,1634889571,1852795252,1881354546,829715041}
    }, 
    {
        name = "𓊆 ★ᯓ سنترال بارك ᯓ★ 𓊇",
        value24 = 23,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1634738993,3372146}
    },
    -- مركز المجتمع الصيني
    {
        name = "𓊆 ★ᯓ مركز المجتمع الصيني ᯓ★ 𓊇",
        value24 = 23,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1634738994,3372146}
    },
    -- حديقة بيئية بطابع قوس قزح
    {
        name = "𓊆 ★ᯓ حديقة بيئية بطابع قوس قزح ᯓ★ 𓊇",
        value24 = 23,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1634738995,3372146}
    },
    -- جولة الزواقة
    {
        name = "𓊆 ★ᯓ جولة الزواقة ᯓ★ 𓊇",
        value24 = 23,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1634738996,3372146}
    },
    -- المعرض الزراعي
    {
        name = "𓊆 ★ᯓ المعرض الزراعي ᯓ★ 𓊇",
        value24 = 23,
    pointerValues  = {1735550285,1698968165,1634889571,1852795252,1634738997,3306610}
    },
    -- مجمع رياضي
    {
        name = "𓊆 ★ᯓ مجمع رياضي ᯓ★ 𓊇",
        value24 = 23,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1634738998,3306610}
    },
    -- عالم البطاريق
    {
        name = "𓊆 ★ᯓ عالم البطاريق ᯓ★ 𓊇",
        value24 = 23,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1634738999,3306610}
    },
    -- صالة ديسكو كلاسيكية
    {
        name = "𓊆 ★ᯓ صالة ديسكو كلاسيكية ᯓ★ 𓊇",
        value24 = 23,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1634739000,3241074}
    },
    -- معرض الفنون والحرف اليدوية
    {
        name = "𓊆 ★ᯓ معرض الفنون والحرف اليدوية ᯓ★ 𓊇",
        value24 = 23,
    pointerValues  = {1735550285,1698968165,1634889571,1852795252,1634739001,3241074}
    },
    -- موقع مخيم مريح
    {
        name = "𓊆 ★ᯓ موقع مخيم مريح ᯓ★ 𓊇",
        value24 = 24,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1881354289,829715041}
    },
    -- حفل شاطئي
    {
        name = "𓊆 ★ᯓ حفل شاطئي ᯓ★ 𓊇",
        value24 = 24,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1881354545,829715041}
    },
    -- قلب إيطاليا
    {
        name = "𓊆 ★ᯓ قلب إيطاليا ᯓ★ 𓊇",
        value24 = 24,
    pointerValues   = {1735550285,1698968165,1634889571,1852795252,1881354801,829715041}
    }

}

--زيادة الديكورات
local basmalasaData = {
    {
        name = "𓊆 ★ᯓ أبطال الحديقة القديمة ᯓ★ 𓊇",
        directValues = {1886930216,1953064037,1148088169,1919902565,1869182049,110}
    },
    {
        name = "𓊆 ★ᯓ ملكة جزيرة السلحفاه ᯓ★ 𓊇",
        directValues = {1886930218,1953064037,1148088169,1919902565,1869182049,12910}
    },
    {
        name = "𓊆 ★ᯓ حارس الشمال ᯓ★ 𓊇",
        directValues = {1886930218,1953064037,1148088169,1919902565,1869182049,13166}
    },
    {
        name = "𓊆 ★ᯓ أوديسة القراصنة ᯓ★ 𓊇",
        directValues = {1886930218,1953064037,1148088169,1919902565,1869182049,13422}
    },
    {
        name = "𓊆 ★ᯓ ميجالوث الوحش الثلجي ᯓ★ 𓊇",
        directValues = {1886930218,1953064037,1148088169,1919902565,1869182049,13678}
    },
    {
        name = "𓊆 ★ᯓ منتجع فندقي أسرار كليوباترا ᯓ★ 𓊇",
        directValues = {1886930218,1953064037,1148088169,1919902565,1869182049,13934}
    },
    {
        name = "𓊆 ★ᯓ متنزه ترفيهي نباتي ᯓ★ 𓊇",
        directValues = {1886930218,1953064037,1148088169,1919902565,1869182049,14190}
    },
    {
        name = "𓊆 ★ᯓ متحف مملكة بوسيدون ᯓ★ 𓊇",
        directValues = {1886930218,1953064037,1148088169,1919902565,1869182049,14446}
    },
    {
        name = "𓊆 ★ᯓ مركز أبحاث الحالات الشاذة الطبيعية ᯓ★ 𓊇",
        directValues = {1886930218,1953064037,1148088169,1919902565,1869182049,14702}
    },
    {
        name = "𓊆 ★ᯓ قصر ذكي ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3158382}
    },
    {
        name = "𓊆 ★ᯓ منزل الغزال الذهبي الريفي ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3223918}
    },
    {
        name = "𓊆 ★ᯓ تمثال نافوره اللوتس ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3289454}
    },
    {
        name = "𓊆 ★ᯓ مسرح باندور القديم ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3354990}
    },
    {
        name = "𓊆 ★ᯓ صوبة ملكة الدبابير ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3420526}
    },
    {
        name = "𓊆 ★ᯓ منشأت ابحاث فضائيه ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3486062}
    },
    {
        name = "𓊆 ★ᯓ مكتبة الشجره ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3551598}
    },
    {
        name = "𓊆 ★ᯓ قاعده التخمين ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3617134}
    },
    {
        name = "𓊆 ★ᯓ المقهي الكوني ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3682670}
    },
    {
        name = "𓊆 ★ᯓ حديقه ارض القرود المائيه ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3748206}
    },
    {
        name = "𓊆 ★ᯓ ملاز جبلي ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3158638}
    },
    {
        name = "𓊆 ★ᯓ حديقه ترفيهيه رائعة ᯓ★ 𓊇",
        directValues = {1886930220,1953064037,1148088169,1919902565,1869182049,3224174}
    },
    {
        name = "𓊆 ★ᯓ سنترال بارك ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862283630,3158382}
    },
    {
        name = "𓊆 ★ᯓ مركز المجتمع الصيني ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862283886,3158382}
    },
    {
        name = "𓊆 ★ᯓ حديقه بيئيه بطابع قوس قزح ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862284142,3158382}
    },
    {
        name = "𓊆 ★ᯓ جواله الزواقه ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862284398,3158382}
    },
    {
        name = "𓊆 ★ᯓ المعرض الزراعي ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862284654,3158382}
    },
    {
        name = "𓊆 ★ᯓ مجمع رياضي ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862284910,321137}
    },
    {
        name = "𓊆 ★ᯓ عالم البطريق ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862285166,3276914}
    },
    {
        name = "𓊆 ★ᯓ صاله ديسكو كلاسيكيه ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862285422,3354990}
    },
    {
        name = "𓊆 ★ᯓ معرض الفنون والحرف اليدوية ᯓ★ 𓊇",
        directValues = {1919241506,1144153447,1919902565,1869182049,1862285678,3354990}
    },
    {
        name = "𓊆 ★ᯓ موقع مخيم مريح ᯓ★ 𓊇",
        directValues = {1919241508,1144153447,1919902565,1869182049,3158382,3420526}
    },
    {
        name = "𓊆 ★ᯓ حفل شاطئ ᯓ★ 𓊇",
        directValues = {1919241508,1144153447,1919902565,1869182049,3223918,3539058}
    },
    {
        name = "𓊆 ★ᯓ قلب ايطالي ᯓ★ 𓊇",
        directValues = {1919241508,1144153447,1919902565,1869182049,3289454,3604594}
    
}
}

--الملصقاات



local bbsData = {
{ name = "𓊆 ★ᯓ بطة البوسه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3486324,0,0,0} },
{ name = "𓊆 ★ᯓ بطة العضلات ᯓ★ 𓊇", directValues = {1869440276,1935632746,3486068,0,0,0} },
{ name = "𓊆 ★ᯓ بطة هالوين بوسه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3290228,0,0,0} },
{ name = "𓊆 ★ᯓ بطة السيلفي ᯓ★ 𓊇", directValues = {1869440274,1935632746,14704,0,0,0} },
{ name = "𓊆 ★ᯓ بطة القراصنه تطلق النار ᯓ★ 𓊇", directValues = {1869440274,1935632746,12660,0,0,0} },
{ name = "𓊆 ★ᯓ بطة تعلن الاستسلام ᯓ★ 𓊇", directValues = {1869440274,1935632746,14196,0,0,0} },

{ name = "𓊆 ★ᯓ النحلة الراقصه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3223924,0,0,0} },
{ name = "𓊆 ★ᯓ نحلة الكريسماس ᯓ★ 𓊇", directValues = {1869440276,1935632746,3551604,0,0,0} },
{ name = "𓊆 ★ᯓ النحلة الماهره ᯓ★ 𓊇", directValues = {1869440276,1935632746,3551860,0,0,0} },
{ name = "𓊆 ★ᯓ نحلة عيد الفصح ᯓ★ 𓊇", directValues = {1869440276,1935632746,3158900,0,0,0} },
{ name = "𓊆 ★ᯓ نحلة هالوين ᯓ★ 𓊇", directValues = {1869440276,1935632746,3355764,0,0,0} },
{ name = "𓊆 ★ᯓ النحله الضاحكه ᯓ★ 𓊇", directValues = {1869440274,1935632746,13936,0,0,0} },
-- قسم الفرخة + قسم البقرة (العدد الكلي: 37)

{ name = "𓊆 ★ᯓ الفرخه المشعوذه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3422068,0,0,0} },
{ name = "𓊆 ★ᯓ الفرخه في استراحه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3159924,0,0,0} },
{ name = "𓊆 ★ᯓ الفرخه الساحره ᯓ★ 𓊇", directValues = {1869440276,1935632746,3158388,0,0,0} },
{ name = "𓊆 ★ᯓ فرخه تتزلج على الجليد ᯓ★ 𓊇", directValues = {1869440276,1935632746,3682676,0,0,0} },
{ name = "𓊆 ★ᯓ الفرخه الخبازه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3420788,0,0,0} },
{ name = "𓊆 ★ᯓ فرخه تسمع الموسيقى ᯓ★ 𓊇", directValues = {1869440276,1935632746,3683188,0,0,0} },
{ name = "𓊆 ★ᯓ فرخه تودع ᯓ★ 𓊇", directValues = {1869440276,1935632746,3224692,0,0,0} },
{ name = "𓊆 ★ᯓ فرخه رياضيه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3683444,0,0,0} },
{ name = "𓊆 ★ᯓ الفرخه الجنيه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3224948,0,0,0} },
{ name = "𓊆 ★ᯓ الفرخه غمزه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3421556,0,0,0} },
{ name = "𓊆 ★ᯓ فرخه الحفل ᯓ★ 𓊇", directValues = {1869440276,1935632746,3683700,0,0,0} },
{ name = "𓊆 ★ᯓ فرخة الاستعراض ᯓ★ 𓊇", directValues = {1869440276,1935632746,3290740,0,0,0} },
{ name = "𓊆 ★ᯓ فرخه تعزف على اله موسيقيه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3487348,0,0,0} },
{ name = "𓊆 ★ᯓ فرخه صينيه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3684212,0,0,0} },
{ name = "𓊆 ★ᯓ فرخة اوكيتو وغمزه ᯓ★ 𓊇", directValues = {1869440274,1935632746,13424,0,0,0} },

{ name = "𓊆 ★ᯓ بقرة القراصنه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3487604,0,0,0} },
{ name = "𓊆 ★ᯓ البقرة على دراجه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3225460,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة تحمل سلة الخضار ᯓ★ 𓊇", directValues = {1869440276,1935632746,3354996,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة في الفضاء ᯓ★ 𓊇", directValues = {1869440276,1935632746,3289716,0,0,0} },
{ name = "𓊆 ★ᯓ البقرة المغنيه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3224436,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة تشغل النار ᯓ★ 𓊇", directValues = {1869440276,1935632746,3552116,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة مصاص الدماء تاكل فوشار ᯓ★ 𓊇", directValues = {1869440276,1935632746,3159156,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة الكريسماس ᯓ★ 𓊇", directValues = {1869440276,1935632746,3486836,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة القلوب ᯓ★ 𓊇", directValues = {1869440276,1935632746,3617908,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة على المريخ ᯓ★ 𓊇", directValues = {1869440276,1935632746,3159412,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة تحضر الكيك ᯓ★ 𓊇", directValues = {1869440276,1935632746,3487092,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة مصاص الدماء خفاش ᯓ★ 𓊇", directValues = {1869440276,1935632746,3552628,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة على لوح تزلج ᯓ★ 𓊇", directValues = {1869440276,1935632746,3749236,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة عيد الفصح ᯓ★ 𓊇", directValues = {1869440276,1935632746,3356276,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة اعلاميه تصور ᯓ★ 𓊇", directValues = {1869440276,1935632746,3552884,0,0,0} },
{ name = "𓊆 ★ᯓ البقره الملكه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3683956,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة تشرب الشاي ᯓ★ 𓊇", directValues = {1869440276,1935632746,3618676,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة تعليم الموسيقى ᯓ★ 𓊇", directValues = {1869440276,1935632746,3749748,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة بوسات ᯓ★ 𓊇", directValues = {1869440274,1935632746,12912,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة في السينمه تاكل الفوشار ᯓ★ 𓊇", directValues = {1869440274,1935632746,14192,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة ببرميل قراصنه ᯓ★ 𓊇", directValues = {1869440274,1935632746,3158644,0,0,0} },
-- قسم الخروف + قسم كلب البحر (العدد الكلي: 26)

{ name = "𓊆 ★ᯓ خروف الهارب ᯓ★ 𓊇", directValues = {1869440276,1935632746,3553140,0,0,0} },
{ name = "𓊆 ★ᯓ الخروف المصري ᯓ★ 𓊇", directValues = {1869440276,1935632746,3422068,0,0,0} },
{ name = "𓊆 ★ᯓ خروف الهديه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3290996,0,0,0} },
{ name = "𓊆 ★ᯓ خروف بالثلج ᯓ★ 𓊇", directValues = {1869440276,1935632746,3617140,0,0,0} },
{ name = "𓊆 ★ᯓ خروف العازف ᯓ★ 𓊇", directValues = {1869440276,1935632746,3617396,0,0,0} },
{ name = "𓊆 ★ᯓ خروف يضرب التلفاز ᯓ★ 𓊇", directValues = {1869440276,1935632746,3486580,0,0,0} },
{ name = "𓊆 ★ᯓ خروف مقلب التنين ᯓ★ 𓊇", directValues = {1869440276,1935632746,3552372,0,0,0} },
{ name = "𓊆 ★ᯓ خروف مقلب الذئب ᯓ★ 𓊇", directValues = {1869440276,1935632746,3289460,0,0,0} },
{ name = "𓊆 ★ᯓ خروف بلباس الارنب ᯓ★ 𓊇", directValues = {1869440276,1935632746,3748980,0,0,0} },
{ name = "𓊆 ★ᯓ خروف ملك ᯓ★ 𓊇", directValues = {1869440276,1935632746,3290484,0,0,0} },
{ name = "𓊆 ★ᯓ خروف المحقق ᯓ★ 𓊇", directValues = {1869440276,1935632746,3356020,0,0,0} },
{ name = "𓊆 ★ᯓ خروف الرمايه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3618164,0,0,0} },
{ name = "𓊆 ★ᯓ خروف على شكل مهرج ᯓ★ 𓊇", directValues = {1869440276,1935632746,3159668,0,0,0} },
{ name = "𓊆 ★ᯓ خروف يعزف على الجيتار ᯓ★ 𓊇", directValues = {1869440276,1935632746,3421812,0,0,0} },
{ name = "𓊆 ★ᯓ خروف الفارس ᯓ★ 𓊇", directValues = {1869440276,1935632746,3618420,0,0,0} },
{ name = "𓊆 ★ᯓ الخروف بوسه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3749492,0,0,0} },
{ name = "𓊆 ★ᯓ خروف تسريحة الشعر ᯓ★ 𓊇", directValues = {1869440276,1935632746,3160180,0,0,0} },
{ name = "𓊆 ★ᯓ خروف مفاجأه ᯓ★ 𓊇", directValues = {1869440274,1935632746,12656,0,0,0} },
{ name = "𓊆 ★ᯓ خروف يقدم العصير ᯓ★ 𓊇", directValues = {1869440274,1935632746,13428,0,0,0} },

{ name = "𓊆 ★ᯓ كلب البحر مصباح علاء الدين ᯓ★ 𓊇", directValues = {1869440276,1935632746,3682932,0,0,0} },
{ name = "𓊆 ★ᯓ كلب البحر المطبل ᯓ★ 𓊇", directValues = {1869440276,1935632746,3289972,0,0,0} },
{ name = "𓊆 ★ᯓ كلب البحر على المسرح ᯓ★ 𓊇", directValues = {1869440276,1935632746,3421300,0,0,0} },
{ name = "𓊆 ★ᯓ كلب البحر شيطان ᯓ★ 𓊇", directValues = {1869440274,1935632746,13168,0,0,0} },
{ name = "𓊆 ★ᯓ كلب البحر يضرب راسه ᯓ★ 𓊇", directValues = {1869440274,1935632746,14448,0,0,0} },
{ name = "𓊆 ★ᯓ كلب البحر يلعب بالنقود ᯓ★ 𓊇", directValues = {1869440274,1935632746,14708,0,0,0} },
-- قسم الخنزير (عدد العناصر: 8)


{ name = "𓊆 ★ᯓ خنزير اوكيتو ᯓ★ 𓊇", directValues = {1869440276,1935632746,3420532,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير على صاروخ ᯓ★ 𓊇", directValues = {1869440276,1935632746,3355252,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير على القارب ᯓ★ 𓊇", directValues = {1869440276,1935632746,3421044,0,0,0} },
{ name = "𓊆 ★ᯓ خنزيره تفوز بالجائزه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3748724,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير يشرب القهوه ᯓ★ 𓊇", directValues = {1869440276,1935632746,3225204,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير يشم الزهور ᯓ★ 𓊇", directValues = {1869440274,1935632746,13680,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير المراقبه ᯓ★ 𓊇", directValues = {1869440274,1935632746,3158900,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير يلعب بالحبل ᯓ★ 𓊇", directValues = {1869440274,1935632746,14452,0,0,0} }
}
--الصور
local bbbsData = {
    { name = "𓊆 ★ᯓ صوره بروفايل 1 عام ᯓ★ 𓊇", directValues = {1635148044,3748145,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 2 عام ᯓ★ 𓊇", directValues = {1635148044,3158577,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 3 عام ᯓ★ 𓊇", directValues = {1635148044,3224113,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 4 عام ᯓ★ 𓊇", directValues = {1635148044,3289649,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 5 عام ᯓ★ 𓊇", directValues = {1635148044,3355185,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 6 عام ᯓ★ 𓊇", directValues = {1635148044,3421489,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 7 عام ᯓ★ 𓊇", directValues = {1635148044,3225905,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 8 عام ᯓ★ 𓊇", directValues = {1635148044,3748658,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 9 عام ᯓ★ 𓊇", directValues = {1635148044,3225650,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 10 عام ᯓ★ 𓊇", directValues = {1635148044,3354931,0,0,0,0} },
    { name = "𓊆 ★ᯓ صوره بروفايل 11 عام ᯓ★ 𓊇", directValues = {1635148044,3290675,0,0,0,0} },

{ name = "𓊆 ★ᯓ صورة بغبغاء ᯓ★ 𓊇", directValues = {1635148044,3617074,0,0,0,0} },
{ name = "𓊆 ★ᯓ بطة تلقي التحية ᯓ★ 𓊇", directValues = {1635148044,3487537,0,0,0,0} },
{ name = "𓊆 ★ᯓ كلب يحمل بخاخ ᯓ★ 𓊇", directValues = {1635148044,3422001,0,0,0,0} },
{ name = "𓊆 ★ᯓ فأر يحمل كيك ᯓ★ 𓊇", directValues = {1635148044,3750193,0,0,0,0} },
{ name = "𓊆 ★ᯓ فرخة عاملة ᯓ★ 𓊇", directValues = {1635148044,3160113,0,0,0,0} },
{ name = "𓊆 ★ᯓ حدث الأفعوانية ᯓ★ 𓊇", directValues = {1635148044,3684657,0,0,0,0} },
{ name = "𓊆 ★ᯓ خروف يحمل خيزرانة ᯓ★ 𓊇", directValues = {1635148044,3684145,0,0,0,0} },
{ name = "𓊆 ★ᯓ أرنبة ترسم على البيض ᯓ★ 𓊇", directValues = {1635148044,3551538,0,0,0,0} },
{ name = "𓊆 ★ᯓ أرنبة تضحك ᯓ★ 𓊇", directValues = {1635148044,3224370,0,0,0,0} },
{ name = "𓊆 ★ᯓ حمار يضحك ᯓ★ 𓊇", directValues = {1635148044,3289906,0,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير يأكل 🍭 ᯓ★ 𓊇", directValues = {1635148044,3551794,0,0,0,0} },
{ name = "𓊆 ★ᯓ خروف عيد الميلاد ᯓ★ 𓊇", directValues = {1635148044,3355953,0,0,0,0} },
{ name = "𓊆 ★ᯓ ختيار الديسكو ᯓ★ 𓊇", directValues = {1635148044,3224371,0,0,0,0} },
{ name = "𓊆 ★ᯓ بطة ترتدي معطف ᯓ★ 𓊇", directValues = {1635148044,3617331,0,0,0,0} },
{ name = "𓊆 ★ᯓ رجل رياضي ᯓ★ 𓊇", directValues = {1635148044,3289651,0,0,0,0} },
{ name = "𓊆 ★ᯓ شاب يحمل يقطين ᯓ★ 𓊇", directValues = {1635148044,3420467,0,0,0,0} },
{ name = "𓊆 ★ᯓ امرأة طباخة ᯓ★ 𓊇", directValues = {1635148044,3747891,0,0,0,0} },
{ name = "𓊆 ★ᯓ كلب فوق رأسه فرخة ᯓ★ 𓊇", directValues = {1635148044,3420211,0,0,0,0} },
{ name = "𓊆 ★ᯓ شاب احتفال صيني ᯓ★ 𓊇", directValues = {1635148044,3684658,0,0,0,0} },
{ name = "𓊆 ★ᯓ فرخة صيفية تشرب العصير ᯓ★ 𓊇", directValues = {1635148044,3487027,0,0,0,0} },
{ name = "𓊆 ★ᯓ خروف فارس ᯓ★ 𓊇", directValues = {1635148044,3617843,0,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة بالزي الرسمي ᯓ★ 𓊇", directValues = {1635148044,3224627,0,0,0,0} },
{ name = "𓊆 ★ᯓ فرخة تأكل العنب ᯓ★ 𓊇", directValues = {1635148044,3748659,0,0,0,0} },
{ name = "𓊆 ★ᯓ خروف الديسكو ᯓ★ 𓊇", directValues = {1635148044,3486515,0,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة عيد الفصح ᯓ★ 𓊇", directValues = {1635148044,3420979,0,0,0,0} },
{ name = "𓊆 ★ᯓ فرخة إيرلندية تحمل برسيم ᯓ★ 𓊇", directValues = {1635148044,3355443,0,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير الفوانيس ᯓ★ 𓊇", directValues = {1635148044,3158835,0,0,0,0} },
{ name = "𓊆 ★ᯓ بغبغاء بعجلة ᯓ★ 𓊇", directValues = {1635148044,3355186,0,0,0,0} },
{ name = "𓊆 ★ᯓ مهرجان العلكة ᯓ★ 𓊇", directValues = {1635148044,3486258,0,0,0,0} },
{ name = "𓊆 ★ᯓ شاب يحمل ميدالية ᯓ★ 𓊇", directValues = {1635148044,3290162,0,0,0,0} },
{ name = "𓊆 ★ᯓ خروف أنيق ᯓ★ 𓊇", directValues = {1635148044,3158834,0,0,0,0} },
{ name = "𓊆 ★ᯓ ختيار يحمل بطاقات ᯓ★ 𓊇", directValues = {1635148044,3159858,0,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة حمى الحب ᯓ★ 𓊇", directValues = {1635148044,3618866} },
{ name = "𓊆 ★ᯓ دجاجة رياضية ᯓ★ 𓊇", directValues = {1635148044,3160370,0,0,0,0} },
{ name = "𓊆 ★ᯓ صقر ᯓ★ 𓊇", directValues = {1635148044,3422258,0,0,0,0} },
{ name = "𓊆 ★ᯓ امرأة قرصانة ᯓ★ 𓊇", directValues = {1635148044,3684402,0,0,0,0} },
{ name = "𓊆 ★ᯓ بغبغاء آخر ᯓ★ 𓊇", directValues = {1635148044,3749938,0,0,0,0} },
   { name = "𓊆 ★ᯓ بنت تحمل دمية لطيفة ᯓ★ 𓊇", directValues = {1635148044,3289907,0,0,0,0} },
{ name = "𓊆 ★ᯓ رجل رحلة التخييم ᯓ★ 𓊇", directValues = {1635148044,3552051,0,0,0,0} },
{ name = "𓊆 ★ᯓ بنت تشرب العصير ᯓ★ 𓊇", directValues = {1635148044,3159091,0,0,0,0} },
{ name = "𓊆 ★ᯓ ولد إيطالي يأكل البيتزا ᯓ★ 𓊇", directValues = {1635148044,3552307,0,0,0,0} },
{ name = "𓊆 ★ᯓ خنزير يشرب العصير ᯓ★ 𓊇", directValues = {1635148044,3355442,0,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة دراكولا ᯓ★ 𓊇", directValues = {1635148044,3159090,0,0,0,0} },
{ name = "𓊆 ★ᯓ ولد يحمل السمك ᯓ★ 𓊇", directValues = {1635148044,3421234,0,0,0,0} },
{ name = "𓊆 ★ᯓ ضيف غامض ᯓ★ 𓊇", directValues = {1635148044,3683378,0,0,0,0} },
{ name = "𓊆 ★ᯓ حمامة الحب ᯓ★ 𓊇", directValues = {1635148044,3290418,0,0,0,0} },
{ name = "𓊆 ★ᯓ قزم يحمل هدية ᯓ★ 𓊇", directValues = {1635148044,3354673,0,0,0,0} },
{ name = "𓊆 ★ᯓ عجوز أنيقة ᯓ★ 𓊇", directValues = {1635148044,3682866,0,0,0,0} },
{ name = "𓊆 ★ᯓ بنت ترتدي قبعة ᯓ★ 𓊇", directValues = {1635148044,3748402,0,0,0,0} },
{ name = "𓊆 ★ᯓ ولد مصاص دماء ᯓ★ 𓊇", directValues = {1635148044,3420978,0,0,0,0} },
{ name = "𓊆 ★ᯓ رجل يحمل القمح ᯓ★ 𓊇", directValues = {1635148044,3224626,0,0,0,0} },
{ name = "𓊆 ★ᯓ بنت تحدي الفضاء ᯓ★ 𓊇", directValues = {1635148044,3486770,0,0,0,0} },
{ name = "𓊆 ★ᯓ ولد الكريسماس ᯓ★ 𓊇", directValues = {1635148044,3355698,0,0,0,0} },
{ name = "𓊆 ★ᯓ رجل فرنسي ᯓ★ 𓊇", directValues = {1635148044,3748914,0,0,0,0} },
{ name = "𓊆 ★ᯓ ملك عربي ᯓ★ 𓊇", directValues = {1635148044,3159346,0,0,0,0} },
{ name = "𓊆 ★ᯓ بنت عيد الفصح ᯓ★ 𓊇", directValues = {1635148044,3224882,0,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة الشتاء الرياضي ᯓ★ 𓊇", directValues = {1635148044,3486259,0,0,0,0} },
{ name = "𓊆 ★ᯓ خروف برازيلي ᯓ★ 𓊇", directValues = {1635148044,3551795,0,0,0,0} },
{ name = "𓊆 ★ᯓ صورة كائن فضائي ᯓ★ 𓊇", directValues = {1635148044,3552563,0,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة أطلانتس ᯓ★ 𓊇", directValues = {1635148044,3159347,0,0,0,0} },
{ name = "𓊆 ★ᯓ رجل قرصان ᯓ★ 𓊇", directValues = {1635148044,3289394,0,0,0,0} },
{ name = "𓊆 ★ᯓ خفاش 🦇 ᯓ★ 𓊇", directValues = {1635148044,3749169,0,0,0,0} },
{ name = "𓊆 ★ᯓ بقرة مهرجان العلكة ᯓ★ 𓊇", directValues = {1635148044,3159601,0,0,0,0} },
{ name = "𓊆 ★ᯓ ولد استكشاف الجزيرة المفقودة ᯓ★ 𓊇", directValues = {1635148044,3682355,0,0,0,0} },
{ name = "𓊆 ★ᯓ حيوان أليف ركب الجليد ᯓ★ 𓊇", directValues = {1635148044,3224114,0,0,0,0} },
{ name = "𓊆 ★ᯓ بنت المكياج ᯓ★ 𓊇", directValues = {1635148044,3422514,0,0,0,0} },
{ name = "𓊆 ★ᯓ ثعلب يأكل العشب ᯓ★ 𓊇", directValues = {1635148044,3553073,0,0,0,0} },
{ name = "𓊆 ★ᯓ بنت رسامة ᯓ★ 𓊇", directValues = {1635148044,3618098,0,0,0,0} },
{ name = "𓊆 ★ᯓ فرخة تحمل فانوس ᯓ★ 𓊇", directValues = {1635148044,3616819,0,0,0,0} },
{ name = "𓊆 ★ᯓ تمساح صيفي ᯓ★ 𓊇", directValues = {1635148044,3356210,0,0,0,0} },
{ name = "𓊆 ★ᯓ فرخة مسرحية ᯓ★ 𓊇", directValues = {1635148044,3684146,0,0,0,0} },
{ name = "𓊆 ★ᯓ غزالة كريسماس ᯓ★ 𓊇", directValues = {1635148044,3748401,0,0,0,0} },
{ name = "𓊆 ★ᯓ حيوان أليف كريسماس ᯓ★ 𓊇", directValues = {1635148044,3158833,0,0,0,0} },
{ name = "𓊆 ★ᯓ حيوان أليف يرتدي معطف ᯓ★ 𓊇", directValues = {1635148044,3224369,0,0,0,0} },
{ name = "𓊆 ★ᯓ ولد غواص ᯓ★ 𓊇", directValues = {1635148044,3289905,0,0,0,0} },
{ name = "𓊆 ★ᯓ احتفال الذكرى السنوية العاشرة ᯓ★ 𓊇", directValues = {1635148044,3289395,0,0,0,0} },
{ name = "𓊆 ★ᯓ خروف بالزي الرسمي ᯓ★ 𓊇", directValues = {1635148044,3354675,0,0,0,0} },
{ name = "𓊆 ★ᯓ دب رومانسي يعزف ᯓ★ 𓊇", directValues = {1635148044,3422002,0,0,0,0} },
}
--لافتات
local bbbsssbData = {

{
    name = "𓊆 ★ᯓ لافتة مدينة روك ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402547,1953063775,1769168761,1918856807,1600873327,1852270963}
},

{
    name = "𓊆 ★ᯓ لافتة العلكة للجميع ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {1852402547,1953063775,1769168761,1918856807,1852403061,1601465953,1751343469,6647401}
},

{
    name = "𓊆 ★ᯓ لافتة وحش مطاطية ᯓ★ 𓊇",
    value24 = 30,
    pointerValues = {1852402547,1953063775,1769168761,1717530215,1802396018,1818323039,1702326124,28261}
},

{
    name = "𓊆 ★ᯓ علامة المدينة في عيد الميلاد ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402547,1953063775,1769168761,1667198567,1936290408,1935764852,1734964063,110}
},

{
    name = "𓊆 ★ᯓ لافتة بطابع عيد الميلاد ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402547,1953063775,1769168761,1398763111,959930192,1769168688,28263}
},

{
    name = "𓊆 ★ᯓ لافتة الذكرى السنوية للمدينة ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {1852402547,1953063775,1769168761,1650421351,1752461929,1601790308,1702441009,7565921}
},

{
    name = "𓊆 ★ᯓ لافتة مزرعة قديمة رائعة ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402547,1953063775,1769168761,1667198567,1935636335,7235433}
},

{
    name = "𓊆 ★ᯓ لافتة كشك المشروبات ᯓ★ 𓊇",
    value24 = 31,
    pointerValues = {1852402547,1953063775,1769168761,1935634023,1953460077,1650813288,1935635041,7235433}
},

{
    name = "𓊆 ★ᯓ لافتة تزلج على الجليد للمدينة ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402547,1953063775,1769168761,1935634023,1651994478,1685217647,1734964063,110}
},

{
    name = "𓊆 ★ᯓ السيد بسكويت الزنجبيل ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1735289159,1919054437,1298424165,1867017825,1869103988,1634496355,25972}
},

{
    name = "𓊆 ★ᯓ لافتة مدينة التفاحة الكبيرة ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {1852402547,1953063775,1769168761,1751084647,1702261345,1935635571,7235433}
},

{
    name = "𓊆 ★ᯓ لافتة المدينة التي لا تنام ᯓ★ 𓊇",
    value24 = 30,
    pointerValues = {1852402547,1953063775,1769168761,1683975783,1868788585,1953063775,1769168761,28263}
},

{
    name = "𓊆 ★ᯓ لافتة مدينة ميكانيكية ᯓ★ 𓊇",
    value24 = 28,
    pointerValues = {1852402547,1953063775,1769168761,1834970727,1634231141,1600350574,1852270963}
},

{
    name = "𓊆 ★ᯓ لافتة مدينة بطابع خيالي ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402547,1953063775,1769168761,1633644135,1768055154,1769168739,28263}
},



{
    name = "𓊆 ★ᯓ لافتة مدينة ذات مطحنة ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402547,1953063775,1769168761,1298099815,1399614569,7235433}
},
{
    name = "𓊆 ★ᯓ علامة المدينة الحجرية ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402547,1953063775,1769168761,1935634023,1701736308,1734964063,110}
},

{
    name = "𓊆 ★ᯓ لافتة التقاليد القديمة ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402547,1953063775,1769168761,1633644135,1851877747,1734964063,110}
},

{
    name = "𓊆 ★ᯓ علامة مدينة الأحلام ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402547,1953063775,1769168761,1767861863,1702260588,1734964063,110}
},

{
    name = "𓊆 ★ᯓ علامة مدينة الأضواء ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402547,1953063775,1769168761,1985965671,1935763301,1734964063,110}
},

{
    name = "𓊆 ★ᯓ لافتة مزرعة مريحة ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402547,1953063775,1769168761,1717530215,1601008225,1852270963}
},

{
    name = "𓊆 ★ᯓ شعار عيد مدينة ᯓ★ 𓊇",
    value24 = 28,
    pointerValues = {1852402547,1953063775,1769168761,1650421351,1752461929,1601790308,1852270963}
},

{
    name = "𓊆 ★ᯓ علامة هالوين كبيرة ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402547,1953063775,1769168761,1751084647,1869376609,1852138871,1734964063,110}
},

{
    name = "𓊆 ★ᯓ علامة مدينة الغرب البري ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402547,1953063775,1769168761,2002742887,1600416873,1953719671,1734964063,110}
},

{
    name = "𓊆 ★ᯓ لافتة نيون للمدينة ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402547,1953063775,1769168761,1851747943,1601072997,1852270963}
},

{
    name = "𓊆 ★ᯓ لافتة إعلانية ᯓ★ 𓊇",
    value24 = 30,
    pointerValues = {1852402547,1953063775,1769168761,1818193511,1601203553,1918988130,1769168740,28263}
},

{
    name = "𓊆 ★ᯓ علامة المدينة الموسيقية ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402547,1953063775,1769168761,1834970727,1667855221,1734964063,110}
},

{
    name = "𓊆 ★ᯓ لافتة المدينة الرائعة ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402547,1953063775,1769168761,2002742887,1701080943,1769168750,28263}
},

{
    name = "𓊆 ★ᯓ لافتة المدينة الزهرية ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402547,1953063775,1769168761,1717530215,1702326124,1684365938,1734964063,110}
},

{
    name = "𓊆 ★ᯓ لافتة المدينة الفنية ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {1852402547,1953063775,1769168761,1230990951,1131310962,1400468585,7235433}
},

{
    name = "𓊆 ★ᯓ لافتة صبار للمدينة ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402547,1953063775,1769168761,1667198567,1970561889,1769168755,28263}
},

{
    name = "𓊆 ★ᯓ لافتة طيران للمدينة ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402547,1953063775,1769168761,2002742887,1701277289,1769168740,28263}
},

{
    name = "𓊆 ★ᯓ لافتة تحية للمدينة ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402547,1953063775,1769168761,1885302375,1601006689,1701147252,115}
},

{
    name = "𓊆 ★ᯓ لافتة معكم على الهواء مباشرة ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {1852402547,1953063775,1769168761,1415540327,1768120150,1935636852,7235433}
},

{
    name = "𓊆 ★ᯓ لافتة رائعة للمدينة ᯓ★ 𓊇",
    value24 = 30,
    pointerValues = {1852402547,1953063775,1769168761,1834970727,1769239417,1600938339,1852143205,29556}
},

{
    name = "𓊆 ★ᯓ لافتة وحش مطاطية ᯓ★ 𓊇",
    value24 = 30,
    pointerValues = {1852402547,1953063775,1769168761,1717530215,1802396018,1818323039,1702326124,28261}
},

{
    name = "𓊆 ★ᯓ لافتة تزلج على الجليد للمدينة ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402547,1953063775,1769168761,1935634023,1651994478,1685217647,1734964063,110}
},

{
    name = "𓊆 ★ᯓ لافتة منزل مريح ᯓ★ 𓊇",
    value24 = 29,
    pointerValues = {1852402547,1953063775,1769168761,1717530215,1768845941,1701999988,1734964063,110}
}

}
--مظاهر حيوانات
local bbbsssbbData = {

{ name = "𓊆 ★ᯓ دجاجة طيّارة ᯓ★ 𓊇", directValues = {1768641318,1749245806,1701536617,1920229230,1818588769,0} },
{ name = "𓊆 ★ᯓ الدجاجة المشجعة ᯓ★ 𓊇", directValues = {1768641316,1749245806,1701536617,1886609262,7631471,0} },
{ name = "𓊆 ★ᯓ الدجاجة المستكشفة ᯓ★ 𓊇", directValues = {1768641318,1749245806,1701536617,1969905518,1701603182,0} },
{ name = "𓊆 ★ᯓ دجاجة عيد الميلاد ᯓ★ 𓊇", directValues = {1768641316,1749245806,1701536617,2004049774,7628133,0} },
{ name = "𓊆 ★ᯓ دجاجة جنية ᯓ★ 𓊇", directValues = {1768641320,1749245806,1701536617,1919508334,1851878501,100} },
{ name = "𓊆 ★ᯓ دجاجة بثوب يوناني ᯓ★ 𓊇", directValues = {1768641318,1749245806,1701536617,1701338990,1935764588,0} },
{ name = "𓊆 ★ᯓ دجاجة الفضاء ᯓ★ 𓊇", directValues = {1768641322,1749245806,1701536617,1634557806,808612722,13618} },
{ name = "𓊆 ★ᯓ الدجاجة الاحتفالية ᯓ★ 𓊇", directValues = {1768641320,1749245806,1701536617,1852006254,842019449,53} },
{ name = "𓊆 ★ᯓ دجاجة الفارس ᯓ★ 𓊇", directValues = {1768641318,1749245806,1701536617,1850433390,1952999273,0} },
{ name = "𓊆 ★ᯓ دجاجة الديسكو ᯓ★ 𓊇", directValues = {1768641316,1749245806,1701536617,1768185710,7299955,0} },
{ name = "𓊆 ★ᯓ دجاجة الموضة ᯓ★ 𓊇", directValues = {1768641320,1749245806,1701536617,1634099054,1869178995,110} },
{
    name = "𓊆 ★ᯓ دجاجة الروك اند رول ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {1852402515,1768440671,1852140387,1919500895,1633970292,808607609,7550258,1952805734}
},
{
    name = "𓊆 ★ᯓ دجاجة الكريسماس ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402515,1768440671,1852140387,1919443807,1836348265,912225121,539099191,1702258028}
},
{
    name = "𓊆 ★ᯓ دجاجة المهرج ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402515,1768440671,1852140387,1701344351,1769108577,7102819,1701594369,1634607213}
},
{
    name = "𓊆 ★ᯓ دجاجة الهالوين ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402515,1768440671,1852140387,1818323039,1702326124,808611429,503329842,116}
},
{
    name = "𓊆 ★ᯓ دجاجة الاحتفالات ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402515,1768440671,1852140387,1919509087,1633970292,842019449,1946182452,1635131426}
},
{
    name = "𓊆 ★ᯓ دجاجة احتفالية ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402515,1768440671,1852140387,1919509087,1633970292,842019449,519372852,116}
},
{
    name = "𓊆 ★ᯓ دجاجة في ايجازة ᯓ★ 𓊇",
    value24 = 25,
    pointerValues = {1852402515,1768440671,1852140387,1819042143,1818455657,1986622325,1144782949,1164014689}
},
{
    name = "𓊆 ★ᯓ مساعد سانتا الصغير ᯓ★ 𓊇",
    value24 = 26,
    pointerValues = {1852402515,1768440671,1852140387,1919443807,1836348265,808612705,570438450,1144798767}
},
{
    name = "𓊆 ★ᯓ دجاجة الخيالية ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402515,1768440671,1852140387,1852400479,1701995876,6384748,520812832,116}
},
{
    name = "𓊆 ★ᯓ خروف روك اند رول ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1701335903,1113550949,1752461929,1601790308,892481586,1633952256,1951621492}
},
{
    name = "𓊆 ★ᯓ خروف نجم الروك ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402515,1701335903,1650421861,1752461929,846815588,3486256,520818976,116}
},
{
    name = "𓊆 ★ᯓ خروف احتفالي ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1701335903,1650421861,1752461929,846815588,1932800560,519003648,116}
},
{
    name = "𓊆 ★ᯓ خروف العطلة ᯓ★ 𓊇",
    value24 = 27,
    pointerValues = {1852402515,1701335903,1633644645,1852402796,1937075299,845510249,3486256}
},
{
    name = "𓊆 ★ᯓ بيلي بونكا ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402515,1701335903,1650421861,1752461929,846815588,3420720,519024896,116}
},
{
    name = "𓊆 ★ᯓ النعجة الساحرة ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1701335903,1751085157,1869376609,1852138871,842149938,1852383744,1981817460}
},
{
    name = "𓊆 ★ᯓ عصابة الخرفان ᯓ★ 𓊇",
    value24 = 23,
    pointerValues = {1852402515,1701335903,2002743397,2003070057,846492517,3420720,7340143,7667820}
},
{
    name = "𓊆 ★ᯓ خروف عيد ميلاد ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1701335903,1667199077,1936290408,1935764852,875704370,520832512,116}
},
{
    name = "𓊆 ★ᯓ خروف مصاص الدماء ᯓ★ 𓊇",
    value24 = 24,
    pointerValues = {1852402515,1701335903,1214214245,1869376609,1852138871,892481586,790769664,1631861822}
},
{ name = "𓊆 ★ᯓ نعجة مهرجان الربيع ᯓ★ 𓊇", directValues = {1768641324,1750294382,1601201509,1634628972,844713586,3289648} },
{ name = "𓊆 ★ᯓ نعجة الفصح ᯓ★ 𓊇", directValues = {1768641322,1750294382,1601201509,1953718629,808612453,13106} },
{ name = "𓊆 ★ᯓ خروف شمالي ᯓ★ 𓊇", directValues = {1768641320,1750294382,1601201509,1685221230,1866949481,100} },
{ name = "𓊆 ★ᯓ الخروف المحقق ᯓ★ 𓊇", directValues = {1768641320,1750294382,1601201509,1702126948,1986622563,101} },
{ name = "𓊆 ★ᯓ خروف عيد الميلاد ᯓ★ 𓊇", directValues = {1768641312,1750294382,1601201509,1701148531,116,0} },
{ name = "𓊆 ★ᯓ بانديت النبيلة ᯓ★ 𓊇", directValues = {1768641320,1750294382,1601201509,1768058738,1869564014,100} },
{ name = "𓊆 ★ᯓ خروف السامبا ᯓ★ 𓊇", directValues = {1768641314,1750294382,1601201509,2053206626,27753,0} },
{ name = "𓊆 ★ᯓ الخروف المقاتل ᯓ★ 𓊇", directValues = {1768641314,1750294382,1601201509,1734962795,29800,0} },
{ name = "𓊆 ★ᯓ الخراف المصرية ᯓ★ 𓊇", directValues = {1768641312,1750294382,1601201509,1887004517,116,0} },
{ name = "𓊆 ★ᯓ خراف قاعة الرقص ᯓ★ 𓊇", directValues = {1768641322,1750294382,1601201509,1903386989,1634887029,25956} },
{ name = "𓊆 ★ᯓ الخروف الأسطوري ᯓ★ 𓊇", directValues = {1768641322,1750294382,1601201509,1819043176,808612705,13618} },
{ name = "𓊆 ★ᯓ خروف غاتسبي ᯓ★ 𓊇", directValues = {1768641314,1750294382,1601201509,1937006919,31074,0} },
{ name = "𓊆 ★ᯓ مظهر البقرة اليابانية 🐄 ᯓ★ 𓊇", directValues = {1768641308,1866686318,1634361207,7233904,0,0} },
{ name = "𓊆 ★ᯓ بقرة ملكة أطلانتس ᯓ★ 𓊇", directValues = {1768641314,1866686318,1952538487,1953390956,29545,0} },
{ name = "𓊆 ★ᯓ بقرة الزهور ᯓ★ 𓊇", directValues = {1768641314,1866686318,1701207927,1986622579,27745,0} },
{ name = "𓊆 ★ᯓ بقرة سينمائية ᯓ★ 𓊇", directValues = {1768641308,1866686318,1869438839,6646134} },
{ name = "𓊆 ★ᯓ البقرة صانعة الحلويات ᯓ★ 𓊇", directValues = {1768641310,1866686318,2004049783,846488933,56733696} },
{ name = "𓊆 ★ᯓ بقرة الاحتفالات ᯓ★ 𓊇", directValues = {1768641314,1866686318,1768054647,1684567154,50362721} },
{ name = "𓊆 ★ᯓ بقرة عيد الميلاد ᯓ★ 𓊇", directValues = {1768641308,1866686318,2004049783,7628133,56733768} },
{ name = "𓊆 ★ᯓ بقرة مغازلة ᯓ★ 𓊇", directValues = {1768641316,1866686318,1635147639,1953391980,6647401,122} },
{ name = "𓊆 ★ᯓ البقرة رائدة الفضاء ᯓ★ 𓊇", directValues = {1768641306,1866686318,1634557815,29554,0,0} },
{ name = "𓊆 ★ᯓ بقرة احتفالية ᯓ★ 𓊇", directValues = {1768641322,1866686318,1768054647,1684567154,808614241,13362} },
{ name = "𓊆 ★ᯓ بقرة أنيقة ᯓ★ 𓊇", directValues = {1768641316,1866686318,1953062775,846818401,3420720,124} },
{ name = "𓊆 ★ᯓ بقرة الجاسوسة ᯓ★ 𓊇", directValues = {1768641304,1866686318,1886609271,121,0,0} },
{ name = "𓊆 ★ᯓ بقرة جبلية ᯓ★ 𓊇", directValues = {1768641320,1866686318,1769430903,1919251566,1919905875,116} },
{ name = "𓊆 ★ᯓ بقرة مو-سفيراتو ᯓ★ 𓊇", directValues = {1768641324,1866686318,1634230135,2003790956,846095717,3355184} },
{ name = "𓊆 ★ᯓ بقرة السيمفونية ᯓ★ 𓊇", directValues = {1768641322,1866686318,1818451831,1769173857,1937075555,25449} },
{ name = "𓊆 ★ᯓ بقرة القطب الشمالي ᯓ★ 𓊇", directValues = {1768641310,1866686318,1918984055,1667855459,0,0} },
{ name = "𓊆 ★ᯓ بقرة القراصنة المعتمدين ᯓ★ 𓊇", directValues = {1768641318,1866686318,1768972151,1702125938,875704370,0} },
{ name = "𓊆 ★ᯓ نظارات شمسية الروك آند رول للأبقار ᯓ★ 𓊇", directValues = {1768641324,1866686318,1765957495,1684567154,845117793,3486256} },
{ name = "𓊆 ★ᯓ بقرة عربية ᯓ★ 𓊇", directValues = {1768641306,1866686318,1918984055,25185,0,0} },
{ name = "𓊆 ★ᯓ بقرة الفصح ᯓ★ 𓊇", directValues = {1768641318,1866686318,1634033527,1919251571,875704370,0} },
{ name = "𓊆 ★ᯓ البقرة القزمة ᯓ★ 𓊇", directValues = {1768641324,1866686318,1751342967,1953720690,846422381,3289648} },
{ name = "𓊆 ★ᯓ الخنزير الكيوبيد ᯓ★ 𓊇", directValues = {1768641324,1766874990,1635147623,1953391980,1936027241,7954756} },
{ name = "𓊆 ★ᯓ خنزير احتفالي ᯓ★ 𓊇", directValues = {1768641304,1766874990,1313038183,89,0,0} }
}


--------------------------------------------------
-- 📋 دوال القوائم الفرعية
--------------------------------------------------
function showSubMenu(title, data)
    local menu = {}
    for i,v in ipairs(data) do
        table.insert(menu, v.name)
    end
    table.insert(menu, "👽☠b͢a͢c͢k͢ 👽☠")

    local c = gg.choice(menu, nil, title)
    if not c or c > #data then return end

    applyPointer(data[c])
    showSubMenu(title, data)
end

--------------------------------------------------
-- 📋 القائمة الرئيسية
--------------------------------------------------
function showMainMenu()
    while true do  -- حلقة مستمرة للقائمة الرئيسية
        local menu = {
          
    "✦✧▬▭▬ الزينــات ▭▬✧✦",
    "✦✧▬▭▬ الهيلــو ▭▬✧✦",
    "✦✧▬▭▬ المطــار ▭▬✧✦",
    "✦✧▬▭▬ القطــار ▭▬✧✦",
    "✦✧▬▭▬ المينــاء ▭▬✧✦",
    "✦✧▬▭▬ الجــزر ▭▬✧✦",
    "✦✧▬▭▬ الديكـوراات ▭▬✧✦",
    "✦✧▬▭▬ زيادة الديكـوراات ▭▬✧✦",
    "✦✧▬▭▬ الملصقــات ▭▬✧✦",
    "✦✧▬▭▬ الصــور ▭▬✧✦",
    "✦✧▬▭▬ لافتات ▭▬✧✦",
    "✦✧▬▭▬ مظاهر الحيوانات ▭▬✧✦", 
    "✦✧▬▭▬ خــروج ▭▬✧✦"
}
        

        local c = gg.choice(menu, nil,
"Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime()
)

        if not c then
            -- الضغط على الغاء: اختفاء النافذة فقط، ثم العودة لانتظار GARDEN
            
            return  -- تعود لانتظار GARDEN
        elseif c == 13 then
            -- الضغط على خروج: الخروج من القائمة والعودة إلى basmala()
            return "exit"
        else
if c == 1 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        shonaData
    )
end
if c == 1 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        shonaData
    )
end
if c == 2 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        buildData
    )
end
if c == 3 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        helloData
    )
end
if c == 4 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        airportData
    )
end
if c == 5 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        planeData
    )
end
if c == 6 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        bsData
    )
end
if c == 7 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        sbData
    )
end
if c == 8 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        basmalasaData
    )
end
if c == 9 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        bbsData
    )
end
if c == 10 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        bbbsData
    )
end
if c == 11 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        bbbsssbData
    )
end
if c == 12 then
    showSubMenu(
        "Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ\n⏰ TIME : " .. getTime(),
        bbbsssbbData
    )
end
            
        end
    end
end

--------------------------------------------------
-- ▶️ الحلقة الرئيسية لمراقبة GARDEN
--------------------------------------------------
while true do
    if gg.isVisible(true) then
        gg.setVisible(false)  -- اخفاء واجهة GG
        local result = showMainMenu()  -- عرض القائمة عند فتح GARDEN
        if result == "exit" then
            break  -- فقط عند الضغط على خروج
        end
    end
    gg.sleep(100)
end
end
function BASMALASAHERB3()  
gg.toast("Ⓑ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ⓢ")
SBBB = gg.choice({
"༺ الفريق الفني༻", 
"༺بسـملة༻", 
"༺سـاهࢪ༻", 
"༺اشرف الزناتي༻", 
"༺عبد الحـق༻", 
"༺عبد الرحمن ༻", 
"༺ناريـن༻", 
"،༺أبو ضـي༻", 
"❢◤ e͢x͢i͢t͢ ◥❢",
  }, nil,"🦋سنة أولى تطوير 🦋\n⏰ TIME : " .. getTime()) 
if SBBB == nil then else
if SBBB == 1 then SBBB1() end
if SBBB == 2 then SBBB2() end
if SBBB == 3 then SBBB3() end
if SBBB == 4 then SBBB4() end
if SBBB == 5 then SBBB5() end
if SBBB == 6 then SBBB6() end
if SBBB == 7 then SBBB7() end
if SBBB == 8 then SBBB8() end
if SBBB == 9 then basmala() end
end
THSH = -1
end

function SBBB1()
gg.alert("الفريق هو القوة اللي ورا كل نجاح. هو ناس مختلفة، لكن قلبهم واحد وهدفهم واحد. كل واحد فيهم ليه دور مهم، ومع بعض بيصنعوا المستحيل. بالتعاون والثقة والدعم، الفريق الحقيقي دايمًا يوصل للقمة. واللي وراه فريق قوي… عمره ما يخسر 💪\n⏰ TIME : " .. getTime())
end
function SBBB2()
gg.alert("💜 مصريه بقلب سوري🦋\n⏰ TIME : " .. getTime())
end
function SBBB3()
gg.alert("💜 سوري بقلب مصري🦋\n⏰ TIME : " .. getTime())
end
function SBBB4()
gg.alert("🔥اشرف البوب واحد بس💪🏻\n⏰ TIME : " .. getTime())
end
function SBBB5()
gg.alert("💯الصديق الجدع فخر الجزائر 🇩🇿\n⏰ TIME : " .. getTime())
end
function SBBB6()
gg.alert("👌🏻لما نقول الجدعنه يبقى ابن اليمن 🇾🇪🎗\n⏰ TIME : " .. getTime())
end
function SBBB7()
gg.alert("🌺بنت سوريا الجدعه صاحبة صاحبتها🌺\n⏰ TIME : " .. getTime())
end
function SBBB8()
gg.alert("🌼لما نقول العراق يبقى لازم نشوف رجوله ابوضي وجدعنته 🇮🇶\n⏰ TIME : " .. getTime())
end

function EXIT()
    print("ʚïɞ  ╭⊱ꕥ🅱🅰🆂🅼🅰🅻🅰ꕥ⊱╮ ʚïɞ")
 print("🜲🥀قَالَ عَنْهَا هِيَ كَالْفَرَاشَةِ لَكِنَّهَا إِنْ ابْتَسَمَتْ أَنَا مَنْ يَطِيرُ🥀🜲")
  print("ꗟ━╬٨ـﮩﮩ💜٨ـﮩﮩـ╬━ꕗ")
 
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
gg.toast("🚀 السكربت يعمل الآن")
end
saherb()
