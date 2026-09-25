extends Control
## แปลผลคะแนนตามระดับการศึกษาของผู้ป่วย — คั่นก่อนหน้าฟีดแบค

var cut := ""
var verdict := ""
var peeked := false
var cut_box: VBoxContainer
var ver_box: VBoxContainer
var go: Button
var peek_btn: Button
var peek_line: RichTextLabel


func _ready() -> void:
	var t := G.totals()
	add_child(UI.backdrop(0.7))
	var col := UI.vbox(12)
	var sc := UI.scroll(UI.margin(col, 22))
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sc)
	col.add_child(UI.label("ประเมินครบทุกข้อแล้ว · Scenario %d — %s" % [G.scn().no, G.scn().name], 13, Color("cfe3f7"), true))
	col.add_child(UI.title("ด่านสุดท้าย: แปลผลคะแนน", 32, UI.GOLD))
	col.add_child(UI.wrap(UI.label("ถามครบทุกข้อแล้วยังไม่จบ — ผู้ประเมินต้องแปลผลคะแนนตามระดับการศึกษาของผู้ป่วยด้วย", 15, Color.WHITE)))

	var row := UI.hbox(14)
	col.add_child(row)
	var left := UI.panel(UI.SURFACE, UI.INK, 18)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	var lv := UI.vbox(10)
	left.add_child(lv)
	lv.add_child(UI.head("คะแนนที่คุณบันทึกไว้", 18))
	var sh := UI.hbox(10)
	sh.add_child(UI.head(str(t.given), 52, UI.BRAND))
	var mx := UI.label("/ %d คะแนน" % t.max, 18, UI.MUTED)
	mx.size_flags_vertical = Control.SIZE_SHRINK_END
	sh.add_child(mx)
	lv.add_child(sh)
	var parts := UI.flow()
	for id in G.run.queue:
		if G.run.results.has(id):
			var r: Dictionary = G.run.results[id]
			parts.add_child(UI.chip("ข้อ %d · %d/%d" % [D.part_of(id).n, r.given, r.max], UI.SURFACE_2, UI.INK_2, 12))
	lv.add_child(parts)
	lv.add_child(UI.head("1 · เลือกเกณฑ์ที่ใช้แปลผล", 17))
	peek_btn = UI.btn("จำไม่ได้ว่าผู้ป่วยรายนี้เรียนถึงชั้นไหน — เปิดดูข้อมูลจากขั้นตอนคัดกรอง", _peek, "ghost", 12)
	lv.add_child(peek_btn)
	peek_line = UI.rich("", 14)
	peek_line.visible = false
	lv.add_child(peek_line)
	cut_box = UI.vbox(6)
	lv.add_child(cut_box)
	lv.add_child(UI.head("2 · สรุปผลการแปล", 17))
	ver_box = UI.vbox(6)
	lv.add_child(ver_box)
	var bh := UI.hbox(10)
	go = UI.btn("ยืนยันการแปลผล · ดูฟีดแบค", _confirm, "primary", 17)
	bh.add_child(go)
	bh.add_child(UI.btn("ออกจากรอบนี้", func(): G.goto("lobby"), "ghost"))
	lv.add_child(bh)
	row.add_child(left)

	var right := UI.frame("paper", 18)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := UI.vbox(8)
	right.add_child(rv)
	rv.add_child(UI.head("เกณฑ์การแปลผลคะแนน MMSE (ฉบับภาษาไทย)", 16))
	var bb := "[b]จุดตัดตามระดับการศึกษาของผู้ป่วย[/b]\n"
	for c in D.MMSE_CUT:
		bb += "\n• %s — คะแนน [b]≤ %d คะแนน = สงสัยว่ามีภาวะสมองเสื่อม[/b]\n   [color=#5b7085]%s[/color]" % [c.t, c.cut, c.note]
	rv.add_child(UI.rich(bb, 13))
	row.add_child(right)
	_render()


func _peek() -> void:
	peeked = true
	peek_line.text = "จากขั้นตอนคัดกรอง — ระดับการศึกษาของผู้ป่วยรายนี้คือ [b]%s[/b]" % D.cut_of(G.patient_edu()).short
	peek_line.visible = true
	peek_btn.visible = false


func _opt(on: bool, title: String, desc: String, cb: Callable) -> Button:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.text = ("☑  " if on else "☐  ") + title + "\n      " + desc
	b.add_theme_font_size_override("font_size", 14)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UI.tbox("slot_on" if on else "btn_light", 12))
	b.add_theme_stylebox_override("hover", UI.tbox("slot_on", 12))
	b.add_theme_stylebox_override("pressed", UI.tbox("slot_on", 12))
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(c, UI.INK)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func(): S.play("click"))
	b.pressed.connect(cb)
	return b


func _render() -> void:
	UI.clear(cut_box)
	UI.clear(ver_box)
	for c in D.MMSE_CUT:
		var k: String = c.k
		cut_box.add_child(_opt(cut == k, c.t, "จุดตัด ≤ %d คะแนน = สงสัยว่ามีภาวะสมองเสื่อม · %s" % [c.cut, c.note], func():
			cut = k
			_render()))
	for o in [["normal", "ไม่สงสัยภาวะสมองเสื่อม", "คะแนนสูงกว่าจุดตัด — ให้คำแนะนำส่งเสริมสุขภาพสมอง และนัดประเมินซ้ำตามรอบ"],
			["suspect", "สงสัยว่ามีภาวะสมองเสื่อม", "คะแนนเท่ากับหรือต่ำกว่าจุดตัด — ส่งต่อเพื่อประเมินและวินิจฉัยเพิ่มเติม"]]:
		var v: String = o[0]
		ver_box.add_child(_opt(verdict == v, o[1], o[2], func():
			verdict = v
			_render()))
	go.disabled = cut == "" or verdict == ""


func _confirm() -> void:
	if cut == "" or verdict == "":
		return
	G.run.interp = {"cut": cut, "verdict": verdict, "peeked": peeked}
	G.goto("result")
