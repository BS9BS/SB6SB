const express = require("express");
const multer = require("multer");
const crypto = require("crypto");
const { createClient } = require("@supabase/supabase-js");

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });
const BUCKET = process.env.SUPABASE_BACKUP_BUCKET || "backups";
const supabase = process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY
  ? createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth: { autoRefreshToken: false, persistSession: false } })
  : null;

// The APK writes one CRLF instead of the usual blank line between multipart
// headers and values. Parse both standard and legacy multipart bodies.
function parseMultipart(req, res, next) {
  const contentType = String(req.headers["content-type"] || "");
  const match = contentType.match(/boundary=(?:"([^"]+)"|([^;]+))/i);
  if (!match) return next();
  const boundary = match[1] || match[2];
  const chunks = [];
  let total = 0;
  req.on("data", (chunk) => {
    total += chunk.length;
    if (total <= 60 * 1024 * 1024) chunks.push(chunk);
  });
  req.on("end", () => {
    if (total > 60 * 1024 * 1024) return res.status(413).json({ status: false, message: "file too large" });
    const raw = Buffer.concat(chunks);
    const marker = Buffer.from(`--${boundary}`);
    const fields = {};
    const files = [];
    let cursor = 0;
    while (true) {
      const startMarker = raw.indexOf(marker, cursor);
      if (startMarker < 0) break;
      let start = startMarker + marker.length;
      if (raw[start] === 45 && raw[start + 1] === 45) break;
      if (raw[start] === 13 && raw[start + 1] === 10) start += 2;
      const nextMarker = raw.indexOf(marker, start);
      if (nextMarker < 0) break;
      let part = raw.subarray(start, nextMarker);
      if (part.length >= 2 && part[part.length - 2] === 13 && part[part.length - 1] === 10) part = part.subarray(0, -2);
      let headerEnd = part.indexOf(Buffer.from("\r\n\r\n"));
      let separatorLength = 4;
      if (headerEnd < 0) {
        headerEnd = part.indexOf(Buffer.from("\r\n"));
        separatorLength = 2;
      }
      if (headerEnd < 0) { cursor = nextMarker; continue; }
      const headers = part.subarray(0, headerEnd).toString("latin1");
      const body = part.subarray(headerEnd + separatorLength);
      const disposition = headers.match(/Content-Disposition:\s*form-data;\s*name="([^"]+)"(?:;\s*filename="([^"]*)")?/i);
      if (!disposition) { cursor = nextMarker; continue; }
      const fieldname = disposition[1];
      const filename = disposition[2];
      if (filename !== undefined) {
        const type = (headers.match(/Content-Type:\s*([^\r\n]+)/i) || [])[1] || "application/octet-stream";
        files.push({ fieldname, originalname: filename, mimetype: type.trim(), buffer: body, size: body.length });
      } else {
        fields[fieldname] = body.toString("utf8");
      }
      cursor = nextMarker;
    }
    req.body = { ...(req.body || {}), ...fields };
    req.files = files;
    next();
  });
  req.on("error", next);
}

function value(req, ...names) {
  for (const name of names) {
    const v = req.query?.[name] ?? req.body?.[name];
    if (typeof v === "string" && v.trim()) return v.trim().slice(0, 240);
  }
  return "";
}

function db(res) {
  if (!supabase) {
    res.status(503).json({ status: "database_unconfigured" });
    return false;
  }
  return true;
}

function publicItem(row) {
  return {
    id: row.id,
    name: row.file_name,
    file_name: row.file_name,
    filename: row.file_name,
    license_key: row.license_key,
    deviceid: row.deviceid,
    device_id: row.deviceid,
    size: row.size_bytes,
    created_at: row.created_at,
    claimed_at: row.claimed_at
  };
}

async function listBackups(req, res) {
  if (!db(res)) return;
  const licenseKey = value(req, "license_key", "key");
  const deviceid = value(req, "deviceid", "device_id");
  let query = supabase.from("backups").select("*").order("created_at", { ascending: false }).limit(100);
  if (licenseKey) query = query.eq("license_key", licenseKey);
  if (deviceid) query = query.eq("deviceid", deviceid);
  const { data, error } = await query;
  if (error) return res.status(500).json({ status: "error", message: error.message });
  const items = (data || []).map(publicItem);
  return res.json({ status: true, ok: true, items, backups: items, data: items });
}

router.get("/list_backup_global.php", listBackups);
router.post("/list_backup_global.php", listBackups);
router.get("/list_backup.php", listBackups);
router.post("/list_backup.php", listBackups);

