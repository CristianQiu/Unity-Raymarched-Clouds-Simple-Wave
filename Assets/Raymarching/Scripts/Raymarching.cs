using UnityEngine;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.UI;

[RequireComponent(typeof(MeshRenderer))]
public class Raymarching : MonoBehaviour
{
    #region Private Attributes

    [Header("UI")]
    [SerializeField] private Slider sunSpeedSlider = null;

    [SerializeField] private Slider coverageSlider = null;
    [SerializeField] private Slider densitySlider = null;
    [SerializeField] private Slider absortionSlider = null;
    [SerializeField] private Slider jitterSlider = null;
    [SerializeField] private Toggle taaToggle = null;

    [Header("Components")]
    [SerializeField] private Transform sun = null;

    [SerializeField] private PostProcessLayer ppLayer = null;
    [SerializeField] private Transform sphere = null;

    private Material raymarchMat;

    private readonly int posId = Shader.PropertyToID("_SpherePos");
    private readonly int radiusId = Shader.PropertyToID("_SphereRadius");
    private readonly int coverageId = Shader.PropertyToID("_Coverage");
    private readonly int densityId = Shader.PropertyToID("_Density");
    private readonly int absortionId = Shader.PropertyToID("_Absortion");
    private readonly int jitterId = Shader.PropertyToID("_JitterEnabled");
    private readonly int frameCountId = Shader.PropertyToID("_FrameCount");

    #endregion

    #region MonoBehaviour Methods

    private void Start()
    {
        raymarchMat = GetComponent<MeshRenderer>().sharedMaterial;
        Camera.onPreRender += MyPreRender;
    }

    private void Update()
    {
        Vector3 eulers = new Vector3(0.0f, sunSpeedSlider.value * Time.deltaTime, 0.0f);
        sun.Rotate(eulers, Space.World);
    }

    private void OnDestroy()
    {
        Camera.onPreRender -= MyPreRender;
    }

    #endregion

    #region Methods

    private void MyPreRender(Camera cam)
    {
        raymarchMat.SetVector(posId, sphere.position);
        raymarchMat.SetFloat(radiusId, sphere.localScale.x * 0.5f);
        raymarchMat.SetFloat(coverageId, coverageSlider.value);
        raymarchMat.SetFloat(densityId, densitySlider.value);
        raymarchMat.SetFloat(absortionId, absortionSlider.value);
        raymarchMat.SetInt(jitterId, (int)jitterSlider.value);
        raymarchMat.SetFloat(frameCountId, Time.frameCount);
        ppLayer.antialiasingMode = taaToggle.isOn ? PostProcessLayer.Antialiasing.TemporalAntialiasing : PostProcessLayer.Antialiasing.None;
    }

    #endregion
}