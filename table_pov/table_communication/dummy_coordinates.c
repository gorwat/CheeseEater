#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>

#include <windows.h>

int main(int argc, char** argv)
{
   if(argc != 2) return 1;

#ifdef _WIN64
   fprintf(stderr, "%s", argv[1]);
   HWND hwnd = (HWND)strtoull(argv[1], NULL, 10);

   SetWindowPos(hwnd, NULL, 0, 0, 960, 540, 0);
#endif

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