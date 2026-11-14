using System.Collections.Generic;
using System.Globalization;
using System.IO;
using FurRendering;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

/// <summary>
/// Renders the demo scene's main camera to PNGs from the command line (without -quit; the tool
/// exits when done), e.g.
/// Unity -batchmode -projectPath . -executeMethod CaptureTool.CaptureFromCommandLine
/// Arguments: -captureOut path.png -captureWidth 1920 -captureHeight 1080
/// -capturePos x,y,z -captureEuler x,y,z -captureFov 40 (camera override)
/// -captureTime t (animation and wind time) -captureHide "name;name"
/// CaptureSequence also takes -captureFrames n -captureFps f and writes path_000.png onwards,
/// after one unrecorded loop so the fur's motion lag has settled into the loop.
/// Each render happens on its own editor frame: draws queued with Graphics.RenderPrimitives
/// last until the frame ends, so rendering twice in one frame would draw them twice.
/// </summary>
public static class CaptureTool
{
    const string DemoScene = "Assets/Demo/Test.unity";

    static Queue<System.Action> _steps;

    public static void CaptureFromCommandLine()
    {
        Prepare();
        float time = Float(Arg("-captureTime", "0"));
        string output = Arg("-captureOut", Path.Combine("Captures", "capture.png"));
        var steps = new List<System.Action>();
        // Warm-up frames: the first skins the meshes, the next settle the fur state.
        for (int i = 0; i < 3; i++)
            steps.Add(() => { Pose(time); Render(null); });
        steps.Add(() => { Pose(time); Render(output); });
        Run(steps);
    }

    public static void CaptureSequence()
    {
        Prepare();
        string output = Arg("-captureOut", Path.Combine("Captures", "frame.png"));
        int frames = int.Parse(Arg("-captureFrames", "60"));
        float fps = Float(Arg("-captureFps", "30"));
        string stem = Path.Combine(Path.GetDirectoryName(output), Path.GetFileNameWithoutExtension(output));
        var steps = new List<System.Action>();
        for (int i = -frames; i < frames; i++)
        {
            int frame = i;
            float time = (i + frames) / fps;
            steps.Add(() => { Pose(time); Render(frame < 0 ? null : $"{stem}_{frame:000}.png"); });
        }
        Run(steps);
    }

    static void Run(List<System.Action> steps)
    {
        _steps = new Queue<System.Action>(steps);
        EditorApplication.update += Tick;
    }

    static void Tick()
    {
        if (_steps.Count == 0)
        {
            EditorApplication.update -= Tick;
            EditorApplication.Exit(0);
            return;
        }
        try
        {
            _steps.Dequeue()();
        }
        catch (System.Exception e)
        {
            Debug.LogException(e);
            EditorApplication.Exit(1);
        }
    }

    static void Prepare()
    {
        EditorSceneManager.OpenScene(Arg("-captureScene", DemoScene));
        var cam = Camera.main;
        string pos = Arg("-capturePos", null);
        string euler = Arg("-captureEuler", null);
        string fov = Arg("-captureFov", null);
        if (pos != null)
            cam.transform.position = ParseVector(pos);
        if (euler != null)
            cam.transform.eulerAngles = ParseVector(euler);
        if (fov != null)
            cam.fieldOfView = Float(fov);
        string hide = Arg("-captureHide", null);
        if (hide != null)
            foreach (var name in hide.Split(';'))
                GameObject.Find(name)?.SetActive(false);
    }

    /// <summary>Poses every animated character at the given time of its first clip and sets the wind time.</summary>
    static void Pose(float time)
    {
        ShellFur.TimeOverride = time;
        foreach (var animator in Object.FindObjectsByType<Animator>(FindObjectsSortMode.None))
        {
            var controller = animator.runtimeAnimatorController;
            if (controller == null || controller.animationClips.Length == 0)
                continue;
            var clip = controller.animationClips[0];
            clip.SampleAnimation(animator.gameObject, time % clip.length);
        }
    }

    static void Render(string path)
    {
        int width = int.Parse(Arg("-captureWidth", "1920"));
        int height = int.Parse(Arg("-captureHeight", "1080"));
        var cam = Camera.main;
        var rt = RenderTexture.GetTemporary(width, height, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB, 8);
        var previous = cam.targetTexture;
        cam.targetTexture = rt;
        cam.Render();
        cam.targetTexture = previous;
        if (path != null)
        {
            var active = RenderTexture.active;
            RenderTexture.active = rt;
            var tex = new Texture2D(width, height, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, width, height), 0, 0);
            tex.Apply();
            RenderTexture.active = active;
            Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
            File.WriteAllBytes(path, tex.EncodeToPNG());
            Object.DestroyImmediate(tex);
            Debug.Log("[CaptureTool] Wrote " + Path.GetFullPath(path));
        }
        RenderTexture.ReleaseTemporary(rt);
    }

    static float Float(string s) => float.Parse(s, CultureInfo.InvariantCulture);

    static Vector3 ParseVector(string s)
    {
        var p = s.Split(',');
        return new Vector3(Float(p[0]), Float(p[1]), Float(p[2]));
    }

    static string Arg(string name, string fallback)
    {
        var args = System.Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length - 1; i++)
            if (args[i] == name)
                return args[i + 1];
        return fallback;
    }
}
