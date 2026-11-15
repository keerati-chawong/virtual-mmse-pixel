extends Control
## หน้ารวม Achievement — ปลดล็อกแล้ว/ยังไม่ปลดล็อก พร้อมรูปและรางวัล
## รูปวาดเอง: วางไฟล์ PNG ที่ res://assets/achievements/<id>.png (ดู id ใน scripts/profile.gd)


func _ready() -> void:
	add_child(UI.backdrop(0.6))
	var col := UI.vbox(12)
	var sc := UI.scroll(UI.margin(col, 20))
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sc)

	var top := UI.hbox(10)
	top.add_child(UI.btn("◀ เมนูเกม", func(): G.goto("lobby"), "", 13))
	top.add_child(UI.title("Achievement", 32, Color.WHITE))
	var got := Prof.ACH.filter(func(a): return Prof.has_ach(a.id)).size()
	top.add_child(UI.title("  %d / %d" % [got, Prof.ACH.size()], 22, UI.GOLD))
	top.add_child(UI.spacer())
	top.add_child(UI.btn("👗 แต่งตัว & ร้านค้า", func(): G.goto("wardrobe"), "", 14))
	var cf := UI.frame("slot_on", 8)
	cf.add_child(UI.head("🪙 %d" % Prof.coins(), 20, UI.INK))
	top.add_child(cf)
	col.add_child(top)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	col.add_child(grid)
	for a in Prof.ACH:
		grid.add_child(_card(a))


func _card(a: Dictionary) -> Control:
	var on := Prof.has_ach(a.id)
	var card := UI.frame("slot_on" if on else "dialog", 12)
	card.custom_minimum_size = Vector2(390, 128)
	var h := UI.hbox(12)
	card.add_child(h)
	h.add_child(UI.ach_icon(a, on, 3.0))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.wrap(UI.label(a.t if on else "🔒 " + a.t, 16, UI.INK, true)))
	v.add_child(UI.wrap(UI.label(a.desc, 13, UI.INK_2)))
	v.add_child(UI.wrap(UI.label("รางวัล: " + Prof.reward_text(a), 13, UI.OK if on else UI.MUTED, true)))
	if on:
		v.add_child(UI.label("ปลดล็อกเมื่อ " + str(Prof.data.ach[a.id]), 11, UI.MUTED))
	h.add_child(v)
	return card
