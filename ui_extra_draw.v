module ui

import gx
import math
import sokol.sgl

const (
	empty_text_cfg = gx.TextCfg{}
)

pub fn is_empty_text_cfg(t gx.TextCfg) bool {
	return t.str() == ui.empty_text_cfg.str()
}

//-----  Generic for performance

// T is Widget with text_cfg field
fn text_size<T>(w &T, text string) (int, int) {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_size(text)
}

fn text_width<T>(w &T, text string) int {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_width(text)
}

fn text_height<T>(w &T, text string) int {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_height(text)
}

// T is a widget Type with text_cfg field
fn draw_text<T>(w &T, x int, y int, text_ string) {
	window := w.ui.window
	if w.text_size > 0 {
		_, win_height := window.size()
		tc := gx.TextCfg{
			...w.text_cfg
			size: text_size_as_int(w.text_size, win_height)
		}
		w.ui.gg.draw_text(x, y, text_, tc)
	} else {
		// println("draw_text: $text_ $w.text_cfg.color")
		w.ui.gg.draw_text(x, y, text_, w.text_cfg)
	}
}

fn draw_text_with_color<T>(w &T, x int, y int, text_ string, color gx.Color) {
	if w.text_size > 0 {
		_, win_height := w.ui.window.size()
		tc := gx.TextCfg{
			...w.text_cfg
			size: text_size_as_int(w.text_size, win_height)
			color: color
		}
		w.ui.gg.draw_text(x, y, text_, tc)
	} else {
		tc := gx.TextCfg{
			...w.text_cfg
			color: color
		}
		w.ui.gg.draw_text(x, y, text_, tc)
	}
}

//--------- DrawText interface (for Tooltip and Message)
// Rmk: this can be used for Widget having these fields too

interface DrawText {
	ui &UI
mut:
	text_cfg gx.TextCfg
	text_size f64
}

fn init_text_cfg(mut w DrawText) {
	if is_empty_text_cfg(w.text_cfg) {
		w.text_cfg = w.ui.window.text_cfg
	}
	if w.text_size > 0 {
		_, win_height := w.ui.window.size()
		w.text_cfg = gx.TextCfg{
			...w.text_cfg
			size: text_size_as_int(w.text_size, win_height)
		}
	}
}

// No text_size to not conflict with
fn get_text_size(w DrawText, text_ string) (int, int) {
	w.ui.gg.set_cfg(w.text_cfg)
	return w.ui.gg.text_size(text_)
}

fn set_text_cfg_color(mut w DrawText, color gx.Color) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		color: color
	}
}

fn set_text_cfg_size(mut w DrawText, size int) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		size: size
	}
}

fn set_text_cfg_style(mut w DrawText, bold bool, italic bool, mono bool) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		bold: bold
		italic: italic
		mono: mono
	}
}

fn set_text_cfg_align(mut w DrawText, align gx.HorizontalAlign) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		align: align
	}
}

fn set_text_cfg_vertical_align(mut w DrawText, align gx.VerticalAlign) {
	w.text_cfg = gx.TextCfg{
		...w.text_cfg
		vertical_align: align
	}
}

// pub fn draw_text_line(w DrawText, x int, y int, text_ string) {
// 	w.ui.gg.draw_text(x, y, text_, w.text_cfg)
// }

// pub fn draw_text_line_with_color(w DrawText, x int, y int, text_ string, color gx.Color) {
// 	tc := gx.TextCfg{
// 		...w.text_cfg
// 		color: color
// 	}
// 	w.ui.gg.draw_text(x, y, text_, tc)
// }

pub fn draw_text_lines(w DrawText, x int, y int, lines []string) {
	mut th := 0
	for line in lines {
		w.ui.gg.draw_text(x, y + th, line, w.text_cfg)
		_, tmp := get_text_size(w, line)
		th += tmp
	}
}

fn update_text_size(mut w DrawText) {
	if w.text_size > 0 {
		_, win_height := w.ui.window.size()
		w.text_cfg = gx.TextCfg{
			...w.text_cfg
			size: text_size_as_int(w.text_size, win_height)
		}
	}
}

//------- Futher functions

// text_size: f64
//   0  (default)  => system
//   16 (or 16.)   => fixed font size
//   .5 (in ]0,1]) => proprtion of height window
pub fn text_size_as_int(size f64, win_height int) int {
	return if size > 0 && size < 1 {
		// println("tsai: ${int(size * win_height)} = $size * $win_height")
		int(size * win_height)
	} else if size == int(size) {
		int(size)
	} else {
		0
	}
}

// This a a generic function
fn point_inside<T>(w &T, x f64, y f64) bool {
	wx, wy := w.x + w.offset_x, w.y + w.offset_y
	return x >= wx && x <= wx + w.width && y >= wy && y <= wy + w.height
}

// h, s, l in [0,1]
pub fn hsv_to_rgb(h f64, s f64, v f64) gx.Color {
	c := v * s
	x := c * (1. - math.abs(math.fmod(h * 6., 2.) - 1.))
	m := v - c
	mut r, mut g, mut b := 0., 0., 0.
	h6 := h * 6.
	if h6 < 1. {
		r, g = c, x
	} else if h6 < 2. {
		r, g = x, c
	} else if h6 < 3. {
		g, b = c, x
	} else if h6 < 4. {
		g, b = x, c
	} else if h6 < 5. {
		r, b = x, c
	} else {
		r, b = c, x
	}
	return gx.rgb(byte((r + m) * 255.), byte((g + m) * 255.), byte((b + m) * 255.))
}

