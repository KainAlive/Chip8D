module Data;

import std.random : uniform, Random;

class Data {
    // Maps the input (int) to the key map
    short[16] keyMap = [
                        120, 49, 50, 51,        //"x", "1", "2", "3",
                        113, 119, 101, 97,       //"q", "w", "e", "a",
                        115, 100, 121, 99,      //"s", "d", "y", "c",
                        52, 114, 102, 118       //"4", "r", "f", "v"
                        ]; 

    // Random number generator
    auto rnd = Random(42);

    // Characters are stored as hex representation
    char[] hexChars = [
        0xF0, 0x90, 0x90, 0x90, 0xF0,   // 0
        0x20, 0x60, 0x20, 0x20, 0x70,   // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0,   // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0,   // 3
        0x90, 0x90, 0xF0, 0x10, 0x10,   // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0,   // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0,   // 6
        0xF0, 0x10, 0x20, 0x40, 0x40,   // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0,   // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0,   // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90,   // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0,   // B
        0xF0, 0x80, 0x80, 0x80, 0xF0,   // C
        0xE0, 0x90, 0x90, 0x90, 0xE0,   // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0,   // E
        0xF0, 0x80, 0xF0, 0x80, 0x80    // F
    ];

    int getRandomData() {
        return uniform(0, 255, rnd);
    }

}