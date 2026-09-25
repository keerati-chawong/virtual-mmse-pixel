extends "res://scripts/screens/sim_base.gd"
## ข้อ 1 การรับรู้เวลา — เลือกหัวข้อ → เลือกวิธีถาม → ฟังคำตอบ → ให้คะแนนบนคลิปบอร์ด

var order := {}
var log_ := {}
var current := ""
var checked := {}
var nudged := false
var tw: Tween


func _ready() -> void:
	build_base("room")
	set_title("ข้อ 1 · การรับรู้เวลา", "Orientation for time — 5 คะแนน")
	pad_head.text = "ข้อ 1 การรับรู้เวลา (ข้อย่อยละ 1 คะแนน)"
	rubric_btn.text = "📅 ปฏิทิน"
	for item in D.ITEMS:
		order[item.id] = G.shuffled(item.options)
		pad_row(item.id, "1.%d %s" % [item.n, item.pad])
	stage.add_hotspot("cal", Rect2(276, 52, 24, 22), "เปิดดูปฏิทินตั้งโต๊ะ", _open_cal)
	stage.add_hotspot("win", Rect2(232, 12, 76, 60), "มองออกไปนอกหน้าต่าง", _open_win)
	stage.add_hotspot("ward", Rect2(59, 19, 58, 34), "ป้ายข้อมูลหอผู้ป่วย", _open_ward)
	_update()
	var s := G.scn()
	speak("narr", "คุณเดินเข้ามาที่เตียงของ %s (%d ปี) — ถามเรื่องเวลาให้ครบ 5 ข้อย่อย · ของที่มีประกาย ✦ ในห้องกดดูเพื่อตรวจคำตอบได้" % [s.name, s.age])
	var t := create_tween()
	t.tween_interval(2.6)
	t.tween_callback(_menu_topics)


func _menu_topics() -> void:
	var left := []
	for item in D.ITEMS:
		if not log_.has(item.id):
			left.append(item)
	if left.is_empty():
		speak("narr", "ถามครบทั้ง 5 ข้อย่อยแล้ว")
		action("สรุปผลข้อ 1", _finish, "ok")
		return
	choices("จะถามเรื่องอะไรต่อ?  (เหลือ %d ข้อย่อย)" % left.size(),
		left.map(func(it): return "ถามเรื่อง “%s”" % it.label),
		func(i): _menu_phrase(left[i].id))


func _menu_phrase(id: String) -> void:
	var item := _item(id)
	var opts: Array = order[id]
	var items := opts.map(func(o): return o.text)
	items.append("« เปลี่ยนหัวข้อ")
	choices("จะถามเรื่อง “%s” ว่าอย่างไร?" % item.label, items, func(i):
		if i >= opts.size():
			_menu_topics()
		else:
			_ask(i, id))


func _item(id: String) -> Dictionary:
	for it in D.ITEMS:
		if it.id == id:
			return it
	return {}


func _ask(i: int, id: String) -> void:
	var item := _item(id)
	var opt: Dictionary = order[id][i]
	var ans := Parts.time_answer(item, opt.type)
	current = id
	log_[id] = {"text": opt.text, "type": opt.type, "score": -1, "ans": ans}
	_update()
	speak("nurse", opt.text)
	var slow := G.slow()
	var off: bool = ans.get("off", false)
	if tw:
		tw.kill()
	tw = create_tween()
	tw.tween_interval(1.1)
	if slow > 1.2:
		tw.tween_callback(func():
			speak("patient", "เอ่อ…", "think")
			stage.set_think(true))
		tw.tween_interval(0.9)
	tw.tween_callback(func():
		stage.set_think(off, true)
		speak("patient", D.t(ans.t))
		if off:
			patient_face("confused"))
	tw.tween_interval(1.2 * slow)
	tw.tween_callback(func():
		pad_set(id, "active", true)
		pad_ask.text = "ข้อ 1.%d “%s”\nผู้ป่วยตอบว่า “%s” — ให้คะแนนหรือไม่?" % [item.n, item.pad, D.t(ans.t)]
		UI.clear(pad_actions)
		pad_actions.add_child(UI.btn("ตอบได้ · 1", func(): _score(1), "ok", 15))
		pad_actions.add_child(UI.btn("ตอบไม่ได้ · 0", func(): _score(0), "warn", 15))
		pad_actions.add_child(UI.btn("📅 ดูปฏิทินก่อน", _open_cal, "", 12))
		pad_open(true))


