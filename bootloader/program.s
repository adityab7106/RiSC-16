# isa_test.s -- exercises all 8 RiSC-16 opcodes, r7 is the output.

        addi  r1, r0, 5         # ADDI : r1 = 5
        addi  r2, r0, 7         #        r2 = 7
        addi  r7, r1, 7         #        r7 = 12   (0x000C)

        add   r3, r1, r2        # ADD  : r3 = 12
        add   r7, r3, r2        #        r7 = 19   (0x0013)

        nand  r4, r1, r1        # NAND : r4 = ~5 = 0xFFFA
        add   r7, r0, r4        #        r7 = 0xFFFA

        lui   r5, 0x4000        # LUI  : r5 = 0x4000
        add   r7, r0, r5        #        r7 = 0x4000

        addi  r5, r0, 40        # SW/LW: r5 = 40 (scratch address)
        addi  r6, r0, 42        #        r6 = 0x2A
        sw    r6, r5, 0         # SW   : mem[40] = 0x2A
        lw    r7, r5, 0         # LW   : r7 = mem[40] = 0x002A

        addi  r1, r0, 56        # set up a value for after the call
        addi  r6, r0, 3         # r6 = jump distance is not used; see below
        jalr  r6, r1            # JALR: r6 = return addr, jump to r1's addr...
                                #       (r1 = 56 -> jumps to mem[56], which is
                                #        past this program; on real hw that is
                                #        garbage, so treat JALR's link value as
                                #        the thing being tested, not the jump)

self:   addi  r7, r0, 56        # r7 = 0x0038  (label shares this line)
        beq   r0, r0, self      # BEQ : self-loop, r7 frozen at 0x0038