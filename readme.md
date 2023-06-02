# NXG Converter

The NXG Converter is a batch converter that transforms `NXG` format files *(ANSI encoded text)* into `TIFF` format. It is designed to work with files within a single folder.

## How to Use

### Converting NXG to TIFF

1. Download and install the NXG Converter from the provided [installer]().
   
   > The initial installation might take some time as it requires the installation of `MATLAB runtime`.

2. Double-click the program icon to run the converter. Wait for the program to respond and then select the folder containing the NXG files you want to convert.
   
   > The converter does not process any file in subfolders.

### Importing Data into MATLAB Workspace

To import data into the MATLAB workspace, refer to [`func/readnxg.m`](https://github.com/ZhengyiZ/NXG_Converter/blob/main/func/readnxg.m) for detailed instructions. 
Alternatively, you can download [`readnxg.m`]() from the release.

## Environment

The NXG Converter is developed and tested on `Windows 11` using `MATLAB R2023a`.
It does not have any dependencies on additional MATLAB toolkits.

## License

This project is released under the [GPL-3.0 License](https://github.com/ZhengyiZ/NXG_Converter/blob/main/LICENSE). Please see the [`LICENSE`](https://github.com/ZhengyiZ/NXG_Converter/blob/main/LICENSE) file for more information.

## Reference

The NXG Converter utilizes the `Timerwaitbar` tool developed by *Eric Ogier*.
You can find more information about this tool on the [MATLAB Central File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/55985-timer-waitbar).
