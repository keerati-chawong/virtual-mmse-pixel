extends SceneTree
## เครื่องมือดูสไปรต์: godot --headless --path . --script res://tools/render_sprites.gd -- <out_dir>

func _init() -> void:
	var out_dir := "user://sprites"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var list := [
		["nurse_idle", Px.nurse("idle").get_image()],
		["nurse_walk1", Px.nurse("walk1").get_image()],
		["nurse_walk2", Px.nurse("walk2").get_image()],
		["nurse_offer", Px.nurse("offer").get_image()],
		["nurse_tray", Px.nurse("tray").get_image()],
		["nurse_clip", Px.nurse("clip").get_image()],
		["pt_m", Px.patient("m").get_image()],
		["pt_m_reach", Px.patient("m", "reach_r", "open", true).get_image()],
		["pt_f", Px.patient("f", "think", "worried").get_image()],
		["pt_f_closed", Px.patient("f", "fingers", "closed").get_image()],
		["logo24", Px.logo_pixel(24).get_image()],
	]
	# แผ่นรวม
	var sheet := Image.create_empty(12 * 40, 70, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("bedee9"))
	var x := 2
	for it in list:
		var img: Image = it[1]
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, 2))
		x += img.get_width() + 4
	sheet.resize(sheet.get_width() * 5, sheet.get_height() * 5, Image.INTERPOLATE_NEAREST)
	sheet.save_png(out_dir.path_join("sheet.png"))
	print("saved ", out_dir)
	quit()
