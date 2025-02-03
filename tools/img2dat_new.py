import sys
import re
from PIL import Image
from numpy import asarray

# Read the input image file name from command-line arguments
image_file = sys.argv[1]

# Open the image
image = Image.open(image_file)

# Force resize to 48x64
# (width=48, height=64). Use LANCZOS for higher-quality resizing.
image = image.resize((48, 64), Image.LANCZOS)

# Convert image to array
array = asarray(image)
# Check if the image is rgb or grayscale
is_rgb = (len(array.shape) > 2)

# If RGB, separate channels; if grayscale, all channels are the same
if is_rgb:
    r = array[:, :, 0]
    g = array[:, :, 1]
    b = array[:, :, 2]
else:
    r = array
    g = array
    b = array

# Prepare output file name by replacing any existing extension with ".dat"
output_file_name = re.sub(r'\.[^.]+$', '.dat', image_file)

with open(output_file_name, 'w') as output_file:
    # Write header comments
    output_file.write("// image rom content of: " + str(image_file) + "\n")
    output_file.write("// FORCED WIDTH = 48\n")
    output_file.write("// FORCED HEIGHT = 64\n\n")

    # For each pixel, convert color number to HEX and take only the 0th element (4 bits)
    for h in range(64):      # height = 64
        for w in range(48):  # width = 48
            # Convert each channel to hex, take the first nibble (first hex digit)
            pixel = (
                '{:X}'.format(r[h, w])[0] +
                '{:X}'.format(g[h, w])[0] +
                '{:X}'.format(b[h, w])[0]
            )
            output_file.write(pixel + "\n")

print(f"Saved resized image data (48x64) to {output_file_name}")
