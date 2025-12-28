#include <stdio.h>
#include <stdlib.h>

#pragma pack(push, 1)
typedef struct {
    char bfType[2];
    unsigned int bfSize;
    unsigned short bfReserved1;
    unsigned short bfReserved2;
    unsigned int bfOffBits;
} BMPFileHeader;

typedef struct {
    unsigned int biSize;
    int biWidth;
    int biHeight;
    unsigned short biPlanes;
    unsigned short biBitCount;
    unsigned int biCompression;
    unsigned int biSizeImage;
} BMPInfoHeader;
#pragma pack(pop)

extern int find_markers(unsigned char *bitmap, unsigned int *x_pos, unsigned int* y_pos);

int main(void) {
    FILE *file = fopen("test.bmp", "rb");
    if (!file) {
        printf("Error while opening the file!\n");
        return 1;
    }

    fseek(file, 0, SEEK_END);
    long fileSize = ftell(file);
    rewind(file);

    unsigned char *bitmap = malloc(fileSize);
    if (!bitmap) {
        printf("Failed to allocate memory for full BMP file.\n");
        fclose(file);
        return 1;
    }
    fread(bitmap, 1, fileSize, file);

    BMPFileHeader *fh = (BMPFileHeader *)bitmap;
    BMPInfoHeader *ih = (BMPInfoHeader *)(bitmap + sizeof(BMPFileHeader));

    //printf("Width: %d, Height: %d, Bits per pixel: %d\n", ih->biWidth, ih->biHeight, ih->biBitCount);

    unsigned int *x_pos = malloc(50 * sizeof(unsigned int));
    unsigned int *y_pos = malloc(50 * sizeof(unsigned int));

    if (!x_pos || !y_pos) {
        printf("Failed to allocate memory for marker positions.\n");
        free(bitmap);
        if (x_pos) free(x_pos);
        if (y_pos) free(y_pos);
        fclose(file);
        return 1;
    }


    //printf("sizeof(&bitmap) = %zu\n", sizeof(&bitmap));
    //printf("Address of bitmap in main: %p\n", (void *)bitmap);

    //int pixel_offset = bitmap[10] | (bitmap[11]<<8) | (bitmap[12]<<16) | (bitmap[13]<<24);
    //printf("Pixel data offset: %d (0x%X)\n", pixel_offset, pixel_offset);


    // ------TESTING THE FUNCTION-----------//

    //printf("Pointer to the X_POS %p \n", (void*)x_pos);
    //printf("Pointer to the Y_POS %p \n", (void*)y_pos);

    int markers_num;
    markers_num = find_markers(bitmap, x_pos, y_pos);
    printf("Program found %d markers\n", markers_num);
    for(int i=0; i<markers_num; i++){
        printf("Coordinates of the marker %d: (%d,%d)\n", (i+1), x_pos[i], y_pos[i]);
    }


    free(bitmap);
    free(x_pos);
    free(y_pos);
    fclose(file);
    return 0;
}