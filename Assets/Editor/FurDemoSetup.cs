using System.Collections.Generic;
using System.IO;
using System.Linq;
using FurRendering;
using UnityEditor;
using UnityEditor.Animations;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>One-off setup of the fur demo, run from the command line with -executeMethod.</summary>
public static class FurDemoSetup
{
    const string FoxPath = "Assets/Demo/Fox/Fox.glb";
    const string FoxMeshPath = "Assets/Demo/Fox/Fox Fur.asset";
    const string FoxControllerPath = "Assets/Demo/Fox/Fox.controller";
    const string ScenePath = "Assets/Demo/Test.unity";
    const string FurShader = "FurRendering/Shell Fur";
    const string StateShaderPath = "Assets/ShellFur/Shaders/FurState.compute";

    public static void Refresh()
    {
        SetupMaterials();
        SetupScene();
    }

    public static void All()
    {
        SetupPipeline();
        SetupMaterials();
        SetupFoxMesh();
        SetupScene();
    }

    public static void SetupPipeline()
    {
        Directory.CreateDirectory("Assets/Settings");
        var rendererData = ScriptableObject.CreateInstance<UniversalRendererData>();
        AssetDatabase.CreateAsset(rendererData, "Assets/Settings/URP Renderer.asset");
        var asset = UniversalRenderPipelineAsset.Create(rendererData);
        AssetDatabase.CreateAsset(asset, "Assets/Settings/URP.asset");

        var so = new SerializedObject(asset);
        Set(so, "m_MSAA", 4);                       // alpha to coverage turns strand coverage into samples
        Set(so, "m_SupportsHDR", true);
        Set(so, "m_ShadowDistance", 25f);
        Set(so, "m_ShadowCascadeCount", 2);
        Set(so, "m_MainLightShadowmapResolution", 4096);
        Set(so, "m_SoftShadowsSupported", true);
        so.ApplyModifiedPropertiesWithoutUndo();

        GraphicsSettings.defaultRenderPipeline = asset;
        PlayerSettings.colorSpace = ColorSpace.Linear;
        AssetDatabase.SaveAssets();
        Debug.Log("[FurDemoSetup] URP asset created, Linear colour space");
    }

    public static void SetupMaterials()
    {
        var lit = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Standard.mat");
        lit.shader = Shader.Find("Universal Render Pipeline/Lit");
        lit.SetColor("_BaseColor", Color.white);
        lit.SetFloat("_Smoothness", 0.6f);
        lit.SetFloat("_Metallic", 0f);
        Clean(lit);

        // Giraffe fur on the sphere.
        Fur("Assets/Materials/Fur.mat", AssetDatabase.LoadAssetAtPath<Texture>("Assets/Textures/kirin.png"), m =>
        {
            m.SetFloat("_FurLength", 0.045f);
            m.SetFloat("_Density", 300f);
            m.SetFloat("_Thickness", 0.85f);
            m.SetFloat("_MinLength", 0.5f);
            m.SetFloat("_Gravity", 0.35f);
            m.SetFloat("_WindStrength", 0.1f);
        });

        // Grass on the plane: thin, tall blades in a stronger wind.
        Fur("Assets/Materials/Grass.mat", AssetDatabase.LoadAssetAtPath<Texture>("Assets/Textures/Grass.jpg"), m =>
        {
            m.SetFloat("_FurLength", 0.1f);
            m.SetTextureScale("_BaseMap", new Vector2(3f, 3f));
            m.SetTextureOffset("_BaseMap", new Vector2(0.5f, 0.5f));
            m.SetFloat("_Density", 4200f);              // the plane is 30 m across
            m.SetFloat("_Thickness", 0.7f);
            m.SetFloat("_MinLength", 0.25f);
            m.SetFloat("_RootOcclusion", 0.15f);
            m.SetFloat("_Gravity", 0.05f);
            m.SetFloat("_WindStrength", 0.25f);
            m.SetFloat("_Specular", 0.25f);
            m.SetFloat("_SpecularExponent", 32f);
        });

        // The fox, textured with the model's own base colour map.
        var foxTexture = AssetDatabase.LoadAllAssetsAtPath(FoxPath).OfType<Texture2D>().First();
        Fur("Assets/Materials/Fox.mat", foxTexture, m =>
        {
            m.SetFloat("_FurLength", 0.025f);
            m.SetFloat("_Density", 400f);
            m.SetFloat("_Thickness", 0.85f);
            m.SetFloat("_MinLength", 0.45f);
            m.SetFloat("_Gravity", 0.4f);
            m.SetFloat("_WindStrength", 0.15f);
            m.SetFloat("_MotionLag", 1.5f);
        });
        AssetDatabase.SaveAssets();
    }

    static void Fur(string path, Texture texture, System.Action<Material> configure)
    {
        var m = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (m == null)
        {
            m = new Material(Shader.Find(FurShader));
            AssetDatabase.CreateAsset(m, path);
        }
        m.shader = Shader.Find(FurShader);
        m.SetTexture("_BaseMap", texture);
        m.SetColor("_BaseColor", Color.white);
        m.SetFloat("_WindFrequency", 2f / 3.4166667f);  // two gusts per loop of the fox's Survey animation
        configure(m);
        m.renderQueue = -1;
        Clean(m);
        EditorUtility.SetDirty(m);
    }

    /// <summary>Drops properties and keywords the material's current shader doesn't have.</summary>
    static void Clean(Material m)
    {
        m.shaderKeywords = new string[0];
        var so = new SerializedObject(m);
        var saved = so.FindProperty("m_SavedProperties");
        foreach (var listName in new[] { "m_TexEnvs", "m_Ints", "m_Floats", "m_Colors" })
        {
            var list = saved.FindPropertyRelative(listName);
            for (int i = list.arraySize - 1; i >= 0; i--)
            {
                var name = list.GetArrayElementAtIndex(i).FindPropertyRelative("first").stringValue;
                if (m.shader.FindPropertyIndex(name) < 0)
                    list.DeleteArrayElementAtIndex(i);
            }
        }
        so.ApplyModifiedPropertiesWithoutUndo();
        EditorUtility.SetDirty(m);
    }

