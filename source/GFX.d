module GFX;

class GFX {
    // Screen Pixels (2048 pixels => [64 * 32]) Pixel states are 0 and 1
    const ROWS = 32;
    const COLUMNS = 64;
    const GFX_MULTIPLIER = 10;
    const FPS = 60;
    byte[COLUMNS * ROWS] gfxMemory;
}