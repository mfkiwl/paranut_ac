.section .text

.global _start
.global done


#define R0 0
#define R1 1
#define R2 2
#define R3 3
#define R4 4
#define R5 5
#define R6 6
#define R7 7
#define R8 8
#define R9 9
#define R10 10
#define R11 11
#define R12 12
#define R13 13
#define R14 14
#define R15 15
#define R16 16
#define R17 17
#define R18 18
#define R19 19
#define R20 20
#define R21 21
#define R22 22
#define R23 23
#define R24 24
#define R25 25
#define R26 26
#define R27 27
#define R28 28
#define R29 29
#define R30 30
#define R31 31

#define PN_CWRITEBACK(BASE, REG)   .word (0xf8001000 | ((REG) << 16) | ((BASE) & 0x7ff) | (((BASE) & 0xf800) << 10))
        # 111110 iiiii aaaaa ---10 i ii iiii iiii         # cache writeback
#define PN_CINVALIDATE(BASE, REG)  .word (0xf8000800 | ((REG) << 16) | ((BASE) & 0x7ff) | (((BASE) & 0xf800) << 10))
        # 111110 iiiii aaaaa ---01 i ii iiii iiii         # cache invalidate
#define PN_CFLUSH(BASE, REG)       .word (0xf8001800 | ((REG) << 16) | ((BASE) & 0x7ff) | (((BASE) & 0xf800) << 10))
        # 111110 iiiii aaaaa ---11 i ii iiii iiii         # cache flush


### Workaround macros
# NOTE: or32-elf-as (or32-elf-1.0rc1) does not assemble load/store instructions correctly:
#   - Labels for the adress offsets are accepted with the lo() operation, but lead to incorrect register operands..
#   - Offsets >= 0x800 are not put into the correct fields, leading to incorrect instructions.
# 
# The following macros work around these bugs and generate correct or1k instructions.

_zero:		.org 0

#define PN_SW(I, RA, RB)  	   .word (0xd4000000 | ((((I)-_zero) & 0xf800) << 10) | (((I)-_zero) & 0x7ff) | ((RA) << 16) | ((RB) << 11))
	# 110101 iiiii aaaaa bbbbb i ii iiii iiii
#define PN_SH(I, RA, RB)  	   .word (0xdc000000 | ((((I)-_zero) & 0xf800) << 10) | (((I)-_zero) & 0x7ff) | ((RA) << 16) | ((RB) << 11))
	# 110111 iiiii aaaaa bbbbb i ii iiii iiii
#define PN_SB(I, RA, RB)  	   .word (0xd8000000 | ((((I)-_zero) & 0xf800) << 10) | (((I)-_zero) & 0x7ff) | ((RA) << 16) | ((RB) << 11))
	# 110110 iiiii aaaaa bbbbb i ii iiii iiii

#define PN_LWZ(RD, I, RA)  	   .word (0x84000000 | (((I)-_zero) & 0xffff) | ((RD) << 21) | ((RA) << 16))
	# 100001 ddddd aaaaa iiiii i ii iiii iiii
#define PN_LWS(RD, I, RA)  	   .word (0x88000000 | (((I)-_zero) & 0xffff) | ((RD) << 21) | ((RA) << 16))
	# 100010 ddddd aaaaa iiiii i ii iiii iiii
#define PN_LHZ(RD, I, RA)  	   .word (0x94000000 | (((I)-_zero) & 0xffff) | ((RD) << 21) | ((RA) << 16))
	# 100101 ddddd aaaaa iiiii i ii iiii iiii
#define PN_LHS(RD, I, RA)  	   .word (0x98000000 | (((I)-_zero) & 0xffff) | ((RD) << 21) | ((RA) << 16))
	# 100110 ddddd aaaaa iiiii i ii iiii iiii
#define PN_LBZ(RD, I, RA)  	   .word (0x8c000000 | (((I)-_zero) & 0xffff) | ((RD) << 21) | ((RA) << 16))
	# 100011 ddddd aaaaa iiiii i ii iiii iiii
#define PN_LBS(RD, I, RA)  	   .word (0x90000000 | (((I)-_zero) & 0xffff) | ((RD) << 21) | ((RA) << 16))
	# 100100 ddddd aaaaa iiiii i ii iiii iiii




                .org 0x100
