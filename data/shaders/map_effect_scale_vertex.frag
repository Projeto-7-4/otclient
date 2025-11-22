attribute vec2 a_Vertex;
attribute vec2 a_TexCoord;

uniform mat3 u_TransformMatrix;
uniform mat3 u_ProjectionMatrix;
uniform mat3 u_TextureMatrix;
uniform float u_EffectScale; // Scale factor for effect 173 (default 1.0, use 2.0 for 64x64)
varying vec2 v_TexCoord;

void main()
{
    // Scale vertex if this is effect 173 (u_EffectScale > 1.0)
    vec2 scaledVertex = a_Vertex;
    if (u_EffectScale > 1.0) {
        // Center the scaling
        vec2 center = vec2(16.0, 16.0); // Center of 32x32 sprite
        scaledVertex = (a_Vertex - center) * u_EffectScale + center;
    }
    
    gl_Position = vec4((u_ProjectionMatrix * u_TransformMatrix * vec3(scaledVertex.xy, 1.0)).xy, 1.0, 1.0);
    v_TexCoord = (u_TextureMatrix * vec3(a_TexCoord,1.0)).xy;
}

