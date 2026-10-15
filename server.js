const express = require("express");
const cors = require("cors");
const crypto = require("crypto");
const { createClient } = require("@supabase/supabase-js");
const backupApi = require("./backup");

const app = express();
const PORT = Number(process.env.PORT || 3000);
const ADMIN_API_KEY = process.env.ADMIN_API_KEY || "";
const origin = process.env.CORS_ORIGIN || "*";

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
  console.warn("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required for database routes.");
}

const supabase = process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY
  ? createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false }
    })
  : null;

app.use(cors({ origin: origin === "*" ? true : origin }));
app.use(express.json({ limit: "256kb" }));
app.use(express.urlencoded({ extended: false, limit: "64kb" }));

// Safe request tracing: log method/path/status only; never log keys or request bodies.
app.use((req, res, next) => {
  const started = Date.now();
  res.on("finish", () => console.log(`[request] ${req.method} ${req.path} ${res.statusCode} ${Date.now() - started}ms`));
  next();
});

const requestLog = new Map();
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 30;

function clean(value, max = 160) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

function clientIp(req) {
  return clean((req.headers["x-forwarded-for"] || req.socket.remoteAddress || "").split(",")[0], 80);
}

function rateLimit(req, res, next) {
  const key = `${clientIp(req)}:${req.path}`;
  const now = Date.now();
  const old = requestLog.get(key);
  if (!old || now - old.started >= WINDOW_MS) {
    requestLog.set(key, { started: now, count: 1 });
    return next();
  }
  old.count += 1;
  if (old.count > MAX_PER_WINDOW) {
    return res.status(429).json({ status: "rate_limited", retry_after_seconds: 60 });
  }
  return next();
}

function requireAdmin(req, res, next) {
  if (!ADMIN_API_KEY || req.get("x-api-key") !== ADMIN_API_KEY) {
    return res.status(401).json({ status: "unauthorized" });
  }
  return next();
}

function requireDb(res) {
  if (!supabase) {
    res.status(503).json({ status: "database_unconfigured" });
    return false;
  }
  return true;
}

function makeKey() {
  return `BS-${crypto.randomBytes(5).toString("hex").toUpperCase()}`;
}

function addDays(days) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + Math.max(1, Math.min(Number(days) || 1, 3650)));
  return date.toISOString();
}

function remaining(expireAt) {
  const diff = new Date(expireAt).getTime() - Date.now();
  if (!Number.isFinite(diff) || diff <= 0) return { days: 0, hours: 0, minutes: 0 };
  return {
    days: Math.floor(diff / 86400000),
    hours: Math.floor((diff / 3600000) % 24),
    minutes: Math.floor((diff / 60000) % 60)
  };
}

app.get("/health", (req, res) => res.json({ status: "ok", service: "sb6sb-license-server" }));

app.use("/api", backupApi);

// Compatible with both the new Lua contract and the original Android contract.
// New:  GET  /api/check?key=...&deviceid=...
// Old:  POST /api/check_license.php with license_key=...&device_id=...
async function checkLicense(req, res) {
  if (!requireDb(res)) return;
  const legacy = req.path.endsWith("check_license.php");
  const reply = (status, extra = {}) => {
    if (legacy) {
      return res.json({
        status: status === "active",
        message: status,
        expired_at: extra.expire_at || "",
        ...extra
      });
    }
    return res.json({ status, ...extra });
  };
  const key = clean(req.query.key || req.body?.key || req.body?.license_key, 100);
  const deviceid = clean(req.query.deviceid || req.body?.deviceid || req.body?.device_id, 200);
  if (!key || !deviceid) return reply("invalid");

  try {
    const { data: item, error } = await supabase.from("license_keys").select("*").eq("key", key).maybeSingle();
    if (error || !item) return reply("invalid");
    if (item.status === "banned") return reply("banned");

    if (item.deviceid && item.deviceid !== deviceid) {
      return reply("another_device");
    }
    if (!item.deviceid) {
      const { error: bindError } = await supabase.from("license_keys").update({ deviceid }).eq("id", item.id).is("deviceid", null);
      if (bindError) return res.status(500).json({ status: legacy ? false : "error", message: "error" });
    }

    if (new Date(item.expireat).getTime() <= Date.now()) {
      await supabase.from("license_keys").update({ status: "expired" }).eq("id", item.id);
      return reply("expired");
    }
    return reply("active", { name: item.name || "", expire_at: item.expireat, ...remaining(item.expireat) });
  } catch (error) {
    console.error("check error", error.message);
    return res.status(500).json({ status: "error" });
  }
}

app.all("/api/check", rateLimit, checkLicense);
app.all("/api/check_license.php", rateLimit, checkLicense);

app.post("/api/request", rateLimit, async (req, res) => {
  if (!requireDb(res)) return;
  const deviceid = clean(req.body.deviceid, 200);
  const fingerprint = clean(req.body.fingerprint, 500);
  if (!deviceid) return res.status(400).json({ status: "error", message: "deviceid is required" });
  const { error } = await supabase.from("activation_requests").insert({ deviceid, fingerprint, ip: clientIp(req) });
  if (error) return res.status(500).json({ status: "error" });
  return res.json({ status: "received" });
});

app.post("/api/admin/create-key", requireAdmin, async (req, res) => {
  if (!requireDb(res)) return;
  const name = clean(req.body.name, 120);
  const deviceid = clean(req.body.deviceid, 200) || null;
  const days = Math.max(1, Math.min(Number(req.body.days) || 30, 3650));
  if (!name) return res.status(400).json({ status: "error", message: "name is required" });
  const key = makeKey();
  const { data, error } = await supabase.from("license_keys").insert({ key, name, deviceid, expireat: addDays(days), status: "active" }).select("key,name,deviceid,expireat,status").single();
  if (error) return res.status(500).json({ status: "error", message: error.message });
  return res.json({ status: "success", key: data.key, license: data });
});

app.post("/api/admin/extend", requireAdmin, async (req, res) => {
  if (!requireDb(res)) return;
  const key = clean(req.body.key, 100);
  const days = Math.max(1, Math.min(Number(req.body.days) || 30, 3650));
  if (!key) return res.status(400).json({ status: "error", message: "key is required" });
  const { data: item, error: findError } = await supabase.from("license_keys").select("id,expireat").eq("key", key).maybeSingle();
  if (findError || !item) return res.status(404).json({ status: "not_found" });
  const base = new Date(item.expireat).getTime() > Date.now() ? new Date(item.expireat) : new Date();
  base.setUTCDate(base.getUTCDate() + days);
  const { error } = await supabase.from("license_keys").update({ expireat: base.toISOString(), status: "active" }).eq("id", item.id);
  if (error) return res.status(500).json({ status: "error", message: error.message });
  return res.json({ status: "success", expire_at: base.toISOString() });
});

app.post("/api/admin/status", requireAdmin, async (req, res) => {
  if (!requireDb(res)) return;
  const key = clean(req.body.key, 100);
  const status = clean(req.body.status, 20);
  if (!key || !["active", "banned"].includes(status)) return res.status(400).json({ status: "error" });
  const { error } = await supabase.from("license_keys").update({ status }).eq("key", key);
  if (error) return res.status(500).json({ status: "error", message: error.message });
  return res.json({ status: "success" });
});

app.listen(PORT, "0.0.0.0", () => console.log(`SB6SB license server listening on ${PORT}`));
