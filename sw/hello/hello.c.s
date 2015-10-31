   1              		.file	"hello.c"
   2              		.section .text
   3              	.Ltext0:
   4              		.cfi_sections	.debug_frame
   5              		.align	4
   6              	.proc	buserr_except
   7              		.global buserr_except
   8              		.type	buserr_except, @function
   9              	buserr_except:
  10              	.LFB0:
  11              		.file 1 "hello.c"
   1:hello.c       **** // #include <stdio.h>
   2:hello.c       **** #include <support.h>
   3:hello.c       **** 
   4:hello.c       **** // OR32 trap vector dummy functions
   5:hello.c       **** void buserr_except(){}
  12              		.loc 1 5 0
  13              		.cfi_startproc
  14 0000 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
  15              		.cfi_offset 1, -4
  16 0004 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
  17              		.cfi_def_cfa_offset 4
  18              		.loc 1 5 0
  19 0008 9C210004 		l.addi	r1,r1,4
  20 000c 44004800 		l.jr    	r9	# return_internal	# delay slot filled
  21 0010 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
  22              		.cfi_endproc
  23              	.LFE0:
  24              		.size	buserr_except, .-buserr_except
  25              		.align	4
  26              	.proc	dpf_except
  27              		.global dpf_except
  28              		.type	dpf_except, @function
  29              	dpf_except:
  30              	.LFB1:
   6:hello.c       **** void dpf_except(){}
  31              		.loc 1 6 0
  32              		.cfi_startproc
  33 0014 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
  34              		.cfi_offset 1, -4
  35 0018 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
  36              		.cfi_def_cfa_offset 4
  37              		.loc 1 6 0
  38 001c 9C210004 		l.addi	r1,r1,4
  39 0020 44004800 		l.jr    	r9	# return_internal	# delay slot filled
  40 0024 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
  41              		.cfi_endproc
  42              	.LFE1:
  43              		.size	dpf_except, .-dpf_except
  44              		.align	4
  45              	.proc	ipf_except
  46              		.global ipf_except
  47              		.type	ipf_except, @function
  48              	ipf_except:
  49              	.LFB2:
   7:hello.c       **** void ipf_except(){}
  50              		.loc 1 7 0
  51              		.cfi_startproc
  52 0028 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
  53              		.cfi_offset 1, -4
  54 002c 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
  55              		.cfi_def_cfa_offset 4
  56              		.loc 1 7 0
  57 0030 9C210004 		l.addi	r1,r1,4
  58 0034 44004800 		l.jr    	r9	# return_internal	# delay slot filled
  59 0038 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
  60              		.cfi_endproc
  61              	.LFE2:
  62              		.size	ipf_except, .-ipf_except
  63              		.align	4
  64              	.proc	lpint_except
  65              		.global lpint_except
  66              		.type	lpint_except, @function
  67              	lpint_except:
  68              	.LFB3:
   8:hello.c       **** void lpint_except(){timer_interrupt();}
  69              		.loc 1 8 0
  70              		.cfi_startproc
  71 003c D7E14FFC 		l.sw    	-4(r1),r9	 # SI store
  72 0040 D7E10FF8 		l.sw    	-8(r1),r1	 # SI store
  73              		.cfi_offset 9, -4
  74              		.cfi_offset 1, -8
  75              		.loc 1 8 0
  76 0044 04000000 		l.jal   	timer_interrupt # call_value_internal	# delay slot filled
  77 0048 9C21FFF8 		l.addi  	r1,r1,-8 # addsi3
  78              		.cfi_def_cfa_offset 8
  79              	.LVL0:
  80 004c 9C210008 		l.addi	r1,r1,8
  81 0050 8521FFFC 		l.lwz   	r9,-4(r1)	 # SI load
  82 0054 44004800 		l.jr    	r9	# return_internal	# delay slot filled
  83 0058 8421FFF8 		l.lwz   	r1,-8(r1)	 # SI load
  84              		.cfi_endproc
  85              	.LFE3:
  86              		.size	lpint_except, .-lpint_except
  87              		.align	4
  88              	.proc	align_except
  89              		.global align_except
  90              		.type	align_except, @function
  91              	align_except:
  92              	.LFB4:
   9:hello.c       **** void align_except(){}
  93              		.loc 1 9 0
  94              		.cfi_startproc
  95 005c D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
  96              		.cfi_offset 1, -4
  97 0060 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
  98              		.cfi_def_cfa_offset 4
  99              		.loc 1 9 0
 100 0064 9C210004 		l.addi	r1,r1,4
 101 0068 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 102 006c 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 103              		.cfi_endproc
 104              	.LFE4:
 105              		.size	align_except, .-align_except
 106              		.align	4
 107              	.proc	illegal_except
 108              		.global illegal_except
 109              		.type	illegal_except, @function
 110              	illegal_except:
 111              	.LFB5:
  10:hello.c       **** void illegal_except(){}
 112              		.loc 1 10 0
 113              		.cfi_startproc
 114 0070 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
 115              		.cfi_offset 1, -4
 116 0074 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
 117              		.cfi_def_cfa_offset 4
 118              		.loc 1 10 0
 119 0078 9C210004 		l.addi	r1,r1,4
 120 007c 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 121 0080 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 122              		.cfi_endproc
 123              	.LFE5:
 124              		.size	illegal_except, .-illegal_except
 125              		.align	4
 126              	.proc	hpint_except
 127              		.global hpint_except
 128              		.type	hpint_except, @function
 129              	hpint_except:
 130              	.LFB6:
  11:hello.c       **** void hpint_except(){}
 131              		.loc 1 11 0
 132              		.cfi_startproc
 133 0084 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
 134              		.cfi_offset 1, -4
 135 0088 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
 136              		.cfi_def_cfa_offset 4
 137              		.loc 1 11 0
 138 008c 9C210004 		l.addi	r1,r1,4
 139 0090 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 140 0094 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 141              		.cfi_endproc
 142              	.LFE6:
 143              		.size	hpint_except, .-hpint_except
 144              		.align	4
 145              	.proc	dtlbmiss_except
 146              		.global dtlbmiss_except
 147              		.type	dtlbmiss_except, @function
 148              	dtlbmiss_except:
 149              	.LFB7:
  12:hello.c       **** void dtlbmiss_except(){}
 150              		.loc 1 12 0
 151              		.cfi_startproc
 152 0098 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
 153              		.cfi_offset 1, -4
 154 009c 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
 155              		.cfi_def_cfa_offset 4
 156              		.loc 1 12 0
 157 00a0 9C210004 		l.addi	r1,r1,4
 158 00a4 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 159 00a8 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 160              		.cfi_endproc
 161              	.LFE7:
 162              		.size	dtlbmiss_except, .-dtlbmiss_except
 163              		.align	4
 164              	.proc	itlbmiss_except
 165              		.global itlbmiss_except
 166              		.type	itlbmiss_except, @function
 167              	itlbmiss_except:
 168              	.LFB8:
  13:hello.c       **** void itlbmiss_except(){}
 169              		.loc 1 13 0
 170              		.cfi_startproc
 171 00ac D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
 172              		.cfi_offset 1, -4
 173 00b0 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
 174              		.cfi_def_cfa_offset 4
 175              		.loc 1 13 0
 176 00b4 9C210004 		l.addi	r1,r1,4
 177 00b8 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 178 00bc 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 179              		.cfi_endproc
 180              	.LFE8:
 181              		.size	itlbmiss_except, .-itlbmiss_except
 182              		.align	4
 183              	.proc	range_except
 184              		.global range_except
 185              		.type	range_except, @function
 186              	range_except:
 187              	.LFB9:
  14:hello.c       **** void range_except(){}
 188              		.loc 1 14 0
 189              		.cfi_startproc
 190 00c0 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
 191              		.cfi_offset 1, -4
 192 00c4 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
 193              		.cfi_def_cfa_offset 4
 194              		.loc 1 14 0
 195 00c8 9C210004 		l.addi	r1,r1,4
 196 00cc 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 197 00d0 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 198              		.cfi_endproc
 199              	.LFE9:
 200              		.size	range_except, .-range_except
 201              		.align	4
 202              	.proc	fpu_except
 203              		.global fpu_except
 204              		.type	fpu_except, @function
 205              	fpu_except:
 206              	.LFB10:
  15:hello.c       **** //void syscall_except(){}
  16:hello.c       **** void fpu_except(){}
 207              		.loc 1 16 0
 208              		.cfi_startproc
 209 00d4 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
 210              		.cfi_offset 1, -4
 211 00d8 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
 212              		.cfi_def_cfa_offset 4
 213              		.loc 1 16 0
 214 00dc 9C210004 		l.addi	r1,r1,4
 215 00e0 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 216 00e4 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 217              		.cfi_endproc
 218              	.LFE10:
 219              		.size	fpu_except, .-fpu_except
 220              		.align	4
 221              	.proc	trap_except
 222              		.global trap_except
 223              		.type	trap_except, @function
 224              	trap_except:
 225              	.LFB11:
  17:hello.c       **** void trap_except(){}
 226              		.loc 1 17 0
 227              		.cfi_startproc
 228 00e8 D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
 229              		.cfi_offset 1, -4
 230 00ec 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
 231              		.cfi_def_cfa_offset 4
 232              		.loc 1 17 0
 233 00f0 9C210004 		l.addi	r1,r1,4
 234 00f4 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 235 00f8 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 236              		.cfi_endproc
 237              	.LFE11:
 238              		.size	trap_except, .-trap_except
 239              		.align	4
 240              	.proc	res2_except
 241              		.global res2_except
 242              		.type	res2_except, @function
 243              	res2_except:
 244              	.LFB12:
  18:hello.c       **** void res2_except(){}
 245              		.loc 1 18 0
 246              		.cfi_startproc
 247 00fc D7E10FFC 		l.sw    	-4(r1),r1	 # SI store
 248              		.cfi_offset 1, -4
 249 0100 9C21FFFC 		l.addi  	r1,r1,-4 # addsi3
 250              		.cfi_def_cfa_offset 4
 251              		.loc 1 18 0
 252 0104 9C210004 		l.addi	r1,r1,4
 253 0108 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 254 010c 8421FFFC 		l.lwz   	r1,-4(r1)	 # SI load
 255              		.cfi_endproc
 256              	.LFE12:
 257              		.size	res2_except, .-res2_except
 258              		.section	.rodata.str1.1,"aMS",@progbits,1
 259              	.LC0:
 260 0000 48656C6C 		.string	"Hello World #%i!\n"
 260      6F20576F 
 260      726C6420 
 260      23256921 
 260      0A00
 261              		.section	.text.startup,"ax",@progbits
 262              		.align	4
 263              	.proc	main
 264              		.global main
 265              		.type	main, @function
 266              	main:
 267              	.LFB13:
  19:hello.c       **** 
  20:hello.c       **** 
  21:hello.c       **** int main () {
 268              		.loc 1 21 0
 269              		.cfi_startproc
 270              	.LVL1:
 271 0000 D7E117F8 		l.sw    	-8(r1),r2	 # SI store
 272 0004 D7E14FFC 		l.sw    	-4(r1),r9	 # SI store
 273 0008 D7E10FF4 		l.sw    	-12(r1),r1	 # SI store
 274              		.cfi_offset 2, -8
 275              		.cfi_offset 9, -4
 276              		.cfi_offset 1, -12
  22:hello.c       ****   int n;
  23:hello.c       **** 
  24:hello.c       ****   for (n = 0; n < 10; n++)
 277              		.loc 1 24 0
 278 000c 9C400000 		l.addi  	r2,r0,0	 # move immediate I
  21:hello.c       ****   int n;
 279              		.loc 1 21 0
 280 0010 9C21FFF0 		l.addi  	r1,r1,-16 # addsi3
 281              		.cfi_def_cfa_offset 16
 282              	.LVL2:
  25:hello.c       ****     printf ("Hello World #%i!\n", n);
 283              		.loc 1 25 0 discriminator 3
 284 0014 18600000 		l.movhi  	r3,hi(.LC0) # movsi_high
 285              	.L18:
 286 0018 D4011000 		l.sw    	0(r1),r2	 # SI store
 287 001c A8630000 		l.ori   	r3,r3,lo(.LC0) # movsi_lo_sum
 288              	.LVL3:
 289 0020 04000000 		l.jal   	printf# call_internal	# delay slot filled
 290 0024 9C420001 		l.addi  	r2,r2,1 # addsi3
 291              	.LVL4:
  24:hello.c       ****     printf ("Hello World #%i!\n", n);
 292              		.loc 1 24 0 discriminator 3
 293 0028 BC22000A 		l.sfnei	r2,10 # cmpsi_ne
 294 002c 13FFFFFB 		l.bf	.L18	# delay slot filled
 295 0030 18600000 		l.movhi  	r3,hi(.LC0) # movsi_high
  26:hello.c       **** }
 296              		.loc 1 26 0
 297 0034 9C210010 		l.addi	r1,r1,16
 298 0038 8521FFFC 		l.lwz   	r9,-4(r1)	 # SI load
 299 003c 8421FFF4 		l.lwz   	r1,-12(r1)	 # SI load
 300              	.LVL5:
 301 0040 44004800 		l.jr    	r9	# return_internal	# delay slot filled
 302 0044 8441FFF8 		l.lwz   	r2,-8(r1)	 # SI load
 303              		.cfi_endproc
 304              	.LFE13:
 305              		.size	main, .-main
 306              		.section .text
 307              	.Letext0:
 308              		.file 2 "/home/gundolf/hsa/paranut/src/sw/hello/openrisc/orpsocv2/sw/support/support.h"
 309              		.section	.debug_info,"",@progbits
 310              	.Ldebug_info0:
 311 0000 000001A9 		.4byte	0x1a9
 312 0004 0004     		.2byte	0x4
 313 0006 00000000 		.4byte	.Ldebug_abbrev0
 314 000a 04       		.byte	0x4
 315 000b 01       		.uleb128 0x1
 316 000c 00000000 		.4byte	.LASF17
 317 0010 01       		.byte	0x1
 318 0011 00000000 		.4byte	.LASF18
 319 0015 00000000 		.4byte	.LASF19
 320 0019 00000000 		.4byte	.Ldebug_ranges0+0
 321 001d 00000000 		.4byte	0
 322 0021 00000000 		.4byte	.Ldebug_line0
 323 0025 02       		.uleb128 0x2
 324 0026 04       		.byte	0x4
 325 0027 05       		.byte	0x5
 326 0028 00000000 		.4byte	.LASF0
 327 002c 02       		.uleb128 0x2
 328 002d 04       		.byte	0x4
 329 002e 07       		.byte	0x7
 330 002f 00000000 		.4byte	.LASF1
 331 0033 03       		.uleb128 0x3
 332 0034 04       		.byte	0x4
 333 0035 05       		.byte	0x5
 334 0036 696E7400 		.string	"int"
 335 003a 04       		.uleb128 0x4
 336 003b 00000000 		.4byte	.LASF2
 337 003f 01       		.byte	0x1
 338 0040 05       		.byte	0x5
 339 0041 00000000 		.4byte	.LFB0
 340 0045 00000014 		.4byte	.LFE0-.LFB0
 341 0049 01       		.uleb128 0x1
 342 004a 9C       		.byte	0x9c
 343 004b 04       		.uleb128 0x4
 344 004c 00000000 		.4byte	.LASF3
 345 0050 01       		.byte	0x1
 346 0051 06       		.byte	0x6
 347 0052 00000000 		.4byte	.LFB1
 348 0056 00000014 		.4byte	.LFE1-.LFB1
 349 005a 01       		.uleb128 0x1
 350 005b 9C       		.byte	0x9c
 351 005c 04       		.uleb128 0x4
 352 005d 00000000 		.4byte	.LASF4
 353 0061 01       		.byte	0x1
 354 0062 07       		.byte	0x7
 355 0063 00000000 		.4byte	.LFB2
 356 0067 00000014 		.4byte	.LFE2-.LFB2
 357 006b 01       		.uleb128 0x1
 358 006c 9C       		.byte	0x9c
 359 006d 05       		.uleb128 0x5
 360 006e 00000000 		.4byte	.LASF20
 361 0072 01       		.byte	0x1
 362 0073 08       		.byte	0x8
 363 0074 00000000 		.4byte	.LFB3
 364 0078 00000020 		.4byte	.LFE3-.LFB3
 365 007c 01       		.uleb128 0x1
 366 007d 9C       		.byte	0x9c
 367 007e 0000009D 		.4byte	0x9d
 368 0082 06       		.uleb128 0x6
 369 0083 00000000 		.4byte	.LASF14
 370 0087 01       		.byte	0x1
 371 0088 08       		.byte	0x8
 372 0089 00000033 		.4byte	0x33
 373 008d 00000093 		.4byte	0x93
 374 0091 07       		.uleb128 0x7
 375 0092 00       		.byte	0
 376 0093 08       		.uleb128 0x8
 377 0094 00000000 		.4byte	.LVL0
 378 0098 00000177 		.4byte	0x177
 379 009c 00       		.byte	0
 380 009d 04       		.uleb128 0x4
 381 009e 00000000 		.4byte	.LASF5
 382 00a2 01       		.byte	0x1
 383 00a3 09       		.byte	0x9
 384 00a4 00000000 		.4byte	.LFB4
 385 00a8 00000014 		.4byte	.LFE4-.LFB4
 386 00ac 01       		.uleb128 0x1
 387 00ad 9C       		.byte	0x9c
 388 00ae 04       		.uleb128 0x4
 389 00af 00000000 		.4byte	.LASF6
 390 00b3 01       		.byte	0x1
 391 00b4 0A       		.byte	0xa
 392 00b5 00000000 		.4byte	.LFB5
 393 00b9 00000014 		.4byte	.LFE5-.LFB5
 394 00bd 01       		.uleb128 0x1
 395 00be 9C       		.byte	0x9c
 396 00bf 04       		.uleb128 0x4
 397 00c0 00000000 		.4byte	.LASF7
 398 00c4 01       		.byte	0x1
 399 00c5 0B       		.byte	0xb
 400 00c6 00000000 		.4byte	.LFB6
 401 00ca 00000014 		.4byte	.LFE6-.LFB6
 402 00ce 01       		.uleb128 0x1
 403 00cf 9C       		.byte	0x9c
 404 00d0 04       		.uleb128 0x4
 405 00d1 00000000 		.4byte	.LASF8
 406 00d5 01       		.byte	0x1
 407 00d6 0C       		.byte	0xc
 408 00d7 00000000 		.4byte	.LFB7
 409 00db 00000014 		.4byte	.LFE7-.LFB7
 410 00df 01       		.uleb128 0x1
 411 00e0 9C       		.byte	0x9c
 412 00e1 04       		.uleb128 0x4
 413 00e2 00000000 		.4byte	.LASF9
 414 00e6 01       		.byte	0x1
 415 00e7 0D       		.byte	0xd
 416 00e8 00000000 		.4byte	.LFB8
 417 00ec 00000014 		.4byte	.LFE8-.LFB8
 418 00f0 01       		.uleb128 0x1
 419 00f1 9C       		.byte	0x9c
 420 00f2 04       		.uleb128 0x4
 421 00f3 00000000 		.4byte	.LASF10
 422 00f7 01       		.byte	0x1
 423 00f8 0E       		.byte	0xe
 424 00f9 00000000 		.4byte	.LFB9
 425 00fd 00000014 		.4byte	.LFE9-.LFB9
 426 0101 01       		.uleb128 0x1
 427 0102 9C       		.byte	0x9c
 428 0103 04       		.uleb128 0x4
 429 0104 00000000 		.4byte	.LASF11
 430 0108 01       		.byte	0x1
 431 0109 10       		.byte	0x10
 432 010a 00000000 		.4byte	.LFB10
 433 010e 00000014 		.4byte	.LFE10-.LFB10
 434 0112 01       		.uleb128 0x1
 435 0113 9C       		.byte	0x9c
 436 0114 04       		.uleb128 0x4
 437 0115 00000000 		.4byte	.LASF12
 438 0119 01       		.byte	0x1
 439 011a 11       		.byte	0x11
 440 011b 00000000 		.4byte	.LFB11
 441 011f 00000014 		.4byte	.LFE11-.LFB11
 442 0123 01       		.uleb128 0x1
 443 0124 9C       		.byte	0x9c
 444 0125 04       		.uleb128 0x4
 445 0126 00000000 		.4byte	.LASF13
 446 012a 01       		.byte	0x1
 447 012b 12       		.byte	0x12
 448 012c 00000000 		.4byte	.LFB12
 449 0130 00000014 		.4byte	.LFE12-.LFB12
 450 0134 01       		.uleb128 0x1
 451 0135 9C       		.byte	0x9c
 452 0136 09       		.uleb128 0x9
 453 0137 00000000 		.4byte	.LASF21
 454 013b 01       		.byte	0x1
 455 013c 15       		.byte	0x15
 456 013d 00000033 		.4byte	0x33
 457 0141 00000000 		.4byte	.LFB13
 458 0145 00000048 		.4byte	.LFE13-.LFB13
 459 0149 01       		.uleb128 0x1
 460 014a 9C       		.byte	0x9c
 461 014b 00000177 		.4byte	0x177
 462 014f 0A       		.uleb128 0xa
 463 0150 6E00     		.string	"n"
 464 0152 01       		.byte	0x1
 465 0153 16       		.byte	0x16
 466 0154 00000033 		.4byte	0x33
 467 0158 00000000 		.4byte	.LLST0
 468 015c 0B       		.uleb128 0xb
 469 015d 00000000 		.4byte	.LVL4
 470 0161 00000188 		.4byte	0x188
 471 0165 0C       		.uleb128 0xc
 472 0166 01       		.uleb128 0x1
 473 0167 53       		.byte	0x53
 474 0168 05       		.uleb128 0x5
 475 0169 03       		.byte	0x3
 476 016a 00000000 		.4byte	.LC0
 477 016e 0C       		.uleb128 0xc
 478 016f 02       		.uleb128 0x2
 479 0170 71       		.byte	0x71
 480 0171 00       		.sleb128 0
 481 0172 02       		.uleb128 0x2
 482 0173 72       		.byte	0x72
 483 0174 7F       		.sleb128 -1
 484 0175 00       		.byte	0
 485 0176 00       		.byte	0
 486 0177 06       		.uleb128 0x6
 487 0178 00000000 		.4byte	.LASF14
 488 017c 01       		.byte	0x1
 489 017d 08       		.byte	0x8
 490 017e 00000033 		.4byte	0x33
 491 0182 00000188 		.4byte	0x188
 492 0186 07       		.uleb128 0x7
 493 0187 00       		.byte	0
 494 0188 0D       		.uleb128 0xd
 495 0189 00000000 		.4byte	.LASF15
 496 018d 02       		.byte	0x2
 497 018e 13       		.byte	0x13
 498 018f 0000019A 		.4byte	0x19a
 499 0193 0E       		.uleb128 0xe
 500 0194 0000019A 		.4byte	0x19a
 501 0198 07       		.uleb128 0x7
 502 0199 00       		.byte	0
 503 019a 0F       		.uleb128 0xf
 504 019b 04       		.byte	0x4
 505 019c 000001A0 		.4byte	0x1a0
 506 01a0 10       		.uleb128 0x10
 507 01a1 000001A5 		.4byte	0x1a5
 508 01a5 02       		.uleb128 0x2
 509 01a6 01       		.byte	0x1
 510 01a7 06       		.byte	0x6
 511 01a8 00000000 		.4byte	.LASF16
 512 01ac 00       		.byte	0
 513              		.section	.debug_abbrev,"",@progbits
 514              	.Ldebug_abbrev0:
 515 0000 01       		.uleb128 0x1
 516 0001 11       		.uleb128 0x11
 517 0002 01       		.byte	0x1
 518 0003 25       		.uleb128 0x25
 519 0004 0E       		.uleb128 0xe
 520 0005 13       		.uleb128 0x13
 521 0006 0B       		.uleb128 0xb
 522 0007 03       		.uleb128 0x3
 523 0008 0E       		.uleb128 0xe
 524 0009 1B       		.uleb128 0x1b
 525 000a 0E       		.uleb128 0xe
 526 000b 55       		.uleb128 0x55
 527 000c 17       		.uleb128 0x17
 528 000d 11       		.uleb128 0x11
 529 000e 01       		.uleb128 0x1
 530 000f 10       		.uleb128 0x10
 531 0010 17       		.uleb128 0x17
 532 0011 00       		.byte	0
 533 0012 00       		.byte	0
 534 0013 02       		.uleb128 0x2
 535 0014 24       		.uleb128 0x24
 536 0015 00       		.byte	0
 537 0016 0B       		.uleb128 0xb
 538 0017 0B       		.uleb128 0xb
 539 0018 3E       		.uleb128 0x3e
 540 0019 0B       		.uleb128 0xb
 541 001a 03       		.uleb128 0x3
 542 001b 0E       		.uleb128 0xe
 543 001c 00       		.byte	0
 544 001d 00       		.byte	0
 545 001e 03       		.uleb128 0x3
 546 001f 24       		.uleb128 0x24
 547 0020 00       		.byte	0
 548 0021 0B       		.uleb128 0xb
 549 0022 0B       		.uleb128 0xb
 550 0023 3E       		.uleb128 0x3e
 551 0024 0B       		.uleb128 0xb
 552 0025 03       		.uleb128 0x3
 553 0026 08       		.uleb128 0x8
 554 0027 00       		.byte	0
 555 0028 00       		.byte	0
 556 0029 04       		.uleb128 0x4
 557 002a 2E       		.uleb128 0x2e
 558 002b 00       		.byte	0
 559 002c 3F       		.uleb128 0x3f
 560 002d 19       		.uleb128 0x19
 561 002e 03       		.uleb128 0x3
 562 002f 0E       		.uleb128 0xe
 563 0030 3A       		.uleb128 0x3a
 564 0031 0B       		.uleb128 0xb
 565 0032 3B       		.uleb128 0x3b
 566 0033 0B       		.uleb128 0xb
 567 0034 11       		.uleb128 0x11
 568 0035 01       		.uleb128 0x1
 569 0036 12       		.uleb128 0x12
 570 0037 06       		.uleb128 0x6
 571 0038 40       		.uleb128 0x40
 572 0039 18       		.uleb128 0x18
 573 003a 9742     		.uleb128 0x2117
 574 003c 19       		.uleb128 0x19
 575 003d 00       		.byte	0
 576 003e 00       		.byte	0
 577 003f 05       		.uleb128 0x5
 578 0040 2E       		.uleb128 0x2e
 579 0041 01       		.byte	0x1
 580 0042 3F       		.uleb128 0x3f
 581 0043 19       		.uleb128 0x19
 582 0044 03       		.uleb128 0x3
 583 0045 0E       		.uleb128 0xe
 584 0046 3A       		.uleb128 0x3a
 585 0047 0B       		.uleb128 0xb
 586 0048 3B       		.uleb128 0x3b
 587 0049 0B       		.uleb128 0xb
 588 004a 11       		.uleb128 0x11
 589 004b 01       		.uleb128 0x1
 590 004c 12       		.uleb128 0x12
 591 004d 06       		.uleb128 0x6
 592 004e 40       		.uleb128 0x40
 593 004f 18       		.uleb128 0x18
 594 0050 9742     		.uleb128 0x2117
 595 0052 19       		.uleb128 0x19
 596 0053 01       		.uleb128 0x1
 597 0054 13       		.uleb128 0x13
 598 0055 00       		.byte	0
 599 0056 00       		.byte	0
 600 0057 06       		.uleb128 0x6
 601 0058 2E       		.uleb128 0x2e
 602 0059 01       		.byte	0x1
 603 005a 3F       		.uleb128 0x3f
 604 005b 19       		.uleb128 0x19
 605 005c 03       		.uleb128 0x3
 606 005d 0E       		.uleb128 0xe
 607 005e 3A       		.uleb128 0x3a
 608 005f 0B       		.uleb128 0xb
 609 0060 3B       		.uleb128 0x3b
 610 0061 0B       		.uleb128 0xb
 611 0062 49       		.uleb128 0x49
 612 0063 13       		.uleb128 0x13
 613 0064 3C       		.uleb128 0x3c
 614 0065 19       		.uleb128 0x19
 615 0066 01       		.uleb128 0x1
 616 0067 13       		.uleb128 0x13
 617 0068 00       		.byte	0
 618 0069 00       		.byte	0
 619 006a 07       		.uleb128 0x7
 620 006b 18       		.uleb128 0x18
 621 006c 00       		.byte	0
 622 006d 00       		.byte	0
 623 006e 00       		.byte	0
 624 006f 08       		.uleb128 0x8
 625 0070 898201   		.uleb128 0x4109
 626 0073 00       		.byte	0
 627 0074 11       		.uleb128 0x11
 628 0075 01       		.uleb128 0x1
 629 0076 31       		.uleb128 0x31
 630 0077 13       		.uleb128 0x13
 631 0078 00       		.byte	0
 632 0079 00       		.byte	0
 633 007a 09       		.uleb128 0x9
 634 007b 2E       		.uleb128 0x2e
 635 007c 01       		.byte	0x1
 636 007d 3F       		.uleb128 0x3f
 637 007e 19       		.uleb128 0x19
 638 007f 03       		.uleb128 0x3
 639 0080 0E       		.uleb128 0xe
 640 0081 3A       		.uleb128 0x3a
 641 0082 0B       		.uleb128 0xb
 642 0083 3B       		.uleb128 0x3b
 643 0084 0B       		.uleb128 0xb
 644 0085 49       		.uleb128 0x49
 645 0086 13       		.uleb128 0x13
 646 0087 11       		.uleb128 0x11
 647 0088 01       		.uleb128 0x1
 648 0089 12       		.uleb128 0x12
 649 008a 06       		.uleb128 0x6
 650 008b 40       		.uleb128 0x40
 651 008c 18       		.uleb128 0x18
 652 008d 9742     		.uleb128 0x2117
 653 008f 19       		.uleb128 0x19
 654 0090 01       		.uleb128 0x1
 655 0091 13       		.uleb128 0x13
 656 0092 00       		.byte	0
 657 0093 00       		.byte	0
 658 0094 0A       		.uleb128 0xa
 659 0095 34       		.uleb128 0x34
 660 0096 00       		.byte	0
 661 0097 03       		.uleb128 0x3
 662 0098 08       		.uleb128 0x8
 663 0099 3A       		.uleb128 0x3a
 664 009a 0B       		.uleb128 0xb
 665 009b 3B       		.uleb128 0x3b
 666 009c 0B       		.uleb128 0xb
 667 009d 49       		.uleb128 0x49
 668 009e 13       		.uleb128 0x13
 669 009f 02       		.uleb128 0x2
 670 00a0 17       		.uleb128 0x17
 671 00a1 00       		.byte	0
 672 00a2 00       		.byte	0
 673 00a3 0B       		.uleb128 0xb
 674 00a4 898201   		.uleb128 0x4109
 675 00a7 01       		.byte	0x1
 676 00a8 11       		.uleb128 0x11
 677 00a9 01       		.uleb128 0x1
 678 00aa 31       		.uleb128 0x31
 679 00ab 13       		.uleb128 0x13
 680 00ac 00       		.byte	0
 681 00ad 00       		.byte	0
 682 00ae 0C       		.uleb128 0xc
 683 00af 8A8201   		.uleb128 0x410a
 684 00b2 00       		.byte	0
 685 00b3 02       		.uleb128 0x2
 686 00b4 18       		.uleb128 0x18
 687 00b5 9142     		.uleb128 0x2111
 688 00b7 18       		.uleb128 0x18
 689 00b8 00       		.byte	0
 690 00b9 00       		.byte	0
 691 00ba 0D       		.uleb128 0xd
 692 00bb 2E       		.uleb128 0x2e
 693 00bc 01       		.byte	0x1
 694 00bd 3F       		.uleb128 0x3f
 695 00be 19       		.uleb128 0x19
 696 00bf 03       		.uleb128 0x3
 697 00c0 0E       		.uleb128 0xe
 698 00c1 3A       		.uleb128 0x3a
 699 00c2 0B       		.uleb128 0xb
 700 00c3 3B       		.uleb128 0x3b
 701 00c4 0B       		.uleb128 0xb
 702 00c5 27       		.uleb128 0x27
 703 00c6 19       		.uleb128 0x19
 704 00c7 3C       		.uleb128 0x3c
 705 00c8 19       		.uleb128 0x19
 706 00c9 01       		.uleb128 0x1
 707 00ca 13       		.uleb128 0x13
 708 00cb 00       		.byte	0
 709 00cc 00       		.byte	0
 710 00cd 0E       		.uleb128 0xe
 711 00ce 05       		.uleb128 0x5
 712 00cf 00       		.byte	0
 713 00d0 49       		.uleb128 0x49
 714 00d1 13       		.uleb128 0x13
 715 00d2 00       		.byte	0
 716 00d3 00       		.byte	0
 717 00d4 0F       		.uleb128 0xf
 718 00d5 0F       		.uleb128 0xf
 719 00d6 00       		.byte	0
 720 00d7 0B       		.uleb128 0xb
 721 00d8 0B       		.uleb128 0xb
 722 00d9 49       		.uleb128 0x49
 723 00da 13       		.uleb128 0x13
 724 00db 00       		.byte	0
 725 00dc 00       		.byte	0
 726 00dd 10       		.uleb128 0x10
 727 00de 26       		.uleb128 0x26
 728 00df 00       		.byte	0
 729 00e0 49       		.uleb128 0x49
 730 00e1 13       		.uleb128 0x13
 731 00e2 00       		.byte	0
 732 00e3 00       		.byte	0
 733 00e4 00       		.byte	0
 734              		.section	.debug_loc,"",@progbits
 735              	.Ldebug_loc0:
 736              	.LLST0:
 737 0000 00000000 		.4byte	.LVL1
 738 0004 00000000 		.4byte	.LVL2
 739 0008 0002     		.2byte	0x2
 740 000a 30       		.byte	0x30
 741 000b 9F       		.byte	0x9f
 742 000c 00000000 		.4byte	.LVL2
 743 0010 00000000 		.4byte	.LVL3
 744 0014 0001     		.2byte	0x1
 745 0016 52       		.byte	0x52
 746 0017 00000000 		.4byte	.LVL3
 747 001b 00000000 		.4byte	.LVL4-1
 748 001f 0002     		.2byte	0x2
 749 0021 71       		.byte	0x71
 750 0022 00       		.sleb128 0
 751 0023 00000000 		.4byte	.LVL4-1
 752 0027 00000000 		.4byte	.LVL4
 753 002b 0003     		.2byte	0x3
 754 002d 72       		.byte	0x72
 755 002e 7F       		.sleb128 -1
 756 002f 9F       		.byte	0x9f
 757 0030 00000000 		.4byte	.LVL4
 758 0034 00000000 		.4byte	.LVL5
 759 0038 0001     		.2byte	0x1
 760 003a 52       		.byte	0x52
 761 003b 00000000 		.4byte	0
 762 003f 00000000 		.4byte	0
 763              		.section	.debug_aranges,"",@progbits
 764 0000 00000024 		.4byte	0x24
 765 0004 0002     		.2byte	0x2
 766 0006 00000000 		.4byte	.Ldebug_info0
 767 000a 04       		.byte	0x4
 768 000b 00       		.byte	0
 769 000c 0000     		.2byte	0
 770 000e 0000     		.2byte	0
 771 0010 00000000 		.4byte	.Ltext0
 772 0014 00000110 		.4byte	.Letext0-.Ltext0
 773 0018 00000000 		.4byte	.LFB13
 774 001c 00000048 		.4byte	.LFE13-.LFB13
 775 0020 00000000 		.4byte	0
 776 0024 00000000 		.4byte	0
 777              		.section	.debug_ranges,"",@progbits
 778              	.Ldebug_ranges0:
 779 0000 00000000 		.4byte	.Ltext0
 780 0004 00000000 		.4byte	.Letext0
 781 0008 00000000 		.4byte	.LFB13
 782 000c 00000000 		.4byte	.LFE13
 783 0010 00000000 		.4byte	0
 784 0014 00000000 		.4byte	0
 785              		.section	.debug_line,"",@progbits
 786              	.Ldebug_line0:
 787 0000 000000B7 		.section	.debug_str,"MS",@progbits,1
 787      00020000 
 787      006F0401 
 787      FB0E0D00 
 787      01010101 
 788              	.LASF14:
 789 0000 74696D65 		.string	"timer_interrupt"
 789      725F696E 
 789      74657272 
 789      75707400 
 790              	.LASF3:
 791 0010 6470665F 		.string	"dpf_except"
 791      65786365 
 791      707400
 792              	.LASF4:
 793 001b 6970665F 		.string	"ipf_except"
 793      65786365 
 793      707400
 794              	.LASF10:
 795 0026 72616E67 		.string	"range_except"
 795      655F6578 
 795      63657074 
 795      00
 796              	.LASF17:
 797 0033 474E5520 		.string	"GNU C 4.9.2 -mnewlib -g -O2"
 797      4320342E 
 797      392E3220 
 797      2D6D6E65 
 797      776C6962 
 798              	.LASF6:
 799 004f 696C6C65 		.string	"illegal_except"
 799      67616C5F 
 799      65786365 
 799      707400
 800              	.LASF1:
 801 005e 6C6F6E67 		.string	"long unsigned int"
 801      20756E73 
 801      69676E65 
 801      6420696E 
 801      7400
 802              	.LASF11:
 803 0070 6670755F 		.string	"fpu_except"
 803      65786365 
 803      707400
 804              	.LASF12:
 805 007b 74726170 		.string	"trap_except"
 805      5F657863 
 805      65707400 
 806              	.LASF9:
 807 0087 69746C62 		.string	"itlbmiss_except"
 807      6D697373 
 807      5F657863 
 807      65707400 
 808              	.LASF8:
 809 0097 64746C62 		.string	"dtlbmiss_except"
 809      6D697373 
 809      5F657863 
 809      65707400 
 810              	.LASF21:
 811 00a7 6D61696E 		.string	"main"
 811      00
 812              	.LASF5:
 813 00ac 616C6967 		.string	"align_except"
 813      6E5F6578 
 813      63657074 
 813      00
 814              	.LASF0:
 815 00b9 6C6F6E67 		.string	"long int"
 815      20696E74 
 815      00
 816              	.LASF2:
 817 00c2 62757365 		.string	"buserr_except"
 817      72725F65 
 817      78636570 
 817      7400
 818              	.LASF13:
 819 00d0 72657332 		.string	"res2_except"
 819      5F657863 
 819      65707400 
 820              	.LASF7:
 821 00dc 6870696E 		.string	"hpint_except"
 821      745F6578 
 821      63657074 
 821      00
 822              	.LASF19:
 823 00e9 2F686F6D 		.string	"/home/gundolf/hsa/paranut/src/sw/hello"
 823      652F6775 
 823      6E646F6C 
 823      662F6873 
 823      612F7061 
 824              	.LASF15:
 825 0110 7072696E 		.string	"printf"
 825      746600
 826              	.LASF20:
 827 0117 6C70696E 		.string	"lpint_except"
 827      745F6578 
 827      63657074 
 827      00
 828              	.LASF16:
 829 0124 63686172 		.string	"char"
 829      00
 830              	.LASF18:
 831 0129 68656C6C 		.string	"hello.c"
 831      6F2E6300 
 832              		.ident	"GCC: (GNU) 4.9.2"
