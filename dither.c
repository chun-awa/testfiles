#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#pragma pack(push, 1)
typedef struct {
    unsigned char b, g, r;
} RGB24;

typedef struct {
    unsigned char b, g, r, reserved;
} RGBQUAD;

typedef struct {
    unsigned short type;
    unsigned int size;
    unsigned short reserved1;
    unsigned short reserved2;
    unsigned int offset;
} BITMAPFILEHEADER;

typedef struct {
    unsigned int size;
    int width;
    int height;
    unsigned short planes;
    unsigned short bitCount;
    unsigned int compression;
    unsigned int sizeImage;
    int xPelsPerMeter;
    int yPelsPerMeter;
    unsigned int clrUsed;
    unsigned int clrImportant;
} BITMAPINFOHEADER;
#pragma pack(pop)

RGBQUAD palette[256];
unsigned char* color_lut = NULL;

void generate_palette() {
    for (int i = 0; i < 216; i++) {
        palette[i].r = (i / 36) * 51;
        palette[i].g = ((i % 36) / 6) * 51;
        palette[i].b = (i % 6) * 51;
    }
    for (int i = 216; i < 256; i++) {
        unsigned char gray = ((i - 216) * 255 + 19) / 39;
        palette[i].r = palette[i].g = palette[i].b = gray;
    }
}

int find_nearest_color(unsigned char r, unsigned char g, unsigned char b) {
    float min_dist = 1e9;
    int min_idx = 0;
    for (int i = 0; i < 256; i++) {
        float dr = r - palette[i].r;
        float dg = g - palette[i].g;
        float db = b - palette[i].b;
        float dist = dr*dr + dg*dg + db*db;
        if (dist < min_dist) {
            min_dist = dist;
            min_idx = i;
        }
    }
    return min_idx;
}

