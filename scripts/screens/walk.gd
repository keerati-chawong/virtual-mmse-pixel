extends Control
## ฉากเดินไปหยิบอุปกรณ์ — เข้าห้องตรวจ (in) / เดินออกมาหยิบของเพิ่ม (out)

var args := {}
var stage: Stage
var tray_box: BoxContainer
var seq: Tween
var walk_tw: Tween
var done_called := false
var hold: PanelContainer
var hold_text: RichTextLabel


func setup(a: Dictionary) -> void:
	args = a


func _ready() -> void:
	var out: bool = args.get("mode", "in") == "out"
	stage = Stage.new("corridor")
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stage)

	var top := UI.hbox(10)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 14
	top.offset_right = -14
	top.offset_top = 12
	var tf := UI.frame("dialog", 10)
	var title := "เดินไปหยิบอุปกรณ์เพิ่ม" if out else ("กลับเข้าห้องตรวจ" if args.get("resume", false) else "เข้าห้องตรวจ")
	tf.add_child(UI.title("🚪 " + title, 20, Color.WHITE))
	top.add_child(tf)
	top.add_child(UI.spacer())
	var skip := UI.btn("ข้าม ▶▶", _finish, "", 14)
	skip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(skip)
	add_child(top)

	var bottom := UI.hbox(12)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 14
	bottom.offset_right = -14
	bottom.offset_top = -176
	bottom.offset_bottom = -14
	add_child(bottom)
	var tp := UI.frame("dialog", 12)
	var tv := UI.vbox(4)
	tp.add_child(tv)
	tv.add_child(UI.title("ถาดที่ถือไป", 16, UI.GOLD))
	tray_box = UI.hbox(6)
	tv.add_child(tray_box)
	bottom.add_child(tp)
	var np := UI.frame("dialog", 14)
	np.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	np.add_child(UI.rich(_note(), 15, UI.DIALOG_TEXT))
	bottom.add_child(np)

	hold = UI.frame("slot_on", 12)
	hold_text = UI.rich("", 15)
	hold_text.custom_minimum_size.x = 300
	hold.add_child(hold_text)
	hold.visible = false
	stage.overlay.add_child(hold)

	_play.call_deferred()


func _note() -> String:
	if args.get("mode", "in") == "in":
		var n := "[b]หยิบของเพิ่มแล้ว กลับเข้าห้องตรวจ[/b]\nตรวจถาดอีกครั้งก่อนเข้าไป จะได้ไม่ต้องเดินออกมาอีก" if args.get("resume", false) \
			else "[b]ก่อนเข้าห้องตรวจ[/b]\nตรวจของในถาดให้ครบตามที่แบบประเมินกำหนด 6 ชิ้น"
		var miss := G.missing_kit()
		if miss.size():
			n += "\n[color=#ff9a8a]ยังขาด %d ชิ้น — %s พอถึงข้อที่ต้องใช้จะต้องเดินออกมาหยิบ[/color]" % [miss.size(), " · ".join(miss.map(func(k): return D.kit_name(k)))]
		var extra := G.wrong_kit()
		if extra.size():
			n += "\n[color=#ff9a8a]หยิบเกินมา: %s — ไม่ได้อยู่ในรายการอุปกรณ์[/color]" % " · ".join(extra.map(func(e): return e.t))
		return n
	var part: Dictionary = args.part
	var prob: Dictionary = args.prob
	if prob.wrong.size():
		var w: Dictionary = prob.wrong[0]
		return "[b]ข้อ %d %s — หยิบของมาผิดชิ้น[/b]\nข้อนี้ต้องใช้ [b]%s[/b] แต่ที่ติดมือมาคือ [color=#ff9a8a]%s[/color]\n%s — ใช้แทนกันไม่ได้ ต้องเดินกลับไปหยิบของที่ถูกต้อง" % [
			part.n, part.title, D.kit_name(w.need), D.kit_name(w.got), D.kit_item(w.got).why]
	return "[b]ข้อ %d %s — ไม่มีอุปกรณ์ติดมือมา[/b]\nข้อนี้ต้องใช้ [color=#ff9a8a]%s[/color]\nในถาดไม่มีของชิ้นนี้เลย ต้องเดินออกจากห้องตรวจไปหยิบที่โต๊ะเตรียมอุปกรณ์" % [
		part.n, part.title, " · ".join(prob.missing.map(func(k): return D.kit_name(k)))]


