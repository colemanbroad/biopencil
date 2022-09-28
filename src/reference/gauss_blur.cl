__global__
void gaussian_blur(const unsigned char* const inputChannel,
                   unsigned char* const outputChannel,
                   int numRows, int numCols,
                   const float* const filter, const int filterWidth)
{
  const int2 thread_2D_pos = make_int2( blockIdx.x * blockDim.x + threadIdx.x,
                                        blockIdx.y * blockDim.y + threadIdx.y);
  const int thread_1D_pos = thread_2D_pos.y * numCols + thread_2D_pos.x;

  if (thread_2D_pos.x >= numCols || thread_2D_pos.y >= numRows)
  {
      return;  // "this output pixel" is out-of-bounds. Do not compute
  }

  int j, k, jn, kn, filterIndex = 0;
  float value = 0.0;
  int2 pixel_2D_pos;
  int pixel_1D_pos;

  // Now we'll process input pixels.
  // Note the use of max(0, min(thread_2D_pos.x + j, numCols-1)),
  // which is a way to clamp the coordinates to the borders.
  for(k = -filterWidth/2; k <= filterWidth/2; ++k)
  {
      pixel_2D_pos.y = max(0, min(thread_2D_pos.y + k, numRows-1));
      for(j = -filterWidth/2; j <= filterWidth/2; ++j,++filterIndex)
      {
          pixel_2D_pos.x = max(0, min(thread_2D_pos.x + j, numCols-1));
          pixel_1D_pos =  pixel_2D_pos.y * numCols + pixel_2D_pos.x;

          value += ((float)(inputChannel[pixel_1D_pos])) * filter[filterIndex];
      }
  }

    outputChannel[thread_1D_pos] = (unsigned char)value;
} 