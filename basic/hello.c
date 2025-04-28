//riscv64-unknown-elf-gcc -march=rv64gc -mabi=lp64d -o hello hello.c
#include <stdio.h>

int main(){
    printf("Hello, RISC-V!\n");
    return 0;
}
