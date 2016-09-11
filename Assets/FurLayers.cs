using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Renderer))]
public class FurLayers : MonoBehaviour 
{
	public int layerCount = 20;

	MeshFilter meshFilter;
    Material[] materials;
    Matrix4x4[] matrices;

	void Start() 
    {
        Material furMaterial = GetComponent<Renderer>().material;
		meshFilter = GetComponent<MeshFilter>();
        materials = new Material[layerCount];
        matrices = new Matrix4x4[layerCount];

        for(int i = 0; i < layerCount; i++)
        {
            materials[i] = new Material(furMaterial);
            materials[i].CopyPropertiesFromMaterial(furMaterial);
            materials[i].SetFloat("_LayerIndex", (float)i / (float)layerCount);
            materials[i].SetFloat("_ZWrite", i == 0 ? 1.0f : 0.0f);
            materials[i].renderQueue = 3000 + i;
            matrices[i] = Matrix4x4.identity;
            matrices[i].SetTRS(transform.position, transform.rotation, transform.localScale);

        }
	}

	void Update() 
    {
		for (int i = 0; i < layerCount; i++) 
        {
            Graphics.DrawMesh(meshFilter.mesh, matrices[i], materials[i], 1);
		}
	}
}
