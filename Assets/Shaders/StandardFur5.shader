Shader "Custom/Standard Fur (5 Layers)" 
{
	Properties 
	{
		_MainTex ("Albedo", 2D) = "white" {}
		_AlbedoColor ("Albedo Color", Color) = (1,1,1,1)
		_Glossiness ("Smoothness", Range(0, 1)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0.0

		_FurTex ("Fur Texture (RGBA)", 2D) = "white" {}
		_FurLength ("Fur Length", Range(0.0, 1.0)) = 1.0
		_Displacement ("Displacement", Vector) = (0.0, 0.0, 0, 1.0)
        _EdgeFade ("Edge Fade", Range(0.0, 1.0)) = 0.4
        _FakeOcclusion ("Fake Occlusion", Range(0.0, 1.0)) = 0.3
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.0
	}
	CGINCLUDE
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard vertex:vert fullforwardshadows alphatest:_Cutoff addshadow
		#pragma multi_compile FIXED LIN POW2 POW3 SINE
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
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
	ENDCG
	SubShader 
	{
		Tags { "RenderType" = "TransparentCutout" "Queue" = "Geometry" }
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite On
		Cull Off
		LOD 200
		
		CGPROGRAM
		#define _LayerIndex 0.0
		void vert(inout appdata_full v)
		{
			// fur and swaying effect
            v.vertex.xyz = FurDisplacement(v.vertex.xyz, v.normal.xyz, _LayerIndex);
		}
		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			// alpha steps
			half furData = 1.0f - (_LayerIndex * _LayerIndex);
			furData += dot(IN.viewDir, o.Normal) - _EdgeFade;
			furData *= _LayerIndex == 0.0 ? 1.0 : tex2D(_FurTex, IN.uv_FurTex).a;
            // fake inter-strands occlusion
            half fakeShadow = lerp(_FakeOcclusion, 1.0, _LayerIndex);
            // pass values
			o.Albedo = _AlbedoColor * tex2D(_MainTex, IN.uv_MainTex) * fakeShadow;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = furData;	
		}
		ENDCG
		ZWrite Off
		
		CGPROGRAM
		#define _LayerIndex 0.2
		void vert(inout appdata_full v)
		{
			// fur and swaying effect
            v.vertex.xyz = FurDisplacement(v.vertex.xyz, v.normal.xyz, _LayerIndex);
		}
		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			// alpha steps
			half furData = 1.0f - (_LayerIndex * _LayerIndex);
			furData += dot(IN.viewDir, o.Normal) - _EdgeFade;
			furData *= _LayerIndex == 0.0 ? 1.0 : tex2D(_FurTex, IN.uv_FurTex).a;
            // fake inter-strands occlusion
            half fakeShadow = lerp(_FakeOcclusion, 1.0, _LayerIndex);
            // pass values
			o.Albedo = _AlbedoColor * tex2D(_MainTex, IN.uv_MainTex) * fakeShadow;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = furData;	
		}
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.4
		void vert(inout appdata_full v)
		{
			// fur and swaying effect
            v.vertex.xyz = FurDisplacement(v.vertex.xyz, v.normal.xyz, _LayerIndex);
		}
		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			// alpha steps
			half furData = 1.0f - (_LayerIndex * _LayerIndex);
			furData += dot(IN.viewDir, o.Normal) - _EdgeFade;
			furData *= _LayerIndex == 0.0 ? 1.0 : tex2D(_FurTex, IN.uv_FurTex).a;
            // fake inter-strands occlusion
            half fakeShadow = lerp(_FakeOcclusion, 1.0, _LayerIndex);
            // pass values
			o.Albedo = _AlbedoColor * tex2D(_MainTex, IN.uv_MainTex) * fakeShadow;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = furData;	
		}
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.6
		void vert(inout appdata_full v)
		{
			// fur and swaying effect
            v.vertex.xyz = FurDisplacement(v.vertex.xyz, v.normal.xyz, _LayerIndex);
		}
		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			// alpha steps
			half furData = 1.0f - (_LayerIndex * _LayerIndex);
			furData += dot(IN.viewDir, o.Normal) - _EdgeFade;
			furData *= _LayerIndex == 0.0 ? 1.0 : tex2D(_FurTex, IN.uv_FurTex).a;
            // fake inter-strands occlusion
            half fakeShadow = lerp(_FakeOcclusion, 1.0, _LayerIndex);
            // pass values
			o.Albedo = _AlbedoColor * tex2D(_MainTex, IN.uv_MainTex) * fakeShadow;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = furData;	
		}
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.8
		void vert(inout appdata_full v)
		{
			// fur and swaying effect
            v.vertex.xyz = FurDisplacement(v.vertex.xyz, v.normal.xyz, _LayerIndex);
		}
		void surf (Input IN, inout SurfaceOutputStandard o) 
		{
			// alpha steps
			half furData = 1.0f - (_LayerIndex * _LayerIndex);
			furData += dot(IN.viewDir, o.Normal) - _EdgeFade;
			furData *= _LayerIndex == 0.0 ? 1.0 : tex2D(_FurTex, IN.uv_FurTex).a;
            // fake inter-strands occlusion
            half fakeShadow = lerp(_FakeOcclusion, 1.0, _LayerIndex);
            // pass values
			o.Albedo = _AlbedoColor * tex2D(_MainTex, IN.uv_MainTex) * fakeShadow;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = furData;	
		}
		ENDCG
	}

	FallBack "VertexLit"
	CustomEditor "FurShaderEditor"
}
