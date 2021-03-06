Shader "Portals/PortalShader"
{
	Properties
	{
	 _LeftTex("left tex", 2D) = "white" {}
	 _RightTex("right tex", 2D) = "white" {}
	 [Toggle] _RecursiveRender("recursive render", Float) = 0
	}

	SubShader {
		Tags { "LightMode" = "ForwardBase" }
		Pass {
			CGPROGRAM
			#include "UnityCG.cginc"

			// pragmas
			#pragma vertex vert
			#pragma fragment frag

			// make fog work
			#pragma multi_compile_fog

			// user defined variables
			uniform fixed _RecursiveRender;

			/// which eye we are rendering. 0 == left, 1 == right
			uniform int RenderingEye;
			uniform int OpenVRRender;


			sampler2D _LeftTex;

			// VR Only
			sampler2D _RightTex;

			// base input structs
			struct vertexInput {
				half4 vertex : POSITION;
				fixed3 normal : NORMAL;
				half4 texCoord : TEXCOORD0;
			};

			struct vertexOutput {
				half4 pos : SV_POSITION;
				half4 screenPos : TEXCOORD2;
				UNITY_FOG_COORDS(1)
			};

			// Same as standard ComputeScreenPos() except that it doesn't call TransformStereoScreenSpaceTex()
			// when stereo instance rendering is enabled. This is important because we need to be able to sample
			// from the entire reflection texture, and not just the left/right half, which is what the normal
			// ComputeScreenPos() would get us.
			inline half4 ComputeScreenPosIgnoreStereo(half4 pos) {
				half4 o = pos * 0.5f;
#if defined(UNITY_HALF_TEXEL_OFFSET)
				o.xy = half2(o.x, o.y*_ProjectionParams.x) + o.w * _ScreenParams.zw;
#else
				o.xy = half2(o.x, o.y*_ProjectionParams.x) + o.w;
#endif
				o.zw = pos.zw;
				return o;
			}

			// vertex shader
			vertexOutput vert(vertexInput v) {
				vertexOutput o;

				o.pos = UnityObjectToClipPos(v.vertex);
				//float2 uv = (o.pos.xy / o.pos.w) * 0.5f + 1;
				//o.screenPos = float4(uv, 0, 1);
				//o.screenPos = (o.pos.xy / o.pos.w) * 0.5f + 1;
				o.screenPos = ComputeScreenPos(o.pos); //ComputeScreenPos(o.pos);
				UNITY_TRANSFER_FOG(o,o.pos);

				return o;
			}

			// fragment shader
			float4 frag(vertexOutput i) : COLOR {
				float2 screenUV = i.screenPos.xy / i.screenPos.w;
				bool leftEye;

			#ifdef UNITY_SINGLE_PASS_STEREO
				leftEye = unity_StereoEyeIndex == 0;
			#else
				leftEye = (unity_CameraProjection[0][2] <= 0);
			#endif

			if (OpenVRRender) {
				leftEye = RenderingEye;
			}

			fixed4 col;
			if (leftEye || _RecursiveRender == 1) {
				col = tex2D(_LeftTex, screenUV);//  * float4(0, 0, 1, 1);
			}
			else {
				col = tex2D(_RightTex, screenUV);// * float4(1,1,0,1);
			}

			// apply fog
			UNITY_APPLY_FOG(i.fogCoord, col);
			return col;
		}

			ENDCG
		}
	}

}
