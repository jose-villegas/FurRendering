using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Renderer))]
public class FurLayers : MonoBehaviour 
{
    [SerializeField]
	private int _layerCount = 20;

    private Material[] _materials;
    private Matrix4x4 _matrix;
    private Mesh _mesh = null;
    private Material _furMaterial;

    private void Start() 
    {
        _furMaterial = GetComponent<Renderer>().sharedMaterial;
        _mesh = GetComponent<MeshFilter>().sharedMesh;
        _materials = new Material[_layerCount];

        for(int i = 0; i < _layerCount; i++)
        {
            _materials[i] = new Material(_furMaterial);
            _materials[i].CopyPropertiesFromMaterial(_furMaterial);
            _materials[i].SetFloat("_LayerIndex", (float)i / (float)_layerCount);
            _materials[i].SetFloat("_ZWrite", i == 0 ? 1.0f : 0.0f);
            _materials[i].renderQueue = 3000 + i;
        }

        _matrix = Matrix4x4.identity;
        _matrix.SetTRS(transform.position, transform.rotation, transform.localScale);
	}

	private void Update() 
    {
        if(_layerCount != _materials.Length)
        {
            _materials = new Material[_layerCount];
        }

		for (int i = 0; i < _layerCount; i++) 
        {
            if(_materials[i] == null)
            {
                _materials[i] = new Material(_furMaterial);
            }

            // update material
            _materials[i].CopyPropertiesFromMaterial(_furMaterial);
            _materials[i].SetFloat("_LayerIndex", (float)i / (float)_layerCount);
            _materials[i].SetFloat("_ZWrite", i == 0 ? 1.0f : 0.0f);
            _materials[i].renderQueue = 3000 + i;
            // draw shell mesh
            Graphics.DrawMesh(_mesh, _matrix, _materials[i], 1);
		}
	}
}
