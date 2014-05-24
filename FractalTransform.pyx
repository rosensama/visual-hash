#cython: nonecheck=True
#        ^^^ Turns on nonecheck globally

import random

from libc.stdlib cimport rand
from libc.math cimport log, sqrt, cos, sin
from cython cimport view

import numpy as np
cimport numpy as np
# We now need to fix a datatype for our arrays. I've used the variable
# DTYPE for this, which is assigned to the usual NumPy runtime
# type info object.
DTYPE = np.double
# "ctypedef" assigns a corresponding compile-time type to DTYPE_t. For
# every type in the numpy module there's a corresponding compile-time
# type with a _t-suffix.
ctypedef np.double_t DTYPE_t

cdef class Point:
    cdef public double x, y, R, G, B, A
    def __cinit__(self, x, y):
        self.x = x
        self.y = y
        self.A = 0
        self.R = 0
        self.G = 0
        self.B = 0
    def __str__(self):
        return str((self.x, self.y)) + ' color ' + str((self.R, self.G, self.B, self.A))
    cpdef Point add(self, Point p):
        return Point(self.x + p.x, self.y + p.y)
    def __add__(self, p):
        return self.add(p)
    cpdef iadd(self, Point p):
        self.x += p.x
        self.y += p.y
    def __iadd__(self, p):
        self.iadd(p)
    cpdef Point sub(self, Point p):
        return Point(self.x - p.x, self.y - p.y)
    def __sub__(self, p):
        return self.sub(p)
    cpdef isub(self, Point p):
        self.x -= p.x
        self.y -= p.y
    def __isub__(self, p):
        self.isub(p)

cdef class Transform:
    cpdef Point transform(self, Point p):
        return Point(0, 0)
    cdef double R, G, B, A
    def __call__(self, p):
        return self.transform(p)
    def __cinit__(self):
        self.A = 1
        self.R = random.uniform(0,1)
        self.G = random.uniform(0,1)
        self.B = random.uniform(0,1)
        cdef double m = self.R
        if self.G > m:
            m = self.G
        if self.B > m:
            m = self.B
        self.R /= m
        self.G /= m
        self.B /= m
    cpdef Point colortransform(self, Point p):
        p.R = (self.A*self.R + p.A*p.R)/(self.A + p.A)
        p.G = (self.A*self.G + p.A*p.G)/(self.A + p.A)
        p.B = (self.A*self.B + p.A*p.B)/(self.A + p.A)
        p.A = (self.A+p.A)/2
        return p

cdef Root(double x):
   if x < 0:
       return -sqrt(-x)
   return sqrt(x)

cdef class Affine(Transform):
    cdef public double Mxx, Mxy, Myx, Myy, Ox, Oy
    cdef public Point O
    def __cinit__(self):
        # currently we always initialize pseudorandomly, but
        # eventually we'll want to generate this deterministically.
        cdef double theta = random.uniform(0, 2*np.pi)
        rot = np.matrix([[cos(theta), sin(theta)],
                         [-sin(theta),cos(theta)]])
        cdef double compressme = random.gauss(0.7, 0.2)
        print compressme
        compress = np.matrix([[compressme, 0],
                              [0, compressme]])
        mat = compress*rot
        self.Mxx = mat[0,0]
        self.Mxy = mat[0,1]
        self.Myx = mat[1,0]
        self.Myy = mat[1,1]
        #print mat
        #cdef double scale = Root(self.Mxx*self.Myy - self.Mxy*self.Myx)
        cdef double translation_scale = 0.8
        self.Ox = random.gauss(0, translation_scale)
        self.Oy = random.gauss(0, translation_scale)
    cpdef Point transform(self, Point p):
        cdef Point out = self.colortransform(p)
        p.x -= self.Ox
        p.y -= self.Oy
        out.x = p.x*self.Mxx + p.y*self.Mxy # + self.Ox
        out.y = p.x*self.Myx + p.y*self.Myy # + self.Oy
        #p.x += self.Ox
        #p.y += self.Oy
        return out
    def __str__(self):
        return 'M='+str(((self.Mxx, self.Mxy), (self.Myx, self.Myy))) + ' O='+str(self.O) + ' C=%g, %g, %g, %g' % (self.R, self.G, self.B, self.A)

