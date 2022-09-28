// #define BLOCK 4;

__kernel void sumpool(__global short * input,
                      __global short * output){
                      //__global short height,
                      //__global short width){
  //int i = get_global_id(0);
  //int j = get_global_id(1);
  //int Nx = get_global_size(0);
  //int Ny = get_global_size(1);


  // int Nx = 64; //2^6
  // int Ny = 16; //2^4

  int n = get_global_id(0);
  // int j = n/Nx;
  // int i = n%Nx;

  int res = 0;

  // if (n==0) {
  //   int gs = get_global_size(0);
  //   printf("\nOpenCL: The global_size on dim0 is %d\n", gs);
  //   // printf(input);
  // }

  int BLOCK = 4;

  for (int m=0; m < BLOCK; ++m)
    res += input[BLOCK*n+m];
  output[n] = res;

    // output[Nx*j+i] = (short)(res/BLOCK/BLOCK);

  // for (int m = 0; m < BLOCK; ++m)
  //    for (int n = 0; n < BLOCK; ++n)
  //         res+=input[BLOCK*Nx*(BLOCK*j+m)+BLOCK*i+n];
  // output[Nx*j+i] = (short)(res/BLOCK/BLOCK);

  // output[n] = input[n];
}

__kernel void sumpool1Di16(__global short * input,
                          __global short * output
                          // short height,
                          // short width
                          ){

  //int i = get_global_id(0);
  //int j = get_global_id(1);
  //int Nx = get_global_size(0);
  //int Ny = get_global_size(1);

  // int Nx = 64; //2^6
  // int Ny = 16; //2^4

  int n = get_global_id(0);
  // int j = n/Nx;
  // int i = n%Nx;

  int res = 0; 

  if (n==0) {
    int gs = get_global_size(0);
    printf("\nOpenCL: The global_size on dim 0 is %d\n", gs);
  }
  int BLOCK = 2;

  for (int m=0; m < BLOCK; ++m)
    res += input[BLOCK*n+m];
  output[n] = res;

  // output[Nx*j+i] = (short)(res/BLOCK/BLOCK);

  // for (int m = 0; m < BLOCK; ++m)
  //    for (int n = 0; n < BLOCK; ++n)
  //         res+=input[BLOCK*Nx*(BLOCK*j+m)+BLOCK*i+n];
  // output[Nx*j+i] = (short)(res/BLOCK/BLOCK);

  // output[n] = input[n];

}