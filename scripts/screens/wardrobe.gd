extends Control
## ตู้เสื้อผ้า & ร้านค้า — เลือกเพศตัวละคร · ซื้อ/สวม ชุด หมวก รองเท้า เครื่องประดับ ด้วยเหรียญ

var slot := "suit"
var preview_box: VBoxContainer
var grid: GridContainer
var tabs: HBoxContainer
var coin_l: Label


func _ready() -> void:
	add_child(UI.backdrop(0.6))
	var col := UI.vbox(12)
	var m := UI.margin(col, 20)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(m)

	var top := UI.hbox(10)
	top.add_child(UI.btn("◀ เมนูเกม", func(): G.goto("lobby"), "", 13))
	top.add_child(UI.title("ตู้เสื้อผ้า & ร้านค้า", 32, Color.WHITE))
	top.add_child(UI.spacer())
	top.add_child(UI.btn("🏆 Achievement", func(): G.goto("achieve"), "", 14))
	var cf := UI.frame("slot_on", 8)
	coin_l = UI.head("", 20, UI.INK)
	cf.add_child(coin_l)
	top.add_child(cf)
	col.add_child(top)

	var body := UI.hbox(14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	# ---- ตัวอย่างตัวละคร ----
	var left := UI.frame("dialog", 16)
	left.custom_minimum_size.x = 330
	preview_box = UI.vbox(10)
	preview_box.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(preview_box)
	body.add_child(left)

	# ---- ร้าน ----
	var right := UI.frame("dialog", 16)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := UI.vbox(10)
	right.add_child(rv)
	tabs = UI.hbox(8)
	rv.add_child(tabs)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	rv.add_child(UI.scroll(grid))
	rv.add_child(UI.wrap(UI.label("ได้เหรียญจากการเล่น (ดาวที่ได้ · ประเมินครบชุด · ระดับยากได้มากขึ้น) และจากรางวัล Achievement · ของบางชิ้นได้จาก Achievement เท่านั้น", 12, UI.MUTED)))
	body.add_child(right)

	Prof.changed.connect(_render)
	_render()


func _render() -> void:
	if not is_inside_tree():
		return
	coin_l.text = "🪙 %d" % Prof.coins()
	_render_preview()
	_render_tabs()
	_render_grid()


func _render_preview() -> void:
	UI.clear(preview_box)
	var o := Prof.outfit()
	var t := UI.title("ตัวละครของคุณ", 20, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(t)
	var row := UI.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UI.pix(Px.nurse("idle"), 5.0))
	var pf := UI.frame("slot", 6)
	pf.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pf.add_child(UI.pix(Px.portrait("nurse", "smile"), 2.4))
	row.add_child(pf)
	preview_box.add_child(row)
	var sx := UI.hbox(8)
	sx.alignment = BoxContainer.ALIGNMENT_CENTER
	for s in [["f", "👩 ผู้หญิง"], ["m", "👨 ผู้ชาย"]]:
		var k: String = s[0]
		var b := UI.btn(s[1], func():
			Prof.equip("sex", k)
			S.play("ok"), "ok" if o.sex == k else "", 15)
		sx.add_child(b)
	preview_box.add_child(sx)
	var lines := []
	for sl in Prof.SLOTS:
		lines.append("%s: %s" % [sl.t, Prof.item(o.get(sl.k, "")).get("t", "-")])
	var info := UI.wrap(UI.label("\n".join(lines), 13, UI.INK_2))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(info)


func _render_tabs() -> void:
	UI.clear(tabs)
	for sl in Prof.SLOTS:
		var k: String = sl.k
		var b := UI.btn(sl.t, func():
			slot = k
			_render(), "primary" if slot == k else "", 15)
		tabs.add_child(b)


func _render_grid() -> void:
	UI.clear(grid)
	var o := Prof.outfit()
	for it in Prof.items_of(slot):
		var k: String = it.k
		var owned := Prof.owns(k)
		var worn: bool = o.get(slot, "") == k
		var card := UI.frame("slot_on" if worn else "panel", 10)
		card.custom_minimum_size = Vector2(250, 0)
		var v := UI.vbox(4)
		card.add_child(v)
		var h := UI.hbox(10)
		var po: Dictionary = o.duplicate()
		po[slot] = k
		var pf := UI.frame("slot", 4)
		pf.add_child(UI.pix(Px.nurse("idle", false, po), 1.5))
		h.add_child(pf)
		var tv := UI.vbox(2)
		tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tv.add_child(UI.wrap(UI.label(it.t, 15, UI.INK, true)))
		if it.desc != "":
			tv.add_child(UI.wrap(UI.label(it.desc, 12, UI.MUTED)))
		h.add_child(tv)
		v.add_child(h)
		var act: Button
		if worn:
			act = UI.btn("✔ สวมอยู่", Callable(), "ok", 14)
			act.disabled = true
		elif owned:
			act = UI.btn("สวมใส่", func():
				Prof.equip(slot, k)
				S.play("ok"), "primary", 14)
		elif it.get("reward_only", false):
			act = UI.btn("🔒 ได้จาก Achievement", Callable(), "", 13)
			act.disabled = true
		else:
			var price: int = it.price
			act = UI.btn("ซื้อ 🪙 %d" % price, func():
				var err := Prof.buy(k)
				if err != "":
					S.play("error")
					G.say(err)
					return
				S.play("star")
				Prof.equip(slot, k)
				G.say("ซื้อ “%s” แล้ว — สวมให้เลย" % it.t), "warn" if Prof.coins() >= price else "", 14)
		v.add_child(act)
		grid.add_child(card)
