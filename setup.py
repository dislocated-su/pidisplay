from setuptools import setup
from Cython.Build import cythonize

setup(
    ext_modules = cythonize(
        module_list="src/*.pyx",
        compiler_directives={'language_level' : "3"},
        build_dir="build"
    )   
)