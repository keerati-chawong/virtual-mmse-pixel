extends Node
## สถานะของเกม: ผู้ใช้ · สถานการณ์ · การคัดกรอง/อุปกรณ์ · รอบการเล่น · ประวัติคะแนน

signal navigate(screen: String, args: Dictionary)
signal toast(msg: String)
signal user_changed

const USERS_PATH := "user://users.json"
const SESSION_PATH := "user://session.json"

var scenario_key := "s1"
var setup := {"ans": {}, "kit": {}}
var run: Dictionary = {}
var after_login := "lobby"
var main: Node   # main.gd — ใช้เปิด popup


func pop(title: String, bb: String, extra: Control = null) -> void:
	if main:
		main.open_pop(title, bb, extra)


func _ready() -> void:
	randomize()


# ---------- routing ----------
func goto(screen: String, args: Dictionary = {}) -> void:
	navigate.emit(screen, args)

func say(msg: String) -> void:
	toast.emit(msg)


# ---------- scenario ----------
func scn() -> Dictionary:
	return D.scenario(scenario_key)

## โอกาสที่ผู้ป่วยทำ/ตอบได้ ปรับตามสถานการณ์ (s1 ร่วมมือดี · s2 สับสน)
func chance(p: float) -> bool:
	return randf() < clampf(p * float(scn().skill), 0.03, 0.97)

func confused_moment() -> bool:
	return randf() < float(scn().confuse)

func slow() -> float:
	return float(scn().slow)

func pick(a: Array):
	return a[randi() % a.size()]

func shuffled(a: Array) -> Array:
	var b := a.duplicate()
	b.shuffle()
	return b


# ---------- users (เดโม — เก็บในเครื่องนี้เท่านั้น) ----------
func _read_json(path: String, fallback):
	if not FileAccess.file_exists(path):
		return fallback
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return fallback
	var v = JSON.parse_string(f.get_as_text())
	return v if v != null else fallback

func _write_json(path: String, v) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(v))

func hash_pass(s: String) -> String:
	return "h" + s.sha256_text().substr(0, 24) + "-" + str(s.length())

func read_users() -> Dictionary:
	var u = _read_json(USERS_PATH, {})
	return u if u is Dictionary else {}

func current_user() -> String:
	var s = _read_json(SESSION_PATH, {})
	return s.get("user", "") if s is Dictionary else ""

func set_user(mail: String) -> void:
	_write_json(SESSION_PATH, {"user": mail})
	user_changed.emit()

## คืนค่าข้อความผิดพลาด หรือ "" ถ้าสำเร็จ
func register(mail: String, pass_: String, pass2: String) -> String:
	var e := _check_cred(mail, pass_)
	if e != "":
		return e
	if pass2 != pass_:
		return "รหัสผ่านทั้งสองช่องไม่ตรงกัน"
	var users := read_users()
	if users.has(mail):
		return "อีเมลนี้สมัครไว้แล้ว — กดแท็บเข้าสู่ระบบได้เลย"
	users[mail] = {"pass": hash_pass(pass_), "since": Time.get_datetime_string_from_system()}
	_write_json(USERS_PATH, users)
	set_user(mail)
	return ""

func login(mail: String, pass_: String) -> String:
	var e := _check_cred(mail, pass_)
	if e != "":
		return e
	var users := read_users()
	if not users.has(mail):
		return "ยังไม่มีบัญชีนี้ — กดแท็บสมัครสมาชิกก่อน"
	if users[mail].pass != hash_pass(pass_):
		return "รหัสผ่านไม่ถูกต้อง"
	set_user(mail)
	return ""

func _check_cred(mail: String, pass_: String) -> String:
	var re := RegEx.new()
	re.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")
	if re.search(mail) == null:
		return "รูปแบบอีเมลไม่ถูกต้อง"
	if pass_.length() < 6:
		return "รหัสผ่านต้องยาวอย่างน้อย 6 ตัวอักษร"
	return ""


# ---------- history ----------
func _hist_path() -> String:
	var u := current_user()
	if u == "":
		u = "guest"
	return "user://hist_" + u.sha256_text().substr(0, 16) + ".json"

func read_history() -> Array:
	var h = _read_json(_hist_path(), [])
	return h if h is Array else []

func push_history(rec: Dictionary) -> void:
	var h := read_history()
	h.push_front(rec)
	_write_json(_hist_path(), h.slice(0, 10))


# ---------- ดาวที่ดีที่สุด ----------
func _best_path() -> String:
	var u := current_user()
	if u == "":
		u = "guest"
	return "user://best_" + u.sha256_text().substr(0, 16) + ".json"

