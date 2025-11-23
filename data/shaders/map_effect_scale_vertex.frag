attribute vec2 a_Vertex;
attribute vec2 a_TexCoord;

uniform mat3 u_TransformMatrix;
uniform mat3 u_ProjectionMatrix;
uniform mat3 u_TextureMatrix;
varying vec2 v_TexCoord;

void main()
{
    // Always scale to 2x (64x64) for Critical Damage effect (effect 173)
    // Center the scaling at the sprite center (16, 16 for 32x32 base)
    vec2 center = vec2(16.0, 16.0);
    vec2 scaledVertex = (a_Vertex - center) * 2.0 + center;
    
    gl_Position = vec4((u_ProjectionMatrix * u_TransformMatrix * vec3(scaledVertex.xy, 1.0)).xy, 1.0, 1.0);
    v_TexCoord = (u_TextureMatrix * vec3(a_TexCoord,1.0)).xy;
}


