using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Renderer)), ExecuteInEditMode]
public class FurLayers : MonoBehaviour
{
    [SerializeField, Range(0, 120)]
    private int _layerCount = 20;

    private GameObject[] _layers = new GameObject[0];
    private Material[] _materials = new Material[0];
    private Mesh _mesh = null;
    private Material _furMaterial;
    private GameObject _layersContainer;

    private void Start()
    {
        _furMaterial = GetComponent<Renderer>().sharedMaterial;
        _mesh = GetComponent<MeshFilter>().sharedMesh;

        for (int i = 0; i < transform.childCount; i++)
        {
            if (transform.GetChild(i).name == "_LayersContainer")
            {
                SetupLayersContainer(transform.GetChild(i).gameObject); 
            }
        }

        if (_layersContainer == null)
        {
            SetupLayersContainer(new GameObject("_LayersContainer")); 
        }
    }

    void SetupLayersContainer(GameObject go)
    {
        _layersContainer = go;
        _layersContainer.transform.SetParent(transform, false);
        _layersContainer.hideFlags = HideFlags.HideInHierarchy;
        // reset respective to parent
        _layersContainer.transform.localRotation = Quaternion.identity;
        _layersContainer.transform.localPosition = Vector3.zero;
        _layersContainer.transform.localScale = Vector3.one;
    }

    private GameObject CreateShellGameObject(int i, Mesh mesh, Material material)
    {
        // rendering components
        GameObject layer = new GameObject("_ShellLayer" + i, typeof(MeshFilter), typeof(MeshRenderer));
        layer.transform.SetParent(_layersContainer.transform, false);
        layer.hideFlags = HideFlags.HideInHierarchy;
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
        mat.renderQueue = 2900 + i; 
    }

    void RefreshLayers()
    {
        for (int i = 0; i < _layers.Length; i++)
        {
            if (null != _layers[i])
            {
                DestroyImmediate(_layers[i]);
            }
        }
        // create gameobject layers
        _layers = new GameObject[_layerCount];
    }

    void RefreshMaterials()
    {
        for (int i = 0; i < _materials.Length; i++)
        {
            if (null != _materials[i])
            {
                DestroyImmediate(_materials[i]);
            }
        }
        // materials for each layer
        _materials = new Material[_layerCount];
    }

    void CreateShells()
    {
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

    private void Update()
    {
        if (null == _layers)
        {
            _layers = new GameObject[_layerCount];
        }
        if (null == _materials)
        {
            _materials = new Material[_layerCount];
        }

        if (_layersContainer.transform.childCount != _layerCount)
        {
            RefreshLayers();
            RefreshMaterials();
            DestroyImmediate(_layersContainer);
            // new layers container
            SetupLayersContainer(new GameObject("_LayersContainer")); 
            // add shells to container
            CreateShells();
        }

        if (_layerCount != _layers.Length)
        {
            RefreshLayers();
        }

        if (_layerCount != _materials.Length)
        {
            RefreshMaterials();
        }

        CreateShells();
    }
}
