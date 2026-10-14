# SB6SB License Server

سيرفر مستقل لتفعيل التطبيق عبر Render + Supabase. لا يحتوي مفاتيح حقيقية.

## تشغيل محلي

```bash
cd server
npm install
cp .env.example .env
npm start
```

## إعداد Supabase

1. افتح SQL Editor في مشروع Supabase.
2. نفذ محتوى `schema.sql`.
3. أنشئ قيمة `SUPABASE_SERVICE_ROLE_KEY` من إعدادات المشروع. لا تضعها داخل التطبيق أو GitHub.

## إعداد Render

أنشئ Web Service من مستودع GitHub، ثم اجعل:

- Root Directory: `server`
- Runtime: `Node`
- Build Command: `npm install`
- Start Command: `npm start`

أضف Environment Variables:

```text
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
ADMIN_API_KEY=...
CORS_ORIGIN=*
```

بعد النشر اختبر:

```text
GET https://YOUR-SERVICE.onrender.com/health
```

## API التطبيق

```text
GET /api/check?key=BS-XXXX&deviceid=DEVICE_ID
```

النتائج:

```text
active
expired
banned
another_device
invalid
```

## API طلب التفعيل

```http
POST /api/request
Content-Type: application/json

{"deviceid":"DEVICE_ID","fingerprint":"optional"}
```

## API الإدارة

أرسل الرأس التالي لكل مسار إدارة:

```text
x-api-key: قيمة ADMIN_API_KEY
```

إنشاء مفتاح:

```http
POST /api/admin/create-key
{"name":"User 1","deviceid":"optional","days":30}
```

تمديد مفتاح:

```http
POST /api/admin/extend
{"key":"BS-XXXXXXXXXX","days":30}
```

تغيير الحالة:

```http
POST /api/admin/status
{"key":"BS-XXXXXXXXXX","status":"banned"}
```

## ملاحظات

- التخزين الدائم موجود في Supabase، وليس على قرص Render.
- لا ترفع `.env` أو مفاتيح Supabase إلى GitHub.
- حماية الإدارة الحالية بمفتاح API؛ يمكن إضافة لوحة ويب لاحقًا دون تغيير API التطبيق.
