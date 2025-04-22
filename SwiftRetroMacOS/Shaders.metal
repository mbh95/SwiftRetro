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

fragment float4 fragmentShader(
    VertexOut interpolated [[stage_in]],
    texture2d<float, access::read> gameTexture [[texture(0)]]
) {
    uint2 pixel_coord = uint2(interpolated.texCoord * float2(gameTexture.get_width(), gameTexture.get_height()));
    return gameTexture.read(pixel_coord);
}
