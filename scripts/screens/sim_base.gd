extends Control
## โครงหน้าจอเกมประเมิน (สไตล์ RPG)
##   ฉาก pixel เต็มจอ · HUD ด้านบน · กล่องบทสนทนาพร้อมภาพหน้าตัวละคร + ตัวเลือกคำพูด
##   ปุ่มการกระทำลอยเหนือกล่อง · คลิปบอร์ดใบคะแนนเลื่อนออกมาจากด้านขวา

signal typed

var stage: Stage
# HUD
var hud_title: Label
var hud_sub: Label
var dots: HBoxContainer
var score_chip: Label
var rubric_btn: Button
var sheet_btn: Button
# กล่องบทสนทนา
var dlg: PanelContainer
var dlg_portrait: TextureRect
var dlg_port_box: Control
var dlg_name: Label
var dlg_text: RichTextLabel
var dlg_choices: GridContainer
var dlg_next: Label
var type_tw: Tween
var _type_who := ""
var _type_last := 0
var _choice_cb: Callable
var _choice_btns: Array = []
# ปุ่มการกระทำ
var act_btn: Button
var _act_cb: Callable
# คลิปบอร์ด
var sheet: PanelContainer
var sheet_open := false
var pad_head: Label
var pad_rows: VBoxContainer
var pad_ask: Label
var pad_actions: HFlowContainer
var pad_total: Label
var replay_btn: Button
var rows_state := {}
var seq_tw: Tween
var pause_layer: Control


func build_base(kind: String = "room") -> void:
	stage = Stage.new(kind)
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stage)
	_build_hud()
	_build_sheet()
	_build_dialog()
	_build_action()


# ============================================================
# HUD
# ============================================================
func _build_hud() -> void:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_TOP_WIDE)
	for s in ["left", "right", "top"]:
		m.add_theme_constant_override("margin_" + s, 12)
	add_child(m)
	var h := UI.hbox(10)
	m.add_child(h)
	var who := UI.frame("dialog", 10)
	var wh := UI.hbox(10)
	who.add_child(wh)
	wh.add_child(UI.pix(Px.portrait(G.scn().sex, "normal"), 1.2))
	var wv := UI.vbox(-4)
	hud_title = UI.title("", 19, Color.WHITE)
	hud_sub = UI.label(G.run_tag(), 11, Color("a9c6e3"), true)
	wv.add_child(hud_title)
	wv.add_child(hud_sub)
	wh.add_child(wv)
	h.add_child(who)
	h.add_child(UI.spacer())
	var dp := UI.frame("dialog", 8)
	dp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dots = UI.hbox(4)
	dp.add_child(dots)
	h.add_child(dp)
	var sc := UI.frame("slot_on", 10)
	sc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sh := UI.hbox(6)
	sh.add_child(UI.pix(Px.sparkle(1), 3))
	score_chip = UI.head("0", 18, UI.INK)
	sh.add_child(score_chip)
	sc.add_child(sh)
	h.add_child(sc)
	var bv := UI.hbox(6)
	bv.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sheet_btn = UI.btn("📋 ใบคะแนน", func(): pad_open(not sheet_open), "", 13)
	sheet_btn.tooltip_text = "เปิด/ปิดใบบันทึกคะแนน (Tab)"
	rubric_btn = UI.btn("📖 เกณฑ์", _on_rubric, "", 13)
	var menu := UI.btn("☰", _pause, "", 13)
	bv.add_child(sheet_btn)
	bv.add_child(rubric_btn)
	bv.add_child(menu)
	h.add_child(bv)


func set_title(t: String, sub: String = "") -> void:
	hud_title.text = t
	hud_title.tooltip_text = sub
	_title_card(t, sub)

