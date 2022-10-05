/*

  Volume ray casting kernel

  adapted from the Nvidia sdk sample
  http://developer.download.nvidia.com/compute/cuda/4_2/rel/sdk/website/OpenCL/html/samples.html
  mweigert@mpi-cbg.de

  Adapted for Zig + OpenCL starting Wed Oct  6 2021 [coleman.broaddus@gmail.com]
  
  
*/

int intersectBox(float4 r_o, float4 r_d, float4 boxmin, float4 boxmax, float *tnear, float *tfar) {

    // compute intersection of ray with all six bbox planes
    float4 invR = (float4){1.0f,1.0f,1.0f,1.0f} / r_d;
    float4 tbot = invR * (boxmin - r_o);
    float4 ttop = invR * (boxmax - r_o);

    // re-order intersections to find smallest and largest on each axis
    float4 tmin = min(ttop, tbot);
    float4 tmax = max(ttop, tbot);

    // find the largest tmin and the smallest tmax
    float largest_tmin = max(max(tmin.x, tmin.y), max(tmin.x, tmin.z));
    float smallest_tmax = min(min(tmax.x, tmax.y), min(tmax.x, tmax.z));

  *tnear = largest_tmin;
  *tfar = smallest_tmax;

  return smallest_tmax > largest_tmin;
}


#define MPI_2 6.2831853071795f
#define RadPerDegree 0.017453292519943295; // PI/180;


// returns random value between [0,1]
inline float random2(uint x, uint y) {
    uint a = 4421 +(1+x)*(1+y) +x +y;
    for(int i=0; i < 10; i++) {
        a = (1664525 * a + 1013904223) % 79197919;
    }
    float rnd = (a*1.0f)/(79197919);
    return rnd;
}

inline float rand_int2(uint x, uint y, int start, int end) {
    uint a = 4421 +(1+x)*(1+y) +x +y;
    for(int i=0; i < 10; i++){
        a = (1664525 * a + 1013904223) % 79197919;
    }
    float rnd = (a*1.0f)/(79197919);
    return (int)(start+rnd*(end-start));
}




// assumes row-first matrix layout
float4 mult(float M[16], float4 v){
  float4 res;
  res.x = dot(v, (float4){M[0],M[1],M[2],M[3]} );
  res.y = dot(v, (float4){M[4],M[5],M[6],M[7]} );
  res.z = dot(v, (float4){M[8],M[9],M[10],M[11]} );
  res.w = dot(v, (float4){M[12],M[13],M[14],M[15]} );
  return res;
}

#define read_image(volume , sampler , pos , isShortType) (isShortType?1.f*read_imageui(volume, sampler, pos).x:read_imagef(volume, sampler, pos).x)


// Tell me the value of the pixel at a certain location.
__kernel void imgtest(
  uint dx,
  uint dy,
  read_only image2d_t img
  )
{

  uint x = get_global_id(0);
  uint y = get_global_id(1);

  int nx = get_image_width(img);
  int ny = get_image_height(img);

  float u = ((x + 0.5) / (float) nx); //*2.0f-1.0f;
  float v = ((y + 0.5) / (float) ny); //*2.0f-1.0f;

  // d_output[x + 10*y] = (float) (x*y);
  // const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
  const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

  // printf("(%d,%d)",x,y);
  
  // const sampler_t volumeSampler = CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;

  if (x==dx && y==dy){
    float val = read_imagef(img, volumeSampler, (float2) {u,v}).x; // NOTE: pixels accessed by float values must be translated 1/2 pixel from int coordinates.
    printf("x,y = %d & %d value = %f \n",x,y,val);
    printf("u,v = %f & %f value = %f \n",u,v,val);
  }
}


__kernel void enumerateBuffer(
  __global float *d_output 
  )
{
  uint x = get_global_id(0);
  uint y = get_global_id(1);
  d_output[x + 10*y] = (float) (x*y);
}

