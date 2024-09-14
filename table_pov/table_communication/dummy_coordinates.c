#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <unistd.h>

int main(void)
{
   while(1) {
      float pi = 3.14;
      write(STDOUT_FILENO, &pi, 4);
      sleep(1);
   }
   return 0;
}