void build_color_lut() {
    color_lut = malloc(1 << 24);  // 16MB for 24-bit RGB
    if (!color_lut) return;

    for (int r = 0; r < 256; r++) {
        for (int g = 0; g < 256; g++) {
            for (int b = 0; b < 256; b++) {
                int idx = (r << 16) | (g << 8) | b;
                color_lut[idx] = find_nearest_color(r, g, b);
            }
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <input.bmp> <output.bmp>\n", argv[0]);
        return 1;
    }

    FILE *in = fopen(argv[1], "rb");
    if (!in) {
        perror("Error opening input file");
        return 1;
    }

    BITMAPFILEHEADER bfh;
    BITMAPINFOHEADER bih;

    if (fread(&bfh, sizeof(BITMAPFILEHEADER), 1, in) != 1) {
        perror("Error reading file header");
        fclose(in);
        return 1;
    }
    if (fread(&bih, sizeof(BITMAPINFOHEADER), 1, in) != 1) {
        perror("Error reading info header");
        fclose(in);
        return 1;
    }

    if (bfh.type != 0x4D42 || bih.bitCount != 24 || bih.compression != 0) {
        fprintf(stderr, "Unsupported BMP format. Must be 24-bit uncompressed.\n");
        fclose(in);
        return 1;
    }

    int width = bih.width;
    int height = abs(bih.height);
    int is_top_down = bih.height < 0;
    bih.height = height;

    int in_row_size = (width * 3 + 3) & ~3;
    unsigned char* in_pixels = malloc(in_row_size * height);
    if (!in_pixels) {
        perror("Memory allocation failed");
        fclose(in);
        return 1;
    }

    fseek(in, bfh.offset, SEEK_SET);
    if (fread(in_pixels, in_row_size, height, in) != height) {
        perror("Error reading pixel data");
        free(in_pixels);
        fclose(in);
        return 1;
    }
    fclose(in);

    generate_palette();
    build_color_lut();

    unsigned char* out_pixels = malloc(width * height);
    if (!out_pixels) {
        perror("Memory allocation failed");
        free(in_pixels);
        return 1;
    }

    // Allocate error buffers
    short* errors[2][3] = {0};
    for (int i = 0; i < 2; i++) {
        for (int c = 0; c < 3; c++) {
            errors[i][c] = calloc(width, sizeof(short));
            if (!errors[i][c]) {
                perror("Memory allocation failed");
                for (int j = 0; j < i; j++)
                    for (int d = 0; d < 3; d++) free(errors[j][d]);
                free(in_pixels); free(out_pixels);
                return 1;
            }
        }
    }

    int cur_error_idx = 0;
    int next_error_idx = 1;

    for (int y = 0; y < height; y++) {
        int src_y = is_top_down ? y : height - 1 - y;
        unsigned char* row = in_pixels + src_y * in_row_size;
        
        for (int x = 0; x < width; x++) {
            RGB24* pixel = (RGB24*)(row + x * sizeof(RGB24));
            int idx = y * width + x;
            
            // Get original colors with error diffusion
            int r = pixel->r + (errors[cur_error_idx][0][x] + 8) / 16;
            int g = pixel->g + (errors[cur_error_idx][1][x] + 8) / 16;
            int b = pixel->b + (errors[cur_error_idx][2][x] + 8) / 16;
            
            // Clamp to [0, 255]
            r = (r < 0) ? 0 : (r > 255) ? 255 : r;
            g = (g < 0) ? 0 : (g > 255) ? 255 : g;
            b = (b < 0) ? 0 : (b > 255) ? 255 : b;
            
            // Find nearest color using LUT or fallback
            int color_idx;
            if (color_lut) {
                color_idx = color_lut[(r << 16) | (g << 8) | b];
            } else {
                color_idx = find_nearest_color(r, g, b);
            }
            out_pixels[idx] = color_idx;
            
            // Calculate errors
            RGBQUAD pal = palette[color_idx];
            int err_r = r - pal.r;
            int err_g = g - pal.g;
            int err_b = b - pal.b;
            
            // Distribute errors using fixed-point (16x scaling)
            if (x + 1 < width) {
                errors[cur_error_idx][0][x+1] += err_r * 7;
                errors[cur_error_idx][1][x+1] += err_g * 7;
                errors[cur_error_idx][2][x+1] += err_b * 7;
            }
            
            if (y + 1 < height) {
                if (x > 0) {
                    errors[next_error_idx][0][x-1] += err_r * 3;
                    errors[next_error_idx][1][x-1] += err_g * 3;
                    errors[next_error_idx][2][x-1] += err_b * 3;
                }
                
                errors[next_error_idx][0][x] += err_r * 5;
                errors[next_error_idx][1][x] += err_g * 5;
                errors[next_error_idx][2][x] += err_b * 5;
                
                if (x + 1 < width) {
                    errors[next_error_idx][0][x+1] += err_r * 1;
                    errors[next_error_idx][1][x+1] += err_g * 1;
                    errors[next_error_idx][2][x+1] += err_b * 1;
                }
            }
        }
        
        // Clear current row errors and swap buffers
        memset(errors[cur_error_idx][0], 0, width * sizeof(short));
        memset(errors[cur_error_idx][1], 0, width * sizeof(short));
        memset(errors[cur_error_idx][2], 0, width * sizeof(short));
        
        int temp = cur_error_idx;
        cur_error_idx = next_error_idx;
        next_error_idx = temp;
    }
    
    // Free input and error buffers
    free(in_pixels);
    for (int i = 0; i < 2; i++) {
        for (int c = 0; c < 3; c++) {
            free(errors[i][c]);
        }
    }
    
    // Write output BMP
    FILE *out = fopen(argv[2], "wb");
    if (!out) {
        perror("Error opening output file");
        free(out_pixels);
        if (color_lut) free(color_lut);
        return 1;
    }

    bfh.offset = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + sizeof(palette);
    bfh.size = bfh.offset + ((width + 3) & ~3) * height;
    bih.bitCount = 8;
    bih.clrUsed = 256;
    bih.sizeImage = ((width + 3) & ~3) * height;

    fwrite(&bfh, sizeof(BITMAPFILEHEADER), 1, out);
    fwrite(&bih, sizeof(BITMAPINFOHEADER), 1, out);
    fwrite(palette, sizeof(palette), 1, out);

    int out_row_size = (width + 3) & ~3;
    for (int y = height - 1; y >= 0; y--) {
        fwrite(out_pixels + y * width, 1, width, out);
        for (int p = width; p < out_row_size; p++) {
            fputc(0, out);
        }
    }

    free(out_pixels);
    if (color_lut) free(color_lut);
    fclose(out);
    return 0;
}
