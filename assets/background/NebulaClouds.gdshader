shader_type canvas_item;

uniform float time_seed : hint_range(0, 100) = 0.0;
uniform vec3 base_color : source_color = vec3(0.2, 0.1, 0.3);
uniform vec3 accent_color : source_color = vec3(0.4, 0.2, 0.6);
uniform float cloud_scale : hint_range(1.0, 10.0) = 3.0;
uniform float cloud_density : hint_range(0.0, 1.0) = 0.5;

// Hash function to generate pseudo-random values
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Improved Perlin-like noise
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Smooth interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Four corners in 2D of a tile
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    // Mix the four corners progressively
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

void fragment() {
    // Create multiple layers of noise
    vec2 st = UV * cloud_scale;
    st += time_seed * 0.05;

    // Layered noise with different scales
    float n1 = noise(st);
    float n2 = noise(st * 2.0) * 0.5;
    float n3 = noise(st * 4.0) * 0.25;

    // Combine noise layers
    float combined_noise = n1 + n2 + n3;

    // Normalize and adjust noise
    combined_noise = smoothstep(0.4, 0.7, combined_noise);

    // Color blending
    vec3 cloud_color = mix(base_color, accent_color, combined_noise);

    // Alpha and density control
    float alpha = combined_noise * cloud_density;

    COLOR = vec4(cloud_color, alpha);
}