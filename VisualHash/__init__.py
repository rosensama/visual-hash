#!/usr/bin/python2

"""
Create a visual hash of a string.

VisualHash is a package that includes several functions to create a
visual hash of an arbitrary string.  Each function implements a
distinct algorithm that given a random number generator produces a
visual image.  The cryptographic strength of the hash relies on using
a cryptographically strong random number generator that is seeded by
the data to be hashed.

We provide a strong random number generator (called StrongRandom),
which is based on taking the SHA512 hash of the data, followed by the
SHA512 hash of the hash, and so on.  This puts an upper bound of 512
bits of entropy on any of our hashes (which should not be a problem).

We also provide a "tweaked" random number generator TweakedRandom,
which gives a slight variation on a specific strong random number
sequence.  This will enable us to test the effect of small changes in
the generated hashes.

The visual hash styles supported are:

- Fractal
- Flag
- T-Flag
- RandomArt
- Identicon
"""

from PIL import Image

try:
    import pyximport; pyximport.install()
except:
    print '****** There does not seem to be cython available!!! *******'

from VisualHashPrivate import identicon
from VisualHashPrivate import randomart
from VisualHashPrivate.Color import DistinctColor
from VisualHashPrivate import FractalTransform
try:
    from VisualHashPrivate import OptimizedFractalTransform
except:
    import VisualHashPrivate.FractalTransform as OptimizedFractalTransform
    print '****** Fractals will be very slow!!! *******'

from VisualHash import random

# annoying imports to enable "random" duplication without strange
# __init__ error.
from math import sqrt, log, exp, sin, cos, pi

import random, struct
from Crypto.Hash import SHA512 as _hash

def StrongRandom(x):
    return random.StrongRandom(x)

def TweakedRandom(x, string, fraction, seed1, seed2):
    return random.TweakedRandom(x, string, fraction, seed1, seed2)

def Fractal(random = StrongRandom(""), size = 128):
    """
    Create a hash as a fractal flame.

    Given a random generator (and optionally a size in pixels) return a PIL
    Image that is a hash generated by the random generator.
    """
    return FractalTransform.Image(random, size)

def OptimizedFractal(random = StrongRandom(""), size = 128):
    """
    Create a hash as a fractal flame.

    Given a random generator (and optionally a size in pixels) return a PIL
    Image that is a hash generated by the random generator.
    """
    return OptimizedFractalTransform.Image(random, size)

def Flag(random = StrongRandom(""), size = 128):
    """
    Create a hash using the "flag" algorithm.

    Given a random generator (and optionally a size in pixels) return a PIL
    Image that is a hash generated by the random generator.
    """
    img = Image.new( 'RGBA', (size,size), "black") # create a new black image
    pixels = img.load() # create the pixel map
    ncolors = 4
    r = [0]*ncolors
    g = [0]*ncolors
    b = [0]*ncolors
    for i in range(ncolors):
        r[i], g[i], b[i] = DistinctColor(random)
    for i in range(img.size[0]):    # for every pixel:
        for j in range(img.size[1]):
            n = (i*ncolors) // img.size[0]
            pixels[i,j] = (r[n], g[n], b[n], 255) # set the colour accordingly
    return img

def TFlag(random = StrongRandom(""), size = 128):
    """
    Create a hash using the "flag" algorithm.

    Given a random generator (and optionally a size in pixels) return a PIL
    Image that is a a hash generated by the random generator.
    """
    img = Image.new( 'RGBA', (size,size), "black") # create a new black image
    pixels = img.load() # create the pixel map
    ncolors = 16
    r = [0]*ncolors
    g = [0]*ncolors
    b = [0]*ncolors
    for i in range(ncolors):
        r[i], g[i], b[i] = DistinctColor(random)
    for i in range(img.size[0]):    # for every pixel:
        for j in range(img.size[1]):
            nx = (2*i) // img.size[0]
            ny = (j*ncolors//4) // img.size[1]
            n = nx+2*ny
            pixels[i,j] = (r[n], g[n], b[n], 255) # set the colour accordingly
    return img

def Identicon(random = StrongRandom(""), size = 128):
    """
    Create an identicon hash.

    Given a random generator (and optionally a size in pixels) return
    a PIL Image that is a hash generated by the random generator.
    This hash has only 32 bits in it, so it is not a strong hash.
    """
    code = 0
    for i in range(32):
        if random.random() < 0.5:
            code += 1 << i
    img = identicon.render_identicon(code, int(size/3))
    return img

def RandomArt(random = StrongRandom(""), size = 128):
    """
    Create a hash using the randomart algorithm.

    Given a random generator (and optionally a size in pixels) return a PIL
    Image that is a hash generated by the random generator.
    """
    img = randomart.Create(random, size)
    return img
