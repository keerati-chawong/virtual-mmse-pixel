extends "res://scripts/screens/sim_base.gd"
## ข้อ 8 verbal command · ข้อ 9 written command

var ids: Array = []
var items: Array = []
var idx := 0
var phase := "pick"
var order := {}
var log_ := {}
var replays := 0
var max_ := 0
var anim: Tween

const NURSE_HOME := Stage.NURSE_HOME
const NURSE_NEAR := Stage.NURSE_NEAR


func setup(a: Dictionary) -> void:
	ids = a.get("ids", ["cmd8"])


func _ready() -> void:
	build_base("room")
	for it in D.CMD_ITEMS:
		if ids.has(it.id):
			items.append(it)
			max_ += it.subs.size()
	var t := "ข้อ 8–9 · ทำตามคำสั่ง" if items.size() > 1 else "ข้อ %d · %s" % [items[0].n, items[0].label]
	set_title(t, " · ".join(items.map(func(it): return it.cat)))
	pad_head.text = "ทำตามคำสั่ง — ติ๊กทีละขั้นที่ทำได้จริง"
	stage.props.table.visible = true
	var card_l := stage.add_label("card", Rect2(146, 50, 44, 11), "หลับตา", 16, Color("20364a"))
	card_l.add_theme_stylebox_override("normal", UI.box(Color("fdfcf8"), UI.INK, 2, 2))
	card_l.visible = false
	for it in items:
		order[it.id] = G.shuffled(it.options)
		for i in it.subs.size():
			var no := ("%d.%d" % [it.n, i + 1]) if it.subs.size() > 1 else "%d." % it.n
			pad_row(it.id + "." + it.subs[i].k, no + " " + it.subs[i].t)
	_set_item(0)


func _set_item(i: int) -> void:
	idx = i
	phase = "pick"
	var it: Dictionary = items[i]
	_reset_anim()
	_update()
	speak("narr", "ข้อ %d %s — %s" % [it.n, it.label, it.hint])
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func():
		choices("จะพูดกับผู้ป่วยว่าอย่างไร?", order[it.id].map(func(o): return D.t(o.text)), func(j): _pick(j, it.id)))


func _reset_anim() -> void:
	if anim:
		anim.kill()
	stage.reset_scene()
	stage.props.table.visible = true


func _pick(i: int, id: String) -> void:
	if phase != "pick" or log_.has(id):
		return
	var opt: Dictionary = order[id][i]
	log_[id] = {"text": D.t(opt.text), "type": opt.type,
		"sc": Parts.roll_cmd8(opt.type) if id == "cmd8" else Parts.roll_cmd9(opt.type), "given": {}}
	speak("nurse", D.t(opt.text))
	phase = "ready"
	action(items[idx].action, _play)


func _on_replay() -> void:
	if phase != "score":
		return
	replays += 1
	pad_open(false)
	_play()


func _on_rubric() -> void:
	G.pop("เกณฑ์ข้อนี้", D.t(items[idx].rubric))


func _play() -> void:
	var it: Dictionary = items[idx]
	var rec: Dictionary = log_[it.id]
	phase = "playing"
	action_hide()
	replay_btn.visible = false
	UI.clear(pad_actions)
	pad_ask.text = ""
	for s in it.subs:
		var key: String = it.id + "." + s.k
		rows_state[key].tickable = false
		rows_state[key].on = false
		pad_set(key, "scored", false)
	_reset_anim()
	speak("narr", "สังเกตให้ดีว่าผู้ป่วยทำอะไรบ้าง…")
	if it.id == "cmd8":
		_play8(rec.sc)
	else:
		_play9(rec.sc)


