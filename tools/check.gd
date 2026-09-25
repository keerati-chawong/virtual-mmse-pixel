extends SceneTree
## ตรวจว่าสคริปต์ทุกไฟล์ compile ผ่าน: godot --headless --path . --script res://tools/check.gd

func _init() -> void:
	var bad := 0
	for f in _files("res://scripts"):
		var s = load(f)
		if s == null or not (s is GDScript) or not s.can_instantiate():
			print("FAIL ", f)
			bad += 1
	print("CHECK DONE bad=", bad)
	quit()

func _files(d: String) -> Array:
	var out := []
	var da := DirAccess.open(d)
	for f in da.get_files():
		if f.ends_with(".gd"):
			out.append(d.path_join(f))
	for sub in da.get_directories():
		out.append_array(_files(d.path_join(sub)))
	return out
