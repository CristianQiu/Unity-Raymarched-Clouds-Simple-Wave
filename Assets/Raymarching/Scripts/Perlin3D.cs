using UnityEngine;

public class Perlin3D : MonoBehaviour
{
    //	TODO: 	these constants need tweaked to find the best possible noise.
    //			probably requires some kind of brute force computational searching or something....
    const float OFFSETX = 50.0f;
    const float OFFSETY = 161.0f;

    const float SOMELARGEFLOATSX = 635.298681f;
    const float SOMELARGEFLOATSY = 682.357502f;
    const float SOMELARGEFLOATSZ = 668.926525f;

    const float DOMAIN = 69.0f;

    const float ZINCX = 48.500388f;
    const float ZINCY = 65.294118f;
    const float ZINCZ = 63.934599f;

    #region MonoBehaviour Methods

    // Use this for initialization
    void Start () 
    {
        //float perlin = Perlin3Dim(new Vector3(15.8f, 90.5f, 8.92f));
    }

    #endregion

    #region Methods

    private float Perlin3Dim(Vector3 P)
    {
        Vector3 Pi = FloorVec(P);
        Vector3 Pf = P - Pi;
        Vector3 Pf_min1 = SubFromVec(Pf, 1.0f);

        Vector4 hashx0 = Vector4.zero;
        Vector4 hashy0 = Vector4.zero;
        Vector4 hashz0 = Vector4.zero;
        Vector4 hashx1 = Vector4.zero;
        Vector4 hashy1 = Vector4.zero;
        Vector4 hashz1 = Vector4.zero;

        FAST32_hash_3D(Pi, out hashx0, out hashy0, out hashz0, out hashx1, out hashy1, out hashz1);

        float k = 0.49999f;

        Vector4 grad_x0 = SubFromVec(hashx0, k);
        Vector4 grad_y0 = SubFromVec(hashy0, k);
        Vector4 grad_z0 = SubFromVec(hashz0, k);
        Vector4 grad_x1 = SubFromVec(hashx1, k);
        Vector4 grad_y1 = SubFromVec(hashy1, k);
        Vector4 grad_z1 = SubFromVec(hashz1, k);


        // first chorizo
        Vector4 grad_x02 = PowVec(grad_x0, 2);
        Vector4 grad_y02 = PowVec(grad_y0, 2);
        Vector4 grad_z02 = PowVec(grad_z0, 2);

        Vector4 sumGrad_x02y02z02 = SqrtVec(grad_x02 + grad_y02 + grad_z02);
        Vector4 xyxy = VecXyXy(new Vector2(Pf.x, Pf_min1.x));

        Vector4 sumGradByXyXy = MulVecByVec(sumGrad_x02y02z02, xyxy);
        sumGradByXyXy = MulVecByVec(sumGradByXyXy, grad_x0);

        Vector4 xxyy = VecXxYy(new Vector2(Pf.y, Pf_min1.y));
        xxyy = MulVecByVec(xxyy, grad_y0);


        // second chorizo
        Vector4 grad_x12 = PowVec(grad_x1, 2);
        Vector4 grad_y12 = PowVec(grad_y1, 2);
        Vector4 grad_z12 = PowVec(grad_z1, 2);

        Vector4 sumGrad_x12y12z12 = SqrtVec(grad_x12 + grad_y12 + grad_z12);
        Vector4 xyxy2 = VecXyXy(new Vector2(Pf.x, Pf_min1.x));

        Vector4 sumGradByXyXy2 = MulVecByVec(sumGrad_x12y12z12, xyxy2);
        sumGradByXyXy2 = MulVecByVec(sumGradByXyXy2, grad_x1);

        Vector4 xxyy2 = VecXxYy(new Vector2(Pf.y, Pf_min1.y));
        xxyy2 = MulVecByVec(xxyy2, grad_y1);

        Vector4 grad_results_0 = sumGradByXyXy + xxyy + (MulVecByVec(new Vector4(Pf.z, Pf.z, Pf.z, Pf.z), grad_z0));
        Vector4 grad_results_1 = sumGradByXyXy2 + xxyy2 + (MulVecByVec(new Vector4(Pf_min1.z, Pf_min1.z, Pf_min1.z, Pf_min1.z), grad_z1));

        Vector3 blend = Interpolation_C2(Pf);

        Vector4 res0 = Vector4.Lerp(grad_results_0, grad_results_1, blend.z);
        Vector2 res1 = Vector4.Lerp(new Vector2(res0.x, res0.y), new Vector2(res0.z, res0.w), blend.y);

        float final = Mathf.Lerp(res1.x, res1.y, blend.x);
        final *= 1.1547005383792515290182975610039f;

        return final;
    }

