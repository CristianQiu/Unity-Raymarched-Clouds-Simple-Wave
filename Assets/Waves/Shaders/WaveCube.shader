Shader "Unlit/WaveCube"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "ShaderUtils.cginc"

			struct appdata
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 color : COLOR;

				UNITY_FOG_COORDS(1)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;

				float4 zero = float4(0.0, 0.0, 0.0, 1.0);

				// world positions
				float4 vertexPos = mul(unity_ObjectToWorld, v.vertex);
				float4 worldObjectCenter = mul(unity_ObjectToWorld, zero);
				float3 camWorldPos = _WorldSpaceCameraPos;

				float3 xZVertexDistFromWorldOrigin = length(float2(vertexPos.xz));
				float3 xZObjectDistFromWorldOrigin = length(float2(worldObjectCenter.xz));

				// Note: every factor of 1.0 is there just cause it can be tweaked to vary the behaviours

				// rotation
				float t = _Time.w - (xZObjectDistFromWorldOrigin * 1.0);
				t = clamp(t, 0.0, t);

				float percSin = perc(-1.0, 1.0, sin(t));

				float3 rotation = float3(0.0, 0.0, 0.0);

				rotation.x = (worldObjectCenter.z / 20.0) * percSin;
				//rotation.x = (vertexPos.z / 20.0) * percSin;
				rotation.y = 0.0;
				rotation.z = -(worldObjectCenter.x / 20.0) * percSin;
				//rotation.z = -(vertexPos.x / 20.0) * percSin;

				// translation
				//t = _Time.w - (xZObjectDistFromWorldOrigin * 1.0);
				//t = clamp(t, 0.0, t);

				//percSin = perc(-1.0, 1.0, sin(t));

				float3 translation = float3(0.0, 0.0, 0.0);
				translation.y = percSin * 0.15 * xZObjectDistFromWorldOrigin;

				// scale
				float currScale = lerp(0.6, 0.9, percSin);

				// MATRICES

				float4x4 identity = float4x4
				(
					1.0, 0.0, 0.0, 0.0,
					0.0, 1.0, 0.0, 0.0,
					0.0, 0.0, 1.0, 0.0,
					0.0, 0.0, 0.0, 1.0
				);

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

				float4x4 transMat = float4x4
				(
					1.0, 0.0, 0.0, translation.x,
					0.0, 1.0, 0.0, translation.y,
					0.0, 0.0, 1.0, translation.z,
					0.0, 0.0, 0.0, 1.0
				);

				float4x4 scaleMat = float4x4
				(
					currScale, 0.0, 0.0, 0.0,
					0.0, currScale, 0.0, 0.0,
					0.0, 0.0, currScale, 0.0,
					0.0, 0.0, 0.0, 1.0
				); 

				float4x4 rotMat = mul(rotZMat, rotXMat);
				rotMat = mul(rotMat, rotYMat);

				float4x4 modelMatrix = mul(unity_ObjectToWorld, rotMat);
				modelMatrix = mul(modelMatrix, scaleMat);
				modelMatrix = mul(modelMatrix, transMat);

				float4x4 mv = mul(UNITY_MATRIX_V, modelMatrix);
				float4x4 mvp = mul(UNITY_MATRIX_P, mv);

				o.vertex = mul(mvp, v.vertex);

				float4 col = float4(v.color.r * (1.0 - percSin), v.color.g * (-percSin * 0.5), v.color.b * percSin, 1.0);

				o.color = col;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
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