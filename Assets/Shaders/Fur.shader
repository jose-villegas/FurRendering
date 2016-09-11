Shader "Custom/Fur" 
{
    Properties 
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _AlbedoColor("Albedo Color", Color) = (1, 1, 1, 1)
        _SpecularTex ("Specular", 2D) = "white" {}
        _SpecularColor("Specular Color", Color) = (0, 0, 0, 0)
        _Shininess ("Shininess", Float) = 10
        _FurTex ("Fur Texture (RGBA)", 2D) = "white" {}
        _EdgeFade ("Edge Fade", Range(0.0, 1.0)) = 0.4
        _FurLength ("Fur Length", Range(0.0, 1.0)) = 1.0
        _Displacement ("Displacement", Vector) = (0, -2.0, 0, 1.0)
        _FakeOcclusion ("Fake Occlusion", Range(0.0, 1.0)) = 0.3
        [HideInInspector] _ZWrite ("__ZWrite", Float) = 1.0
    }

    CGINCLUDE
        #pragma multi_compile FIXED LIN POW2 POW3 SINE

        float _FurLength;
        float _LayerIndex;
        half4 _Displacement;

        half3 FurEffect(float3 position, float3 normal)
        {
            half3 pos = position + normal * _FurLength * _LayerIndex;

            // swaying effect
            #if !FIXED
                half3 grav = mul(_Displacement, _World2Object).xyz;
                float k = 0;
                // varying density functions
                #if LIN
                    k = _LayerIndex;
                #endif
                #if POW2
                    k = pow(_LayerIndex, 2.0);
                #endif
                #if POW3
                    k = pow(_LayerIndex, 3.0);
                #endif
                #if SINE
                    k = sin(_LayerIndex);
                #endif
                pos = pos + grav * k;
            #endif

            return pos;
        }
    ENDCG

    SubShader 
    {
        Tags { "Queue" = "Transparent" }
        LOD 200

        Pass 
        {
            Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
            Cull Off
            ZWrite [_ZWrite]
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            sampler2D _FurTex;
            sampler2D _SpecularTex;
            half4 _MainTex_ST;
            half4 _AlbedoColor;
            half4 _SpecularColor;
            float _Shininess;
            float _EdgeFade;
            float _FakeOcclusion;

            struct v2f 
            {
                half4 pos : SV_POSITION;
                half3 worldPos : WORLDPOSITION;
                half2 uv : TEXCOORD0;
                half3 normal : TEXCOORD1;
                half3  lightDir : TEXCOORD2;
                half3 viewDir : VIEWDIRECTION;
                LIGHTING_COORDS(3,4)
            };

            half3 FurColor(v2f i)
            {
                half4 albedo = tex2D(_MainTex, i.uv) * _AlbedoColor;
                half3 ambient = ShadeSH9(half4(i.normal, 1.0)) * albedo;
                half4 specular = tex2D(_SpecularTex, i.uv) * _SpecularColor;
                fixed attenuation = LIGHT_ATTENUATION(i); 
                half3 lightDir = normalize(i.lightDir);
                // lambertian model
                float nDotL = dot(i.normal, lightDir);
                // diffuse color lambert
                albedo.rgb *= _LightColor0.rgb * max(0.0, nDotL);
                // specular color- half vector for blinn specular
                half3 H = normalize(lightDir + i.viewDir);
                // schlick approximation for specular fresnel
                float w = pow(1.0 - max(0.0, dot(H, i.viewDir)), 5.0);
                // specular intensity
                specular.rgb = _LightColor0.rgb * lerp(specular.rgb, half3(1, 1, 1), w);
                specular.rgb *= pow(max(0.0, dot(H, i.normal)), _Shininess);
                // lighting composite
                return ambient.rgb + (albedo.rgb + specular.rgb) * attenuation;
            }

            v2f vert(appdata_base v) 
            {
                v2f o = (v2f)0;
                // fur and swaying effect
                half3 pos = FurEffect(v.vertex, v.normal);
                // space transform
                o.worldPos = mul(_Object2World, half4(pos, 1.0)).xyz;
                o.pos = mul(UNITY_MATRIX_MVP, half4(pos, 1.0));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - o.worldPos);
                // lighting info
                o.lightDir = ObjSpaceLightDir(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o); 
                // output vertex
                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
                // shading
                half3 furColor = FurColor(i);
                // alpha steps
                float furData = 1.0 - (_LayerIndex * _LayerIndex);
                furData += dot(i.viewDir, i.normal) - _EdgeFade;
                furData *= _LayerIndex == 0.0 ? 1.0 : tex2D(_FurTex, i.uv).a;
                // fake inter-strands occlusion
                float shadow = lerp(_FakeOcclusion, 1.0, _LayerIndex);
                // resulting pixel color
                furColor = furColor * shadow;
                return half4(furColor, furData);
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o = (v2f)0;
                // fur and swaying effect
                half3 pos = FurEffect(v.vertex, v.normal);
                o.pos = mul(UNITY_MATRIX_MVP, half4(pos, 1.0));
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }

	CustomEditor "FurShaderEditor"
}