func _score(v: int) -> void:
	if current == "":
		return
	var id := current
	log_[id].score = v
	current = ""
	stage.set_think(false)
	pad_set(id, "active", false)
	rows_state[id].scored = true
	pad_set(id, "value", v)
	pad_ask.text = ""
	UI.clear(pad_actions)
	stamp()
	_update()
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_callback(func():
		pad_open(false)
		_menu_topics())
	var item_prop := "window" if id == "season" else "calendar"
	if not nudged and not checked.has(item_prop):
		nudged = true
		G.say("ยังไม่ได้ตรวจคำตอบใช่ไหม — ลองกดปฏิทินบนตู้ข้างเตียง ✦ ดูสิ")


func _update() -> void:
	var total := 0
	var list := []
	for item in D.ITEMS:
		var rec: Dictionary = log_.get(item.id, {})
		var st := ""
		if rec.size() and rec.score >= 0:
			st = "done"
			total += rec.score
		elif current == item.id:
			st = "now"
		list.append({"t": item.label, "state": st, "tip": item.pad})
	set_dots(list)
	score_chip.text = "%d / 5" % total
	pad_total.text = "%d / 5" % total


func _open_cal() -> void:
	checked.calendar = true
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for d in ["อา", "จ", "อ", "พ", "พฤ", "ศ", "ส"]:
		grid.add_child(UI.label(d, 13, UI.MUTED, true))
	var days := ["", "", "", 1, 2, 3, 4]
	for x in range(5, 32):
		days.append(x)
	for d in days:
		var c := PanelContainer.new()
		var today: bool = str(d) == "28"
		c.add_theme_stylebox_override("panel", UI.box(Color("d8556b") if today else Color.WHITE, UI.INK if today else UI.LINE, 2, 4))
		c.custom_minimum_size = Vector2(56, 26)
		var l := UI.label(str(d), 13, Color.WHITE if today else UI.INK, today)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(l)
		grid.add_child(c)
	var v := UI.vbox(6)
	var hd := UI.hbox(10)
	hd.add_child(UI.head("กรกฎาคม", 22, Color("d8556b")))
	hd.add_child(UI.head("2569", 22, UI.MUTED))
	v.add_child(hd)
	v.add_child(grid)
	G.pop("ปฏิทินตั้งโต๊ะ", D.CAL_TEXT, v)


func _open_win() -> void:
	checked.window = true
	var r := UI.pix(Px.tex(stage.vp.get_texture().get_image().get_region(Rect2i(232, 12, 76, 60))), 4.0)
	G.pop("นอกหน้าต่าง", D.WIN_TEXT, r)


func _open_ward() -> void:
	G.pop("ป้ายข้อมูลหอผู้ป่วย", D.t(D.WARD_TEXT))


func _on_rubric() -> void:
	_open_cal()


