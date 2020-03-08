float perc(float t1, float t2, float t)
{
	return saturate( (t - t1) / (t2 - t1) );
}