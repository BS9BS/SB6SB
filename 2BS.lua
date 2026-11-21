local REQUIRED_ENVIRONMENT_PACKAGE = "com.ssssbbbb"

if gg.PACKAGE ~= REQUIRED_ENVIRONMENT_PACKAGE then
    gg.alert("⚠️ اختر الناسخ الذي تعمل به وليس برامج او اللعاب اخرى")
    return
end

if gg.PACKAGE == REQUIRED_ENVIRONMENT_PACKAGE then
local LICENSE_SERVER = "https://bs-service.onrender.com"
local CHECK_URL = LICENSE_SERVER .. "/api/check"

local SAVE_ID_FILE   = "/storage/emulated/0/Download/.gg_install_id.txt"
local SAVE_KEY_FILE  = "/storage/emulated/0/Download/.gg_license_key.txt"
local SAVE_LAST_FILE = "/storage/emulated/0/Download/.gg_last_run.txt"
local TIME_MARGIN    = 3600

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function urlEncode(value)
  value = tostring(value or "")
  return (value:gsub("([^%w%-_%.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

local function randomID()
  local t = {}
  for i = 1, 16 do
    t[i] = string.format("%x", math.random(0, 15))
  end
  return table.concat(t)
end

local function getInstallID()
  local f = io.open(SAVE_ID_FILE, "r")
  if f then
    local id = trim(f:read("*l"))
    f:close()
    if id ~= "" then return id end
  end
  math.randomseed(os.time() + math.floor(os.clock() * 1000))
  local id = randomID()
  f = io.open(SAVE_ID_FILE, "w")
  if f then f:write(id); f:close() end
  return id
end

local function readSavedKey()
  local f = io.open(SAVE_KEY_FILE, "r")
  if not f then return "" end
  local key = trim(f:read("*l"))
  f:close()
  return key
end

local function saveKey(key)
  local f = io.open(SAVE_KEY_FILE, "w")
  if f then f:write(key); f:close() end
end

local function checkTimeIntegrity()
  local now = os.time()
  local f = io.open(SAVE_LAST_FILE, "r")
  if f then
    local last = tonumber(f:read("*l"))
    f:close()
    if last and now + TIME_MARGIN < last then
      gg.alert("⛔ تم اكتشاف إرجاع تاريخ الجهاز للخلف")
      os.exit()
    end
  end
  f = io.open(SAVE_LAST_FILE, "w")
  if f then f:write(now); f:close() end
end

-- استخراج بسيط للحقول التي يعيدها server.js، ولا يعتمد على مكتبة خارجية.
local function jsonString(body, field)
  local value = body:match('"' .. field .. '"%s*:%s*"(.-)"')
  return value or ""
end

local function jsonNumber(body, field)
  local value = body:match('"' .. field .. '"%s*:%s*(-?%d+%.?%d*)')
  return tonumber(value)
end

local function requestLicense(key, deviceID)
  local url = CHECK_URL .. "?key=" .. urlEncode(key) .. "&deviceid=" .. urlEncode(deviceID)
  local response = gg.makeRequest(url, {
    ["Accept"] = "application/json",
    ["User-Agent"] = "SB6SB-GameGuardian/1.0",
    ["Cache-Control"] = "no-cache"
  })
  if not response then
    return nil, "تعذر الاتصال بالسيرفر. تحقق من الإنترنت ورابط Render."
  end
  local code = tonumber(response.code or 0) or 0
  local body = tostring(response.content or "")
  if code < 200 or code >= 300 then
    return nil, "❌ تعذر التحقق من المفتاح حاليًا، حاول مرة أخرى"
  end
  local status = jsonString(body, "status")
  if status ~= "active" then
    local messages = {
      invalid = "❌ المفتاح غير صحيح",
      banned = "⛔ المستخدم محظور",
      expired = "⏳ انتهت مدة التفعيل",
      another_device = "📱 المفتاح مربوط بجهاز آخر",
      rate_limited = "⏱️ محاولات كثيرة، انتظر قليلًا"
    }
    return nil, messages[status] or "❌ تعذر قبول المفتاح، حاول مرة أخرى"
  end
  return {
    name = jsonString(body, "name"),
    expire_at = jsonString(body, "expire_at"),
    days = jsonNumber(body, "days") or 0,
    hours = jsonNumber(body, "hours") or 0,
    minutes = jsonNumber(body, "minutes") or 0
  }
end

local function activate(deviceID)
  while true do
    -- يتم إرسال USER ID تلقائيًا من الجهاز؛ المستخدم يدخل المفتاح فقط.
    local input = gg.prompt({"🌺ادخل كود التفعيل الدائم🌺"}, {""}, {"text"})
    -- زر إلغاء/رجوع يعيد المستخدم إلى الواجهة الأولى بدل إغلاق السكربت.
    if not input then return nil end
    local key = trim(input[1]):upper()
    if key == "" then
      gg.alert("❌ يجب إدخال مفتاح التفعيل")
    else
      gg.toast("🔄 جارٍ التحقق من المفتاح...")
      local license, err = requestLicense(key, deviceID)
      if license then
        saveKey(key)
        gg.alert("✅ تم التفعيل بنجاح\n\n" ..
          "👤 " .. (license.name ~= "" and license.name or "مستخدم") .. "\n" ..
          "⏳ المتبقي: " .. license.days .. " يوم و " .. license.hours .. " ساعة و " .. license.minutes .. " دقيقة")
        return license
      end
      gg.alert("❌ تعذر التحقق من المفتاح، حاول مرة أخرى.")
    end
  end
end

local function verifySavedLicense(deviceID)
  local key = readSavedKey()
  if key == "" then return nil end
  local license, err = requestLicense(key, deviceID)
  if license then return license end
  -- لا نحذف المفتاح عند الحظر أو الانتهاء؛ بعد فك الحظر أو التمديد
  -- ستتم المصادقة عليه تلقائيًا في التشغيل التالي دون إدخاله من جديد.
  return nil, err
end

checkTimeIntegrity()
local DEVICE_ID = getInstallID()
local license, licenseError = verifySavedLicense(DEVICE_ID)
while not license do
  if licenseError then
    gg.alert("❌ تعذر التحقق من المفتاح، حاول مرة أخرى.")
    licenseError = nil
  end
  -- بعد الإلغاء لا نفتح GameGuardian تلقائيًا؛ ننتظر المستخدم حتى يفتحه.
  while not gg.isVisible(true) do
    gg.sleep(200)
  end
  gg.setVisible(false)

  local choice = gg.choice({"🔑 إدخال مفتاح التفعيل", "❌ خروج"}, nil, "🔐 نظام التفعيل عبر السيرفر")
  if choice == 2 then
    os.exit()
  elseif choice == 1 then
    license, licenseError = activate(DEVICE_ID)
  else
    -- إلغاء/رجوع: لا نغلق السكربت، وننتظر فتح GG لعرض الواجهة مجددًا.
    gg.toast("ℹ️ افتح GameGuardian مجددًا لعرض واجهة التفعيل")
  end
end

local d = license.days or 0
local h = license.hours or 0
local m = license.minutes or 0
gg.alert("⏳ الوقت المتبقي من السيرفر:\n\n" ..
  "🗓 " .. d .. " يوم\n" ..
  "⏰ " .. h .. " ساعة\n" ..
  "⏱ " .. m .. " دقيقة")

--------------------------------------------------
-- ✅ انتهى نظام التفعيل عبر السيرفر
--------------------------------------------------

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

    local function hasNonEmptyFile(path)
        local f = io.open(path, 'rb')
        if not f then return false end
        local firstByte = f:read(1)
        f:close()
        return firstByte ~= nil
    end

    -- لا تعرض المزرعة إلا إذا كان ملفا الحفظ موجودين وغير فارغين.
    for user = 0, 20 do
        local p = MERGED_BASE ..
            '/virtual/data/user/' ..
            tostring(user) ..
            '/com.playrix.township/saves/'

        if hasNonEmptyFile(p .. 'LocalInfo.xml') and
           hasNonEmptyFile(p .. 'mGameInfo.xml') then
            result[#result + 1] = {
                user = user,
                path = p,
                source = 'virtual'
            }
        end
    end

    -- فحص مسار Resource Manager أيضًا، مع منع تكرار نفس المسار.
    local realRoot = '/data/data/com.lbe.parallel.intl/parallel_intl/'
    for city = 0, 100 do
        local p = realRoot .. tostring(city) .. '/com.playrix.township/saves/'
        if hasNonEmptyFile(p .. 'LocalInfo.xml') and
           hasNonEmptyFile(p .. 'mGameInfo.xml') then
            local alreadyAdded = false
            for _, existing in ipairs(result) do
                if existing.path == p then
                    alreadyAdded = true
                    break
                end
            end
            if not alreadyAdded then
                result[#result + 1] = {
                    user = city,
                    path = p,
                    source = 'parallel_intl'
                }
            end
        end
    end

    return result
end

local environments = find_environments()
if #environments == 0 then
    gg.alert('⚠️ اختر الناسخ الذي تعمل به اولا')
    return
end
local envMenu = {}
for i, e in ipairs(environments) do
    -- المسار الأساسي يبقى بترقيمه الأصلي، والاحتياطي يعرض رقم المجلد الحقيقي
    local displayNumber = (e.source == 'parallel_intl') and e.user or i
    envMenu[i] = '📦 المزرعة' .. tostring(displayNumber)
end
local envChoice = gg.choice(envMenu, nil, '📦 اختر المزرعة')
if not envChoice then
    gg.alert('⚠️ يجب اختيار مزرعة اولا')
    return
end
local MERGED_TOWNSHIP_BASE=environments[envChoice].path

local function isValidEnvironmentPath(path)
    if type(path) ~= 'string' or path == '' then return false end
    local function hasData(fileName)
        local f = io.open(path .. fileName, 'rb')
        if not f then return false end
        local data = f:read(1)
        f:close()
        return data ~= nil
    end
    return hasData('LocalInfo.xml') and hasData('mGameInfo.xml')
end

if not isValidEnvironmentPath(MERGED_TOWNSHIP_BASE) then
    gg.alert('⚠️ اختر الناسخ الذي تعمل به')
    return
end

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
local EDITED_OUTPUT = MERGED_TOWNSHIP_BASE .. "mGameInfo.xml"

-- ============================================
-- SERVER
-- ============================================

local DECODE_URL =
    "https://soft-flower-4528.alklharq40.workers.dev/api/decode"

local EDIT_URL =
    "https://soft-flower-4528.alklharq40.workers.dev/api/edit"


-- ============================================
local APP_BARN_CATEGORIES = {
    {name="🌾النباتات🍓", items={
        {key="wheat", label="قمح"},
        {key="corn", label="ذرة"},
        {key="carrot", label="جزر"},
        {key="sugarcane", label="قصب سكر"},
        {key="cotton", label="قطن"},
        {key="strawberry", label="فراولة"},
        {key="tomat", label="طماطم"},
        {key="pine", label="خشب"},
        {key="potato", label="بطاطس"},
        {key="cacao", label="كاكاو"},
        {key="rubberTree", label="شجرة المطاط"},
        {key="silk", label="حرير"},
        {key="pepper", label="فلفل"},
        {key="rice", label="أرز"},
        {key="roseSeed", label="بذور ورد"},
        {key="jasmine", label="ياسمين"},
        {key="coffee", label="بن"},
        {key="soybean", label="فول صويا"},
        {key="teabush", label="أوراق شاي"},
        {key="mint", label="نعناع"},
        {key="peanut", label="فول سوداني"},
        {key="lavender", label="خزامى"},
        {key="cork", label="فلين"},
    }},
    {name="🐮المنتجات الحيوانية🥛", items={
        {key="milk", label="حليب"},
        {key="egg", label="بيض"},
        {key="wool", label="صوف"},
        {key="bacon", label="بيكون"},
        {key="honeycomb", label="قرص عسل"},
        {key="mushroom", label="فطر"},
        {key="downFeather", label="ريش"},
        {key="bigFeather", label="ريشة كبيرة"},
    }},
    {name="🍤منتجات الجزر🍉", items={
        {key="apple", label="تفاح"},
        {key="peach", label="خوخ"},
        {key="watermelon", label="بطيخ"},
        {key="plum", label="برقوق"},
        {key="grapes", label="عنب"},
        {key="fish", label="سمك"},
        {key="shrimp", label="جمبري"},
        {key="lobster", label="كركند"},
        {key="scallop", label="محار"},
        {key="pearl", label="لؤلؤ"},
        {key="seaweed", label="أعشاب بحرية"},
        {key="banana", label="موز"},
        {key="coconut", label="جوز هند"},
        {key="pineapple", label="أناناس"},
        {key="olive", label="زيتون"},
        {key="lemon", label="ليمون"},
        {key="aloe", label="صبار"},
        {key="aloeLeaves", label="أوراق صبار"},
        {key="mango1", label="مانجو"},
    }},
    {name="🦃أعلاف الحيوانات🐝", items={
        {key="cowfeed", label="علف بقري"},
        {key="chickenfeed", label="علف دجاج"},
        {key="sheepfeed", label="علف خراف"},
        {key="pigfeed", label="علف خنازير"},
        {key="beefeed", label="علف نحل"},
    }},
    {name="🥨الألبان والمخبوزات والسكر 🥐", items={
        {key="flour", label="دقيق"},
        {key="bread", label="خبز"},
        {key="cookie", label="بسكويت"},
        {key="bagel", label="بيغل"},
        {key="pizza", label="بيتزا"},
        {key="potatobread", label="خبز بطاطس"},
        {key="bananabread", label="خبز موز"},
        {key="mushroomPie", label="فطيرة فطر"},
        {key="strudel", label="سترودل"},
        {key="marinepizza", label="بيتزا مارينارا"},
        {key="dough", label="عجين"},
        {key="cream", label="كريمة"},
        {key="cheese", label="جبن"},
        {key="butter", label="زبدة"},
        {key="yogurt", label="زبادي"},
        {key="peachyogurt", label="زبادي خوخ"},
        {key="sugar", label="سكر"},
        {key="syrup", label="شراب"},
    }},
    {name="🍩الحلويات🍭", items={
        {key="candy", label="حلوى"},
        {key="caramelapple", label="تفاحة بالكراميل"},
        {key="jellybeans", label="فاصوليا جيلي"},
        {key="toffee", label="توفي"},
        {key="candystick", label="عصا حلوى"},
        {key="lollipop", label="مصاصة"},
        {key="honeycandy", label="حلوى عسل"},
        {key="fruitjelly", label="جيلي فواكه"},
        {key="chocobar", label="لوح شوكولاتة"},
        {key="teacandies", label="حلوى شاي"},
        {key="mintlollipops", label="مصاصات نعناع"},
        {key="cottonCandy", label="غزل بنات"},
        {key="chocolate", label="شوكولاتة"},
        {key="icecream", label="آيس كريم"},
        {key="frozenyogurt", label="زبادي مجمد"},
        {key="fruitice", label="مثلجات فواكه"},
        {key="eskimo", label="آيس كريم إسكيمو"},
        {key="pineapplesorbet", label="سوربيه أناناس"},
        {key="roseSorbet", label="سوربيه ورد"},
        {key="parfait", label="بارفيه"},
        {key="mintchocolateicecream", label="آيس كريم شوكولاتة بالنعناع"},
        {key="muffin", label="مافن"},
        {key="brownie", label="براوني"},
        {key="cupcake", label="كب كيك"},
        {key="doughnut", label="دونات"},
        {key="cheesecake", label="تشيز كيك"},
        {key="limepie", label="فطيرة ليمون"},
        {key="coconutmacaroon", label="ماكرون جوز هند"},
        {key="honeycake", label="كيك عسل"},
        {key="strawberrycake", label="كيك فراولة"},
        {key="weddingcake", label="كيك زفاف"},
        {key="coffeecake", label="كيك بن"},
        {key="chocolatecake", label="كيك شوكولاتة"},
        {key="carrotcake", label="كيك جزر"},
        {key="mintcake", label="كيك نعناع"},
        {key="tiramisu", label="تيراميسو"},
    }},
    {name="🍟الوجبات السريعة🍔", items={
        {key="chips", label="رقائق بطاطس"},
        {key="popcorn", label="فشار"},
        {key="cornchips", label="رقائق ذرة"},
        {key="granola", label="جرانولا"},
        {key="canape", label="كانابيه"},
        {key="glazedbacon", label="بيكون مزجج"},
        {key="puffedrice", label="أرز منفوش"},
        {key="saltedpeanut", label="فول سوداني مملح"},
        {key="frenchfries", label="بطاطس مقلية"},
        {key="sandwich", label="ساندويتش"},
        {key="cheeseburger", label="تشيز برجر"},
        {key="bakedpotatoes", label="بطاطس مشوية"},
        {key="fishburger", label="برجر سمك"},
        {key="fish_chips", label="سمك ورقائق"},
        {key="peanot_crepes", label="كريب فول سوداني"},
        {key="hot_dog", label="هوت دوج"},
        {key="corndog", label="كورن دوج"},
        {key="cheese_coney", label="تشيز كوني"},
        {key="carrot_hotdog", label="هوت دوج جزر"},
        {key="taco", label="تاكو"},
        {key="nachos", label="ناتشوز"},
        {key="burrito", label="بوريتو"},
        {key="jalapeno", label="هالابينو"},
        {key="falafel", label="فلافل"},
        {key="hummus", label="حمص"},
        {key="guacamole", label="جواكامولي"},
        {key="bacon_eggs", label="بيض وبيكون"},
    }},
    {name="🍹المشروبات🍹", items={
        {key="milkshake", label="ميلك شيك"},
        {key="grap_fizz", label="صودا عنب"},
        {key="chocolate_smoothie", label="سموذي شوكولاتة"},
        {key="watermelon_fresh", label="عصير بطيخ"},
        {key="tropical_mix", label="مزيج استوائي"},
        {key="cold_tea", label="شاي مثلج"},
        {key="minticetea", label="شاي مثلج بالنعناع"},
        {key="applefresh", label="عصير تفاح"},
        {key="espresso", label="إسبريسو"},
        {key="cappuccino", label="كابتشينو"},
        {key="mokachino", label="موكاشينو"},
        {key="hot_chocolate", label="شوكولاتة ساخنة"},
        {key="blacktea", label="شاي أسود"},
        {key="whitetea", label="شاي أبيض"},
        {key="rosetea", label="شاي ورد"},
        {key="tibettea", label="شاي تبتي"},
        {key="oolong", label="شاي أولونغ"},
        {key="appletea", label="شاي تفاح"},
        {key="coconut_raf", label="كافيه كوكو راف"},
        {key="teabags", label="أكياس شاي"},
    }},
    {name="🧥الملابس والأحذية🧦", items={
        {key="woolfabric", label="قماش صوف"},
        {key="cottonfabric", label="قماش قطن"},
        {key="silkfabric", label="قماش حرير"},
        {key="nylonthread", label="خيط نايلون"},
        {key="shirt", label="قميص"},
        {key="sweater", label="سترة"},
        {key="coat", label="معطف"},
        {key="hat", label="قبعة"},
        {key="suit", label="بدلة"},
        {key="tiroleanHat", label="قبعة تيرولية"},
        {key="eveningdress", label="فستان سهرة"},
        {key="dress", label="فستان"},
        {key="flipflops", label="شبشب"},
        {key="sandals", label="صنادل"},
        {key="sneakers", label="حذاء رياضي"},
        {key="boots", label="حذاء"},
        {key="heels", label="كعب عالي"},
        {key="downBoots", label="حذاء شتوي"},
        {key="downJacket", label="جاكيت شتوي"},
    }},
    {name="📖المنزل والقرطاسية💢", items={
        {key="paper", label="ورق"},
        {key="papertowel", label="مناديل ورقية"},
        {key="wallpapers", label="ورق جدران"},
        {key="book", label="كتاب"},
        {key="stickers", label="لصاقات"},
        {key="marker", label="قلم تحديد"},
        {key="eraser", label="ممحاة"},
        {key="corkboard", label="لوح فلين"},
        {key="table", label="طاولة"},
        {key="chair", label="كرسي"},
        {key="couch", label="أريكة"},
        {key="bed", label="سرير"},
        {key="floor_lamp", label="مصباح أرضي"},
        {key="pillow", label="وسادة"},
        {key="duvet", label="لحاف"},
        {key="tissue", label="مناديل"},
        {key="dispenser", label="موزع"},
    }},
    {name="🍴المطعم والأطباق🍽", items={
        {key="sushi", label="سوشي"},
        {key="lobster_nigiri", label="نيجيري كركند"},
        {key="scallopsushi", label="سوشي محار"},
        {key="soup", label="حساء"},
        {key="misosoup", label="شوربة ميسو"},
        {key="corn_soup", label="شوربة ذرة"},
        {key="mushroomSoup", label="شوربة فطر"},
        {key="gazpacho", label="جازباتشو"},
        {key="bouillabaisse", label="بويابيس"},
        {key="seaweedsalad", label="سلطة أعشاب بحرية"},
        {key="mushroomSalad", label="سلطة فطر"},
        {key="seafood_salad", label="سلطة مأكولات بحرية"},
        {key="nicoise", label="سلطة نيكواز"},
        {key="rice_noodle", label="نودلز أرز"},
        {key="thai_sauce", label="صلصة تايلاندية"},
        {key="sauce", label="صلصة"},
        {key="quiche", label="كيش"},
        {key="fried_fish", label="سمك مقلي"},
        {key="rice_casserole", label="طاجن أرز"},
        {key="baked_lobster", label="كركند مشوي"},
        {key="lobster_newburg", label="كركند نيوبيرغ"},
        {key="scallopskew", label="كباب محار"},
        {key="grilledMeat", label="لحم مشوي"},
        {key="ratatouille", label="راتاتوي"},
        {key="profiteroles", label="بروفيترول"},
        {key="gyoza", label="غيوزا"},
        {key="readylunch", label="علبة غداء"},
        {key="frozenvegetables", label="خضروات مجمدة"},
        {key="seafoodcocktail", label="كوكتيل مأكولات بحرية"},
        {key="oliveoil", label="زيت زيتون"},
        {key="bruschetta", label="بروشيتا"},
        {key="arrabbiata", label="أرابياتا"},
        {key="ravioli", label="رافيولي"},
        {key="lasagna", label="لازانيا"},
        {key="mole", label="مول"},
    }},
    {name="🍒المربيات🍓", items={
        {key="jam", label="مربى"},
        {key="strawberry_jam", label="مربى فراولة"},
        {key="peach_jam", label="مربى خوخ"},
        {key="watermelon_jam", label="مربى بطيخ"},
        {key="plum_jam", label="مربى برقوق"},
        {key="grapes_jam", label="مربى عنب"},
        {key="roseJam", label="مربى ورد"},
        {key="mushroom_jam", label="مربى فطر"},
        {key="applejam", label="مربى تفاح"},
        {key="peanut_butter", label="زبدة فول سوداني"},
        {key="ketchup", label="كاتشب"},
        {key="driedMushrooms", label="فطر مجفف"},
        {key="tofu", label="توفو"},
        {key="soymilk", label="حليب صويا"},
    }},
    {name="💍التجميل والمجوهرات👑", items={
        {key="brownCandle", label="شمعة بنية"},
        {key="perfumeBottle", label="عطر"},
        {key="flowerSoap", label="صابون أزهار"},
        {key="lotionBottle", label="لوشن"},
        {key="aromatic_oil", label="زيت عطري"},
        {key="air_freshener", label="معطر جو"},
        {key="creammask", label="ماسك وجه"},
        {key="toothpaste", label="معجون أسنان"},
        {key="vitamin_cocktail", label="كوكتيل فيتامينات"},
        {key="pendant", label="قلادة"},
        {key="ring", label="خاتم"},
        {key="pearlneck", label="عقد لؤلؤ"},
        {key="earrings", label="أقراط"},
        {key="diadem", label="تاج"},
    }},
    {name="🎉الألعاب والحفلات🥳", items={
        {key="toys", label="ألعاب"},
        {key="ball", label="كرة"},
        {key="shuttlecock", label="ريشة ريشة"},
        {key="Plasticine", label="صلصال"},
        {key="ragdoll", label="دمية قماش"},
        {key="puppet", label="دمية يد"},
        {key="chinadoll", label="دمية خزف"},
        {key="barbie", label="دمية باربي"},
        {key="ukulele", label="يوكولالي"},
        {key="saxophone", label="ساكسفون"},
        {key="drum", label="طبل"},
        {key="accordion", label="أكورديون"},
        {key="panpipe", label="مزمار بان"},
        {key="pettoy", label="لعبة حيوانات"},
        {key="cattoy", label="لعبة قطط"},
        {key="waterbowl", label="وعاء ماء"},
        {key="catcave", label="كهف قطة"},
        {key="catlitter", label="رمل قطط"},
        {key="airballoon", label="منطاد"},
        {key="soapBubbles", label="فقاعات صابون"},
        {key="lei", label="إكليل هاواي"},
    }},
    {name="🌺الأدوات والزهور🌹", items={
        {key="clover", label="برسيم"},
        {key="bridebouquet", label="باقة زفاف"},
        {key="sweetbouquet", label="باقة سكرية"},
        {key="basketbouquet", label="باقة سلة"},
        {key="teacoffeebouquet", label="باقة شاي وقهوة"},
        {key="driedflowers", label="زهور مجففة"},
        {key="summerbouquet", label="باقة صيفية"},
        {key="vegetablebouquet", label="باقة خضروات"},
        {key="toolset", label="مجموعة أدوات"},
        {key="irrigationhose", label="خرطوم ري"},
        {key="flowertub", label="حوض زهور"},
        {key="gardengnome", label="قزم حديقة"},
        {key="brush", label="فرشاة"},
        {key="clothesline", label="حبل غسيل"},
        {key="plunger", label="مكبس"},
        {key="duster", label="منفضة"},
        {key="gloves", label="قفازات"},
        {key="plastic", label="بلاستيك"},
        {key="glue", label="صمغ"},
        {key="dumbbell", label="دمبل"},
    }},
    {name="🧺أدوات المطبخ والحقائب🛍", items={
        {key="mug", label="كوب"},
        {key="frypan", label="مقلاة"},
        {key="teapot", label="إبريق شاي"},
        {key="cutlery", label="أدوات مائدة"},
        {key="teaceremonykit", label="طقم حفل شاي"},
        {key="potstand", label="حامل أواني"},
        {key="newbackpack", label="حقيبة ظهر"},
        {key="basket", label="سلة"},
        {key="handbag", label="حقيبة يد"},
        {key="suitcase", label="حقيبة سفر"},
    }},
    {name="🛠مواد البناء⛏️", items={
        {key="Brick", label="طوب"},
        {key="Glass", label="زجاج"},
    }},
    {name="مواد المخزن والتوسعة", items={
        {key="hammerMat", label="مطرقة"},
        {key="nailMat", label="مسامير"},
        {key="paintRedMat", label="طلاء أحمر"},
        {key="axe", label="فأس"},
        {key="powersaw", label="منشار كهربائي"},
        {key="pick", label="معول"},
        {key="TNT", label="TNT"},
        {key="jackhammer", label="شاكوش ضاغط"},
    }},    
    {name="🥈السبائك🏅", items={
        {key="BronzeBullion", label="سبيكة برونز"},
        {key="SilverBullion", label="سبيكة فضة"},
        {key="GoldBullion", label="سبيكة ذهب"},
    }},
}

local APP_RESOURCE_CATEGORIES = {
    {name="♡BS♡", items={
        {key="معزز الصاروخ"},
        {key="معزز القنبلة"},
        {key="كرة قوس قزح"},
        {key="مطرقة المطابقة"},
        {key="أداة المطابقة الأفقية"},
        {key="أداة المطابقة العمودية"},
        {key="إعادة خلط المطابقة"},
        {key="معزز مضاعف (أيام)"},
        {key="حياة لا نهائية (أيام)"},
        {key="حركات المطابقة"},
    }},
    {name="♡BS♡", items={
        {key="جوهرة 1"},
        {key="جوهرة 2"},
        {key="جوهرة 3"},
        {key="جوهرة 4"},
        {key="سبيكة ذهب"},
        {key="سبيكة فضة"},
        {key="سبيكة برونز"},
        {key="سبيكة بلاتين"},
    }},
    {name="♡BS♡", items={
        {key="معول"},
        {key="متفجرات"},
        {key="متفجرات قوية"},
        {key="خام برونز"},
        {key="خام ذهب"},
        {key="خام فضة"},
        {key="خام بلاتين"},
        {key="طين"},
    }},
    {name="♡BS♡", items={
        {key="برسيم"},
        {key="نجمة"},
        {key="طاقة استكشاف"},
    }},
    {name=" ♡BS♡", items={
        {key="زيادة إنتاج المزرعة"},
        {key="مضاعفة إنتاج المصنع"},
        {key="تسريع القطارات"},
        {key="زيادة عملات الطلبات"},
        {key="تسريع وقت المصنع"},
        {key="تسريع وقت المصهر"},
        {key="تسريع السوق"},
        {key="تسريع السفن"},
        {key="عملات المطار"},
        {key="زيادة حد التبرع"},
        {key="زيادة سعة التخزين"},
        {key="قلوب حديقة الحيوان"},
        {key="طلبات مساعدة الفريق"},
        {key="فوانيس المنجم"},
        {key="احتمالية الجزر"},
        {key="زيادة إنتاج الحصاد"},
        {key="تسريع التاجر"},
        {key="تسريع الحصاد"},
        {key="تسريع الطلبات"},
    }},
    {name="♡BS♡", items={
        {key="قسيمة ترقية المصانع"},
        {key="قسيمة ترقية الجزيرة"},
        {key="قسيمة ترقية القطار"},
        {key="قسيمة التحميل"},
        {key="قسيمة التوسعة"},
        {key="قسيمة الشونة"},
        {key="قسيمة التاجر"},
    }},
    {name="♡BS♡", items={
        {key="سرعة البناء"},
        {key="سرعة الحصاد"},
        {key="سرعة الحيوانات"},
        {key="معزز الحظيرة"},
        {key="سرعة الطائرات"},
        {key="قطار مضاعف"},
        {key="سوق ممتاز"},
        {key="مكافأة العملات"},
        {key="صاروخ المنجم"},
        {key="طلب تعاون"},
        {key="منجم مضاعف"},
    }},
}

-- المعرفات الداخلية التي أكدها السكربت القديم والسيرفر.
-- الاسم العربي للعرض فقط، أما name المرسل للسيرفر فيجب أن يكون هنا.
local APP_RESOURCE_KEY_MAP = {
    -- أدوات المطابقة
    ["معزز الصاروخ"] = "m3Line",
    ["معزز القنبلة"] = "m3Bomb",
    ["كرة قوس قزح"] = "m3RainbowBall",
    ["مطرقة المطابقة"] = "m3Mallet",
    ["أداة المطابقة الأفقية"] = "m3HorizontalLine",
    ["أداة المطابقة العمودية"] = "m3VerticalLine",
    ["إعادة خلط المطابقة"] = "m3Reshuffle",
    ["معزز مضاعف (أيام)"] = "booster2x_days",
    ["حياة لا نهائية (أيام)"] = "lives_inf_days",
    ["حركات المطابقة"] = "match3_moves",
    ["قنبلة لا نهائية (أيام)"] = "m3bomb_inf_days",
    ["خط لا نهائي (أيام)"] = "m3line_inf_days",
    ["كرة قوس قزح لا نهائية (أيام)"] = "m3rainbow_inf_days",

    -- المختبر
    ["زيادة إنتاج المزرعة"] = "BoostProductFarm",
    ["مضاعفة إنتاج المصنع"] = "BoostDoubleFactory",
    ["تسريع القطارات"] = "BoostSpeedUpTrains",
    ["زيادة عملات الطلبات"] = "BoostMoneyOrder",
    ["تسريع وقت المصنع"] = "BoostTimeFactory",
    ["تسريع وقت المصهر"] = "BoostTimeSmeltery",
    ["تسريع السوق"] = "BoostTimeMarket",
    ["تسريع السفن"] = "BoostSpeedUpShips",
    ["عملات المطار"] = "BoostAirportCoins",
    ["زيادة حد التبرع"] = "BoostMaxDonate",
    ["زيادة سعة التخزين"] = "BoostStorageCapacity",
    ["قلوب حديقة الحيوان"] = "BoostHeartsZoo",
    ["طلبات مساعدة الفريق"] = "BoostClanHelpRequest",
    ["فوانيس المنجم"] = "BoostLanternMine",
    ["احتمالية الجزر"] = "BoostProbabilityIslands",
    ["زيادة إنتاج الحصاد"] = "BoostProductHarvest",
    ["تسريع التاجر"] = "BoostSpeedUpDealer",
    ["تسريع الحصاد"] = "BoostSpeedUpHarvest",
    ["تسريع الطلبات"] = "BoostSpeedUpOrder",

    -- الجواهر والمنجم والموارد
    ["جوهرة 1"] = "gem1",
    ["جوهرة 2"] = "gem2",
    ["جوهرة 3"] = "gem3",
    ["جوهرة 4"] = "gem4",
    ["سبيكة ذهب"] = "GoldBullion",
    ["سبيكة فضة"] = "SilverBullion",
    ["سبيكة برونز"] = "BronzeBullion",
    ["سبيكة بلاتين"] = "PlatinumBullion",
    ["طاقة استكشاف"] = "energy_expedition",
    ["نجمة"] = "star",
    ["برسيم"] = "clovers",
    ["معول"] = "m1",
    ["متفجرات"] = "m2",
    ["متفجرات قوية"] = "m3",
    ["TNT"] = "m3",
    ["خام برونز"] = "o1",
    ["خام ذهب"] = "o2",
    ["خام فضة"] = "o3",
    ["خام بلاتين"] = "o4",
    ["طين"] = "o5",

    -- المعززات الإضافية
    ["سرعة البناء"] = "SP_BoostSpeedUpBuildings",
    ["سرعة الحصاد"] = "SP_BoostSpeedUpHarvest",
    ["سرعة الحيوانات"] = "SP_BoostSpeedUpFarms",
    ["معزز الحظيرة"] = "SP_BoostStorageCapacity",
    ["سرعة الطائرات"] = "SP_BoostSpeedUpAir",
    ["قطار مضاعف"] = "SP_BoostTrainMats",
    ["سوق ممتاز"] = "SP_MarketPremium",
    ["مكافأة العملات"] = "SP_BoostOrderCoins",
    ["صاروخ المنجم"] = "SP_BoostMineRocket",
    ["طلب تعاون"] = "SP_BoostClanHelpRequest",
    ["منجم مضاعف"] = "CascadeEventMine"
}

local function resourceInternalKey(key)
    return APP_RESOURCE_KEY_MAP[tostring(key or "")] or tostring(key or "")
end

local function choose_catalog_items(categories, title)
    -- بعض عناصر الموارد القديمة تحتوي على key فقط دون label.
    -- استخدام key كاسم عرض احتياطي يمنع خطأ nil عند فتح القائمة.
    local function itemLabel(item)
        return tostring(item.label or item.name or item.key or "عنصر")
    end

    local category_labels = {}
    for _, category in ipairs(categories) do
        table.insert(category_labels, category.name)
    end
    local category_index = gg.choice(category_labels, nil, title .. " — اختر القسم")
    if not category_index then return nil end
    local category = categories[category_index]
    local item_labels = {}
    table.insert(item_labels, "✅ تحديد جميع أصناف القسم")
    for _, item in ipairs(category.items) do
        table.insert(item_labels, itemLabel(item) .. "  [" .. tostring(item.key or "") .. "]")
    end
    local selected = gg.multiChoice(item_labels, nil, title .. " — " .. category.name .. " (اختر عدة أصناف)")
    if not selected then return nil end
    local input = gg.prompt({"العدد لجميع الأصناف المحددة"}, {""}, {"number"})
    if not input or input[1] == nil or tostring(input[1]) == "" then return nil end
    local amount = tonumber(input[1])
    if not amount or amount < 0 then
        gg.alert("❌ العدد غير صحيح")
        return nil
    end
    local result = {}
    for index, checked in pairs(selected) do
        if checked and index == 1 then
            for _, item in ipairs(category.items) do
                table.insert(result, {name = resourceInternalKey(item.key), value = amount, label = itemLabel(item)})
            end
            break
        elseif checked and index > 1 then
            local item = category.items[index - 1]
            if item and item.key then
                table.insert(result, {name = resourceInternalKey(item.key), value = amount, label = itemLabel(item)})
            end
        end
    end
    if #result == 0 then return nil end
    return result
end

local APP_SKIN_IDS = {
    "Skin_Sheep_butterfly_71", "Skin_Sheep_halloween2022", "Skin_Sheep_lunarNY2022", "Skin_Sheep_easter2023", "Skin_Sheep_nordicGod",
    "Skin_Sheep_detective", "Skin_Sheep_sweet", "Skin_Sheep_robinHood", "Skin_Sheep_brazil", "Skin_Sheep_rocknroll",
    "Skin_Sheep_knight", "Skin_Sheep_wildwest2024", "Skin_Sheep_birthday2024", "Skin_Sheep_birthday2024s", "Skin_Sheep_egypt",
    "Skin_Sheep_christmas2024", "Skin_Sheep_allinclusive2025", "Skin_Sheep_hellas2025", "Skin_Sheep_masquerade", "Skin_Sheep_Default",
    "Skin_Sheep_Birthday_2025", "Skin_Sheep_Halloween2025", "Skin_Helicopter_butterfly_71", "Skin_Helicopter_Resort", "Skin_Helicopter_Travel",
    "Skin_Helicopter_Sport", "Skin_Helicopter_cinderella", "Skin_Helicopter_detective", "Skin_Helicopter_halloween2023", "Skin_Helicopter_brazil",
    "Skin_Helicopter_easter2024", "Skin_Helicopter_atlantis", "Skin_Helicopter_pirate2024", "Skin_Helicopter_disco", "Skin_Helicopter_mars2025",
    "Skin_Helicopter_Ufo", "Skin_Helicopter_Robot", "Skin_Helicopter_sport", "Skin_Helicopter_Arabic", "Skin_Helicopter_travel",
    "Skin_Helicopter_Sleigh", "Skin_Helicopter_Gatsby", "Skin_Helicopter_masquerade", "Skin_Helicopter_cny2025", "Skin_Helicopter_Ufo:2",
    "Skin_Helicopter_Sleigh:2", "Skin_Helicopter_Harvest", "Skin_Helicopter_Robot:2", "Skin_Helicopter_Default", "Skin_Helicopter_Birthday_2025",
    "Skin_Helicopter_christmas_67", "Skin_Airplane_carnival_70", "Skin_Airplane_movie", "Skin_Airplane_christmas2022", "Skin_Airplane_easter2023",
    "Skin_Airplane_sweet", "Skin_Airplane_winterSport", "Skin_Airplane_ireland", "Skin_Airplane_spy", "Skin_Airplane_allinclusive",
    "Skin_Airplane_fashion", "Skin_Airplane_arab", "Skin_Airplane_SP3:2", "Skin_Airplane_halloween2021:2", "Skin_Airplane_space",
    "Skin_Airplane_rock", "Skin_Airplane_classicmusic", "Skin_Airplane_Default", "Skin_Airplane_Halloween2025", "Skin_Chicken_easter_72",
    "Skin_Chicken_travel", "Skin_Chicken_theatrical", "Skin_Chicken_sport", "Skin_Chicken_cinderella", "Skin_Chicken_jungle",
    "Skin_Chicken_sweet", "Skin_Chicken_christmas2023", "Skin_Chicken_ireland", "Skin_Chicken_hellas", "Skin_Chicken_allinclusive",
    "Skin_Chicken_birthday2024", "Skin_Chicken_halloween2024", "Skin_Chicken_fashion", "Skin_Chicken_disco", "Skin_Chicken_mars2025",
    "Skin_Chicken_cny2025", "Skin_Chicken_Default", "Skin_Chicken_Birthday_2025", "Skin_Chicken_Birthday_2025s", "Skin_TrainStation_prehistoric",
    "Skin_TrainStation_theatrical", "Skin_TrainStation_lunarNY2022", "Skin_TrainStation_mars", "Skin_TrainStation_robinHood", "Skin_TrainStation_rocknroll",
    "Skin_TrainStation_knight", "Skin_TrainStation_italy2024", "Skin_TrainStation_halloween2024", "Skin_TrainStation_christmas2024", "Skin_TrainStation_festival",
    "Skin_TrainStation_hellas2025", "Skin_TrainStation_Default", "Skin_TrainStation_western", "Skin_TrainStation_easter", "Skin_HelicopterPlace_butterfly_71",
    "Skin_HelicopterPlace_Travel", "Skin_HelicopterPlace_Sport", "Skin_HelicopterPlace_cinderella", "Skin_HelicopterPlace_detective", "Skin_HelicopterPlace_halloween2023",
    "Skin_HelicopterPlace_brazil", "Skin_HelicopterPlace_easter2024", "Skin_HelicopterPlace_atlantis", "Skin_HelicopterPlace_pirate2024", "Skin_HelicopterPlace_disco",
    "Skin_HelicopterPlace_mars2025", "Skin_HelicopterPlace_masquerade", "Skin_HelicopterPlace_cny2025", "Skin_HelicopterPlace_Sleigh", "Skin_HelicopterPlace_Harvest",
    "Skin_HelicopterPlace_Arabic", "Skin_HelicopterPlace_Resort", "Skin_HelicopterPlace_Default", "Skin_HelicopterPlace_Birthday_2025", "Skin_HelicopterPlace_christmas_67",
    "Skin_Harbor_easter_72", "Skin_Harbor_halloween2022", "Skin_Harbor_valentinesDay", "Skin_Harbor_nordicGod", "Skin_Harbor_jungle",
    "Skin_Harbor_christmas2023", "Skin_Harbor_CNY", "Skin_Harbor_hellas", "Skin_Harbor_wildwest2024", "Skin_Harbor_birthday2024",
    "Skin_Harbor_egypt", "Skin_Harbor_allinclusive2025", "Skin_Harbor_arctic", "Skin_Harbor_japan", "Skin_Harbor_SP9",
    "Skin_Harbor_venice", "Skin_Harbor_Default", "Skin_Harbor_ST1", "Skin_Harbor_paris", "Skin_Harbor_ST8",
    "Skin_Harbor_ST35", "Skin_Harbor_ST43", "Skin_Harbor_ST51", "Skin_Airport_carnival_70", "Skin_Airport_christmas2022",
    "Skin_Airport_sweet", "Skin_Airport_winterSport", "Skin_Airport_ireland", "Skin_Airport_spy", "Skin_Airport_allinclusive",
    "Skin_Airport_arab", "Skin_Airport_SP3", "Skin_Airport_rock", "Skin_Airport_halloween2021", "Skin_Airport_easter2023",
    "Skin_Airport_classicmusic", "Skin_Airport_fashion", "Skin_Airport_Default", "Skin_Airport_movie", "Skin_Airport_Halloween2025",
    "Skin_Ship_easter_72", "Skin_Ship_halloween2022", "Skin_Ship_valentinesDay", "Skin_Ship_nordicGod", "Skin_Ship_jungle",
    "Skin_Ship_christmas2023", "Skin_Ship_CNY", "Skin_Ship_hellas", "Skin_Ship_wildwest2024", "Skin_Ship_birthday2024",
    "Skin_Ship_egypt", "Skin_Ship_allinclusive2025", "Skin_Ship_Default", "Skin_Ship_ST1", "Skin_Ship_paris",
    "Skin_Ship_venice", "Skin_Ship_arctic", "Skin_Ship_japan", "Skin_Ship_SP9", "Skin_Train_prehistoric",
    "Skin_Train_theatrical", "Skin_Train_lunarNY2022", "Skin_Train_mars", "Skin_Train_robinHood", "Skin_Train_rocknroll",
    "Skin_Train_knight", "Skin_Train_italy2024", "Skin_Train_halloween2024", "Skin_Train_christmas2024", "Skin_Train_festival",
    "Skin_Train_hellas2025", "Skin_Train_easter", "Skin_Train_christmas", "Skin_Train_SP5", "Skin_Train_SP8",
    "Skin_Train_western", "Skin_Train_Default1", "Skin_Train_SP2:2", "Skin_Train_ST45", "Skin_Train_ST50",
    "Skin_Train_ST47", "Skin_Train_ST24", "Skin_Cow_carnival_70", "Skin_Cow_movie", "Skin_Cow_christmas2022",
    "Skin_Cow_valentine", "Skin_Cow_mars", "Skin_Cow_sweet2", "Skin_Cow_sweet", "Skin_Cow_halloween2023",
    "Skin_Cow_winterSport", "Skin_Cow_CNY", "Skin_Cow_easter2024", "Skin_Cow_spy", "Skin_Cow_atlantis",
    "Skin_Cow_italy2024", "Skin_Cow_birthday2024", "Skin_Cow_pirate2024", "Skin_Cow_festival", "Skin_Cow_arab",
    "Skin_Cow_arctic", "Skin_Cow_japan", "Skin_Cow_pirate20", "Skin_Cow_classicmusic", "Skin_Cow_Birthday_2025",
    "Skin_Pig_CNY", "Skin_Pig_valentinesDay", "Skin_Fortress_aztecs", "Skin_Fortress_Pirate1", "Skin_Fortress_Pirate2",
    "Skin_Fortress_Pirate3", "Skin_Fortress_Gatsby1", "Skin_Fortress_Gatsby2", "Skin_Fortress_Gatsby3", "Skin_Fortress_Christmas",
    "Skin_Fortress_paris", "Skin_Fortress_easter", "Skin_Fortress_Halloween2021_1", "Skin_Fortress_Halloween2021_2", "Skin_Fortress_Halloween2021_3",
    "Skin_Fortress_prehistoric",
}
local APP_DECOR_IDS = {
    "1400_Christmas_Decoration", "5years", "Apple_Garden", "AquariumAtlantic_ancient", "Arabic_Tent",
    "Atlantis_fence", "Basil_Cath", "Beach_volleyball", "BobsleighRace", "Book_Store",
    "Bungalow_hammock", "CafeTube", "Cafe_Vineyard", "Cafe_Waterfall", "Carousel_Octopus",
    "Cars_Exposition", "Castle_Trampoline", "Cave_Place", "ChineseBanner", "ChineseDog",
    "ChineseNYTree", "ChineseNY_pigStatue", "Chinese_fence", "ChocolateFactoryDecor", "ChristmasBall",
    "ChristmasBanner", "ChristmasCarousel", "ChristmasTrain_Bridge", "Christmas_Cafe", "Christmas_Chorus",
    "Christmas_Fair", "Christmas_GingerbreadMan", "Christmas_Ice_skating", "Christmas_Santa_House", "Christmas_Santas_Reinde",
    "Christmas_Snow_fortress", "Christmas_Snowman", "Christmas_Urban_tree", "Christmas_angel", "Christmas_fence",
    "Christmas_gifts", "Christmas_lantern", "Christmas_presentsock", "Christmas_scene", "Christmas_train",
    "Circus_Camping", "Color_Egg", "Connect_Station", "Cover_Gift", "CowArtist",
    "Cowboy_Tower", "Crab_Cook", "CraneFountain", "Cycle_Parking", "Decor_FlowerShop",
    "Decor_Ropepark", "Decor_TreeHouse", "Dino_Safe", "DiscoDecorationSP8", "DroneRace_plane",
    "Easter2017Decor", "EasterStump", "EasterVineyard", "Easter_bunnies", "Easter_fence",
    "Easter_fountain", "EgyptPapyrusBoat", "EgyptPharaohStatue", "EgyptPyramid", "ExpeditionDecoration",
    "ExpeditionDecoration10", "ExpeditionDecoration11", "ExpeditionDecoration12", "ExpeditionDecoration13", "ExpeditionDecoration14",
    "ExpeditionDecoration15", "ExpeditionDecoration16", "ExpeditionDecoration17", "ExpeditionDecoration18", "ExpeditionDecoration19",
    "ExpeditionDecoration2", "ExpeditionDecoration20", "ExpeditionDecoration21", "ExpeditionDecoration22", "ExpeditionDecoration25",
    "ExpeditionDecoration3", "ExpeditionDecoration34", "ExpeditionDecoration37", "ExpeditionDecoration38", "ExpeditionDecoration39",
    "ExpeditionDecoration4", "ExpeditionDecoration40", "ExpeditionDecoration41", "ExpeditionDecoration5", "ExpeditionDecoration6",
    "ExpeditionDecoration7", "ExpeditionDecoration8", "ExpeditionDecoration9", "Fairy_Fountain", "Fashion_Boutique",
    "FinalReward_gardenCinema", "Flower_Statue", "Flower_Store", "GhostGarden", "Giant_Snowman",
    "Ginger_House", "GingerbreadManHotChocolate", "Glamping_Camp", "Glamping_House", "GlassBridge",
    "Gold_Diggers", "Gothic_Tower", "Grape_Press", "Greenhouse_Predator", "Hall_Fame",
    "Halloween2017Decor", "Halloween_Organ", "Halloween_Park", "Happy_Aquarium", "Headless_Horseman",
    "HelixJump_TreasureIsland", "Helix_Pazzles", "Horn_Harvest", "Horse_Carousel", "HotDogSwing",
    "Hot_Fountain", "HouseEgyptian", "House_Garden", "IceExhibition_runner", "Installation_Insomnia",
    "InstrumentWorkshop", "JazzClub", "JurassicPark", "KidsRailway", "KingdomCentre",
    "LandscapesIcon", "LiraFountain", "LoveLock", "LoveTunnel", "Marsh_treasure",
    "Mechanic_Car", "MegaCake", "Merge2Decoration1", "Merge2Decoration10", "Merge2Decoration11",
    "Merge2Decoration12", "Merge2Decoration2", "Merge2Decoration3", "Merge2Decoration4", "Merge2Decoration5",
    "Merge2Decoration6", "Merge2Decoration7", "Merge2Decoration8", "Merge2Decoration9", "MiniTownship",
    "Mobile_Market", "MountainChalet_CozyHouse", "MountainChalet_HuskyHouse", "MusicCarousele", "Music_Scene",
    "NewCinema_gatsby", "New_Year", "NewyearGlobe", "Notre_Dame", "Olympic_Baseballtraining",
    "Olympic_Snowmachine", "Organic_Shop", "Palace_of_the_sky", "PaletteSculpture", "Paris_Street",
    "PencilHouse_art", "PigOscar", "PinSculpture", "PirateFort", "Plank_Decor",
    "Plank_Jeep", "Plank_Shop", "Plank_Werewolf", "Pumpkin_House", "Pumpkin_Metro",
    "RainbowArch", "RestoratorBuild2", "Rialto_Bridge", "SailingRaft_treasure", "SaleSquare",
    "Saloon_GrayMouse", "SantaSleigh", "Santa_Reception", "SculptureExhibition_art", "SeaFence_fence",
    "SheepElf_runner", "SheepSlide", "ShipTower", "Ship_Fight", "Ski_Shop",
    "SmallWaterfall", "Snowman", "SpaceRocket", "SpecialBeauty_AlbatrossOnBoat", "SpecialBeauty_Aquarium",
    "SpecialBeauty_AquaticJetpack", "SpecialBeauty_AstrologerTower", "SpecialBeauty_AvtoAttraction", "SpecialBeauty_Banner", "SpecialBeauty_BathyscaphDive",
    "SpecialBeauty_BeePilot", "SpecialBeauty_BirthdayBanner", "SpecialBeauty_BoatWithPirateFlag", "SpecialBeauty_BonfireCamp", "SpecialBeauty_CaptainStatueSeason",
    "SpecialBeauty_China_dragon", "SpecialBeauty_China_fish", "SpecialBeauty_China_house", "SpecialBeauty_China_lantern", "SpecialBeauty_China_lightTree",
    "SpecialBeauty_China_maneki", "SpecialBeauty_China_monkey", "SpecialBeauty_CityDay_arch_of_flowers", "SpecialBeauty_CityDay_boat_of_flowers", "SpecialBeauty_CityDay_flowerbed_car",
    "SpecialBeauty_CityDay_pavlin", "SpecialBeauty_CityDay_sheeps", "SpecialBeauty_CommonwealthStatue", "SpecialBeauty_Digging_Tyrannosaurus", "SpecialBeauty_Dovecote",
    "SpecialBeauty_EasterRabbit", "SpecialBeauty_EasterSymbol", "SpecialBeauty_EasterTopiary", "SpecialBeauty_Easter_ChocolateFoun", "SpecialBeauty_Easter_EasterBunny",
    "SpecialBeauty_Easter_EasterChicken", "SpecialBeauty_Easter_EasterTree", "SpecialBeauty_Easter_FabergeEgg", "SpecialBeauty_Easter_FabergeEgg_blue", "SpecialBeauty_Easter_RabbitHouse",
    "SpecialBeauty_Easter_SpringGirl", "SpecialBeauty_Excalibur", "SpecialBeauty_FrogStatue", "SpecialBeauty_FruitBridge", "SpecialBeauty_FruitKiosk",
    "SpecialBeauty_Ghostbuster", "SpecialBeauty_GiantWatermelon", "SpecialBeauty_HelicopterTrampoline", "SpecialBeauty_HorrorHorses", "SpecialBeauty_InflatableCastle",
    "SpecialBeauty_KidKite", "SpecialBeauty_KingsThrone", "SpecialBeauty_LanternGhost", "SpecialBeauty_MechanicalRodeo", "SpecialBeauty_MedievilCarrige",
    "SpecialBeauty_MedievilTaverna", "SpecialBeauty_OctopusChest", "SpecialBeauty_PirateTavern", "SpecialBeauty_PumpkinWheel", "SpecialBeauty_RomanticDinner",
    "SpecialBeauty_RuinsDive", "SpecialBeauty_RunwayAirplane", "SpecialBeauty_SeaCarousel", "SpecialBeauty_ShipGun", "SpecialBeauty_SpiderTree",
    "SpecialBeauty_StatueFisherman", "SpecialBeauty_StatueOfTheCook", "SpecialBeauty_StatueWorkTogether", "SpecialBeauty_Sun", "SpecialBeauty_SwingPlane",
    "SpecialBeauty_ThreeHouses", "SpecialBeauty_Totem", "SpecialBeauty_TreeBroccoli", "SpecialBeauty_TruckCamping", "SpecialBeauty_Valentine_flowercart",
    "SpecialBeauty_WaterMill", "SpecialBeauty_WaterTower", "SpecialBeauty_ancor", "SpecialBeauty_animal_tower", "SpecialBeauty_bioplan",
    "SpecialBeauty_birthday_ballon", "SpecialBeauty_chef_balloon", "SpecialBeauty_china_dragon2017", "SpecialBeauty_cockleshell", "SpecialBeauty_firerooster",
    "SpecialBeauty_fishermans_house", "SpecialBeauty_flooded_tower", "SpecialBeauty_flyButterfly", "SpecialBeauty_flyChicken", "SpecialBeauty_flyCow",
    "SpecialBeauty_flyDuck", "SpecialBeauty_flyElep", "SpecialBeauty_flyOctopus", "SpecialBeauty_flyParrot", "SpecialBeauty_flyPenguin",
    "SpecialBeauty_flyPig", "SpecialBeauty_flyPlane", "SpecialBeauty_flySheep", "SpecialBeauty_flyTurtle", "SpecialBeauty_flyWhale",
    "SpecialBeauty_fountain_restourante", "SpecialBeauty_galorobot", "SpecialBeauty_harvest_figure", "SpecialBeauty_ice_cream_cafe", "SpecialBeauty_jumping_fish",
    "SpecialBeauty_mermaid", "SpecialBeauty_mobile_coffee_truck", "SpecialBeauty_octopus", "SpecialBeauty_paukohod", "SpecialBeauty_perpetumlucerna",
    "SpecialBeauty_planeAmphibian", "SpecialBeauty_plungerDive", "SpecialBeauty_redBridge", "SpecialBeauty_seahorse", "SpecialBeauty_statue_pig",
    "SpecialBeauty_topiary_egg", "SpecialBeauty_walking_castle", "SpecialBeauty_wealth_bowl", "SpecialBeauty_whalefountain_fishing", "Summer_Cafe",
    "Surf_Decor", "Surf_Pool", "Surf_Rental", "Surf_Sale", "Surfingers_Trampoline",
    "Sweet_Tree", "Tiki_Bar", "TouristParking_treasure", "Tower_of_Pisa", "Town_Fair",
    "TrainConductor", "Tree_Market", "Tree_sakura", "Trio", "Trucks_Decotor",
    "Trucks_PirateBistro", "Valentine_Bunny", "Valentine_CupidsArrow", "Valentine_Flowerbed", "Valentine_Gazebo_lovers",
    "Valentine_Pond_with_swans", "Valentine_Statue_Lovers", "Valentine_Statue_of_cupid", "Valentine_Swing_lovers", "Valentine_Teddy_bear",
    "Valentine_Teddy_bear2", "Valentine_Topiary", "Valentine_cats", "Valentine_diamond_heart", "Valentine_fountain_eternallove",
    "Valentine_heartInHands", "Valentine_heart_pedestal", "Valentine_justMarried", "Valentine_key", "Valentine_lovearch",
    "Valentine_lovers_bench", "Valentine_lovers_cart", "Valentine_moon_from_heaven", "Valentine_peacock_inlove", "Valentine_pigeons_love",
    "Valentine_plush_cat", "Valentine_postsheep", "Valentine_serenade", "Valentine_statue_prince", "Valentine_topiary_hearts",
    "Wagon_Mountain", "Watchtower", "WaterBungalowSP9", "Wedding3D_Decor", "WitchPot",
    "WitchStatue_halloween", "airboat_plank", "airship_base", "ancient_bridge", "apple_tree",
    "aquapark_helix", "aquariumHouse_fishing", "aquarium_v1", "arabic_al_ain_palace", "arabic_horse_statue",
    "arabic_jin_lamp", "arabic_oasis", "arbor", "archaeology_atlantis", "archery_runner",
    "asphalt", "bagrunning_easter", "ballShooting_helix", "baloon_castle", "baloons",
    "bamboo_runner", "baobab", "bar_fin", "baseball", "basketball_1x2",
    "beach_dance_floor", "beach_fruit_mix", "beach_party_bar", "beach_yellow_submarine", "bears_family",
    "beauty_3_ballon", "beauty_5y_monument", "beauty_Coconut_bar", "beauty_DivingTower_olympiad", "beauty_Flower_gates",
    "beauty_FootballDog", "beauty_Goalkeeper", "beauty_Gong", "beauty_Luxury_gates", "beauty_MovieFountain",
    "beauty_OlympicFountain", "beauty_SketebordPlace", "beauty_SuperheroStand", "beauty_TrainingGround_olympiad", "beauty_acacia_giraffe",
    "beauty_acrobats_stilts", "beauty_ancient_drums", "beauty_ancient_town", "beauty_animals_pasta", "beauty_araguaney",
    "beauty_arch_balloon", "beauty_artist_quarter", "beauty_astronomer_tower", "beauty_atlantis_aquarium", "beauty_atlantis_boulevard",
    "beauty_atlantis_hotel", "beauty_atlantis_ruins", "beauty_atlantis_statue", "beauty_atlas_hand", "beauty_balloon_dancer",
    "beauty_baloon_flowers", "beauty_burdzh_halifa", "beauty_cancer_hermit", "beauty_candy_bridge", "beauty_candy_carousel",
    "beauty_candy_house", "beauty_candy_tree", "beauty_carousel", "beauty_cave_in_jungle", "beauty_chalk_elephant",
    "beauty_chalk_jiraffe", "beauty_chalk_lion", "beauty_chalk_zebra", "beauty_children_pirates", "beauty_china_town",
    "beauty_coloring_cubes", "beauty_confectioner_cow", "beauty_coral_garden", "beauty_cottage_horn", "beauty_delonix",
    "beauty_diamond", "beauty_dinosaur", "beauty_divers_boat", "beauty_dog_ballon", "beauty_dogs_arctic",
    "beauty_dolphins", "beauty_dragon_boat", "beauty_dragon_dance", "beauty_easter_lantern", "beauty_easter_stump",
    "beauty_elephants", "beauty_elf_house", "beauty_experiment_knowledgetower", "beauty_experiment_laboratory", "beauty_experiment_monument",
    "beauty_experiment_plasma", "beauty_experiment_projector", "beauty_finic_palm", "beauty_fireworkshop", "beauty_fish_ballon",
    "beauty_fish_market", "beauty_floral_sheeps", "beauty_flower_vase", "beauty_flowerhouse", "beauty_flyHouse",
    "beauty_flyMedusa", "beauty_flyingship", "beauty_friendBench_fday", "beauty_ghost_ship", "beauty_goldberg_machine",
    "beauty_gondola", "beauty_graffiti_competition", "beauty_greengrocery", "beauty_halloween_scary_crypt", "beauty_halloween_skeleton_orchestra",
    "beauty_houseMaldives", "beauty_iceDeer", "beauty_ice_castle", "beauty_iceberg", "beauty_iceberg_penguin",
    "beauty_icebreaker", "beauty_jirafe_dall", "beauty_juggler", "beauty_jungle_monk", "beauty_jungle_riverhouse",
    "beauty_jungle_ruins", "beauty_jungle_sanctuary", "beauty_jungle_totems", "beauty_lake_house", "beauty_large_sundial",
    "beauty_luxury_house", "beauty_mammoth", "beauty_party_pirates", "beauty_peacock_statue", "beauty_pine_tree",
    "beauty_pirate_ship_bow", "beauty_pizzeria_pasta", "beauty_plane_steam", "beauty_plane_vought_v173", "beauty_playground2",
    "beauty_plushSheep", "beauty_polarStation", "beauty_polar_bear", "beauty_poseidon", "beauty_prehistoric_house",
    "beauty_primitive_artist", "beauty_puddleJumper", "beauty_pyramid_knife", "beauty_rhino", "beauty_rhododendron",
    "beauty_runner_cablecar", "beauty_sailboat", "beauty_saloon", "beauty_santa_plank", "beauty_sea_researchers",
    "beauty_seahouse_decoration", "beauty_sequoia", "beauty_serf_pool", "beauty_shipUlysses_ancient", "beauty_ship_pool",
    "beauty_simulator_plane", "beauty_skatingPenguins", "beauty_snowfortress", "beauty_snowman_skater", "beauty_snowslide",
    "beauty_solar_system", "beauty_souvenir_shop", "beauty_space_cosmonaut_cow", "beauty_space_mars_rover", "beauty_space_shuttle",
    "beauty_stonehenge", "beauty_submarine", "beauty_sweet_hill", "beauty_swing_giraffe", "beauty_swing_palm",
    "beauty_tarzan_tree", "beauty_thai_temple", "beauty_throwing_knives", "beauty_titans", "beauty_torchbearer_olympiad",
    "beauty_treasure_chest", "beauty_tree_ballon", "beauty_triathlon_runner", "beauty_ufo", "beauty_venus_flytrap",
    "beauty_waterSlide", "beauty_water_monster", "beauty_watercraft", "beauty_winners_place_olympiad", "beauty_winter_cannon",
    "beauty_wisteria", "beauty_yeti", "berryTree_knife", "bigPicnic", "bigTractor_rescue",
    "big_ban", "birthdaynineDecoration", "blender_knife", "boat00_fin", "boat02_fin",
    "bookTree_jungle", "bridge00_fin", "bridge01_fin", "bronze_bull", "buek1",
    "buek2", "buek3", "buek4", "buek5", "buek6",
    "buek7", "buek8", "bullStatue_runner", "cactus", "cafe_rescue",
    "camping", "camping_wildwest", "candyCastle_helix", "candyTrain_surfingers", "candy_fence",
    "candy_gate", "candy_rainbow", "captainStatue_pirate", "caramelApple_surfingers", "carousel_elephants",
    "carousel_helix", "carousel_runner", "cartRace_blackfriday", "castle", "chamber_halloween",
    "champion_cup", "chess_arabic", "chickchik", "christmasComing", "christmasPlace_xmas2022",
    "christmasTree_xmas2022", "christmas_santa_helper", "christmas_snowball", "coconutArmchair_bungalow", "colorFountain_match3",
    "contactZoo_rescue", "cowboyStatue_wildwest", "craftsmanWorking_egypt", "crater", "crocodile",
    "curling_runner", "dalesIcon", "danceMachine_helix", "dancingFountains", "darkForestWithTrainSign",
    "deerRiding_plank", "dirigeablestatue", "discoForever_music", "discusThrower_ancient", "dragon_statue_SP_800",
    "dynamometer_rescue", "easterHammock", "easterRailroad", "easterRibbons", "easter_factory",
    "easter_pond", "easterhouse_tree", "easternBazar", "eifel_tower", "empire_state_v1",
    "expandBuyAvailable", "fair_rescue", "fairy_water", "falcon_hunting", "farmmusic",
    "figureSkating_xmas2022", "filmmaking_treasure", "flag", "flamingo", "floating_lanterns",
    "flowerUnderHood", "flower_fence", "flower_hedge", "flower_house", "flower_swing",
    "flowerbed1", "flowerbed2", "flowerbed_daffodils", "flowerbed_gerbera", "flowerbed_gladiolus",
    "flowerbed_irises", "flowerbed_poppies", "flowering_tree", "flyBee", "flyDragon",
    "flyLantern_santa", "flyPanda", "flyValentineBalloons", "flyValentineCupid", "flyingShip_treasure",
    "foodshow_burger", "football", "fountain1", "fountain2", "fountain4",
    "fountain_swan", "fountain_tree", "fountain_whale", "fountainbig", "freedom_v1",
    "fruitFootball_knife", "fruitPark_knife", "fruitSlicing_knife", "gallery_art", "gameboy_helix",
    "gardens_arabic", "ghostlyCarriage", "giantVegetables_rescue", "girrafe", "globalFlight_plane",
    "gnomes", "golden_gate", "gorilla", "granite_fence", "gravelroad",
    "green", "green10", "green12", "green14", "green16",
    "green18", "green2", "green20", "green5", "green5_2",
    "green8", "green9", "green_bird", "green_bunny", "green_dolphin",
    "green_elephant", "green_peacock", "green_tree1", "green_tree2", "green_tree3",
    "green_turtle", "greenbox_fin", "ground", "groundroad", "halloween_castle",
    "halloween_cat", "halloween_fountain", "halloween_gargoyle", "halloween_ghost_ship", "halloween_haunted_house",
    "halloween_museum", "halloween_pump", "halloween_sarcophagus", "halloween_scarecrow", "halloween_tree",
    "halloween_witch", "halloween_witch_hire", "hay", "heartTree_valentine", "hedge",
    "helmetOctopus_ancient", "hockeyField_runner", "hotSpring_match3", "iceArch_arctic", "iceDragon",
    "iceLake", "iceSculptures_plank", "ice_dino", "iglu", "installation_art",
    "island_knife", "jakaranda", "jellyBounce", "jetpack_plane", "juice_fountain",
    "katamaran", "kitchen_plank", "koala", "labyrinth_easter", "lakehouse_boattrip",
    "lakehouse_home", "landing_fence", "lastHour_plank", "lifeguard_hut", "lion",
    "lion_slides", "lookout_point", "loveTower", "loveWings", "love_bridge",
    "love_flowers", "lovegarden", "lowriders_rescue", "luxury_fence", "mammoth_match3",
    "maya_calendar", "mechDragon_medieval", "mechStrawman", "minotaur_ancient", "monkeys_plank",
    "monument1", "monument2", "monument3", "monument4", "monument5",
    "monument_tools", "movieMonument", "movieMuseum", "museum_atlantis", "musicQuarter_music",
    "ninja_knife", "noodle_shop", "oasis_egypt", "oilDerrick", "olympicVillage_runner",
    "organ_music", "palmHotel", "palma1", "palma2", "palma4",
    "palma_totem", "panda", "park1_1x1", "park1_1x2", "park2_1x1",
    "parking_common", "parking_green_side", "parking_green_yard", "penguin", "penguinIcehole_xmas2022",
    "petronas", "phone_box", "photoStand_valentine", "picnic", "pinball_helix",
    "pineapple_knife", "pirateShip_treasure", "pirateStatue_treasure", "pizzacutting_pasta", "planeAircraftReward",
    "plank1_fin", "plank3_fin", "playground", "plushUnicorn_valentine", "polarman_arctic",
    "pond", "pondSwans", "pond_mother_earth", "pond_with_carp", "pool",
    "pumpkinrace", "pyramide", "quay_fin", "quiosk_plank", "radar",
    "radiorace_rescue", "railway_station", "rainbowFair_helix", "ratGarden_jump", "redLiliesPond",
    "reef_hedge", "reserve1x2_v1", "reserve2x2_v1", "reserve3x3_v1", "retro_avto",
    "ringGame_surfingers", "roadsIcon", "robocafe_cakeshop", "rockCat_music", "rodeoHelic_runner",
    "roman_chariot", "rose_bush", "rugby_stadium", "sailHotel", "sailing_race",
    "sand", "sausage_restorator", "scarab_egypt", "scarecrow", "scriptorium_medieval",
    "sculptor_ancient", "seaStation_dive", "sea_gate", "seal", "seasonCinecamera_cinema",
    "seasonUfoStudio_cinema", "shack", "shark_slide", "shearedTree", "shellgame_helix",
    "ship", "shipAttraction_pirate", "shooting_rescue", "skin_city_sign_IronCitySign", "skin_city_sign_MillSign",
    "skin_city_sign_SP_790_sign", "skin_city_sign_TV_city_sign", "skin_city_sign_arabic_sign", "skin_city_sign_asian_sign", "skin_city_sign_birthday_10years",
    "skin_city_sign_birthday_sign", "skin_city_sign_cactus_sign", "skin_city_sign_christmas_sign", "skin_city_sign_cinema_sign", "skin_city_sign_cow_sign",
    "skin_city_sign_def_sign", "skin_city_sign_disco_city_sign", "skin_city_sign_dry_fountain_sign", "skin_city_sign_easter_sign", "skin_city_sign_expedition22_2200_sign",
    "skin_city_sign_expedition23_2200_sign", "skin_city_sign_expedition24_2300_sign", "skin_city_sign_expedition25_2300_sign", "skin_city_sign_expedition26_2400_sign", "skin_city_sign_expedition27_2400_sign",
    "skin_city_sign_expedition28_2500_sign", "skin_city_sign_expedition29_2500_sign", "skin_city_sign_expedition30_2600_sign", "skin_city_sign_expedition31_2600_sign", "skin_city_sign_expedition32_2700_sign",
    "skin_city_sign_expedition33_2700_sign", "skin_city_sign_expedition36_2900_sign", "skin_city_sign_farm_sign", "skin_city_sign_flowerbed_sign", "skin_city_sign_frank_halloween",
    "skin_city_sign_furniture_sign", "skin_city_sign_halloween_sign", "skin_city_sign_harvest_sign", "skin_city_sign_ilove_sign", "skin_city_sign_lamp_board_sign",
    "skin_city_sign_mechanic_sign", "skin_city_sign_music_sign", "skin_city_sign_mystical_events", "skin_city_sign_neon_sign", "skin_city_sign_palm_trees",
    "skin_city_sign_regatta_2100_sign", "skin_city_sign_regatta_2300_sign", "skin_city_sign_regatta_2400_sign", "skin_city_sign_regatta_3000_sign", "skin_city_sign_regatta_3100_sign",
    "skin_city_sign_rock_sign", "skin_city_sign_ruminant_machine", "skin_city_sign_smoothiebar_sign", "skin_city_sign_snowboard_sign", "skin_city_sign_stone_sign",
    "skin_city_sign_vegas_sign", "skin_city_sign_wild_west_sign", "skin_city_sign_winged_sign", "skin_city_sign_wooden_sign", "skisCow_olympiad",
    "slide_match3", "small_green_tree_04", "snow", "snowFight_plank", "snowboardSheep_olympiad",
    "snowboard_runner", "southernflowers", "spacegarden", "spaceneedle_v1", "sphinx_v1",
    "stairs_match3", "statue_artist", "statue_boat_gold", "statue_chemist", "statue_fireman",
    "statue_flyboy", "statue_footballer", "statue_general", "statue_geneticist", "statue_musican",
    "statue_neanderthal", "statue_policeman", "statue_thinker", "statue_tourist", "statue_writer",
    "stork_statue", "stream_hedge", "streetCinema_cakeshop", "sunflower", "swan",
    "sydney_opera", "tajmahal_v1", "teahouse", "tennis", "thanksgiving_CarrotTree",
    "thanksgiving_vegetableBasket", "thanksgiving_vegetableHouse", "thanksgiving_vegetablePlace", "theaterOdeon_ancient", "throneHall_medieval",
    "tiger", "topiary_castle", "topiary_competition", "toyMachine_helix", "track",
    "tractor_and_hay", "trainchicken", "travelingTruck_rescue", "tree_adenium", "tree_shaping",
    "tree_with_stairs", "trojanHorse_ancient", "trouveres_medieval", "turbosledge_santa", "ufoClue",
    "upsideDownHouse_bungalow", "vegetables", "vetryak", "village_jungle", "water",
    "water_flowers_1", "water_flowers_2", "waterfall_mountain_surfingers", "wateringCan_easter", "weeping_willow",
    "weightlifter_runner", "well", "white_fence", "whiterose_tree", "wildpark",
    "wildwest_cinema", "windmill", "winterYurt_xmas2022", "wishingWell", "workshopCrash",
    "yacht", "yacht_fin", "yellow_roses", "young_gardeners", "zebra",
    "zoo_caffe", "zoo_cinema", "zoo_cocktail_store", "zoo_contact", "zoo_decor",
    "zoo_eatery", "zoo_icecream_shop", "zoo_restaurant", "zoo_shop",
}
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
        label = "『مستويات المطابقة المكتملة』", 
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
        label = "『إظهار جميع الأحداث』",
        type = "checkbox",
        edit = "showAllEvents"
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
        label = "『المظاهر』",
        type = "checkbox",
        edit = "skins"
    },

    {
        label = "『الديكورات』",
        type = "checkbox",
        edit = "allDecor"
    },
    {
        label = "『صور』",
        type = "checkbox",
        edit = "unlockAllAvatars"
    },
    {
        label = "『الملصقات』",
        type = "checkbox",
        edit = "chatEmojis"
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
        label = "『فتح التذكرة الذهبية + جميع الجوائز』",
        type = "checkbox",
        edit = "goldenTicket"
    },
    {
        label = "『فتح التذكرة الذهبية 2 + المسارين』",
        type = "checkbox",
        edit = "goldenTicket2"
    },
    {
        label = "『العملات الذهبية』",
        type = "number",
        edit = "money"
    },
    {
        label = "『الكاش』",
        type = "number",
        edit = "moneyCash"
    },
    {
        label = "『تاريخ بدء اللعبة』",
        type = "text",
        edit = "gameStartDate"
    },
    {
        label = "『ترقية الشونة الدائمة』",
        type = "number",
        edit = "barnCapacity"
    },
    {
        label = "『عملات الإطار』",
        type = "number",
        edit = "frameCoins"
    },
    {
        label = "『زيادة المنتجات بالشونة』",
        type = "checkbox",
        edit = "barnMenu"
    },
    {
        label = "『قطار القمح 1️⃣』",
        type = "checkbox",
        edit = "trainPresetWheat"
    },
    {
        label = "『قطار التاج5️⃣0️⃣0️⃣』",
        type = "checkbox",
        edit = "trainPresetDiadem"
    },
    {
        label = "『قطار الجزر 9️⃣9️⃣9️⃣9️⃣』",
        type = "checkbox",
        edit = "trainPresetCarrot"
    }

}

