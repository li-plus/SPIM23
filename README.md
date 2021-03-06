# SPIM-23

SPIM-23 is a naive MIPS 32 CPU implementation. It is a course project of Computer Architecture, 2019 Autumn at THU.

## Functionality

+ 45MHz main clock frequency
+ Wishbone bus
+ VGA frame buffer, Flash, BootROM, SRAM, GPIO and USB (no driver support, not properly tested)
+ TLB support
+ A tiny retro snake game in pure MIPS assembly

## Game Demo

![gif](docs/snake.gif)

Please refer to **[SPIM23-Snake](https://github.com/zx1239856/SPIM23-Snake)** for more details.

## Address Allocation

| Segment | Virtual Addr            | Physical Target  |
| ------- | ----------------------- | ---------------- |
| kuseg   | 0x00000000 - 0x7FFFFFFF | TLB Mapped       |
| kseg0   | 0x80000000 - 0x803FFFFF | BaseRAM          |
| kseg0   | 0x80400000 - 0x807FFFFF | ExtRAM           |
| kseg1   | 0xB0000000 - 0xB000003F | 64 Byte BootROM  |
| kseg1   | 0xB1000000 - 0xB1000024 | GPIO             |
| kseg1   | 0xBA000000 - 0xBA0752FF | VGA Graphics RAM |
| kseg1   | 0xBC000000 - 0xBC7FFFFF | 8M Flash         |
| kseg1   | 0xBD000000 - 0xBD000004 | USB              |
| kseg1   | 0xBFD003F8 - 0xBFD003FC | UART             |

## GPIO Registers

Please download [gpio_spec.pdf](docs/gpio_spec.pdf) to see how to use GPIO registers.

## BootROM

```assembly
# BootROM loader
lui $t0, 0xbc00 # flash
lui $t1, 0x8000 # baseRAM
lui $t2, 0xbc01 # 64 kB
loop:
lw  $t3,0($t0)
sw  $t3,0($t1)
addiu $t0,$t0,4
addiu $t1,$t1,4
bne $t0,$t2,loop
nop
xor $t0,$t0,$t0
xor $t1,$t1,$t1
xor $t2,$t2,$t2
xor $t3,$t3,$t3
lui $1, 0x8000  # jump to entry
j $1
nop
```

The supervisor should be put in Flash beforehand, with offset 0.


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