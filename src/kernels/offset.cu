extern "C" __global__ void offset(tuple *in, float *out)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    out[i] = in[i].y - in[i].x;
}
