extends Control
## เตรียมตัวก่อนเข้าห้องตรวจ — ขั้นที่ 1 แฟ้มคัดกรองผู้ป่วย · ขั้นที่ 2 โต๊ะหยิบอุปกรณ์

var mode := "new"
var note := ""
var step := 1
var body: Control
var step_btns: Array = []
var warn_panel: PanelContainer
var warn_text: RichTextLabel
var go_btn: Button


func setup(args: Dictionary) -> void:
	mode = args.get("mode", "new")
	note = args.get("note", "")
	step = 2 if mode == "resume" else 1


func _ready() -> void:
	add_child(UI.backdrop(0.7))
	var col := UI.vbox(10)
	var m := UI.margin(col, 18)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var top := UI.hbox(12)
	if mode != "resume":
		top.add_child(UI.btn("◀ เมนู", func(): G.goto("lobby"), "", 13))
	top.add_child(UI.title("เตรียมตัวก่อนเยี่ยมบ้าน" if G.is_comm() else "เตรียมตัวก่อนเข้าห้องตรวจ", 28, Color.WHITE))
	top.add_child(UI.spacer())
	for i in [1, 2]:
		var b := UI.btn("① แฟ้มคัดกรองผู้ป่วย" if i == 1 else "② โต๊ะหยิบอุปกรณ์", func(): _set_step(i), "", 15)
		step_btns.append(b)
		top.add_child(b)
	col.add_child(top)

	# หัวหน้าเวรบรีฟ
	var npc := UI.frame("dialog", 12)
	var nh := UI.hbox(12)
	npc.add_child(nh)
	var pf := UI.frame("slot", 4)
	pf.add_child(UI.pix(Px.portrait("head", "smile"), 1.6))
	nh.add_child(pf)
	var nv := UI.vbox(0)
	nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nv.add_child(UI.title("พยาบาล รพ.สต. (พี่เลี้ยง)" if G.is_comm() else "พยาบาลหัวหน้าเวร", 15, UI.GOLD))
	var brief_t := ("วันนี้เราจะไปเยี่ยมบ้าน %s นะ ก่อนออกไป" if G.is_comm() else "ก่อนเข้าไปประเมิน %s ") + "ต้องคัดกรองผู้ป่วยตามข้อบังคับของ MMSE ก่อนนะ แล้วหยิบอุปกรณ์ให้ครบ 6 ชิ้น — ของบนโต๊ะมีของหลอกปนอยู่ด้วย ระวังหยิบผิด!"
	brief_t = brief_t % G.scn().name
	if mode == "resume":
		brief_t = "ลืมของใช่ไหม? หยิบให้ครบแล้วกลับไปประเมินต่อได้เลย"
	nv.add_child(UI.wrap(UI.label(brief_t, 15, UI.DIALOG_TEXT)))
	nh.add_child(nv)
	nh.add_child(UI.btn("📖 คู่มือผู้ประเมิน", func(): G.pop("คำสั่งสำหรับผู้ประเมิน", D.RULES_TEXT), "", 13))
	col.add_child(npc)

	warn_panel = UI.frame("slot_on", 12)
	warn_text = UI.rich(note, 14)
	warn_panel.add_child(warn_text)
	warn_panel.visible = note != ""
	col.add_child(warn_panel)

	body = Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	var bottom := UI.hbox(10)
	bottom.add_child(UI.spacer())
	go_btn = UI.btn("", _next, "primary", 20)
	bottom.add_child(go_btn)
	col.add_child(bottom)
	_set_step(step)


func _set_step(s: int) -> void:
	step = s
	for i in step_btns.size():
		step_btns[i].add_theme_stylebox_override("normal", UI.tbox("slot_on" if i + 1 == s else "btn_light", 12))
	UI.clear(body)
	var c := _chart() if s == 1 else _table()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(c)
	if s == 1:
		go_btn.text = "  ไปหยิบอุปกรณ์  ▶  "
	else:
		go_btn.text = "  กลับไปประเมินต่อ  ▶  " if mode == "resume" else ("  ออกเยี่ยมบ้าน  ▶  " if G.is_comm() else "  เข้าห้องตรวจ  ▶  ")


