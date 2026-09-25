extends Node
## เล่นอัตโนมัติทั้งรอบ + ถ่ายภาพหน้าจอ (ใช้ตรวจงาน): godot --path . -- --shots <dir> [--s2]

var main: Node
var dir := ""
var n := 0


func run(m: Node, d: String) -> void:
	main = m
	dir = d
	DirAccess.make_dir_recursive_absolute(dir)
	S.enabled = false
	Engine.time_scale = 3.0
	await _go()
	print("SHOTS DONE ", n)
	get_tree().quit()


func shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	n += 1
	img.save_png(dir.path_join("%02d_%s.png" % [n, name]))
	print("shot ", name)


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func cur() -> Node:
	return main.current


func until(cond: Callable, timeout: float = 30.0) -> void:
	var t := 0.0
	while not cond.call() and t < timeout:
		await get_tree().process_frame
		t += get_process_delta_time()
	if t >= timeout:
		push_error("timeout on " + main.current_name)


func _go() -> void:
	await wait(1.0)
	await shot("title")
	G.register("demo.shots@example.com", "123456", "123456")
	G.login("demo.shots@example.com", "123456")
	G.scenario_key = "s2" if OS.get_cmdline_user_args().has("--s2") else "s1"
	G.goto("lobby")
	await wait(0.6)
	await shot("lobby")
	G.setup = {"ans": {"edu": "yes", "blind": "no", "deaf": "no", "dep": "no", "pedu": "primary"},
		"kit": {"form": true, "a4": true, "watch": true, "card": true, "penta": true, "x_pen": true}}
	G.goto("brief", {"mode": "new"})
	await wait(0.6)
	await shot("brief_chart")
	cur()._next()
	await wait(0.3)
	await shot("brief_table")
	cur()._next()
	await wait(1.3)
	await shot("walk_in")
	await until(func(): return main.current_name == "time")
	await wait(1.4)
	await shot("time_intro")
	var t: Node = cur()
	await until(func(): return t.dlg_choices.visible)
	await wait(0.2)
	await shot("time_menu")
	for item in D.ITEMS:
		t._ask(0, item.id)
		if item.id == "date":
			await wait(0.8)
			await shot("time_answer")
		await until(func(): return t.pad_actions.get_child_count() > 0)
		if item.id == "date":
			await wait(0.4)
			await shot("time_score")
		t._score(1)
		await wait(0.5)
	t._finish()
	var taken := {}
	while true:
		await wait(0.3)
		var nm: String = main.current_name
		if nm == "walk":
			if not taken.has("walk_out"):
				await wait(1.0)
				await shot("walk_out")
				taken.walk_out = true
			await until(func(): return main.current_name == "brief")
			await wait(0.4)
			await shot("brief_resume")
			G.setup.kit.pencil = true
			G.setup.kit.erase("x_pen")
			cur()._next()
			await until(func(): return main.current_name != "brief" and main.current_name != "walk", 30)
			continue
		if nm == "part":
			var p: Node = cur()
			await until(func(): return p.dlg_choices.visible)
			if not taken.has(p.id + "_menu") and p.id == "place":
				await shot("part_place_menu")
			p._pick(0)
			p._play()
			await wait(1.6)
			await shot("part_" + p.id + "_play")
			await until(func():
				if p.id == "calc" and p.dlg_choices.visible and p.phase == "playing":
					p._choice_btns[0].pressed.emit()
				return p.phase == "score", 60)
			await wait(0.5)
			main.close_pop()
			for k in p.rows_state:
				p.rows_state[k].on = randf() < 0.7
				p._row_style(k)
			if p.id in ["place", "calc", "draw"]:
				await shot("part_" + p.id + "_score")
			taken[p.id] = true
			p._save()
			await wait(0.5)
			p._finish()
			continue
		if nm == "cmd":
			var c: Node = cur()
			for i in c.items.size():
				await until(func(): return c.dlg_choices.visible)
				c._pick(0, c.items[i].id)
				c._play()
				await wait(1.8)
				await shot("cmd_" + c.items[i].id + "_play")
				await until(func(): return c.phase == "score", 60)
				c.rows_state.values()[0].on = true
				c._save()
				await wait(0.5)
				if i == c.items.size() - 1:
					c._finish()
				else:
					c._set_item(i + 1)
			continue
		if nm == "interpret":
			await wait(0.4)
			await shot("interpret")
			var ip: Node = cur()
			ip.cut = "primary"
			ip.verdict = "normal"
			ip._confirm()
			await wait(2.0)
			await shot("result")
			return
		if nm == "result":
			await shot("result")
			return
