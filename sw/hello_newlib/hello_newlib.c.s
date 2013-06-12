   1              		.file	"hello_newlib.c"
   2              		.section	.debug_abbrev,"",@progbits
   3              	.Ldebug_abbrev0:
   4              		.section	.debug_info,"",@progbits
   5              	.Ldebug_info0:
   6              		.section	.debug_line,"",@progbits
   7              	.Ldebug_line0:
   8              		.section .text
   9              	.Ltext0:
  10              		.section	.rodata.str1.1,"aMS",@progbits,1
  11              	.LC0:
  12 0000 2532692E 		.string	"%2i. Hello World!\n"
  12      2048656C 
  12      6C6F2057 
  12      6F726C64 
  12      210A00
  13              		.section .text
  14              		.align	4
  15              	.proc	main
  16              		.global main
  17              		.type	main, @function
  18              	main:
  19              	.LFB0:
  20              	.LM1:
  21              	.LVL0:
  22 0000 D7E117F8 		l.sw    	-8(r1),r2	 # SI store
  23              	.LCFI0:
  24 0004 D7E14FFC 		l.sw    	-4(r1),r9	 # SI store
  25              	.LCFI1:
  26              	.LM2:
  27 0008 9C400001 		l.addi  	r2,r0,1	 # move immediate I
  28              	.LM3:
  29 000c 9C21FFF4 		l.addi  	r1,r1,-12
  30              	.LCFI2:
  31              	.LVL1:
  32              	.LM4:
  33 0010 18600000 		l.movhi  	r3,hi(.LC0)
  34              	.L5:
  35 0014 D4011000 		l.sw    	0(r1),r2	 # SI store
  36 0018 A8630000 		l.ori   	r3,r3,lo(.LC0)
  37 001c 04000000 		l.jal   	printf	# delay slot filled
  38 0020 9C420001 		l.addi  	r2,r2,1
  39              	.LVL2:
  40              	.LM5:
  41 0024 BC22000B 		l.sfnei	r2,11
  42 0028 13FFFFFB 		l.bf	.L5	# delay slot filled
  43 002c 18600000 		l.movhi  	r3,hi(.LC0)
  44              	.LM6:
  45 0030 9C21000C 		l.addi	r1,r1,12
  46 0034 9D600000 		l.addi  	r11,r0,0	 # move immediate I
  47 0038 8521FFFC 		l.lwz   	r9,-4(r1)	 # SI load
  48              	.LVL3:
  49 003c 44004800 		l.jr    	r9	# delay slot filled
  50 0040 8441FFF8 		l.lwz   	r2,-8(r1)	 # SI load
  51              	.LFE0:
  52              		.size	main, .-main
  53              		.section	.debug_frame,"",@progbits
  54              	.Lframe0:
  55 0000 00000010 		.4byte	.LECIE0-.LSCIE0
  56              	.LSCIE0:
  57 0004 FFFFFFFF 		.4byte	0xffffffff
  58 0008 01       		.byte	0x1
  59 0009 00       		.string	""
  60 000a 01       		.uleb128 0x1
  61 000b 7C       		.sleb128 -4
  62 000c 23       		.byte	0x23
  63 000d 0C       		.byte	0xc
  64 000e 01       		.uleb128 0x1
  65 000f 00       		.uleb128 0x0
  66 0010 09       		.byte	0x9
  67 0011 23       		.uleb128 0x23
  68 0012 09       		.uleb128 0x9
  69 0013 00       		.align	4
  70              	.LECIE0:
  71              	.LSFDE0:
  72 0014 00000014 		.4byte	.LEFDE0-.LASFDE0
  73              	.LASFDE0:
  74 0018 00000000 		.4byte	.Lframe0
  75 001c 00000000 		.4byte	.LFB0
  76 0020 00000044 		.4byte	.LFE0-.LFB0
  77 0024 48       		.byte	0x4
  78              		.4byte	.LCFI1-.LFB0
  79 0025 89       		.byte	0x89
  80 0026 01       		.uleb128 0x1
  81 0027 82       		.byte	0x82
  82 0028 02       		.uleb128 0x2
  83 0029 48       		.byte	0x4
  84              		.4byte	.LCFI2-.LCFI1
  85 002a 0E       		.byte	0xe
  86 002b 0C       		.uleb128 0xc
  87              		.align	4
  88              	.LEFDE0:
  89              		.section .text
  90              	.Letext0:
  91              		.section	.debug_loc,"",@progbits
  92              	.Ldebug_loc0:
  93              	.LLST0:
  94 0000 00000000 		.4byte	.LFB0-.Ltext0
  95 0004 00000010 		.4byte	.LCFI2-.Ltext0
  96 0008 0002     		.2byte	0x2
  97 000a 71       		.byte	0x71
  98 000b 00       		.sleb128 0
  99 000c 00000010 		.4byte	.LCFI2-.Ltext0
 100 0010 00000044 		.4byte	.LFE0-.Ltext0
 101 0014 0002     		.2byte	0x2
 102 0016 71       		.byte	0x71
 103 0017 0C       		.sleb128 12
 104 0018 00000000 		.4byte	0x0
 105 001c 00000000 		.4byte	0x0
 106              	.LLST1:
 107 0020 00000000 		.4byte	.LVL0-.Ltext0
 108 0024 00000010 		.4byte	.LVL1-.Ltext0
 109 0028 0002     		.2byte	0x2
 110 002a 31       		.byte	0x31
 111 002b 9F       		.byte	0x9f
 112 002c 00000024 		.4byte	.LVL2-.Ltext0
 113 0030 0000003C 		.4byte	.LVL3-.Ltext0
 114 0034 0001     		.2byte	0x1
 115 0036 52       		.byte	0x52
 116 0037 00000000 		.4byte	0x0
 117 003b 00000000 		.4byte	0x0
 118              		.section	.debug_info
 119 0000 00000095 		.4byte	0x95
 120 0004 0002     		.2byte	0x2
 121 0006 00000000 		.4byte	.Ldebug_abbrev0
 122 000a 04       		.byte	0x4
 123 000b 01       		.uleb128 0x1
 124 000c 00000000 		.4byte	.LASF10
 125 0010 01       		.byte	0x1
 126 0011 00000000 		.4byte	.LASF11
 127 0015 00000000 		.4byte	.LASF12
 128 0019 00000000 		.4byte	.Ltext0
 129 001d 00000000 		.4byte	.Letext0
 130 0021 00000000 		.4byte	.Ldebug_line0
 131 0025 02       		.uleb128 0x2
 132 0026 04       		.byte	0x4
 133 0027 07       		.byte	0x7
 134 0028 00000000 		.4byte	.LASF0
 135 002c 02       		.uleb128 0x2
 136 002d 01       		.byte	0x1
 137 002e 06       		.byte	0x6
 138 002f 00000000 		.4byte	.LASF1
 139 0033 02       		.uleb128 0x2
 140 0034 01       		.byte	0x1
 141 0035 08       		.byte	0x8
 142 0036 00000000 		.4byte	.LASF2
 143 003a 02       		.uleb128 0x2
 144 003b 02       		.byte	0x2
 145 003c 05       		.byte	0x5
 146 003d 00000000 		.4byte	.LASF3
 147 0041 02       		.uleb128 0x2
 148 0042 02       		.byte	0x2
 149 0043 07       		.byte	0x7
 150 0044 00000000 		.4byte	.LASF4
 151 0048 03       		.uleb128 0x3
 152 0049 04       		.byte	0x4
 153 004a 05       		.byte	0x5
 154 004b 696E7400 		.string	"int"
 155 004f 02       		.uleb128 0x2
 156 0050 04       		.byte	0x4
 157 0051 07       		.byte	0x7
 158 0052 00000000 		.4byte	.LASF5
 159 0056 02       		.uleb128 0x2
 160 0057 08       		.byte	0x8
 161 0058 05       		.byte	0x5
 162 0059 00000000 		.4byte	.LASF6
 163 005d 02       		.uleb128 0x2
 164 005e 08       		.byte	0x8
 165 005f 07       		.byte	0x7
 166 0060 00000000 		.4byte	.LASF7
 167 0064 02       		.uleb128 0x2
 168 0065 04       		.byte	0x4
 169 0066 05       		.byte	0x5
 170 0067 00000000 		.4byte	.LASF8
 171 006b 02       		.uleb128 0x2
 172 006c 01       		.byte	0x1
 173 006d 06       		.byte	0x6
 174 006e 00000000 		.4byte	.LASF9
 175 0072 04       		.uleb128 0x4
 176 0073 01       		.byte	0x1
 177 0074 00000000 		.4byte	.LASF13
 178 0078 01       		.byte	0x1
 179 0079 05       		.byte	0x5
 180 007a 00000048 		.4byte	0x48
 181 007e 00000000 		.4byte	.LFB0
 182 0082 00000000 		.4byte	.LFE0
 183 0086 00000000 		.4byte	.LLST0
 184 008a 05       		.uleb128 0x5
 185 008b 6E00     		.string	"n"
 186 008d 01       		.byte	0x1
 187 008e 06       		.byte	0x6
 188 008f 00000048 		.4byte	0x48
 189 0093 00000000 		.4byte	.LLST1
 190 0097 00       		.byte	0x0
 191 0098 00       		.byte	0x0
 192              		.section	.debug_abbrev
 193 0000 01       		.uleb128 0x1
 194 0001 11       		.uleb128 0x11
 195 0002 01       		.byte	0x1
 196 0003 25       		.uleb128 0x25
 197 0004 0E       		.uleb128 0xe
 198 0005 13       		.uleb128 0x13
 199 0006 0B       		.uleb128 0xb
 200 0007 03       		.uleb128 0x3
 201 0008 0E       		.uleb128 0xe
 202 0009 1B       		.uleb128 0x1b
 203 000a 0E       		.uleb128 0xe
 204 000b 11       		.uleb128 0x11
 205 000c 01       		.uleb128 0x1
 206 000d 12       		.uleb128 0x12
 207 000e 01       		.uleb128 0x1
 208 000f 10       		.uleb128 0x10
 209 0010 06       		.uleb128 0x6
 210 0011 00       		.byte	0x0
 211 0012 00       		.byte	0x0
 212 0013 02       		.uleb128 0x2
 213 0014 24       		.uleb128 0x24
 214 0015 00       		.byte	0x0
 215 0016 0B       		.uleb128 0xb
 216 0017 0B       		.uleb128 0xb
 217 0018 3E       		.uleb128 0x3e
 218 0019 0B       		.uleb128 0xb
 219 001a 03       		.uleb128 0x3
 220 001b 0E       		.uleb128 0xe
 221 001c 00       		.byte	0x0
 222 001d 00       		.byte	0x0
 223 001e 03       		.uleb128 0x3
 224 001f 24       		.uleb128 0x24
 225 0020 00       		.byte	0x0
 226 0021 0B       		.uleb128 0xb
 227 0022 0B       		.uleb128 0xb
 228 0023 3E       		.uleb128 0x3e
 229 0024 0B       		.uleb128 0xb
 230 0025 03       		.uleb128 0x3
 231 0026 08       		.uleb128 0x8
 232 0027 00       		.byte	0x0
 233 0028 00       		.byte	0x0
 234 0029 04       		.uleb128 0x4
 235 002a 2E       		.uleb128 0x2e
 236 002b 01       		.byte	0x1
 237 002c 3F       		.uleb128 0x3f
 238 002d 0C       		.uleb128 0xc
 239 002e 03       		.uleb128 0x3
 240 002f 0E       		.uleb128 0xe
 241 0030 3A       		.uleb128 0x3a
 242 0031 0B       		.uleb128 0xb
 243 0032 3B       		.uleb128 0x3b
 244 0033 0B       		.uleb128 0xb
 245 0034 49       		.uleb128 0x49
 246 0035 13       		.uleb128 0x13
 247 0036 11       		.uleb128 0x11
 248 0037 01       		.uleb128 0x1
 249 0038 12       		.uleb128 0x12
 250 0039 01       		.uleb128 0x1
 251 003a 40       		.uleb128 0x40
 252 003b 06       		.uleb128 0x6
 253 003c 00       		.byte	0x0
 254 003d 00       		.byte	0x0
 255 003e 05       		.uleb128 0x5
 256 003f 34       		.uleb128 0x34
 257 0040 00       		.byte	0x0
 258 0041 03       		.uleb128 0x3
 259 0042 08       		.uleb128 0x8
 260 0043 3A       		.uleb128 0x3a
 261 0044 0B       		.uleb128 0xb
 262 0045 3B       		.uleb128 0x3b
 263 0046 0B       		.uleb128 0xb
 264 0047 49       		.uleb128 0x49
 265 0048 13       		.uleb128 0x13
 266 0049 02       		.uleb128 0x2
 267 004a 06       		.uleb128 0x6
 268 004b 00       		.byte	0x0
 269 004c 00       		.byte	0x0
 270 004d 00       		.byte	0x0
 271              		.section	.debug_pubnames,"",@progbits
 272 0000 00000017 		.4byte	0x17
 273 0004 0002     		.2byte	0x2
 274 0006 00000000 		.4byte	.Ldebug_info0
 275 000a 00000099 		.4byte	0x99
 276 000e 00000072 		.4byte	0x72
 277 0012 6D61696E 		.string	"main"
 277      00
 278 0017 00000000 		.4byte	0x0
 279              		.section	.debug_pubtypes,"",@progbits
 280 0000 0000000E 		.4byte	0xe
 281 0004 0002     		.2byte	0x2
 282 0006 00000000 		.4byte	.Ldebug_info0
 283 000a 00000099 		.4byte	0x99
 284 000e 00000000 		.4byte	0x0
 285              		.section	.debug_aranges,"",@progbits
 286 0000 0000001C 		.4byte	0x1c
 287 0004 0002     		.2byte	0x2
 288 0006 00000000 		.4byte	.Ldebug_info0
 289 000a 04       		.byte	0x4
 290 000b 00       		.byte	0x0
 291 000c 0000     		.2byte	0x0
 292 000e 0000     		.2byte	0x0
 293 0010 00000000 		.4byte	.Ltext0
 294 0014 00000044 		.4byte	.Letext0-.Ltext0
 295 0018 00000000 		.4byte	0x0
 296 001c 00000000 		.4byte	0x0
 297              		.section	.debug_line
 298 0000 00000062 		.4byte	.LELT0-.LSLT0
 299              	.LSLT0:
 300 0004 0002     		.2byte	0x2
 301 0006 00000022 		.4byte	.LELTP0-.LASLTP0
 302              	.LASLTP0:
 303 000a 01       		.byte	0x1
 304 000b 01       		.byte	0x1
 305 000c F6       		.byte	0xf6
 306 000d F5       		.byte	0xf5
 307 000e 0A       		.byte	0xa
 308 000f 00       		.byte	0x0
 309 0010 01       		.byte	0x1
 310 0011 01       		.byte	0x1
 311 0012 01       		.byte	0x1
 312 0013 01       		.byte	0x1
 313 0014 00       		.byte	0x0
 314 0015 00       		.byte	0x0
 315 0016 00       		.byte	0x0
 316 0017 01       		.byte	0x1
 317 0018 00       		.byte	0x0
 318 0019 68656C6C 		.string	"hello_newlib.c"
 318      6F5F6E65 
 318      776C6962 
 318      2E6300
 319 0028 00       		.uleb128 0x0
 320 0029 00       		.uleb128 0x0
 321 002a 00       		.uleb128 0x0
 322 002b 00       		.byte	0x0
 323              	.LELTP0:
 324 002c 00       		.byte	0x0
 325 002d 05       		.uleb128 0x5
 326 002e 02       		.byte	0x2
 327 002f 00000000 		.4byte	.LM1
 328 0033 18       		.byte	0x18
 329 0034 00       		.byte	0x0
 330 0035 05       		.uleb128 0x5
 331 0036 02       		.byte	0x2
 332 0037 00000000 		.4byte	.LM2
 333 003b 17       		.byte	0x17
 334 003c 00       		.byte	0x0
 335 003d 05       		.uleb128 0x5
 336 003e 02       		.byte	0x2
 337 003f 00000000 		.4byte	.LM3
 338 0043 11       		.byte	0x11
 339 0044 00       		.byte	0x0
 340 0045 05       		.uleb128 0x5
 341 0046 02       		.byte	0x2
 342 0047 00000000 		.4byte	.LM4
 343 004b 18       		.byte	0x18
 344 004c 00       		.byte	0x0
 345 004d 05       		.uleb128 0x5
 346 004e 02       		.byte	0x2
 347 004f 00000000 		.4byte	.LM5
 348 0053 13       		.byte	0x13
 349 0054 00       		.byte	0x0
 350 0055 05       		.uleb128 0x5
 351 0056 02       		.byte	0x2
 352 0057 00000000 		.4byte	.LM6
 353 005b 17       		.byte	0x17
 354 005c 00       		.byte	0x0
 355 005d 05       		.uleb128 0x5
 356 005e 02       		.byte	0x2
 357 005f 00000000 		.4byte	.Letext0
 358 0063 00       		.byte	0x0
 359 0064 01       		.uleb128 0x1
 360 0065 01       		.byte	0x1
 361              	.LELT0:
 362 0066 00000019 		.section	.debug_str,"MS",@progbits,1
 362      00020000 
 362      00130101 
 362      FB0E0D00 
 362      01010101 
 363              	.LASF6:
 364 0000 6C6F6E67 		.string	"long long int"
 364      206C6F6E 
 364      6720696E 
 364      7400
 365              	.LASF5:
 366 000e 756E7369 		.string	"unsigned int"
 366      676E6564 
 366      20696E74 
 366      00
 367              	.LASF13:
 368 001b 6D61696E 		.string	"main"
 368      00
 369              	.LASF0:
 370 0020 6C6F6E67 		.string	"long unsigned int"
 370      20756E73 
 370      69676E65 
 370      6420696E 
 370      7400
 371              	.LASF11:
 372 0032 68656C6C 		.string	"hello_newlib.c"
 372      6F5F6E65 
 372      776C6962 
 372      2E6300
 373              	.LASF7:
 374 0041 6C6F6E67 		.string	"long long unsigned int"
 374      206C6F6E 
 374      6720756E 
 374      7369676E 
 374      65642069 
 375              	.LASF12:
 376 0058 2F686F6D 		.string	"/home/gundolf/hsa/paranut/src/sw/hello_newlib"
 376      652F6775 
 376      6E646F6C 
 376      662F6873 
 376      612F7061 
 377              	.LASF2:
 378 0086 756E7369 		.string	"unsigned char"
 378      676E6564 
 378      20636861 
 378      7200
 379              	.LASF9:
 380 0094 63686172 		.string	"char"
 380      00
 381              	.LASF8:
 382 0099 6C6F6E67 		.string	"long int"
 382      20696E74 
 382      00
 383              	.LASF4:
 384 00a2 73686F72 		.string	"short unsigned int"
 384      7420756E 
 384      7369676E 
 384      65642069 
 384      6E7400
 385              	.LASF1:
 386 00b5 7369676E 		.string	"signed char"
 386      65642063 
 386      68617200 
 387              	.LASF3:
 388 00c1 73686F72 		.string	"short int"
 388      7420696E 
 388      7400
 389              	.LASF10:
 390 00cb 474E5520 		.string	"GNU C 4.5.1-or32-1.0rc4"
 390      4320342E 
 390      352E312D 
 390      6F723332 
 390      2D312E30 
 391              		.ident	"GCC: (OpenRISC 32-bit toolchain for or32-elf (built 20110410)) 4.5.1-or32-1.0rc4"