func _title_card(t: String, sub: String) -> void:
	var card := UI.vbox(2)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.title(t, 44, UI.GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(l)
	if sub != "":
		var s := UI.title(sub, 18, Color.WHITE)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(s)
	add_child(card)
	card.reset_size.call_deferred()
	card.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.05)
	tw.tween_callback(func():
		card.position = Vector2((size.x - card.size.x) * 0.5, size.y * 0.3)
		S.play("whoosh"))
	tw.tween_property(card, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(card, "position:y", size.y * 0.26, 0.35).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(1.1)
	tw.tween_property(card, "modulate:a", 0.0, 0.3)
	tw.tween_callback(card.queue_free)


func set_dots(list: Array) -> void:
	UI.clear(dots)
	for d in list:
		var kind := "slot"
		var fg := Color("a9c6e3")
		if d.state == "done":
			kind = "btn_green"; fg = Color.WHITE
		elif d.state == "now":
			kind = "slot_on"; fg = UI.INK
		var c := UI.frame(kind, 5)
		c.custom_minimum_size = Vector2(30, 0)
		var l := UI.label(str(d.t), 12, fg, true)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(l)
		c.tooltip_text = d.get("tip", "")
		dots.add_child(c)

func run_dots() -> void:
	var list := []
	for i in G.run.queue.size():
		var id: String = G.run.queue[i]
		list.append({"t": D.part_of(id).n, "tip": D.part_of(id).title,
			"state": "done" if G.run.results.has(id) else ("now" if i == G.run.i else "")})
	set_dots(list)


# ============================================================
# กล่องบทสนทนา
# ============================================================
func _build_dialog() -> void:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	m.grow_vertical = Control.GROW_DIRECTION_BEGIN
	m.offset_top = -212
	for s in ["left", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 14)
	add_child(m)
	dlg = UI.frame("dialog", 18)
	dlg.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			skip_typing())
	m.add_child(dlg)
	var h := UI.hbox(16)
	dlg.add_child(h)
	dlg_port_box = UI.vbox(2)
	var pf := UI.frame("slot", 6)
	dlg_portrait = UI.pix(Px.portrait("nurse"), 3.0)
	pf.add_child(dlg_portrait)
	dlg_port_box.add_child(pf)
	h.add_child(dlg_port_box)
	var v := UI.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlg_name = UI.title("", 18, UI.GOLD)
	v.add_child(dlg_name)
	dlg_text = UI.rich("", 19, UI.DIALOG_TEXT)
	dlg_text.add_theme_color_override("font_outline_color", Color("0b1626"))
	dlg_text.add_theme_constant_override("outline_size", 3)
	dlg_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(dlg_text)
	dlg_choices = GridContainer.new()
	dlg_choices.add_theme_constant_override("h_separation", 8)
	dlg_choices.add_theme_constant_override("v_separation", 0)
	v.add_child(dlg_choices)
	h.add_child(v)
	dlg_next = UI.label("▼", 16, UI.GOLD, true)
	dlg_next.size_flags_vertical = Control.SIZE_SHRINK_END
	dlg_next.visible = false
	h.add_child(dlg_next)
	var bl := dlg_next.create_tween().set_loops()
	bl.tween_property(dlg_next, "modulate:a", 0.2, 0.4)
	bl.tween_property(dlg_next, "modulate:a", 1.0, 0.4)


## who: "nurse" · "patient" · "narr" (คำบรรยาย ไม่มีภาพหน้า)
func speak(who: String, text: String, expr: String = "talk") -> void:
	hide_choices()
	_type_who = who
	match who:
		"nurse":
			dlg_port_box.visible = true
			dlg_portrait.texture = Px.portrait("nurse", expr)
			dlg_name.text = "นักศึกษาพยาบาล (คุณ)"
			dlg_name.add_theme_color_override("font_color", Color("9fd3ff"))
			stage.say(text, "nurse")
		"patient":
			dlg_port_box.visible = true
			dlg_portrait.texture = Px.portrait(G.scn().sex, expr)
			dlg_name.text = G.scn().name
			dlg_name.add_theme_color_override("font_color", UI.GOLD)
			stage.say(text, "patient")
		_:
			dlg_port_box.visible = false
			dlg_name.text = ""
	dlg_text.text = text if who != "narr" else "[color=#bcd6ee]" + text + "[/color]"
	dlg_text.visible_ratio = 0.0
	_type_last = 0
	if type_tw:
		type_tw.kill()
	var n := dlg_text.get_total_character_count()
	var dur := clampf(n * 0.028, 0.15, 1.6)
	type_tw = create_tween()
	type_tw.tween_method(_type_step, 0.0, 1.0, dur)
	type_tw.tween_callback(_typed_done)

