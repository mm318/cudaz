#include "tuple.h"

extern "C" __global__ void offset(tuple *in, float *out)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    out[i] = in[i].y - in[i].x;
}

extern "C" void launchOffset(dim3 block_dim, dim3 grid_dim, tuple *in, float *out)
{
    offset<<<block_dim, grid_dim>>>(in, out);
}
