from setuptools import setup
from Cython.Build import cythonize
import numpy
setup(
    ext_modules = cythonize(
        module_list="src/*.pyx",
        compiler_directives={'language_level' : "3"})
)