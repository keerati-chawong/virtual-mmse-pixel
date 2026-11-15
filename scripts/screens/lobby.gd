extends Control
## เมนูเกม — ① เลือกสถานที่ (โรงพยาบาล/ชุมชน) · ② เลือกระดับความยาก → สุ่มเคส · ③ เคสที่ได้
## โหมดประเมินเต็มชุด · ด่านฝึกทีละข้อพร้อมดาว · ทางไปตู้เสื้อผ้า / Achievement

var pick_row: HBoxContainer
var case_box: VBoxContainer
var levels: GridContainer
var full_stars: HBoxContainer
var coin_l: Label


func _ready() -> void:
	if D.scenario(G.scenario_key).diff != G.diff:
		G.roll_case()
	add_child(UI.backdrop(0.6))
	var col := UI.vbox(12)
	var sc := UI.scroll(UI.margin(col, 20))
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sc)

	var top := UI.hbox(10)
	top.add_child(UI.btn("◀ Title", func(): G.goto("home"), "", 13))
	top.add_child(UI.title("เมนูเกม", 32, Color.WHITE))
	top.add_child(UI.spacer())
	var cf := UI.frame("slot_on", 8)
	coin_l = UI.head("🪙 %d" % Prof.coins(), 18, UI.INK)
	cf.add_child(coin_l)
	top.add_child(cf)
	top.add_child(UI.btn("👗 แต่งตัว & ร้านค้า", func(): G.goto("wardrobe"), "", 14))
	top.add_child(UI.btn("🏆 Achievement", func(): G.goto("achieve"), "", 14))
	top.add_child(UI.btn("ออกจากระบบ", func():
		G.set_user("")
		G.say("ออกจากระบบแล้ว")
		G.goto("home"), "", 12))
	col.add_child(top)

	pick_row = UI.hbox(14)
	col.add_child(pick_row)
	case_box = UI.vbox(0)
	col.add_child(case_box)

	var modes := UI.hbox(14)
	var full := UI.btn("🩺  ประเมินเต็มชุด 11 ข้อ  (Story mode)", func(): G.goto("brief", {"mode": "new"}), "primary", 20)
	full.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	full.tooltip_text = "คัดกรองผู้ป่วย → หยิบอุปกรณ์ → เข้าไปประเมิน → ประเมินครบ 11 ข้อ → แปลผล"
	modes.add_child(full)
	full_stars = UI.hbox(0)
	modes.add_child(full_stars)
	modes.add_child(UI.btn("📜 ประวัติ", _history, "", 15))
	col.add_child(modes)

	var lh := UI.hbox(8)
	lh.add_child(UI.title("🎯 ด่านฝึกทีละข้อ", 20, UI.GOLD))
	lh.add_child(UI.label("  (ถือว่าอุปกรณ์พร้อม และผู้ป่วยอ่านออกเขียนได้)", 14, UI.INK_2, true))
	col.add_child(lh)
	levels = GridContainer.new()
	levels.columns = 6
	levels.add_theme_constant_override("h_separation", 10)
	levels.add_theme_constant_override("v_separation", 10)
	col.add_child(levels)
	_render()


func _render() -> void:
	_render_picks()
	_render_case()
	_render_levels()
	UI.clear(full_stars)
	var fs := G.best_stars("full")
	if fs > 0:
		full_stars.add_child(_stars(fs, 22))


func _stars(n: int, size: int = 16) -> Label:
	return UI.title("★".repeat(n) + "☆".repeat(3 - n), size, UI.GOLD)


## การ์ดตัวเลือก (สถานที่ / ระดับความยาก)
func _card(head: String, desc: String, on: bool, tint: Color, cb: Callable, wide: float = 220) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(wide, 92)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", UI.tbox("slot_on" if on else "dialog", 10))
	b.add_theme_stylebox_override("hover", UI.tbox("slot_on", 10))
	b.add_theme_stylebox_override("pressed", UI.tbox("slot_on", 10))
	var v := UI.vbox(2)
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_top = 10
	v.offset_right = -12
	v.offset_bottom = -8
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UI.title(head, 20, tint, Color.WHITE)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(t)
	if on:
		var ok := UI.title("✔ เลือกแล้ว", 13, UI.OK, Color.WHITE)
		ok.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(ok)
	v.add_child(h)
	var d := UI.wrap(UI.label(desc, 13, UI.INK_2))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(d)
	b.add_child(v)
	b.mouse_entered.connect(func(): S.play("hover"))
	b.pressed.connect(func():
		S.play("ok")
		cb.call())
	return b


