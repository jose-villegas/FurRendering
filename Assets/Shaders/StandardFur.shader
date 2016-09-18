Shader "Custom/Standard Fur (Needs Script)"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _AlbedoColor ("Albedo Color", Color) = (1, 1, 1, 1)
        _Glossiness ("Smoothness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0, 1)) = 0.0

        _FurTex ("Fur Texture (RGBA)", 2D) = "white" {}
        _FurLength ("Fur Length", Range(0.0, 1.0)) = 1.0
        _Displacement ("Displacement", Vector) = (0.0, 0.0, 0, 1.0)
        _EdgeFade ("Edge Fade", Range(0.0, 1.0)) = 0.4
        _FakeOcclusion ("Fake Occlusion", Range(0.0, 1.0)) = 0.3
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.0

        [HideInInspector] _ZWrite ("__ZWrite", Float) = 1.0
        [HideInInspector] _LayerIndex ("__LayerIndex", Float) = 0.0
    }
    CGINCLUDE
        #pragma surface surf Standard vertex:vert fullforwardshadows alphatest:_Cutoff addshadow
        #pragma multi_compile FIXED LIN POW2 POW3 SINE
        #pragma target 3.0

        half _LayerIndex;
        #include "FurCommons.cginc"
    ENDCG
    SubShader
    {
        Tags { "RenderType" = "TransparentCutout" "Queue" = "Geometry" "IgnoreProjector"="True" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite [_ZWrite]
        Cull Off
        LOD 200

        CGPROGRAM
        #include "FurSurface.cginc"
        ENDCG
    }

    FallBack "VertexLit"
    CustomEditor "FurShaderEditor"
}
