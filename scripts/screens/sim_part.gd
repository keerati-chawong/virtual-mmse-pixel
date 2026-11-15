extends "res://scripts/screens/sim_base.gd"
## ข้อ 2 3 4 5 6 7 10 11 — เลือกคำพูด → ลงมือ → สังเกต → ติ๊กคะแนนบนคลิปบอร์ด

var id := ""
var P: Dictionary
var part: Dictionary
var phase := "pick"
var rec: Dictionary = {}
var replays := 0
var opts: Array = []
var chips: HFlowContainer


func setup(a: Dictionary) -> void:
	id = a.get("id", "place")


func _ready() -> void:
	build_base(G.room_kind())
	P = D.S_PARTS[id]
	part = D.part_of(id)
	opts = G.shuffled(P.options)
	set_title("ข้อ %d · %s" % [part.n, part.title], "%s — %d คะแนน" % [part.en, part.max])
	pad_head.text = P.cat
	pad_total.text = "0 / %d" % part.max
	score_chip.text = "0 / %d" % part.max
	stage.add_hotspot("win", Rect2(232, 12, 76, 60), "มองออกไปนอกหน้าต่าง", func(): G.pop("นอกหน้าต่าง", D.WIN_TEXT))
	if id == "place":
		stage.add_hotspot("ward", Rect2(59, 19, 58, 34), "ป้ายข้อมูลหอผู้ป่วย — คำตอบที่ถูกต้องของข้อ 2", _ward)
	if id == "draw" or id == "write":
		stage.props.table.visible = true
	chips = UI.flow(4)
	chips.position = Vector2(16, 96)
	chips.custom_minimum_size.x = 600
	add_child(chips)
	run_dots()
	speak("narr", D.t(P.hint).replace("[b]", "").replace("[/b]", ""))
	var t := create_tween()
	t.tween_interval(2.2)
	t.tween_callback(_menu)


func _menu() -> void:
	choices("จะพูดกับผู้ป่วยว่าอย่างไร?  (เลือกได้ครั้งเดียว — ผลจะสรุปตอนจบ)", opts.map(func(o): return D.t(o.text)), _pick)


func _ward() -> void:
	G.pop(D.ward_title(), D.ward_text())


func _pick(i: int) -> void:
	if phase != "pick":
		return
	var opt: Dictionary = opts[i]
	rec = {"text": D.t(opt.text), "type": opt.type, "sc": Parts.roll(id, opt.type), "given": {}}
	speak("nurse", D.t(opt.text), "normal")
	pad_clear()
	var list := Parts.rows(id, rec.sc)
	for k in list.size():
		var no := ("%d.%d" % [part.n, k + 1]) if list.size() > 1 else "%d." % part.n
		pad_row(list[k].k, no + " " + list[k].t)
	phase = "ready"
	action(P.act, _play)


func _on_replay() -> void:
	if phase != "score":
		return
	replays += 1
	pad_open(false)
	_play()


func _on_rubric() -> void:
	G.pop("เกณฑ์ข้อนี้", D.t(P.rubric))


func _play() -> void:
	phase = "playing"
	action_hide()
	replay_btn.visible = false
	UI.clear(pad_actions)
	pad_ask.text = ""
	for k in rows_state:
		rows_state[k].on = false
		rows_state[k].tickable = false
		pad_set(k, "scored", false)
	stop_seq()
	stage.reset_scene()
	if id == "draw" or id == "write":
		stage.props.table.visible = true
	UI.clear(chips)
	var sc: Dictionary = rec.sc
	match id:
		"reg":
			G.run.reg_words = sc.got.duplicate()
			run_seq(sc.seq, 2.3, _after_play)
		"calc":
			_play_calc(sc)
		"name":
			run_seq(sc.seq, 2.6, func():
				stage.hide_props()
				stage.set_nurse("clip")
				_after_play())
		"write", "draw":
			run_seq(sc.seq, 2.6, func():
				stage.hide_props()
				_proof()
				_after_play())
		_:
			run_seq(sc.seq, 2.3, _after_play)


