import sys
from PIL import Image

# Usage: python image_to_header.py <input_image>
if len(sys.argv) != 2:
    print("Usage: python image_to_header.py <input_image>")
    sys.exit(1)

input_image = sys.argv[1]

# Open and resize image to 640x480
image = Image.open(input_image)
image = image.resize((640, 480))
image = image.convert("RGB")

pixels = list(image.getdata())  # List of (R, G, B) tuples

with open("obj_dir/image_data.h", "w") as f:
    f.write("const uint32_t image_data[640*480] = {\n")
    for i, (r, g, b) in enumerate(pixels):
        value = (0xFF << 24) | (r << 16) | (g << 8) | b
        if i < len(pixels) - 1:
            f.write(f"0x{value:08x}, ")
        else:
            f.write(f"0x{value:08x}")
        if (i + 1) % 8 == 0:
            f.write("\n")
    f.write("\n};\n")