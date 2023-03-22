#include <stdio.h>
#include <stdlib.h>
#include <OpenCL/CL.h>

#define ARRAY_SIZE 10

int main() {
    // OpenCL variables
    cl_platform_id platform_id;
    cl_device_id device_id;
    cl_context context;
    cl_command_queue queue;
    cl_program program;
    cl_kernel kernel;
    cl_mem input_buffer, output_buffer;
    cl_int err;

    // Create input and output arrays
    int input[ARRAY_SIZE] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    int output[ARRAY_SIZE];

    // Initialize OpenCL
    err = clGetPlatformIDs(1, &platform_id, NULL);
    err = clGetDeviceIDs(platform_id, CL_DEVICE_TYPE_GPU, 1, &device_id, NULL);
    context = clCreateContext(NULL, 1, &device_id, NULL, NULL, &err);
    queue = clCreateCommandQueue(context, device_id, 0, &err);

    // Create input and output buffers
    input_buffer = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(int) * ARRAY_SIZE, NULL, &err);
    output_buffer = clCreateBuffer(context, CL_MEM_WRITE_ONLY, sizeof(int) * ARRAY_SIZE, NULL, &err);

    // Write input data to input buffer
    err = clEnqueueWriteBuffer(queue, input_buffer, CL_TRUE, 0, sizeof(int) * ARRAY_SIZE, input, 0, NULL, NULL);

    // Create and build the program
    const char *source  = "__kernel void square(__global int* input, __global int* output) { int i = get_global_id(0); output[i] = input[i] * input[i]; }";

    program = clCreateProgramWithSource(context, 1, &source, NULL, &err);
    err = clBuildProgram(program, 1, &device_id, NULL, NULL, NULL);

    // Create the kernel
    kernel = clCreateKernel(program, "square", &err);

    // Set kernel arguments
    err = clSetKernelArg(kernel, 0, sizeof(cl_mem), &input_buffer);
    err = clSetKernelArg(kernel, 1, sizeof(cl_mem), &output_buffer);

    // Run the kernel
    size_t global_size = ARRAY_SIZE;
    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &global_size, NULL, 0, NULL, NULL);

    // Read the output data from output buffer
    err = clEnqueueReadBuffer(queue, output_buffer, CL_TRUE, 0, sizeof(int) * ARRAY_SIZE, output, 0, NULL, NULL);

    // Print the output data
    for (int i = 0; i < ARRAY_SIZE; i++) {
        printf("%d ", output[i]);
    }
    printf("\n");

    // Cleanup
    clReleaseMemObject(input_buffer);
    clReleaseMemObject(output_buffer);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    return 0;
}
