//	FAST32_hash
//	A very fast hashing function.  Requires 32bit support.
//	http://briansharpe.wordpress.com/2011/11/15/a-fast-and-simple-32bit-floating-point-hash-function/
//
//	The hash formula takes the form....
//	hash = mod( coord.x * coord.x * coord.y * coord.y, SOMELARGEFLOAT ) / SOMELARGEFLOAT
//	We truncate and offset the domain to the most interesting part of the noise.
//	SOMELARGEFLOAT should be in the range of 400.0->1000.0 and needs to be hand picked.  Only some give good results.
//	3D Noise is achieved by offsetting the SOMELARGEFLOAT value by the Z coordinate
//
void FAST32_hash_3D(float3 gridcell,
	out float4 lowz_hash_0,
	out float4 lowz_hash_1,
	out float4 lowz_hash_2,
	out float4 highz_hash_0,
	out float4 highz_hash_1,
	out float4 highz_hash_2)		//	generates 3 random numbers for each of the 8 cell corners
{
	//    gridcell is assumed to be an integer coordinate

	//	TODO: 	these constants need tweaked to find the best possible noise.
	//			probably requires some kind of brute force computational searching or something....
	const float2 OFFSET = float2(50.0, 161.0);
	const float DOMAIN = 69.0;
	const float3 SOMELARGEFLOATS = float3(635.298681, 682.357502, 668.926525);
	const float3 ZINC = float3(48.500388, 65.294118, 63.934599);

	//	truncate the domain
	gridcell.xyz = gridcell.xyz - floor(gridcell.xyz * (1.0 / DOMAIN)) * DOMAIN;
	float3 gridcell_inc1 = step(gridcell, float3(DOMAIN - 1.5, DOMAIN - 1.5, DOMAIN - 1.5)) * (gridcell + 1.0);

	//	calculate the noise
	float4 P = float4(gridcell.xy, gridcell_inc1.xy) + OFFSET.xyxy;
	P *= P;
	P = P.xzxz * P.yyww;
	float3 lowz_mod = float3(1.0 / (SOMELARGEFLOATS.xyz + gridcell.zzz * ZINC.xyz));
	float3 highz_mod = float3(1.0 / (SOMELARGEFLOATS.xyz + gridcell_inc1.zzz * ZINC.xyz));
	lowz_hash_0 = frac(P * lowz_mod.xxxx);
	highz_hash_0 = frac(P * highz_mod.xxxx);
	lowz_hash_1 = frac(P * lowz_mod.yyyy);
	highz_hash_1 = frac(P * highz_mod.yyyy);
	lowz_hash_2 = frac(P * lowz_mod.zzzz);
	highz_hash_2 = frac(P * highz_mod.zzzz);
}

//	Interpolation functions
//	( smoothly increase from 0.0 to 1.0 as x increases linearly from 0.0 to 1.0 )
//	http://briansharpe.wordpress.com/2011/11/14/two-useful-interpolation-functions-for-noise-development/

float3 Interpolation_C2(float3 x) { return x * x * x * (x * (x * 6.0 - 15.0) + 10.0); }

//	Perlin Noise 3D  ( gradient noise )
//	Return value range of -1.0->1.0
//	http://briansharpe.files.wordpress.com/2011/11/perlinsample.jpg

float Perlin3D(float3 P)
{
	//	establish our grid cell and unit position
	float3 Pi = floor(P);
	float3 Pf = P - Pi;
	float3 Pf_min1 = Pf - 1.0;

	//
	//	classic noise.
	//	requires 3 random values per point.  with an efficent hash function will run faster than improved noise
	//

	//	calculate the hash.
	//	( various hashing methods listed in order of speed )
	float4 hashx0, hashy0, hashz0, hashx1, hashy1, hashz1;
	FAST32_hash_3D(Pi, hashx0, hashy0, hashz0, hashx1, hashy1, hashz1);

	//	calculate the gradients
	float4 grad_x0 = hashx0 - 0.49999;
	float4 grad_y0 = hashy0 - 0.49999;
	float4 grad_z0 = hashz0 - 0.49999;
	float4 grad_x1 = hashx1 - 0.49999;
	float4 grad_y1 = hashy1 - 0.49999;
	float4 grad_z1 = hashz1 - 0.49999;
	float4 grad_results_0 = rsqrt(grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0) * (float2(Pf.x, Pf_min1.x).xyxy * grad_x0 + float2(Pf.y, Pf_min1.y).xxyy * grad_y0 + Pf.zzzz * grad_z0);
	float4 grad_results_1 = rsqrt(grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1) * (float2(Pf.x, Pf_min1.x).xyxy * grad_x1 + float2(Pf.y, Pf_min1.y).xxyy * grad_y1 + Pf_min1.zzzz * grad_z1);

	//	Classic Perlin Interpolation
	float3 blend = Interpolation_C2(Pf);
	float4 res0 = lerp(grad_results_0, grad_results_1, blend.z);
	float2 res1 = lerp(res0.xy, res0.zw, blend.y);
	float final = lerp(res1.x, res1.y, blend.x);
	final *= 1.1547005383792515290182975610039;		//	(optionally) scale things to a strict -1.0->1.0 range    *= 1.0/sqrt(0.75)

    final = (final + 1.0) * 0.5;

	return final;
}

float InverseLerp(float val, float min, float max)
{
	return saturate((val - min) / (max - min));
}

float Remap(float val, float origMin, float origMax, float destMin, float destMax)
{
	float t = InverseLerp(val, origMin, origMax);
	return lerp(destMin, destMax, t);
}

float2 PerlinNormal(float3 p, float cutOff, int octaves, float3 offset, float frequency, float amplitude, float lacunarity, float persistence)
{
	float sum = 0.0;
	float maxAmp = 0.0;

	for (int i = 0; i < octaves; i++)
	{
        float h = Perlin3D((p + offset) * frequency);

		sum += h * amplitude;
		maxAmp += amplitude;

        frequency *= lacunarity;
		amplitude *= persistence;
	}

    if (sum <= cutOff)
        sum = 0.0;
    else
        Remap(sum, cutOff, 1.0, 0.0, 1.0);

    return float2(sum, maxAmp);
}