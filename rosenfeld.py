USER = "JobuSaurus@closedform.com"

import VisualHash as VH

vh_random = VH.StrongRandom(USER)
# fractal = VH.Fractal(vh_random)
# fractal.save("js_fractal.png", "PNG")

# flag = VH.Flag(vh_random)
# flag.save("js_flag.png", "PNG")

identicon = VH.Identicon(vh_random, 200)
identicon.save("js_identicon.png", "PNG")

# opt_fractal = VH.OptimizedFractal(vh_random)
# opt_fractal.save("js_opt_fractal.png", "PNG")

# random_art = VH.RandomArt(vh_random)
# random_art.save("js_random_art.png", "PNG")

import pydenticon

# Set-up a list of foreground colours (taken from Sigil).
foreground = [ "rgb(45,79,255)",
               "rgb(254,180,44)",
               "rgb(226,121,234)",
               "rgb(30,179,253)",
               "rgb(232,77,65)",
               "rgb(49,203,115)",
               "rgb(141,69,170)" ]

# Set-up a background colour (taken from Sigil).
background = "rgba(224,224,224,0)"

# Set-up the padding (top, bottom, left, right) in pixels.
padding = (20, 20, 20, 20)

# Instantiate a generator that will create 5x5 block identicons using SHA1
# digest.
generator = pydenticon.Generator(10, 10, foreground=foreground, background=background)

identicon = generator.generate(USER, 200, 200, padding=padding, output_format="png")

filename = "js_pydenticon.png"
with open(filename, mode="wb") as f:
    f.write(identicon)
