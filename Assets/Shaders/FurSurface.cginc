void vert(inout appdata_full v)
{
	// fur and swaying effect
    v.vertex.xyz = FurDisplacement(v.vertex.xyz, v.normal.xyz, _LayerIndex);
}

void surf (Input IN, inout SurfaceOutputStandard o) 
{
	// alpha steps
	half furData = 1.0f - (_LayerIndex * _LayerIndex);
	furData += dot(IN.viewDir, o.Normal) - _EdgeFade;
	furData *= _LayerIndex == 0.0 ? 1.0 : tex2D(_FurTex, IN.uv_FurTex).a;

	if(furData <= 0) { return; }

    // fake inter-strands occlusion
    half fakeShadow = lerp(_FakeOcclusion, 1.0, _LayerIndex);
    // pass values
	o.Albedo = _AlbedoColor * tex2D(_MainTex, IN.uv_MainTex) * fakeShadow;
	o.Metallic = _Metallic;
	o.Smoothness = _Glossiness;
	o.Alpha = furData;	
}