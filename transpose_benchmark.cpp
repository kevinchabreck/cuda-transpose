#include <iostream>
#include <cstdlib>
#include <chrono>

void transpose(char transposed_buffer[], char buffer[], int width, int height){
  for(int i=0; i<height; i++) {
    for(int j=0; j<width; j++) {
      transposed_buffer[i*width + j] = buffer[j*width + i];
    }
  }
}

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
  // allocate memory
  unsigned int mem_size = sizeof(char) * request_size * cohort_size;
  char * idata = new char[mem_size];
  char * odata = new char[mem_size];
  // initialize input matrix
  for( unsigned int i = 0; i < (request_size * cohort_size); i++) {
    idata[i] = (char) (i%26 + 97);
  }
  // initialize timer
  typedef std::chrono::high_resolution_clock Clock;
  typedef std::chrono::duration<float> fsec;
  float times[iterations];
  for(int i=0; i<iterations; i++){
    auto start = Clock::now(); // Tstart
    for(int j=0; j<n; j++){
      transpose(odata, idata, request_size, cohort_size);
    }
    auto stop = Clock::now(); // Tstop
    // calculate elapsed time
    fsec fs = stop - start;
    times[i] = fs.count();
  }
  double avg = 0;
  for(int i=0; i<iterations; i++){
    avg += times[i];
  }
  avg = avg / iterations;
  // free memory
  free(idata);
  free(odata);
  return avg;
}

double latency_bench(int request_size, int cohort_size, int iterations){
  // allocate memory
  unsigned int mem_size = sizeof(char) * request_size * cohort_size;
  char * idata = new char[mem_size];
  char * odata = new char[mem_size];
  // initialize input matrix
  for( unsigned int i = 0; i < (request_size * cohort_size); i++) {
    idata[i] = (char) (i%26 + 97);
  }
  // initialize timer
  typedef std::chrono::high_resolution_clock Clock;
  typedef std::chrono::duration<float> fsec;
  float times[iterations];
  for(int i=0; i<iterations; i++){
    auto start = Clock::now(); // Tstart
    transpose(odata, idata, request_size, cohort_size);
    auto stop = Clock::now(); // Tstop
    // calculate elapsed time
    fsec fs = stop - start;
    times[i] = fs.count();
  }
  double avg = 0;
  for(int i=0; i<iterations; i++){
    avg += times[i];
  }
  avg = avg / iterations;
  // free memory
  free(idata);
  free(odata);
  return avg;
}

void run_benchmarks(int request_size, int cohort_size, int iterations){
  // throughput
  int n = 100;
  double throughput = throughput_bench(request_size, cohort_size, iterations, n);
  printf("\n*CPU THROUGHPUT BENCHMARK*\n");
  printf("iterations: %d\n", iterations);
  printf("transposes per iteration: %d\n", n);
  printf("request size: %d\n", request_size);
  printf("cohort size: %d\n", cohort_size);
  printf("average time for %d transposes (ms): %f\n", n, throughput*1000);
  // latency
  double latency = latency_bench(request_size, cohort_size, iterations);
  printf("\n*CPU LATENCY BENCHMARK*\n");
  printf("iterations: %d\n", iterations);
  printf("request size: %d\n", request_size);
  printf("cohort size: %d\n", cohort_size);
  printf("average latency (ms): %f\n", latency*1000);
}

int main(void)
{
  int request_size = 1024; // length of requests in bytes
  int cohort_size  = 4096; // # of requests in cohorts (shouldnt change)
  int iterations   = 100;  // number of iterations to run benchmarks
  run_benchmarks(request_size, cohort_size, iterations);
}