func fx(name: String) -> void:
	match name:
		"pencil":
			stage.set_nurse("show")
			stage.show_prop("pencil", Vector2(132, 86))
		"watch":
			stage.props.pencil.visible = false
			stage.set_nurse("point")
			stage.show_prop("watch", Vector2(132, 88))
		"think":
			stage.set_think(true)
			patient_face("think")
			if id == "write" or id == "draw":
				stage.set_patient("table")
				stage.show_prop("write" if id == "write" else "penta", Vector2(200, 106))
			else:
				stage.set_patient("think")
		"unthink":
			stage.set_think(false)
			stage.set_patient("rest")
		_:
			super.fx(name)


func _chip(t: String) -> void:
	var c := UI.frame("slot_on", 8)
	c.add_child(UI.head(t, 16, UI.INK))
	chips.add_child(c)
	c.scale = Vector2(0.5, 0.5)
	c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)


func _play_calc(sc: Dictionary) -> void:
	if sc.mode == "spell":
		run_seq(sc.seq, 2.4, _after_play)
		return
	if sc.get("stuck", false):
		run_seq([{"q": rec.text, "a": D.t("{me}คิดเลขไม่เป็น{k}")}, {"q": "(ผู้ประเมินถามย้ำ)", "a": D.t("ไม่ไหว{k} คิดไม่ออก")}], 2.3, _after_play)
		return
	var s := G.slow()
	seq_tw = create_tween()
	seq_tw.tween_callback(func(): stage.show_flag("ให้เลข 100 แล้วให้ลบออกทีละ 7"))
	seq_tw.tween_interval(1.0)
	seq_tw.tween_callback(func(): speak("patient", D.t("ได้{k} ลองดู")))
	for i in 2:
		_calc_step(seq_tw, sc, i, s)
	seq_tw.tween_interval(1.0)
	seq_tw.tween_callback(func():
		stage.show_flag("ผู้ป่วยเงียบไป…")
		patient_face("think")
		stage.set_think(true)
		_ask_prompt(sc))


func _calc_step(tw: Tween, sc: Dictionary, i: int, s: float) -> void:
	tw.tween_interval(1.1 * s)
	tw.tween_callback(func():
		stage.show_flag("ครั้งที่ %d" % (i + 1))
		if sc.get("fingers", false) and i == 1:
			stage.set_patient("fingers"))
	tw.tween_interval(0.7 * s)
	tw.tween_callback(func():
		speak("patient", str(sc.ans[i]))
		_chip("%d) %s" % [i + 1, sc.ans[i]]))


func _ask_prompt(sc: Dictionary) -> void:
	var options := G.shuffled([{"type": "good", "text": "“ลบอีก 7 เหลือเท่าไหร่คะ”"}, {"type": "bad", "text": "“%s ลบอีก 7 เหลือเท่าไหร่คะ”" % str(sc.ans[1])}])
	choices("ผู้ป่วยหยุดคิด — จะพูดกระตุ้นว่าอย่างไร?", options.map(func(o): return o.text), func(i):
		rec.prompt = options[i].type
		stage.set_think(false)
		speak("nurse", options[i].text)
		_calc_rest(sc))


func _calc_rest(sc: Dictionary) -> void:
	var s := G.slow()
	seq_tw = create_tween()
	seq_tw.tween_interval(0.6)
	for i in range(2, 5):
		_calc_step(seq_tw, sc, i, s)
	seq_tw.tween_interval(1.2)
	seq_tw.tween_callback(func():
		stage.show_flag("")
		stage.set_patient("rest")
		_after_play())


func _proof() -> void:
	var sc: Dictionary = rec.sc
	if id == "write":
		var note := UI.frame("paper", 22)
		note.add_child(UI.label(sc.sentence.t, 32, Color("2c3e66")))
		G.pop("ลายมือของผู้ป่วย — อ่านแล้วมีความหมายหรือไม่", "", note)
	elif id == "draw":
		var h := UI.hbox(24)
		for pair in [["good", "รูปต้นแบบ"], [sc.variant.k, "รูปที่ผู้ป่วยวาด"]]:
			var v := UI.vbox(4)
			var f := UI.frame("paper", 8)
			f.add_child(UI.pix(Px.penta_drawing(pair[0]), 4.0))
			v.add_child(f)
			v.add_child(UI.label(pair[1], 13, UI.MUTED, true))
			h.add_child(v)
		G.pop("เทียบรูปต้นแบบกับรูปที่ผู้ป่วยวาด", "เกณฑ์: มุมครบ 5 มุมทั้งสองรูป และรอยตัดกันเป็นสี่เหลี่ยม", h)


