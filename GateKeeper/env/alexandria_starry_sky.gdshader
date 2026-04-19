shader_type sky;

/// Colores alineados con el ProceduralSkyMaterial previo (oliva / cálido).
group_uniforms Colors;
uniform vec3 sky_top_color : source_color = vec3(0.114, 0.118, 0.094);
uniform vec3 sky_horizon_color : source_color = vec3(0.224, 0.208, 0.169);
uniform vec3 ground_bottom_color : source_color = vec3(0.302, 0.278, 0.212);

group_uniforms Stars;
uniform float star_brightness : hint_range(0.0, 2.0) = 0.72;
uniform float star_twinkle : hint_range(0.0, 1.0) = 0.1;

void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = dir.y;
	vec3 col = mix(sky_horizon_color, sky_top_color, smoothstep(-0.18, 0.55, h));
	if (h < 0.0) {
		col = mix(ground_bottom_color, sky_horizon_color, smoothstep(-0.55, 0.02, h));
	}
	// Estrellas procedurales (malla fina sobre la bóveda).
	float u = atan(dir.x, dir.z) * 0.159154943 + 0.5;
	float v = asin(clamp(dir.y, -1.0, 1.0)) * 0.318309886 + 0.5;
	vec2 g = floor(vec2(u, v) * vec2(960.0, 480.0));
	float r = fract(sin(dot(g, vec2(12.9898, 78.233))) * 43758.5453);
	float tw = sin(TIME * 1.15 + r * 40.0) * 0.5 + 0.5;
	float thr = mix(0.972, 0.985, tw * star_twinkle);
	float star = step(thr, r) * smoothstep(0.04, 0.42, h);
	vec3 star_col = vec3(0.9, 0.93, 1.0) * star * star_brightness;
	COLOR = col + star_col;
}
