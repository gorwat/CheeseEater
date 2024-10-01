shader_type spatial;
render_mode specular_toon;

const vec3 darker_color = vec3(0, 0.01 ,0);
const vec3 brighter_color = vec3(0.0, 0.02, 0.0); 

uniform bool shaking_bush;
uniform float time_left;

void vertex() {
	// Called for every vertex the material is visible on.
	if (shaking_bush) {
		VERTEX.y += (VERTEX.y*0.1 * sin(VERTEX.x*00.1) *sin(VERTEX.z*0.01) * sin(TIME*20.0)) * time_left *2.0;
		VERTEX.x += sin(VERTEX.y) * sin(TIME*10.0) * time_left *2.0;
		VERTEX.z += sin(VERTEX.y) * sin(TIME*10.0) * time_left *2.0;
	}
}

void fragment() {
	ALBEDO = brighter_color; 
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
