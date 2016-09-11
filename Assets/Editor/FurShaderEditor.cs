using UnityEditor;
using UnityEngine;
using System;

public class FurShaderEditor : ShaderGUI
{
    private enum DensityFunctions
    {
        Fixed,
        Linear,
        Pow2,
        Pow3,
        Sine,
    }

    private DensityFunctions _option;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        Material targetMat = materialEditor.target as Material;

        EditorGUI.BeginChangeCheck();
        // option resets every time the spector isn't being renderer
        if (targetMat.IsKeywordEnabled("FIXED"))
        {
            _option = DensityFunctions.Fixed;
        }
        else if (targetMat.IsKeywordEnabled("LIN"))
        {
            _option = DensityFunctions.Linear;
        }
        else if (targetMat.IsKeywordEnabled("POW2"))
        {
            _option = DensityFunctions.Pow2;
        }
        else if (targetMat.IsKeywordEnabled("POW3"))
        {
            _option = DensityFunctions.Pow3;
        }
        else if (targetMat.IsKeywordEnabled("SINE"))
        {
            _option = DensityFunctions.Sine;
        }

        _option = (DensityFunctions)EditorGUILayout.EnumPopup("Density Function", _option);

        if (EditorGUI.EndChangeCheck())
        {
            targetMat.DisableKeyword("FIXED");
            targetMat.DisableKeyword("LIN");
            targetMat.DisableKeyword("POW2");
            targetMat.DisableKeyword("POW3");
            targetMat.DisableKeyword("SINE");
            // enable or disable the keyword based on enum
            switch (_option)
            {
                case DensityFunctions.Fixed:
                    targetMat.EnableKeyword("FIXED");
                    break;
                case DensityFunctions.Linear:
                    targetMat.EnableKeyword("LIN");
                    break;
                case DensityFunctions.Pow2:
                    targetMat.EnableKeyword("POW2");
                    break;
                case DensityFunctions.Pow3:
                    targetMat.EnableKeyword("POW3");
                    break;
                case DensityFunctions.Sine:
                    targetMat.EnableKeyword("SINE");
                    break;                   
                default:
                    break;
            }
        }

        base.OnGUI(materialEditor, properties);
    }
}