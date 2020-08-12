using UnityEngine;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.UI;

[ExecuteInEditMode]
[RequireComponent(typeof(MeshRenderer))]
public class Sphere : MonoBehaviour
{
    [Header("UI")]
    [SerializeField] private Slider scatteringSlider;

    [SerializeField] private Slider densitySlider;
    [SerializeField] private Slider coverageSlider;
    [SerializeField] private Slider sunSpeedSlider;
    [SerializeField] private Slider jitterSlider;
    [SerializeField] private Toggle taaToggle;

    [Header("Components")]
    [SerializeField] private Transform sun = null;

    [SerializeField] private PostProcessLayer ppLayer = null;
    [SerializeField] private Transform sphere = null;

    private Material raymarchMat = null;

    private int posId = -1;
    private int radiusId = -1;
    private int frameCountId = -1;
    private int absortionId = -1;
    private int outScatteringId = -1;
    private int densityId = -1;
    private int coverageId = -1;
    private int jitterId = -1;

    private void Start()
    {
        raymarchMat = GetComponent<MeshRenderer>().sharedMaterial;

        absortionId = Shader.PropertyToID("_Absortion");
        outScatteringId = Shader.PropertyToID("_OutScattering");
        densityId = Shader.PropertyToID("_Density");
        coverageId = Shader.PropertyToID("_Coverage");
        jitterId = Shader.PropertyToID("_JitterEnabled");
        posId = Shader.PropertyToID("_SpherePos");
        radiusId = Shader.PropertyToID("_SphereRadius");
        frameCountId = Shader.PropertyToID("_FrameCount");

        Camera.onPreRender += MyPreRender;
    }

    private void Update()
    {
        float dt = Time.deltaTime;

        Vector3 eulers = new Vector3(0.0f, sunSpeedSlider.value * dt, 0.0f);
        sun.Rotate(eulers, Space.World);
    }

    private void OnDestroy()
    {
        Camera.onPreRender -= MyPreRender;
    }

    private void SetAAMode(bool wantTaa)
    {
        if (wantTaa)
            ppLayer.antialiasingMode = PostProcessLayer.Antialiasing.TemporalAntialiasing;
        else
            ppLayer.antialiasingMode = PostProcessLayer.Antialiasing.None;
    }

    private void MyPreRender(Camera cam)
    {
        raymarchMat.SetFloat(absortionId, 0.0f);
        raymarchMat.SetFloat(outScatteringId, scatteringSlider.value);
        raymarchMat.SetFloat(densityId, densitySlider.value);
        raymarchMat.SetFloat(coverageId, coverageSlider.value);

        raymarchMat.SetInt(jitterId, (int)jitterSlider.value);

        raymarchMat.SetVector(posId, sphere.position);
        raymarchMat.SetFloat(radiusId, sphere.localScale.x * 0.5f);
        raymarchMat.SetFloat(frameCountId, Time.frameCount);

        SetAAMode(taaToggle.isOn);
    }
}