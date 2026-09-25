extends Control
## เมนูเกม — เลือกผู้ป่วย (character select) · เลือกโหมด · ด่านฝึกทีละข้อพร้อมดาว

var cards_row: HBoxContainer
var levels: GridContainer
var levels_box: Control


func _ready() -> void:
	add_child(UI.backdrop(0.6))
	var col := UI.vbox(12)
	var sc := UI.scroll(UI.margin(col, 22))
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sc)

	var top := UI.hbox(12)
	top.add_child(UI.btn("◀ Title", func(): G.goto("home"), "", 13))
	top.add_child(UI.title("เลือกผู้ป่วยที่จะประเมิน", 32, Color.WHITE))
	col.add_child(top)
	cards_row = UI.hbox(18)
	col.add_child(cards_row)
	_render_cards()

	var modes := UI.hbox(14)
	var full := UI.btn("🏥  ประเมินเต็มชุด 11 ข้อ  (Story mode)", func(): G.goto("brief", {"mode": "new"}), "primary", 20)
	full.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full.tooltip_text = "คัดกรองผู้ป่วย → หยิบอุปกรณ์ → เข้าห้องตรวจ → ประเมินครบ 11 ข้อ → แปลผล"
	modes.add_child(full)
	var fs := G.best_stars("full")
	if fs > 0:
		modes.add_child(_stars(fs, 22))
	modes.add_child(UI.btn("📜 ประวัติ", _history, "", 15))
	col.add_child(modes)

	var lh := UI.hbox(8)
	lh.add_child(UI.title("🎯 ด่านฝึกทีละข้อ", 20, UI.GOLD))
	lh.add_child(UI.label("  (ถือว่าอุปกรณ์พร้อม และผู้ป่วยอ่านออกเขียนได้)", 13, Color("cfe3f7")))
	col.add_child(lh)
	levels = GridContainer.new()
	levels.columns = 6
	levels.add_theme_constant_override("h_separation", 10)
	levels.add_theme_constant_override("v_separation", 10)
	col.add_child(levels)
	_render_levels()


func _stars(n: int, size: int = 16) -> Label:
	var l := UI.title("★".repeat(n) + "☆".repeat(3 - n), size, UI.GOLD)
	return l


func _stat(name: String, v: int, color: Color) -> Control:
	var h := UI.hbox(6)
	var l := UI.label(name, 12, Color("cfe3f7"), true)
	l.custom_minimum_size.x = 96
	h.add_child(l)
	for i in 5:
		var b := ColorRect.new()
		b.custom_minimum_size = Vector2(18, 10)
		b.color = color if i < v else Color("2c3e55")
		h.add_child(b)
	return h


func _render_cards() -> void:
	UI.clear(cards_row)
	var stats := {"s1": [5, 4, 5], "s2": [3, 2, 2]}
	for s in D.SCENARIOS:
		var on: bool = G.scenario_key == s.k
		var card := UI.frame("slot_on" if on else "dialog", 16)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var k: String = s.k
		card.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				S.play("ok")
				G.scenario_key = k
				_render_cards()
				_render_levels())
		var h := UI.hbox(16)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(h)
		var pv := UI.vbox(4)
		var pf := UI.frame("slot", 6)
		pf.add_child(UI.pix(Px.portrait(s.sex, "normal" if s.k == "s1" else "confused"), 3.6))
		pv.add_child(pf)
		var body := UI.pix(Px.patient(s.sex, "rest", "open" if s.k == "s1" else "worried"), 2.0)
		pv.add_child(body)
		h.add_child(pv)
		var v := UI.vbox(6)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var fg := UI.INK if on else Color.WHITE
		var tag := UI.hbox(8)
		tag.add_child(UI.title("SCENARIO %d" % s.no, 16, s.tint.lightened(0.2), UI.INK))
		if on:
			tag.add_child(UI.title("◀ เลือกแล้ว", 14, UI.OK, Color.WHITE))
		v.add_child(tag)
		v.add_child(UI.title("%s  %d ปี" % [s.name, s.age], 26, Color.WHITE if not on else UI.INK, UI.INK if not on else Color.WHITE))
		v.add_child(UI.label(s.short, 15, fg, true))
		var st: Array = stats[s.k]
		var sb := UI.frame("dialog", 10)
		var sv := UI.vbox(4)
		sb.add_child(sv)
		sv.add_child(_stat("ความร่วมมือ", st[0], Color("5fd18f")))
		sv.add_child(_stat("ความจำ", st[1], Color("7fb2e0")))
		sv.add_child(_stat("ความเร็วตอบ", st[2], UI.GOLD))
		v.add_child(sb)
		var summary := "เข้ารักษาด้วยอาการอ่อนเพลีย กินได้น้อย สื่อสารได้ดี เริ่มหลงลืมเล็กน้อย" if s.k == "s1" \
			else "มีประวัติหลงลืม ถามคำถามเดิมซ้ำ ๆ สับสนเรื่องวันและสถานที่ ตอบช้า บางครั้งตอบไม่ตรง"
		v.add_child(UI.wrap(UI.label(summary, 13, fg)))
		var story: String = s.story
		v.add_child(UI.btn("📄 อ่านเคสเต็ม", func(): G.pop("Scenario %d · %s" % [s.no, s.short], story), "", 12))
		for ch in v.get_children():
			ch.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(v)
		cards_row.add_child(card)


func _render_levels() -> void:
	UI.clear(levels)
	for p in D.PARTS:
		var st := G.best_stars(p.id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(186, 108)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_stylebox_override("normal", UI.tbox("dialog", 10))
		b.add_theme_stylebox_override("hover", UI.tbox("slot_on", 10))
		b.add_theme_stylebox_override("pressed", UI.tbox("btn_press", 10))
		var v := UI.vbox(0)
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 12
		v.offset_top = 8
		v.offset_right = -10
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var h := UI.hbox(8)
		h.add_child(UI.title(str(p.n), 30, p.tint.lightened(0.25)))
		var hv := UI.vbox(-4)
		hv.add_child(UI.label(p.title, 13, Color.WHITE, true))
		hv.add_child(UI.label("%d คะแนน" % p.max, 11, Color("a9c6e3")))
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(hv)
		v.add_child(h)
		v.add_child(_stars(st, 18))
		for ch in [h, hv] + h.get_children() + hv.get_children() + v.get_children():
			ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		b.tooltip_text = p.en + " — " + p.desc
		var id: String = p.id
		b.mouse_entered.connect(func(): S.play("hover"))
		b.pressed.connect(func():
			S.play("ok")
			G.start_single_run(id))
		levels.add_child(b)


func _history() -> void:
	var h := G.read_history()
	var bb := ""
	if h.is_empty():
		bb = "ยังไม่มีประวัติ — ลองเล่นสัก 1 รอบดูก่อนนะ"
	for rec in h:
		bb += "[b]%d / %d[/b]  ·  %s · %s · %s\n" % [rec.score, rec.max, rec.when, rec.mod,
			("บันทึกคลาดเคลื่อน %d จุด" % rec.miss) if rec.miss else "บันทึกตรงทุกจุด"]
	G.pop("ประวัติคะแนน", bb)