    Vector3 Step(Vector3 a, Vector3 x)
    {
        Vector3 step = new Vector3();
        if (x.x >= a.x) step.x = 1;
        else step.x = 0;
        if (x.y >= a.y) step.y = 1;
        else step.y = 0;
        if (x.z >= a.z) step.z = 1;
        else step.z = 0;
        return step;
    }

    Vector3 addFloatToVector(float value, Vector3 v)
    {
        return new Vector3(v.x + value, v.y + value, v.z + value);
    }

    Vector3 divideFloatToVector(float value, Vector3 v)
    {
        return new Vector3(value / v.x, value / v.y, value / v.z);
    }

    Vector4 frac(Vector4 v)
    {
        Vector4 newVector = new Vector4();
        newVector.x = v.x - Mathf.Floor(v.x);
        newVector.y = v.y - Mathf.Floor(v.y);
        newVector.z = v.z - Mathf.Floor(v.z);
        newVector.w = v.w - Mathf.Floor(v.w);
        return v;
    }

    void FAST32_hash_3D(Vector3 gridcell,
    out Vector4 lowz_hash_0,
    out Vector4 lowz_hash_1,
    out Vector4 lowz_hash_2,
    out Vector4 highz_hash_0,
    out Vector4 highz_hash_1,
    out Vector4 highz_hash_2)        //	generates 3 random numbers for each of the 8 cell corners
    {
        //    gridcell is assumed to be an integer coordinate

        Vector2 OFFSET = new Vector2(OFFSETX, OFFSETY);
        Vector3 SOMELARGEFLOATS = new Vector3(SOMELARGEFLOATSX, SOMELARGEFLOATSY, SOMELARGEFLOATSZ);
        Vector3 ZINC = new Vector3(ZINCX, ZINCY, ZINCZ);

        //	truncate the domain
        float gridDom = 1.0f / DOMAIN;
        gridcell = gridcell - new Vector3(Mathf.Floor(gridcell.x * gridDom), Mathf.Floor(gridcell.y * gridDom), Mathf.Floor(gridcell.z * gridDom)) * DOMAIN;
        Vector3 gridcell_inc1 = Step(gridcell, Vector3.Scale(new Vector3(DOMAIN - 1.5f, DOMAIN - 1.5f, DOMAIN - 1.5f), addFloatToVector(1.0f, gridcell)));

        //	calculate the noise
        Vector4 P = new Vector4(gridcell.x, gridcell.y, gridcell_inc1.x, gridcell_inc1.y) + new Vector4(OFFSET.x, OFFSET.y, OFFSET.x, OFFSET.y);

        P = Vector4.Scale(P, P);
        P = Vector4.Scale(new Vector4(P.x, P.z, P.x, P.z), new Vector4(P.y, P.y, P.w, P.w));

        Vector3 lowz_mod = divideFloatToVector(1.0f, (SOMELARGEFLOATS + Vector3.Scale(new Vector3(gridcell.z, gridcell.z, gridcell.z), ZINC)));
        Vector3 highz_mod = divideFloatToVector(1.0f, (SOMELARGEFLOATS + Vector3.Scale(new Vector3(gridcell_inc1.z, gridcell_inc1.z, gridcell_inc1.z), ZINC)));

        lowz_hash_0 = frac(Vector4.Scale(P, new Vector4(lowz_mod.x, lowz_mod.x, lowz_mod.x, lowz_mod.x)));
        highz_hash_0 = frac(Vector4.Scale(P, new Vector4(highz_mod.x, highz_mod.x, highz_mod.x, highz_mod.x)));
        lowz_hash_1 = frac(Vector4.Scale(P, new Vector4(lowz_mod.y, lowz_mod.y, lowz_mod.y, lowz_mod.y)));
        highz_hash_1 = frac(Vector4.Scale(P, new Vector4(highz_mod.y, highz_mod.y, highz_mod.y, highz_mod.y)));
        lowz_hash_2 = frac(Vector4.Scale(P, new Vector4(lowz_mod.z, lowz_mod.z, lowz_mod.z, lowz_mod.z)));
        highz_hash_2 = frac(Vector4.Scale(P, new Vector4(highz_mod.z, highz_mod.z, highz_mod.z, highz_mod.z)));
    }

