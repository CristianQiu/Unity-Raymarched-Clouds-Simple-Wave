#include "Perlin3D.cginc"

// Extremely nice reading to understand the basics of volume rendering !
// https://www.scratchapixel.com/lessons/advanced-rendering/volume-rendering-for-artists

// raymarching macros
#define FROMCAMSTEPS 16
#define FROMCAMSTEPSIZE 1.0 / (float)FROMCAMSTEPS

#define TOLIGHTSTEPS 4
#define TOLIGHTSTEPSIZE 1.0 / (float)TOLIGHTSTEPS

#define ZEROF 0.0

struct PerlinInfo
{
    float cutOff;
    int octaves;
    float3 offset;
    float freq;
    float amp;
    float lacunarity;
    float persistence;
};

struct SphereInfo
{
    float3 pos;
    float radius;
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

// distance to the limits of the sphere (AKA sphere SDF)
float sphereDist(float3 pos, SphereInfo sphereInfo)
{
    return distance(pos, sphereInfo.pos) - sphereInfo.radius;
}

// raymarching
float4 march(float3 camRayOrig, float3 camRayDir, float3 lightDir, PerlinInfo perlinInfo, SphereInfo sphereInfo, CloudInfo cloudInfo)
{
    // variables initialization
    float3 lightEnergy = float3(0.0f, 0.0f, 0.0f);

    float accumFromCam = 0.0;
    float accumToLight = 0.0;

    float transmittance = 1.0;
    float cloudDensity = 0.0;

    // squish some performance precalculating some stuff...
    float3 camRayStep = camRayDir * FROMCAMSTEPSIZE;
    float3 lightRayStep = lightDir * TOLIGHTSTEPSIZE;

    cloudInfo.density *= FROMCAMSTEPS;
    cloudInfo.absortion *= TOLIGHTSTEPSIZE;

    // the "from cam" march
    for (int i = 0; i < FROMCAMSTEPS; i++)
    {
        // if inside of the sphere, take samples
        if (sphereDist(camRayOrig, sphereInfo) <= ZEROF)
        {
            float fromCamSample = PerlinNormal(camRayOrig, perlinInfo.cutOff, perlinInfo.octaves, perlinInfo.offset, perlinInfo.freq, perlinInfo.amp, perlinInfo.lacunarity, perlinInfo.persistence).x;

            if (fromCamSample > 0.01)
            {
                float3 lightRayPos = camRayOrig;

                // take the initial sample? don't think so
                accumToLight = 0.0;

                // the "to light" march
                for (int j = 0; j < TOLIGHTSTEPS; j++)
                {
                    // if inside of the sphere, take samples
                    if (sphereDist(lightRayPos, sphereInfo) <= ZEROF)
                    {
                        lightRayPos += lightRayStep;

                        float toLightSample = PerlinNormal(lightRayPos, perlinInfo.cutOff, perlinInfo.octaves, perlinInfo.offset, perlinInfo.freq, perlinInfo.amp, perlinInfo.lacunarity, perlinInfo.persistence).x;
                        accumToLight += (toLightSample * TOLIGHTSTEPSIZE); // < 0-1 range if all steps are taken
                    }
                    else
                        break;
                }

                // code straight out http://shaderbits.com/blog/creating-volumetric-ray-marcher with some tweaks that may not be correct for our approach...
                cloudDensity = saturate(fromCamSample * cloudInfo.density);

                float atten = exp(-accumToLight * (cloudInfo.absortion + cloudInfo.outScattering));
                float3 absorbedLight = atten * cloudDensity;

                lightEnergy += (absorbedLight * transmittance);
                transmittance *= (1.0 - cloudDensity);
            }
        }

        camRayOrig += camRayStep;
    }

    return float4(lightEnergy.rgb, transmittance);
}