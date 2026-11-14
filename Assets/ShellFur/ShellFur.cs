using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace FurRendering
{
    /// <summary>
    /// Renders the fur of this object's mesh as instanced shells. The renderer's material must
    /// use the FurRendering/Shell Fur shader. One draw call per submesh draws every shell, reading
    /// the vertices straight from the mesh's GPU buffers, or from the GPU-skinned vertices of a
    /// SkinnedMeshRenderer, so animated characters need no CPU work. The renderer's own draw is
    /// hidden; the innermost shell is the skin.
    /// </summary>
    [ExecuteAlways, RequireComponent(typeof(Renderer))]
    public class ShellFur : MonoBehaviour
    {
        [SerializeField, Range(1, 128)] int _shellCount = 32;
        [SerializeField, Tooltip("How quickly the fur catches up with the skin when it moves, per second.")]
        float _lagResponse = 12f;
        [SerializeField] ShadowCastingMode _shadows = ShadowCastingMode.On;
        [SerializeField] ComputeShader _stateShader;

        /// <summary>Time fed to the wind instead of the clock, for deterministic captures.</summary>
        public static float? TimeOverride;

        static readonly int FurPositions = Shader.PropertyToID("_FurPositions");
        static readonly int FurTexcoords = Shader.PropertyToID("_FurTexcoords");
        static readonly int FurIndices = Shader.PropertyToID("_FurIndices");
        static readonly int FurState = Shader.PropertyToID("_FurState");
        static readonly int FurPositionStride = Shader.PropertyToID("_FurPositionStride");
        static readonly int FurPositionOffset = Shader.PropertyToID("_FurPositionOffset");
        static readonly int FurNormalOffset = Shader.PropertyToID("_FurNormalOffset");
        static readonly int FurTexcoordStride = Shader.PropertyToID("_FurTexcoordStride");
        static readonly int FurTexcoordOffset = Shader.PropertyToID("_FurTexcoordOffset");
        static readonly int FurTexcoordHalf = Shader.PropertyToID("_FurTexcoordHalf");
        static readonly int FurIndexStart = Shader.PropertyToID("_FurIndexStart");
        static readonly int FurBaseVertex = Shader.PropertyToID("_FurBaseVertex");
        static readonly int FurIndex16 = Shader.PropertyToID("_FurIndex16");
        static readonly int FurShellCount = Shader.PropertyToID("_FurShellCount");
        static readonly int FurObjectToWorld = Shader.PropertyToID("_FurObjectToWorld");
        static readonly int FurWorldToObject = Shader.PropertyToID("_FurWorldToObject");
        static readonly int FurVertexCount = Shader.PropertyToID("_FurVertexCount");
        static readonly int FurBlend = Shader.PropertyToID("_FurBlend");
        static readonly int FurTime = Shader.PropertyToID("_FurTime");
        static readonly int FurLength = Shader.PropertyToID("_FurLength");

        Renderer _renderer;
        SkinnedMeshRenderer _skinned;
        Mesh _mesh;
        GraphicsBuffer _positions, _texcoords, _indices, _state;
        GraphicsBuffer _skinnedPositions;
        MaterialPropertyBlock _props;
        int _positionStride, _positionOffset, _normalOffset, _texcoordStride, _texcoordOffset;
        bool _texcoordHalf;
        float _lastTime = float.NaN;

        void OnEnable()
        {
            _renderer = GetComponent<Renderer>();
            _skinned = _renderer as SkinnedMeshRenderer;
            var filter = GetComponent<MeshFilter>();
            _mesh = _skinned != null ? _skinned.sharedMesh : filter != null ? filter.sharedMesh : null;
            if (_mesh == null || !Setup())
            {
                Release();
                return;
            }
            // Hide the renderer's own draw: the innermost shell is the skin. A skinned mesh must stay
            // rendered or Unity stops skinning it, so the fur shader collapses that draw instead.
            _renderer.forceRenderingOff = _skinned == null;
            RenderPipelineManager.beginContextRendering += Draw;
        }

        void OnDisable()
        {
            RenderPipelineManager.beginContextRendering -= Draw;
            if (_renderer != null)
                _renderer.forceRenderingOff = false;
            Release();
        }

        bool Setup()
        {
            if (_mesh.GetVertexAttributeFormat(VertexAttribute.Position) != VertexAttributeFormat.Float32
                || !_mesh.HasVertexAttribute(VertexAttribute.Normal)
                || _mesh.GetVertexAttributeFormat(VertexAttribute.Normal) != VertexAttributeFormat.Float32
                || !_mesh.HasVertexAttribute(VertexAttribute.TexCoord0))
            {
                Debug.LogError($"[ShellFur] {_mesh.name} needs float positions and normals and a UV0 channel.", this);
                return false;
            }
            int positionStream = _mesh.GetVertexAttributeStream(VertexAttribute.Position);
            if (_mesh.GetVertexAttributeStream(VertexAttribute.Normal) != positionStream)
            {
                Debug.LogError($"[ShellFur] {_mesh.name} must keep normals in the same vertex stream as positions.", this);
                return false;
            }
            var uvFormat = _mesh.GetVertexAttributeFormat(VertexAttribute.TexCoord0);
            if (uvFormat != VertexAttributeFormat.Float32 && uvFormat != VertexAttributeFormat.Float16)
            {
                Debug.LogError($"[ShellFur] {_mesh.name} UV0 must be float or half.", this);
                return false;
            }

            _mesh.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
            _mesh.indexBufferTarget |= GraphicsBuffer.Target.Raw;
            if (_skinned != null)
            {
                _skinned.vertexBufferTarget |= GraphicsBuffer.Target.Raw;
                // The skinned buffer holds position, normal (and tangent) only.
                _positionOffset = 0;
                _normalOffset = 12;
            }
            else
            {
                _positions = _mesh.GetVertexBuffer(positionStream);
                _positionStride = _mesh.GetVertexBufferStride(positionStream);
                _positionOffset = _mesh.GetVertexAttributeOffset(VertexAttribute.Position);
                _normalOffset = _mesh.GetVertexAttributeOffset(VertexAttribute.Normal);
            }

            int uvStream = _mesh.GetVertexAttributeStream(VertexAttribute.TexCoord0);
            _texcoords = _mesh.GetVertexBuffer(uvStream);
            _texcoordStride = _mesh.GetVertexBufferStride(uvStream);
            _texcoordOffset = _mesh.GetVertexAttributeOffset(VertexAttribute.TexCoord0);
            _texcoordHalf = uvFormat == VertexAttributeFormat.Float16;
            _indices = _mesh.GetIndexBuffer();

            _state = new GraphicsBuffer(GraphicsBuffer.Target.Structured, _mesh.vertexCount, 16);
            _state.SetData(new Vector4[_mesh.vertexCount]);
            _lastTime = float.NaN;
            _props ??= new MaterialPropertyBlock();
            return true;
        }

        void Release()
        {
            _positions?.Dispose();
            _texcoords?.Dispose();
            _indices?.Dispose();
            _state?.Dispose();
            _skinnedPositions?.Dispose();
            _positions = _texcoords = _indices = _state = _skinnedPositions = null;
        }

        void Draw(ScriptableRenderContext context, List<Camera> cameras)
        {
            if (this == null || !isActiveAndEnabled)
                return;
            var materials = _renderer.sharedMaterials;
            if (materials.Length == 0 || materials[0] == null || _state == null)
                return;

            var positions = _positions;
            int positionStride = _positionStride;
            if (_skinned != null)
            {
                // Skinned vertices of the latest pose; keep the handle alive until the next draw.
                _skinnedPositions?.Dispose();
                _skinnedPositions = _skinned.GetVertexBuffer();
                if (_skinnedPositions == null)
                    return;     // not skinned yet
                positions = _skinnedPositions;
                positionStride = _skinnedPositions.stride;
            }

            float time = TimeOverride ?? (Application.isPlaying ? Time.time : Time.realtimeSinceStartup);
            Shader.SetGlobalFloat(FurTime, time);
            var localToWorld = SkinnedSpace();

            if (_stateShader != null)
            {
                float dt = float.IsNaN(_lastTime) ? 0f : Mathf.Max(0f, time - _lastTime);
                _lastTime = time;
                _stateShader.SetBuffer(0, FurPositions, positions);
                _stateShader.SetBuffer(0, FurState, _state);
                _stateShader.SetInt(FurPositionStride, positionStride);
                _stateShader.SetInt(FurPositionOffset, _positionOffset);
                _stateShader.SetInt(FurVertexCount, _mesh.vertexCount);
                _stateShader.SetMatrix(FurObjectToWorld, localToWorld);
                _stateShader.SetFloat(FurBlend, 1f - Mathf.Exp(-dt * _lagResponse));
                _stateShader.Dispatch(0, (_mesh.vertexCount + 63) / 64, 1, 1);
            }

            _props.SetBuffer(FurPositions, positions);
            _props.SetBuffer(FurTexcoords, _texcoords);
            _props.SetBuffer(FurIndices, _indices);
            _props.SetBuffer(FurState, _state);
            _props.SetInteger(FurPositionStride, positionStride);
            _props.SetInteger(FurPositionOffset, _positionOffset);
            _props.SetInteger(FurNormalOffset, _normalOffset);
            _props.SetInteger(FurTexcoordStride, _texcoordStride);
            _props.SetInteger(FurTexcoordOffset, _texcoordOffset);
            _props.SetInteger(FurTexcoordHalf, _texcoordHalf ? 1 : 0);
            _props.SetInteger(FurIndex16, _mesh.indexFormat == IndexFormat.UInt16 ? 1 : 0);
            _props.SetInteger(FurShellCount, _shellCount);
            _props.SetMatrix(FurObjectToWorld, localToWorld);
            _props.SetMatrix(FurWorldToObject, localToWorld.inverse);

            var bounds = _renderer.bounds;
            for (int s = 0; s < _mesh.subMeshCount; s++)
            {
                var material = materials[Mathf.Min(s, materials.Length - 1)];
                var subMesh = _mesh.GetSubMesh(s);
                if (material == null || subMesh.topology != MeshTopology.Triangles)
                    continue;
                bounds.Expand(4f * material.GetFloat(FurLength));
                _props.SetInteger(FurIndexStart, subMesh.indexStart);
                _props.SetInteger(FurBaseVertex, subMesh.baseVertex);
                var rp = new RenderParams(material)
                {
                    worldBounds = bounds,
                    matProps = _props,
                    shadowCastingMode = _shadows,
                    receiveShadows = true,
                    layer = gameObject.layer,
                    lightProbeUsage = LightProbeUsage.BlendProbes,
                };
                Graphics.RenderPrimitives(rp, MeshTopology.Triangles, subMesh.indexCount, _shellCount);
            }
        }

        /// <summary>
        /// The space the vertex buffer is in. Skinned vertices come out relative to the root bone's
        /// position and rotation, with its scale already applied.
        /// </summary>
        Matrix4x4 SkinnedSpace()
        {
            if (_skinned == null)
                return transform.localToWorldMatrix;
            var root = _skinned.rootBone != null ? _skinned.rootBone : transform;
            return Matrix4x4.TRS(root.position, root.rotation, Vector3.one);
        }

#if UNITY_EDITOR
        void Reset()
        {
            foreach (var guid in UnityEditor.AssetDatabase.FindAssets("FurState t:ComputeShader"))
                _stateShader = UnityEditor.AssetDatabase.LoadAssetAtPath<ComputeShader>(UnityEditor.AssetDatabase.GUIDToAssetPath(guid));
        }
#endif
    }
}
