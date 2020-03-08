Shader "Raymarching/Raymarching"
{
	Properties
	{
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)

		_Absortion("Absortion", Range(0.0, 20.0)) = 20.0
		_OutScattering("OutScattering", Range(0.0, 20.0)) = 0.2
		_Density("Density", Range(0.0, 0.1)) = 0.04

		[HideInInspector]
		_JitterEnabled("JitterEnabled", Range(0, 1)) = 1

		_Coverage("Coverage", Range(0.0, 0.5)) = 0.42
		_Octaves("Octaves", Int) = 8
		_Offset("Offset", Vector) = (0.0, 0.005, 0.0, 0.0)
		_Frequency("Frequency", Float) = 3.0
		_Lacunarity("Lacunarity", Float) = 3.0
		[HideInInspector]
		_Amplitude("Amplitude", Float) = 0.5
		[HideInInspector]
		_Persistence("Persistence", Float) = 0.5

		[HideInInspector]
		_SphereRadius("SphereRadius", Float) = 0.5
		[HideInInspector]
		_SpherePos("SpherePos", Vector) = (0.0, 0.0, 0.0)

		[HideInInspector]
		_FrameCount("FrameCount", Int) = 0.0
	}

	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha

		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Raymarching.cginc"
			#include "Lighting.cginc"

			float4 _Color;

			float _Absortion;
			float _OutScattering;
			float _Density;

			int _JitterEnabled;

			float _Coverage;
			int _Octaves;
			float3 _Offset;
			float _Frequency;
			float _Amplitude;
			float _Lacunarity;
			float _Persistence;

			float _SphereRadius;
			float3 _SpherePos;

			int _FrameCount;
	
			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 wPos : TEXCOORD0;
			};

			// vertex shader
			v2f vert (appdata v)
			{
				v2f o;
				
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.wPos = mul(unity_ObjectToWorld, v.vertex);

				return o;
			}

			// pixel shader
			float4 frag (v2f i) : SV_Target
			{
				float3 lightDir = _WorldSpaceLightPos0.xyz;

				float3 rayDir = normalize(i.wPos - _WorldSpaceCameraPos);
				float3 rayOrig = _WorldSpaceCameraPos;

				_FrameCount %= 8.0;
				float2 frameCount = float2(_FrameCount, -_FrameCount);
				float rayOffset = IGN(i.vertex.xy + frameCount);
									
				rayOrig += (rayDir * (rayOffset * FROMCAMSTEPSIZE)) * _JitterEnabled;

				// fill the info of perlin noise
				PerlinInfo perlinInfo;

				perlinInfo.cutOff = 1.0 - _Coverage;
				perlinInfo.octaves = _Octaves;
				perlinInfo.offset = _Offset * _Time.y;
				perlinInfo.freq = _Frequency;
				perlinInfo.amp = _Amplitude;
				perlinInfo.lacunarity = _Lacunarity;
				perlinInfo.persistence = _Persistence;

				// fill the info of the sphere
				SphereInfo sphereInfo;

				sphereInfo.pos = _SpherePos;
				sphereInfo.radius = _SphereRadius;

				// fill the cloud info
				CloudInfo cloudInfo;

				cloudInfo.absortion = _Absortion;
				cloudInfo.outScattering = _OutScattering;
				cloudInfo.density = _Density;

				// raymarching
				float4 o = march(rayOrig, rayDir, lightDir, perlinInfo, sphereInfo, cloudInfo);
				
				return float4(o.rgb * _LightColor0.rgb *_Color.rgb, 1.0 - o.a);
			}

			ENDCG
		}
	}
}