
// This doesn't help... still can only printf once per thread.
// #pragma OPENCL EXTENSION cl_amd_printf : enable


/*

  Volume ray casting kernel

  adapted from the Nvidia sdk sample
  http://developer.download.nvidia.com/compute/cuda/4_2/rel/sdk/website/OpenCL/html/samples.html
  mweigert@mpi-cbg.de

  Adapted for Zig + OpenCL starting Wed Oct  6 2021 [coleman.broaddus@gmail.com]
*/

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
  float theta;
  float phi;
}  View ; 

void printview(View v) {
  printf("view matrix \n");
  // for (int i=0;i<9;i++) {printf("%2.2f ",v.view_matrix[i]);}
  // printf("\nfront_scale %2.2v3hlf \n" , v.front_scale);
  // printf("back_scale %2.2v3hlf" , v.back_scale);
  // printf("anisotropy %2.2v3hlf  \n" , v.anisotropy);
  // printf("screen_size %3v2d \n" , v.screen_size);
}

typedef struct {
  float3 orig;
  float3 direc;
}  Ray ;

void printray(Ray r) {
  printf("orig %2.2v3hlf \n",  r.orig);
  // printf("direc %2.2v3hlf \n", r.direc);
}


// Find the ray corresponding to a virutal pixel in the simulated image plane.
Ray pix2Ray(uint2 pix , View view, uint idx) {

  float2 xy = (float2){2.0f*pix[0]/(float)(view.screen_size[0]-1) - 1, 
                       2.0f*pix[1]/(float)(view.screen_size[1]-1) - 1};

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

// Nx,Ny = width & height of output (also compute grid?)
__kernel void max_project_float(
                  read_only image3d_t volume,
                  global uchar4 *d_output,
                  global float *d_zbuffer,
                  global uchar4 *colormap,
                  uint Nx, 
                  uint Ny,
                  float2 global_minmax,
                  View view,
                  ushort3 volume_dims
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
  // float clipLow   = 0.0;
  // float clipHigh  = 1.0;
  // float gamma     = 1.0;

  // int zdepth = get_image_depth(volume);

  // for multi-pass rendering
  // int currentPart = 0;
  
  // NORMALIZED COORDS IN [0,1] ! Not [-1,1] !
  const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP | CLK_FILTER_NEAREST; // CLK_FILTER_NEAREST

  uint x = get_global_id(0);
  uint y = get_global_id(1);
  uint idx = x+Nx*y;

  // float maxxy = 0;
  // for (int i=0; i<volume_dims[2]; i++) {
  //   float4 pos = (float4){(float3){x,y,i} / convert_float3(volume_dims) , 0};
  //   float val = read_imagef(volume, volumeSampler, pos).x;
  //   if (val > maxxy) {
  //     maxxy = val;
  //   }
  // }
  // d_output[idx] = maxxy;
  // return; 

  if (idx==0) {
    // printf("theta = %f \n", view.theta);
    // printview(view);
    // printray(r);
  }

  // Clipping Boxes with domain [-1..1]
  float3 boxMin = (float3){boxMin_x,boxMin_y,boxMin_z};
  float3 boxMax = (float3){boxMax_x,boxMax_y,boxMax_z};

  // find ray and intersection with box
  Ray r = pix2Ray((uint2){x,y},view,idx);
  float tnear, tfar;
  int hit = intersectBox3(r.orig, r.direc, boxMin, boxMax, &tnear, &tfar);
  // if (idx==181248) {printray(r);}
  
  if (!hit) {
    d_output[idx] = (uchar4){75,75,0,255};
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
  const int maxSteps = 30; //15;
  
  /// tfar and tnear are scalar multipliers that solve
  /// r.orig + tnear * r.direc = near_intersection_pt
  /// r.orig + tfar * r.direc = far_intersection_pt
  const float dt = fabs(tfar-tnear)/maxSteps; //((reducedSteps/LOOPUNROLL)*LOOPUNROLL);
  // const float dt = 1 / 35.0;
  // const float dt = 1.0 / dot(r.direc, convert_float3(volume_dims)) * 4.0;
  // const float dt = 0.1; // dot(r.direc, view.anisotropy);
  
  // delta_pos, pos, maxValPosition are re-normalized into [0,1] for access into read_imagef() with normalized coords
  const float4 delta_pos = (float4){dt*r.direc/2, 0};
  float4 pos = (float4){(r.orig+tnear*r.direc)/2 + (float3)(0.5), 0};
  float4 maxValPosition = pos;
  
  // if (x==300 && y==300) {
  //   printview(view);
  //   printf("RAY = \n");
  //   printray(r);
  //   printf("tnear %6.3f, tfar = %6.3f \n", tnear, tfar);
  //   // printf("currentVal = %6.3f \n", );
  //   printf("The INITIAL pos = %6.3f %6.3f %6.3f %6.3f \n", pos.x , pos.y, pos.z, pos.w);
  //   printf("delta_pos = %6.3f %6.3f %6.3f %6.3f \n", delta_pos.x, delta_pos.y, delta_pos.z, delta_pos.w);
  //   printf("dt = %6.3f \n", dt);
  // }

  // initial values for output
  float maxVal = 0;
  int maxValDepth = 0;

  float alpha_pow = 0.1;


  // Perform the max projection
  if (alpha_pow==0) {

    float currentVal = 0.f;

    for(int i=0; i <= maxSteps; ++i){

      currentVal = read_imagef(volume, volumeSampler, pos).x;
      // if ((pos.x-0.5)<1e-2 and (pos.)) {printf("position = %2.2v4hlf \n", pos);}
      // if (idx%1000==0) {printf("currentVal = %6.3f \n", currentVal);}
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

        currentVal = read_imagef(volume, volumeSampler, pos).x;

        // if (max(pos.x, max(pos.y,pos.z))>1.001) {
        //   printf("currentVal = %6.3f \n", currentVal);
        //   printf("pos = %6.3f %6.3f %6.3f %6.3f \n", pos.x , pos.y, pos.z, pos.w);
        // }
        // if (x==300 && y==300) {
        // }
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
  float zDepth = maxValPosition.z;
  maxVal = (maxVal - global_minmax[0])/(global_minmax[1] - global_minmax[0]);
  float gamma = 1.0;
  maxVal = clamp(pow(maxVal,gamma),0.f,1.f);
  // float alphaVal = clamp(maxVal,0.f,1.f);
  
  // d_output[idx] = convert_uchar4(temp);
  uchar4 color = colormap[ (uchar)(255*zDepth) ];
  uchar4 val;
  val = convert_uchar4(convert_float4(color) * float4(maxVal));
  // val = (uchar4){255,maxVal,maxVal,255};
  // val.z = 0;
  d_output[idx] = val;

  d_zbuffer[idx] = maxValDepth * dt + tnear;
  // float4 temp = (float4){255,255,255,255} * float4(maxVal); // * float4(zDepth);
  // d_output[idx] = uchar4(maxVal*255);

  // char stringfloat[1000] = {};
  // sprintf(&stringfloat, "this is a string\n\n");

  return;
}

