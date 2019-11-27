Thinpad 模板工程
---------------

工程包含示例代码和所有引脚约束，可以直接编译。

代码中包含中文注释，编码为utf-8，在Windows版Vivado下可能出现乱码问题。  
请用别的代码编辑器打开文件，并将编码改为GBK。

## VGA Demo

Load kernel to base RAM 0x00000000, connect your terminal, and press reset button.

Load `thinpad_top.srcs/sources_1/new/demo/pic.bin` to external RAM 0x00000000.

Execute the following scripts in your terminal. Then you see the picture.

```assembly
    lui     $t0, 7
    ori     $t0, 0x5300
    lui     $t1, 0x8040
    lui     $t2, 0xba00
vga:
    lb      $t3, 0($t1)
    sb      $t3, 0($t2)
    addiu   $t0, $t0, -1
    addiu   $t1, $t1, 1
    addiu   $t2, $t2, 1
    bnez    $t0, vga
    nop
    jr      $ra
    nop
```

## Reading from Flash

Load `thinpad_top.srcs/sources_1/new/demo/pic.bin` into external RAM `0x00000000`, and execute the following scripts.

```assembly
    lui     $t0, 7
    ori     $t0, 0x5300
    lui     $t1, 0xbc00
    lui     $t2, 0xba00
flash:
    lw      $t3, 0($t1)
    sb      $t3, 0($t2)
    sra     $t3, $t3, 8
    sb      $t3, 1($t2)
    sra     $t3, $t3, 8
    sb      $t3, 2($t2)
    sra     $t3, $t3, 8
    sb      $t3, 3($t2) 
    addiu   $t0, $t0, -4
    addiu   $t1, $t1, 4
    addiu   $t2, $t2, 4
    bnez    $t0, flash
    nop
    jr      $ra
    nop
```
