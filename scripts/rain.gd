extends Node2D
## ฝนตกนอกหน้าต่าง (ฤดูฝน) — วาดเป็นเส้นพิกเซลในกรอบที่กำหนด

var area := Rect2(0, 0, 10, 10)
var drops: Array = []


func _ready() -> void:
	for i in 26:
		drops.append(Vector2(randf() * area.size.x, randf() * area.size.y))


func _process(delta: float) -> void:
	for i in drops.size():
		var d: Vector2 = drops[i]
		d.y += 70.0 * delta
		d.x -= 12.0 * delta
		if d.y > area.size.y:
			d = Vector2(randf() * area.size.x + 4, -3)
		if d.x < 0:
			d.x += area.size.x
		drops[i] = d
	queue_redraw()


func _draw() -> void:
	for d in drops:
		var x := floorf(area.position.x + d.x)
		var y := floorf(area.position.y + d.y)
		if y + 3 <= area.end.y and y >= area.position.y:
			draw_rect(Rect2(x, y, 1, 3), Color(0.9, 0.95, 1.0, 0.8))