func _after_play() -> void:
	phase = "score"
	replay_btn.visible = true
	for k in rows_state:
		rows_state[k].on = false
		pad_set(k, "tickable", true)
	pad_ask.text = "ติ๊กเฉพาะส่วนที่ผู้ป่วยทำได้จริง แล้วกดบันทึก"
	UI.clear(pad_actions)
	pad_actions.add_child(UI.btn("✔ บันทึกคะแนน", _save, "ok", 15))
	if id == "write" or id == "draw":
		pad_actions.add_child(UI.btn("ดูของกลางอีกที", _proof, "", 12))
	if id == "place":
		pad_actions.add_child(UI.btn("ดูป้ายหอผู้ป่วย", _ward, "", 12))
	speak("narr", "ให้คะแนนบนใบบันทึกด้านขวา — ติ๊กตามที่เห็นจริง")
	pad_open(true)
	on_row_toggled()


func on_row_toggled() -> void:
	var n := ticked_count()
	pad_total.text = "%d / %d" % [n, part.max]
	score_chip.text = "%d / %d" % [n, part.max]


func _save() -> void:
	if phase != "score":
		return
	for k in rows_state:
		var st: Dictionary = rows_state[k]
		rec.given[k] = 1 if st.on else 0
		st.tickable = false
		st.on = false
		st.scored = true
		pad_set(k, "value", rec.given[k])
	UI.clear(pad_actions)
	pad_ask.text = ""
	phase = "next"
	replay_btn.visible = false
	stamp()
	on_row_toggled()
	var last: bool = G.run.i >= G.run.queue.size() - 1
	var t := create_tween()
	t.tween_interval(0.9)
	t.tween_callback(func():
		pad_open(false)
		speak("nurse", "ขอบคุณ{c}ค่ะ".replace("{c}", G.scn().c), "smile")
		action("ดูผลการประเมิน" if last else "ไปข้อถัดไป", _finish, "ok"))


func _finish() -> void:
	stop_seq()
	var rows := []
	var fbl := []
	var given := 0
	var truth := 0
	var miss := []
	var list := Parts.rows(id, rec.sc)
	for i in list.size():
		var r: Dictionary = list[i]
		var g: int = rec.given[r.k]
		var t: int = rec.sc.truth[r.k]
		given += g
		truth += t
		var no := ("%d.%d" % [part.n, i + 1]) if list.size() > 1 else "%d." % part.n
		if g != t:
			miss.append(no + " " + r.t)
		rows.append({"no": no, "label": r.t, "detail": rec.sc.said[r.k], "sub": "ควรได้ %d คะแนน" % t,
			"given": g, "ok": g == t, "tag": ["ok", "บันทึกตรง"] if g == t else ["warn", "คลาดเคลื่อน"]})
	Parts.feedback(id, rec, fbl)
	if miss.size():
		fbl.append(G.fb("tip", "ข้อ %d บันทึกคลาดเคลื่อน %d จุด" % [part.n, miss.size()],
			" · ".join(miss) + " — ให้คะแนนไม่ตรงกับสิ่งที่ผู้ป่วยทำหรือพูดจริงในฉาก กด “เกณฑ์” ระหว่างเล่นเพื่อทบทวนเงื่อนไขได้เสมอ"))
	else:
		fbl.append(G.fb("good", "ข้อ %d บันทึกคะแนนตรงทุกจุด" % part.n, "สังเกตและให้คะแนนตรงกับสิ่งที่เกิดขึ้นจริงในฉาก"))
	if replays > 0:
		fbl.append(G.fb("info", "ข้อ %d เปิดดูซ้ำ %d ครั้ง" % [part.n, replays], "ในสถานการณ์จริงผู้ป่วยตอบหรือทำให้ดูเพียงครั้งเดียว ควรฝึกสังเกตให้ครบตั้งแต่รอบแรก"))
	G.part_done(id, {"rows": rows, "fb": fbl, "given": given, "truth": truth, "max": part.max})
