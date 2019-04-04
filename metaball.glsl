vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(texture, texture_coords);
    float alpha = pixel.w;
    float threshold = 0.88;
    if (alpha >= threshold) {
        alpha = 1;
    } else {
        alpha = 0;
    }
    return vec4(pixel.x, pixel.y, pixel.z, alpha);
}