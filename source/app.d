import std;
import Chip8;
import raylib;

void main()
{
	InitWindow(800, 600, "Hello Raylib");
	while (!WindowShouldClose()) {
		BeginDrawing();
		ClearBackground(Colors.WHITE);
		DrawText("Hello, World", 400, 300, 28, Colors.BLACK);
		EndDrawing();
	}
	CloseWindow();

	Chip8 myChip8 = new Chip8();

	myChip8.initialize();
	while(true) {
		myChip8.emulateCycle();
	}
}
