shader_type spatial;
render_mode unshaded;

// Animated TV static / noise. Driven entirely by built-in TIME — no assets, no video.
uniform float noise_speed = 12.0;
uniform float flicker_amount = 0.08;
uniform float tv_on = 1.0; // 1.0 = static visible, 0.0 = screen dark

float hash(vec2 p) {
	// Cheap pseudo-random from a 2D coordinate.
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec3 col;
	if (tv_on >= 0.5) {
		// Sample noise in a grid that scrolls with time -> animated static.
		vec2 uv = UV * vec2(160.0, 100.0);
		float t = TIME * noise_speed;
		float n = hash(floor(uv) + vec2(t, t * 0.7));
		// Occasional horizontal bands of brighter static.
		n = mix(n, hash(floor(uv * vec2(1.0, 0.15)) + t), 0.3);
		// Subtle flicker so it's not perfectly uniform.
		n += flicker_amount * (hash(vec2(t, 1.0)) - 0.5);
		n = clamp(n, 0.0, 1.0);
		col = vec3(n);
	} else {
		// Screen off.
		col = vec3(0.0);
	}
	ALBEDO = col;
	EMISSION = col;
}
