module Chip8;

import std.stdio;
import std.random : uniform, Random;
import std.path;

// Emulator Class
class Chip8 {
    // Stores current opcode (2 bytes)
    private ushort opcode;

    // Memory (4K)
    char[4096] memory;

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

    // Random number generator
    auto rnd = Random(42);

    // METHODS
    // Initialize the system
    void initialize() {
        
        // Initializing the emulator by setting all pointers (and the opcode) to 0 | Useable memory begins at 0x200
        this.pc = 0x200;
        this.opcode = 0;
        this.I = 0;
        this.sp = 0;

        // Loading the program into memory
        // Useable memory begins at 0x200 (512)
        File ROM = File("UFO", "r");
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
        writef("\rPC: %s | OPCODE: 0x%X", this.pc, this.opcode & 0xFFFF);

        // Decode opcodes
        // The & just keeps the bit at F and sets the rest to 000 so we can decode it
        switch(this.opcode & 0xF000) {
            // Execute opcodes
            case 0x0000: {
                switch (this.opcode & 0xF0FF) {
                    // 0x0000 clears the screen
                    case 0x0000: {
                        // TODO when implementing graphics
                        writeln("Clear screen");
                        this.pc += 2;
                        break;
                    }

                    // 0x00EE returns from subroutine
                    case 0x00EE: {
                        this.pc = this.stack[--this.sp];
                        break;
                    }
                    default: {
                        break;
                    }
                }
                break;
            }
            // 0x1NNN jumps to address NNN
            case 0x1000: {
                this.pc = this.opcode & 0x0FFF;
                break;
            }

            // 0x2NNN calls a subroutine at address NNN -> we need to keep track of the pc in the stack because of the return
            case 0x2000: {
                this.stack[sp] = pc;
                ++this.sp;
                this.pc = opcode & 0x0FFF;
                break;
            }

            //0x3XNN skips the next instruction when V[X] equals NN
            case 0x3000: {
                if(this.V[(this.opcode & 0x0F00) >> 8] == (this.opcode & 0x00FF)) {
                    this.pc += 4;
                } else {
                    this.pc += 2;
                }
                break;
            }

            // 0x4XNN skips the next instruction when V[X] doesn't euqal NN
            case 0x4000: {
                if(this.V[(this.opcode & 0x0F00) >> 8] != (this.opcode & 0x00FF)) {
                    this.pc += 4;
                } else {
                    this.pc += 2;
                }
                break;
            }

            // 0x5XY0 skips the next instruction when V[X] equals V[Y]
            case 0x5000: {
                if(this.V[(this.opcode & 0x0F00) >> 8] == (this.opcode & 0x00F0) >> 4) {
                    this.pc += 4;
                } else {
                    this.pc += 2;
                }
                break;
            }
            
            // 0x6XNN sets V[X] to NN
            case 0x6000: {
                this.V[(this.opcode & 0x0F00) >> 8] = (this.opcode & 0x00FF);
                this.pc += 2;
                break;
            }
            
            // 0x7XNN adds NN to V[X] (wihout changing the carry flag)
            case 0x7000: {
                this.V[(this.opcode & 0x0F00) >> 8] += (this.opcode & 0x00FF);
                this.pc += 2;
                break;
            }

            // 0x8 requires additional checks
            case 0x8000: {
                switch (this.opcode & 0x000F) {
                    // 0x8XY0 sets V[X] to V[Y]
                    case 0x0000: {
                        this.V[(this.opcode & 0x0F00) >> 8] = this.V[(this.opcode & 0x00F0) >> 4];
                        this.pc += 2;
                        break;
                    }

                    // 0x8XY1 sets V[X] to V[X] OR V[Y]
                    case 0x0001: {
                        this.V[(this.opcode & 0x0F00) >> 8] |= this.V[(this.opcode & 0x00F0) >> 4];
                        this.pc += 2;
                        break;
                    }

                    // 0x8XY2 sets V[X] to V[X] AND V[Y]
                    case 0x0002: {
                        this.V[(this.opcode & 0x0F00) >> 8] &= this.V[(this.opcode & 0x00F0) >> 4];
                        this.pc += 2;
                        break;
                    }

                    // 0x8XY3 sets V[X] to V[X] XOR V[Y]
                    case 0x0003: {
                        this.V[(this.opcode & 0x0F00) >> 8] ^= this.V[(this.opcode & 0x00F0) >> 4];
                        this.pc += 2;
                        break;
                    }

                    // 0x8XY4 adds V[Y] to V[X]. V[F] is set to 1 when there's a carry, if not to 0.
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

                    // 0x8XY5 subtracts V[Y] from V[X]. V[F] is set to 1 when there's a borrow, if not to 0.
                    case 0x0005: {
                        if(this.V[(this.opcode & 0x0F00) >> 8] > (0xFF - this.V[(this.opcode & 0x00F0) >> 4])) {
                            this.V[0xF] = 1; //setting the carry
                        } else {
                            this.V[0xF] = 0;
                        }
                        this.V[(this.opcode & 0x0F00) >> 8] -= this.V[(this.opcode & 0x00F0) >> 4];
                        this.pc += 2;
                        break;
                    }

                    // 0x8XY6 Stores the least significant bit of V[X] in V[F] and then shifts V[X] to the right by 1
                    case 0x0006: {
                        this.V[0xF] = this.V[(this.opcode & 0x0F00) >> 8] & 0x1;
                        this.V[(this.opcode & 0x0F00) >> 8] >>= 1 & 0xFF;
                        this.pc += 2;
                        break;
                    }

                    // 0x8XY7 sets V[X] to V[Y] - V[X]. V[F] is set to 1 when there's a borrow, if not to 0
                    case 0x0007: {
                        if(this.V[(this.opcode & 0x0F00) >> 8] > (0xFF - this.V[(this.opcode & 0x00F0) >> 4])) {
                            this.V[0xF] = 1; //setting the carry
                        } else {
                            this.V[0xF] = 0;
                        }
                        this.V[(this.opcode & 0x0F00) >> 8] = this.V[(this.opcode & 0x00F0 >> 4)] -= this.V[(this.opcode & 0x0F00 >> 8)];
                        this.pc += 2;
                        break;
                    }

                    // 0x8YXE Stores the most significant bit of V[X] in V[F] and then shifts V[X] to the left by 1
                    case 0x000E: {
                        this.V[0xF] = (this.V[(this.opcode & 0xF00) >> 8] & 0x80) >> 7;
                        this.V[(this.opcode & 0x0F00) >> 8] <<= 1;
                        this.pc += 2;
                        break;
                    }

                    default: {
                        writefln("Unknown opcode [0x8000]: 0x%X", this.opcode);
                    }
                }
                break;
            }

            // 0x9XY0 skips next instruction when V[X] doesn't equal V[Y]
            case 0x9000: {
                if(this.V[(this.opcode & 0x0F00) >> 8] != this.V[(this.opcode & 0x00F0) >> 4]) {
                    this.pc += 4;
                } else {
                    this.pc += 2;
                }
                break;
            }
            
            // 0xANNN sets I to the Address in NNN
            case 0xA000: {
                this.I = this.opcode & 0x0FFF;
                this.pc += 2;
                break;
            }

            // 0xBNNN jumps to the address NNN + V[0]
            case 0xB000: {
                this.pc = (this.opcode & 0x0FFF) + this.V[0];
                break;
            }

            // 0xCX00 sets V[X] to NN AND random between 0 and 255
            case 0xC000: {
                immutable int r = uniform(0, 255, rnd);
                this.V[(this.opcode & 0x0F00) >> 8] = r & (this.opcode & 0x00FF);
                this.pc += 2;
                break;
            }

            // 0xDXYN draws a sprite at (V[X] , V[Y]) ...
            case 0xD000: {
                // TODO when implementing gfx
                //writeln("Draw Sprite");
                this.pc += 2;
                break;
            }

            // 0xE handels some Keyboard input but requires additional checks
            case 0xE000: {
                switch (this.opcode & 0xF0FF) {
                    // 0xEX9E skips the next instruction when the key saved in V[X] is pressed
                    case 0xE09E: {
                        // TODO when implememting keyboard...
                        writeln("Keyboard 1");
                        this.pc += 2;
                        break;
                    }

                    // 0xEXA1 skips the next instruction when the key saved in V[X] is not pressed
                    case 0xE0A1: {
                        // TODO when implememting keyboard...
                        writeln("Keyboard 2");
                        this.pc += 2;
                        break;
                    }
                    default: {
                        writefln("Unknown opcode [0xE000]: 0x%X", this.opcode);
                    }
                }
                break;
            }

            case 0xF000: {
                switch(this.opcode & 0x00FF) {
                    // 0xFX07 sets V[X] to the delayTimer
                    case 0x0007: {
                        this.V[(this.opcode & 0x0F00) >> 8] = this.delayTimer;
                        this.pc += 2;
                        break;
                    }

                    // 0xFX0A is waiting for a keypress and stores it in V[X]
                    case 0x000A: {
                        // TODO when implementing keyboard
                        writeln("Keyboard 3");
                        this.pc += 2;
                        break;
                    }

                    // 0xFX15 sets delayTimer to V[X]
                    case 0x0015: {
                        this.delayTimer = this.V[(this.opcode & 0xF00) >> 8];
                        this.pc += 2;
                        break;
                    }

                    // 0xFX18 sets the soundTimer to V[X]
                    case 0x0018: {
                        this.soundTimer = this.V[(this.opcode & 0xF00) >> 8];
                        this.pc += 2;
                        break;
                    }

                    //0xFX1E adds VX to I (V[F] is not affected)
                    case 0x001E: {
                        this.I += this.V[(this.opcode & 0xF00) >> 8];
                        this.pc += 2;
                        break;
                    }

                    //0xFX29 sets I to the location of the sprite for the character in V[X]
                    case 0x0029: {
                        // TODO when implementing gfx
                        //writeln("Set location for char");
                        this.pc += 2;
                        break;
                    }

                    // 0xFX33 stores the binary representation of V[0xN] at addresses I, I + 1 and I + 2
                    case 0x0033: {
                        this.memory[this.I] = this.V[(this.opcode & 0x0F00) >> 8] / 100;
                        this.memory[this.I + 1] = (this.V[(this.opcode & 0x0F00) >> 8] / 10) % 10;
                        this.memory[this.I + 2] = (this.V[(this.opcode & 0x0F00) >> 8] % 100) & 10;
                        this.pc += 2;
                        break;
                    }

                    // 0xFX55
                    case 0x0055: {
                        for(int i = 0; i <= ((this.opcode & 0x0F00) >> 8); i++) {
                            this.memory[I + i] = this.V[0 + i];
                        }
                        this.pc += 2;
                        break;
                    }

                    // 0xFX65
                    case 0x0065: {
                        for(int i = 0; i <= ((this.opcode & 0x0F00) >> 8); i++) {
                            this.V[0 + i] = this.memory[I + i];
                        }
                        this.pc += 2;
                        break;
                    }

                    default: {
                        writefln("Unknown opcode [0xF000]: 0x%X", this.opcode);
                    }

                }
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