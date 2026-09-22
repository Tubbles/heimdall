package heimdall

import "core:testing"

Rect :: struct {
	x, y: f32, // Rectangle top-left corner
	w, h: f32,
}

rect_get_center :: proc(rect: Rect) -> Point {
	return {x = rect.x + rect.w / 2, y = rect.y + rect.h / 2}
}

@(test)
test_rect_get_center :: proc(t: ^testing.T) {
	testing.expect(t, rect_get_center({x = 1, y = 2, w = 3, h = 4}) == Point{x = 2.5, y = 4})
}
