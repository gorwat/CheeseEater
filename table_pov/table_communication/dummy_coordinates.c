#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <unistd.h>

int main(void)
{
   float arr[12] = 
   { 
      1.0, 1.0,
      0.75, 0.75, 
      0.25, 0.25,
      0.0, 0.0, 
   };

   int index = 0;
   int is_on = 1;
   while(1) {
      write(STDOUT_FILENO, &is_on, 1);
      if (is_on){
         write(STDOUT_FILENO, &arr[index * 2 + 0], 4);
         write(STDOUT_FILENO, &arr[index * 2 + 1], 4);

      }
      index += 1;
      index %= 4;
      is_on ^= 1;
      sleep(1);
   }
   return 0;
}