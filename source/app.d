import std.stdio;
import Chip8;

void main()
{
	Chip8 myChip8 = new Chip8();

	myChip8.initialize();
	for (int i = 512; i < 4096; i++) {
		myChip8.emulateCycle();
	}
}
