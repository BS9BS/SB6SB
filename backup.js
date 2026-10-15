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

router.post("/upload_backup.php", upload.any(), async (req, res) => {
  if (!db(res)) return;
  const file = (req.files || [])[0];
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