_start:         l.j go_ahead
                l.nop 0x0


# Result array...

#.section .data
.global result
.global load_ok
.global store_ok
.global alu_imm_ok
.global alu_reg_ok
.global alu_ext_ok
.global alu_shift_ok
.global alu_comp_ok
.global alu_comp_imm_ok
.global jump_ok
.global result_end


                        .org 0x700  # larger adresses cannot be used due to bug in or32-elf-as.
result:                 .byte 0xff, 0xff, 0xff, 0xff        # must become 0xcafebabe

load_ok:                .byte 0xff, 0xff, 0xff, 0xff        # must become 0
store_ok:               .byte 0xff, 0xff, 0xff, 0xff        # must become 0
alu_imm_ok:             .byte 0xff, 0xff, 0xff, 0xff        # must become 0
alu_reg_ok:             .byte 0xff, 0xff, 0xff, 0xff        # must become 0
alu_ext_ok:             .byte 0xff, 0xff, 0xff, 0xff        # must become 0
alu_shift_ok:           .byte 0xff, 0xff, 0xff, 0xff        # must become 0
alu_comp_ok:            .byte 0xff, 0xff, 0xff, 0xff        # must become 0
alu_comp_imm_ok:        .byte 0xff, 0xff, 0xff, 0xff        # must become 0
jump_ok:                .byte 0xff, 0xff, 0xff, 0xff        # must become 0

result_end:             .byte 0xde, 0xad, 0xbe, 0xef        # must remain 0xdeadbeef



### Main Programm

                .org 0x1000
go_ahead:       l.nop 0x0



### Load/Store instructions...

                .global load_store
load_store:     l.movhi r2, 0xcafe
                l.ori   r2, r2, 0xbabe
#                l.sw    result-_zero (r0), r2     # FIXME: This is assembled as "l.sw    lo(result) (r0), r0" !! (see above)
		PN_SW (result, R0, R2)

                # Load...
                l.movhi r1, hi(result)
                l.ori   r1, r1, lo(result)
                l.lwz   r1, 0 (r1)     # r1 = 0xcafebabe
                l.xor   r3, r1, r2

                PN_LHS	(R4, result, R0) #l.lhs   r4, lo(result) (r0)     # r4 = 0xffffcafe
                l.movhi r2, 0xffff
                l.ori   r2, r2, 0xcafe
                l.xor   r5, r4, r2
                l.or    r3, r3, r5
                PN_LHZ	(R5, result+2, R0) #l.lhz   r5, lo(result+2) (r0)   # r5 = 0x0000babe
                l.movhi r2, 0
                l.ori   r2, r2, 0xbabe
                l.xor   r5, r5, r2
                l.or    r3, r3, r5

                l.movhi r1, hi(result)
                l.ori   r1, r1, lo(result)
                l.lbs   r6, 0(r1)       # 0xffffffca
                l.lbs   r7, 2(r1)       # 0xffffffba
                l.lbs   r8, 3(r1)       # 0xffffffbe
                l.lbz   r9, 1(r1)       # 0x000000fe
                l.lbz   r10, 2(r1)      # 0x000000ba
                l.lbz   r11, 3(r1)      # 0x000000be

                l.xor   r12, r6, r9     # 0xffffff34
                l.xor   r13, r7, r11    # 0xffffff04
                l.xor   r14, r8, r10    # 0xffffff04
                l.movhi r15, 0xffff
                l.ori   r15, r15, 0xff34
                l.xor   r4, r12, r15
                l.or    r3, r3, r4
                l.xori  r15, r15, 0x30
                l.xor   r4, r13, r15            
                l.or    r3, r3, r4
                l.xor   r4, r14, r15
                l.or    r3, r3, r4

		PN_SW (load_ok, R0, R3)		#l.sw    lo(load_ok) (r0), r3
                
                # Store half word and byte...
                l.movhi r7, hi(store_ok)
                l.ori   r7, r7, lo(store_ok)
                l.ori   r4, r0, 0xdead
                PN_SH	(store_ok, R0, R4)	#l.sh    lo(store_ok) (r0), r4
                l.ori   r5, r0, 0xbeef
                l.sh    2 (r7), r5
                PN_LWZ	(R6, store_ok, R0)	#l.lwz   r6, lo(store_ok) (r0)   # 0xdeadbeef
                l.movhi r3, 0xdead
                l.ori   r3, r3, 0xbeef
                l.xor   r3, r3, r6

                l.ori   r8, r0, 0x12
                PN_SB	(store_ok, R0, R8)	# l.sb    lo(store_ok) (r0), r8
                l.ori   r9, r0, 0x34
                l.sb    1 (r7), r9
                l.ori   r10, r0, 0x56
                l.sb    2 (r7), r10
                l.ori   r11, r0, 0x78
                l.sb    3 (r7), r11
                l.lwz   r12, 0 (r7)
                l.movhi r13, 0x1234
                l.ori   r13, r13, 0x5678
                l.xor   r13, r13, r12
                l.or    r3, r3, r13

		PN_SW	(store_ok, R0, R3)	#l.sw    lo(store_ok) (r0), r3   # 0



