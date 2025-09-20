// retro_crt_bloom_barrel.glsl
// Single-pass shader for Ghostty that:
// 1) Applies a barrel “fishbowl” distortion (warp)
// 2) Adds bloom glow
// 3) Overlays scanlines
// 4) Applies a greenish tint
//
// If you push warp too high, you’ll see black borders unless you clamp
// or color them differently (see the CLAMP_OUT_OF_BOUNDS define).

#define CLAMP_OUT_OF_BOUNDS  // comment this out if you prefer black

float warp            = 0.15;    // Barrel distortion strength. 0.0 = no warp
float scan            = 1.00;    // Darkness between scanlines
float bloomThreshold  = 0.20;    // Luminance threshold for bloom
float bloomIntensity  = 0.20;    // Bloom multiplier
float tintIntensity   = 0.40;    // 0.0=no tint, 1.0=strong tint
vec3  tintColor       = vec3(0.2, 1.0, 0.2); // Greenish tint

// Golden spiral bloom samples
const vec3 samples[24] = {
    vec3( 0.1693761725,  0.9855514762,  1.0),
    vec3(-1.3330708310,  0.4721463329,  0.7071067812),
    vec3(-0.8464394910, -1.5111387058,  0.5773502692),
    vec3( 1.5541556807, -1.2588090086,  0.5),
    vec3( 1.6813643776,  1.4741145918,  0.4472135955),
    vec3(-1.2795157692,  2.0887411032,  0.4082482905),
    vec3(-2.4575847531, -0.9799373355,  0.3779644730),
    vec3( 0.5874641440, -2.7667464429,  0.3535533906),
    vec3( 2.9977157034,  0.1170493988,  0.3333333333),
    vec3( 0.4136084245,  3.1351121306,  0.3162277660),
    vec3(-3.1671499338,  0.9844599012,  0.3015113446),
    vec3(-1.5736713847, -3.0860263079,  0.2886751346),
    vec3( 2.8882026483, -2.1583061558,  0.2773500981),
    vec3( 2.7150778983,  2.5745586041,  0.2672612419),
    vec3(-2.1504069972,  3.2211410628,  0.2581988897),
    vec3(-3.6548858795, -1.6253643308,  0.25),
    vec3( 1.0130775986, -3.9967078676,  0.2425356250),
    vec3( 4.2297236736,  0.3308136106,  0.2357022604),
    vec3( 0.4010779029,  4.3404074136,  0.2294157339),
    vec3(-4.3191245702,  1.1598115997,  0.2236067977),
    vec3(-1.9209044803, -4.1605439521,  0.2182178902),
    vec3( 3.8639122287, -2.6589814383,  0.2132007164),
    vec3( 3.3486228405,  3.4331800233,  0.2085144141),
    vec3(-2.8769733644,  3.9652268864,  0.2041241452)
};

float lum(vec4 c) {
    return 0.299*c.r + 0.587*c.g + 0.114*c.b;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // normalized coords
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Barrel distortion
    //   We'll do a simple formula: 
    //   * shift uv to [-0.5..0.5], 
    //   * multiply by (1 + warp * r^2), 
    //   * shift back.
    //   r^2 = x^2 + y^2 around center.
    vec2 center = uv - 0.5;
    float r2 = dot(center, center); // squared distance from center
    // The larger warp is, the more corners get pushed out (or in).
    // Positive warp -> "barrel" (fishbowl).
    // Negative warp -> "pincushion".
    center *= (1.0 + warp * r2);
    uv = center + 0.5;

#ifdef CLAMP_OUT_OF_BOUNDS
    // If uv went out of [0..1], clamp it so we don't sample black
    // This *keeps* the main image, but can cause visible stretching at edges.
    uv = clamp(uv, 0.0, 1.0);
#endif

    // sample base color
    vec4 color = texture(iChannel0, uv);

    // bloom
    vec2 stepSize = vec2(1.414) / iResolution.xy;
    for(int i = 0; i < 24; i++){
        vec3 s = samples[i];
        vec4 c = texture(iChannel0, uv + s.xy * stepSize);
        float l = lum(c);
        if(l > bloomThreshold) {
            color += l * s.z * c * bloomIntensity;
        }
    }

    // scanlines
    float lineIntensity = abs(sin(fragCoord.y) * 0.25 * scan);
    color.rgb = mix(color.rgb, vec3(0.0), lineIntensity);

    // tint
    color.rgb = mix(color.rgb, color.rgb * tintColor, tintIntensity);

    fragColor = color;
}
