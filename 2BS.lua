
local KEY_FILE = "/storage/emulated/0/Download/.bs_key"
local ID_FILE  = "/storage/emulated/0/Download/.bs_install_id"

local SERVER = "https://soft-flower-4528.alklharq40.workers.dev/api/check"

--------------------------------------------------
-- 🆔 توليد / جلب Install ID
--------------------------------------------------
local function generateID()
    local chars = "abcdef0123456789"
    local id = ""

    for i = 1, 16 do
        local r = math.random(1, #chars)
        id = id .. string.sub(chars, r, r)
    end

    return id
end

local function getInstallID()
    local f = io.open(ID_FILE, "r")

    if f then
        local id = f:read("*a")
        f:close()
        return id
    end

    local newID = generateID()

    local f2 = io.open(ID_FILE, "w")
    f2:write(newID)
    f2:close()

    return newID
end

--------------------------------------------------
-- 💾 حفظ / تحميل المفتاح
--------------------------------------------------
local function saveKey(key)
    local f = io.open(KEY_FILE, "w")
    f:write(key)
    f:close()
end

local function loadKey()
    local f = io.open(KEY_FILE, "r")
    if not f then return nil end

    local k = f:read("*a")
    f:close()

    return k:gsub("%s+", "")
end

--------------------------------------------------
-- 🌐 الاتصال بالسيرفر
--------------------------------------------------
local function checkServer(key, deviceid)
    local url = SERVER .. "?key=" .. key .. "&deviceid=" .. deviceid
    local res = gg.makeRequest(url)

    if not res or not res.content then
        return nil
    end

    return res.content
end

--------------------------------------------------
-- 🔍 تحليل الرد
--------------------------------------------------
local function parseResponse(res)

    if string.find(res, '"status"%s*:%s*"active"') then
        return "active"

    elseif string.find(res, '"status"%s*:%s*"expired"') then
        return "expired"

    elseif string.find(res, '"status"%s*:%s*"banned"') then
        return "banned"

    elseif string.find(res, '"status"%s*:%s*"another_device"') then
        return "device"

    else
        return "invalid"
    end
end
local function getJsonNumber(json, key)
    local value = json:match('"' .. key .. '"%s*:%s*(%d+)')
    return tonumber(value) or 0
end

local function showRemainingTime(res)
    local days = getJsonNumber(res, "days")
    local hours = getJsonNumber(res, "hours")
    local minutes = getJsonNumber(res, "minutes")

    gg.alert(
        "⏳ الوقت المتبقي:\n\n" ..
        "🗓 " .. days .. " يوم\n" ..
        "⏰ " .. hours .. " ساعة\n" ..
        "⏱ " .. minutes .. " دقيقة"
    )

    if days == 1 then
        gg.alert(
            "⚠️ تنبيه\n\n" ..
            "بقي يوم واحد فقط على انتهاء الاشتراك."
        )
    end
end
--------------------------------------------------
-- 🔐 شاشة التفعيل
--------------------------------------------------
local function activate()
    local id = getInstallID()

    gg.setVisible(true)

    while true do
        if gg.isVisible(true) then
            gg.setVisible(false)

            local choice = gg.choice({
                "📋 نسخ Install ID",
                "🔑 إدخال كود التفعيل",
                "❌ خروج"
            }, nil, "🔐 نظام التفعيل")

            -- إذا ضغط إلغاء، أخفِ القائمة وانتظر فتح GG مرة أخرى
            if choice == nil then
                gg.setVisible(false)

            elseif choice == 1 then
                gg.copyText(id)
                gg.toast("📋 تم نسخ ID")

            elseif choice == 2 then
                local input = gg.prompt({"أدخل كود التفعيل"}, nil, {"text"})
                if input then
                    local key = input[1]
                    local res = checkServer(key, id)

                    if not res then
                        gg.alert("❌ فشل الاتصال")
                    else
                        local status = parseResponse(res)

if status == "active" then
    saveKey(key)
    showRemainingTime(res)
    return true

                        elseif status == "device" then
                            gg.alert("❌ هذا المفتاح لجهاز آخر")

                        elseif status == "expired" then
                            gg.alert("❌ الاشتراك منتهي")

                        elseif status == "banned" then
                            gg.alert("🚫 محظور")

                        else
                            gg.alert("❌ مفتاح غير صالح")
                        end
                    end
                end

            elseif choice == 3 then
                os.exit()
            end
        end
        gg.sleep(200)
    end
end

--------------------------------------------------
-- 🔎 التحقق عند التشغيل
--------------------------------------------------
local function verify()

    local key = loadKey()
    if not key then
        return false
    end

    local id = getInstallID()
    local res = checkServer(key, id)

    if not res then
        return false
    end

    local status = parseResponse(res)

if status == "active" then
    showRemainingTime(res)
    return true
    else
        os.remove(KEY_FILE)
        return false
    end
end

--------------------------------------------------
-- 🚀 التشغيل الرئيسي
--------------------------------------------------
local function main()

    local ok = verify()

    if not ok then
        local activated = activate()

        if not activated then
            return false
        end
    else
        gg.toast("✅ مفعل")
    end

    return true
end

--------------------------------------------------
-- ▶️ تشغيل النظام
--------------------------------------------------
local run = main()

if not run then
    os.exit()
end

--------------------------------------------------
-- 🔥 سكربتك الحقيقي (لن يعمل إلا بعد التفعيل)
--------------------------------------------------
gg.alert('ᗷᗩᔕᗰᗩᒪᗩ ᗩᕼᘻᘿᕲ')
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
-- شاشة الترحيب
local function welcome()
    local text = [[
✿ــــــــــــ♡•▣سنة اولى تطوير▣•♡ــــــــــ✿     
┌─────────────────────
│⚜️ DAY     :☆ ]] .. getDay() .. [[ 
│📅DATE    :☆ ]] .. getDate() .. [[  
│⏰ TIME    :☆ ]] .. getTime() .. [[  
└─────────────────────
 ┏┳┳┓┏━┓─────────┏━━┓┏━┓
 ┃┃┃┃┃━┫┏┓─┏━┓┏━┓┃┃┃┃┃━┫
 ┃┃┃┃┃━┫┃┣┓┃┣┫┃╋┃┃┃┃┃┃━┫
 ┗━━┛┗━┛┗━┛┗━┛┗━┛┗┻┻┛┗━┛
]] 

 local c = gg.choice({"🚀 ᑕOᑎTIᑎᑌE", "❌ 乇乂丨ㄒ"}, nil, text)
    if c == 2 then os.exit() end
end
welcome()
--[[
 Township Unified GameGuardian Lua
 دمج أربعة سكربتات مع مسار مشترك

 ملاحظات:
 1) شغّل الملف من GameGuardian بعد اختيار اللعبة.
 2) يتم اكتشاف Package والبيئات تلقائيًا من /data/user/0/[Package].
 3) لا تكتب أي مسار يدويًا؛ المسار الناتج هو مسار البيئة المختارة.
 4) اختر المزرعة برقمها (1 = user/0، 2 = user/1 ...).
 5) تم تضمين الأكواد الأصلية في الأسفل داخل SRC_* ويمكن استبدالها بنفس الطريقة.
]]--

local function get_package()
    local info = gg.getTargetInfo and gg.getTargetInfo() or nil
    if info and info.packageName and info.packageName ~= '' then return tostring(info.packageName) end
    if gg.PACKAGE and tostring(gg.PACKAGE) ~= '' then return tostring(gg.PACKAGE) end
    return nil
end

local MERGED_PACKAGE = get_package()
if not MERGED_PACKAGE then gg.alert('❌ تعذر تهيئة الأداة'); return end
local MERGED_BASE = '/data/user/0/' .. MERGED_PACKAGE

