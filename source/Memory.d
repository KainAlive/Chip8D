module Memory;

import std.path;
import std.stdio : writefln, File;

class Memory {
    // Memory (4K)
    char[4096] memory;

    // Stack and stackpointer are used to store the program counter in case of a jump
    short[16] stack;
    short sp;

    void loadRom(string romName) {
        // Useable memory begins at 0x200 (512)
        // I have to look into try / catch a bit more....
        try {
            File ROM = File(romName, "r");
            char[] buffer = ROM.rawRead(new char[ROM.size()]);
            ROM.close();
            const bufferSize = buffer.length;
            for(int i = 0; i < bufferSize; i++) {
                this.memory[i + 512] = buffer[i];
            }
        } catch(Error e) {
            writefln("Could find file to read...");
        }
    }
}