func _play8(sc: Dictionary) -> void:
	var paper: Sprite2D = stage.props.paper
	var n := stage.nurse
	var hand_pt := {"right": Vector2(185, 99), "left": Vector2(215, 99), "both": Vector2(200, 99)}
	var arms := {"right": "reach_r", "left": "reach_l", "both": "reach_both"}
	var s := G.slow()
	anim = create_tween()
	anim.tween_callback(func(): stage.show_flag("ยื่นกระดาษเปล่าให้ผู้ป่วย"))
	anim.tween_property(n, "position", NURSE_NEAR, 0.6)
	anim.tween_callback(func():
		stage.set_nurse("offer")
		paper.texture = Px.paper("flat")
		stage.show_prop("paper", NURSE_NEAR + Vector2(14, -4)))
	anim.tween_interval(0.7 * s)
	anim.tween_callback(func():
		stage.show_flag("ผู้ป่วยยื่นมือมารับ")
		stage.set_patient(arms[sc.hand]))
	anim.tween_property(paper, "position", hand_pt[sc.hand], 0.6)
	anim.tween_interval(0.4)
	anim.tween_callback(func():
		stage.set_nurse("clip")
		stage.set_patient("hold"))
	anim.parallel().tween_property(n, "position", NURSE_HOME, 0.5)
	anim.parallel().tween_property(paper, "position", Vector2(200, 104), 0.4)
	anim.tween_interval(0.5)
	anim.tween_callback(func(): stage.show_flag("ผู้ป่วยจัดการกับกระดาษ"))
	anim.tween_interval(0.6 * s)
	anim.tween_callback(func():
		if sc.fold != "none":
			S.play("step")
			paper.texture = Px.paper("half"))
	anim.tween_interval(0.7)
	anim.tween_callback(func():
		if sc.fold == "quarter":
			S.play("step")
			paper.texture = Px.paper("quarter"))
	anim.tween_interval(0.8)
	anim.tween_callback(func(): stage.show_flag("ขั้นสุดท้าย"))
	match sc.place:
		"table":
			anim.tween_callback(func(): stage.set_patient("table"))
			anim.tween_property(paper, "position", Vector2(206, 107), 0.6)
			anim.tween_callback(func():
				S.play("step")
				stage.set_patient("rest"))
		"back":
			anim.tween_callback(func(): stage.set_patient("reach_r"))
			anim.tween_property(paper, "position", Vector2(185, 99), 0.4)
			anim.tween_callback(func(): stage.set_nurse("offer"))
			anim.tween_property(paper, "position", NURSE_HOME + Vector2(14, -4), 0.6)
			anim.tween_callback(func():
				stage.set_patient("rest")
				paper.visible = false
				stage.set_nurse("clip"))
		_:
			anim.tween_interval(0.6)
	anim.tween_interval(0.8)
	anim.tween_callback(func():
		stage.show_flag("")
		_after_play())


func _play9(sc: Dictionary) -> void:
	var n := stage.nurse
	var s := G.slow()
	anim = create_tween()
	anim.tween_callback(func(): stage.show_flag("ยกกระดาษคำสั่งให้ผู้ป่วยอ่าน"))
	anim.tween_property(n, "position", NURSE_NEAR, 0.5)
	anim.tween_callback(func():
		stage.set_nurse("show")
		stage.show_prop("card", NURSE_NEAR + Vector2(14, -8))
		stage.labels.card.visible = true)
	anim.tween_interval(1.0 * s)
	anim.tween_callback(func():
		stage.show_flag("ผู้ป่วยกำลังอ่าน")
		if sc.read == "aloud":
			speak("patient", "“หลับตา”")
		elif sc.read == "silent":
			stage.set_think(true))
	anim.tween_interval(1.6 * s)
	anim.tween_callback(func():
		stage.set_think(false)
		stage.show_flag("")
		if sc.eyes == "shut":
			stage.set_patient("", "closed")
			patient_face("closed"))
	anim.tween_interval(2.4)
	anim.tween_callback(func():
		stage.set_patient("", "open")
		stage.hide_props()
		stage.set_nurse("clip"))
	anim.tween_property(n, "position", NURSE_HOME, 0.5)
	anim.tween_callback(_after_play)


func _after_play() -> void:
	var it: Dictionary = items[idx]
	phase = "score"
	replay_btn.visible = true
	for s in it.subs:
		var key: String = it.id + "." + s.k
		rows_state[key].on = false
		pad_set(key, "tickable", true)
	pad_ask.text = "ข้อ %d — ติ๊กเฉพาะขั้นที่ผู้ป่วยทำได้จริง แล้วกดบันทึก" % it.n
	UI.clear(pad_actions)
	pad_actions.add_child(UI.btn("✔ บันทึกคะแนน", _save, "ok", 15))
	speak("narr", "ให้คะแนนบนใบบันทึกด้านขวา")
	pad_open(true)