// h, s, l in [0,1]
pub fn hsl_to_rgb(h f64, s f64, l f64) gx.Color {
	c := (1. - math.abs(2. * l - 1.)) * s
	x := c * (1. - math.abs(math.fmod(h * 6., 2.) - 1.))
	m := l - c / 2.
	mut r, mut g, mut b := 0., 0., 0.
	h6 := h * 6.
	if h6 < 1. {
		r, g = c, x
	} else if h6 < 2. {
		r, g = x, c
	} else if h6 < 3. {
		g, b = c, x
	} else if h6 < 4. {
		g, b = x, c
	} else if h6 < 5. {
		r, b = x, c
	} else {
		r, b = c, x
	}
	return gx.rgb(byte((r + m) * 255.), byte((g + m) * 255.), byte((b + m) * 255.))
}

pub fn rgb_to_hsv(col gx.Color) (f64, f64, f64) {
	r, g, b := f64(col.r) / 255., f64(col.g) / 255., f64(col.b) / 255.
	v, m := f64_max(f64_max(r, g), b), -f64_max(f64_max(-r, -g), -b)
	d := v - m
	mut h, mut s := 0., 0.
	if v == m {
		h = 0
	} else if v == r {
		if g > b {
			h = ((g - b) / d) / 6.
		} else {
			h = (6. - (g - b) / d) / 6
		}
	} else if v == g {
		h = ((b - r) / d + 2.) / 6.
	} else if v == b {
		h = ((r - g) / d + 4.) / 6.
	}
	// println("h: $h")
	if v != 0 {
		s = d / v
	}
	return h, s, v
}

pub fn rgb_to_hsl(col gx.Color) (f64, f64, f64) {
	r, g, b := f64(col.r) / 255., f64(col.g) / 255., f64(col.b) / 255.
	v, m := f64_max(f64_max(r, g), b), -f64_max(f64_max(-r, -g), -b)
	d := v - m
	mut h, mut s := 0., 0.
	if v == m {
		h = 0
	} else if v == r {
		if g > b {
			h = ((g - b) / d) / 6.
		} else {
			h = (6. - (g - b) / d) / 6
		}
	} else if v == g {
		h = ((b - r) / d + 2.) / 6.
	} else if v == b {
		h = ((r - g) / d + 4.) / 6.
	}
	l := (v + m) / 2.
	// println("h: $h")
	if v != 0 {
		s = d / (1. - math.abs(2 * l - 1.))
	}

	return h, s, l
}

// Texture stuff borrowed from @penguindark to deal with texture in sokol
//

pub fn create_texture(w int, h int, buf &byte) C.sg_image {
	mut img_desc := C.sg_image_desc{
		width: w
		height: h
		num_mipmaps: 0
		min_filter: .linear
		mag_filter: .linear
		wrap_u: .clamp_to_edge
		wrap_v: .clamp_to_edge
		label: &byte(0)
		d3d11_texture: 0
	}
	sz := w * h * 4

	img_desc.data.subimage[0][0] = C.sg_range{
		ptr: buf
		size: size_t(sz)
	}

	sg_img := C.sg_make_image(&img_desc)
	return sg_img
}

pub fn destroy_texture(sg_img C.sg_image) {
	C.sg_destroy_image(sg_img)
}

// Dynamic texture
pub fn create_dynamic_texture(w int, h int) C.sg_image {
	mut img_desc := C.sg_image_desc{
		width: w
		height: h
		num_mipmaps: 0
		min_filter: .linear
		mag_filter: .linear
		usage: .dynamic
		wrap_u: .clamp_to_edge
		wrap_v: .clamp_to_edge
		label: &byte(0)
		d3d11_texture: 0
	}

	sg_img := C.sg_make_image(&img_desc)
	return sg_img
}

// Use only if usage: .dynamic is enabled
pub fn update_text_texture(sg_img C.sg_image, w int, h int, buf &byte) {
	sz := w * h * 4
	mut tmp_sbc := C.sg_image_data{}
	tmp_sbc.subimage[0][0] = C.sg_range{
		ptr: buf
		size: size_t(sz)
	}
	C.sg_update_image(sg_img, &tmp_sbc)
}

pub fn (c &CanvasLayout) draw_texture(w int, h int, simg C.sg_image) {
	ctx := c.ui.gg
	cx, cy := c.x + c.offset_x, c.y + c.offset_y
	u0 := f32(cx / w)
	v0 := f32(cy / h)
	u1 := f32((cx + c.width) / w)
	v1 := f32((cy + c.height) / h)
	x0 := f32(cx * ctx.scale)
	y0 := f32(cy * ctx.scale)
	x1 := f32((cx + c.width) * ctx.scale)
	y1 := f32((cy + c.height) * ctx.scale)
	sgl.load_pipeline(ctx.timage_pip)
	sgl.enable_texture()
	sgl.texture(simg)
	sgl.begin_quads()
	sgl.c4b(255, 255, 255, 255)
	sgl.v2f_t2f(x0, y0, u0, v0)
	sgl.v2f_t2f(x1, y0, u1, v0)
	sgl.v2f_t2f(x1, y1, u1, v1)
	sgl.v2f_t2f(x0, y1, u0, v1)
	sgl.end()
	sgl.disable_texture()
}