func _type_step(v: float) -> void:
	dlg_text.visible_ratio = v
	var c := dlg_text.visible_characters
	if c - _type_last >= 3:
		_type_last = c
		S.play("blip2" if _type_who == "patient" else "blip", 0.9 + randf() * 0.2)

func _typed_done() -> void:
	dlg_text.visible_ratio = 1.0
	if _type_who == "nurse":
		dlg_portrait.texture = Px.portrait("nurse", "normal")
	elif _type_who == "patient":
		var ex := "normal"
		if stage.pt_eyes == "closed":
			ex = "closed"
		dlg_portrait.texture = Px.portrait(G.scn().sex, ex)
	typed.emit()

func skip_typing() -> void:
	if type_tw and type_tw.is_running():
		type_tw.kill()
		_typed_done()

func patient_face(expr: String) -> void:
	if _type_who == "patient":
		dlg_portrait.texture = Px.portrait(G.scn().sex, expr)


## เมนูตัวเลือกคำพูด (กดเลข 1–9 ได้)
func choices(prompt: String, items: Array, cb: Callable) -> void:
	speak("narr", prompt)
	dlg_port_box.visible = true
	dlg_portrait.texture = Px.portrait("nurse", "normal")
	dlg_name.text = "เลือกสิ่งที่จะพูด / ทำ"
	dlg_name.add_theme_color_override("font_color", Color("9fd3ff"))
	UI.clear(dlg_choices)
	_choice_btns.clear()
	_choice_cb = cb
	var two: bool = items.size() > 3 and items.all(func(s): return String(s).length() < 40)
	dlg_choices.columns = 2 if two else 1
	for i in items.size():
		var b := UI.btn("%d ▸ %s" % [i + 1, items[i]], func(): _choose(i), "opt", 16)
		b.custom_minimum_size.x = 440 if two else 820
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dlg_choices.add_child(b)
		_choice_btns.append(b)
	dlg_choices.visible = true

func _choose(i: int) -> void:
	if not dlg_choices.visible:
		return
	var cb := _choice_cb
	hide_choices()
	cb.call(i)

func hide_choices() -> void:
	dlg_choices.visible = false
	UI.clear(dlg_choices)
	_choice_btns.clear()


# ============================================================
# ปุ่มการกระทำ
# ============================================================
func _build_action() -> void:
	act_btn = UI.btn("", func():
		var cb := _act_cb
		action_hide()
		if cb.is_valid():
			cb.call(), "primary", 20)
	act_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	act_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	act_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	act_btn.offset_right = -24
	act_btn.offset_bottom = -226
	act_btn.visible = false
	add_child(act_btn)

