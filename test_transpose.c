// this is a test written by Sandeep. Not relevant to project.

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

#define ROWS 4
#define COLUMNS 4

#define TRANSPOSE(x) COLUMNS*x

char buffer[ROWS][COLUMNS];
char transposed_buffer[COLUMNS][ROWS];

long int profiler_get_time()
{
 struct timespec t1;
 clock_gettime(CLOCK_MONOTONIC, &t1);
 return (t1.tv_sec*1000000 + (t1.tv_nsec/1000));
}

int main()
{
 int i, j;
 srand(0);
 for(i=0; i<ROWS; i++) {
  fprintf(stderr, "\n ");
  for(j=0; j<COLUMNS; j++) {
   buffer[i][j] = rand()%256;
   fprintf(stderr, "%d ", buffer[i][j]);
  }
 }
 long int start_time = profiler_get_time();
 for(i=0; i<COLUMNS; i++) {
  fprintf(stderr, "\n ");
  for(j=0; j<ROWS; j++) {
   transposed_buffer[i][j] = buffer[j][i];
   fprintf(stderr, "%d ", transposed_buffer[i][j]);
  }
 }
 long int end_time = profiler_get_time();
 fprintf(stderr, "\nElapsed time = %ld ms", (end_time - start_time)/1000);
}