-- المعرفات الداخلية للقسائم كما يستخدمها التطبيق والسيرفر.
local APP_COUPON_IDS = {
    ["قسيمة ترقية المصانع"] = "CouponUpgradeFactory",
    ["قسيمة ترقية الجزيرة"] = "CouponUpgradeIsland",
    ["قسيمة ترقية القطار"] = "CouponUpgradeTrain",
    ["قسيمة التحميل"] = "CouponLoadTrainAirport",
    ["قسيمة التوسعة"] = "freeExpansion",
    ["قسيمة الشونة"] = "freeAmbarInc",
    ["قسيمة التاجر"] = "CouponHireDealer"
}

-- تظهر موارد القائمة الفرعية داخل القائمة الرئيسية، مع إبقاء المفتاح داخليًا فقط.
for _, category in ipairs(APP_RESOURCE_CATEGORIES) do
    for _, item in ipairs(category.items) do
        table.insert(OPTIONS, {
            label = "『" .. category.name .. "』 " .. item.key,
            type = "checkbox",
            edit = "resourceItem",
            resourceKey = resourceInternalKey(item.key),
            resourceLabel = item.key,
            resourceCategory = category.name,
            couponName = APP_COUPON_IDS[item.key]
        })
    end
end

-- تقسيم الواجهة دون حذف أي خيار من السكربت.
-- race: الحقول/الإدخالات والإطارات والشارات والأحداث والألقاب والأرضي والكروت والصور والملصقات.
local RACE_CHECKBOXES = {
    showAllEvents=true, unlockedFrames=true, unlockedStyles=true, UnlockedBadges=true,
    unlockedExpRanks=true, goldenTicket=true, goldenTicket2=true, unlockAllCards=true, unlockLandExpansions=true,
}
local function optionInSection(option, section)
    local cat = option.resourceCategory or ""
    if section == "race" then
        return option.type ~= "checkbox" or RACE_CHECKBOXES[option.edit] == true
    elseif section == "coupons" then
        return cat == " ♡BS♡"
    elseif section == "trains" then
        return option.edit == "trainPresetWheat" or option.edit == "trainPresetDiadem" or option.edit == "trainPresetCarrot"
    elseif section == "lab" then
        return cat == " ♡BS♡"
    elseif section == "decoration" then
        return option.edit == "skins" or option.edit == "allDecor" or option.edit == "unlockAllAvatars" or option.edit == "chatEmojis"
    elseif section == "barn" then
        return option.edit == "barnMenu"
    elseif section == "other" then
        if option.type ~= "checkbox" then return false end
        if RACE_CHECKBOXES[option.edit] then return false end
        if option.edit == "trainPresetWheat" or option.edit == "trainPresetDiadem" or option.edit == "trainPresetCarrot" then return false end
        if option.edit == "skins" or option.edit == "allDecor" or option.edit == "unlockAllAvatars" or option.edit == "chatEmojis" or option.edit == "barnMenu" then return false end
        if cat == " ♡BS♡" or cat == " ♡BS♡" then return false end
        return true
    end
    return true
