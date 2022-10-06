/*

  Volume ray casting kernel

  adapted from the Nvidia sdk sample
  http://developer.download.nvidia.com/compute/cuda/4_2/rel/sdk/website/OpenCL/html/samples.html
  mweigert@mpi-cbg.de

  Adapted for Zig + OpenCL starting Wed Oct  6 2021 [coleman.broaddus@gmail.com]
  
  
*/

// deprecated 
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

int intersectBox3(float3 r_o, float3 r_d, float3 boxmin, float3 boxmax, float *tnear, float *tfar) {

    // compute intersection of ray with all six bbox planes
    float3 invR = (float3){1.0f,1.0f,1.0f,} / r_d;
    float3 tbot = invR * (boxmin - r_o);
    float3 ttop = invR * (boxmax - r_o);

    // re-order intersections to find smallest and largest on each axis
    float3 tmin = min(ttop, tbot);
    float3 tmax = max(ttop, tbot);

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
float4 mult4(float M[16], float4 v){
  float4 res;
  res.x = dot(v, (float4){M[0],M[1],M[2],M[3]} );
  res.y = dot(v, (float4){M[4],M[5],M[6],M[7]} );
  res.z = dot(v, (float4){M[8],M[9],M[10],M[11]} );
  res.w = dot(v, (float4){M[12],M[13],M[14],M[15]} );
  return res;
}

float3 mult3(float M[9], float3 v){
  float3 res;
  res.x = dot(v, (float3){M[0],M[1],M[2] } );
  res.y = dot(v, (float3){M[3],M[4],M[5] } );
  res.z = dot(v, (float3){M[6],M[7],M[8] } );
  return res;
}


typedef struct {
  float view_matrix[9] ;
  float3 front_scale ;
  float3 back_scale ;
  float3 anisotropy ;
  uint2 screen_size ;
}  View ; 

void printview(View v) {
  printf("view matrix \n" , v.view_matrix);
  for (int i=0;i<9;i++) {printf("%2.2f ",v.view_matrix[i]);}
  printf("\nfront_scale %2.2v3hlf \n" , v.front_scale);
  printf("back_scale %2.2v3hlf  \n" , v.back_scale);
  printf("anisotropy %2.2v3hlf  \n" , v.anisotropy);
  printf("screen_size %3v2d \n" , v.screen_size);
}

typedef struct {
  float3 orig;
  float3 direc;
}  Ray ;

void printray(Ray r) {
  printf("orig %2.2v3hlf \n",  r.orig);
  printf("direc %2.2v3hlf \n", r.direc);
}


Ray pix2Ray(uint2 pix , View view, uint idx) {

  // pixel x,y coordinates in normalized world coords [-1,1]
  // float u = ((float) x / (float) (Nx-1))*2.0f-1.0f;
  // float v = ((float) y / (float) (Ny-1))*2.0f-1.0f;

  // float2 xy = ((float2){2,2}*(float2)(pix))/((float2)(view.screen_size) + (float2){1,1}) - (float2){1,1};
  float2 xy = (float2){2.0f*pix[0]/(float)(view.screen_size[0]-1) - 1, 2.0f*pix[1]/(float)(view.screen_size[1]-1) - 1};

  // if (idx==181248) printf("xy = %2.2v2hlf \n", xy);

  float3 front = { xy[0], xy[1], -1 };
  float3 back = { xy[0], xy[1], 1 };
  front *= view.front_scale;
  back *= view.back_scale;
  front = mult3(view.view_matrix, front);
  back = mult3(view.view_matrix, back);
  front *= view.anisotropy;
  back *= view.anisotropy;

  float3 direc = normalize(back - front);
  Ray r = { .orig = front, .direc = direc };
  return r;
}


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
                  float2 global_minmax,
                  read_only View view
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
  float clipLow   = 0.0;
  float clipHigh  = 1.0;
  float gamma     = 1.0;
  float alpha_pow = 0.0;

  // int zdepth = get_image_depth(volume);

  // for multi-pass rendering
  int currentPart = 0;
  
  // NORMALIZED COORDS IN [0,1] ! Not [-1,1] !
  const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST; // CLK_FILTER_NEAREST

  uint x = get_global_id(0);
  uint y = get_global_id(1);
  uint idx = x+Nx*y;

  // if (idx==0) {
  //   printview(view);
  //   // printray(r);
  // }

  // Clipping Boxes with domain [-1..1]
  float3 boxMin = (float3){boxMin_x,boxMin_y,boxMin_z};
  float3 boxMax = (float3){boxMax_x,boxMax_y,boxMax_z};

  // find ray and intersection with box
  Ray r = pix2Ray((uint2){x,y},view,idx);
  float tnear, tfar;
  int hit = intersectBox3(r.orig, r.direc, boxMin, boxMax, &tnear, &tfar);
  // if (idx==181248) {printray(r);}
  
  if (!hit) {
    d_output[idx] = (uchar4){0,0,0,255};
    return;
  }

  // // dither the original
  // uint entropy = (uint)( 6779514*length(r.orig) + 6257327*length(r.direc) );
  // // printf("x,y,rand = %d %d %d \n", x, y , random(x*93939393,y*383838)%100);
  // r.orig += dt*random(entropy+x,entropy+y)*r.direc;
  // // TODO: how to properly implement dither? Is dither just to prevent aliasing?
  // float jitterx = (random(x*93939393,y*383837)%100) / 100.0 / Nx * 3.0;
  // float jittery = (random(x*23942347,y*294833)%100) / 100.0 / Ny * 3.0;
  // r.orig += (float4) {jitterx,jittery,0,0};

  // Setup Ray stepping geometry
  // if (tnear < 0.0f) tnear = 0.0f;
  // const int reducedSteps = maxSteps; // /numParts
  // const int maxSteps = int(fabs(tfar-tnear)/dt); // assume dt = 1;
  // const float4 delta_pos = r.direc;
  // float4 pos = 0.5f * (1.f + r.orig + tnear*r.direc);
  const int maxSteps = 15;
  const float dt = fabs(tfar-tnear)/maxSteps; //((reducedSteps/LOOPUNROLL)*LOOPUNROLL);
  const float3 delta_pos = dt*r.direc;
  float3 pos = r.orig + tnear*r.direc;
  float3 maxValPosition = pos;

  // initial values for output
  float maxVal = 0;
  int maxValDepth = 0;

  if (alpha_pow==0) {

    float currentVal = 0.f;

    for(int i=0; i <= maxSteps; ++i){

      float4 npos = (float4){pos/2 + float3(0.5) , 0};
      // if (idx==181248) {printf("position = %2.2v4hlf \n", npos);}
      currentVal = read_imagef(volume, volumeSampler, npos).x;
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

        currentVal = read_imagef(volume, volumeSampler, (float4){pos/2 + float3(0.5) , 0}).x;
        // currentVal = (maxVal == 0)?currentVal:(currentVal-clipLow)/(clipHigh-clipLow);
        maxValDepth = (cumsum * currentVal > maxVal) ? i : maxValDepth;
        maxValPosition = (currentVal > maxVal) ? pos : maxValPosition;
        maxVal = fmax(maxVal,cumsum*currentVal);

        cumsum  *= (1.f-.1f*alpha_pow*clamp(currentVal,0.f,1.f));
        pos += delta_pos;
        if (cumsum<=0.02f) break;
    
    }

  }

  // float4 maxValPosition = r.orig + r.direc*maxValDepth;
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

