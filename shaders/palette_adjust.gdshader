shader_type canvas_item;

// Переиспользуемая подгонка палитры под общий тон игры: снижает
// насыщенность и/или затемняет спрайт, не трогая альфа-канал.
// Годится для любого временного ассета, который визуально выбивается
// из общей мрачной эстетики (не хардкожено под конкретный узел).

uniform float saturation: hint_range(0.0, 1.0) = 0.5; // 1.0 = оригинал, 0.0 = чёрно-белый
uniform float darken: hint_range(0.0, 1.0) = 0.2; // 0.0 = без затемнения, 1.0 = чёрный

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	float luminance = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(vec3(luminance), tex_color.rgb, saturation);
	COLOR = vec4(desaturated * (1.0 - darken), tex_color.a);
}
