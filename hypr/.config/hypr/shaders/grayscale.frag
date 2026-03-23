#version 300 es
precision highp float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// Grayscale intensity: 0.0 = original color, 1.0 = full grayscale
float u_grayscaleIntensity = 1.0; 

// Enum for type of grayscale conversion
const int LUMINOSITY = 0;
const int LIGHTNESS = 1;
const int AVERAGE = 2;

// Enum for selecting luma coefficients
const int PAL = 0;
const int HDTV = 1;
const int HDR = 2;

// Settings (can tweak these to taste)
const int Type = LUMINOSITY;       // Use LUMINOSITY formula
const int LuminosityType = HDTV;   // Use HDTV luma

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    float gray = 0.0;
    if (Type == LUMINOSITY) {
        if (LuminosityType == PAL) {
            gray = dot(pixColor.rgb, vec3(0.299, 0.587, 0.114));
        } else if (LuminosityType == HDTV) {
            gray = dot(pixColor.rgb, vec3(0.2126, 0.7152, 0.0722));
        } else if (LuminosityType == HDR) {
            gray = dot(pixColor.rgb, vec3(0.2627, 0.6780, 0.0593));
        }
    } else if (Type == LIGHTNESS) {
        float maxPixColor = max(pixColor.r, max(pixColor.g, pixColor.b));
        float minPixColor = min(pixColor.r, min(pixColor.g, pixColor.b));
        gray = (maxPixColor + minPixColor) / 2.0;
    } else if (Type == AVERAGE) {
        gray = (pixColor.r + pixColor.g + pixColor.b) / 3.0;
    }

    vec3 grayscale = vec3(gray);

    // Blend original color with grayscale to soften effect
    vec3 finalColor = mix(pixColor.rgb, grayscale, clamp(u_grayscaleIntensity, 0.0, 1.0));

    fragColor = vec4(finalColor, pixColor.a);
}

