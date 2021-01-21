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
    float outScattering;
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

        t1 = ro + rd * tx1;
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
float4 march(float3 roJittered, float3 ro, float3 rd, float3 lightDir, SphereInfo sphereInfo, PerlinInfo perlinInfo, CloudInfo cloudInfo)
{
    float s = sphereInfo.pos;
    float r = sphereInfo.radius;

    float3 t1 = float3(0.0, 0.0, 0.0);
    float3 t2 = float3(0.0, 0.0, 0.0);

    bool intersectsSphere = raySphereIntersection(ro, rd, s, r, t1, t2);

    if (!intersectsSphere)
        return float4(0.0, 0.0, 0.0, 0.0);

    // I'm unsure about the correctness of the jitter since intersecting with the sphere is already offsetting... It definitely improves the quality still though.
    float3 jitter = roJittered - ro;
    t1 += jitter;

    // set the number of raymarching steps
    const int MarchSteps = 12;
    const float MarchStepSize = (r * 2.0) / (float)MarchSteps;

    float accum = 0.0;
    int numSamples = 0;

    float3 lightEnergy = float3(0.0f, 0.0f, 0.0f);

    float transmittance = 1.0;
    float cloudDensity = 0.0;

    // precalculate rays steps
    float3 camRayStep = rd * MarchStepSize;
    float3 lightRayStep = lightDir * MarchStepSize;

    cloudInfo.density *= MarchSteps;
    cloudInfo.absortion *= MarchSteps;

    // march from the camera
    for (int i = 0; i < MarchSteps; i++)
    {
        // if outside of the sphere, end
        if (sphereDist(t1, s, r) >= 0.0)
            break;

        float fromCamSample = PerlinNormal(t1, perlinInfo.cutOff, perlinInfo.octaves, perlinInfo.offset, perlinInfo.freq, perlinInfo.amp, perlinInfo.lacunarity, perlinInfo.persistence).x;

        // say goodbye to performance with the help of nested raymarching + perlin octaves :) 
        if (fromCamSample > 0.001)
        {
            // this will produce shadow banding but idk how to simulate the dither effect that is done with the camera march
            float3 lightRayPos = t1;

            // take the initial sample? would that be like selfshadowing?
            float accumToLight = 0.0;

            // march to the light
            for (int j = 0; j < MarchSteps; j++)
            {
                // if inside of the sphere, take samples
                if (sphereDist(lightRayPos, s, r) <= 0.0)
                {
                    lightRayPos += lightRayStep;

                    float toLightSample = PerlinNormal(lightRayPos, perlinInfo.cutOff, perlinInfo.octaves, perlinInfo.offset, perlinInfo.freq, perlinInfo.amp, perlinInfo.lacunarity, perlinInfo.persistence).x;
                    accumToLight += (toLightSample * MarchStepSize); // < 0-1 range if all steps are taken
                }
                else
                    break;
            }

            // code adapted from http://shaderbits.com/blog/creating-volumetric-ray-marcher
            cloudDensity = saturate(fromCamSample * cloudInfo.density);

            float atten = exp(-accumToLight * (cloudInfo.absortion + cloudInfo.outScattering));
            float3 absorbedLight = atten * cloudDensity;

            lightEnergy += (absorbedLight * transmittance);
            transmittance *= (1.0 - cloudDensity);
        }

        t1 += camRayStep;
    }

    return float4(lightEnergy.rgb, 1.0 - transmittance);
}

//float4 march(float3 roJittered, float3 ro, float3 rd, float3 lightDir, PerlinInfo perlinInfo, SphereInfo sphereInfo, CloudInfo cloudInfo)
//{
//    float3 t1 = 0.0;
//    float3 t2 = 0.0;
//
//    bool intersectsSphere = raySphereIntersection(ro, rd, sphereInfo, t1, t2);
//
//    if (!intersectsSphere)
//        return float4(0.0, 0.0, 0.0, 0.0);
//
//    float3 lightEnergy = float3(0.0f, 0.0f, 0.0f);
//
//    float accumFromCam = 0.0;
//    float accumToLight = 0.0;
//
//    float transmittance = 1.0;
//    float cloudDensity = 0.0;
//
//    // precalculate rays steps
//    float3 camRayStep = rd * CAMSTEPSIZE;
//    float3 lightRayStep = lightDir * LIGHTSTEPSIZE;
//
//    cloudInfo.density *= CAMSTEPS;
//    cloudInfo.absortion *= LIGHTSTEPSIZE;
//
//    // march from the camera
//    for (int i = 0; i < CAMSTEPS; i++)
//    {
//        // if inside of the sphere, take samples
//        if (sphereDist(ro, sphereInfo) <= 0.0)
//        {
//            float fromCamSample = PerlinNormal(roJittered, perlinInfo.cutOff, perlinInfo.octaves, perlinInfo.offset, perlinInfo.freq, perlinInfo.amp, perlinInfo.lacunarity, perlinInfo.persistence).x;
//
//            // say goodbye to performance with the help of nested raymarching + perlin octaves :) 
//            if (fromCamSample > 0.01)
//            {
//                // this will produce shadow banding but idk how to simulate the dither effect that is done with the camera march
//                float3 lightRayPos = roJittered;
//
//                // take the initial sample? would that be like selfshadowing?
//                accumToLight = 0.0;
//
//                // march to the light
//                for (int j = 0; j < LIGHTSTEPS; j++)
//                {
//                    // if inside of the sphere, take samples
//                    if (sphereDist(lightRayPos, sphereInfo) <= 0.0)
//                    {
//                        lightRayPos += lightRayStep;
//
//                        float toLightSample = PerlinNormal(lightRayPos, perlinInfo.cutOff, perlinInfo.octaves, perlinInfo.offset, perlinInfo.freq, perlinInfo.amp, perlinInfo.lacunarity, perlinInfo.persistence).x;
//                        accumToLight += (toLightSample * LIGHTSTEPSIZE); // < 0-1 range if all steps are taken
//                    }
//                    else
//                        break;
//                }
//
//                // code adapted from http://shaderbits.com/blog/creating-volumetric-ray-marcher
//                cloudDensity = saturate(fromCamSample * cloudInfo.density);
//
//                float atten = exp(-accumToLight * (cloudInfo.absortion + cloudInfo.outScattering));
//                float3 absorbedLight = atten * cloudDensity;
//
//                lightEnergy += (absorbedLight * transmittance);
//                transmittance *= (1.0 - cloudDensity);
//            }
//        }
//
//        ro += camRayStep;
//    }
//
//    return float4(lightEnergy.rgb, transmittance);
//}