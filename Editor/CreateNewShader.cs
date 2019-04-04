using UnityEditor;
using UnityEngine;
using System.IO;

public class CreateNewShader {

    [MenuItem("Assets/Create/Shader/FotflatonStandardShader")]
    static void CreateShaderBase()
    {
        var path = "Assets/FotflatonStandardShader/Shader/FotflatonStandardShaderBase.shader";

        var filename = "new FotflatonStandardShader.shader";
        var createPath = "Assets/FotflatonStandardShader/" + filename;

        File.Copy(path, createPath);

        AssetDatabase.ImportAsset(createPath);
    }
}
