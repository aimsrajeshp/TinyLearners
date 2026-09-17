extends Control
## Generic 2D tracing pad: draws a glyph as one or more strokes and tracks
## the child's finger along it. Leaving the path resets the current stroke
## (doc rule: boundary violation -> retry, same letter/number). Completing
## every stroke in order finishes the trace.
##
## Glyph data comes from data/trace_paths.json (points in Hershey font
## units - see the generator in the Numbers/Alphabet tracing scenes).

signal stroke_started
signal stroke_completed(stroke_index: int)
signal trace_completed
signal trace_failed

const UNIT_HEIGHT := 23.0
const TOP_MARGIN_RATIO := 0.08
const HEIGHT_FILL_RATIO := 0.88
const START_TOLERANCE := 130.0
const PATH_TOLERANCE := 95.0
const END_TOLERANCE := 50.0
const LINE_WIDTH := 70.0
const PENCIL_FONT_SIZE := 72

const COLOR_UPCOMING := Color(0.85, 0.87, 0.91, 0.6)
const COLOR_UNTOUCHED := Color(0.784, 0.804, 0.851, 1.0)
const COLOR_ACTIVE := Color(0.396, 0.780, 0.969, 1.0)
const COLOR_DONE := Color(0.459, 0.839, 0.506, 1.0)

var glyph_data: Dictionary = {}
var _scale: float = 1.0
var _origin: Vector2 = Vector2.ZERO

var _stroke_points: Array = []       # Array[PackedVector2Array], one per stroke, in local pixel space
var _stroke_cumlen: Array = []       # Array[PackedFloat32Array]
var _stroke_total: Array = []        # Array[float]

var current_stroke_index: int = 0
var _progress_len: float = 0.0
var _is_drawing: bool = false
var _finger_pos: Vector2 = Vector2.ZERO
var _show_finger: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_glyph(data: Dictionary) -> void:
	glyph_data = data
	current_stroke_index = 0
	_progress_len = 0.0
	_is_drawing = false
	_show_finger = false
	_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not glyph_data.is_empty():
		_rebuild()

func _rebuild() -> void:
	if glyph_data.is_empty():
		return
	_scale = (size.y * HEIGHT_FILL_RATIO) / UNIT_HEIGHT
	var glyph_w: float = (float(glyph_data.max_x) - float(glyph_data.min_x)) * _scale
	_origin = Vector2(
		(size.x - glyph_w) / 2.0 - float(glyph_data.min_x) * _scale,
		size.y * TOP_MARGIN_RATIO - float(glyph_data.min_y) * _scale
	)
	_stroke_points.clear()
	_stroke_cumlen.clear()
	_stroke_total.clear()
	for stroke in glyph_data.strokes:
		var pts := PackedVector2Array()
		for p in stroke:
			pts.append(Vector2(float(p[0]), float(p[1])) * _scale + _origin)
		_stroke_points.append(pts)
		var cum := PackedFloat32Array([0.0])
		var total := 0.0
		for i in range(1, pts.size()):
			total += pts[i].distance_to(pts[i - 1])
			cum.append(total)
		_stroke_cumlen.append(cum)
		_stroke_total.append(total)
	queue_redraw()

func _point_at_length(pts: PackedVector2Array, cum: PackedFloat32Array, target_len: float) -> Vector2:
	if pts.size() == 1:
		return pts[0]
	for i in range(1, cum.size()):
		if cum[i] >= target_len:
			var seg_len: float = cum[i] - cum[i - 1]
			var t: float = 0.0 if seg_len <= 0.0 else (target_len - cum[i - 1]) / seg_len
			return pts[i - 1].lerp(pts[i], t)
	return pts[pts.size() - 1]

func _nearest_forward(pts: PackedVector2Array, cum: PackedFloat32Array, pos: Vector2, from_len: float) -> Dictionary:
	# Search the whole current stroke for the closest point on the path that is
	# not behind our current progress (small backward slack allowed).
	var best_dist := INF
	var best_len := from_len
	var slack := LINE_WIDTH
	for i in range(1, pts.size()):
		if cum[i] < from_len - slack:
			continue
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var seg: Vector2 = b - a
		var seg_len_sq: float = seg.length_squared()
		var t: float = 0.0 if seg_len_sq <= 0.0001 else clamp((pos - a).dot(seg) / seg_len_sq, 0.0, 1.0)
		var closest: Vector2 = a + seg * t
		var d: float = pos.distance_to(closest)
		if d < best_dist:
			best_dist = d
			best_len = cum[i - 1] + seg.length() * t
	return {"dist": best_dist, "len": best_len}