### ALU instructions...

                .global alu
alu:            l.ori     r0, r0, 0xffff  # must be 0!

                # add, sub, logical, mul with immediates...
                .global alu_imm
alu_imm:        l.ori     r3, r0, 0x1234
                l.addi    r4, r3, 0x2326  # 0x355a (Carry is reset)
                l.addic   r5, r3, -0x0326 # 0x0f0e (Carry was reset, is now set)
                l.addic   r5, r5, -1      # 0x0f0e (Carry was set)
                l.andi    r6, r3, 0x2326  # 0x0224
                l.ori     r7, r3, 0x2326  # 0x3336
                l.muli    r8, r3, 5       # 0x5b04
                l.muli    r9, r3, -11     # 0xffff37c4

                l.add     r1, r4, r6      # 0x377e
                l.add     r1, r1, r8      # 0x9282
                l.addi    r1, r1, -0x7000 # 0x2282 (Carry is set)
                l.addic   r1, r1, -0x2283 # 0x0000 (Carry is set)
                l.add     r2, r5, r7      # 0x4244
                l.add     r2, r2, r9      # 0xffff7a08 (Carry is reset)
                l.addic   r2, r2, 0x7000  # 0xffffea08 (Carry is reset)
                l.addic   r2, r2, 0x15f8  # 0x0000 (Carry is set)
                l.or      r1, r1, r2
                PN_SW	(alu_imm_ok, R0, R1)
                #l.sw      lo(alu_imm_ok) (r0), r1

                # with register operands: check against immediate counterparts...
                .global alu_reg
alu_reg:        l.ori     r10, r0, 0x2326
                l.ori     r11, r0, 0x0326
                l.ori     r12, r0, 5
                l.xori    r13, r0, -11
                l.add     r14, r3, r10  # 0x355a, Carry := 0
                l.addc    r14, r14, r0  # 0x355a
                l.xor     r1, r14, r4
                l.sub     r14, r3, r11  # 0x0f0e, Carry := 0
                l.addc    r14, r14, r0  # 0x0f0f, Carry := 0
                l.xor     r2, r14, r5
                l.or      r1, r1, r2
		l.sub	  r14, r0, r10	# -0x2326, Carry := 1
                l.addic	  r14, r14, 0x2325
                l.or	  r1, r1, r14
                l.and     r14, r3, r10  # 0x0224
                l.xor     r2, r14, r6
                l.or      r1, r1, r2
                l.or      r14, r3, r10  # 0x3336
                l.xor     r2, r14, r7
                l.or      r1, r1, r2
                l.mulu    r14, r3, r12  # 0x5b04
                l.xor     r2, r14, r8   
                l.or      r1, r1, r2
                l.mul     r14, r3, r13  # 0xffff37c4
                l.xor     r2, r14, r9
                l.or      r1, r1, r2
                PN_SW	  (alu_reg_ok, R0, R1)	#l.sw      lo(alu_reg_ok) (r0), r1

                # test sign/zero extension...
                .global alu_ext
