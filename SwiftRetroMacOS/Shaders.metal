//
//  Shaders.metal
//  SwiftRetroMacOS
//
//  Created by Matt Hammond on 4/20/25.
//

#include <metal_stdlib>

using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord [[user(texturecoord)]];
};

vertex VertexOut vertexShader(
    uint vertexID [[vertex_id]],
    constant float4* position [[buffer(0)]],
    constant float2* texCoord [[buffer(1)]]
) {
    VertexOut out;
    out.position = position[vertexID];
    out.texCoord = texCoord[vertexID];
    return out;
}

fragment float4 fragmentShader_XRGB8888(
    VertexOut interpolated [[stage_in]],
    texture2d<float, access::sample> gameTexture [[texture(0)]]
) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    return gameTexture.sample(textureSampler, interpolated.texCoord);
}

fragment float4 fragmentShader_0RGB1555(
    VertexOut interpolated [[stage_in]],
    texture2d<uint16_t, access::read> gameTexture [[texture(0)]]
) {
    uint2 pixel_coord = uint2(interpolated.texCoord * float2(gameTexture.get_width(), gameTexture.get_height()));
    uint16_t pixel = gameTexture.read(pixel_coord).r;
        
    // Decode 0RGB1555
    // 0 RRRRR GGGGG BBBBB
    float r = float((pixel >> 10) & 0x1F) / 0x1F;
    float g = float((pixel >> 5)  & 0x1F) / 0x1F;
    float b = float(pixel         & 0x1F) / 0x1F;
    
    return float4(r,g,b, 1.0);
}



fragment float4 fragmentShader_RGB565(
    VertexOut interpolated [[stage_in]],
    texture2d<uint16_t, access::read> gameTexture [[texture(0)]]
) {
    uint2 pixel_coord = uint2(interpolated.texCoord * float2(gameTexture.get_width(), gameTexture.get_height()));
    uint16_t pixel = gameTexture.read(pixel_coord).r;
    
    // Decode RGB565
    // RRRRR GGGGGG BBBBB
    float r = float((pixel >> 11) & 0x1F) / 0x1F;
    float g = float((pixel >> 5)  & 0x3F) / 0x3F;
    float b = float(pixel         & 0x1F) / 0x1F;
    
    return float4(r, g, b, 1.0);
}
