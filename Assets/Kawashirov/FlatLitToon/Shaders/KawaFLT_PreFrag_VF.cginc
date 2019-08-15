#ifndef KAWAFLT_PREFRAG_VF_INCLUDED
#define KAWAFLT_PREFRAG_VF_INCLUDED

#include ".\KawaFLT_Struct_VF.cginc"
#include ".\KawaFLT_Features_Lightweight.cginc"
#include ".\KawaFLT_PreFrag_Shared.cginc"

#include "UnityInstancing.cginc"
#include "KawaRND.cginc"

VERTEX_OUT vert(appdata_full v_in) {
	UNITY_SETUP_INSTANCE_ID(v_in);
	VERTEX_OUT v_out;
	UNITY_INITIALIZE_OUTPUT(VERTEX_OUT, v_out);
	UNITY_TRANSFER_INSTANCE_ID(v_in, v_out);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(v_out);

	half3 normal_obj = normalize(v_in.normal);

	v_out.uv0 = v_in.texcoord;
	
	fps_vertex(v_in, v_out);

	v_out.pos = UnityObjectToClipPos(v_in.vertex); 
	v_out.pos_world = mul(unity_ObjectToWorld, v_in.vertex);

	screencoords_fragment_in(v_out);
	
	#if defined(KAWAFLT_PASS_FORWARD)
		v_out.uv1 = v_in.texcoord1;

		// Тангентное-пространство в координатах 
		v_out.normal_world = normalize(UnityObjectToWorldNormal(normal_obj));
		half tangent_w = v_in.tangent.w; // Определяет леворукость/праворукость/зеркальность?
		half3 tangent_obj = normalize(v_in.tangent.xyz);
		half3 bitangent_obj = normalize(cross(normal_obj, tangent_obj) * tangent_w);

		// Тангентное-пространство в координатах мира
		v_out.tangent_world = normalize(UnityObjectToWorldDir(tangent_obj));
		v_out.bitangent_world = normalize(cross(v_out.normal_world, v_out.tangent_world) * tangent_w);

		#if defined(KAWAFLT_F_MATCAP_ON)
			// А почему в юнити нет UNITY_MATRIX_IT_V ? :thinking:
			half3x3 tangent_obj_basis = half3x3(tangent_obj, bitangent_obj, normal_obj);
			v_out.matcap_x = mul(tangent_obj_basis, half3(UNITY_MATRIX_IT_MV[0].xyz));
			v_out.matcap_y = mul(tangent_obj_basis, half3(UNITY_MATRIX_IT_MV[1].xyz));
		#endif

		bool vertexlight = false;
		#if defined(VERTEXLIGHT_ON)
			vertexlight = true;
		#endif
		float3 wsvd = KawaWorldSpaceViewDir(v_out.pos_world.xyz);
		kawaflt_fragment_in(v_out, /* compile-time */ vertexlight, wsvd);

		prefrag_transfer_shadow(v_in.vertex, v_out); // v_out.pos
		UNITY_TRANSFER_FOG(v_out, v_out.pos);
	#endif
	
	prefrag_shadowcaster_pos(v_in.vertex.xyz, normal_obj, v_out.pos);
	
	dstfade_frament_in(v_out);

	return v_out;
}

#endif // KAWAFLT_PREFRAG_VF_INCLUDED