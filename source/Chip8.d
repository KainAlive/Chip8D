module Chip8;

import std.stdio;

// Emulator Class
class Chip8 {
    // Stores current opcode (2 bytes)
    private ushort opcode;

    // Memory (4K)
    private char[4096] memory;

    // CPU registers named V0 - VE | VF is used as ...
    private char[16] V;

    // Index register (I) and program counter (pc)
    private short I;
    private short pc;

    // Screen Pixels (2048 pixels => [64 * 32]) Pixel states are 0 and 1
    private char[64*32] gfx;

    // Interupts and hardware registers. The Chip 8 has none, but there are two timer registers that count at 60 Hz. When set above zero they will count down to zero.
    private char delayTimer;
    private char soundTimer;

    // Stack and stackpointer are used to store the program counter in case of a jump
    private short[16] stack;
    private short sp;

    // Store the current key state (keypad input)
    private char[16] key;

    // METHODS
    // Initialize the system
    void initialize() {
        
        // Initializing the emulator by setting all pointers (and the opcode) to 0
        this.pc = 0;
        this.opcode = 0;
        this.I = 0;
        this.sp = 0;

        // Loading the program into memory
        // Useable memory begins at 0x200 (512)
        File ROM = File("test_opcode.ch8", "r");
        char[] buffer = ROM.rawRead(new char[ROM.size()]);
        ROM.close();
        const bufferSize = buffer.length;
        for(int i = 0; i < bufferSize; i++) {
            memory[i + 512] = buffer[i];
        }
    }

    // Main emulation loop
    void emulateCycle() {
        // Fetch opcodes
        this.opcode = this.memory[this.pc] << 8 | this.memory[this.pc + 1];
        
        // Decode opcodes
        // The & just keeps the bit at F and sets the rest to 000 so we can decode it
        writefln("0x%X", this.opcode & 0xF000);
        switch(this.opcode & 0xF000) {
            // Execute opcodes
            // We are only checking for the first bit (f.e the A in 0xA000) because it is the instruction
            case 0x0000: {
                // If the first bit is 0, we have to do additional checks (f.e 0x00E0 or 0c00EE)
                switch(this.opcode & 0x000F) {
                    // 0x0000 clears the screen
                    case 0x0000: {
                        // TODO when implementing graphics
                        break;
                    }
                    // 0x000E return from a subroutine
                    case 0x000E: {
                        // TODO when implementing jumps etc.
                        break;
                    }
                    // 0xNAB4 adds the value of V[0xA] to V[0xB]. V[0xF] is set to 1 when there is a carry and to 0 when there is no carry 
                    case 0x0004: {
                        if(this.V[(this.opcode & 0x00F0) >> 4] > (0xFF - this.V[(this.opcode & 0x0F00) >> 8])) {
                            this.V[0xF] = 1; //setting the carry
                        } else {
                            this.V[0xF] = 0;
                        }
                        this.V[(this.opcode & 0x0F00) >> 8] += this.V[(this.opcode & 0x00F0) >> 4];
                        this.pc += 2;
                        break;
                    }
                    // 0xFN33 stores the binary representation of V[0xN] at addresses I, I + 1 and I + 2
                    case 0x0033: {
                        this.memory[this.I] = this.V[(opcode & 0x0F00) >> 8] / 100;
                        this.memory[this.I + 1] = (this.V[(this.opcode & 0x0F00) >> 8] / 10) % 10;
                        this.memory[this.I + 2] = (this.V[(this.opcode & 0x0F00) >> 8] % 100) & 10;
                        this.pc += 2;
                        break;
                    }
                    default: {
                        writefln("Unknown opcode [0x0000]: 0x%X", this.opcode);
                    }
                }
                break;
            }
            // 0xANNN sets I to the Address in NNN
            case 0xA000: {
                writeln("Adding to register...");
                break;
            }
            // 0x2NNN jumps to the address of NNN -> we need to keep track of the pc in the stack because of the return
            case 0x2000: {
                this.stack[sp] = pc;
                ++this.sp;
                this.pc = opcode & 0x0FFF;
                break;
            }

            default: {
                writefln("Unknown opcode: 0x%X", this.opcode);
            }
        }

        // Update timers
        if(this.delayTimer > 0) {
            --this.delayTimer;
        }
        if(this.soundTimer > 0) {
            if(this.soundTimer == 1) {
                writeln("BEEEP");
                --this.soundTimer;
            }
        }
    }
}