router.post("/upload_backup.php", parseMultipart, async (req, res) => {
  if (!db(res)) return;
  const file = (req.files || [])[0];
  console.log(`[upload] files=${(req.files || []).map((item) => item.fieldname).join(",") || "none"} token=${Boolean(req.body?.token)} license_key=${Boolean(req.body?.license_key)}`);
  if (!file) return res.status(400).json({ status: false, message: "file is required" });
  const licenseKey = value(req, "license_key", "key");
  const deviceid = value(req, "deviceid", "device_id") || `legacy:${value(req, "token") || licenseKey}`;
  if (!licenseKey) return res.status(400).json({ status: false, message: "license_key is required" });
  const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, "_").slice(-120) || "backup.bin";
  const path = `${licenseKey}/${Date.now()}-${crypto.randomBytes(4).toString("hex")}-${safeName}`;
  const { error: storageError } = await supabase.storage.from(BUCKET).upload(path, file.buffer, { contentType: file.mimetype || "application/octet-stream", upsert: false });
  if (storageError) return res.status(500).json({ status: false, message: storageError.message });
  const { data, error } = await supabase.from("backups").insert({ license_key: licenseKey, deviceid, file_name: safeName, storage_path: path, size_bytes: file.size, metadata: { mimetype: file.mimetype || "application/octet-stream" } }).select("*").single();
  if (error) {
    await supabase.storage.from(BUCKET).remove([path]);
    return res.status(500).json({ status: false, message: error.message });
  }
  return res.json({ status: true, ok: true, backup: publicItem(data), ...publicItem(data) });
});

async function findBackup(req, res) {
  const id = value(req, "id", "backup_id", "backupid");
  const fileName = value(req, "file", "file_name", "filename");
  const licenseKey = value(req, "license_key", "key");
  let query = supabase.from("backups").select("*").limit(1);
  if (id) query = query.eq("id", id);
  else if (fileName && licenseKey) query = query.eq("file_name", fileName).eq("license_key", licenseKey);
  else if (licenseKey) query = query.eq("license_key", licenseKey).order("created_at", { ascending: true });
  else return null;
  const { data, error } = await query.maybeSingle();
  if (error || !data) return null;
  return data;
}

async function downloadBackup(req, res) {
  if (!db(res)) return;
  const row = await findBackup(req, res);
  if (!row) return res.status(404).json({ status: false, message: "backup not found" });
  const { data, error } = await supabase.storage.from(BUCKET).download(row.storage_path);
  if (error) return res.status(404).json({ status: false, message: error.message });
  res.set("Content-Type", row.metadata?.mimetype || "application/octet-stream");
  res.set("Content-Disposition", `attachment; filename="${row.file_name.replace(/[^a-zA-Z0-9._-]/g, "_")}"`);
  return res.send(Buffer.from(await data.arrayBuffer()));
}

router.get("/download_backup.php", downloadBackup);
router.post("/download_backup.php", downloadBackup);

async function deleteBackup(req, res) {
  if (!db(res)) return;
  const row = await findBackup(req, res);
  if (!row) return res.status(404).json({ status: false, message: "backup not found" });
  const { error: storageError } = await supabase.storage.from(BUCKET).remove([row.storage_path]);
  if (storageError) return res.status(500).json({ status: false, message: storageError.message });
  const { error } = await supabase.from("backups").delete().eq("id", row.id);
  if (error) return res.status(500).json({ status: false, message: error.message });
  return res.json({ status: true, ok: true, deleted: row.id });
}

router.get("/delete_backup_license.php", deleteBackup);
router.post("/delete_backup_license.php", deleteBackup);

async function oldest(req, res, claim) {
  if (!db(res)) return;
  const licenseKey = value(req, "license_key", "key");
  let query = supabase.from("backups").select("*").order("created_at", { ascending: true }).limit(1);
  if (licenseKey) query = query.eq("license_key", licenseKey);
  const { data, error } = await query.maybeSingle();
  if (error || !data) return res.status(404).json({ status: false, message: "no backup found" });
  if (claim) await supabase.from("backups").update({ claimed_at: new Date().toISOString() }).eq("id", data.id);
  return res.json({ status: true, ok: true, backup: publicItem(data), ...publicItem(data) });
}

router.get("/get_oldest_backup.php", (req, res) => oldest(req, res, false));
router.post("/get_oldest_backup.php", (req, res) => oldest(req, res, false));
router.get("/claim_oldest_backup.php", (req, res) => oldest(req, res, true));
router.post("/claim_oldest_backup.php", (req, res) => oldest(req, res, true));

router.all("/license_features.php", (req, res) => res.json({ status: true, features: [] }));
router.all("/update_info.php", (req, res) => res.json({ status: true, ok: true }));

module.exports = router;