func _finish() -> void:
	var given := 0
	var truth := 0
	var leading := []
	var miss := []
	var rows := []
	var fbl := []
	var off_n := 0
	for item in D.ITEMS:
		var rec: Dictionary = log_[item.id]
		given += rec.score
		truth += rec.ans.ok
		if rec.type == "leading":
			leading.append(item)
		if rec.score != rec.ans.ok:
			miss.append(item)
		if rec.ans.get("off", false):
			off_n += 1
		rows.append({"no": "1.%d" % item.n, "label": item.label, "detail": rec.text,
			"sub": "ผู้ป่วย: “%s” — %s · ควรได้ %d คะแนน" % [D.t(rec.ans.t), rec.ans.why, rec.ans.ok],
			"given": rec.score, "ok": rec.score == rec.ans.ok,
			"tag": ["ok", "คำถามปลายเปิด"] if rec.type == "open" else ["warn", "คำถามชี้นำ"]})
	if leading.is_empty():
		fbl.append(G.fb("good", "ข้อ 1 การรับรู้เวลา — ใช้คำถามปลายเปิดครบทั้ง 5 ข้อย่อย", "คุณไม่ได้ใบ้คำตอบให้ผู้ป่วยเลย ผลที่ได้จึงสะท้อนความสามารถจริงของผู้ป่วย เป็นเทคนิคการถามที่ถูกต้องตามคู่มือ MMSE"))
	else:
		var names := leading.map(func(i): return "1.%d %s" % [i.n, i.label])
		var opens := leading.map(func(i):
			for o in i.options:
				if o.type == "open":
					return o.text
			return "")
		fbl.append(G.fb("tip", "ข้อ 1 การรับรู้เวลา — ใช้คำถามชี้นำ %d ข้อย่อย (%s)" % [leading.size(), " · ".join(names)],
			"คำถามชี้นำใส่คำตอบไว้ในคำถามแล้ว ผู้ป่วยจึงตอบตามได้โดยไม่ต้องระลึกเอง ถ้าใบ้ถูกคะแนนจะสูงเกินจริง ถ้าใบ้ผิดผู้ป่วยก็ตอบผิดตามทั้งที่ตอบเองได้ — แปลผลไม่ได้ทั้งสองทาง",
			"ควรถามแบบปลายเปิด เช่น " + " / ".join(opens)))
	if miss.is_empty():
		fbl.append(G.fb("good", "ข้อ 1 การรับรู้เวลา — ให้คะแนนตรงกับคำตอบทุกข้อย่อย", "เทียบคำตอบกับปฏิทินได้ครบ อย่าลืมว่าเกณฑ์รับคำตอบทั้งปฏิทินสากลและจันทรคติ เช่น “ขึ้น 14 ค่ำ” “วันโกน” “เดือน 9” “ปีมะเมีย” ล้วนได้ 1 คะแนนเท่ากับคำตอบแบบสากล"))
	else:
		fbl.append(G.fb("tip", "ข้อ 1 การรับรู้เวลา — บันทึกคะแนนคลาดเคลื่อน %d ข้อย่อย" % miss.size(),
			"ข้อ " + " · ".join(miss.map(func(i): return "1.%d %s" % [i.n, i.label])) + " ให้คะแนนไม่ตรงกับคำตอบที่ผู้ป่วยพูดจริง จุดพลาดที่พบบ่อยคือหักคะแนนคำตอบแบบจันทรคติหรือปีนักษัตร ทั้งที่เกณฑ์นับให้เท่ากับปฏิทินสากล"))
	if off_n > 0:
		fbl.append(G.fb("info", "ผู้ป่วยตอบไม่ตรงคำถาม %d ครั้ง" % off_n, "ผู้ป่วยที่สับสนอาจตอบเรื่องอื่นแทน เช่น ถามถึงลูกหรือการกลับบ้าน คำตอบที่ไม่ตรงคำถามถือว่าตอบไม่ได้ ข้อย่อยนั้นได้ 0 คะแนน — ผู้ประเมินควรใจเย็น รอ และบันทึกตามจริง"))
	var used := []
	if checked.has("calendar"):
		used.append("ปฏิทิน")
	if checked.has("window"):
		used.append("นอกหน้าต่าง")
	if used.size():
		fbl.append(G.fb("good", "ตรวจสอบข้อมูลในสถานการณ์ก่อนให้คะแนน", "คุณเปิดดู " + " และ ".join(used) + " ก่อนบันทึก เป็นนิสัยที่ดี เพราะผู้ประเมินต้องรู้คำตอบที่ถูกต้องของเวลาและสถานที่นั้นเสมอ"))
	else:
		fbl.append(G.fb("tip", "ยังไม่ได้ตรวจสอบสิ่งของในห้อง", "ในฉากมีปฏิทินตั้งโต๊ะและหน้าต่างที่แตะดูได้ ผู้ประเมินควรทราบวันเวลาที่ถูกต้องก่อน จึงจะตัดสินได้ว่าคำตอบของผู้ป่วยถูกหรือผิด"))
	G.part_done("time", {"rows": rows, "fb": fbl, "given": given, "truth": truth, "max": 5})
