# Batlab: Julia-Based Chirp Processing
## Setup
1. Install [Julia](https://julialang.org/downloads/), [Jupyter Notebook](https://jupyter.org/install), and [IJulia](https://github.com/JuliaLang/IJulia.jl).
2. Clone this repository: `git@github.com:NSagan271/batlab-chirp-processing.git`. Before doing so, you will have to [add your SSH key to Github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).
3. Run `cd batlab-chirp-processing`.
4. Run `git submodule init` and `git submodule update`. This will clone the `BatlabJuliaUtils` library into a folder of the same name.
5. Install the required packages (make sure you're in the `batlab-chirp-processing` directory, AKA the root directory of this repository.
    - On the command line, type `julia`. Then, hit the `]` key.
    - Type `add Plots`, and then press Enter.
    - Do the same for using `Printf`, `MAT`, `Statistics`, `Roots`, `DataInterpolations`, and `DSP`.
    - Run `activate ./BatlabJuliaUtils`.
    -  Press Backspace to exit package mode, and CTRL+d to exit the Julia command line.
6. Go to `matlab_utils` and use `tdms_to_mat.m` to convert some bat audio TDMS files to MAT files. It is recommended you start off with `Pu166_01` and `Gr116_01`, and save the MAT files in the `batlab-chirp-processing/data` directory.
7. Copy all mic position files to `data`.
8. Make a subdirectory of `data` called `centroid` and copy all relevant centroid data files to that directory.
9. Go to `jupyter_notebooks` and run either `jupyter notebook` or `jupyter lab` from the command line. When prompted, opt to use a `Julia` kernel. The file `Walkthrough.ipynb` contains a tutorial for estimating bat vocalizations given the audio data.
   - If `jupyter lab` doesn't work, then  here are some alternatives that might work: `python3 -m jupyterlab`, `python3 -m jupyter lab`, `python3 -m notebook`.

## Documentation: Julia Code
Documentation for the `BatlabJuliaUtils` library can be found online [here](https://nsagan271.github.io/BatlabJuliaUtils/build/index.html).

## Transformer-Based Imputation and Signal Boosting
Coming soon!
