#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <unistd.h>

int main(void)
{
   while(1) {
      printf("spotlight coordinates\n");
      sleep(1);
   }
   return 0;
}