func read_best() -> Dictionary:
	var b = _read_json(_best_path(), {})
	return b if b is Dictionary else {}

func best_stars(key: String) -> int:
	return int(read_best().get(scenario_key + ":" + key, 0))

func save_stars(key: String, stars: int) -> bool:
	var b := read_best()
	var k := scenario_key + ":" + key
	var improved: bool = stars > int(b.get(k, 0))
	if improved:
		b[k] = stars
		_write_json(_best_path(), b)
	return improved

static func stars_for(miss: int, full: bool) -> int:
	if miss == 0:
		return 3
	if miss <= (3 if full else 1):
		return 2
	return 1


# ---------- screening + kit ----------
func is_illiterate() -> bool:
	return setup.ans.get("pedu", "") == "none"

func patient_edu() -> String:
	return setup.ans.get("pedu", "higher")

func blocked_reason() -> Dictionary:
	for q in D.SCREEN_QS:
		if q.has("block") and setup.ans.get(q.k, "") == q.block:
			return q
	return {}

func screen_complete() -> bool:
	for q in D.SCREEN_QS:
		if not setup.ans.has(q.k):
			return false
	return true

func plan_parts() -> Array:
	var skip := is_illiterate()
	var out := []
	for p in D.PARTS:
		if not (skip and p.get("skip_illiterate", false)):
			out.append(p)
	return out

func plan_max() -> int:
	var m := 0
	for p in plan_parts():
		m += p.max
	return m

func missing_kit() -> Array:
	var out := []
	for k in D.KIT_NEED:
		if not setup.kit.get(k, false):
			out.append(k)
	return out

func wrong_kit() -> Array:
	var out := []
	for it in D.KIT:
		if not it.ok and setup.kit.get(it.k, false):
			out.append(it)
	return out

func verdict_of(score: int, k: String) -> String:
	return "suspect" if score <= int(D.cut_of(k).cut) else "normal"


# ---------- run control ----------
func run_tag() -> String:
	if run.is_empty():
		return "เกมสถานการณ์จำลอง"
	var s := "Scenario %d · %s" % [scn().no, scn().name]
	if not run.full:
		return "ฝึกทีละข้อ · " + s
	return "ประเมินเต็มชุด · ข้อที่ %d จาก %d · %s" % [run.i + 1, run.queue.size(), s]

func start_full_run() -> void:
	var q := []
	for p in plan_parts():
		q.append(p.id)
	run = {"queue": q, "i": -1, "results": {}, "full": true, "use_kit": true,
		   "lit": not is_illiterate(), "reg_words": [], "interp": {}}
	next_run()

func start_single_run(id: String) -> void:
	run = {"queue": [id], "i": -1, "results": {}, "full": false, "use_kit": false,
		   "lit": true, "reg_words": [], "interp": {}}
	next_run()

func next_run() -> void:
	run.i += 1
	if run.i >= run.queue.size():
		goto("interpret" if run.full else "result")
		return
	route_part(run.queue[run.i])

func part_done(id: String, data: Dictionary) -> void:
	run.results[id] = data
	next_run()

func kit_problem(part: Dictionary) -> Dictionary:
	if run.is_empty() or not run.use_kit:
		return {}
	var miss := []
	for k in part.get("kit", []):
		if not setup.kit.get(k, false):
			miss.append(k)
	if miss.is_empty():
		return {}
	var wrong := []
	for k in miss:
		var d: String = D.DECOY_FOR.get(k, "")
		if d != "" and setup.kit.get(d, false):
			wrong.append({"need": k, "got": d})
	return {"missing": miss, "wrong": wrong}

func route_part(id: String) -> void:
	var part := D.part_of(id)
	var prob := kit_problem(part)
	if not prob.is_empty():
		goto("walk", {"mode": "out", "part": part, "prob": prob})
		return
	match part.scr:
		"time":
			goto("time")
		"cmd":
			var ids := [id]
			if id == "cmd8" and run.i + 1 < run.queue.size() and run.queue[run.i + 1] == "cmd9":
				ids.append("cmd9")
			goto("cmd", {"ids": ids})
		_:
			goto("part", {"id": id})

func totals() -> Dictionary:
	var t := {"given": 0, "truth": 0, "max": 0, "miss": 0, "rows": 0}
	for id in run.queue:
		if not run.results.has(id):
			continue
		var r: Dictionary = run.results[id]
		t.given += r.given
		t.truth += r.truth
		t.max += r.max
		for row in r.rows:
			t.rows += 1
			if not row.ok:
				t.miss += 1
	return t


func fb(kind: String, title: String, body: String, better: String = "") -> Dictionary:
	return {"kind": kind, "title": title, "body": body, "better": better}