    Vector2 PerlinNormal(Vector3 p, int octaves, Vector3 offset, float frequency, float amplitude, float lacunarity, float persistence)
    {
        float sum = 0.0f;
        float maxAmp = 0.0f;

        for (int i = 0; i < octaves; i++)
        {
            float h = 0;
            h = Perlin3Dim((p + offset) * frequency);
            sum += h * amplitude;
            frequency *= lacunarity;
            maxAmp += amplitude;
            amplitude *= persistence;
        }

        return new Vector2(sum, maxAmp);
    }

    private Vector3 Interpolation_C2(Vector3 v)
    {
        Vector3 outer = Vector3.Scale(v, v);
        outer = Vector3.Scale(outer, v);

        Vector3 inner = SubFromVec((Vector3.Scale(v, new Vector3(6.0f, 6.0f, 6.0f))), 15.0f);
        inner = Vector3.Scale(inner, v);
        inner += new Vector3(10.0f, 10.0f, 10.0f);

        return Vector3.Scale(inner, outer);
    }

    private Vector4 VecXyXy (Vector2 v)
    {
        return new Vector4(v.x, v.y, v.x, v.y);
    }

    private Vector4 VecXxYy(Vector2 v)
    {
        return new Vector4(v.x, v.x, v.y, v.y);
    }

    private Vector3 FloorVec(Vector3 p)
    {
        p.x = Mathf.Floor(p.x);
        p.y = Mathf.Floor(p.y);
        p.z = Mathf.Floor(p.z);

        return p;
    }

    private Vector3 SubFromVec(Vector3 v, float quantity)
    {
        v.x = v.x - quantity;
        v.y = v.y - quantity;
        v.z = v.z - quantity;

        return v;
    }

    private Vector4 SubFromVec(Vector4 v, float quantity)
    {
        v.x = v.x - quantity;
        v.y = v.y - quantity;
        v.z = v.z - quantity;
        v.w = v.w - quantity;

        return v;
    }

    private Vector4 MulVecByVec(Vector4 a, Vector4 b)
    {
        Vector4 result = Vector3.zero;

        result.x = a.x * b.x;
        result.y = a.y * b.y;
        result.z = a.z * b.z;
        result.w = a.w * b.w;

        return result;
    }

    private Vector4 SqrtVec(Vector4 v)
    {
        v.x = Mathf.Sqrt(v.x);
        v.y = Mathf.Sqrt(v.y);
        v.z = Mathf.Sqrt(v.z);
        v.w = Mathf.Sqrt(v.w);

        return v;
    }

    private Vector4 PowVec(Vector4 v, int power)
    {
        v.x = Mathf.Pow(v.x, power);
        v.y = Mathf.Pow(v.y, power);
        v.z = Mathf.Pow(v.z, power);
        v.w = Mathf.Pow(v.w, power);

        return v;
    }

    #endregion
}