func _tray(reveal: bool) -> void:
	UI.clear(tray_box)
	var rows := []
	for k in D.KIT_NEED:
		var ok: bool = G.setup.kit.get(k, false)
		rows.append(["✓ " if ok else "! ", D.kit_name(k) + ("" if ok else " — ยังไม่ได้หยิบมา"), UI.OK if ok else UI.WARN, k])
	for it in D.KIT:
		if not it.ok and G.setup.kit.get(it.k, false):
			rows.append(["✕ ", it.t + " — " + it.why, Color("c0392b"), it.k])
	var i := 0
	for r in rows:
		var kind := "slot_on" if r[0] == "✓ " else ("btn_orange" if r[0] == "✕ " else "slot")
		var h := UI.frame(kind, 4)
		h.custom_minimum_size = Vector2(56, 56)
		var ic := UI.pix(Px.kit_icon(r[3]), 3.0)
		if r[0] == "! ":
			ic.modulate = Color(1, 1, 1, 0.25)
		h.add_child(ic)
		h.tooltip_text = r[1]
		tray_box.add_child(h)
		if reveal:
			h.modulate.a = 0.0
			create_tween().tween_property(h, "modulate:a", 1.0, 0.2).set_delay(0.19 * i)
		i += 1


func _walking(on: bool) -> void:
	if walk_tw:
		walk_tw.kill()
	if not on:
		stage.set_nurse("tray" if args.get("mode") == "in" else "idle")
		return
	walk_tw = create_tween().set_loops()
	walk_tw.tween_callback(func(): stage.set_nurse("walk1"))
	walk_tw.tween_interval(0.18)
	walk_tw.tween_callback(func(): stage.set_nurse("walk2"))
	walk_tw.tween_interval(0.18)


func _play() -> void:
	var n := stage.nurse
	seq = create_tween()
	if args.get("mode", "in") == "in":
		_tray(true)
		n.position = Vector2(80, 96)
		stage.show_flag("จัดอุปกรณ์ใส่ถาด")
		seq.tween_interval(1.7)
		seq.tween_callback(func():
			stage.show_flag("เดินไปที่ห้องตรวจ")
			_walking(true))
		seq.tween_property(n, "position:x", 246.0, 2.0)
		seq.tween_callback(func():
			stage.props.door.visible = false
			stage.show_flag("เปิดประตูเข้าห้องตรวจ"))
		seq.tween_interval(0.5)
		seq.tween_property(n, "position:x", 262.0, 0.5)
		seq.parallel().tween_property(n, "modulate:a", 0.0, 0.5)
		seq.tween_interval(0.5)
		seq.tween_callback(_finish)
	else:
		_tray(false)
		n.flip_h = true
		n.position = Vector2(262, 96)
		n.modulate.a = 0.0
		stage.props.door.visible = false
		stage.set_nurse("idle")
		stage.show_flag("ออกจากห้องตรวจ")
		seq.tween_property(n, "modulate:a", 1.0, 0.4)
		seq.parallel().tween_property(n, "position:x", 244.0, 0.5)
		seq.tween_callback(func():
			var prob: Dictionary = args.prob
			if prob.wrong.size():
				var w: Dictionary = prob.wrong[0]
				hold_text.text = "[b]นี่ไม่ใช่ %s[/b]\nในถาดมีแต่ %s" % [D.kit_name(w.need), D.kit_name(w.got)]
			else:
				hold_text.text = "[b]ในถาดไม่มี[/b] " + " · ".join(prob.missing.map(func(k): return D.kit_name(k)))
			hold.visible = true
			hold.reset_size()
			hold.position = stage.w2s(Vector2(150, 40)))
		seq.tween_interval(1.7)
		seq.tween_callback(func():
			hold.visible = false
			stage.show_flag("เดินกลับไปที่โต๊ะเตรียมอุปกรณ์")
			_walking(true))
		seq.tween_property(n, "position:x", 80.0, 2.2)
		seq.parallel().tween_callback(func(): stage.props.door.visible = true).set_delay(0.6)
		seq.tween_callback(func():
			_walking(false)
			stage.show_flag("ถึงโต๊ะเตรียมอุปกรณ์แล้ว"))
		seq.tween_interval(0.7)
		seq.tween_callback(_finish)


func _finish() -> void:
	if done_called:
		return
	done_called = true
	if seq:
		seq.kill()
	if walk_tw:
		walk_tw.kill()
	if args.get("mode", "in") == "in":
		if args.get("resume", false):
			G.route_part(G.run.queue[G.run.i])
		else:
			G.start_full_run()
	else:
		var part: Dictionary = args.part
		var prob: Dictionary = args.prob
		var t := "[b]ข้อ %d %s %s[/b]\n" % [part.n, part.title, "ใช้อุปกรณ์ที่หยิบมาไม่ได้" if prob.wrong.size() else "ต้องใช้อุปกรณ์ที่ยังไม่ได้หยิบมา"]
		if prob.wrong.size():
			t += "ต้องใช้ %s — ที่หยิบมาคือ %s ซึ่งใช้แทนกันไม่ได้\n" % [D.kit_name(prob.wrong[0].need), D.kit_name(prob.wrong[0].got)]
		t += "ยังขาด: %s\nหยิบให้ครบบนโต๊ะ (คลิกของที่ไม่ใช่เพื่อเอาออกได้ด้วย) แล้วกด “กลับไปประเมินต่อ”" % " · ".join(prob.missing.map(func(k): return D.kit_name(k)))
		G.goto("brief", {"mode": "resume", "note": t})
