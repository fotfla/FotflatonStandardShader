sampler2D _Normal;
sampler2D _Metalic;
float _Smoothness;

struct GSOut
{
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 normal : NORMAL;
	float3 tangent : TANGENT;

	float3 bitangent : TEXCOORD3;
	float3 worldPos : TEXCOORD4;
	float3 worldNormal : TEXCOORD5;
	uint id : TEXCOORD6;
	
};

struct Surface {
	float4 Albedo;
	float4 Emission;
};

float3 NormalReCalc(float4 v0, float4 v1, float4 v2) {
	float3 v01 = normalize(v1.xyz - v0.xyz);
	float3 v02 = normalize(v2.xyz - v1.xyz);
	return normalize(cross(v01, v02));
}

void Shading(in GSOut IN, in Surface surf,inout float4 color) {

	//Reflection
	float3 normal = IN.normal;
	float3 tangent = IN.tangent;
	float3 bitangent = IN.bitangent;

	float3 tanToWorld0 = float3(tangent.x, bitangent.x, normal.x);
	float3 tanToWorld1 = float3(tangent.y, bitangent.y, normal.y);
	float3 tanToWorld2 = float3(tangent.z, bitangent.z, normal.z);

	float3 worldPos = IN.worldPos;
	float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

	float3 objectNormal = UnpackNormal(tex2D(_Normal, IN.uv));
	float4 Metalic = tex2D(_Metalic, IN.uv);

#ifndef USING_DIRECTIONAL_LIGHT
	fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
#else
	fixed3 lightDir = _WorldSpaceLightPos0.xyz;
#endif

	SurfaceOutputStandard o;
	UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
	o.Albedo = surf.Albedo;
	o.Emission = surf.Emission;
	o.Normal = fixed3(0,0,0);
	o.Metallic = Metalic;
	o.Smoothness = _Smoothness;
	o.Alpha = 1.0;
	o.Occlusion = 1.0;
	o.Normal = IN.worldNormal;

    float3 worldN;
	worldN.x = dot(tanToWorld0, objectNormal);
    worldN.y = dot(tanToWorld1, objectNormal);
    worldN.z = dot(tanToWorld2, objectNormal);
    worldN = normalize(worldN);
    o.Normal = worldN;

	UnityGI gi;
	UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
	gi.indirect.diffuse = 0;
	gi.indirect.specular = 0;
	gi.light.color = _LightColor0.rgb;
	gi.light.dir = lightDir;

	UnityGIInput giInput;
	UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
	giInput.light = gi.light;
	giInput.worldPos = worldPos;
	giInput.worldViewDir = worldViewDir;

	giInput.probeHDR[0] = unity_SpecCube0_HDR;
	giInput.probeHDR[1] = unity_SpecCube1_HDR;

#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
	giInput.boxMin[0] = unity_SpecCube0_BoxMin;
#endif
#if UNITY_SPECCUBE_BOX_PROJECTION
	giInput.boxMax[0] = unity_SpecCube0_BoxMax;
	giInput.probePosition[0] = unity_SpecCube0_ProbePosition;
	giInput.boxMax[1] = unity_SpecCube1_BoxMax;
	giInput.boxMin[1] = unity_SpecCube1_BoxMin;
	giInput.probePosition[1] = unity_SpecCube1_ProbePosition;
#endif

	LightingStandard_GI(o, giInput, gi);
	color += LightingStandard(o, worldViewDir, gi);
    color.rgb += o.Emission;
}