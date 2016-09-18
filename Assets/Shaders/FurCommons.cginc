sampler2D _MainTex;
sampler2D _FurTex;

struct Input 
{
	float2 uv_MainTex;
	float2 uv_FurTex;
	float3 viewDir;
};

half _Glossiness;
half _Metallic;
half _FurLength;
half4 _Displacement;
fixed4 _AlbedoColor;
half _EdgeFade;
half _FakeOcclusion;

half3 FurDisplacement(half3 position, half3 normal, float layer)
{
    half3 pos = position + normal * _FurLength * layer;

    // swaying effect
    #if !FIXED
        half3 grav = mul(_Displacement, _World2Object).xyz;
        half k = 0;
        // varying density functions
        #if LIN
            k = layer;
        #endif
        #if POW2
            k = pow(layer, 2.0);
        #endif
        #if POW3
            k = pow(layer, 3.0);
        #endif
        #if SINE
            k = sin(layer);
        #endif
        pos = pos + grav * k;
    #endif

    return pos;
}