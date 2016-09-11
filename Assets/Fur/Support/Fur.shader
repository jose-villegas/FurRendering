Shader "Fur"
{
	Properties
	{
		_FurLength ("Fur Length", Range (.0002, 1)) = .25
		_MainTex ("Base (RGB)", 2D) = "white" { }
		_Cutoff ("Alpha Cutoff", Range (0, 1)) = .0001
		_EdgeFade ("Edge Fade", Range(0,1)) = 0.4
		_LightDirection0 ("Light Direction 0, Ambient", Vector) = (1,0,0,1)
		_MyLightColor0 ("Light Color 0", Color) = (1,1,1,1)
		_LightDirection1 ("Light Direction 1, Ambient", Vector) = (1,0,0,1)
		_MyLightColor1 ("Light Color 1", Color) = (1,1,1,1)
	}
	Category
	{
		ZWrite Off
		Tags {"Queue" = "Transparent"}
		Blend SrcAlpha OneMinusSrcAlpha
		Alphatest Greater [_Cutoff]
		SubShader
		{
			Pass
			{
				ZWrite On
				
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					constantColor(1,1,1,1)
					combine texture * primary double, constant
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.05, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.1, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.15, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.2, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.25, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.3, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.35, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.4, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.45, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.5, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.55, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.60, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.65, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.70, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.75, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.8, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.85, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.9, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
			Pass
			{
				CGPROGRAM
				// vertex VertexProgram
				#include "FurHelpers.cginc"

				v2f VertexProgram (appdata_base v)
				{
					v2f o;
					FurVertexPass(0.95, v, _FurLength, o.pos, o.fog, o.color, o.uv);	
					return o;
				}
				ENDCG
				SetTexture [_MainTex]
				{
					combine texture * primary double, texture * primary
				}
			}
		}
		Fallback " VertexLit", 1
	}
}