# ---------- ขั้นที่ 1: แฟ้มคัดกรอง ----------
func _chart() -> Control:
	var h := UI.hbox(14)
	var paper := UI.frame("paper", 18)
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper.size_flags_stretch_ratio = 1.7
	var v := UI.vbox(10)
	paper.add_child(UI.scroll(v))
	var ph := UI.hbox(10)
	ph.add_child(UI.pix(Px.portrait(G.scn().sex), 1.4))
	var pv := UI.vbox(-2)
	pv.add_child(UI.head("แบบคัดกรองก่อนใช้ MMSE", 20, UI.PAPER_INK))
	pv.add_child(UI.label("ผู้ป่วย: %s อายุ %d ปี · %s" % [G.scn().name, G.scn().age, D.t("{ward}")], 13, Color("7a6656"), true))
	ph.add_child(pv)
	v.add_child(ph)
	for q in D.SCREEN_QS:
		var qv := UI.vbox(4)
		qv.add_child(UI.wrap(UI.label("▸ " + q.q, 15, UI.PAPER_INK, true)))
		var seg := UI.flow(6)
		for o in q.opts:
			var on: bool = G.setup.ans.get(q.k, "") == o.v
			var blockv: bool = q.get("block", "") == o.v
			var b := UI.btn(("☑ " if on else "☐ ") + o.t, func():
				G.setup.ans[q.k] = o.v
				_set_step(1), "", 14)
			if on:
				b.add_theme_stylebox_override("normal", UI.tbox("btn_orange" if blockv else "btn_green", 10))
				b.add_theme_color_override("font_color", Color.WHITE)
			seg.add_child(b)
		qv.add_child(seg)
		qv.add_child(UI.wrap(UI.label(q.why, 11, Color("8f7a66"))))
		v.add_child(qv)
	h.add_child(paper)

	var side := UI.frame("dialog", 16)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv := UI.vbox(8)
	side.add_child(sv)
	sv.add_child(UI.title("ชุดข้อที่จะประเมิน", 18, UI.GOLD))
	if not G.setup.ans.has("pedu"):
		sv.add_child(UI.wrap(UI.label("ตอบแบบคัดกรองให้ครบ ระบบจะจัดชุดข้อให้ตามระดับการศึกษาของผู้ป่วย", 13, UI.INK_2)))
	else:
		var skip := G.is_illiterate()
		var fl := UI.flow(4)
		for p in D.PARTS:
			var off: bool = skip and p.get("skip_illiterate", false)
			var ch := UI.frame("slot" if off else "btn", 5)
			ch.custom_minimum_size.x = 34
			var l := UI.label(str(p.n), 13, UI.FAINT if off else Color.WHITE, true)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ch.add_child(l)
			ch.tooltip_text = p.title + (" (ข้าม)" if off else "")
			fl.add_child(ch)
		sv.add_child(fl)
		sv.add_child(UI.title("คะแนนเต็ม %d" % G.plan_max(), 22, Color.WHITE))
		sv.add_child(UI.wrap(UI.label("จุดตัด ≤ %d = สงสัยภาวะสมองเสื่อม" % D.cut_of(G.patient_edu()).cut, 14, UI.GOLD, true)))
		if skip:
			sv.add_child(UI.wrap(UI.label("ผู้ป่วยอ่านไม่ออกเขียนไม่ได้ → ข้ามข้อ 4 · 9 · 10", 13, UI.INK_2)))
	h.add_child(side)
	return h