alu_ext:        l.xori    r3, r0, -1      # 0xffffffff
                l.addi    r1, r3, 1
                l.andi    r4, r3, 0xffff  # 0x0000ffff
                l.ori     r5, r4, 0xffff  # 0x0000ffff
                l.addi    r6, r5, 0x8000  # 0x00007fff
                l.xori    r2, r6, 0x7fff
                l.or      r1, r1, r2
                l.muli    r7, r3, -1      # 0x00000001
                l.xori    r2, r7, 1
                l.or      r1, r1, r2
                PN_SW	(alu_ext_ok, R0, R1)
                #l.sw      lo(alu_ext_ok) (r0), r1

                # shifts...
                .global alu_shift
alu_shift:      l.ori     r1, r0, 1
                l.ori     r2, r0, 10
                l.ori     r3, r0, 21
                l.movhi   r4, 0x4040
                l.ori     r4, r4, 0x1010  # 0x40401010

                l.sll     r5, r4, r1      # 0x80802020
                l.sll     r6, r1, r2      # 0x00000400
                l.sll     r7, r1, r3      # 0x00200000
                l.srl     r8, r4, r1      # 0x20200808
                l.srl     r9, r5, r2      # 0x00202008
                l.srl     r10, r5, r3     # 0x00000404
                l.sra     r11, r4, r1     # 0x20200808
                l.sra     r12, r5, r2     # 0xffe02008
                l.sra     r13, r5, r3     # 0xfffffc04

                l.xor     r1, r5, r6      # 0x80802420
                l.xor     r2, r7, r8      # 0x20000808
                l.xor     r3, r9, r10     # 0x0020240c
                l.xor     r4, r11, r12    # 0xdfc02800

                l.xor     r1, r1, r13     # 0x7f7fd824
                l.xor     r2, r2, r3      # 0x20202c04

                l.xor     r1, r1, r4      # 0xa0bff024

                l.xor     r1, r1, r2      # 0x809fdc20

                l.movhi   r2, 0x809f
                l.ori     r2, r2, 0xdc20
                l.xor     r1, r1, r2
                PN_SW	(alu_shift_ok, R0, R1)		
                #l.sw      lo(alu_shift_ok) (r0), r1

                # cmov, sfxxx ...
                .global alu_comp
alu_comp:       l.ori     r1, r0, 1
                l.xori    r3, r0, -5

                l.ori     r2, r0, 1
                l.sfeq    r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r0, r4
                l.sfeq    r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfeq    r2, r2      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                l.ori     r2, r0, 2
                l.sfne    r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfne    r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfne    r2, r2      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 4
                l.sfgtu   r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgtu   r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgtu   r2, r2      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 8
                l.sfgeu   r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgeu   r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgeu   r2, r2      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x10
                l.sfltu   r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfltu   r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfltu   r2, r2      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x20
                l.sfleu   r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfleu   r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfleu   r2, r2      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x40
                l.sfgts   r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgts   r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgts   r0, r1      # less (both unsigned and signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgts   r1, r0      # greater (both unsigned and signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgts   r2, r2      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x80
                l.sfges   r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfges   r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfges   r0, r1      # less (both unsigned and signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfges   r1, r0      # greater (both unsigned and signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfges   r2, r2      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x100
                l.sflts   r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sflts   r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sflts   r0, r1      # less (both unsigned and signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sflts   r1, r0      # greater (both unsigned and signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sflts   r2, r2      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x200
                l.sfles   r1, r3      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfles   r3, r1      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfles   r0, r1      # less (both unsigned and signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfles   r1, r0      # greater (both unsigned and signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfles   r2, r2      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                PN_SW	(alu_comp_ok, R0, R5)
                #l.sw      lo(alu_comp_ok) (r0), r5

                # sfxxxi ...
                .global alu_comp_imm
