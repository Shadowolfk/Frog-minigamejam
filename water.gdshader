shader_type canvas_item;

// --- NIGHT WATER PALETTE ---
uniform vec3 deep_color      : source_color = vec3(0.02, 0.04, 0.10);
uniform vec3 shallow_color   : source_color = vec3(0.06, 0.13, 0.24);
uniform vec3 highlight_color : source_color = vec3(0.20, 0.36, 0.55);

// --- NOISE TEXTURE ---
uniform sampler2D noise_tex : filter_nearest_mipmap, repeat_enable;

// --- MOTION & SHAPE ---
uniform float speed              : hint_range(0.0, 2.0)  = 0.30;
uniform float tile_scale         : hint_range(0.1, 12.0) = 1.8;   // size of SURFACE pattern
uniform float highlight_strength : hint_range(0.0, 1.0)  = 0.55;
uniform float vignette           : hint_range(0.0, 1.5)  = 0.60;

// --- BACK LAYER (the new one — distant dark blobs read as depth) ---
uniform float back_scale    : hint_range(0.1, 2.0) = 0.45;  // <1 = bigger, more distant features
uniform float back_strength : hint_range(0.0, 1.5) = 0.70;  // how dark the back blobs make things
uniform float back_speed    : hint_range(0.0, 1.0) = 0.30;  // slower than surface = parallax-like depth

// --- PIXELATION ---
uniform float pixels : hint_range(20.0, 600.0) = 120.0;

void fragment() {
	// Square-cell pixel grid.
	vec2 screen = vec2(1.0) / SCREEN_PIXEL_SIZE;
	vec2 cells = vec2(pixels, max(1.0, pixels * screen.y / screen.x));
	vec2 puv = floor(UV * cells) / cells;

	float t = TIME * speed;
	float t_bg = t * back_speed;          // back layer drifts slower for a parallax feel

	// --- BACK LAYER ---
	// One slow, large-scale sample. Its DARK areas become depth shadows beneath the surface.
	vec2 uv_bg = puv * tile_scale * back_scale + vec2(t_bg * 0.05, t_bg * 0.03 + 17.0);
	float bg = texture(noise_tex, uv_bg).r;
	float depth = (1.0 - bg) * back_strength;   // black blobs (bg≈0) -> depth≈back_strength

	// --- SURFACE LAYERS ---
	// Two scrolling samples used ONLY for highlights — their dark parts no longer
	// contribute, so the top surface stays clean instead of getting big dark splotches.
	vec2 uv_s1 = puv * tile_scale + vec2(t * 0.06, t * 0.02);
	vec2 uv_s2 = puv * tile_scale * 1.7 + vec2(-t * 0.04, t * 0.05);
	float s1 = texture(noise_tex, uv_s1).r;
	float s2 = texture(noise_tex, uv_s2).r;
	float surface = s1 * 0.6 + s2 * 0.4;        // bright only when both layers' white veins overlap

	// --- COMPOSITE: start mid, push DOWN with back depth, push UP with surface highlights ---
	vec3 col = shallow_color;
	col = mix(col, deep_color, clamp(depth, 0.0, 1.0));
	float hi = smoothstep(0.85, 1.0, surface);
	col = mix(col, highlight_color, hi * highlight_strength);

	// Vignette on the snapped UV so it doesn't smooth-bleed across pixels.
	vec2 vd = puv - 0.5;
	float vig = 1.0 - dot(vd, vd) * vignette * 2.0;
	col *= clamp(vig, 0.40, 1.0);

	COLOR = vec4(col, 1.0);
}