local function find_environments()
    local result = {}

    -- البحث الحالي يبقى كما هو
    for user = 0, 20 do
        local p = MERGED_BASE ..
            '/virtual/data/user/' ..
            tostring(user) ..
            '/com.playrix.township/saves/'

        local f = io.open(p .. 'LocalInfo.xml', 'rb')
        if f then
            f:close()
            result[#result + 1] = {
                user = user,
                path = p,
                source = 'virtual'
            }
        end
    end

    -- إذا لم يجد البحث الحالي أي مدينة، ابحث في مسار Resource Manager
    -- ولا تقبل المدينة إلا عند وجود ملفي الحفظ معًا.
    if #result == 0 then
        local realRoot =
            '/data/data/com.lbe.parallel.intl/parallel_intl/'

        for city = 0, 100 do
            local p = realRoot ..
                tostring(city) ..
                '/com.playrix.township/saves/'

            local localInfo = io.open(p .. 'LocalInfo.xml', 'rb')
            if localInfo then
                localInfo:close()

                local gameInfo = io.open(p .. 'mGameInfo.xml', 'rb')
                if gameInfo then
                    gameInfo:close()
                    result[#result + 1] = {
                        user = city,
                        path = p,
                        source = 'parallel_intl'
                    }
                end
            end
        end
    end

    return result
end

local environments = find_environments()
if #environments == 0 then
    gg.alert('❌ لم يتم العثور على مدن')
    return
end
local envMenu = {}
for i, e in ipairs(environments) do
    -- الرقم الظاهر يبدأ من 1: user/0 يظهر كمزرعة 1
    envMenu[i] = '📦 مزرعة رقم ' .. tostring(e.user + 1)
end
local envChoice = gg.choice(envMenu, nil, '📦 اختر المزرعة')
if not envChoice then return end
local MERGED_TOWNSHIP_BASE=environments[envChoice].path

-- The farm is selected with the original copier picker below; no number is requested.
_G.MERGED_PACKAGE=MERGED_PACKAGE
_G.MERGED_BASE=MERGED_BASE
_G.MERGED_TOWNSHIP_BASE=MERGED_TOWNSHIP_BASE