func _save() -> void:
	if phase != "score":
		return
	var it: Dictionary = items[idx]
	var rec: Dictionary = log_[it.id]
	for s in it.subs:
		var key: String = it.id + "." + s.k
		var st: Dictionary = rows_state[key]
		rec.given[s.k] = 1 if st.on else 0
		st.tickable = false
		st.on = false
		st.scored = true
		pad_set(key, "value", rec.given[s.k])
	UI.clear(pad_actions)
	pad_ask.text = ""
	phase = "next"
	replay_btn.visible = false
	stamp()
	_update()
	var label := ""
	var cb: Callable
	if idx >= items.size() - 1:
		label = "ไปข้อถัดไป" if G.run.i + items.size() < G.run.queue.size() else "ดูผลการประเมิน"
		cb = _finish
	else:
		label = "ไปข้อ %d" % items[idx + 1].n
		cb = func(): _set_item(idx + 1)
	var t := create_tween()
	t.tween_interval(0.9)
	t.tween_callback(func():
		pad_open(false)
		action(label, cb, "ok"))


func _update() -> void:
	var total := 0
	var list := []
	for i in items.size():
		var it: Dictionary = items[i]
		var rec: Dictionary = log_.get(it.id, {})
		var scored: bool = rec.size() > 0 and rec.given.size() > 0
		list.append({"t": "ข้อ %d" % it.n, "state": "done" if scored else ("now" if i == idx else "")})
		if scored:
			for s in it.subs:
				total += rec.given[s.k]
	set_dots(list)
	score_chip.text = "%d / %d" % [total, max_]
	pad_total.text = "%d / %d" % [total, max_]


func _finish() -> void:
	if anim:
		anim.kill()
	for it in items:
		var rec: Dictionary = log_[it.id]
		var given := 0
		var truth := 0
		var miss := []
		var rows := []
		var fbl := []
		for i in it.subs.size():
			var s: Dictionary = it.subs[i]
			var g: int = rec.given[s.k]
			var t: int = rec.sc.truth[s.k]
			given += g
			truth += t
			var no := ("%d.%d" % [it.n, i + 1]) if it.subs.size() > 1 else "%d." % it.n
			if g != t:
				miss.append(no + " " + s.t)
			rows.append({"no": no, "label": s.t, "detail": rec.sc.said[s.k], "sub": "ควรได้ %d คะแนน" % t,
				"given": g, "ok": g == t, "tag": ["ok", "บันทึกตรง"] if g == t else ["warn", "คลาดเคลื่อน"]})
		Parts.cmd_feedback(it, rec, fbl)
		if miss.size():
			fbl.append(G.fb("tip", "ข้อ %d บันทึกคลาดเคลื่อน %d จุด (%s)" % [it.n, miss.size(), " · ".join(miss)],
				"MMSE ให้คะแนนตาม “สิ่งที่ผู้ป่วยทำได้จริง” ทีละขั้น จุดที่พลาดกันบ่อยคือมือที่ใช้รับ — ถ้ารับด้วยมือซ้ายหรือรับสองมือ ถือว่าไม่ได้ทำตามคำสั่ง ขั้นนั้นได้ 0 คะแนน"))
		if replays > 0 and it.id == items[0].id:
			fbl.append(G.fb("info", "เปิดดูซ้ำ %d ครั้ง" % replays, "ในสถานการณ์จริงผู้ป่วยทำให้ดูเพียงครั้งเดียว ผู้ประเมินต้องสังเกตให้ครบตั้งแต่รอบแรก และห้ามขอให้ผู้ป่วยทำใหม่"))
		G.run.results[it.id] = {"rows": rows, "fb": fbl, "given": given, "truth": truth, "max": it.subs.size()}
	G.run.i += items.size() - 1
	G.next_run()