end
local requestedSection = rawget(_G, "BS_TOOL_SECTION") or "race"
local filteredOptions = {}
for _, option in ipairs(OPTIONS) do
    if optionInSection(option, requestedSection) then table.insert(filteredOptions, option) end
end
OPTIONS = filteredOptions

-- GameGuardian may not expose error() globally; use assert to raise a catchable Lua error.
local function raiseError(message)
    -- assert يعمل في جميع نسخ GameGuardian ويُبقي تفاصيل الخطأ قابلة للالتقاط
    -- بواسطة pcall في المشغل الخارجي.
    assert(false, tostring(message or "حدث خطأ غير معروف"))
end
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

        raiseError(
            "تعذر فتح ملف الإدخال: " .. tostring(path)
        )

    end

    local data =
        f:read("*a")

    f:close()

    if not data or #data == 0 then

        raiseError(
            "ملف الإدخال فارغ: " .. tostring(path) .. "\nتأكد أن حفظ اللعبة مكتمل وأن المزرعة المختارة صحيحة."
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

local function write_file(path, data)
    if type(data) ~= "string" or #data == 0 then
        raiseError("لن تتم كتابة الملف لأن البيانات المستلمة فارغة أو غير صالحة: " .. tostring(path))
    end

    local tempPath = path .. ".tmp"
    -- اكتب الناتج في ملف مؤقت، ولا تلمس ملف الحفظ الأصلي بعد.
    local temp, tempErr = io.open(tempPath, "wb")
    if not temp then raiseError("تعذر إنشاء الملف المؤقت: " .. tostring(tempErr)) end
    local writeOk, writeErr = pcall(function()
        temp:write(data)
        temp:flush()
        temp:close()
    end)
    if not writeOk then
        pcall(function() temp:close() end)
        raiseError("فشلت كتابة الملف المؤقت: " .. tostring(writeErr))
    end

    local verify = io.open(tempPath, "rb")
    local saved = verify and verify:read("*a") or nil
    if verify then verify:close() end
    if saved ~= data then
        raiseError("فشل التحقق من الملف المؤقت؛ لم يتم تغيير ملف الحفظ الأصلي.")
    end

    local renameOk, renameErr = os.rename(tempPath, path)
    if not renameOk then
        raiseError("فشل استبدال ملف الحفظ: " .. tostring(renameErr))
    end
end


-- ============================================
-- POST
-- ============================================

local function saveErrorLog(details)
    return false
end
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
        raiseError("تعذر الاتصال بالسيرفر أثناء تنفيذ العملية: " .. tostring(response))
    end

    -- فحص نوع الاستجابة
    if type(response) == "string" then
        raiseError("تعذر قراءة نتيجة العملية من السيرفر")
    end

    if type(response) ~= "table" then
        raiseError("تعذر قراءة نتيجة العملية من السيرفر")
    end

    local code = tonumber(response.code)
    local content = response.content

    if not code then
        raiseError("تعذر التحقق من نتيجة العملية")
    end

    if code < 200 or code >= 300 then
        local detail = tostring(content or "")
        if detail == "" then detail = "(رد الخادم فارغ)" end
        if #detail > 3000 then detail = detail:sub(1, 3000) .. "\n[تم اختصار الرد]" end
        raiseError("استجابة الخادم HTTP " .. tostring(code) .. ":\n" .. detail)
    end

    if type(content) ~= "string" or content == "" then
        raiseError("السيرفر أعاد HTTP " .. tostring(code) .. " دون بيانات صالحة للملف. الرد: " .. tostring(content or "(رد الخادم فارغ)"))
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
    local trainProductId = nil
    local trainProductCount = nil
    local trainOrderBlue = false
    local trainClearBox = false
    local trainPreset = nil
    local resourceSpec = nil
    local skinsSpec = nil
    local decorSpec = nil
    local resourceBatch = nil
    local couponSpec = nil
    local barnSpec = nil
    local barnBatch = nil


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

        elseif edit.type == "trainProductId" then
            trainProductId = tostring(edit.value or "")
        elseif edit.type == "trainProductCount" then
            trainProductCount = tonumber(edit.value)
        elseif edit.type == "trainOrderBlue" then
            trainOrderBlue = edit.value == true
        elseif edit.type == "trainClearBox" then
            trainClearBox = edit.value == true
        elseif edit.type == "trainPresetWheat" then
            if trainPreset ~= nil then raiseError("اختر خيار قطار واحد فقط.") end
            trainPreset = {productId = "wheat", productCount = 1}
        elseif edit.type == "trainPresetDiadem" then
            if trainPreset ~= nil then raiseError("اختر خيار قطار واحد فقط.") end
            trainPreset = {productId = "diadem", productCount = 500}
        elseif edit.type == "trainPresetCarrot" then
            if trainPreset ~= nil then raiseError("اختر خيار قطار واحد فقط.") end
            trainPreset = {productId = "carrot", productCount = 9999}
        elseif edit.type == "skins" then
            if skinsSpec ~= nil then raiseError("اختر المظاهر مرة واحدة فقط.") end
            skinsSpec = edit.value
        elseif edit.type == "allDecor" then
            if decorSpec ~= nil then raiseError("اختر الديكورات مرة واحدة فقط.") end
            decorSpec = edit.value
        elseif edit.type == "resource" then
            if resourceSpec ~= nil then raiseError("استخدم موردًا واحدًا في كل طلب.") end
            if type(edit.value) == "table" then
                resourceSpec = edit.value
            else
                local name, amount = tostring(edit.value or ""):match("^%s*([A-Za-z][A-Za-z0-9_]*)%s*=%s*(%d+)%s*$")
                if not name or not amount then raiseError("صيغة المورد يجب أن تكون الاسم=العدد، مثل wheat=9999.") end
                resourceSpec = {name = name, value = tonumber(amount)}
            end
        elseif edit.type == "resourceBatch" then
            if resourceBatch ~= nil then raiseError("اختر مجموعة موارد واحدة فقط.") end
            resourceBatch = edit.value
        elseif edit.type == "coupon" then
            if couponSpec ~= nil then raiseError("استخدم قسيمة واحدة في كل طلب.") end
            if type(edit.value) ~= "table" or not edit.value.name then raiseError("بيانات القسيمة غير صحيحة.") end
            couponSpec = edit.value
        elseif edit.type == "barnItem" then
            if barnSpec ~= nil then raiseError("اختر عنصر شونة واحدًا فقط.") end
            barnSpec = edit.value
        elseif edit.type == "barnBatch" then
            if barnBatch ~= nil then raiseError("اختر مجموعة شونة واحدة فقط.") end
            barnBatch = edit.value

        end

    end


    -- ========================================
    -- بناء باقي التعديلات
    -- ========================================

    for _, edit in ipairs(edits) do

        if edit.type ~= "regataTaskCount" and
           edit.type ~= "regataTaskPoint" and
           edit.type ~= "trainProductId" and
           edit.type ~= "trainProductCount" and
           edit.type ~= "trainOrderBlue" and
           edit.type ~= "trainClearBox" and
           edit.type ~= "trainAll" and
           edit.type ~= "trainPresetWheat" and
           edit.type ~= "trainPresetDiadem" and
           edit.type ~= "trainPresetCarrot" and
           edit.type ~= "resource" and
           edit.type ~= "resourceBatch" and
           edit.type ~= "coupon" and
           edit.type ~= "barnItem" and
           edit.type ~= "barnBatch" and
           edit.type ~= "skins" and
           edit.type ~= "allDecor" then

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

    if trainPreset ~= nil then
        trainProductId = trainPreset.productId
        trainProductCount = trainPreset.productCount
        trainOrderBlue = true
        trainClearBox = true
    end

    if skinsSpec ~= nil then
        if skinsSpec.all then
            table.insert(parts, '"skins":{"all":true}')
        else
            local values = {}
            for _, item in ipairs(skinsSpec) do table.insert(values, '"' .. json_escape(item) .. '"') end
            table.insert(parts, '"skins":{"selected":[' .. table.concat(values, ',') .. ']}')
        end
    end
    if decorSpec ~= nil then
        local decorJson = '"allDecor":{"count":' .. tostring(math.floor(decorSpec.count or 1))
        if decorSpec.all then
            decorJson = decorJson .. ',"all":true}'
        else
            local values = {}
            for _, item in ipairs(decorSpec.items or {}) do table.insert(values, '"' .. json_escape(item) .. '"') end
            decorJson = decorJson .. ',"items":[' .. table.concat(values, ',') .. ']}'
        end
        table.insert(parts, decorJson)
    end

    if resourceSpec ~= nil then
        table.insert(parts, '"resource":{"name":"' .. json_escape(resourceSpec.name) .. '","value":' .. tostring(resourceSpec.value) .. '}')
    end
    if resourceBatch ~= nil then
        local batchParts = {}
        for _, item in ipairs(resourceBatch) do
            table.insert(batchParts, '{"name":"' .. json_escape(item.name) .. '","value":' .. tostring(item.value) .. '}')
        end
        table.insert(parts, '"resourceBatch":[' .. table.concat(batchParts, ',') .. ']')
    end
    if couponSpec ~= nil then
        table.insert(parts, '"coupon":{"name":"' .. json_escape(couponSpec.name) .. '","value":' .. tostring(couponSpec.value) .. '}')
    end
    if barnSpec ~= nil then
        table.insert(parts, '"barnItem":{"name":"' .. json_escape(barnSpec.name) .. '","value":' .. tostring(barnSpec.value) .. '}')
    end
    if barnBatch ~= nil then
        local batchParts = {}
        for _, item in ipairs(barnBatch) do
            table.insert(batchParts, '{"name":"' .. json_escape(item.name) .. '","value":' .. tostring(item.value) .. '}')
        end
        table.insert(parts, '"barnBatch":[' .. table.concat(batchParts, ',') .. ']')
    end

    if trainProductId ~= nil or trainProductCount ~= nil then
        if trainProductId == nil or trainProductId == "" or trainProductCount == nil then
            raiseError("يجب إدخال نوع المنتج والكمية لمحرر القطار.")
        end
        table.insert(
            parts,
            '"trainAll":{' ..
            '"productId":"' .. json_escape(trainProductId) .. '",' ..
            '"productCount":' .. tostring(math.floor(trainProductCount)) .. ',' ..
            '"orderBlue":' .. (trainOrderBlue and "true" or "false") .. ',' ..
            '"clearBox":' .. (trainClearBox and "true" or "false") ..
            '}'
        )
    end

    local editsJson = "{" ..
           table.concat(
               parts,
               ","
           ) ..
           "}"
    editsJson = editsJson:gsub('"unlockedFrames":"true"', '"unlockedFrames":true')
    return editsJson

end


-- ============================================
-- EDIT STAGE
-- ============================================

local function edit_stage(
    decoded
)
    local preselectedEdits = rawget(_G, "BS_PRESELECTED_EDITS")
    local edits = preselectedEdits


    if not preselectedEdits then
    -- ترتيب الواجهة: كل حقول الإدخال أولًا، ثم خيارات التفعيل أسفلها.
    local orderedOptions = {}
    for _, option in ipairs(OPTIONS) do
        if option.type ~= "checkbox" then
            table.insert(orderedOptions, option)
        end
    end
    for _, option in ipairs(OPTIONS) do
        if option.type == "checkbox" then
            table.insert(orderedOptions, option)
        end
    end

    local labels = {}
    local defaults = {}
    local types = {}


    for i, option in ipairs(orderedOptions) do

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


    local input
    if requestedSection == "race" then
        -- قسم التعديل والسباق يبقى كما هو: حقول إدخال + خانات تفعيل.
        input = gg.prompt(
            labels,
            defaults,
            types
        )
    else
        -- الأقسام المنقولة تستخدم قائمة اختيار فقط، بدون لوحة كيبورد.
        local selected = gg.multiChoice(
            labels,
            nil,
            "💜ᗷᗩᔕᗰᗩᒪᗩ💜"
        )
        if selected then
            input = {}
            for i, checked in pairs(selected) do
                input[i] = checked == true
            end
        end
    end

    if not input then
        return
    end


    -- ========================================
    -- COLLECT EDITS
    -- ========================================

    edits = {}
    local barnMenuRequested = false
    local resourceMenuRequested = false
    local selectedResources = {}
    local selectedCoupons = {}
    local skinsRequested = false
    local decorRequested = false


    for i, option in ipairs(orderedOptions) do

    local value = input[i]

    if option.type == "checkbox" then

        -- لا تنفذ إلا الخيارات التي حددها المستخدم
        if value == true then
            if option.edit == "barnMenu" then
                barnMenuRequested = true
            elseif option.edit == "resourceMenu" then
                resourceMenuRequested = true
            elseif option.edit == "skins" then
                skinsRequested = true
            elseif option.edit == "allDecor" then
                decorRequested = true
            elseif option.edit == "resourceItem" then
                if option.resourceCategory == " ♡BS♡" then
                    table.insert(selectedCoupons, {
                        name = option.couponName,
                        label = option.resourceLabel
                    })
                else
                    table.insert(selectedResources, {
                        name = option.resourceKey,
                        label = option.resourceLabel
                    })
                end
            else
                table.insert(edits, { type = option.edit, value = true })
            end
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


    if barnMenuRequested then
        local selected = choose_catalog_items(APP_BARN_CATEGORIES, "الشونة")
        if not selected then return end
        table.insert(edits, {type = "barnBatch", value = selected})
    end
    if resourceMenuRequested then
        local selected = choose_catalog_items(APP_RESOURCE_CATEGORIES, "تعديل الموارد")
        if not selected then return end
        table.insert(edits, {type = "resourceBatch", value = selected})
    end

    if skinsRequested then
        local labels = {"✅ تحديد جميع المظاهر"}
        for _, id in ipairs(APP_SKIN_IDS) do table.insert(labels, id) end
        local selected = gg.multiChoice(labels, nil, "المظاهر — اختر المظاهر كما في التطبيق")
        if not selected then return end
        local values = {}
        local selectAll = selected[1] == true
        if selectAll then
            for _, id in ipairs(APP_SKIN_IDS) do table.insert(values, id) end
        else
            for i, checked in pairs(selected) do
                if checked and i > 1 then table.insert(values, APP_SKIN_IDS[i - 1]) end
            end
        end
        if #values == 0 then gg.alert("اختر مظهرًا واحدًا على الأقل."); return end
        table.insert(edits, {type = "skins", value = selectAll and {all = true} or values})
    end

    if decorRequested then
        local labels = {"✅ تحديد جميع الديكورات"}
        for _, id in ipairs(APP_DECOR_IDS) do table.insert(labels, id) end
        local selected = gg.multiChoice(labels, nil, "الديكورات — اختر الديكورات كما في التطبيق")
        if not selected then return end
        local values = {}
        local selectAll = selected[1] == true
        if selectAll then
            for _, id in ipairs(APP_DECOR_IDS) do table.insert(values, id) end
        else
            for i, checked in pairs(selected) do
                if checked and i > 1 then table.insert(values, APP_DECOR_IDS[i - 1]) end
            end
        end
        if #values == 0 then gg.alert("اختر ديكورًا واحدًا على الأقل."); return end
        local countInput = gg.prompt({"عدد كل ديكور (كما في التطبيق)"}, {"1"}, {"number"})
        local count = countInput and tonumber(countInput[1])
        if not count or count <= 0 then return end
        table.insert(edits, {type = "allDecor", value = {count = math.floor(count), all = selectAll, items = selectAll and nil or values}})
    end

    if #selectedResources > 0 then
        local resourceInput = gg.prompt(
        {"🌺اكتب العدد المطلوب🌺"}, 
            {"0"},
            {"number"}
        )
        if not resourceInput or resourceInput[1] == nil or tostring(resourceInput[1]) == "" then
            return
        end
        local resourceBatch = {}
        for _, item in ipairs(selectedResources) do
            table.insert(resourceBatch, {
                name = item.name,
                label = item.label,
                value = tonumber(resourceInput[1])
            })
        end
        table.insert(edits, {type = "resourceBatch", value = resourceBatch})
    end

    if #selectedCoupons > 0 then
        local couponInput = gg.prompt(
            {"🌺اكتب عدد كل قسيمة🌺"},
            {"0"},
            {"number"}
        )
        if not couponInput or couponInput[1] == nil or tostring(couponInput[1]) == "" then
            return
        end
        local couponValue = tonumber(couponInput[1])
        if not couponValue or couponValue <= 0 then
            gg.alert("❌ عدد القسائم غير صحيح")
            return
        end
        for _, item in ipairs(selectedCoupons) do
            table.insert(edits, {
                type = "coupon",
                value = {name = item.name, value = math.floor(couponValue), label = item.label}
            })
        end
    end

    if #edits == 0 then

        gg.alert(
            "❌ لم يتم إدخال أي تعديل"
        )

        return

    end


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


    if decoded == nil then
        return edits
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
    local applied_edits = {}
    local skipped_edits = {}
    local pending_edits = {}

    -- تبقى واجهة المستخدم دفعة واحدة، لكن التنفيذ يكون عنصرًا عنصرًا.
    -- إذا فشل عنصر، لا يمنع بقية العناصر من التنفيذ.
    for _, edit in ipairs(edits) do
        if edit.type == "resourceBatch" or edit.type == "barnBatch" then
            local singleType = edit.type == "resourceBatch" and "resource" or "barnItem"
            for _, item in ipairs(edit.value or {}) do
                table.insert(pending_edits, {type = singleType, value = item})
            end
        else
            table.insert(pending_edits, edit)
        end
    end

    for _, edit in ipairs(pending_edits) do
        -- التطبيق الأصلي يضيف LR2_Currency قبل أول Var إذا لم تكن موجودة،
        -- ثم يمرر الملف للمحرر. نطبق نفس الخطوة في Lua حتى يعمل مع السيرفر القديم.
        if edit.type == "frameCoins" then
            local frameValue = tonumber(edit.value)
            if not frameValue or frameValue < 0 then
                table.insert(skipped_edits, {
                    type = edit.type,
                    name = "LR2_Currency",
                    reason = "قيمة عملات الإطار غير صالحة"
                })
                goto continue_edit
            end
            if not current_data:match("<Var%s+[^>]-name=[\"']LR2_Currency[\"']") then
                local inserted
                current_data, inserted = current_data:gsub(
                    "(<Var%s)",
                    '<Var name="LR2_Currency" v="' .. tostring(math.floor(frameValue)) .. '" t="i"/>\n%1',
                    1
                )
                if inserted == 0 then
                    table.insert(skipped_edits, {
                        type = edit.type,
                        name = "LR2_Currency",
                        reason = "لم يجد التطبيق عقدة Var لإضافة عملات الإطار"
                    })
                    goto continue_edit
                end
            end
        end
        local batch_json = build_edits_json({edit})
        local url = EDIT_URL .. "?edits=" .. url_encode(batch_json)
        local ok, result = pcall(function()
            return post_file(url, current_data)
        end)
        if ok then
            current_data = result
            table.insert(applied_edits, edit)
        else
            table.insert(skipped_edits, {
                type = edit.type,
                name = type(edit.value) == "table" and edit.value.name or tostring(edit.type),
                reason = tostring(result)
            })
        end
        ::continue_edit::
    end

    if #applied_edits == 0 then
        local details = "لم ينجح أي تعديل."
        if #skipped_edits > 0 then
            details = details .. "\nالعناصر الفاشلة:"
            for _, failed in ipairs(skipped_edits) do
                details = details .. "\n- " .. tostring(failed.name) .. ": " .. tostring(failed.reason)
            end
        end
        raiseError(details)
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

        if edit.type == "goldenTicket" then
            message = message .. "✔ تم فتح التذكرة الذهبية وجميع الجوائز\n"
        elseif edit.type == "goldenTicket2" then
            message = message .. "✔ تم فتح التذكرة الذهبية 2 والمسارين\n"
        elseif edit.type == "trainPresetWheat" then
            message = message .. "✔ تم تطبيق القمح: العدد 1 \n"
        elseif edit.type == "trainPresetDiadem" then
            message = message .. "✔ تم تطبيق التاج: العدد 500 \n"
        elseif edit.type == "trainPresetCarrot" then
            message = message .. "✔ تم تطبيق الجزر: العدد9999\n"
        elseif edit.type == "money" then
            message = message .. "✔ تم تعديل رصيد النقود إلى: " .. tostring(edit.value) .. "\n"
        elseif edit.type == "moneyCash" then
            message = message .. "✔ تم تعديل T-Cash إلى: " .. tostring(edit.value) .. "\n"
        elseif edit.type == "gameStartDate" then
            message = message .. "✔ تم تعديل تاريخ البداية إلى: " .. tostring(edit.value) .. "\n"
        elseif edit.type == "barnCapacity" then
            message = message .. "✔ تم تعديل سعة الحظيرة إلى: " .. tostring(edit.value) .. "\n"
        elseif edit.type == "frameCoins" then
            message = message .. "✔ تم تعديل عملات الإطار إلى: " .. tostring(edit.value) .. "\n"
        elseif edit.type == "showAllEvents" then
            message = message .. "✔ تم إظهار وتفعيل جميع الأحداث الموجودة في ملف الحفظ\n"
        elseif edit.type == "resource" then
            message = message .. "✔ تم تعديل المورد المختار: " .. tostring(edit.value.name) .. "\n"
        elseif edit.type == "coupon" then
            message = message .. "✔ تم إضافة القسيمة: " .. tostring(edit.value.name) .. " بالعدد " .. tostring(edit.value.value) .. "\n"
        elseif edit.type == "barnItem" then
            message = message .. "✔ تم تعديل صنف الشونة المختار: " .. tostring(edit.value.name) .. "\n"
        elseif edit.type == "level" then

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

        elseif edit.type == "skins" then
            message = message .. "✔ تم تفعيل المظاهر المحددة كما في التطبيق\n"

        elseif edit.type == "allDecor" then
            message = message .. "✔ تم تفعيل الديكورات المحددة وإضافتها للمخزون بالعدد المحدد\n"

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
    


    message = message .. "\n✅ نجح: " .. tostring(#applied_edits) .. " عنصر"
    if #skipped_edits > 0 then
        message = message .. "\n\n❌ فشل " .. tostring(#skipped_edits) .. " عنصر:"
        for _, failed in ipairs(skipped_edits) do
            message = message .. "\n• " .. tostring(failed.name) .. " — " .. tostring(failed.reason)
        end
        message = message .. "\n\nتم حفظ العناصر الناجحة فقط."
    end

    gg.alert(
        message
    )

end


-- Standalone runner removed; launcher calls this function.
return function()
    -- المرحلة الأولى: عرض الخيارات فقط، بدون فك الملف.
    if rawget(_G, "BS_COLLECT_ONLY") then
        return edit_stage(nil)
    end

    local ok, result = pcall(function()
        -- لا يبدأ فك الملف إلا بعد اكتمال الاختيار.
        local decoded = decode_stage()
        edit_stage(decoded)
    end)
    if not ok then
        gg.alert("❌ حدث خطأ أثناء تنفيذ العملية، حاول مرة أخرى.")
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

    local requestOk, r = pcall(function()
        return gg.makeRequest(
            url,
            {
                ["Content-Type"] = contentType or "application/json; charset=utf-8",
                ["Accept"] = "*/*",
                ["User-Agent"] = "Mozilla/5.0",
                ["Cache-Control"] = "no-cache"
            },
            body
        )
    end)
    if not requestOk then return nil, "تعذر إرسال الطلب: " .. tostring(r) end
    if not r then return nil, "لم تصل استجابة من السيرفر (لا يوجد رد HTTP)." end

    local code =
        tonumber(r.code or 0) or 0

    local content =
        tostring(r.content or "")

    if code < 200 or code >= 300 then
        local detail = content ~= "" and content or "(رد الخادم فارغ)"
        if #detail > 3000 then detail = detail:sub(1, 3000) .. "\n[تم اختصار الرد]" end
        return nil, "استجابة الخادم HTTP " .. tostring(code) .. ":\n" .. detail
    end

    return content
end


-- ============================================================
-- ERROR
-- ============================================================

local function show_error(title, message)
    gg.alert("❌ حدث خطأ أثناء تنفيذ العملية، حاول مرة أخرى.")
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

        local detail = tostring(response or "")
        if #detail > 3000 then detail = detail:sub(1, 3000) .. "\n[تم اختصار الرد]" end
        return nil,
            "رفض الخادم الطلب (HTTP 2xx):\n" .. detail
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
local function card_failure_reason(item)
    local reason = item.error or item.decryptError or item.reason or item.message or item.detail
    if reason and tostring(reason) ~= "" then
        return tostring(reason)
    end
    local status = item.httpStatus and ("HTTP " .. tostring(item.httpStatus)) or nil
    local responseText = item.responseText
    if responseText and tostring(responseText) ~= "" then
        local text = tostring(responseText)
        if #text > 900 then text = text:sub(1, 900) .. "…" end
        return (status and status .. " — " or "") .. text
    end
    if type(item.response) == "table" then
        local encoded = json_encode(item.response)
        if encoded and encoded ~= "{}" then
            if #encoded > 900 then encoded = encoded:sub(1, 900) .. "…" end
            return (status and status .. " — " or "") .. encoded
        end
    end
    if status then return status .. " — لم يقبل SendBox البطاقة" end
    return "لم يرسل السيرفر تفاصيل إضافية"
end

local function card_failure_details(result)
    local lines = {}
    local list = result.failures or result.failedCards or result.errors or result.details
    if type(list) == "table" then
        for _, item in ipairs(list) do
            if type(item) == "table" then
                local id = item.cardId or item.id or item.card or item.name or "بطاقة غير معروفة"
                lines[#lines + 1] = "• " .. tostring(id) .. " — " .. card_failure_reason(item)
            else
                lines[#lines + 1] = "• " .. tostring(item)
            end
        end
    elseif type(list) == "string" and list ~= "" then
        lines[#lines + 1] = list
    end
    local failedIds = result.failedCardIds or result.failedIds
    if type(failedIds) == "table" then
        for _, id in ipairs(failedIds) do
            lines[#lines + 1] = "• " .. tostring(id) .. " — لم يرسل السيرفر سببًا تفصيليًا"
        end
    end
    if #lines == 0 and (tonumber(result.failed or 0) or 0) > 0 then
        lines[#lines + 1] = "• السيرفر أعاد عدد الفشل فقط ولم يرسل أسباب البطاقات."
        lines[#lines + 1] = "• رد السيرفر: " .. tostring(json_encode(result))
    end
    return table.concat(lines, "\n")
end

local function show_result(
    result,
    selected
)
    local sent = tonumber(result.sentCards or 0) or 0
    local failed = tonumber(result.failed or 0) or 0
    local total = tonumber(result.totalCards or #selected.cardIds) or #selected.cardIds
    gg.alert(
        "📊 النتيجة\n\n" ..
        "📤 نجح: " .. tostring(sent) ..
        "\n❌ فشل: " .. tostring(failed) ..
        "\n📦 الإجمالي: " .. tostring(total)
    )
end
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
    gg.alert("❌ حدث خطأ أثناء تنفيذ العملية، حاول مرة أخرى.")
end

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
            "❌ تعذر فك ملف المدن، حاول مرة أخرى"
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
            "❌ تعذر فك الملف، تأكد من البيانات وحاول مرة أخرى"
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
            "❌ تعذر جلب المدينة، حاول مرة أخرى"

    end

    if not response.content then

        return nil,
            "❌ لم تصل بيانات المدينة، حاول مرة أخرى"

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
            "❌ تعذر قراءة بيانات المدينة، حاول مرة أخرى"
        )

        return false

    end

    if not xml:match(
        "</root>%s*$"
    ) then

        copyError(
            "⚠️ بيانات المدينة غير مكتملة، حاول مرة أخرى"
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

local function report_tool_error(title, err)
    local message = tostring(err or "خطأ غير معروف")
    if #message > 2500 then
        message = message:sub(1, 2500) .. "\n..."
    end
    local fullMessage = "❌ " .. tostring(title or "حدث خطأ") .. "\n\nالتفاصيل:\n" .. message
    -- بعض إصدارات GG تقص النص الطويل في alert؛ الحافظة والسجل يضمنان عدم ضياع التفاصيل.
    if gg.copyText then pcall(gg.copyText, fullMessage) end
    local log = io.open("/sdcard/BS64_error.log", "w")
    if log then
        log:write(fullMessage)
        log:close()
    end
    gg.alert(fullMessage .. "\n\nتم نسخ التفاصيل إلى الحافظة وحفظها في:\n/sdcard/BS64_error.log")
end

local function run_source(src, label, section)
    _G.BS_TOOL_SECTION = section or "race"
    local chunk, err = load(src, label)

    if not chunk then
        _G.BS_TOOL_SECTION = nil
        report_tool_error("تعذر تحميل الأداة: " .. tostring(label), err)
        return
    end

    local ok, result = pcall(chunk)

    if not ok then
        report_tool_error("خطأ أثناء تشغيل الأداة: " .. tostring(label), result)
        _G.BS_TOOL_SECTION = nil
        return
    end

    if type(result) == "function" then
        local ok2, err2 = pcall(function()
            -- المرحلة الأولى: عرض الخيارات وتحديدها فقط، قبل فك ملف الحفظ.
            _G.BS_PRESELECTED_EDITS = nil
            _G.BS_COLLECT_ONLY = true
            local selectedEdits = result()
            _G.BS_COLLECT_ONLY = nil
            if type(selectedEdits) ~= "table" then
                return
            end

            -- بعد موافقة المستخدم فقط يشغل المصدر مرحلة فك الملف والتطبيق.
            _G.BS_PRESELECTED_EDITS = selectedEdits
            local applied = result()
            _G.BS_PRESELECTED_EDITS = nil
            return applied
        end)
        _G.BS_PRESELECTED_EDITS = nil
        if not ok2 then
            report_tool_error("خطأ أثناء تنفيذ الأداة: " .. tostring(label), err2)
        end
    end
    _G.BS_TOOL_SECTION = nil
end

while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        local choice=gg.choice({
'【✦】 النسخ 【✦】',
'【✦】 ملف خاص بالتعديل والسباق 【✦】',
'【✦】 القسائم 【✦】',
'【✦】 القطارات 【✦】',
'【✦】 المختبر 【✦】',
'【✦】 زينة وايموجي 【✦】',
'【✦】 زيادة منتجات الشونة 【✦】',
'【✦】 اختيارات اضافية【✦】',
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
                    local selectOk, selectedFarm = pcall(copierApp.select)
                    if not selectOk then
                        report_tool_error("خطأ أثناء الاتصال/اختيار المزرعة", selectedFarm)
                    elseif selectedFarm then
                        local runOk, runErr = pcall(copierApp.run, selectedFarm)
                        if not runOk then report_tool_error("خطأ أثناء تنفيذ النسخ", runErr) end
                    end
                end
            end
        elseif choice==2 then run_source(SRC_TOOL,'ملف خاص بالتعديل والسباق ','race')
        elseif choice==3 then run_source(SRC_TOOL,'القسائم','coupons')
        elseif choice==4 then run_source(SRC_TOOL,'القطارات','trains')
        elseif choice==5 then run_source(SRC_TOOL,'المختبر','lab')
        elseif choice==6 then run_source(SRC_TOOL,'زينة وايموجي','decoration')
        elseif choice==7 then run_source(SRC_TOOL,'زيادة منتجات الشونة','barn')
        elseif choice==8 then run_source(SRC_TOOL,'باقي الخيارات','other')
        elseif choice==9 then run_source(SRC_CARDS,'إرسال الكروت')
        elseif choice==10 then run_source(SRC_LEVEL,'تفعيل مستوى 1')
        elseif choice==11 then
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
else
	gg.alert('⚡☁قم بتحميل الجاردن الخاص بجروب سنة اولى تطوير ☁⚡')
end