// Nx,Ny = width & height of output (also compute grid?)
__kernel void max_project_float(
                  read_only image3d_t volume,
                  global uchar4 *d_output,
                  read_only global uchar4 *colormap,
                  uint Nx, 
                  uint Ny,
                  float2 view_angle,
                  float2 global_minmax,
                  read_only global float * _invM
                  )
{

  // clip boxes [normalized volume coords]
  float boxMin_x  = -1.0;
  float boxMax_x  =  1.0;
  float boxMin_y  = -1.0;
  float boxMax_y  =  1.0;
  float boxMin_z  = -1.0; // (1/11.0);
  float boxMax_z  =  1.0; // (1/11.0);

  // intensity clip
  float clipLow    = 0.0;
  float clipHigh    = 1.0;
  float gamma     = 1.0;
  float alpha_pow = 0.0;

  // int zdepth = get_image_depth(volume);

  // for multi-pass rendering
  int currentPart = 0;

  // int numParts = 10;
  // int numParts = (int) max(1.0,float(100)/zdepth); // scale the number of steps 
  // printf("numParts %d \n",numParts);

  // void setProjectionMatrix(const float &angleOfView, const float &near, const float &far, Matrix44f &M) 
  // { 
  //     // set the basic projection matrix
  //     float scale = 1 / tan(angleOfView * 0.5 * M_PI / 180); 
  //     M[0][0] = scale; // scale the x coordinates of the projected point 
  //     M[1][1] = scale; // scale the y coordinates of the projected point 
  //     M[2][2] = -far / (far - near); // used to remap z to [0,1] 
  //     M[3][2] = -far * near / (far - near); // used to remap z [0,1] 
  //     M[2][3] = -1; // set w = -z 
  //     M[3][3] = 0; 
  // } 
  
  view_angle /= 2;
  
  // NORMALIZED COORDS IN [0,1] ! Not [-1,1] !
  // const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
  const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST; // CLK_FILTER_NEAREST

  uint x = get_global_id(0);
  uint y = get_global_id(1);
  uint idx = x+Nx*y;
  // printf("idx = %d \n",idx);


  // Clipping Boxes with domain [-1..1]
  float4 boxMin = (float4){boxMin_x,boxMin_y,boxMin_z,1.f};
  float4 boxMax = (float4){boxMax_x,boxMax_y,boxMax_z,1.f};

  // place origin [view always pointing to image center 0,0,0]
  // find normalized ray direction = [u,v,1] rotated s.t. [0,0,1] points from cam to volume origin
  // normalized pixel coordinates affine transforms volume to [-1,1]^3
  //  all internal coords should be in this space
  //  but then we must transform back to screen 

  // Model View Matrix
  float invM[16];
  for (int i=0; i<16; i++){invM[i] = _invM[i];}
  
  // pixel x,y coordinates in normalized world coords [-1,1]
  float u = ((float) x / (float) (Nx-1))*2.0f-1.0f;
  float v = ((float) y / (float) (Ny-1))*2.0f-1.0f;

  // front and back planes. ray is cast from front → back
  float4 front = (float4){u,v,-1,1}; // start at z coordinate -1
  float4 back  = (float4){u,v, 1,1}; // end at z coordinate 1. (remember, the volume coords are normalized).  

  // Perspective - control size of front and back planes. determine scale of volume and orthographic vs perspective.
  front *= (float4){1.2,1.2,1,1};
  back  *= (float4){1.8,1.8,1,1};
  // View Angle
  front = mult(invM,front);
  back  = mult(invM,back);
  // Anisotropy - voxel size
  front *= (float4){1,1,4,1};
  back  *= (float4){1,1,4,1};

  float4 direc = normalize(back - front);
  direc.w = 0.0f;

  // find intersection with box
  float tnear, tfar;
  int hit = intersectBox(front, direc, boxMin, boxMax, &tnear, &tfar);

  // float r = sqrt(float(u*u) + float(v*v));
  // if (.201<r && r<.204){
  //   d_output[idx] = 0.9f;
  //   d_alpha_output[idx] = -1.f;
  //   d_depth_output[idx] = -1.f;
  //   return;
  // }

  if (!hit) {
    d_output[idx] = (uchar4){0,0,0,255};
    return;
  }

  // // dither the original
  // uint entropy = (uint)( 6779514*length(front) + 6257327*length(direc) );
  // // printf("x,y,rand = %d %d %d \n", x, y , random(x*93939393,y*383838)%100);
  // front += dt*random(entropy+x,entropy+y)*direc;
  // // TODO: how to properly implement dither? Is dither just to prevent aliasing?
  // float jitterx = (random(x*93939393,y*383837)%100) / 100.0 / Nx * 3.0;
  // float jittery = (random(x*23942347,y*294833)%100) / 100.0 / Ny * 3.0;
  // front += (float4) {jitterx,jittery,0,0};



  // Setup Ray stepping geometry
  // if (tnear < 0.0f) tnear = 0.0f;
  // const int reducedSteps = maxSteps; // /numParts
  // const int maxSteps = int(fabs(tfar-tnear)/dt); // assume dt = 1;
  // const float4 delta_pos = direc;
  // float4 pos = 0.5f * (1.f + front + tnear*direc);
  const int maxSteps = 15;
  const float dt = fabs(tfar-tnear)/maxSteps; //((reducedSteps/LOOPUNROLL)*LOOPUNROLL);
  const float4 delta_pos = dt*direc;
  float4 pos = front + tnear*direc;
  float4 maxValPosition = pos;

  // initial values for output
  float maxVal = 0;
  int maxValDepth = 0;

  if (alpha_pow==0) {

    float currentVal = 0.f;

    for(int i=0; i <= maxSteps; ++i){

      currentVal = read_imagef(volume, volumeSampler, pos/2 + float4(0.5)).x;
      maxValDepth = (currentVal > maxVal) ? i : maxValDepth;
      maxValPosition = (currentVal > maxVal) ? pos : maxValPosition;
      maxVal = fmax(maxVal,currentVal);

      // 
      pos += delta_pos;

    }

  } else {
    
    float currentVal = 0.f;
    float cumsum = 1.f; // keep track of multiplicative absorption

    for(int i=0; i <= maxSteps; ++i){

        currentVal = read_imagef(volume, volumeSampler, pos/2 + float4(0.5)).x;
        // currentVal = (maxVal == 0)?currentVal:(currentVal-clipLow)/(clipHigh-clipLow);
        maxValDepth = (cumsum * currentVal > maxVal) ? i : maxValDepth;
        maxValPosition = (currentVal > maxVal) ? pos : maxValPosition;
        maxVal = fmax(maxVal,cumsum*currentVal);

        cumsum  *= (1.f-.1f*alpha_pow*clamp(currentVal,0.f,1.f));
        pos += delta_pos;
        if (cumsum<=0.02f) break;
    
    }

  }

  // float4 maxValPosition = front + direc*maxValDepth;
  float zDepth = maxValPosition.z / 2 + float(0.5);
  maxVal = (maxVal - global_minmax[0])/(global_minmax[1] - global_minmax[0]);
  maxVal = clamp(pow(maxVal,gamma),0.f,1.f);
  float alphaVal = clamp(maxVal,0.f,1.f);
  
  // d_output[idx] = convert_uchar4(temp);
  uchar4 color = colormap[uchar(255*zDepth)];
  d_output[idx] = convert_uchar4(convert_float4(color) * float4(maxVal));
  // float4 temp = (float4){255,255,255,255} * float4(maxVal); // * float4(zDepth);
  // d_output[idx] = uchar4(maxVal*255);

  return;
}