func action(text: String, cb: Callable, kind: String = "primary") -> void:
	act_btn.text = "  " + text + "  ▶"
	_act_cb = cb
	act_btn.visible = true
	act_btn.reset_size()
	act_btn.offset_left = act_btn.offset_right - act_btn.size.x
	act_btn.offset_top = act_btn.offset_bottom - act_btn.size.y
	act_btn.pivot_offset = act_btn.size * 0.5
	act_btn.scale = Vector2(0.6, 0.6)
	act_btn.create_tween().tween_property(act_btn, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	if kind == "ok":
		UI._btn_style(act_btn, "btn_green", "btn_hover", Color.WHITE, Color.WHITE, 16)
	else:
		UI._btn_style(act_btn, "btn", "btn_hover", Color.WHITE, Color.WHITE, 16)

func action_hide() -> void:
	act_btn.visible = false


# ============================================================
# คลิปบอร์ดใบคะแนน
# ============================================================
func _build_sheet() -> void:
	sheet = UI.frame("wood", 12)
	sheet.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	sheet.offset_left = 0
	sheet.offset_right = 360
	sheet.offset_top = 70
	sheet.offset_bottom = -226
	add_child(sheet)
	var clip := VBoxContainer.new()
	clip.add_theme_constant_override("separation", -6)
	sheet.add_child(clip)
	var ring := UI.label("▬▬", 18, Color("9aa8b4"), true)
	ring.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clip.add_child(ring)
	var paper := UI.frame("paper", 14)
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip.add_child(paper)
	var pv := UI.vbox(6)
	paper.add_child(UI.scroll(pv))
	var th := UI.hbox(6)
	th.add_child(UI.head("ใบบันทึกคะแนน MMSE", 17, UI.PAPER_INK))
	th.add_child(UI.spacer())
	th.add_child(UI.btn("✕", func(): pad_open(false), "", 11))
	pv.add_child(th)
	pad_head = UI.label("", 11, Color("7a6656"), true)
	pv.add_child(pad_head)
	pad_ask = UI.wrap(UI.label("", 14, UI.PAPER_INK, true))
	pv.add_child(pad_ask)
	pad_actions = UI.flow(6)
	pv.add_child(pad_actions)
	pad_rows = UI.vbox(4)
	pv.add_child(pad_rows)
	replay_btn = UI.btn("⟲ ดูซ้ำอีกครั้ง", _on_replay, "", 12)
	replay_btn.visible = false
	pv.add_child(replay_btn)
	pad_total = UI.title("0 / 0", 26, UI.GOLD, Color("3b2414"))
	pad_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pv.add_child(pad_total)

func pad_open(on: bool) -> void:
	sheet_open = on
	var w := 360.0
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sheet, "offset_left", -w - 12 if on else 0.0, 0.25)
	tw.parallel().tween_property(sheet, "offset_right", -12.0 if on else w, 0.25)
	S.play("open" if on else "whoosh")

func pad_clear() -> void:
	UI.clear(pad_rows)
	rows_state.clear()

func pad_row(key: String, text: String) -> void:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_font_override("font", UI.font_body)
	b.focus_mode = Control.FOCUS_NONE
	rows_state[key] = {"btn": b, "text": text, "on": false, "tickable": false, "scored": false, "value": -1, "active": false}
	b.pressed.connect(func():
		var s: Dictionary = rows_state[key]
		if s.tickable:
			s.on = not s.on
			S.play("select" if s.on else "click")
			S.play("click", 1.4 if s.on else 0.8)
			_row_style(key)
			on_row_toggled())
	pad_rows.add_child(b)
	_row_style(key)

func _row_style(key: String) -> void:
	var s: Dictionary = rows_state[key]
	var b: Button = s.btn
	var mark := "□"
	var bg := Color(1, 1, 1, 0.0)
	var border := Color("e2d3bd")
	if s.scored:
		mark = "①" if s.value == 1 else "⓪"
		bg = Color("e3f3e8") if s.value else Color("f6e6da")
	elif s.tickable:
		mark = "☑" if s.on else "☐"
		bg = Color("d8f0df") if s.on else Color.WHITE
		border = UI.OK if s.on else Color("b39a82")
	elif s.active:
		bg = Color("fff4d6")
		border = UI.WARN
	b.text = "%s  %s" % [mark, s.text]
	b.add_theme_stylebox_override("normal", UI.box(bg, border, 2, 8))
	b.add_theme_stylebox_override("hover", UI.box(bg.lightened(0.3) if s.tickable else bg, UI.BRAND if s.tickable else border, 2, 8))
	b.add_theme_stylebox_override("pressed", UI.box(bg, border, 2, 8))
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, UI.PAPER_INK)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if s.tickable else Control.CURSOR_ARROW