func _render_picks() -> void:
	UI.clear(pick_row)
	var sv := UI.vbox(6)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_child(UI.title("① เลือกสถานที่ประเมิน", 18, UI.GOLD))
	var sh := UI.hbox(10)
	for st in D.SETTINGS:
		var k: String = st.k
		sh.add_child(_card(st.icon + " " + st.t, st.desc, G.setting == k, UI.BRAND, func():
			G.setting = k
			_render()))
	sv.add_child(sh)
	pick_row.add_child(sv)
	var dv := UI.vbox(6)
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dv.size_flags_stretch_ratio = 1.4
	dv.add_child(UI.title("② เลือกระดับความยาก  (ระบบจะสุ่มเคสให้ 1 ใน 3)", 18, UI.GOLD))
	var dh := UI.hbox(10)
	for d in D.DIFFS:
		var k: String = d.k
		dh.add_child(_card("★".repeat(d.lv) + " " + d.t, d.desc, G.diff == k, d.tint, func():
			if G.diff != k:
				G.roll_case(k)
				G.say("สุ่มได้เคส: %s %d ปี" % [G.scn().name, G.scn().age])
			_render(), 150))
	dv.add_child(dh)
	pick_row.add_child(dv)


func _stat(name: String, v: int, color: Color) -> Control:
	var h := UI.hbox(6)
	var l := UI.label(name, 12, UI.INK_2, true)
	l.custom_minimum_size.x = 96
	h.add_child(l)
	for i in 5:
		var b := ColorRect.new()
		b.custom_minimum_size = Vector2(18, 10)
		b.color = color if i < v else Color("d3dde8")
		h.add_child(b)
	return h


func _render_case() -> void:
	UI.clear(case_box)
	var s := G.scn()
	var dd := D.diff_of(s.diff)
	var card := UI.frame("dialog", 16)
	var h := UI.hbox(18)
	card.add_child(h)
	var pv := UI.vbox(4)
	var pf := UI.frame("slot", 6)
	var hard: bool = float(s.confuse) > 0.2
	pf.add_child(UI.pix(Px.portrait(s.sex, "confused" if hard else "normal"), 3.2))
	pv.add_child(pf)
	h.add_child(pv)
	h.add_child(UI.pix(Px.patient(s.sex, "rest", "worried" if hard else "open"), 2.0))
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tag := UI.hbox(8)
	tag.add_child(UI.title("③ เคสที่สุ่มได้", 16, UI.GOLD))
	tag.add_child(UI.chip("★".repeat(dd.lv) + " " + dd.t, Color.WHITE, dd.tint, 12))
	tag.add_child(UI.chip(D.setting_of(G.setting).icon + " " + D.setting_of(G.setting).t, UI.BRAND_SOFT, UI.BRAND, 12))
	if s.get("draft", false):
		var dr := UI.chip("เคสตัวอย่าง (รอเนื้อหาจริง)", UI.WARN_SOFT, UI.WARN, 11)
		dr.tooltip_text = "เคสนี้เป็นตัวอย่างชั่วคราว — แก้ไข/แทนที่ได้ใน scripts/data.gd (SCENARIOS)"
		tag.add_child(dr)
	v.add_child(tag)
	v.add_child(UI.title("%s  %d ปี" % [s.name, s.age], 26, UI.INK, Color.WHITE))
	v.add_child(UI.label(s.short, 15, UI.INK_2, true))
	v.add_child(UI.wrap(UI.label(s.hx, 13, UI.INK_2)))
	var bh := UI.hbox(8)
	var story := D.story_of(s, G.setting)
	bh.add_child(UI.btn("📄 อ่านเคสเต็ม", func(): G.pop("%s · %s" % [s.name, s.short], story), "", 13))
	bh.add_child(UI.btn("🎲 สุ่มเคสใหม่", func():
		G.roll_case()
		S.play("ok")
		_render(), "", 13))
	v.add_child(bh)
	h.add_child(v)
	var st: Array = s.get("stats", [3, 3, 3])
	var sb := UI.frame("slot", 10)
	sb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sv := UI.vbox(6)
	sb.add_child(sv)
	sv.add_child(_stat("ความร่วมมือ", st[0], UI.OK))
	sv.add_child(_stat("ความจำ", st[1], UI.BRAND))
	sv.add_child(_stat("ความเร็วตอบ", st[2], Color("e0a93a")))
	h.add_child(sb)
	case_box.add_child(card)


func _render_levels() -> void:
	UI.clear(levels)
	for p in D.PARTS:
		var st := G.best_stars(p.id)
		var b := Button.new()
		b.custom_minimum_size = Vector2(190, 100)
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
		h.add_child(UI.title(str(p.n), 30, p.tint, Color.WHITE))
		var hv := UI.vbox(-4)
		hv.add_child(UI.label(p.title, 14, UI.INK, true))
		hv.add_child(UI.label("%d คะแนน" % p.max, 12, UI.MUTED))
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
