Shader "Custom/Standard Fur (10 Layers)" 
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
		#pragma surface surf Standard vertex:vert fullforwardshadows alphatest:_Cutoff addshadow
		#pragma multi_compile FIXED LIN POW2 POW3 SINE
		#pragma target 3.0
		#include "FurCommons.cginc"
	ENDCG
	SubShader 
	{
		Tags { "RenderType" = "TransparentCutout" "Queue" = "Geometry" "IgnoreProjector"="True" }
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite On
		LOD 200
		
		CGPROGRAM
		#define _LayerIndex 0.0
		#include "FurSurface.cginc"
		ENDCG

		ZWrite Off
		
		CGPROGRAM
		#define _LayerIndex 0.1
		#include "FurSurface.cginc"
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.2
		#include "FurSurface.cginc"
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.3
		#include "FurSurface.cginc"
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.4
		#include "FurSurface.cginc"
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.5
		#include "FurSurface.cginc"
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.6
		#include "FurSurface.cginc"
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.7
		#include "FurSurface.cginc"
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.8
		#include "FurSurface.cginc"
		ENDCG
		
		CGPROGRAM
		#define _LayerIndex 0.9
		#include "FurSurface.cginc"
		ENDCG
	}

	FallBack "VertexLit"
	CustomEditor "FurShaderEditor"
}
