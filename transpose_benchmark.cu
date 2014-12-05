#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <ctype.h>
#include <strings.h>
#include <string.h>
#include <sys/stat.h>
#include <pthread.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/epoll.h>
#include <errno.h>
#include <cuda_profiler_api.h>
#include <nvToolsExt.h>
#include <nvToolsExtCuda.h>
#include <nvToolsExtCudaRt.h>
#include <time.h>
#include "common.h"
#include "common.c"
#include "memory.c"

cudaStream_t stream;
char* h_idata;
char* h_odata;
char* d_idata;
char* d_odata;
dim3 grid;
dim3 threads;

void print_matrix(char * data, int x, int y){
  for( unsigned int i = 0; i < x; i++) {
    for( unsigned int j = 0; j < y; j++) {
      printf("%c", data[i*x + j]);
    }
    printf("\n");
  }
  printf("\n");
}

double throughput_bench(int request_size, int cohort_size, int iterations, int n){
  grid = dim3(request_size/TILE_DIM, cohort_size/TILE_DIM, 1);
  unsigned int mem_size = sizeof(char) * request_size * cohort_size;
  // allocate host memory
  h_idata = (char*) malloc(mem_size);
  h_odata = (char*) malloc(mem_size);
  // allocate device memory
  check_cuda( cudaMalloc( (void**) &d_idata, mem_size));
  check_cuda( cudaMalloc( (void**) &d_odata, mem_size));
  // initialize input matrix
  for( unsigned int i = 0; i < (request_size * cohort_size); i++) {
    h_idata[i] = (char) (i%26 + 97);
  }
  // initialize timer
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);
  float times[iterations];
  for(int i=0; i<iterations; i++){
    // Tstart
    cudaEventRecord(start, 0);
    for(int j=0; j<n; j++){
      // copy to device, transpose, and copy back to host
      check_cuda(cudaMemcpy(d_idata, h_idata, mem_size, cudaMemcpyHostToDevice));
      transpose<<< grid, threads, 0, stream>>>(d_odata, d_idata, request_size, cohort_size);
      cudaDeviceSynchronize();
      check_cuda(cudaMemcpy(h_odata, d_odata, mem_size, cudaMemcpyDeviceToHost));
    }
    // Tstop
    cudaEventRecord(stop, 0);
    // calculate elapsed time
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&times[i], start, stop);
  }
  double avg = 0;
  for(int i=0; i<iterations; i++){
    avg += times[i];
  }
  avg = avg / iterations;
  // free host mem
  free(h_idata);
  free(h_odata);
  // free device memory
  check_cuda( cudaFree(d_idata));
  check_cuda( cudaFree(d_odata));
  return avg;
}

double latency_bench(int request_size, int cohort_size, int iterations){
  grid = dim3(request_size/TILE_DIM, cohort_size/TILE_DIM, 1);

  unsigned int mem_size = sizeof(char) * request_size * cohort_size;
  // allocate host memory
  h_idata = (char*) malloc(mem_size);
  h_odata = (char*) malloc(mem_size);
  // allocate device memory
  check_cuda( cudaMalloc( (void**) &d_idata, mem_size));
  check_cuda( cudaMalloc( (void**) &d_odata, mem_size));
  // initialize input matrix
  for( unsigned int i = 0; i < (request_size * cohort_size); i++) {
    h_idata[i] = (char) (i%26 + 97);
  }
  // initialize timer
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);
  float times[iterations];
  for(int i=0; i<iterations; i++){
    // Tstart
    cudaEventRecord(start, 0);
    // copy to device, transpose, and copy back to host
    check_cuda(cudaMemcpy(d_idata, h_idata, mem_size, cudaMemcpyHostToDevice));
    transpose<<< grid, threads, 0, stream>>>(d_odata, d_idata, request_size, cohort_size);
    cudaDeviceSynchronize();
    check_cuda(cudaMemcpy(h_odata, d_odata, mem_size, cudaMemcpyDeviceToHost));
    // Tstop
    cudaEventRecord(stop, 0);
    // calculate elapsed time
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&times[i], start, stop);
  }
  double avg = 0;
  for(int i=0; i<iterations; i++){
    avg += times[i];
  }
  avg = avg / iterations;
  // free host mem
  free(h_idata);
  free(h_odata);
  // free device memory
  check_cuda( cudaFree(d_idata));
  check_cuda( cudaFree(d_odata));
  return avg;
}

void run_benchmarks(int request_size, int cohort_size, int iterations){
  // set up execution environment
  threads = dim3(TILE_DIM, BLOCK_ROWS, 1);
  stream = alloc_stream();
  // run benchmarks
  int n = 100; // number of transposes to test throughput with
  double throughput = throughput_bench(request_size, cohort_size, iterations, n);
  printf("\n*THROUGHPUT BENCHMARK*\n");
  printf("iterations: %d\n", iterations);
  printf("transposes per iteration: %d\n", n);
  printf("request size: %d\n", request_size);
  printf("cohort size: %d\n", cohort_size);
  printf("average time for %d transposes (ms): %f\n", n, throughput);
  double latency = latency_bench(request_size, cohort_size, iterations);
  printf("\n*LATENCY BENCHMARK*\n");
  printf("iterations: %d\n", iterations);
  printf("request size: %d\n", request_size);
  printf("cohort size: %d\n", cohort_size);
  printf("average latency (ms): %f\n", latency);
}

int main(void)
{ 
  int request_size = 1024; // length of requests in bytes
  int cohort_size  = 4096; // # of requests in cohorts (shouldnt change)
  int iterations   = 100;  // number of iterations to run benchmarks
  run_benchmarks(request_size, cohort_size, iterations);
  
  cudaThreadExit();
}