func _gui_input(event: InputEvent) -> void:
	if glyph_data.is_empty() or current_stroke_index >= _stroke_points.size():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_try_begin(touch.position)
		else:
			_is_drawing = false
			_show_finger = false
			queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_update_drawing(drag.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_try_begin(mb.position)
			else:
				_is_drawing = false
				_show_finger = false
				queue_redraw()
	elif event is InputEventMouseMotion and _is_drawing:
		var mm := event as InputEventMouseMotion
		_update_drawing(mm.position)

func _try_begin(pos: Vector2) -> void:
	var pts: PackedVector2Array = _stroke_points[current_stroke_index]
	var cum: PackedFloat32Array = _stroke_cumlen[current_stroke_index]
	var anchor: Vector2 = _point_at_length(pts, cum, _progress_len)
	var tolerance: float = START_TOLERANCE if _progress_len <= 1.0 else START_TOLERANCE * 0.7
	if pos.distance_to(anchor) <= tolerance:
		_is_drawing = true
		_show_finger = true
		_finger_pos = pos
		queue_redraw()
		stroke_started.emit()

func _update_drawing(pos: Vector2) -> void:
	if not _is_drawing:
		return
	_finger_pos = pos
	_show_finger = true
	var pts: PackedVector2Array = _stroke_points[current_stroke_index]
	var cum: PackedFloat32Array = _stroke_cumlen[current_stroke_index]
	var result := _nearest_forward(pts, cum, pos, _progress_len)
	if result["dist"] > PATH_TOLERANCE:
		_fail()
		return
	if result["len"] > _progress_len:
		_progress_len = result["len"]
	var total: float = _stroke_total[current_stroke_index]
	if _progress_len >= total - END_TOLERANCE:
		_complete_stroke()
		return
	queue_redraw()

func _fail() -> void:
	_is_drawing = false
	_show_finger = false
	_progress_len = 0.0
	queue_redraw()
	trace_failed.emit()

func _complete_stroke() -> void:
	_is_drawing = false
	_show_finger = false
	var finished_index := current_stroke_index
	current_stroke_index += 1
	_progress_len = 0.0
	queue_redraw()
	stroke_completed.emit(finished_index)
	if current_stroke_index >= _stroke_points.size():
		trace_completed.emit()

func _draw() -> void:
	if glyph_data.is_empty():
		return
	for i in _stroke_points.size():
		var pts: PackedVector2Array = _stroke_points[i]
		if pts.size() < 2:
			continue
		if i < current_stroke_index:
			draw_polyline(pts, COLOR_DONE, LINE_WIDTH, true)
		elif i > current_stroke_index:
			draw_polyline(pts, COLOR_UPCOMING, LINE_WIDTH * 0.6, true)
		else:
			draw_polyline(pts, COLOR_UNTOUCHED, LINE_WIDTH, true)
			var cum: PackedFloat32Array = _stroke_cumlen[i]
			var done_pts := PackedVector2Array()
			for j in pts.size():
				if cum[j] <= _progress_len:
					done_pts.append(pts[j])
				else:
					done_pts.append(_point_at_length(pts, cum, _progress_len))
					break
			if done_pts.size() >= 2:
				draw_polyline(done_pts, COLOR_ACTIVE, LINE_WIDTH, true)
			var anchor: Vector2 = _point_at_length(pts, cum, _progress_len)
			draw_circle(anchor, LINE_WIDTH * 0.55, COLOR_ACTIVE)
	if _show_finger:
		var font := get_theme_default_font()
		var text := "✏️"
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, PENCIL_FONT_SIZE)
		# Anchor the pencil tip (bottom-left of the glyph) at the touch point.
		var tip_offset := Vector2(text_size.x * 0.12, -text_size.y * 0.15)
		draw_string(font, _finger_pos - tip_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, PENCIL_FONT_SIZE)