    /// <summary>
    /// The glTF fox has no normals and no shared vertices, so it imports with flat normals and
    /// shells pushed along them would split apart at every edge. This copy averages the normals
    /// of coincident vertices, so the shells stay closed and the fur shades smoothly.
    /// </summary>
    public static void SetupFoxMesh()
    {
        var source = AssetDatabase.LoadAllAssetsAtPath(FoxPath).OfType<Mesh>().First();
        var mesh = Object.Instantiate(source);
        mesh.name = "Fox Fur";
        var vertices = mesh.vertices;
        var normals = mesh.normals;
        var triangles = mesh.triangles;
        var sums = new Dictionary<Vector3Int, Vector3>();
        Vector3Int Key(Vector3 p) => Vector3Int.RoundToInt(p * 100f);
        for (int t = 0; t < triangles.Length; t += 3)
        {
            int a = triangles[t], b = triangles[t + 1], c = triangles[t + 2];
            float area = Vector3.Cross(vertices[b] - vertices[a], vertices[c] - vertices[a]).magnitude;
            foreach (int i in new[] { a, b, c })
            {
                sums.TryGetValue(Key(vertices[i]), out var sum);
                sums[Key(vertices[i])] = sum + normals[i] * area;
            }
        }
        for (int i = 0; i < vertices.Length; i++)
            normals[i] = sums[Key(vertices[i])].normalized;
        mesh.normals = normals;
        AssetDatabase.DeleteAsset(FoxMeshPath);
        AssetDatabase.CreateAsset(mesh, FoxMeshPath);
        AssetDatabase.SaveAssets();
        Debug.Log($"[FurDemoSetup] Smoothed fox normals: {vertices.Length} vertices, {sums.Count} positions");
    }

    public static void SetupScene()
    {
        var scene = EditorSceneManager.OpenScene(ScenePath);
        var stateShader = AssetDatabase.LoadAssetAtPath<ComputeShader>(StateShaderPath);

        // The old shell container left under the plane by FurLayers.
        foreach (var t in Object.FindObjectsByType<Transform>(FindObjectsInactive.Include, FindObjectsSortMode.None))
            if (t != null && t.name == "_LayersContainer")
                Object.DestroyImmediate(t.gameObject);

        var plane = GameObject.Find("Plane");
        plane.transform.localScale = new Vector3(3f, 1f, 3f);    // grass out toward the horizon
        AddFur(plane, 32, stateShader);
        AddFur(GameObject.Find("Sphere (1)"), 32, stateShader);

        // The fox.
        var existing = GameObject.Find("Fox");
        if (existing != null)
            Object.DestroyImmediate(existing);
        var fox = (GameObject)PrefabUtility.InstantiatePrefab(AssetDatabase.LoadAssetAtPath<GameObject>(FoxPath), scene);
        fox.transform.SetPositionAndRotation(new Vector3(1.6f, 0f, -0.6f), Quaternion.Euler(0f, 215f, 0f));
        fox.transform.localScale = Vector3.one * 0.01f;
        var skinned = fox.GetComponentInChildren<SkinnedMeshRenderer>();
        skinned.sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>(FoxMeshPath);
        skinned.sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/Materials/Fox.mat");
        skinned.updateWhenOffscreen = true;
        AddFur(skinned.gameObject, 48, stateShader);

        var clips = AssetDatabase.LoadAllAssetsAtPath(FoxPath).OfType<AnimationClip>().ToArray();
        AssetDatabase.DeleteAsset(FoxControllerPath);
        var controller = AnimatorController.CreateAnimatorControllerAtPathWithClip(FoxControllerPath, clips.First(c => c.name == "Survey"));
        fox.GetComponent<Animator>().runtimeAnimatorController = controller;

        // Frame the fox from the sunlit side.
        var camera = Camera.main;
        camera.transform.SetPositionAndRotation(new Vector3(0.06f, 0.78f, -1.31f), Quaternion.Euler(12f, 65f, 0f));
        camera.fieldOfView = 40f;
        camera.GetUniversalAdditionalCameraData();

        // Bake the sky's ambient light and reflections (no lightmaps): every shell is dynamic.
        var lighting = Lightmapping.lightingSettings;
        lighting.bakedGI = false;
        lighting.realtimeGI = false;
        EditorUtility.SetDirty(lighting);
        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene);
        Lightmapping.Bake();
        EditorSceneManager.SaveScene(scene);
        Debug.Log("[FurDemoSetup] Scene set up, ambient " + RenderSettings.ambientProbe[0, 0]);
    }

    static void AddFur(GameObject go, int shells, ComputeShader stateShader)
    {
        var fur = go.GetComponent<ShellFur>();
        if (fur == null)
            fur = go.AddComponent<ShellFur>();
        var so = new SerializedObject(fur);
        so.FindProperty("_shellCount").intValue = shells;
        so.FindProperty("_stateShader").objectReferenceValue = stateShader;
        so.ApplyModifiedPropertiesWithoutUndo();
    }

    static void Set(SerializedObject so, string name, object value)
    {
        var p = so.FindProperty(name);
        if (p == null)
        {
            Debug.LogWarning("[FurDemoSetup] No property " + name);
            return;
        }
        switch (value)
        {
            case int i: p.intValue = i; break;
            case float f: p.floatValue = f; break;
            case bool b: p.boolValue = b; break;
        }
    }
}