alu_comp_imm:   l.ori     r1, r0, 17
                l.xori    r3, r0, -9

                l.ori     r2, r0, 1
                l.sfeqi   r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r0, r4
                l.sfeqi   r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfeqi   r1, 17      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                l.ori     r2, r0, 2
                l.sfnei   r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfnei   r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfnei   r1, 17      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 4
                l.sfgtui  r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgtui  r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgtui  r1, 17      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 8
                l.sfgeui  r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgeui  r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgeui  r1, 17      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x10
                l.sfltui  r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfltui  r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfltui  r1, 17      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x20
                l.sfleui  r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfleui  r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfleui  r1, 17      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x40
                l.sfgtsi  r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgtsi  r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgtsi  r0, 17      # less (both unsigned and signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgtsi  r1, 0       # greater (both unsigned and signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgtsi  r1, 17      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x80
                l.sfgesi  r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgesi  r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgesi  r0, 17      # less (both unsigned and signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfgesi  r1, 0       # greater (both unsigned and signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfgesi  r1, 17      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x100
                l.sfltsi  r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfltsi  r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfltsi  r0, 17      # less (both unsigned and signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sfltsi  r1, 0       # greater (both unsigned and signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sfltsi  r1, 17      # equal
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4

                l.ori     r2, r0, 0x200
                l.sflesi  r1, -9      # less (unsigned) / greater (signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sflesi  r3, 17      # greater (unsigned) / less (signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sflesi  r0, 17      # less (both unsigned and signed)
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4
                l.sflesi  r1, 0       # greater (both unsigned and signed)
                l.cmov    r4, r2, r0
                l.or      r5, r5, r4
                l.sflesi  r1, 17      # equal
                l.cmov    r4, r0, r2
                l.or      r5, r5, r4

                PN_SW	(alu_comp_imm_ok, R0, R5)
                #l.sw      lo(alu_comp_imm_ok) (r0), r5




### Control flow instructions...

                .global jumps

jumps:          l.nop   0x0

                # J ...
                l.ori     r1, r0, 1
                l.j       cont_06
                l.xori    r1, r1, 1       # delay slot: r1 := 0
                l.ori     r1, r1, 1       # must not be executed
cont_05:        l.or      r2, r0, r0
                l.j       cont_01
                l.nop     0x0
cont_06:        l.ori     r2, r0, 1
                l.j       cont_05         # jump backwards
                l.nop     0x0
cont_01:        l.or      r1, r1, r2

                # JR ...
                l.ori     r2, r0, 2
                l.ori     r3, r0, lo(cont_02)
                l.jr      r3
                l.xori    r2, r2, 2       # delay slot: r2 := 0
                l.ori     r2, r2, 2       # must not be executed
cont_02:        l.or      r1, r1, r2

                # JAL ...
                l.ori     r2, r0, 4
                l.jal     cont_03
                l.xori    r2, r2, 4       # delay slot: r2 := 0
ret_01:         l.ori     r2, r2, 4       # must not be executed
cont_03:        l.ori     r3, r0, lo(ret_01)
                l.ori     r4, r0, 4
                l.sfeq    r3, r9          # Link register contains 'ret_01'?
                l.cmov    r2, r2, r4
                l.or      r1, r1, r2

                # JALR ...
                l.ori     r2, r0, 8
                l.ori     r3, r0, lo(cont_04)
                l.jalr    r3
                l.xori    r2, r2, 8       # delay slot: r2 := 0
ret_02:         l.ori     r2, r2, 8       # must not be executed
cont_04:        l.ori     r3, r0, lo(ret_02)
                l.ori     r4, r0, 8
                l.sfeq    r3, r9          # Link register contains 'ret_01'?
                l.cmov    r2, r2, r4
                l.or      r1, r1, r2
                
                # BF, BNF ...
                l.ori     r2, r0, 16+32+64+128
                l.sfeq    r0, r0
                l.bf      cont_07
                l.xori    r2, r2, 16
                l.ori     r2, r2, 16      # must not be executed
cont_07:        l.bnf     cont_08
                l.nop     0x0
                l.xori    r2, r2, 128
cont_08:        l.sfne    r0, r0
                l.bnf     cont_09
                l.xori    r2, r2, 64
                l.ori     r2, r2, 64      # must not be executed
cont_09:        l.bf      cont_10
                l.nop     0x0
                l.xori    r2, r2, 32
cont_10:        l.or      r1, r1, r2

                PN_SW	(jump_ok, R0, R1)
                #l.sw      lo(jump_ok) (r0), r1
        

### Syscall (TBD) ...


### Flush Cache ...

#flush_cache:    l.ori   r1, r0, lo(result)
#loop_1:         PN_CFLUSH(0, R1)
#                l.sfeqi r1, lo(result_end)
#                l.bnf   loop_1
#                l.addi  r1, r1, 4
                
done:            l.nop 0x1  # HALT