-- TOOL
local SRC_TOOL = [=[
-- ============================================
-- mGameInfo.xml
-- فك الملف ثم تعديل البيانات
-- GameGuardian / Lua
-- ============================================

-- ============================================
-- mGameInfo.xml
-- فك الملف ثم تعديل البيانات
-- GameGuardian / Lua
-- ============================================


-- ============================================
-- CITY SELECTION (provided by merged launcher)
-- ============================================
local INPUT = MERGED_TOWNSHIP_BASE .. "mGameInfo.xml"
local OUTPUT = MERGED_TOWNSHIP_BASE .. ".1bsb.xml"
local EDITED_OUTPUT = MERGED_TOWNSHIP_BASE .. "mGameInfo.xml"

-- ============================================
-- SERVER
-- ============================================

local DECODE_URL =
    "https://soft-flower-4528.alklharq40.workers.dev/api/decode"

local EDIT_URL =
    "https://soft-flower-4528.alklharq40.workers.dev/api/edit"


-- ============================================
-- OPTIONS
-- ============================================

local OPTIONS = {

    {
        label = "『تعديل الـمـسـتـوى 』", 
        type = "number",
        edit = "level"
    },

    {
        label ="『تعديل اسم المدينة 』", 
        type = "text",
        edit = "townName"
    },

    {
        label = "『تعديل انجازات التعاون 』", 
        type = "number",
        edit = "achievementTeamwork"
    },

    {
        label ="『مستويات المحاولة الاولى』", 
        type = "number",
        edit = "firstAttemptM3Levels"
    },

    {
        label ="『مجموعة البطاقات المكتملة』", 
        type = "number",
        edit = "fullCardCollections"
    },

    {
        label ="『الحيوات المرسلة』", 
        type = "number",
        edit = "livesSent"
    },

    {
        label = "『مستوياتM3 المكتملة』", 
        type = "number",
        edit = "m3CompLvls"
    },

    {
        label ="『مهام السباق المكتملة』", 
        type = "number",
        edit = "regataTasksCompleted"
    },

    {
        label ="『عدد مهام السباق الجديدة』", 
        type = "number",
        edit = "regataTaskCount"
    },

    {
        label ="『نقاط مهام السباق』", 
        type = "number",
        edit = "regataTaskPoint"
    },

    {
        label ="『فتح الاطارات』", 
        type = "checkbox",
        edit = "unlockedFrames"
    },

    {
        label = "『فتح النمط』", 
        type = "checkbox",
        edit = "unlockedStyles"
    },

    {
        label = "『فتح الالقاب』", 
        type = "checkbox",
        edit = "unlockedExpRanks"
    },
    
        {
        label = "『فتح الشارات』", 
        type = "checkbox",
        edit = "UnlockedBadges"
    },

    {
        label ="『زيادة واظهار الكروت』", 
        type = "checkbox",
        edit = "unlockAllCards"
    },

    {
        label ="『توسيع كامل للارض』", 
        type = "checkbox",
        edit = "unlockLandExpansions"
    },

    {
        label ="『صور』", 
        type = "checkbox",
        edit = "unlockAllAvatars"
    },

    {
        label ="『الملصقات』", 
        type = "checkbox",
        edit = "chatEmojis"
    }

}


-- ============================================
-- READ FILE
-- ============================================

local function read_file(path)

    local f =
        io.open(
            path,
            "rb"
        )

    if not f then

        error(
            "تعذر فتح الملف"
        )

    end

    local data =
        f:read("*a")

    f:close()

    if not data or #data == 0 then

        error(
            "الملف فارغ"
        )

    end

    return data

end


-- ============================================
-- URL ENCODE
-- ============================================

local function url_encode(str)

    str =
        tostring(str)

    return (
        str:gsub(
            "\n",
            "\r\n"
        ):gsub(
            "([^%w%-_%.~])",
            function(c)

                return string.format(
                    "%%%02X",
                    string.byte(c)
                )

            end
        )
    )

end


-- ============================================
-- JSON ESCAPE
-- ============================================

local function json_escape(value)

    value =
        tostring(value)

    return value
        :gsub(
            "\\",
            "\\\\"
        )
        :gsub(
            '"',
            '\\"'
        )
        :gsub(
            "\n",
            "\\n"
        )
        :gsub(
            "\r",
            "\\r"
        )
        :gsub(
            "\t",
            "\\t"
        )

end


-- ============================================
-- WRITE FILE
-- ============================================

local function write_file(
    path,
    data
)

    local f =
        io.open(
            path,
            "wb"
        )

    if not f then

        error(
            "تعذر إنشاء ملف الناتج"
        )

    end

    f:write(data)

    f:close()

end


-- ============================================
-- POST
-- ============================================

local function post_file(url, data)

    local ok, response = pcall(function()
        return gg.makeRequest(
            url,
            {
                ["Content-Type"] =
                    "application/octet-stream"
            },
            data
        )
    end)

    if not ok then
        error(
            "فشل طلب HTTP\n\n" ..
            tostring(response)
        )
    end

    -- فحص نوع الاستجابة
    if type(response) == "string" then
        error(
            "فشل الاتصال أو قراءة الاستجابة\n\n" ..
            "الاستجابة النصية:\n" ..
            response:sub(1, 2000)
        )
    end

    if type(response) ~= "table" then
        error(
            "نوع استجابة غير متوقع: " ..
            type(response)
        )
    end

    local code = tonumber(response.code)
    local content = response.content

    if not code then
        error(
            "لا توجد حالة HTTP صالحة\n\n" ..
            "نوع المحتوى: " ..
            type(content) ..
            "\nالرد:\n" ..
            tostring(content):sub(1, 2000)
        )
    end

    if code < 200 or code >= 300 then
        error(
            "رفض السيرفر الطلب\n\n" ..
            "HTTP: " .. tostring(code) ..
            "\nالرد:\n" ..
            tostring(content):sub(1, 2000)
        )
    end

    if type(content) ~= "string" or content == "" then
        error(
            "السيرفر أعاد محتوى فارغًا\n" ..
            "HTTP: " .. tostring(code)
        )
    end

    return content
end


-- ============================================
-- DECODE
-- ============================================

local function decode_stage()

    gg.toast(
        "ᗷᗩᔕᗰᗩᒪᗩ ᗩᕼᘻᘿᕲ"
    )

    local encrypted =
        read_file(
            INPUT
        )

    gg.toast(
        "ᗷᗩᔕᗰᗩᒪᗩ ᗩᕼᘻᘿᕲ"
    )

    local decoded =
        post_file(
            DECODE_URL,
            encrypted
        )

    write_file(
        OUTPUT,
        decoded
    )

    gg.alert("✨💗 اللهم صل على  םבםב ﷺ💗✨"  )

    return decoded

end


-- ============================================
-- BUILD JSON
-- ============================================

local function build_edits_json(
    edits
)

    local parts = {}

    local regataCount = nil
    local regataPoint = nil


    -- ========================================
    -- أولاً: جمع Regata
    -- ========================================

    for _, edit in ipairs(edits) do

        if edit.type == "regataTaskCount" then

            regataCount =
                tonumber(
                    edit.value
                )

        elseif edit.type == "regataTaskPoint" then

            regataPoint =
                tonumber(
                    edit.value
                )

        end

    end


    -- ========================================
    -- بناء باقي التعديلات
    -- ========================================

    for _, edit in ipairs(edits) do

        if edit.type ~= "regataTaskCount" and
           edit.type ~= "regataTaskPoint" then

            local key =
                json_escape(
                    edit.type
                )

            local value =
                json_escape(
                    edit.value
                )

            table.insert(
                parts,
                '"' ..
                key ..
                '":"' ..
                value ..
                '"'
            )

        end

    end


    -- ========================================
    -- Regata
    -- ========================================

    if regataCount ~= nil or
       regataPoint ~= nil then

        if regataCount == nil then
            regataCount = 105
        end

        if regataPoint == nil then
            regataPoint = 135
        end

        table.insert(
            parts,
            '"regataTasks":{' ..
            '"taskCount":' ..
            tostring(
                math.floor(regataCount)
            ) ..
            ',' ..
            '"taskPoint":' ..
            tostring(
                math.floor(regataPoint)
            ) ..
            '}'
        )

    end


    return "{" ..
           table.concat(
               parts,
               ","
           ) ..
           "}"

end


-- ============================================
-- EDIT STAGE
-- ============================================

local function edit_stage(
    decoded
)

    local labels = {}
    local defaults = {}
    local types = {}


    for i, option in ipairs(OPTIONS) do

        labels[i] =
            option.label


        if option.type == "checkbox" then
            defaults[i] = false
        else
            defaults[i] = ""
        end


        types[i] =
            option.type

    end


    local input =
        gg.prompt(
            labels,
            defaults,
            types
        )


    if not input then

        return

    end


    -- ========================================
    -- COLLECT EDITS
    -- ========================================

    local edits = {}


    for i, option in ipairs(OPTIONS) do

    local value = input[i]

    if option.type == "checkbox" then

        -- لا تنفذ إلا الخيارات التي حددها المستخدم
        if value == true then

            table.insert(edits, {
                type = option.edit,
                value = true
            })

        end

    else

        -- لا تنفذ الحقول الرقمية والنصية الفارغة
        if value ~= nil and
           tostring(value) ~= "" then

            table.insert(edits, {
                type = option.edit,
                value = value
            })

        end

    end

end


    if #edits == 0 then

        gg.alert(
            "❌ لم يتم إدخال أي تعديل"
        )

        return

    end


    -- ========================================
    -- VALIDATE NUMBERS
    -- ========================================

    for _, edit in ipairs(edits) do

        if edit.type == "level" then

            local level =
                tonumber(
                    edit.value
                )

            if not level then

                gg.alert(
                    "❌ المستوى غير صحيح"
                )

                return

            end

            if level < 0 then

                gg.alert(
                    "❌ المستوى يجب أن يكون 0 أو أكبر"
                )

                return

            end

            edit.value =
                math.floor(
                    level
                )

        elseif edit.type == "regataTaskCount" then

            local count =
                tonumber(
                    edit.value
                )

            if not count then

                gg.alert(
                    "❌ عدد مهام السباق غير صحيح"
                )

                return

            end

            count =
                math.floor(
                    count
                )

            if count < 1 or
               count > 105 then

                gg.alert(
                    "❌ عدد مهام السباق يجب أن يكون بين 1 و 105"
                )

                return

            end

            edit.value =
                count


        elseif edit.type == "regataTaskPoint" then

            local point =
                tonumber(
                    edit.value
                )

            if not point then

                gg.alert(
                    "❌ نقاط السباق غير صحيحة"
                )

                return

            end

            point =
                math.floor(
                    point
                )

            if point < 1 or
               point > 135 then

                gg.alert(
                    "❌ نقاط المهمة يجب أن تكون بين 1 و 135"
                )

                return

            end

            edit.value =
                point

        end

    end


    -- ========================================
    -- EXECUTE
    -- ========================================

    gg.toast(
        "المرحلة 2/2\nجاري تنفيذ التعديلات..."
    )


    -- ========================================
    -- EXECUTE EDITS IN BATCHES
    -- إرسال جميع التعديلات بطلب واحد لتقليل التأخير.
    -- إذا ظهر خطأ متغير مفقود، احذف التعديل المرتبط به
    -- وأعد إرسال الباقي دفعة واحدة.
    -- ========================================

    local current_data = decoded
    local pending_edits = {}
    local applied_edits = {}
    local skipped_edits = {}

    for _, edit in ipairs(edits) do
        table.insert(pending_edits, edit)
    end

    local attempts = 0
    while #pending_edits > 0 and attempts <= #edits do
        attempts = attempts + 1
        local batch_json = build_edits_json(pending_edits)
        local url = EDIT_URL .. "?edits=" .. url_encode(batch_json)

        local ok, result = pcall(function()
            return post_file(url, current_data)
        end)

        if ok then
            current_data = result
            for _, edit in ipairs(pending_edits) do
                table.insert(applied_edits, edit)
            end
            pending_edits = {}
            break
        end

        local err_text = tostring(result)
        local missing_var = err_text:match("Var:%s*([%w_]+)")

        if not missing_var then
            error(err_text)
        end

        -- مطابقة اسم المتغير الوارد من السيرفر مع نوع التعديل.
        local missing_lower = string.lower(missing_var)
        local skipped_index = nil
        for i, edit in ipairs(pending_edits) do
            if string.lower(tostring(edit.type)):gsub("[^%w]", "") ==
               string.lower(missing_var):gsub("[^%w]", "") then
                skipped_index = i
                break
            end
        end

        if not skipped_index then
            -- إذا لم نتمكن من تحديد التعديل المرتبط بالمتغير،
            -- لا نتجاهل الخطأ عشوائيًا حتى لا نُفسد النتيجة.
            error(err_text)
        end

        local skipped = table.remove(pending_edits, skipped_index)
        table.insert(skipped_edits, {
            type = skipped.type,
            reason = "المتغير غير موجود: " .. missing_var
        })
        -- تعاد الدفعة المتبقية كلها في طلب واحد.
    end

    if #applied_edits == 0 then
        local details = "لم ينجح أي تعديل."
        if #skipped_edits > 0 then
            details = details .. "\nتم تخطي " .. #skipped_edits ..
                " تعديل/تعديلات بسبب متغيرات مفقودة."
        end
        error(details)
    end

    -- ========================================
    -- SAVE FINAL RESULT
    -- ========================================

    write_file(
        EDITED_OUTPUT,
        current_data
    )


    -- ========================================
    -- SUCCESS MESSAGE
    -- ========================================

local message =
        "تم تنفيذ التعديلات بنجاح ✔\n\n"


    for _, edit in ipairs(edits) do

        if edit.type == "level" then

            message =
                message ..
                "✔ المستوى: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "townName" then

            message =
                message ..
                "✔ اسم المدينة: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "achievementTeamwork" then

            message =
                message ..
                "✔ إنجاز التعاون: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "firstAttemptM3Levels" then

            message =
                message ..
                "✔ مستويات المحاولة الأولى: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "fullCardCollections" then

            message =
                message ..
                "✔ مجموعات البطاقات المكتملة: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "livesSent" then

            message =
                message ..
                "✔ الحيوات المرسلة: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "m3CompLvls" then

            message =
                message ..
                "✔ مستويات M3 المكتملة: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "regataTasksCompleted" then

            message =
                message ..
                "✔ مهام السباق المكتملة: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "regataTaskCount" then

            message =
                message ..
                "✔ عدد مهام السباق: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "regataTaskPoint" then

            message =
                message ..
                "✔ نقاط مهام السباق: " ..
                tostring(
                    edit.value
                ) ..
                "\n"


        elseif edit.type == "unlockedFrames" then

            message =
                message ..
                "✔ تم فتح الإطارات\n"


        elseif edit.type == "unlockedStyles" then

            message =
                message ..
                "✔ تم فتح الستايلات\n"


        elseif edit.type == "unlockedExpRanks" then

            message =
                message ..
                "✔ تم فتح رتب الخبرة\n"


        elseif edit.type == "unlockAllCards" then

            message =
                message ..
                "✔ تم إظهار الكروت 1 - 150 × 1000\n"


        elseif edit.type == "unlockLandExpansions" then

            message =
                message ..
                "✔ تم فتح جميع توسعات الأراضي\n"


        elseif edit.type == "unlockAllAvatars" then

            message =
                message ..
                "✔ تم فتح جميع الـAvatars\n"


        elseif edit.type == "chatEmojis" then

            message =
                message ..
                "✔ تم فتح جميع الملصقات (Stickers)\n"

        end

    end
    


    if #skipped_edits > 0 then
        message = message .. "\nالآن افتح اللعبة 🎮"
    end

    gg.alert(
        message
    )

end


-- Standalone runner removed; launcher calls this function.
return function()
    local ok, result = pcall(function()
        local decoded = decode_stage()
        edit_stage(decoded)
    end)
    if not ok then
        local err = tostring(result)
        if gg.copyText then gg.copyText(err, false) end
        gg.alert("❌ حدث خطأ أثناء العملية")
    end
end

]=]
-- CARDS
local SRC_CARDS = [=[
-- ============================================================
-- BS CARDS
-- ============================================================

local SERVER =
    "https://soft-flower-4528.alklharq40.workers.dev"

local DECODE_URL =
    SERVER .. "/api/decode"

local ANALYZE_URL =
    SERVER .. "/api/cards/analyze-files"

local SEND_URL =
    SERVER .. "/api/cards/send-all"

local BS_XML_PATH =
    MERGED_TOWNSHIP_BASE .. "LocalInfo.xml"

local CARDS_XML_PATH =
    MERGED_TOWNSHIP_BASE .. "mGameInfo.xml"


local CACHE = {
    ready = false,
    bsXml = nil,
    cardsXml = nil,
    friends = {},
    cards = {},
    analyzed = nil,
    currentFriend = nil
}


-- ============================================================
-- JSON
-- ============================================================

local function json_escape(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub('"', '\\"')
    s = s:gsub("\b", "\\b")
    s = s:gsub("\f", "\\f")
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\t", "\\t")
    return '"' .. s .. '"'
end


local function is_array(t)

    if type(t) ~= "table" then
        return false
    end

    local max = 0
    local count = 0

    for k in pairs(t) do

        if type(k) ~= "number" then
            return false
        end

        if k > max then
            max = k
        end

        count = count + 1
    end

    return max == 0 or count == max
end


local function json_encode(v)

    local t = type(v)

    if t == "nil" then
        return "null"
    end

    if t == "boolean" then
        return v and "true" or "false"
    end

    if t == "number" then

        if v ~= v or
            v == math.huge or
            v == -math.huge then

            return "null"
        end

        return tostring(v)
    end

    if t == "string" then
        return json_escape(v)
    end

    if t ~= "table" then
        return "null"
    end

    local out = {}

    if is_array(v) then

        for i = 1, #v do
            out[#out + 1] =
                json_encode(v[i])
        end

        return "[" ..
            table.concat(out, ",") ..
            "]"
    end

    for k, value in pairs(v) do

        out[#out + 1] =
            json_escape(k) ..
            ":" ..
            json_encode(value)
    end

    return "{" ..
        table.concat(out, ",") ..
        "}"
end


local function json_decode(str)

    if type(str) ~= "string" then
        return nil
    end

    if type(json) == "table" and
        type(json.decode) == "function" then

        local ok, value =
            pcall(json.decode, str)

        if ok then
            return value
        end
    end

    local pos = 1
    local len = #str

    local function skip()

        while pos <= len and
            str:sub(pos, pos):match("%s") do

            pos = pos + 1
        end
    end

    local parse_value

    local function string_value()

        if str:sub(pos, pos) ~= '"' then
            return nil
        end

        pos = pos + 1

        local out = {}

        while pos <= len do

            local c =
                str:sub(pos, pos)

            if c == '"' then

                pos = pos + 1
                return table.concat(out)
            end

            if c == "\\" then

                pos = pos + 1

                local e =
                    str:sub(pos, pos)

                local map = {
                    ['"'] = '"',
                    ['\\'] = '\\',
                    ['/'] = '/',
                    b = "\b",
                    f = "\f",
                    n = "\n",
                    r = "\r",
                    t = "\t"
                }

                if map[e] then

                    out[#out + 1] =
                        map[e]

                elseif e == "u" then

                    local h =
                        str:sub(
                            pos + 1,
                            pos + 4
                        )

                    local n =
                        tonumber(h, 16)

                    if not n then
                        return nil
                    end

                    if n < 128 then

                        out[#out + 1] =
                            string.char(n)

                    elseif n < 2048 then

                        out[#out + 1] =
                            string.char(
                                192 +
                                    math.floor(n / 64),
                                128 +
                                    n % 64
                            )

                    else

                        out[#out + 1] =
                            string.char(
                                224 +
                                    math.floor(n / 4096),
                                128 +
                                    (
                                        math.floor(n / 64)
                                        % 64
                                    ),
                                128 +
                                    n % 64
                            )
                    end

                    pos = pos + 4

                else
                    return nil
                end

                pos = pos + 1

            else

                out[#out + 1] = c
                pos = pos + 1
            end
        end

        return nil
    end


    local function number_value()

        local start = pos

        while pos <= len and
            str:sub(pos, pos):match(
                "[%d%+%-%e%E%.]"
            ) do

            pos = pos + 1
        end

        return tonumber(
            str:sub(start, pos - 1)
        )
    end


    local function array_value()

        pos = pos + 1

        local out = {}

        skip()

        if str:sub(pos, pos) == "]" then

            pos = pos + 1
            return out
        end

        while pos <= len do

            local value =
                parse_value()

            if value == nil then
                return nil
            end

            out[#out + 1] = value

            skip()

            if str:sub(pos, pos) == "]" then

                pos = pos + 1
                return out
            end

            if str:sub(pos, pos) ~= "," then
                return nil
            end

            pos = pos + 1
            skip()
        end

        return nil
    end


    local function object_value()

        pos = pos + 1

        local out = {}

        skip()

        if str:sub(pos, pos) == "}" then

            pos = pos + 1
            return out
        end

        while pos <= len do

            skip()

            local key =
                string_value()

            if not key then
                return nil
            end

            skip()

            if str:sub(pos, pos) ~= ":" then
                return nil
            end

            pos = pos + 1
            skip()

            out[key] =
                parse_value()

            skip()

            if str:sub(pos, pos) == "}" then

                pos = pos + 1
                return out
            end

            if str:sub(pos, pos) ~= "," then
                return nil
            end

            pos = pos + 1
        end

        return nil
    end


    parse_value = function()

        skip()

        local c =
            str:sub(pos, pos)

        if c == '"' then
            return string_value()
        end

        if c == "{" then
            return object_value()
        end

        if c == "[" then
            return array_value()
        end

        if str:sub(pos, pos + 3) == "true" then

            pos = pos + 4
            return true
        end

        if str:sub(pos, pos + 4) == "false" then

            pos = pos + 5
            return false
        end

        if str:sub(pos, pos + 3) == "null" then

            pos = pos + 4
            return nil
        end

        return number_value()
    end


    local result =
        parse_value()

    skip()

    if pos <= len then
        return nil
    end

    return result
end


-- ============================================================
-- FILE
-- ============================================================

local function read_file(path)

    local f, err =
        io.open(path, "rb")

    if not f then

        return nil,
            "لا يمكن فتح الملف"
    end

    local data =
        f:read("*a")

    f:close()

    if not data or #data == 0 then

        return nil,
            "الملف فارغ"
    end

    return data
end


-- ============================================================
-- HTTP
-- ============================================================

local function post(
    url,
    body,
    contentType
)

    local r =
        gg.makeRequest(
            url,
            {
                ["Content-Type"] =
                    contentType or
                    "application/json; charset=utf-8",

                ["Accept"] = "*/*",

                ["User-Agent"] =
                    "Mozilla/5.0",

                ["Cache-Control"] =
                    "no-cache"
            },
            body
        )

    if not r then
        return nil,
            "لم تصل استجابة من السيرفر."
    end

    local code =
        tonumber(r.code or 0) or 0

    local content =
        tostring(r.content or "")

    if code < 200 or code >= 300 then

        return nil,
            "HTTP Error: " ..
            tostring(code) ..
            "\n\n" ..
            content
    end

    return content
end


-- ============================================================
-- ERROR
-- ============================================================

local function show_error(
    title,
    message
)

    local text =
        "❌ " ..
        tostring(title) ..
        "\n\n" ..
        tostring(message)

    local c =
        gg.alert(
            text,
            "📋 نسخ",
            "إغلاق"
        )

    if c == 1 then
        gg.copyText(
            text,
            true
        )
    end
end


-- ============================================================
-- DECODE
-- ============================================================

local function decode_file(
    data,
    fileName
)

    if not data or #data == 0 then

        return nil,
            "الملف فارغ: " ..
            tostring(fileName)
    end

    local decoded, err =
        post(
            DECODE_URL,
            data,
            "application/octet-stream"
        )

    if not decoded then

        return nil,
            "فشل فك تشفير " ..
            tostring(fileName) ..
            "\n\n" ..
            tostring(err)
    end

    if #decoded == 0 then

        return nil,
            "السيرفر أعاد ملفًا فارغًا: " ..
            tostring(fileName)
    end

    return decoded
end


-- ============================================================
-- ANALYZE
-- ============================================================

local function analyze(
    bsXml,
    cardsXml
)

    local response, err =
        post(
            ANALYZE_URL,
            json_encode({
                friendsXml = bsXml,
                cardsXml = cardsXml
            }),
            "application/json; charset=utf-8"
        )

    if not response then
        return nil, err
    end

    local data =
        json_decode(response)

    if type(data) ~= "table" then

        return nil,
            "استجابة التحليل غير صالحة."
    end

    if data.ok == false then

        return nil,
            tostring(
                data.error or
                "فشل تحليل الملفات."
            )
    end

    return data
end


-- ============================================================
-- INITIALIZE
-- ============================================================

local function initialize()

    if CACHE.ready then
        return true
    end

    local encryptedBs, e1 =
        read_file(
            BS_XML_PATH
        )

    if not encryptedBs then

        show_error(
            "قراءة الملف الأول",
            e1
        )

        return false
    end

    local encryptedCards, e2 =
        read_file(
            CARDS_XML_PATH
        )

    if not encryptedCards then

        show_error(
            "قراءة الملف الثاني",
            e2
        )

        return false
    end

    local bsXml, e3 =
        decode_file(
            encryptedBs,
            ".1bs.xml"
        )

    if not bsXml then

        show_error(
            "فك التشفير",
            e3
        )

        return false
    end

    local cardsXml, e4 =
        decode_file(
            encryptedCards,
            "mGameInfo.xml"
        )

    if not cardsXml then

        show_error(
            "فك التشفير",
            e4
        )

        return false
    end

    local analyzed, e5 =
        analyze(
            bsXml,
            cardsXml
        )

    if not analyzed then

        show_error(
            "التحليل",
            e5
        )

        return false
    end

    CACHE.bsXml =
        bsXml

    CACHE.cardsXml =
        cardsXml

    CACHE.analyzed =
        analyzed

    CACHE.friends =
        analyzed.friends or {}

    CACHE.cards =
        analyzed.cards or {}

    CACHE.ready =
        true

    return true
end


-- ============================================================
-- FRIEND
-- ============================================================

local function choose_friend()

    if type(CACHE.friends) ~= "table" or
        #CACHE.friends == 0 then

        show_error(
            "الأصدقاء",
            "لم يتم العثور على أصدقاء."
        )

        return nil
    end

    local labels = {}

    for i, f in ipairs(CACHE.friends) do

        local name =
            tostring(f.name or "")

        local id =
            tostring(f.id or "")

        if name == "" then
            name =
                "Friend " ..
                tostring(i)
        end

        labels[#labels + 1] =
            tostring(i) ..
            ". " ..
            name ..
            " [" ..
            id ..
            "]"
    end

    local choice =
        gg.choice(
            labels,
            nil,
            "👤 اختر الصديق"
        )

    if not choice then
        return nil
    end

    local f =
        CACHE.friends[choice]

    CACHE.currentFriend = {

        id =
            tostring(f.id or ""),

        name =
            tostring(f.name or ""),

        pic =
            tostring(f.pic or "")
    }

    return CACHE.currentFriend
end


-- ============================================================
-- GROUPS
-- ============================================================

local function build_card_groups()

    local groups = {}

    for _, card in ipairs(CACHE.cards) do

        local cardId =
            tostring(
                card.cardId or
                card.id or
                ""
            )

        local number =
            tonumber(
                cardId:match(
                    "^card_(%d+)$"
                )
            )

        if number then

            local groupNumber =
                math.floor(
                    (number - 1) / 10
                ) + 1

            if not groups[groupNumber] then

                groups[groupNumber] = {
                    number = groupNumber,
                    cards = {}
                }
            end

            groups[groupNumber].cards[
                #groups[groupNumber].cards + 1
            ] = {
                cardId = cardId,
                number = number,
                count =
                    tonumber(
                        card.count or 0
                    ) or 0
            }
        end
    end

    return groups
end


local function choose_card_groups()

    local groups =
        build_card_groups()

    local groupNumbers = {}

    for number in pairs(groups) do
        groupNumbers[#groupNumbers + 1] =
            number
    end

    table.sort(groupNumbers)

    if #groupNumbers == 0 then
        -- لا توجد بطاقات متاحة؛ الرجوع بهدوء دون إظهار رسالة خطأ.
        return nil
    end

    local labels = {}

    for _, groupNumber in ipairs(
        groupNumbers
    ) do

        local group =
            groups[groupNumber]

        local first =
            (groupNumber - 1) * 10 + 1

        local last =
            groupNumber * 10

        labels[#labels + 1] =
            "📦 المجموعة " ..
            tostring(groupNumber) ..
            " | card_" ..
            tostring(first) ..
            " → card_" ..
            tostring(last) ..
            " | " ..
            tostring(#group.cards) ..
            " بطاقة"
    end

    local selected =
        gg.multiChoice(
            labels,
            nil,
            "🃏 اختر المجموعات"
        )

    if not selected then
        return nil
    end

    local selectedGroups = {}
    local allCardIds = {}

    for index, checked in pairs(
        selected
    ) do

        if checked then

            local groupNumber =
                groupNumbers[index]

            local group =
                groups[groupNumber]

            if group then

                selectedGroups[
                    #selectedGroups + 1
                ] = group

                for _, card in ipairs(
                    group.cards
                ) do

                    allCardIds[
                        #allCardIds + 1
                    ] =
                        card.cardId
                end
            end
        end
    end

    if #selectedGroups == 0 then
        return nil
    end

    table.sort(
        selectedGroups,
        function(a, b)
            return a.number < b.number
        end
    )

    return {
        groups = selectedGroups,
        cardIds = allCardIds
    }
end


-- ============================================================
-- SEND
-- ============================================================

local function send_selected(
    friend,
    cardIds
)

    -- لا ترسل طلبًا إذا لم يختر المستخدم أي بطاقة.
    if type(cardIds) ~= "table" or #cardIds == 0 then
        return nil, "NO_CARDS_SELECTED"
    end

    local response, err =
        post(
            SEND_URL,
            json_encode({

                friendsXml =
                    CACHE.bsXml,

                cardsXml =
                    CACHE.cardsXml,

                friend =
                    friend,

                cardIds =
                    cardIds
            }),
            "application/json; charset=utf-8"
        )

    if not response then
        return nil, err
    end

    local data =
        json_decode(response)

    if type(data) ~= "table" then

        return nil,
            "استجابة الإرسال غير صالحة."
    end

    return data
end


-- ============================================================
-- GROUP SUMMARY
-- ============================================================

local function groups_summary(selected)

    local lines = {}

    for _, group in ipairs(
        selected.groups
    ) do

        local first =
            (group.number - 1) * 10 + 1

        local last =
            group.number * 10

        lines[#lines + 1] =
            "📦 المجموعة " ..
            tostring(group.number) ..
            " | card_" ..
            tostring(first) ..
            " → card_" ..
            tostring(last)
    end

    return table.concat(
        lines,
        "\n"
    )
end


-- ============================================================
-- RESULT
-- ============================================================

local function show_result(
    result,
    selected
)

    local sent =
        tonumber(
            result.sentCards or 0
        ) or 0

    local failed =
        tonumber(
            result.failed or 0
        ) or 0

    local total =
        tonumber(
            result.totalCards or
            #selected.cardIds
        ) or
        #selected.cardIds

    gg.alert(
        "📊 النتيجة\n\n" ..
        "📤 نجح: " ..
        tostring(sent) ..

        "\n❌ فشل: " ..
        tostring(failed) ..

        "\n📦 الإجمالي: " ..
        tostring(total)
    )
end


-- ============================================================
-- CARD MENU
-- ============================================================

-- ============================================================
-- CARD MENU
-- ============================================================

local function card_menu(friend)

    while true do

        local selected =
            choose_card_groups()

        if selected then

            local confirm =
                gg.alert(
                    "👤 " ..
                    tostring(
                        friend.name ~= "" and
                        friend.name or
                        friend.id
                    ) ..

                    "\n\n" ..
                    groups_summary(selected) ..

                    "\n\n📦 إجمالي البطاقات: " ..
                    tostring(#selected.cardIds) ..

                    "\n\nهل تريد الإرسال؟",

                    "📤 إرسال",
                    "رجوع"
                )

            if confirm == 1 then

                local result, err =
                    send_selected(
                        friend,
                        selected.cardIds
                    )

                if not result then
                    if err ~= "NO_CARDS_SELECTED" then
                        show_error(
                            "الإرسال",
                            err
                        )
                    end

                else

                    show_result(
                        result,
                        selected
                    )
                end
            end

        else
            -- المستخدم لم يختر أي مجموعة أو ألغى الاختيار؛ ارجع بهدوء.
            return "friends"
        end
    end
end


-- ============================================================
-- FRIEND MENU
-- ============================================================

local function friend_menu()

    while true do

        local friend =
            choose_friend()

        if not friend then
            return
        end

        local result =
            card_menu(friend)

        if result == "friends" then
            -- العودة لقائمة الأصدقاء
        end
    end
end


-- ============================================================
-- MAIN
-- ============================================================

-- ============================================================
-- MAIN
-- ============================================================

local function main()

    if not CACHE.ready then

        local ok =
            initialize()

        if not ok then
            return false
        end
    end

    while true do

        local menu =
            gg.choice(
                {
                    "👤 قائمة الأصدقاء",
                    "❌ إغلاق السكربت"
                },
                nil,
                "🃏 BS CARDS"
            )

        if menu == 1 then

            friend_menu()

        elseif menu == 2 or menu == nil then

            return true
        end
    end
end


-- Standalone GameGuardian loop removed; launcher calls main().
return main

]=]
-- LEVEL
local SRC_LEVEL = [=[
-- LEVEL 1 DOWNLOADER
local function OMG1()
    local savePath = _G.MERGED_TOWNSHIP_BASE
    if not savePath or savePath == "" then
        savePath = "/data/data/com.playrix.township/saves/"
    end
    if not savePath:match("/$") then
        savePath = savePath .. "/"
    end

    local files = {
        {
            url = "https://b-servers.qdmasnmdy.workers.dev/mGameInfo.xml",
            names = {
                "mGameInfo.xml",
                "mGameInfo.bak"
            }
        },
        {
            url = "https://b-servers.qdmasnmdy.workers.dev/LocalInfo.xml",
            names = {
                "LocalInfo.xml"
            }
        }
    }

    for _, item in ipairs(files) do
        local response = gg.makeRequest(
            item.url,
            {
                ["X-Garden-Download"] = "1"
            }
        )

        if not response
            or tonumber(response.code or 0) < 200
            or tonumber(response.code or 0) >= 300
            or not response.content
            or response.content == "" then
            gg.alert("⛔ فشل تحميل البيانات")
            return
        end

        for _, name in ipairs(item.names) do
            local fullPath = savePath .. name
            local f = io.open(fullPath, "wb")

            if not f then
                gg.alert("⛔ تعذر حفظ الملف")
                return
            end

            local okWrite = pcall(function()
                f:write(response.content)
                f:flush()
                f:close()
            end)

            if not okWrite then
                gg.alert("⛔ تعذر حفظ الملف")
                return
            end

            local check = io.open(fullPath, "rb")
            local saved = check and check:read("*a") or nil
            if check then check:close() end

            if not saved or saved ~= response.content then
                gg.alert("⛔ لم يتم التحقق من حفظ الملف")
                return
            end
        end
    end

gg.alert("🌺 تم اعادة المدينة الى مستوى 1 🌺")
end
return OMG1

]=]
-- COPIER
local SRC_COPIER = [=[
-- Shared environment supplied by the unified launcher
local SERVER_BASE = "https://soft-flower-4528.alklharq40.workers.dev/api"
local DECODE_FRIENDS_URL = SERVER_BASE .. "/decode-friends"
local FETCH_CITY_URL = SERVER_BASE .. "/fetch-city"
local VIRTUAL_PACKAGE = _G.MERGED_PACKAGE
local VIRTUAL_BASE = _G.MERGED_BASE
local TOWNSHIP_BASE = _G.MERGED_TOWNSHIP_BASE
local XML_FILE = TOWNSHIP_BASE .. "LocalInfo.xml"
local OUTPUT_DIR = TOWNSHIP_BASE
local OUTPUT_FILE = "mGameInfo.xml"
local OUTPUT_PATH = OUTPUT_DIR .. OUTPUT_FILE

-- الملفات
--------------------------------------------------

local XML_FILE =
    TOWNSHIP_BASE ..
    "LocalInfo.xml"

local OUTPUT_DIR =
    TOWNSHIP_BASE

local OUTPUT_FILE =
    "mGameInfo.xml"

local OUTPUT_PATH =
    OUTPUT_DIR ..
    OUTPUT_FILE

--------------------------------------------------
-- عرض المسار بعد اختيار البيئة
--------------------------------------------------

--------------------------------------------------
-- الرسائل
--------------------------------------------------

local function alert(msg)
    -- لا تظهر أي رسالة أثناء العملية
end

local function toast(msg)
    -- لا تظهر أي رسالة أثناء العملية
end

--------------------------------------------------
-- نسخ الخطأ بدون إظهاره
--------------------------------------------------

local function copyError(text)
    text = tostring(text or "")
    if gg.copyText then
        gg.copyText(text, false)
    end
end

--------------------------------------------------
-- قراءة الملف
--------------------------------------------------

local function readFile(path)

    local f =
        io.open(
            path,
            "rb"
        )

    if not f then
        return nil
    end

    local data =
        f:read(
            "*a"
        )

    f:close()

    return data

end

--------------------------------------------------
-- حفظ الملف
--------------------------------------------------

local function saveFile(
    path,
    data
)

    local f =
        io.open(
            path,
            "wb"
        )

    if not f then
        return false
    end

    local okWrite = pcall(function()
        f:write(data)
        f:flush()
        f:close()
    end)

    if not okWrite then
        return false
    end

    local check = io.open(path, "rb")
    local saved = check and check:read("*a") or nil
    if check then
        check:close()
    end

    return saved ~= nil and saved == data

end

--------------------------------------------------
-- JSON Unescape
--------------------------------------------------

local function jsonUnescape(s)

    s =
        tostring(
            s or ""
        )

    s =
        s:gsub(
            '\\"',
            '"'
        )

    s =
        s:gsub(
            "\\/",
            "/"
        )

    s =
        s:gsub(
            "\\\\",
            "\\"
        )

    s =
        s:gsub(
            "\\n",
            "\n"
        )

    s =
        s:gsub(
            "\\r",
            "\r"
        )

    s =
        s:gsub(
            "\\t",
            "\t"
        )

    return s

end

--------------------------------------------------
-- استخراج قيمة JSON نصية
--------------------------------------------------

local function jsonValue(
    object,
    key
)

    local pattern =
        '"' ..
        key ..
        '"%s*:%s*"([^"]*)"'

    local value =
        object:match(
            pattern
        )

    if value then

        return jsonUnescape(
            value
        )

    end

    return ""

end

--------------------------------------------------
-- استخراج قيمة JSON رقمية
--------------------------------------------------

local function jsonNumberValue(
    object,
    key
)

    local pattern =
        '"' ..
        key ..
        '"%s*:%s*(-?%d+)'

    local value =
        object:match(
            pattern
        )

    if value then
        return tostring(value)
    end

    return ""

end

--------------------------------------------------
-- تحليل friends
--------------------------------------------------

local function parseFriendsJson(
    content
)

    local friends = {}

    local friendsBlock =
        content:match(
            '"friends"%s*:%s*%[(.-)%]%s*,%s*"saveProfiles"'
        )

    if not friendsBlock then

        friendsBlock =
            content:match(
                '"friends"%s*:%s*%[(.*)%]%s*}'
            )

    end

    if not friendsBlock then
        return friends
    end

    for object in
        friendsBlock:gmatch(
            "{(.-)}"
        )
    do

        local city_id =
            jsonValue(
                object,
                "city_id"
            )

        if city_id ~= "" then

            local fetched_city_ver =
                jsonValue(
                    object,
                    "fetched_city_ver"
                )

            if fetched_city_ver == "" then
                fetched_city_ver =
                    jsonNumberValue(
                        object,
                        "fetched_city_ver"
                    )
            end

            if fetched_city_ver == "" then
                fetched_city_ver =
                    jsonValue(
                        object,
                        "city_ver"
                    )
            end

            if fetched_city_ver == "" then
                fetched_city_ver =
                    jsonNumberValue(
                        object,
                        "city_ver"
                    )
            end

            friends[#friends + 1] = {

                city_id =
                    city_id,

                city_name =
                    jsonValue(
                        object,
                        "city_name"
                    ),

                name =
                    jsonValue(
                        object,
                        "name"
                    ),

                level =
                    jsonValue(
                        object,
                        "level"
                    ),

                xp =
                    jsonValue(
                        object,
                        "xp"
                    ),

                likes =
                    jsonValue(
                        object,
                        "likes"
                    ),

                lang =
                    jsonValue(
                        object,
                        "lang"
                    ),

                flw =
                    jsonValue(
                        object,
                        "flw"
                    ),

                help =
                    jsonValue(
                        object,
                        "help"
                    ),

                fetched_city_ver =
                    fetched_city_ver,

                bc =
                    jsonValue(
                        object,
                        "bc"
                    )
            }

        end

    end

    return friends

end

--------------------------------------------------
-- تحليل Save Profiles
--------------------------------------------------

local function parseSaveProfilesJson(
    content
)

    local profiles = {}

    local profilesBlock =
        content:match(
            '"saveProfiles"%s*:%s*%[(.*)%]%s*}'
        )

    if not profilesBlock then
        return profiles
    end

    for object in
        profilesBlock:gmatch(
            "{(.-)}"
        )
    do

        local saveId =
            jsonValue(
                object,
                "saveId"
            )

        if saveId ~= "" then

            local cityname =
                jsonValue(
                    object,
                    "cityname"
                )

            local level =
                jsonNumberValue(
                    object,
                    "level"
                )

            if level == "" then

                level =
                    jsonValue(
                        object,
                        "level"
                    )

            end

            profiles[#profiles + 1] = {

                cityname =
                    cityname,

                level =
                    level,

                saveId =
                    saveId
            }

        end

    end

    return profiles

end

--------------------------------------------------
-- تنظيف النص للبحث
--------------------------------------------------

local function normalizeSearch(
    value
)

    value =
        tostring(
            value or ""
        )

    value =
        value:lower()

    value =
        value:gsub(
            "^%s+",
            ""
        )

    value =
        value:gsub(
            "%s+$",
            ""
        )

    return value

end

--------------------------------------------------
-- استخراج المستوى
--------------------------------------------------

local function getLevel(
    item
)

    local level =
        tonumber(
            item.level
        )

    if level then
        return level
    end

    return 0

end

--------------------------------------------------
-- ترتيب من الأعلى إلى الأقل
--------------------------------------------------

local function sortByLevel(
    list
)

    table.sort(
        list,
        function(a, b)

            local levelA =
                getLevel(a)

            local levelB =
                getLevel(b)

            if levelA ~= levelB then

                return levelA >
                    levelB

            end

            local nameA =
                normalizeSearch(
                    a.displayName or
                    a.name or
                    a.cityname or
                    a.city_name or
                    ""
                )

            local nameB =
                normalizeSearch(
                    b.displayName or
                    b.name or
                    b.cityname or
                    b.city_name or
                    ""
                )

            return nameA <
                nameB

        end
    )

    return list

end

--------------------------------------------------
-- إدخال البحث
--------------------------------------------------

local function askSearch()

    local input =
        gg.prompt(
            {
                "🔍 اكتب اسم المدينة أو المستوى"
            },
            {
                ""
            },
            {
                "text"
            }
        )

    if not input then
        return nil
    end

    local text =
        tostring(
            input[1] or ""
        )

    text =
        text:gsub(
            "^%s+",
            ""
        )

    text =
        text:gsub(
            "%s+$",
            ""
        )

    if text == "" then
        return ""
    end

    return text

end

--------------------------------------------------
-- دمج friends + saveProfiles
--------------------------------------------------

local function buildUnifiedList(
    data
)

    local list = {}

    for _, friend in
        ipairs(
            data.friends
        )
    do

        local displayName

        if
            friend.name and
            friend.name ~= ""
        then

            displayName =
                friend.name

        elseif
            friend.city_name and
            friend.city_name ~= ""
        then

            displayName =
                friend.city_name

        else

            displayName =
                "مدينة"

        end

        list[#list + 1] = {

            source =
                "city",

            cityId =
                tostring(
                    friend.city_id or ""
                ),

            cityVer =
                tonumber(
                    friend.fetched_city_ver
                ) or 0,

            displayName =
                displayName,

            level =
                friend.level or "",

            originalCityId =
                friend.city_id or "",

            saveId =
                ""

        }

    end

    for _, profile in
        ipairs(
            data.saveProfiles
        )
    do

        local displayName =
            profile.cityname

        if
            not displayName or
            displayName == ""
        then

            displayName =
                "مدينة"

        end

        list[#list + 1] = {

            source =
                "save",

            cityId =
                tostring(
                    profile.saveId or ""
                ),

            cityVer =
                0,

            displayName =
                displayName,

            level =
                profile.level or "",

            originalCityId =
                "",

            saveId =
                profile.saveId or ""

        }

    end

    return list

end

--------------------------------------------------
-- البحث
--------------------------------------------------

local function searchUnified(
    items,
    searchText
)

    local result = {}

    local query =
        normalizeSearch(
            searchText
        )

    if query == "" then

        for _, item in
            ipairs(items)
        do

            result[#result + 1] =
                item

        end

        return result

    end

    for _, item in
        ipairs(items)
    do

        local name =
            normalizeSearch(
                item.displayName
            )

        local level =
            normalizeSearch(
                item.level
            )

        local cityId =
            normalizeSearch(
                item.cityId
            )

        if
            name:find(
                query,
                1,
                true
            )
            or
            level:find(
                query,
                1,
                true
            )
            or
            cityId:find(
                query,
                1,
                true
            )
        then

            result[#result + 1] =
                item

        end

    end

    return result

end

--------------------------------------------------
-- اختيار المدينة
--------------------------------------------------

local function chooseCity(
    data
)

    local allItems =
        buildUnifiedList(
            data
        )

    if #allItems == 0 then
        return nil
    end

    sortByLevel(
        allItems
    )

    local currentList =
        allItems

    while true do

        local menu = {}

        menu[#menu + 1] =
            "🔍 بحث عن اسم أو مستوى"

        for _, item in
            ipairs(
                currentList
            )
        do

            local name =
                item.displayName

            if
                not name or
                name == ""
            then

                name =
                    "مدينة"

            end

            local level =
                item.level

            if
                not level or
                level == ""
            then

                level =
                    "؟"

            end

            menu[#menu + 1] =
                "👤 " ..
                tostring(
                    name
                ) ..

                "  [Lv." ..
                tostring(
                    level
                ) ..
                "]" ..

                "\n🏙️ City ID"

        end

        local title

        if
            #currentList ==
            #allItems
        then

            title =
                "🏙️ City ID\n" ..
                "⬇️ الترتيب: الأعلى مستوى"

        else

            title =
                "🔍 نتائج البحث\n" ..
                "🏙️ City ID"

        end

        local choice =
            gg.choice(
                menu,
                nil,
                title
            )

        if not choice then
            return nil
        end

        if choice == 1 then

            local searchText =
                askSearch()

            if searchText == nil then
                return nil
            end

            if searchText == "" then

                currentList =
                    allItems

            else

                currentList =
                    searchUnified(
                        allItems,
                        searchText
                    )

            end

            sortByLevel(
                currentList
            )

        else

            local selected =
                currentList[
                    choice - 1
                ]

            if not selected then
                return nil
            end

            return selected

        end

    end

end

--------------------------------------------------
-- رفع الملف للسيرفر وفكه
--------------------------------------------------

local function decodeFriends()

    local data =
        readFile(
            XML_FILE
        )

    if not data then

        copyError(
            "❌ لم يتم العثور على الملف\n\n" ..
            XML_FILE
        )

        return nil

    end

    if #data == 0 then

        copyError(
            "❌ الملف فارغ"
        )

        return nil

    end

    local response =
        gg.makeRequest(
            DECODE_FRIENDS_URL,
            {
                ["Content-Type"] =
                    "application/octet-stream"
            },
            data
        )

    if not response then

        copyError(
            "❌ تعذر الاتصال بالسيرفر"
        )

        return nil

    end

    if response.code ~= 200 then

        local content =
            tostring(
                response.content or ""
            )

        copyError(
            "❌ فشل فك ملف المدن\n\n" ..
            "HTTP: " ..
            tostring(
                response.code
            ) ..
            "\n\n" ..
            content
        )

        return nil

    end

    local content =
        tostring(
            response.content or ""
        )

    if content == "" then

        copyError(
            "❌ السيرفر أعاد استجابة فارغة"
        )

        return nil

    end

    local ok =
        content:match(
            '"ok"%s*:%s*true'
        )

    if not ok then

        copyError(
            "❌ السيرفر لم يستطع فك الملف\n\n" ..
            content
        )

        return nil

    end

    local friends =
        parseFriendsJson(
            content
        )

    local saveProfiles =
        parseSaveProfilesJson(
            content
        )

    if
        #friends == 0 and
        #saveProfiles == 0
    then

        copyError(
            "❌ لم يجد السيرفر أي بيانات"
        )

        return nil

    end

    return {

        friends =
            friends,

        saveProfiles =
            saveProfiles

    }

end

--------------------------------------------------
-- Escape JSON
--------------------------------------------------

local function escapeJson(
    value
)

    value =
        tostring(
            value or ""
        )

    value =
        value:gsub(
            "\\",
            "\\\\"
        )

    value =
        value:gsub(
            '"',
            '\\"'
        )

    value =
        value:gsub(
            "\n",
            "\\n"
        )

    value =
        value:gsub(
            "\r",
            "\\r"
        )

    return value

end

--------------------------------------------------
-- بناء طلب FetchCity
--------------------------------------------------

local function buildRequest(
    selected
)

    return {

        cityId =
            tostring(
                selected.cityId
            ),

        cityVer =
            tonumber(
                selected.cityVer
            ) or 0

    }

end

--------------------------------------------------
-- طلب FetchCity
--------------------------------------------------

local function requestFetchCity(
    request
)

    local payload =
        string.format(
            '{"cityId":"%s","cityVer":%s}',
            escapeJson(
                request.cityId
            ),
            tostring(
                request.cityVer
            )
        )

    local response =
        gg.makeRequest(
            FETCH_CITY_URL,
            {
                ["Content-Type"] =
                    "application/json"
            },
            payload
        )

    if not response then

        return nil,
            "❌ تعذر الاتصال بالسيرفر"

    end

    if response.code ~= 200 then

        local content =
            tostring(
                response.content or ""
            )

        return nil,
            "❌ HTTP " ..
            tostring(
                response.code
            ) ..
            "\n\n" ..
            content

    end

    if not response.content then

        return nil,
            "❌ السيرفر أعاد Response فارغ"

    end

    return response.content,
        nil

end

--------------------------------------------------
-- جلب المدينة وحفظها
--------------------------------------------------

local function fetchOne(
    selected
)

    local request =
        buildRequest(
            selected
        )

    local xml, err =
        requestFetchCity(
            request
        )

    if not xml then

        copyError(
            tostring(
                err or
                "❌ فشل FetchCity"
            )
        )

        return false

    end

    xml =
        tostring(
            xml
        )

    xml =
        xml:gsub(
            "^\239\187\191",
            ""
        )

    xml =
        xml:match(
            "^%s*(.-)%s*$"
        )

    if not xml or xml == "" then

        copyError(
            "❌ السيرفر أعاد XML فارغًا"
        )

        return false

    end

    if not xml:match(
        "^<root"
    ) then

        copyError(
            "❌ السيرفر لم يُرجع XML\n\n" ..
            xml:sub(
                1,
                5000
            )
        )

        return false

    end

    if not xml:match(
        "</root>%s*$"
    ) then

        copyError(
            "⚠️ XML غير مكتمل\n\n" ..
            xml:sub(
                math.max(
                    1,
                    #xml - 5000
                )
            )
        )

        return false

    end

    local filename =
        OUTPUT_FILE

    local path =
        OUTPUT_DIR ..
        filename

    if not saveFile(
        path,
        xml
    ) then

        copyError(
            "❌ فشل حفظ البيانات"
        )

        return false

    end

    gg.alert(
        "🔥 تم النسخ"
    )

    return true

end

--------------------------------------------------
-- FARM PICKER AND RUNNER
local function selectFarm()
    local data = decodeFriends()
    if not data then return nil end
    local selected = chooseCity(data)
    if not selected or not selected.cityId or selected.cityId == "" then return nil end
    return selected
end

local function runFarm(selected)
    return fetchOne(selected)
end

return { select = selectFarm, run = runFarm }

]=]

local function run_source(src, label)
    local chunk, err = load(src, label)

    if not chunk then
        gg.alert("❌ خطأ تحميل الكود:\n\n" .. tostring(err))
        return
    end

    local ok, result = pcall(chunk)

    if not ok then
        gg.alert("❌ خطأ تشغيل الأداة:\n\n" .. tostring(result))
        return
    end

    if type(result) == "function" then
        local ok2, err2 = pcall(result)

        if not ok2 then
            gg.alert(
                "❌ خطأ تنفيذ الأداة:\n\n" ..
                tostring(err2)
            )
        end
    end
end

while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        local choice=gg.choice({
'【✦】 النسخ 【✦】',
'【✦】 ملف خاص بالتعديل والسباق 【✦】',
'【✦】 🃏 إرسال الكروت 【✦】',
'【✦】 مدينة جديدة 【✦】',
'【✦】 ❌ خروج 【✦】'
        },nil,' ༺♥༻ 𝔹𝕒𝕤𝕞𝕒𝕝𝕒 × 𝕊𝕒𝕙𝕖𝕣 ༺♥༻')
        if choice==1 then
            local copierChunk = load(SRC_COPIER, 'النسخ من الناسخ')
            if not copierChunk then
                gg.alert('❌ تعذر تحميل الناسخ')
            else
                local copierOk, copierApp = pcall(copierChunk)
                if not copierOk or type(copierApp) ~= 'table' then
                    gg.alert('❌ تعذر تهيئة الناسخ')
                else
                    local selectedFarm = copierApp.select()
                    if selectedFarm then copierApp.run(selectedFarm) end
                end
            end
        elseif choice==2 then run_source(SRC_TOOL,'ملف خاص بالتعديل والسباق ')
        elseif choice==3 then run_source(SRC_CARDS,'إرسال الكروت')
        elseif choice==4 then run_source(SRC_LEVEL,'تفعيل مستوى 1')
        elseif choice==5 then
            gg.setVisible(true)
            break
        end
    end
    gg.sleep(100)
    end
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
✦ اداة سنة اولى تطوير ✦
━━━━━━━━━━━━━━━━
✓ tool Finished
✓ Thanks For Using

「 See You Again ♡ 」
━━━━━━━━━━━━━━━━
]])


