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
        _FurLength ("Fur Length", Range(0.0, 1.0)) = 1.0
        _Displacement ("Displacement", Vector) = (0, -2.0, 0, 1.0)
        _FakeOcclusion ("Fake Occlusion", Range(0.0, 1.0)) = 0.3
        [HideInInspector] _ZWrite ("__ZWrite", Float) = 1.0
    }

    SubShader 
    {

        Tags { "RenderType" = "Opaque" "Queue" = "Transparent" "LightMode" = "ForwardBase" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite [_ZWrite]

        Pass 
        {
            CGPROGRAM
            #pragma multi_compile FIXED LIN POW2 POW3 SINE
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            sampler2D _FurTex;
            sampler2D _SpecularTex;
            half4 _MainTex_ST;
            float _FurLength;
            float _LayerIndex;
            half4 _AlbedoColor;
            half4 _SpecularColor;
            float _Shininess;
            float _FakeOcclusion;
            half4 _Displacement;

            struct v2f 
            {
                half4 pos : SV_POSITION;
                half3 worldPos : WORLDPOSITION;
                half2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            v2f vert(appdata_base v) 
            {
                v2f o = (v2f)0;
                half3 pos = v.vertex + v.normal * _FurLength * _LayerIndex;
                // swaying effect
                #if !FIXED
	                half3 grav = mul(_Displacement, _World2Object).xyz;
	                // varying density functions
	                #if LIN
	                	float k = _LayerIndex;
	                #endif
	                #if POW2
	                	float k = pow(_LayerIndex, 2.0);
	                #endif
	                #if POW3
	                	float k = pow(_LayerIndex, 3.0);
	               	#endif
	                #if SINE
	                	float k = sin(_LayerIndex);
	               	#endif
	                pos = pos + grav * k;
                #endif
                // space transform
                o.worldPos = mul(_Object2World, half4(pos, 1.0)).xyz;
                o.pos = mul(UNITY_MATRIX_MVP, half4(pos, 1.0));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
            {
                half4 albedo = tex2D(_MainTex, i.uv) * _AlbedoColor;
                half3 ambient = ShadeSH9(half4(i.normal, 1.0)) * albedo;
                half4 specular = tex2D(_SpecularTex, i.uv) * _SpecularColor;
                half3 lightDir;
   
				if (0.0 == _WorldSpaceLightPos0.w) // directional light?
				{
					lightDir = normalize(_WorldSpaceLightPos0.xyz);
				}
				else // point light or spot
				{
					lightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
				}

				float nDotL = dot(i.normal, lightDir);
				albedo.rgb *= _LightColor0.rgb * max(0.0, nDotL);

                if(nDotL > 0.0)
                {
                    half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                    // half vector for blinn specular
                    half3 H = normalize(lightDir + viewDir);
                    // specular intensity
                    specular.rgb *= _LightColor0.rgb * pow(saturate(dot(H, i.normal)), _Shininess);
                }

                half3 furColor = ambient.rgb + albedo.rgb + specular.rgb;
                half4 furData = tex2D(_FurTex, i.uv);
                furData.a = (_LayerIndex == 0.0) ? 1.0 : furData.a;
                // fake inter-strands occlusion
                float shadow = lerp(_FakeOcclusion, 1.0, _LayerIndex);
                // resulting pixel color
                return half4(furColor * shadow, furData.a);
            }
            ENDCG
        }
    }

	CustomEditor "FurShaderEditor"
}
