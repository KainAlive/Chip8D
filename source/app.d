import std.stdio;
import Chip8;

void main()
{
	Chip8 myChip8 = new Chip8();

	myChip8.initialize();
	myChip8.emulateCycle();
}
