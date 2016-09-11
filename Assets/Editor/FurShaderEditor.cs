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
        _option = (DensityFunctions)EditorGUILayout.EnumPopup("Density Function", _option);
        if (EditorGUI.EndChangeCheck())
        {
            targetMat.DisableKeyword("FIXED");
            targetMat.DisableKeyword("LIN");
            targetMat.DisableKeyword("POW2");
            targetMat.DisableKeyword("POW3");
            targetMat.DisableKeyword("SINE");
            // enable or disable the keyword based on enum
            if (_option == DensityFunctions.Fixed)
            {
                targetMat.EnableKeyword("FIXED");
            }
            if (_option == DensityFunctions.Linear)
            {
                targetMat.EnableKeyword("LIN");
            }
            if (_option == DensityFunctions.Pow2)
            {
                targetMat.EnableKeyword("POW2");
            }
            if (_option == DensityFunctions.Pow3)
            {
                targetMat.EnableKeyword("POW3");
            }
            if (_option == DensityFunctions.Sine)
            {
                targetMat.EnableKeyword("SINE");
            }
        }

        base.OnGUI(materialEditor, properties);
    }
}