cdef int Ntransform = 5
class Multiple(Transform):
    def __init__(self):
        self.t = [1]*Ntransform
        for i in xrange(Ntransform):
            self.t[i] = Affine()
    def transform(self, p):
        return self.t[rand() % Ntransform].transform(p)

cdef class CMultiple(Transform):
    cdef Transform a, b, c, d, e, f, g, h, i, j
    def __init__(self):
        self.a = Affine()
        self.b = Affine()
        self.c = Affine()
        self.d = Affine()
        self.e = Affine()
        self.f = Affine()
        self.g = Affine()
        self.h = Affine()
        self.i = Affine()
        self.j = Affine()
    cpdef Point transform(self, Point p):
        cdef int n = rand() % Ntransform
        if n == 1:
            return self.b.transform(p)
        elif n == 2:
            return self.c.transform(p)
        elif n == 3:
            return self.d.transform(p)
        elif n == 4:
            return self.e.transform(p)
        elif n == 5:
            return self.f.transform(p)
        elif n == 6:
            return self.g.transform(p)
        elif n == 7:
            return self.h.transform(p)
        elif n == 8:
            return self.i.transform(p)
        elif n == 9:
            return self.j.transform(p)
        return self.a.transform(p)

cdef place_point(np.ndarray[DTYPE_t, ndim=3] h, Point p):
    cdef int ix = <int>((p.x+1)/2*h.shape[1])
    cdef int iy = <int>((p.y+1)/2*h.shape[2])
    h[0, ix % h.shape[1], iy % h.shape[2]] += p.A
    h[1, ix % h.shape[1], iy % h.shape[2]] += p.R
    h[2, ix % h.shape[1], iy % h.shape[2]] += p.G
    h[3, ix % h.shape[1], iy % h.shape[2]] += p.B

cpdef np.ndarray[DTYPE_t, ndim=3] Simulate(Transform t, Point p,
                                           int nx, int ny):
    cdef np.ndarray[DTYPE_t, ndim=3] h = np.zeros([4, nx,ny], dtype=DTYPE)
    for i in xrange(100*nx*ny):
        place_point(h, p)
        p = t.transform(p)
    return h

cpdef np.ndarray[DTYPE_t, ndim=3] get_colors(np.ndarray[DTYPE_t, ndim=3] h):
    cdef np.ndarray[DTYPE_t, ndim=3] img = np.zeros([3, h.shape[1], h.shape[2]], dtype=DTYPE)
    cdef DTYPE_t maxa = 0
    cdef DTYPE_t mean_nonzero_a = 0
    cdef int num_nonzero = 0
    cdef DTYPE_t mina = 1e300
    for i in xrange(h.shape[1]):
        for j in xrange(h.shape[2]):
            if h[0,i,j] > maxa:
                maxa = h[0,i,j]
            if h[0,i,j] > 0 and h[0,i,j] < mina:
                mina = h[0,i,j]
            if h[0,i,j] > 0:
                mean_nonzero_a += h[0,i,j]
                num_nonzero += 1
    mean_nonzero_a /= num_nonzero
    cdef double factor = maxa/(mean_nonzero_a*mean_nonzero_a)
    cdef double norm = 1.0/log(factor*maxa)
    cdef double a
    for i in xrange(h.shape[1]):
        for j in xrange(h.shape[2]):
            if h[0,i,j] > 0:
                a = norm*log(factor*h[0,i,j]);
                img[0,i,j] = h[1,i,j]/h[0,i,j]*a
                img[1,i,j] = h[2,i,j]/h[0,i,j]*a
                img[2,i,j] = h[3,i,j]/h[0,i,j]*a
    return img
