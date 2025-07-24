import PIL.Image
import sys
import argparse

TILE_WIDTH = 8
TILE_HEIGHT = 8


def ascii_to_verilog(image_path, output_path):
    # Load image and convert to 1bit bmp
    image = PIL.Image.open(image_path)
    image = image.convert("1")
    texture_type = "fill" if "fill" in image_path else "edge"

    # Then output as verilog array
    array_text = f"logic [TILE_WIDTH-1:0][TILE_HEIGHT-1:0] texture_data_{texture_type} [ASCII_LEVELS-1:0] = '{{\n"
    curr_character = 0
    while curr_character * TILE_WIDTH < image.width:
        array_text += f"    '{{\n"  # Open character
        for y in range(TILE_HEIGHT):
            array_text += "        '{"
            array_text += ", ".join(str(image.getpixel((curr_character * TILE_WIDTH + x, y))) for x in range(TILE_WIDTH))
            array_text += "}"
            if y < TILE_HEIGHT - 1:
                array_text += ",\n"
            else:
                array_text += "\n"
        array_text += "    }"
        if (curr_character+1) * TILE_WIDTH < image.width:
            array_text += f", // Character {curr_character}\n"
        else:
            array_text += f"  // Character {curr_character}\n"
        curr_character += 1
        
    array_text += "};\n"
    
    with open(output_path, "w") as f:
        f.write(array_text)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--image_paths", type=str, nargs="+") 
    parser.add_argument("--output_paths", type=str, nargs="+")
    args = parser.parse_args()
    for image_path, output_path in zip(args.image_paths, args.output_paths):
        ascii_to_verilog(image_path, output_path)
