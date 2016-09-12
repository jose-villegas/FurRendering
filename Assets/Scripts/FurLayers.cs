using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Renderer)), ExecuteInEditMode]
public class FurLayers : MonoBehaviour 
{
    [SerializeField, Range(0, 80)]
	private int _layerCount = 20;

    private GameObject[] _layers;
    private Material[] _materials;
    private Mesh _mesh = null;
    private Material _furMaterial;

    private void Start() 
    {
        _furMaterial = GetComponent<Renderer>().sharedMaterial;
        _mesh = GetComponent<MeshFilter>().sharedMesh;
        // materials for each layer
        _materials = new Material[_layerCount];
        // create gameobject layers
        _layers = new GameObject[_layerCount];

        for(int i = 1; i < _layerCount; i++)
        {
            _materials[i] = CreateShellMaterial(i);
            _layers[i] = CreateShellGameObject(i, _mesh, _materials[i]);
        }
    }

    private GameObject CreateShellGameObject(int i, Mesh mesh, Material material)
    {
        // rendering components
        GameObject layer = new GameObject("_ShellLayer" + i, typeof(MeshFilter), typeof(MeshRenderer));
        layer.hideFlags = HideFlags.HideInHierarchy;
        layer.transform.SetParent(transform);
        // reset respective to parent
        layer.transform.localRotation = Quaternion.identity;
        layer.transform.localPosition = Vector3.zero;
        layer.transform.localScale = Vector3.one;
        // setup components
        layer.GetComponent<MeshFilter>().sharedMesh = mesh;
        layer.GetComponent<MeshRenderer>().material = material;
        return layer;
    }

    private Material CreateShellMaterial(int i)
    {
        // shell i material setup
        Material material = new Material(_furMaterial);
        UpdateShellMaterial(i, material);
        return material;
    }

    private void UpdateShellMaterial(int i, Material mat)
    {
        mat.CopyPropertiesFromMaterial(_furMaterial);
        mat.SetFloat("_LayerIndex", (float)i / (float)_layerCount);
        mat.SetFloat("_ZWrite", i == 0 ? 1.0f : 0.0f);
        mat.renderQueue = 3000 + i; 
    }

	private void Update() 
    {
        if (_layerCount != _layers.Length)
        {
            for (int i = 0; i < _layers.Length; i++)
            {
                DestroyImmediate(_layers[i]);
                DestroyImmediate(_materials[i]);
            }

            // materials for each layer
            _materials = new Material[_layerCount];
            // create gameobject layers
            _layers = new GameObject[_layerCount];
        }

		for (int i = 0; i < _layerCount; i++) 
        {
            if (null == _materials[i])
            {
                _materials[i] = new Material(_furMaterial);
            }

            // update material
            UpdateShellMaterial(i, _materials[i]);

            if (null == _layers[i])
            {
                _layers[i] = CreateShellGameObject(i, _mesh, _materials[i]);
            }
		}
	}
}
