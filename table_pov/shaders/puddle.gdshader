shader_type spatial;

uniform vec3 albedo: source_color;
uniform float alpha: hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float metallic: hint_range(0, 1.0) = 0;
uniform float roughness: hint_range(0, 1.0) = 0.02;

uniform sampler2D texture_normal;
// Controls 'size' and depth of puddle
uniform float floor_min_y: hint_range(-1.0, 0) = -0.5;
uniform float radius = 5;

const int MAX_WAVES = 20;
uniform vec2[MAX_WAVES] wave_sources;
uniform float[MAX_WAVES] wave_amplitudes;
uniform int wave_sources_size = 1;
uniform vec2 wave_source;
uniform float wave_amplitude: hint_range(0, 1.0) = 1.0;
uniform float wave_speed;
uniform float wave_radius;
uniform float amplitude;
uniform float frequency: hint_range(0, 300.0) = 1.0;
uniform vec3 wave_colour: source_color;

void vertex() {
 /*
	float dist_from_center = sqrt(VERTEX.x*VERTEX.x + VERTEX.z*VERTEX.z);
	if (dist_from_center >= radius){
		float diff = dist_from_center-radius;
		VERTEX.y = max(-(diff), floor_min_y);
	} else
	{
		float vertex_height = 0.0;
		for (int i=0; i < wave_sources_size; i++){
			// Increase distance over time
			float current_radius = wave_radius*(1.0-(pow(wave_amplitudes[i], 2)));

			// Called for every vertex the material is visible on.
			float dist_x = (VERTEX.x-wave_sources[i].x)*(VERTEX.x-wave_sources[i].x);
			float dist_z = (VERTEX.z-wave_sources[i].y)*(VERTEX.z-wave_sources[i].y);
			float dist_from_source = dist_x + dist_z;
			float sombrero = 0.0;
			if (sqrt(dist_from_source) > current_radius){
				sombrero = 0.0;
			} else {
				sombrero = sin(dist_from_source*frequency - TIME*wave_speed)*amplitude*wave_amplitudes[i];
			}

			vertex_height += sombrero;
		}
		VERTEX.y = max(vertex_height, -0.02);


	}

	
 */
	COLOR.xyz = VERTEX;
}

void fragment() {
	
	float dist_from_center = sqrt(COLOR.x*COLOR.x + COLOR.z*COLOR.z);
	if (dist_from_center >= radius){
		float diff = dist_from_center-radius;
		ALPHA = max(-(diff), floor_min_y);
	} else {
		ALPHA = alpha;
	}
	float total_wave_height = 0.0;
	for (int i=0; i < wave_sources_size; i++){
		// Increase distance over time
		float current_radius = wave_radius*(1.0-(pow(wave_amplitudes[i], 2)));

		// Called for every vertex the material is visible on.
		float dist_x = (COLOR.x-wave_sources[i].x)*(COLOR.x-wave_sources[i].x);
		float dist_z = (COLOR.z-wave_sources[i].y)*(COLOR.z-wave_sources[i].y);
		float dist_from_source = dist_x + dist_z;
		float wave_height = 0.0;
		if (sqrt(dist_from_source) > current_radius){
			wave_height += 0.0;
		}
		else  {
			wave_height = sin(dist_from_source*frequency - TIME*wave_speed)*amplitude*wave_amplitudes[i];
		}

		total_wave_height += wave_height;
	}
	
	ALBEDO = albedo + clamp(total_wave_height*wave_colour, 0.0, 1.0)*0.4;
	
	METALLIC = metallic;
	ROUGHNESS = roughness;

	vec3 normal1 = texture(texture_normal, vec2(UV.x, UV.y) +TIME*vec2(0.01)).rgb;
	vec3 normal2 = texture(texture_normal, vec2(UV.x, UV.y) +TIME*vec2(-0.01, 0.01)).rgb;
	NORMAL_MAP = mix(normal1, normal2, 0.9);

}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
