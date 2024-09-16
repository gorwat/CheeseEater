#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <unistd.h>

int main(void)
{
   float arr[12] = 
   { 
      5.0, 6.0, 5.0,
      -5.0, 6.0, 5.0,
      -5.0, 6.0, -5.0,
      5.0, 6.0, -5.0,
   };

   int index = 0;
   while(1) {
      write(STDOUT_FILENO, &arr[index * 3 + 0], 4);
      write(STDOUT_FILENO, &arr[index * 3 + 1], 4);
      write(STDOUT_FILENO, &arr[index * 3 + 2], 4);

      index += 1;
      index %= 4;

      sleep(1);
   }
   return 0;
}