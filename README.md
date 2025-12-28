# Purpose

This project detects marker of **type 3** in a 24-bit BMP image using a **hybrid C + x86 assembly (32-bit) implementation**.  
The C code handles file input, memory allocation, and output, while the assembly code fully interprets the BMP format and performs marker detection.

The program outputs the coordinates of all detected markers using a **top-left–origin coordinate system**.

# Overview

- **Marker detection logic** implemented in Intel x86 (32-bit) assembly  
- **BMP parsing and image interpretation** done entirely in assembly  
- **Supports** 24-bit, uncompressed BMP images  
- **Fixed image size:** 240 × 240 pixels  
