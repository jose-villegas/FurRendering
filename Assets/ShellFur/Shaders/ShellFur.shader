// Shell fur for URP. Drawn by the ShellFur component: one instanced draw renders every
// shell, the instance index is the shell, and the vertices are read from the mesh's (or the
// skinned mesh's) GPU buffers. Strands are procedural: each shell cuts a grid of tapered
// strands of random length out of the surface's UVs.
Shader "FurRendering/Shell Fur"
{
    Properties
    {
        [MainTexture] _BaseMap ("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor ("Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset] _LengthMap ("Length (R)", 2D) = "white" {}

        [Header(Strands)]
        _FurLength ("Length (m)", Range(0.001, 0.5)) = 0.05
        _Density ("Strands per UV Unit", Float) = 400
        _Thickness ("Root Thickness", Range(0.05, 1)) = 0.8
        _MinLength ("Shortest Strand", Range(0, 1)) = 0.3
        _Jitter ("Strand Jitter", Range(0, 1)) = 0.8

        [Header(Shading)]
        _RootOcclusion ("Root Occlusion", Range(0, 1)) = 0.3
        _Wrap ("Diffuse Wrap", Range(0, 1)) = 0.4
        _SpecularColor ("Specular Color", Color) = (1, 0.95, 0.9, 1)
        _Specular ("Specular", Range(0, 2)) = 0.4
        _SpecularExponent ("Specular Exponent", Range(1, 256)) = 64

        [Header(Motion)]
        _Gravity ("Gravity", Range(0, 2)) = 0.3
        _Curve ("Bend Curve", Range(1, 4)) = 2
        _WindDirection ("Wind Direction", Vector) = (1, 0, 0.3, 0)
        _WindStrength ("Wind", Range(0, 2)) = 0.2
        _WindFrequency ("Wind Frequency (Hz)", Float) = 0.5
        _MotionLag ("Motion Lag", Range(0, 4)) = 1
    }

    HLSLINCLUDE
    #pragma target 4.5
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

    TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);
    TEXTURE2D(_LengthMap);  SAMPLER(sampler_LengthMap);

    CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        half4 _BaseColor;
        float _FurLength, _Density, _Thickness, _MinLength, _Jitter;
        half _RootOcclusion, _Wrap;
        half4 _SpecularColor;
        half _Specular, _SpecularExponent;
        float _Gravity, _Curve;
        float4 _WindDirection;
        float _WindStrength, _WindFrequency, _MotionLag;
    CBUFFER_END

    // Set per draw by ShellFur.
    ByteAddressBuffer _FurPositions;    // positions and normals (skinned output or mesh stream)
    ByteAddressBuffer _FurTexcoords;    // the mesh stream holding UV0
    ByteAddressBuffer _FurIndices;
    StructuredBuffer<float4> _FurState; // xyz: smoothed world position per vertex, w: valid
    uint _FurPositionStride, _FurPositionOffset, _FurNormalOffset;
    uint _FurTexcoordStride, _FurTexcoordOffset, _FurTexcoordHalf;
    uint _FurIndexStart, _FurBaseVertex, _FurIndex16;
    uint _FurShellCount;
    float4x4 _FurObjectToWorld, _FurWorldToObject;
    float _FurTime;

    struct FurVertex
    {
        float3 positionWS;
        float3 normalWS;
        float3 strandWS;    // direction of the strand at this shell
        float2 uv;
        float height;       // 0 at the skin, approaching 1 at the outermost shell
    };

    uint LoadIndex(uint i)
    {
        if (_FurIndex16)
        {
            uint word = _FurIndices.Load((i * 2) & ~3u);
            return (i & 1) ? (word >> 16) : (word & 0xFFFF);
        }
        return _FurIndices.Load(i * 4);
    }

    float2 LoadTexcoord(uint v)
    {
        uint address = v * _FurTexcoordStride + _FurTexcoordOffset;
        if (_FurTexcoordHalf)
        {
            uint packed = _FurTexcoords.Load(address);
            return float2(f16tof32(packed), f16tof32(packed >> 16));
        }
        return asfloat(_FurTexcoords.Load2(address));
    }

    FurVertex LoadFurVertex(uint vertexID, uint shell)
    {
        uint v = LoadIndex(_FurIndexStart + vertexID) + _FurBaseVertex;
        uint address = v * _FurPositionStride;
        float3 positionOS = asfloat(_FurPositions.Load3(address + _FurPositionOffset));
        float3 normalOS = asfloat(_FurPositions.Load3(address + _FurNormalOffset));

        FurVertex o;
        o.uv = LoadTexcoord(v);
        o.height = shell / (float)_FurShellCount;
        float3 root = mul(_FurObjectToWorld, float4(positionOS, 1)).xyz;
        float3 n = SafeNormalize(mul(normalOS, (float3x3)_FurWorldToObject));
        float len = _FurLength * SAMPLE_TEXTURE2D_LOD(_LengthMap, sampler_LengthMap, o.uv, 0).r;

        // Bend, in strand lengths: gravity plus gusting wind travelling along its direction.
        float3 windDir = SafeNormalize(_WindDirection.xyz);
        float phase = dot(root, windDir) * 1.5;
        float w = TWO_PI * _WindFrequency * _FurTime;
        float gust = 0.6 + 0.4 * sin(w - phase) + 0.2 * sin(2.0 * w - phase * 1.7 + 1.3);
        float3 bend = (float3(0, -_Gravity, 0) + windDir * (_WindStrength * gust)) * len;

        // Motion lag, in metres: the fur trails behind where the skin was.
        float4 state = _FurState[v];
        float3 lag = state.w > 0 ? (state.xyz - root) * _MotionLag : 0;
        float lagLength = length(lag);
        if (lagLength > len)
            lag *= len / lagLength;
        bend += lag;
        // Strands lie along the skin rather than through it.
        bend -= n * min(dot(bend, n), 0.0);

        // Strands rise along the normal and curve toward the bend near their tips.
        float curve = pow(o.height, _Curve);
        o.positionWS = root + n * (len * o.height) + bend * curve;
        o.strandWS = SafeNormalize(n * len + bend * (_Curve * pow(max(o.height, 1e-3), _Curve - 1.0)));
        o.normalWS = n;
        return o;
    }

    float Hash12(float2 p)
    {
        float3 p3 = frac(p.xyx * 0.1031);
        p3 += dot(p3, p3.yzx + 33.33);
        return frac((p3.x + p3.y) * p3.z);
    }

    float2 Hash22(float2 p)
    {
        float3 p3 = frac(p.xyx * float3(0.1031, 0.1030, 0.0973));
        p3 += dot(p3, p3.yzx + 33.33);
        return frac((p3.xx + p3.yz) * p3.zy);
    }

    // Distance, in strand cells, from the edge of this cell's strand at the given height:
    // positive inside it. Each strand has a random length and tapers to a point.
    float StrandDistance(float2 uv, float height, out float strandRandom)
    {
        float2 cellUV = uv * _Density;
        float2 cell = floor(cellUV);
        strandRandom = Hash12(cell);
        float strandLength = lerp(_MinLength, 1.0, strandRandom);
        float rootRadius = 0.5 * _Thickness;
        float2 center = 0.5 + (Hash22(cell + 17.0) - 0.5) * (1.0 - 2.0 * rootRadius) * _Jitter;
        float radius = rootRadius * (1.0 - height / strandLength);
        return radius - length(frac(cellUV) - center);
    }

    // The fraction of a cell the strands cover at this height, averaged over strand lengths
    // (uniform between _MinLength and 1): pi r^2 (1 - h/L)^2 integrated over L > h.
    float AverageCoverage(float height)
    {
        float a = max(height, max(_MinLength, 1e-3));
        float integral = (1.0 - a) - 2.0 * height * log(1.0 / a) + height * height * (1.0 / a - 1.0);
        float r = 0.5 * _Thickness;
        return PI * r * r * max(integral, 0.0) / max(1.0 - _MinLength, 1e-3);
    }

    // Exact strand coverage up close, fading to the average where a pixel spans whole strand
    // cells, so distant fur resolves to its density instead of aliasing into moire.
    float StrandCoverage(float2 uv, float height, out float strandRandom)
    {
        float d = StrandDistance(uv, height, strandRandom);
        if (height <= 0)
            return 1;
        float coverage = saturate(d / max(fwidth(d), 1e-5) + 0.5);
        // Cells per pixel, averaged over the footprint's axes so fur seen edge-on keeps its strands.
        float2 footprint2 = fwidth(uv * _Density);
        float footprint = sqrt(footprint2.x * footprint2.y);
        return lerp(coverage, AverageCoverage(height), saturate((footprint - 1.0) / 1.5));
    }

    void ClipStrand(float2 uv, float height)
    {
        float strandRandom;
        if (height > 0)
            clip(StrandDistance(uv, height, strandRandom));
    }
    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "TransparentCutout" "Queue" = "AlphaTest" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Cull Back
            ZWrite On
            AlphaToMask On

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fog
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 strandWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
                nointerpolation float height : TEXCOORD4;
                half fogFactor : TEXCOORD5;
            };

            Varyings Vertex(uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
            {
                Varyings o = (Varyings)0;
                if (_FurShellCount == 0)
                    return o;   // the skinned renderer's own draw (see ShellFur)
                FurVertex f = LoadFurVertex(vertexID, instanceID);
                o.positionCS = TransformWorldToHClip(f.positionWS);
                o.positionWS = f.positionWS;
                o.normalWS = f.normalWS;
                o.strandWS = f.strandWS;
                o.uv = f.uv;
                o.height = f.height;
                o.fogFactor = ComputeFogFactor(o.positionCS.z);
                return o;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
                // Strand coverage, antialiased over a pixel; alpha to coverage turns it into MSAA samples.
                float strandRandom;
                half coverage = StrandCoverage(i.uv, i.height, strandRandom);
                clip(coverage - 0.01);

                half3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, TRANSFORM_TEX(i.uv, _BaseMap)).rgb * _BaseColor.rgb;
                half occlusion = lerp(_RootOcclusion, 1.0, i.height);

                float3 N = normalize(i.normalWS);
                float3 T = normalize(i.strandWS);
                float3 V = GetWorldSpaceNormalizeViewDir(i.positionWS);
                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half attenuation = light.shadowAttenuation * light.distanceAttenuation;

                // Wrapped diffuse: light scatters through the fur past the terminator.
                half NdotL = dot(N, light.direction);
                half diffuse = saturate((NdotL + _Wrap) / (1.0 + _Wrap));

                // Kajiya-Kay: a white primary highlight along the strand and a broader,
                // albedo-tinted secondary one shifted toward the root, varied per strand.
                float3 H = normalize(light.direction + V);
                float TdotH = dot(T, H);
                half primary = smoothstep(-1.0, 0.0, TdotH) * pow(sqrt(saturate(1.0 - TdotH * TdotH)), _SpecularExponent);
                float shifted = clamp(TdotH - 0.25, -1.0, 1.0);
                half secondary = smoothstep(-1.0, 0.0, shifted) * pow(sqrt(saturate(1.0 - shifted * shifted)), _SpecularExponent * 0.25);
                half3 specular = (_SpecularColor.rgb * primary + albedo * secondary * (0.25 + 0.5 * strandRandom)) * _Specular * saturate(NdotL + 0.25);

                half3 color = albedo * occlusion * (diffuse * attenuation * light.color + SampleSH(N));
                color += specular * light.color * attenuation * occlusion;
                color = MixFog(color, i.fogFactor);
                return half4(color, coverage);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            Cull Back
            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                nointerpolation float height : TEXCOORD1;
            };

            Varyings Vertex(uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
            {
                Varyings o = (Varyings)0;
                if (_FurShellCount == 0)
                    return o;
                FurVertex f = LoadFurVertex(vertexID, instanceID);
                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirection = normalize(_LightPosition - f.positionWS);
                #else
                    float3 lightDirection = _LightDirection;
                #endif
                o.positionCS = TransformWorldToHClip(ApplyShadowBias(f.positionWS, f.normalWS, lightDirection));
                #if UNITY_REVERSED_Z
                    o.positionCS.z = min(o.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    o.positionCS.z = max(o.positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                o.uv = f.uv;
                o.height = f.height;
                return o;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
                ClipStrand(i.uv, i.height);
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }
            Cull Back
            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                nointerpolation float height : TEXCOORD1;
            };

            Varyings Vertex(uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
            {
                Varyings o = (Varyings)0;
                if (_FurShellCount == 0)
                    return o;
                FurVertex f = LoadFurVertex(vertexID, instanceID);
                o.positionCS = TransformWorldToHClip(f.positionWS);
                o.uv = f.uv;
                o.height = f.height;
                return o;
            }

            half Fragment(Varyings i) : SV_Target
            {
                ClipStrand(i.uv, i.height);
                return i.positionCS.z;
            }
            ENDHLSL
        }
    }
}