# ---------- ขั้นที่ 2: โต๊ะอุปกรณ์ ----------
func _table() -> Control:
	var v := UI.vbox(10)
	var table := UI.frame("wood", 18)
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tv := UI.vbox(8)
	table.add_child(tv)
	tv.add_child(UI.title("โต๊ะเตรียมอุปกรณ์ — คลิกของเพื่อใส่ถาด / เอาออก", 17, Color.WHITE, Color("3b2414")))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	var order := G.shuffled(D.KIT) if not has_meta("kit_order") else get_meta("kit_order")
	set_meta("kit_order", order)
	for it in order:
		var picked: bool = G.setup.kit.get(it.k, false)
		var b := Button.new()
		b.custom_minimum_size = Vector2(160, 96)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_stylebox_override("normal", UI.tbox("slot" if picked else "paper", 6))
		b.add_theme_stylebox_override("hover", UI.tbox("slot_on", 6))
		b.add_theme_stylebox_override("pressed", UI.tbox("slot_on", 6))
		var bv := UI.vbox(0)
		bv.set_anchors_preset(Control.PRESET_FULL_RECT)
		bv.alignment = BoxContainer.ALIGNMENT_CENTER
		bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := UI.pix(Px.kit_icon(it.k), 3.0)
		ic.modulate.a = 0.25 if picked else 1.0
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(ic)
		var l := UI.label(it.t if not picked else "(อยู่ในถาด)", 12, UI.PAPER_INK if not picked else UI.MUTED, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bv.add_child(l)
		b.add_child(bv)
		var k: String = it.k
		b.mouse_entered.connect(func(): S.play("hover"))
		b.pressed.connect(func():
			S.play("step" if G.setup.kit.get(k, false) else "open")
			G.setup.kit[k] = not G.setup.kit.get(k, false)
			_set_step(2))
		grid.add_child(b)
	tv.add_child(grid)
	v.add_child(table)

	# ถาดอุปกรณ์ (inventory)
	var tray := UI.frame("dialog", 12)
	var th := UI.hbox(8)
	tray.add_child(th)
	th.add_child(UI.title("ถาด", 18, UI.GOLD))
	var picked_list := []
	for it in D.KIT:
		if G.setup.kit.get(it.k, false):
			picked_list.append(it)
	for i in maxi(6, picked_list.size()):
		var slot := UI.frame("slot_on" if i < picked_list.size() else "slot", 4)
		slot.custom_minimum_size = Vector2(60, 60)
		if i < picked_list.size():
			var ic := UI.pix(Px.kit_icon(picked_list[i].k), 3.0)
			slot.add_child(ic)
			slot.tooltip_text = picked_list[i].t
		th.add_child(slot)
	var msg := UI.vbox(2)
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var miss := G.missing_kit()
	var wrong := G.wrong_kit()
	if miss.is_empty() and wrong.is_empty():
		msg.add_child(UI.title("ครบ 6 ชิ้น ถูกต้อง! พร้อมเข้าห้องตรวจ", 16, UI.OK))
	else:
		msg.add_child(UI.label("หยิบแล้ว %d ชิ้น" % picked_list.size(), 14, UI.INK, true))
		msg.add_child(UI.wrap(UI.label("ถ้าขาดหรือหยิบผิด ยังเข้าไปได้ แต่ถึงข้อที่ต้องใช้จะต้องเดินกลับมาหยิบ", 12, UI.INK_2)))
	th.add_child(msg)
	v.add_child(tray)
	return v


func _next() -> void:
	if step == 1:
		_set_step(2)
		return
	if mode == "resume":
		G.goto("walk", {"mode": "in", "resume": true})
		return
	if not G.screen_complete():
		S.play("error")
		G.say("ตอบแบบคัดกรองให้ครบทุกข้อก่อนนะ")
		_set_step(1)
		return
	var b := G.blocked_reason()
	if not b.is_empty():
		var chosen := ""
		for o in b.opts:
			if o.v == b.block:
				chosen = o.t
		warn_text.text = "[b]ยังเริ่มประเมินไม่ได้ตามข้อบังคับของเครื่องมือ[/b]\n%s → คุณตอบว่า “%s”\n%s" % [b.q, chosen, b.why]
		warn_panel.visible = true
		S.play("error")
		_set_step(1)
		return
	if G.missing_kit().size() or G.wrong_kit().size():
		G.say("อุปกรณ์ยังไม่ครบ/ไม่ถูกต้อง — เข้าไปได้ แต่ถึงข้อที่ต้องใช้จะต้องเดินกลับมาหยิบ")
	S.play("ok")
	G.goto("walk", {"mode": "in", "resume": false})
