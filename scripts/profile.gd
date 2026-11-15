extends Node
## โปรไฟล์ผู้เล่น (autoload "Prof"): เหรียญ · ตู้เสื้อผ้า · ชุดที่สวม · Achievement · สถิติสะสม
## เก็บแยกตามบัญชีใน user://prof_<hash>.json
##
## ▸ อยากเพิ่ม/แก้ของในร้าน → แก้ SHOP
## ▸ อยากเพิ่ม/แก้ Achievement → แก้ ACH (รูปวาดเอง: วางไฟล์ PNG ไว้ที่ res://assets/achievements/<id>.png)
## ▸ อยากเปลี่ยนวิธีได้เหรียญ → แก้ COIN_RULES / coins_for_run()

signal changed
signal unlocked(ach: Dictionary)

const ACH_IMG_DIR := "res://assets/achievements/"

# ------------------------------------------------------------
# ร้านเสื้อผ้า — slot: suit (ชุด) · hat (หมวก) · shoes (รองเท้า) · acc (เครื่องประดับ)
#   price 0 = ได้ฟรีตั้งแต่เริ่ม · reward_only = ซื้อไม่ได้ ได้จาก Achievement เท่านั้น
# ------------------------------------------------------------
const SHOP := [
	{"k": "suit_white", "slot": "suit", "t": "ชุดพยาบาลขาวขลิบน้ำเงิน", "price": 0, "desc": "ชุดนักศึกษาพยาบาล มข. (ผู้หญิง = กระโปรง · ผู้ชาย = กางเกง)"},
	{"k": "suit_sky", "slot": "suit", "t": "ชุดสครับสีฟ้า", "price": 60, "desc": "สครับคอวีสีฟ้าอ่อน"},
	{"k": "suit_mint", "slot": "suit", "t": "ชุดสครับสีเขียวมิ้นต์", "price": 60, "desc": "สครับคอวีสีเขียวมิ้นต์"},
	{"k": "suit_pink", "slot": "suit", "t": "ชุดสครับสีชมพู", "price": 60, "desc": "สครับคอวีสีชมพูพาสเทล"},
	{"k": "suit_lilac", "slot": "suit", "t": "ชุดสครับสีม่วงลาเวนเดอร์", "price": 80, "desc": "สครับคอวีสีม่วงอ่อน"},
	{"k": "suit_comm", "slot": "suit", "t": "เสื้อกั๊กเยี่ยมบ้าน", "price": 100, "desc": "เสื้อโปโลขาว + กั๊กสีเขียว สำหรับลงชุมชน"},
	{"k": "suit_gold", "slot": "suit", "t": "ชุดสครับสีทอง", "price": 0, "reward_only": true, "desc": "รางวัลจาก Achievement “ครบทุกระดับ”"},
	{"k": "hat_none", "slot": "hat", "t": "ไม่สวมหมวก", "price": 0, "desc": ""},
	{"k": "hat_cap", "slot": "hat", "t": "หมวกพยาบาลขาว", "price": 0, "desc": "หมวกพยาบาลปกติไม่มีขีด"},
	{"k": "hat_scrub", "slot": "hat", "t": "หมวกคลุมผมลายจุด", "price": 40, "desc": "หมวกผ้าคลุมผมสีฟ้า"},
	{"k": "hat_band", "slot": "hat", "t": "ที่คาดผมโบว์ชมพู", "price": 30, "desc": "ที่คาดผมผูกโบว์"},
	{"k": "hat_sun", "slot": "hat", "t": "หมวกปีกกว้าง", "price": 0, "reward_only": true, "desc": "รางวัลจาก Achievement “ลงชุมชนครั้งแรก” กันแดดตอนเยี่ยมบ้าน"},
	{"k": "hat_helmet", "slot": "hat", "t": "หมวกกันน็อกกันอาจารย์", "price": 0, "reward_only": true, "desc": "รางวัลจาก Achievement “อาจารย์จะเขกหัวแล้วนะ!”"},
	{"k": "shoes_white", "slot": "shoes", "t": "รองเท้าพยาบาลขาว", "price": 0, "desc": "รองเท้าพยาบาลสีขาว ถุงเท้าขาว"},
	{"k": "shoes_black", "slot": "shoes", "t": "รองเท้าหนังดำ", "price": 30, "desc": "รองเท้าหุ้มส้นสีดำ"},
	{"k": "shoes_sneaker", "slot": "shoes", "t": "รองเท้าผ้าใบสีฟ้า", "price": 40, "desc": "ใส่สบาย เดินเยี่ยมบ้านได้ทั้งวัน"},
	{"k": "shoes_pink", "slot": "shoes", "t": "รองเท้าหัวโตสีชมพู", "price": 50, "desc": "รองเท้ายางหัวโต"},
	{"k": "acc_none", "slot": "acc", "t": "ไม่มีเครื่องประดับ", "price": 0, "desc": ""},
	{"k": "acc_stetho", "slot": "acc", "t": "หูฟังแพทย์ (Stethoscope)", "price": 60, "desc": "คล้องคอ"},
	{"k": "acc_glasses", "slot": "acc", "t": "แว่นตากรอบดำ", "price": 40, "desc": "ดูเป็นผู้เชี่ยวชาญขึ้นทันที"},
]
const SLOTS := [
	{"k": "suit", "t": "ชุด"}, {"k": "hat", "t": "หมวก"}, {"k": "shoes", "t": "รองเท้า"}, {"k": "acc", "t": "เครื่องประดับ"},
]
const DEFAULT_OUTFIT := {"sex": "f", "suit": "suit_white", "hat": "hat_cap", "shoes": "shoes_white", "acc": "acc_none"}

