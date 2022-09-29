/*

  Volume ray casting kernel

  adapted from the Nvidia sdk sample
  http://developer.download.nvidia.com/compute/cuda/4_2/rel/sdk/website/OpenCL/html/samples.html
  mweigert@mpi-cbg.de

  Update - Wed Oct  6 2021 - coleman.broaddus@gmail.com
  Adapted for Zig + OpenCL.
  
 */

// #include <utils.cl>

#define LOOPUNROLL 16

int intersectBox(float4 r_o, float4 r_d, float4 boxmin, float4 boxmax, float *tnear, float *tfar)
{
    // compute intersection of ray with all six bbox planes
    float4 invR = (float4)(1.0f,1.0f,1.0f,1.0f) / r_d;
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


// returns random value between [0,1]
inline float random2(uint x, uint y)
{   
    uint a = 4421 +(1+x)*(1+y) +x +y;

    for(int i=0; i < 10; i++)
    {
        a = (1664525 * a + 1013904223) % 79197919;
    }

    float rnd = (a*1.0f)/(79197919);

    return rnd;

}

inline float rand_int2(uint x, uint y, int start, int end)
{
    uint a = 4421 +(1+x)*(1+y) +x +y;

    for(int i=0; i < 10; i++)
    {
        a = (1664525 * a + 1013904223) % 79197919;
    }

    float rnd = (a*1.0f)/(79197919);

    return (int)(start+rnd*(end-start));

}



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

// float4 mult(__CONSTANT float* M, float4 v){

// assumes row-first matrix layout
float4 mult(__constant float* M, float4 v){
  float4 res;
  res.x = dot(v, (float4)(M[0],M[1],M[2],M[3]));
  res.y = dot(v, (float4)(M[4],M[5],M[6],M[7]));
  res.z = dot(v, (float4)(M[8],M[9],M[10],M[11]));
  res.w = dot(v, (float4)(M[12],M[13],M[14],M[15]));
  return res;
}


#define read_image(volume , sampler , pos , isShortType) (isShortType?1.f*read_imageui(volume, sampler, pos).x:read_imagef(volume, sampler, pos).x)


// #define whynot if ((x==150 || x==200|| x==250) && (y==150 || y==200 || y==250))

// the basic max_project ray casting

// #define M_PI



 // Examples:
 // (fovy=45, aspect=1., z1=0.1, z2=10)
 // (60,1.,1,10)

 //     """ like gluPerspective(fovy, aspect, zNear, zFar)
 //        fovy in degrees
 //  """
void mat4_perspective(float fovy, float aspect, float z1, float z2, float * mat) {
    float f = 1.0 / tan(fovy/180.0 * M_PI/2.0);

    // float _mat[16] = {1.*f/aspect, 0, 0, 0, 0, f, 0, 0, 0, 0, -1.*(z2+z1)/(z2-z1), -2.0*z1*z2/(z2-z1), 0, 0, -1, 0};

    // float _mat[16] = {1.*f/aspect, 0, 0, 0, 
    //                   0, f, 0, 0, 
    //                   0, 0, -1.*(z2+z1)/(z2-z1), -2.0*z1*z2/(z2-z1), 
    //                   0, 0, -1, 0};

    // 
    float _mat[16] = {1.*f/aspect, 0,                   0,  0, 
                      0,           f,                   0,  0, 
                      0,           0, -1.*(z2+z1)/(z2-z1), -1, 
                      0,           0, -2.0*z1*z2/(z2-z1) ,  0};
    

    for (int i=0;i<16;i++) mat[i] = _mat[i]; 
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
  const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR;
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
                  __read_only image3d_t volume,
                  __global float *d_output, // probably Nx x Ny "__global" mem so must be buffers
                  __global float *d_alpha_output, // same       "__global" mem so must be buffers
                  __global float *d_depth_output, // same       "__global" mem so must be buffers
                  uint Nx, 
                  uint Ny,
                  float view_angle
                  )
{

  // clip boxes
  float boxMin_x  = -1.0; 
  float boxMax_x  =  1.0;  
  float boxMin_y  = -1.0; 
  float boxMax_y  =  1.0;  
  float boxMin_z  = -1.0; 
  float boxMax_z  =  1.0;  
  // intensity clip
  float minVal    = 0.0;
  float maxVal    = 1.0;

  float gamma     = 1.0;
  float alpha_pow = 0.2;
  int zdepth = get_image_depth(volume);

  // for multi-pass rendering
  int currentPart = 0;
  int numParts = 10;
  // int numParts = (int) max(1.0,float(100)/zdepth); // scale the number of steps 
  // printf("numParts %d \n",numParts);

  // Use this to get orthogonal projection from the front
  // float _invP[16] = {1,0,0,0,  0,1,0,0,  0,0,1,0,  0,0,0,1}; 


  float _invP[16]={0}; mat4_perspective(60, 1., view_angle, 40, &_invP);
  // float _invP[16]={0}; mat4_perspective(60, 1., 0.8, 40, &_invP);

  // python
  // set_modelView(dot(mat4_translate(0,0,-7),mat4_scale(.7,.7,.7)))
  // set_modelView(rotMatX(.7))
  // float _invM[16] = {1,0,0,0,  0,1,0,0,  0,0,1,0,  0,0,0,-6.5}; // ??
  float _invM[16] = {1,0,0,0,  0,1,0,0,  0,0,1,0,  0,0,0,1}; // ??

  constant float* invP = &_invP;
  constant float* invM = &_invM;
  
  const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_TRUE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;
  // const sampler_t volumeSampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_LINEAR; // CLK_FILTER_NEAREST

  uint x = get_global_id(0);
  uint y = get_global_id(1);

  //  if (x!=0 || y!=0) return;
  //  printf("The matrix: \n");
  //  for (int i=0; i<16; i++) {
  //    printf("\n");
  //    printf("%d -> %.2f ", i, matty[i]);
  //  }
  // return;

  // normalized x,y coordinates in the image plane
  float u = ((float) x / (float) (Nx-1))*2.0f-1.0f;
  float v = ((float) y / (float) (Ny-1))*2.0f-1.0f;

  // Clipping Boxes with domain [-1..1]
  float4 boxMin = (float4)(boxMin_x,boxMin_y,boxMin_z,1.f);
  float4 boxMax = (float4)(boxMax_x,boxMax_y,boxMax_z,1.f);

  // calculate eye ray in world space
  float4 orig0, orig;
  float4 direc;
  float4 temp;
  float4 back,front;
  float4 stop0, stop;

  front = (float4)(u,v,-1,1); // start at z coordinate -1
  back  = (float4)(u,v,1 ,1);  // end at z coordinate 1. (remember, the volume coords are normalized).

  // We use homogeneous coordinates to allow for perspective transformations.
  orig0 = mult(invP,front); // origin in camera coordinates (with )
  orig0 *= 1.f/orig0.w;

  orig  = mult(invM,orig0); // origin in world coordinates (should be in domain [-1..1]^3)
  orig  *= 1.f/orig.w;

  stop0  = mult(invP,back); // back
  stop0  *= 1.f/stop0.w;

  stop  = mult(invM,stop0); // back
  stop  *= 1.f/stop.w;

  direc = normalize(stop - orig);
  direc.w = 0.0f;

  // direc = mult(invM , normalize(stop-orig0)); // NOTE: direc is _not_ necessarily normalized.
  // direc.w = 0.0f;

  // find intersection with box
  float tnear, tfar;
  int hit = intersectBox(orig, direc, boxMin, boxMax, &tnear, &tfar);

  // if ((x==150) && (y==150)) {
  //   printf("view_angle : %.3f \n", view_angle);
  // }

  if ((x==150 || x==200|| x==250) && (y==150 || y==200 || y==250)) {
    //printf("x,y,orig0: [%d %d] .... %0.2f %0.2f %0.2f \n", x, y , orig0.x, orig0.y, orig0.z);
    //printf("orig: %.3f %.3f %.3f \n", orig.x , orig.y , orig.z, orig.w);
    //printf("temp: %.3f %.3f %.3f \n", temp.x , temp.y , temp.z, temp.w);
    // printf("direc: %.3f %.3f %.3f \n", direc.x , direc.y , direc.z, direc.w);
    // printf("hit = %d \n", hit);
  }


  if (!hit) {
    if ((x < Nx) && (y < Ny)) {
      d_output[x+Nx*y] = 0.1f;
    d_alpha_output[x+Nx*y] = -1.f;
    }
    return;
  }

  // clamp to near plane
  if (tnear < 0.0f) tnear = 0.0f;


  // the color values we want
  float colVal = 0;
  float alphaVal = 0;

  const int maxSteps = 100;
  const int reducedSteps = maxSteps/numParts;
  const float dt = fabs(tfar-tnear)/maxSteps; //((reducedSteps/LOOPUNROLL)*LOOPUNROLL);

  // apply the shift if mulitpass

  // orig += currentPart*dt*direc;

  // if ((x==150 || x==200|| x==250) && (y==150 || y==200 || y==250)) {
  //   // printf("pos is: %0.2f %0.2f %0.2f \n", pos.x , pos.y, pos.z);
  //   // printf("cumsum = %f \n", cumsum);
  //   printf("orig is: %0.2f %0.2f %0.2f \n", orig.x , orig.y, orig.z);
  //   printf("direc is: %0.2f %0.2f %0.2f \n", direc.x , direc.y, direc.z);
  //   printf("reducedSteps = %f \n", reducedSteps);
  //   // printf("currentPart = %f \n", currentPart);
  //   printf("dt = %f \n", dt);
  // }      


  // dither the original
  // uint entropy = (uint)( 6779514*length(orig) + 6257327*length(direc) );
  // printf("x,y,rand = %d %d %d \n", x, y , random(x*93939393,y*383838)%100);
  // orig += dt*random(entropy+x,entropy+y)*direc;
  // TODO: how to properly implement dither? Is dither just to prevent aliasing?
  // float jitterx = (random(x*93939393,y*383837)%100) / 100.0 / Nx * 3.0;
  // float jittery = (random(x*23942347,y*294833)%100) / 100.0 / Ny * 3.0;
  // orig += (float4) {jitterx,jittery,0,0};

  float4 delta_pos = .5f*dt*direc;
  float4 pos = 0.5f *(1.f + orig + tnear*direc);

  float newVal = 0.f;
  int maxInd = 0;

  if (alpha_pow==0) {
    for(int i=0; i<=reducedSteps/LOOPUNROLL; ++i){
      for (int j = 0; j < LOOPUNROLL; ++j){
        newVal = read_imagef(volume, volumeSampler, pos).x;
        maxInd = newVal>colVal?i*LOOPUNROLL+j:maxInd;
        colVal = fmax(colVal,newVal);

        // colVal = fmax(colVal,read_imagef(volume, volumeSampler, pos).x);
        pos += delta_pos;
      }
    }
    colVal = (maxVal == 0)?colVal:(colVal-minVal)/(maxVal-minVal);
    alphaVal = colVal;
  } else {
    float cumsum = 1.f; // keep track of absorption
    for(int i=0; i<=reducedSteps/LOOPUNROLL; ++i){
      for (int j = 0; j < LOOPUNROLL; ++j){

        newVal = read_imagef(volume, volumeSampler, pos).x;
        newVal = (maxVal == 0)?newVal:(newVal-minVal)/(maxVal-minVal);
        maxInd = cumsum*newVal>colVal?i*LOOPUNROLL+j:maxInd;
        colVal = fmax(colVal,cumsum*newVal);

        //      if ((x==150 || x==200|| x==250) && (y==150 || y==200 || y==250)) {
        //        printf("pos is: %0.2f %0.2f %0.2f \n", pos.x , pos.y, pos.z);
        //        printf("cumsum = %f \n", cumsum);
        //        printf("orig is: %0.2f %0.2f %0.2f \n", orig.x , orig.y, orig.z);
        //        printf("direc is: %0.2f %0.2f %0.2f \n", direc.x , direc.y, direc.z);
        //        printf("tnear = %f \n", tnear);
        //      }      

        cumsum  *= (1.f-.1f*alpha_pow*clamp(newVal,0.f,1.f));
        pos += delta_pos;

        //      if ((x==150 || x==200|| x==250) && (y==150 || y==200 || y==250)) {
        //        printf("newVal = %f \n", newVal);
        //        printf("colVal = %f \n", colVal);
        //        printf("\n");
        //        //printf("vari = %f \n", vari);
        //      }


        if (cumsum<=0.02f) break;

        //  if((x==400)&&(y==400))
        //     printf("cumsum (it %d): %.5f\n",j,cumsum);
      }
    }
  }

  colVal = clamp(pow(colVal,gamma),0.f,1.f);
  alphaVal = clamp(colVal,0.f,1.f);

  // for depth test...
  alphaVal = tnear;
  //if (maxInd>-1)
  //  alphaVal = maxInd*dt;
  //else
  // alphaVal = 0.f;


  if ((x < Nx) && (y < Ny)){
    if (currentPart==0) {
      d_output[x+Nx*y] = colVal;
      d_alpha_output[x+Nx*y] = alphaVal;
    } else {
      d_output[x+Nx*y] = fmax(colVal,d_output[x+Nx*y]);
      d_alpha_output[x+Nx*y] = fmax(alphaVal,d_alpha_output[x+Nx*y]);
    }
  }
}

