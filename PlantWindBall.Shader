Shader "Plant/PlantWindBall"
{
    Properties
    {
		_MainTex("MainTex", 2D) = "white" {}
		_hmin("hmin", Range(0 , 1)) = 0
		_hmax("hmax", Range(0 , 1)) = 1
		_hOffset("hOffset", Range(-1 , 1)) = 0
		_vmin("vmin", Range(0 , 1)) = 0
		_vmax("vmax", Range(0 , 1)) = 1
		_vOffset("vOffset", Range(-5 , 5)) = 0
		_topCol("topCol", Color) = (0,1,0,0)
		_windOffset("windOffset", Vector) = (0,0,0,0)
		_bottomCol("bottomCol", Color) = (0,0,0,0)
		_roleMul("roleMul", Range(0 , 10)) = 0
		_roleHOffset("roleHOffset", Range(0 , 10)) = 0
    }
    SubShader
    {
		Tags{"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
		Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			//要使用GPU Instancing必须加上这句
			#pragma multi_compile_instancing
			#include "UnityShaderVariables.cginc"
			#pragma target 3.0
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				//要使用GPU Instancing必须加上这句
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {                
                float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 centerPos : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 hvVal : TEXCOORD3;
				//要使用GPU Instancing必须加上这句
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			uniform float _hmin;
			uniform float _hmax;
			uniform float _vmin;
			uniform float _vmax;
			uniform float _vOffset;
			uniform float2 _windOffset;
			uniform float3 rolePos;
			uniform float _roleMul;
			uniform float _hOffset;
			uniform float _roleHOffset;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _topCol;
			uniform float4 _bottomCol;
			SamplerState sampler_MainTex;

            v2f vert (appdata v)
            {
                v2f o;
				//要使用GPU Instancing必须加上这句
				UNITY_SETUP_INSTANCE_ID(v);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.centerPos = mul(unity_ObjectToWorld, float4(float3(0, 0, 0), 1)).xyz;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				float hVal = smoothstep(_hmin, _hmax, o.worldPos.y - o.centerPos.y);
				float vVal = smoothstep(_vmin, _vmax, distance(o.worldPos.xz, o.centerPos.xz));
				float hvVal = hVal * vVal;
				o.hvVal = float3(hVal, vVal, hvVal);
				float hVertexOffset = hvVal * _hOffset;
				float2 vVertexOffset = (o.worldPos.xz - o.centerPos.xz)*hvVal*_vOffset;
				float2 wind = _windOffset * hVal*_SinTime.w;
				float roleDis = (1 - distance(o.worldPos.xz, rolePos.xz));
				float2 roleNor = (o.worldPos.xz - rolePos.xz)*step(0, roleDis)*(roleDis*_roleMul);
				float2 rolePosXZOffset = vVertexOffset + wind * (1 - roleNor) + roleNor * hVal;
				float rolePosYOffset = hVertexOffset - saturate(roleDis*_roleHOffset);
				o.pos = UnityObjectToClipPos(v.vertex+float3(rolePosXZOffset.x, rolePosYOffset, rolePosXZOffset.y));
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
				//要使用GPU Instancing必须加上这句
				UNITY_SETUP_INSTANCE_ID(i);
                // sample the texture
                half4 col = tex2D(_MainTex, i.uv);
				half3 finalCol = col.rgb * _topCol.rgb*i.hvVal.z + col.rgb;
				finalCol = clamp(finalCol*i.hvVal.x + _bottomCol * (1 - i.hvVal.x)*finalCol,  half3(0, 0, 0), half3(1, 1, 1));
				half alpha = col.a;
				clip(alpha - 0.5);
                return half4(finalCol,alpha);
            }
            ENDCG
        }
		
		//为了产生影子，加多一个pass，不过在大量渲染的情况下，不建议加阴影，性能实在差
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				//要使用GPU Instancing必须加上这句
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 centerPos : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 hvVal : TEXCOORD3;
				//要使用GPU Instancing必须加上这句
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			uniform float _hmin;
			uniform float _hmax;
			uniform float _vmin;
			uniform float _vmax;
			uniform float _vOffset;
			uniform float2 _windOffset;
			uniform float3 rolePos;
			uniform float _roleMul;
			uniform float _hOffset;
			uniform float _roleHOffset;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _topCol;
			uniform float4 _bottomCol;
			SamplerState sampler_MainTex;

			v2f vert(appdata v)
			{
				v2f o;
				//要使用GPU Instancing必须加上这句
				UNITY_SETUP_INSTANCE_ID(v);

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.centerPos = mul(unity_ObjectToWorld, float4(float3(0, 0, 0), 1)).xyz;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				float hVal = smoothstep(_hmin, _hmax, o.worldPos.y - o.centerPos.y);
				float vVal = smoothstep(_vmin, _vmax, distance(o.worldPos.xz, o.centerPos.xz));
				float hvVal = hVal * vVal;
				o.hvVal = float3(hVal, vVal, hvVal);
				float hVertexOffset = hvVal * _hOffset;
				float2 vVertexOffset = (o.worldPos.xz - o.centerPos.xz)*hvVal*_vOffset;
				float2 wind = _windOffset * hVal*_SinTime.w;
				float roleDis = (1 - distance(o.worldPos.xz, rolePos.xz));
				float2 roleNor = (o.worldPos.xz - rolePos.xz)*step(0, roleDis)*(roleDis*_roleMul);
				float2 rolePosXZOffset = vVertexOffset + wind * (1 - roleNor) + roleNor * hVal;
				float rolePosYOffset = hVertexOffset - saturate(roleDis*_roleHOffset);
				o.pos = UnityObjectToClipPos(v.vertex + float3(rolePosXZOffset.x, rolePosYOffset, rolePosXZOffset.y));
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				//要使用GPU Instancing必须加上这句
				UNITY_SETUP_INSTANCE_ID(i);
			// sample the texture
			half4 col = tex2D(_MainTex, i.uv);
			clip(col.a - 0.5);
			return col;
		}
			ENDCG

		}
		
    }
}
