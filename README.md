Generate JSON files of parameters from FluCoMa fluid_decomposition objects.

This is quick and dirty, so don't be surprised at weirdness.

The JSON will turn up in a folder called `json` in the top level directory, and is generated as part of compilation (by CMake).

So, simple build steps should be along the lines of
```bash
mkdir build
cd build
cmake -DFLUID_PATH=/your/path/to/your/fluid/decompostion/repo ..
make
```

> This project has received funding from the European Research Council (ERC) under the European Union’s Horizon 2020 research and innovation programme (grant agreement No 725899).
