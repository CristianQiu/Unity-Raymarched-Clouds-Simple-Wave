Shader "Unlit/WaveObject"
{
	Properties
	{
		[HideInInspector] _FurthestObjectDistance("", Float) = 50.0

		_OriginColor("OriginColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_EndColor("EndColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_BottomColor("BottomColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_TopColor("TopColor", Color) = (1.0, 1.0, 1.0, 1.0)

		_TranslationIntensity("TranslationIntensity", Float) = 0.5
		_RotationIntensity("RotationIntensity", Range(0.0, 2.0)) = 0.0
		_MinScale("MinScale", Range(0.0, 1.0)) = 0.05
		_MaxScale("MaxScale", Range(0.0, 2.0)) = 0.4
	}

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_instancing // Adds instancing: https://docs.unity3d.com/Manual/GPUInstancing.html?_ga=2.121013825.818621639.1599668057-593361580.1599668057

			#include "UnityCG.cginc"

			float _FurthestObjectDistance;
			
			float4 _OriginColor;
			float4 _EndColor;
			float4 _BottomColor;
			float4 _TopColor;

			float _TranslationIntensity;
			float _RotationIntensity;
			float _MinScale;
			float _MaxScale;

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 color : COLOR;

				UNITY_FOG_COORDS(1)
			};

			v2f vert (appdata v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);

				// object center
				float4 zero = float4(0.0, 0.0, 0.0, 1.0);
				float4 worldObjectCenter = mul(unity_ObjectToWorld, zero);

				// animation
				float3 xzDistFromWorldOrigin = length(float2(worldObjectCenter.xz));
				float xzDist01 = xzDistFromWorldOrigin / _FurthestObjectDistance;
				
				float t = _Time.y + (_FurthestObjectDistance - xzDistFromWorldOrigin);
				float sin01 = (sin(t) + 1.0) * 0.5;

				// translation
				float yTrans = sin01 * _TranslationIntensity;
				float3 translation = float3(0.0, yTrans, 0.0);

				// rotation
				float xRot = (worldObjectCenter.z / 10.0) * sin01 * _RotationIntensity;
				float zRot = -(worldObjectCenter.x / 10.0) * sin01 * _RotationIntensity;
				float3 rotation = float3(xRot, 0.0, zRot);

				// scale
				float scale = lerp(_MinScale, _MaxScale, sin01);

				// matrices
				float4x4 rotXMat = float4x4
				(
					1.0, 0.0, 0.0, 0.0,
					0.0, cos(rotation.x), -sin(rotation.x), 0.0,
					0.0, sin(rotation.x), cos(rotation.x), 0.0,
					0.0, 0.0, 0.0, 1.0
				);
				float4x4 rotYMat = float4x4
				(
					cos(rotation.y), 0.0, sin(rotation.y), 0.0,
					0.0, 1.0, 0.0, 0.0,
					-sin(rotation.y), 0.0, cos(rotation.y), 0.0,
					0.0, 0.0, 0.0, 1.0
				); 
				float4x4 rotZMat = float4x4
				(
					cos(rotation.z), -sin(rotation.z), 0.0, 0.0,
					sin(rotation.z), cos(rotation.z), 0.0, 0.0,
					0.0, 0.0, 1.0, 0.0,
					0.0, 0.0, 0.0, 1.0
				); 

				float4x4 scaleMat = float4x4
				(
					scale, 0.0, 0.0, 0.0,
					0.0, scale, 0.0, 0.0,
					0.0, 0.0, scale, 0.0,
					0.0, 0.0, 0.0, 1.0
				); 

				float4x4 transMat = float4x4
				(
					1.0, 0.0, 0.0, translation.x,
					0.0, 1.0, 0.0, translation.y,
					0.0, 0.0, 1.0, translation.z,
					0.0, 0.0, 0.0, 1.0
				);

				float4x4 rotMat = mul(rotZMat, rotXMat);
				rotMat = mul(rotMat, rotYMat);

				float4x4 modelMatrix = mul(unity_ObjectToWorld, rotMat);
				modelMatrix = mul(modelMatrix, scaleMat);
				modelMatrix = mul(modelMatrix, transMat);

				float4x4 mv = mul(UNITY_MATRIX_V, modelMatrix);
				float4x4 mvp = mul(UNITY_MATRIX_P, mv);

				float4 col = lerp(_OriginColor, _EndColor, xzDist01);
				float4 sinColor = lerp(_BottomColor, _TopColor, sin01);
				col += sinColor;
				col *= 0.5;
				col.a = 1.0;

				o.vertex = mul(mvp, v.vertex);
				o.color = col;

				UNITY_TRANSFER_FOG(o,o.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = i.color.rgba;
				
				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}

			ENDCG
		}
	}
}