func pad_set(key: String, field: String, v) -> void:
	rows_state[key][field] = v
	_row_style(key)

func ticked_count() -> int:
	var n := 0
	for k in rows_state:
		var s: Dictionary = rows_state[k]
		if (s.tickable and s.on) or (s.scored and s.value == 1):
			n += 1
	return n

func on_row_toggled() -> void:
	pass

## ตราประทับตอนบันทึกคะแนน
func stamp() -> void:
	S.play("stamp")
	var l := UI.title("บันทึกแล้ว", 30, Color("d8453b"), Color.WHITE)
	l.rotation = -0.2
	sheet.add_child(l)
	l.position = Vector2(80, 140)
	l.scale = Vector2(1.8, 1.8)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.12)
	tw.tween_interval(0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


# ============================================================
# ลำดับบทสนทนา — พยาบาลพูด → ผู้ป่วยตอบ
# ============================================================
func run_seq(steps: Array, gap: float, done: Callable) -> void:
	if seq_tw:
		seq_tw.kill()
	var slow := G.slow()
	seq_tw = create_tween()
	seq_tw.tween_interval(0.2)
	for st in steps:
		var step: Dictionary = st
		seq_tw.tween_callback(func():
			var q: String = step.get("q", "")
			if q.begins_with("“"):
				speak("nurse", q)
				stage.show_flag("")
			else:
				stage.show_flag(q)
			fx(step.get("fx_before", "")))
		seq_tw.tween_interval(0.9 + 0.4 * slow)
		seq_tw.tween_callback(func():
			if step.has("a"):
				var who: String = step.get("who", "")
				if who != "":
					speak("narr", who + " …")
					stage.say("…", "patient")
				else:
					speak("patient", step.a)
			fx(step.get("fx_after", "")))
		seq_tw.tween_interval(maxf(gap - 0.8, 1.0) * (0.5 + slow * 0.5))
	seq_tw.tween_callback(func():
		stage.show_flag("")
		done.call())

func fx(name: String) -> void:
	match name:
		"think":
			stage.set_think(true)
			stage.set_patient("think")
		"unthink":
			stage.set_think(false)
			stage.set_patient("rest")

func stop_seq() -> void:
	if seq_tw:
		seq_tw.kill()


# ============================================================
# เมนูหยุดเกม + คีย์ลัด
# ============================================================
func _pause() -> void:
	if pause_layer:
		return
	pause_layer = ColorRect.new()
	pause_layer.color = Color(0.03, 0.06, 0.12, 0.7)
	pause_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pause_layer)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(c)
	var p := UI.frame("dialog", 26)
	c.add_child(p)
	var v := UI.vbox(12)
	p.add_child(v)
	var t := UI.title("หยุดเกมชั่วคราว", 32, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(UI.btn("▶ เล่นต่อ", func():
		pause_layer.queue_free()
		pause_layer = null
		get_tree().paused = false, "primary", 18))
	v.add_child(UI.btn("กลับเมนูเกม (ออกจากรอบนี้)", func():
		get_tree().paused = false
		G.goto("lobby"), "", 16))
	S.play("open")

func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	var k: int = e.keycode
	if k == KEY_TAB:
		pad_open(not sheet_open)
	elif k >= KEY_1 and k <= KEY_9 and dlg_choices.visible:
		var i := k - KEY_1
		if i < _choice_btns.size():
			_choice_btns[i].pressed.emit()
	elif (k == KEY_SPACE or k == KEY_ENTER) and act_btn.visible:
		act_btn.pressed.emit()
	elif k == KEY_ESCAPE:
		_pause()


# ---------- ให้ลูกคลาสเขียนทับ ----------
func _on_replay() -> void:
	pass

func _on_rubric() -> void:
	pass
