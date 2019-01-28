Shader "fotfla/FotflatonStandardShaderBase"
{
	Properties
	{
		_MainTex("Albedo", 2D) = "white" {}
		_AlbedoColor("Color",Color) = (1,1,1,1)
		_Metalic("Metalic",2D) = "white" {}
		_Smoothness("Smoothness", Range(0.0,1.0)) = 1
		[Normal]_Normal("Normal",2D) = "white"{}
		_Emission("Emission",2D) = "white" {}
		_EmissionColor("Emission Color",Color) =(1,1,1,1)
		_Intensity("Intensity",float) = 0
	}
	SubShader
	{	
		Pass
		{
		Tags{ "LightMode" = "ForwardBase" }

		Cull off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geo

			#include "UnityCG.cginc"
			#include "Lighting.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

	struct v2g
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
		float3 normal : NORMAL;
		float4 tangent : TANGENT;
	};

	struct g2f
	{

		float4 vertex : SV_POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : NORMAL;
		float3 tangent : TANGENT;
		float3 bitangent : TEXCOORD4;
		float3 worldPos : TEXCOORD3;

	};

			sampler2D _MainTex;
			float4 _AlbedoColor;
			sampler2D _Metalic;
			float _Smoothness;
			sampler2D _Normal;
			sampler2D _Emission;
			float4 _EmissionColor;
			float _Intensity;

			float3 NormalReCalc(float4 v0, float4 v1, float4 v2) {
				float3 v01 = normalize(v1.xyz - v0.xyz);
				float3 v02 = normalize(v2.xyz - v0.xyz);
				return cross(v01, v02);
			}

			v2g vert (appdata v)
			{
				v2g o;
				float4 p = v.vertex;
				o.vertex = p;
				o.normal = v.normal;
				o.tangent = v.tangent;
				o.uv = v.uv;
				return o;
			}

			[maxvertexcount(6)]
			void geo(triangle v2g input[3], inout TriangleStream<g2f> outStream)
			{
				g2f o;

				float3 n = NormalReCalc(input[0].vertex, input[1].vertex, input[2].vertex);

				float2 uv = input[0].uv;

				for (int i = 0; i < 3; i++) {

					float4 v = input[i].vertex;
					o.vertex = UnityObjectToClipPos(v);
					o.worldPos = mul(unity_ObjectToWorld, v);
					o.normal = UnityObjectToWorldNormal(n);
					o.tangent = UnityObjectToWorldDir(input[i].tangent);
					float tangentSign = input[i].tangent.w * unity_WorldTransformParams.w;
					o.bitangent = cross(o.normal, o.tangent) *tangentSign;
					o.uv = input[i].uv;

					outStream.Append(o);
				}

				outStream.RestartStrip();
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				float2 uv = i.uv;

				//Albedo
				fixed4 col = tex2D(_MainTex, uv) * _AlbedoColor;

				//Reflection
				float3 normal = i.normal;
				float3 tangent = i.tangent;
				float3 bitangent = i.bitangent;

				float3 tanToWorld0 = float3(tangent.x, bitangent.x, normal.x);
				float3 tanToWorld1 = float3(tangent.y, bitangent.y, normal.y);
				float3 tanToWorld2 = float3(tangent.z, bitangent.z, normal.z);

				float3 objectNormal = tex2D(_Normal, uv);
				float4 Metalic = tex2D(_Metalic, uv);

				float3 worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

				UnityGIInput data;
				UNITY_INITIALIZE_OUTPUT(UnityGIInput, data);
				data.worldPos = i.worldPos;
				data.worldViewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
				data.probeHDR[0] = unity_SpecCube0_HDR;
				data.probeHDR[1] = unity_SpecCube1_HDR;

#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
				data.boxMin[0] = unity_SpecCube0_BoxMin;
#endif
#if UNITY_SPECCUBE_BOX_PROJECTION
				data.boxMax[0] = unity_SpecCube0_BoxMax;
				data.probePosition[0] = unity_SpecCube0_ProbePosition;
				data.boxMax[1] = unity_SpecCube1_BoxMax;
				data.boxMin[1] = unity_SpecCube1_BoxMin;
				data.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif
				Unity_GlossyEnvironmentData g3 = UnityGlossyEnvironmentSetup(Metalic.r * _Smoothness, worldViewDir, float3(dot(tanToWorld0, objectNormal), dot(tanToWorld1, objectNormal), dot(tanToWorld2, objectNormal)), float3(0, 0, 0));
				float3 indirectSpecular = UnityGI_IndirectSpecular(data, 1.7, float3(dot(tanToWorld0, objectNormal), dot(tanToWorld1, objectNormal), dot(tanToWorld2, objectNormal)), g3);

				col.xyz += indirectSpecular;

				//Light
				col.xyz *= ShadeSH9(half4(0, 0, 0, 1));

				//Emission
				fixed4 emission = tex2D(_Emission, i.uv);
				col = lerp(col, emission * _Intensity  * _EmissionColor, emission);
				
			return col;
			}
			ENDCG
		}
	}
}
