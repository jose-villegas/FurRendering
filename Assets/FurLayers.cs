using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Renderer))]
public class FurLayers : MonoBehaviour 
{
	public int layerCount = 20;

	MeshFilter meshFilter;
    Material[] materials;

	void Start() 
    {
        Material furMaterial = GetComponent<Renderer>().material;
		meshFilter = GetComponent<MeshFilter>();
        materials = new Material[layerCount];

        for(int i = 0; i < layerCount; i++)
        {
            materials[i] = new Material(furMaterial);
            materials[i].CopyPropertiesFromMaterial(furMaterial);
            materials[i].SetFloat("_LayerIndex", (float)i / (float)layerCount);
        }
	}

	void Update() 
    {
		var m = Matrix4x4.identity;
		m.SetTRS(transform.position, transform.rotation, transform.localScale);

		for (int i = 0; i < layerCount; i++) 
        {
            Graphics.DrawMesh(meshFilter.mesh, m, materials[i], 1);
		}
	}
}
