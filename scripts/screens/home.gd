extends Control
## หน้า Title — ฉากหน้าโรงพยาบาล pixel · โลโก้ · เมนูหลัก

var walker: TextureRect
var walk_frame := 0
var press: Label


func _ready() -> void:
	add_child(UI.backdrop(0.05))

	# พยาบาลเดินผ่านหน้าโรงพยาบาล
	walker = UI.pix(Px.nurse("walk1"), 4.0)
	walker.size = walker.custom_minimum_size
	add_child(walker)
	var wt := create_tween().set_loops()
	wt.tween_property(walker, "position:x", 1400.0, 14.0).from(-160.0)
	var ft := create_tween().set_loops()
	ft.tween_callback(func():
		walk_frame = 1 - walk_frame
		walker.texture = Px.nurse("walk1" if walk_frame == 0 else "walk2"))
	ft.tween_interval(0.22)
	var place := func(): walker.position.y = size.y - walker.size.y - 150
	resized.connect(place)
	place.call_deferred()

	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var v := UI.vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var top := UI.hbox(18)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	var logo := UI.pix(Px.logo_pixel(40), 3.0)
	top.add_child(logo)
	var tv := UI.vbox(-12)
	tv.add_child(UI.title("Virtual MMSE", 64, Color.WHITE))
	tv.add_child(UI.title("SIMULATION", 40, UI.GOLD))
	top.add_child(tv)
	v.add_child(top)
	var sub := UI.title("เกมฝึกประเมินภาวะสมองเสื่อม สำหรับนักศึกษาพยาบาล", 18, Color("e9f4ff"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size.y = 16
	v.add_child(gap)

	var menu := UI.frame("dialog", 20)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var mv := UI.vbox(8)
	menu.add_child(mv)
	var start := UI.btn("▶   เริ่มเกม", func(): G.goto("lobby"), "primary", 22)
	start.custom_minimum_size = Vector2(380, 0)
	mv.add_child(start)
	var mh := UI.hbox(8)
	var wb := UI.btn("👗  แต่งตัว & ร้านค้า", func(): G.goto("wardrobe"), "", 16)
	wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mh.add_child(wb)
	var ab := UI.btn("🏆  Achievement", func(): G.goto("achieve"), "", 16)
	ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mh.add_child(ab)
	mv.add_child(mh)
	mv.add_child(UI.btn("🎮  มินิเกม · ฝึกทักษะ MMSE ได้เหรียญ", func(): G.goto("minigame"), "warn", 16))
	mv.add_child(UI.btn("🎓  ชุดนักศึกษาพยาบาล & โลโก้คณะ", _gallery, "", 16))
	mv.add_child(UI.btn("📜  มีอะไรใหม่ · อัปเดต 15-11-2569", _notes, "", 16))
	mv.add_child(UI.btn("📚  Pre-Test · คู่มือ · Post-Test", func(): G.say("ส่วนนี้ยังไม่อยู่ในเดโม — เดโมนี้คือเกมประเมิน MMSE ครบทั้ง 11 ข้อ"), "", 16))
	v.add_child(menu)
	press = UI.title("กด Enter เพื่อเริ่ม", 16, Color.WHITE)
	press.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(press)
	var pt := create_tween().set_loops()
	pt.tween_property(press, "modulate:a", 0.15, 0.6)
	pt.tween_property(press, "modulate:a", 1.0, 0.6)

	var foot := UI.label("© Faculty of Nursing, Khon Kaen University · Pixel edition (Godot) · ฟอนต์ SIL OFL", 12, Color("e9f4ff"))
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.offset_left = 14
	foot.offset_top = -26
	foot.add_theme_constant_override("outline_size", 3)
	foot.add_theme_color_override("font_outline_color", UI.INK)
	add_child(foot)


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and (e.keycode == KEY_ENTER or e.keycode == KEY_SPACE):
		S.play("ok")
		G.goto("lobby")


func _gallery() -> void:
	var v := UI.vbox(10)
	var row := UI.hbox(18)
	for pose in ["idle", "walk1", "offer", "tray", "clip"]:
		var f := UI.frame("slot", 6)
		f.add_child(UI.pix(Px.nurse(pose, false, Prof.DEFAULT_OUTFIT), 3.0))
		row.add_child(f)
	v.add_child(row)
	var r2 := UI.hbox(16)
	var pf := UI.frame("slot", 6)
	pf.add_child(UI.pix(Px.portrait("head", "smile"), 3.0))
	r2.add_child(pf)
	r2.add_child(UI.pix(Px.logo_pixel(40), 3.0))
	r2.add_child(UI.pix(Px.logo_tex(), 0.2))
	v.add_child(r2)
	G.pop("ชุดนักศึกษาพยาบาลใหม่", "ชุดกระโปรงสีขาว [b]ปกป้ายและปลายแขนขลิบสีน้ำเงิน[/b] ติด[b]โลโก้คณะพยาบาลศาสตร์ มหาวิทยาลัยขอนแก่น[/b]ที่อก · [b]หมวกพยาบาลปกติไม่มีขีด[/b] · [b]รองเท้าพยาบาลสีขาว[/b]กับ[b]ถุงเท้าสีขาว[/b]", v)


func _notes() -> void:
	var bb := ""
	bb += "[b]อัปเดต 15-11-2569[/b]\n"
	for n in D.UPDATE_NOTES_NEW:
		bb += "✦ " + n + "\n"
	bb += "\n[b]อัปเดต 25-9-2569[/b]\n"
	for n in D.UPDATE_NOTES:
		bb += "✦ " + n + "\n"
	bb += "✦ ปรับหน้าตาเป็นเกม: ฉากเต็มจอ กล่องบทสนทนาแบบ RPG เลือกคำพูดเป็นเมนู ใบคะแนนแบบคลิปบอร์ด เสียงเอฟเฟกต์ และดาวรางวัล"
	G.pop("มีอะไรใหม่", bb)