# ------------------------------------------------------------
# Achievement — reward: {"coins": n} และ/หรือ {"item": "<k ใน SHOP>"}
#   รูป: res://assets/achievements/<id>.png (ถ้ายังไม่มีไฟล์ เกมจะวาดเหรียญตราชั่วคราวให้)
# ------------------------------------------------------------
const ACH := [
	{"id": "first_run", "icon": "🎓", "t": "ก้าวแรกของนักประเมิน", "desc": "ประเมิน MMSE จบครบทั้งชุดเป็นครั้งแรก", "reward": {"coins": 20}},
	{"id": "miss3", "icon": "😵", "t": "อาจารย์จะเขกหัวแล้วนะ!", "desc": "ให้คะแนนพลาดสะสมครบ 3 ครั้ง", "reward": {"coins": 10, "item": "hat_helmet"}},
	{"id": "perfect", "icon": "🦅", "t": "ตาเหยี่ยว", "desc": "ประเมินเต็มชุดได้ 3 ดาว (บันทึกคะแนนตรงทุกจุด)", "reward": {"coins": 50}},
	{"id": "open_only", "icon": "🤐", "t": "ไม่ชี้นำสักคำ", "desc": "ข้อ 1 และข้อ 2 ใช้คำถามปลายเปิดครบทุกข้อย่อยในรอบเดียว", "reward": {"coins": 30}},
	{"id": "interp", "icon": "📊", "t": "แปลผลเป๊ะ", "desc": "แปลผลคะแนนถูกทั้งเกณฑ์และข้อสรุป", "reward": {"coins": 20}},
	{"id": "community", "icon": "🏡", "t": "ลงชุมชนครั้งแรก", "desc": "ประเมินเต็มชุดในชุมชน (เยี่ยมบ้าน) จบ 1 ครั้ง", "reward": {"item": "hat_sun"}},
	{"id": "hard_clear", "icon": "🔥", "t": "มือโปรเคสยาก", "desc": "ประเมินเต็มชุดระดับยากได้อย่างน้อย 2 ดาว", "reward": {"coins": 80}},
	{"id": "all_diff", "icon": "👑", "t": "ครบทุกระดับ", "desc": "ประเมินเต็มชุดจบครบทั้งระดับง่าย ปานกลาง และยาก", "reward": {"item": "suit_gold"}},
	{"id": "shopper", "icon": "🛍", "t": "สายแฟชั่นประจำวอร์ด", "desc": "ซื้อเสื้อผ้าชิ้นแรกจากร้าน", "reward": {"coins": 10}},
]

# ------------------------------------------------------------
# เหรียญที่ได้ต่อรอบ (ปรับได้ — ระบบเหรียญยังเป็นร่าง)
# ------------------------------------------------------------
const COIN_RULES := {
	"per_star": 10,        # ต่อดาว 1 ดวง
	"full_bonus": 30,      # โบนัสเมื่อประเมินครบทั้งชุด
	"community_bonus": 10, # โบนัสเมื่อประเมินในชุมชน (เต็มชุด)
	"start": 50,           # เหรียญเริ่มต้นของบัญชีใหม่
}

var data := {}
var _queue: Array = []


func _ready() -> void:
	reload()
	G.user_changed.connect(reload)


func _path() -> String:
	var u: String = G.current_user()
	if u == "":
		u = "guest"
	return "user://prof_" + u.sha256_text().substr(0, 16) + ".json"


func reload() -> void:
	var d = G._read_json(_path(), {})
	data = d if d is Dictionary else {}
	if not data.has("coins"):
		data.coins = COIN_RULES.start
	for k in ["owned", "ach", "stats", "outfit"]:
		if not data.has(k) or not (data[k] is Dictionary):
			data[k] = {}
	for it in SHOP:
		if it.price == 0 and not it.get("reward_only", false):
			data.owned[it.k] = true
	for k in DEFAULT_OUTFIT:
		if not data.outfit.has(k):
			data.outfit[k] = DEFAULT_OUTFIT[k]
	Px.outfit_changed()
	changed.emit()


