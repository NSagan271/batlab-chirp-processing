# Batlab: Julia-Based Chirp Processing
## Setup
1. Install [Julia](https://julialang.org/downloads/), [Jupyter Notebook](https://jupyter.org/install), and [IJulia](https://github.com/JuliaLang/IJulia.jl).
2. Run `git submodule init` and `git submodule update`. This will clone the `BatlabJuliaUtils` library into a folder of the same name.
3. Install the required packages (make sure you're in the `batlab-chirp-processing` directory, AKA the root directory of this repository.
   a. On the command line, type `julia`. Then, hit the `]` key.
   b. Type `add Plots`, and then press Enter.
   c. Do the same for using `Printf`, `MAT`, `Statistics`, `Roots`, `DataInterpolations`, and `DSP`.
   d. Run `activate ./BatlabJuliaUtils`.
   e. Press Backspace to exit package mode, and CTRL+d to exit the Julia command line.
5. Go to `matlab_utils` and use `tdms_to_mat.m` to convert some bat audio TDMS files to MAT files. It is recommended you start off with `Pu166_01` and `Gr116_01`, and save the MAT files in the `data` directory.
6. Copy all mic position files to `data`.
7. Make a subdirectory of `data` called `centroid` and copy all relevant centroid data files to that directory.
8. Go to `jupyter notebooks` and run either `jupyter notebook` or `jupyter lab` from the command line. If prompted, opt to use a `Julia` kernel. The file `Walkthrough.ipynb` contains a tutorial for estimating bat vocalizations given the audio data.

## Documentation: Julia Code
Documentation for the `BatlabJuliaUtils` library can be found online [here](https://nsagan271.github.io/BatlabJuliaUtils/build/index.html).

## Transformer-Based Imputation and Signal Boosting
Coming soon!
