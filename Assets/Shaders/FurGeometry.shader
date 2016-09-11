Shader "Custom/Fur (Geometry)" 
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
        _Layers ("Layers" , Range(1.0, 120.0)) = 20
        _Displacement ("Displacement", Vector) = (0, -2.0, 0, 1.0)
        _FakeOcclusion ("Fake Occlusion", Range(0.0, 1.0)) = 0.3
    }

    CGINCLUDE
        #pragma multi_compile FIXED LIN POW2 POW3 SINE

        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        #include "Lighting.cginc"

        sampler2D _MainTex;
        sampler2D _FurTex;
        sampler2D _SpecularTex;
        half4 _MainTex_ST;
        float _FurLength;
        half4 _AlbedoColor;
        half4 _SpecularColor;
        float _Shininess;
        float _FakeOcclusion;
        float _Layers;
        half4 _Displacement;

        struct v2f 
        {
            half4 pos : SV_POSITION;
            half3 worldPos : WORLDPOSITION;
            half2 uv : TEXCOORD0;
            half3 normal : NORMAL;
            float layerIndex : LAYERINDEX;
        };
    ENDCG

    SubShader 
    {

        Tags { "RenderType" = "Opaque" "Queue" = "Transparent" "LightMode" = "ForwardBase" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass 
        {
    		ZWrite On
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            v2f vert(appdata_base v) 
            {
                v2f o = (v2f)0;
                // space transform
                o.worldPos = mul(_Object2World, v.vertex).xyz;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
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
                // fake inter-strands occlusion
                float shadow = _FakeOcclusion;
                // resulting pixel color
                return half4(furColor * shadow, 1.0f);
            }
            ENDCG
        }

        Pass 
        {
        	ZWrite Off
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom

            v2f vert(appdata_base v) 
            {
                v2f o = (v2f)0;
                // space transform
                o.pos = v.vertex;
                o.normal = v.normal;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            [maxvertexcount(75)]
            void geom(triangle v2f input[3], inout TriangleStream<v2f> OutputStream)
            {
                v2f o = (v2f)0;

                for(int layer = 1; layer < _Layers; layer++)
                {
                    for (int i = 0; i < 3; i++)
                    {
                        float layerIndex = float(layer) / _Layers;
                        half3 pos = input[i].pos + input[i].normal * _FurLength * layerIndex;
                        // swaying effect
                        #if !FIXED
                            half3 grav = mul(_Displacement, _World2Object).xyz;
                            // varying density functions
                            #if LIN
                                float k = layerIndex;
                            #endif
                            #if POW2
                                float k = pow(layerIndex, 2.0);
                            #endif
                            #if POW3
                                float k = pow(layerIndex, 3.0);
                            #endif
                            #if SINE
                                float k = sin(layerIndex);
                            #endif
                            pos = pos + grav * k;
                        #endif
                        // pass values to fragment shader
                        o.layerIndex = layerIndex;
                        o.pos = mul(UNITY_MATRIX_MVP, half4(pos, 1.0));
                        o.worldPos = mul(_Object2World, half4(pos, 1.0)).xyz;
                        o.uv = input[i].uv;
                        o.normal = UnityObjectToWorldNormal(input[i].normal);
                        OutputStream.Append(o);
                    }
                    OutputStream.RestartStrip();
                }
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
                furData.a = (i.layerIndex == 0.0) ? 1.0 : furData.a;
                // fake inter-strands occlusion
                float shadow = lerp(_FakeOcclusion, 1.0, i.layerIndex);
                // resulting pixel color
                return half4(furColor * shadow, furData.a);
            }
            ENDCG
        }
    }

	CustomEditor "FurShaderEditor"
}