func save() -> void:
	G._write_json(_path(), data)
	changed.emit()


# ---------- เหรียญ ----------
func coins() -> int:
	return int(data.get("coins", 0))

func add_coins(n: int) -> void:
	data.coins = coins() + n
	save()


# ---------- ตู้เสื้อผ้า ----------
func item(k: String) -> Dictionary:
	for it in SHOP:
		if it.k == k:
			return it
	return {}

func items_of(slot: String) -> Array:
	return SHOP.filter(func(it): return it.slot == slot)

func owns(k: String) -> bool:
	return data.owned.get(k, false)

func outfit() -> Dictionary:
	return data.get("outfit", DEFAULT_OUTFIT)

## คืนข้อความผิดพลาด หรือ "" ถ้าซื้อสำเร็จ
func buy(k: String) -> String:
	var it := item(k)
	if it.is_empty():
		return "ไม่พบสินค้านี้"
	if owns(k):
		return "มีชิ้นนี้อยู่แล้ว"
	if it.get("reward_only", false):
		return "ชิ้นนี้ได้จาก Achievement เท่านั้น"
	if coins() < int(it.price):
		return "เหรียญไม่พอ — ขาดอีก %d เหรียญ" % (int(it.price) - coins())
	data.coins = coins() - int(it.price)
	data.owned[k] = true
	stat_add("bought", 1)
	save()
	if stat("bought") >= 1:
		unlock("shopper")
	return ""

func equip(slot: String, k: String) -> void:
	if slot != "sex" and not owns(k):
		return
	data.outfit[slot] = k
	Px.outfit_changed()
	save()


# ---------- สถิติ ----------
func stat(k: String) -> int:
	return int(data.stats.get(k, 0))

func stat_add(k: String, n: int) -> void:
	data.stats[k] = stat(k) + n


# ---------- Achievement ----------
func ach(id: String) -> Dictionary:
	for a in ACH:
		if a.id == id:
			return a
	return {}

func has_ach(id: String) -> bool:
	return data.ach.has(id)

func ach_image(id: String) -> Texture2D:
	var p := ACH_IMG_DIR + id + ".png"
	if ResourceLoader.exists(p):
		return load(p)
	return Px.ach_badge(id, ach(id).get("icon", ""))

func reward_text(a: Dictionary) -> String:
	var r: Dictionary = a.get("reward", {})
	var out := []
	if r.has("coins"):
		out.append("🪙 %d เหรียญ" % r.coins)
	if r.has("item"):
		out.append("👕 " + item(r.item).get("t", r.item))
	return " + ".join(out)

func unlock(id: String) -> bool:
	if has_ach(id):
		return false
	var a := ach(id)
	if a.is_empty():
		return false
	data.ach[id] = Time.get_datetime_string_from_system(false, true).substr(0, 16)
	var r: Dictionary = a.get("reward", {})
	if r.has("coins"):
		data.coins = coins() + int(r.coins)
	if r.has("item"):
		data.owned[r.item] = true
	save()
	unlocked.emit(a)
	return true


## สรุปรอบเล่น → เหรียญที่ได้ + Achievement ที่ปลดล็อก
## info: {full, stars, miss, diff, setting, interp_ok, open_only}
func on_run_end(info: Dictionary) -> int:
	var earned := coins_for_run(info)
	data.coins = coins() + earned
	stat_add("miss_total", int(info.miss))
	stat_add("runs", 1)
	if info.full:
		stat_add("full_runs", 1)
		data.stats["clear_" + str(info.diff)] = 1
		if info.setting == "comm":
			stat_add("comm_runs", 1)
	save()
	if info.full:
		unlock("first_run")
		if info.stars >= 3:
			unlock("perfect")
		if info.get("open_only", false):
			unlock("open_only")
		if info.get("interp_ok", false):
			unlock("interp")
		if info.setting == "comm":
			unlock("community")
		if info.diff == "hard" and info.stars >= 2:
			unlock("hard_clear")
		if stat("clear_easy") and stat("clear_medium") and stat("clear_hard"):
			unlock("all_diff")
	if stat("miss_total") >= 3:
		unlock("miss3")
	return earned

func coins_for_run(info: Dictionary) -> int:
	var base := int(info.stars) * int(COIN_RULES.per_star)
	if info.full:
		base += int(COIN_RULES.full_bonus)
		if info.setting == "comm":
			base += int(COIN_RULES.community_bonus)
	return int(round(base * float(D.diff_of(info.diff).coin_x)))
