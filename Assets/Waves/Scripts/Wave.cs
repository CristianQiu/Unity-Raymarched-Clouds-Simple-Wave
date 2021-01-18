using System.Collections.Generic;
using UnityEngine;

public class Wave : MonoBehaviour
{
    #region Private Attributes

    private static readonly int FurthestObjectDistanceId = Shader.PropertyToID("_FurthestObjectDistance");

    [SerializeField] private GameObject prefab = null;
    [SerializeField] private Material material = null;

    [Space, SerializeField] private Vector2Int maxGridDimensions = new Vector2Int(100, 100);
    [SerializeField, Range(10.0f, 100.0f)] private float clampSpawnToRadius = 25.0f;
    [SerializeField, Range(0.0f, 1.0f)] private float spacing = 0.05f;

    private List<GameObject> waveObjs = new List<GameObject>();

    private bool dirty;

    #endregion

    #region MonoBehaviour Methods

    private void Start()
    {
        SpawnWave();
    }

    private void Update()
    {
        if (dirty)
        {
            DestroyWave();
            SpawnWave();

            dirty = false;
        }
    }

    private void OnValidate()
    {
        if (maxGridDimensions.x % 2 == 1)
            maxGridDimensions.x += 1;

        if (maxGridDimensions.y % 2 == 1)
            maxGridDimensions.y += 1;

        maxGridDimensions.x = Mathf.Clamp(maxGridDimensions.x, 4, 100);
        maxGridDimensions.y = Mathf.Clamp(maxGridDimensions.y, 4, 100);

        if (Application.isPlaying)
            dirty = true;
    }

    #endregion

    #region Methods

    private void SpawnWave()
    {
        // assume the prefab has the same scale on X and Z
        float offsetX = prefab.transform.localScale.x;
        float offsetZ = prefab.transform.localScale.z;

        Debug.Assert(offsetX == offsetZ, "The prefab must have the same scale in X and Z.");

        int invertX = 1;
        int invertZ = 1;

        float furthestDist = float.MinValue;

        for (int quadrant = 0; quadrant < 4; quadrant++)
        {
            for (int i = 0; i < maxGridDimensions.x / 2; i++)
            {
                for (int j = 0; j < maxGridDimensions.y / 2; j++)
                {
                    float x = j + (j * spacing) + (offsetX * 0.5f) + (spacing * 0.5f);
                    float z = i + (i * spacing) + (offsetZ * 0.5f) + (spacing * 0.5f);

                    x *= invertX;
                    z *= invertZ;

                    Vector3 pos = new Vector3(x, 0.0f, z);
                    float dist = Vector3.Distance(pos, Vector3.zero);

                    if (dist > clampSpawnToRadius)
                        continue;

                    if (dist > furthestDist)
                        furthestDist = dist;

                    GameObject obj = Instantiate(prefab, null) as GameObject;
                    obj.transform.SetPositionAndRotation(pos, Quaternion.identity);

                    waveObjs.Add(obj);
                }
            }

            // generate the grid by generating the quadrants in clockwise order
            switch (quadrant)
            {
                case 0:
                    invertX = 1;
                    invertZ = -1;
                    break;

                case 1:
                    invertX = -1;
                    invertZ = -1;
                    break;

                case 2:
                    invertX = -1;
                    invertZ = 1;
                    break;

                default:
                    invertX = 1;
                    invertZ = 1;
                    break;
            }
        }

        material.SetFloat(FurthestObjectDistanceId, furthestDist);
    }

    private void DestroyWave()
    {
        for (int i = waveObjs.Count - 1; i >= 0; i--)
        {
            GameObject obj = waveObjs[i];
            Destroy(obj);

            waveObjs.RemoveAt(waveObjs.Count - 1);
        }
    }

    #endregion
}