#include "Perlin3D.cginc"

// Extremely nice reading to understand the basics of volume rendering !
// https://www.scratchapixel.com/lessons/advanced-rendering/volume-rendering-for-artists
struct SphereInfo
{
    float3 pos;
    float radius;
};

struct PerlinInfo
{
    float3 offset;
    int octaves;
    float cutOff;
    float freq;
    float amp;
    float lacunarity;
    float persistence;
};

struct CloudInfo
{
    float density;
    float absortion;
};

// interleaved gradient noise mentioned in 
// http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare (slide 122)
float IGN(float2 screenXy)
{
    const float3 magic = float3(0.06711056, 0.00583715, 52.9829189);

    return frac(magic.z * frac(dot(screenXy, magic.xy)));
}

// get whether the ray with origin and direction intersects with the sphere with position s and radius r, and return the entry and exit points
bool raySphereIntersection(float3 ro, float3 rd, float3 s, float r, out float3 t1, out float3 t2)
{
    float t = dot(s - ro, rd);
    float3 p = ro + rd * t;

    float y = length(s - p);

    if (y < r)
    {
        float x = sqrt(r * r - y * y);

        float tx1 = t - x;
        float tx2 = t + x;

        t1 = t < 0.0 ? ro : ro + rd * tx1;
        t2 = ro + rd * tx2;

        return true;
    }

    return false;
}

// distance to the limits of the sphere (AKA sphere SDF)
float sphereDist(float3 pos, float3 s, float3 r)
{
    return distance(pos, s) - r;
}

// raymarching
float4 march(float3 ro, float3 roJittered, float3 rd, float3 lightDir, SphereInfo sphereInfo, PerlinInfo perlinInfo, CloudInfo cloudInfo)
{
    float s = sphereInfo.pos;
    float r = sphereInfo.radius;

    float3 t1 = float3(0.0, 0.0, 0.0);
    float3 t2 = float3(0.0, 0.0, 0.0);

    bool intersectsSphere = raySphereIntersection(ro, rd, s, r, t1, t2);

    if (!intersectsSphere)
        return float4(0.0, 0.0, 0.0, 0.0);

    // set the number of raymarching steps, we are always taking the same number of samples inside the sphere no matter the distance traveled inside
    // TODO: if the distance for each step is so small that is insignificant, we could probably get away with one sample...
    const int MarchSteps = 8;
    float distInsideSphere = distance(t1, t2);
    float marchStepSize = distInsideSphere / (float)MarchSteps;
    
    // Jittering is nowhere near accurate, since intersecting is already offsetting the rays. 
    // The fact that we will also take the same number of samples inside the sphere no matter what distance we travel inside is also another factor why this jitter is "not correct".
    // Still, it improves the quality a lot so I apply it anyway...
    float3 jitter = roJittered - ro;
    t1 += jitter * marchStepSize;

    float3 lightEnergy = float3(0.0f, 0.0f, 0.0f);
    float transmittance = 1.0;

    // march from the camera
    for (int i = 0; i < MarchSteps; i++)
    {
        float fromCamSample = PerlinNormal(t1, perlinInfo.cutOff, perlinInfo.octaves, perlinInfo.offset, perlinInfo.freq, perlinInfo.amp, perlinInfo.lacunarity, perlinInfo.persistence);

        if (fromCamSample > 0.01)
        {
            float3 t3 = 0.0;
            float3 t4 = 0.0;

            // find the exit point (t4)
            raySphereIntersection(t1, lightDir, s, r, t3, t4);
            float distInsideSphereToLight = distance(t1, t4);
            float marchStepSizeToLight = distInsideSphereToLight / (float)MarchSteps;

            float3 lightRayPos = t1;
            float accumToLight = 0.0;

            // say goodbye to performance with the help of nested raymarching + perlin octaves :) 
            for (int j = 0; j < MarchSteps; j++)
            {
                float toLightSample = PerlinNormal(lightRayPos, perlinInfo.cutOff, perlinInfo.octaves, perlinInfo.offset, perlinInfo.freq, perlinInfo.amp, perlinInfo.lacunarity, perlinInfo.persistence);
                accumToLight += (toLightSample * marchStepSizeToLight);

                lightRayPos += (lightDir * marchStepSizeToLight);
            }

            float cloudDensity = saturate(fromCamSample * cloudInfo.density);

            float atten = exp(-accumToLight * cloudInfo.absortion);
            float3 absorbedLight = atten * cloudDensity;

            lightEnergy += (absorbedLight * transmittance);
            transmittance *= (1.0 - cloudDensity);
        }

        t1 += (rd * marchStepSize);
    }

    return float4(lightEnergy.rgb, 1.0 - transmittance);
}
