import sys
import re
from PIL import Image
from numpy import asarray

# Read argument (image file name)
if len(sys.argv) != 2:
    print("Usage: python script.py <image_file>")
    sys.exit(1)

image_file = sys.argv[1]

# Open image
image = Image.open(image_file)

# Resize image to 48x48 pixels using LANCZOS resampling
image = image.resize((64, 64), Image.Resampling.LANCZOS)

# Convert image to array
# The array shape is [width x height x 4]
# These 4 arrays are: red, green, blue, and intensity
array = asarray(image)

# Check if the image is RGB or black & white
is_rgb = len(array.shape) > 2

if is_rgb:
    r = array[:, :, 0]
    g = array[:, :, 1]
    b = array[:, :, 2]
else:
    r = array
    g = array
    b = array

# Prepare output file
output_file_name = re.sub('.[a-zA-Z0-9]*$', '.data', image_file)
output_file = open(output_file_name, 'w')
# output_file.write("// image rom content of: " + str(image_file) + "\n")
# output_file.write("// WIDTH = 48\n")
# output_file.write("// HEIGHT = 48\n")

# For each pixel, convert color number to HEX and take only the 0'th element (4 bits)
for h in range(64):
    for w in range(64):
        pixel = '{:X}'.format(r[h, w])[0] + '{:X}'.format(g[h, w])[0] + '{:X}'.format(b[h, w])[0]
        output_file.write(pixel + "\n")

output_file.close()
