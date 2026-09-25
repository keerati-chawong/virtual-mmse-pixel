extends Control
## ตัวคุมหน้าจอหลัก: สลับหน้าจอพร้อม fade · toast · popup

const SCREENS := {
	"home": "res://scripts/screens/home.gd",
	"auth": "res://scripts/screens/auth.gd",
	"lobby": "res://scripts/screens/lobby.gd",
	"brief": "res://scripts/screens/brief.gd",
	"walk": "res://scripts/screens/walk.gd",
	"time": "res://scripts/screens/sim_time.gd",
	"cmd": "res://scripts/screens/sim_cmd.gd",
	"part": "res://scripts/screens/sim_part.gd",
	"interpret": "res://scripts/screens/interpret.gd",
	"result": "res://scripts/screens/result.gd",
}
const GAME_SCREENS := ["walk", "time", "cmd", "part"]

var content: Control
var current: Control
var current_name := ""
var who_box: HBoxContainer
var fader: ColorRect
var toast_panel: PanelContainer
var toast_label: Label
var toast_tw: Tween
var pop_back: ColorRect
var pop_title: Label
var pop_body: RichTextLabel
var pop_extra: VBoxContainer


func _ready() -> void:
	theme = UI.make_theme()
	G.main = self
	var bg := ColorRect.new()
	bg.color = UI.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	content = Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(content)

	who_box = UI.hbox(6)
	who_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	who_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	who_box.offset_right = -14
	who_box.offset_top = 12
	add_child(who_box)

	fader = ColorRect.new()
	fader.color = Color("0b1626")
	fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fader.modulate.a = 0.0
	add_child(fader)

	_build_toast()
	_build_pop()
	G.navigate.connect(_go)
	G.toast.connect(_toast)
	G.user_changed.connect(_render_who)
	_show("home", {})
	_maybe_shots.call_deferred()


func _render_who() -> void:
	UI.clear(who_box)
	var u := G.current_user()
	who_box.visible = u != "" and current_name == "lobby"
	if u == "":
		return
	var chip := UI.frame("dialog", 8)
	chip.add_child(UI.label("👤 " + u, 12, Color("cfe3f7"), true))
	who_box.add_child(chip)
	who_box.add_child(UI.btn("ออกจากระบบ", func():
		G.set_user("")
		G.say("ออกจากระบบแล้ว")
		G.goto("home"), "", 12))


func _go(screen: String, args: Dictionary) -> void:
	if (screen == "lobby" or screen == "brief") and G.current_user() == "":
		G.after_login = screen
		_toast("เข้าสู่ระบบหรือสมัครสมาชิกก่อนเริ่มเล่น")
		screen = "auth"
	close_pop()
	fader.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(fader, "modulate:a", 1.0, 0.16)
	tw.tween_callback(func(): _show(screen, args))
	tw.tween_property(fader, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func(): fader.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _show(screen: String, args: Dictionary) -> void:
	if current:
		current.queue_free()
	var s: Control = load(SCREENS[screen]).new()
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	if s.has_method("setup"):
		s.setup(args)
	current = s
	current_name = screen
	content.add_child(s)
	_render_who()


# ---------- toast ----------
func _build_toast() -> void:
	toast_panel = UI.frame("dialog", 14)
	toast_label = UI.label("", 16, Color.WHITE, true)
	toast_panel.add_child(toast_label)
	toast_panel.visible = false
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_panel)

func _toast(msg: String) -> void:
	toast_label.text = "💬 " + msg
	toast_panel.visible = true
	toast_panel.reset_size()
	toast_panel.position = Vector2((size.x - toast_panel.size.x) * 0.5, 90)
	toast_panel.modulate.a = 1.0
	S.play("blip2")
	if toast_tw:
		toast_tw.kill()
	toast_tw = create_tween()
	toast_tw.tween_interval(2.6)
	toast_tw.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	toast_tw.tween_callback(func(): toast_panel.visible = false)


# ---------- popup ----------
func _build_pop() -> void:
	pop_back = ColorRect.new()
	pop_back.color = Color(0.03, 0.06, 0.12, 0.62)
	pop_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop_back.visible = false
	pop_back.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			close_pop())
	add_child(pop_back)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_back.add_child(center)
	var p := UI.frame("panel", 22)
	p.custom_minimum_size = Vector2(640, 0)
	center.add_child(p)
	var v := UI.vbox(10)
	p.add_child(v)
	var top := UI.hbox()
	pop_title = UI.title("", 22, UI.GOLD)
	pop_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(pop_title)
	top.add_child(UI.btn("✕", close_pop, "", 14))
	v.add_child(top)
	pop_extra = UI.vbox(8)
	v.add_child(pop_extra)
	pop_body = UI.rich("", 16)
	pop_body.custom_minimum_size.x = 600
	v.add_child(pop_body)

func open_pop(title: String, bb: String, extra: Control = null) -> void:
	pop_title.text = title
	pop_body.text = bb
	pop_body.visible = bb != ""
	UI.clear(pop_extra)
	if extra:
		pop_extra.add_child(extra)
	pop_back.visible = true
	move_child(pop_back, get_child_count() - 1)
	move_child(toast_panel, get_child_count() - 1)
	move_child(fader, get_child_count() - 1)
	S.play("open")

func close_pop() -> void:
	if pop_back and pop_back.visible:
		pop_back.visible = false

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") and pop_back.visible:
		close_pop()
		get_viewport().set_input_as_handled()


# ---------- โหมดถ่ายภาพหน้าจอสำหรับตรวจงาน: godot --path . -- --shots <dir> ----------
func _maybe_shots() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shots")
	if i < 0:
		return
	var dir: String = args[i + 1] if i + 1 < args.size() else "user://shots"
	var tester = load("res://tools/shots.gd").new()
	add_child(tester)
	tester.run(self, dir)
