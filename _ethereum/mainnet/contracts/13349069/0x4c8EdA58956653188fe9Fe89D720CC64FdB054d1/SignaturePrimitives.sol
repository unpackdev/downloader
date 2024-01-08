// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AbstractSignature.sol";

contract SignaturePrimitives is AbstractSignature {

    constructor() AbstractSignature("Signature Primitives", "signature-primitives", "Primitive solid interpretations of the minting address", "SIGP") {
        _styles[0] = "Pxls";
        _styles[1] = "Dots";
        _styles[2] = "Angles";
    }

    function _draw(uint256 styleId, ColorMetaData[] memory colors) internal view override returns(string memory) {
        string memory svg;
        if (styleId == 1) {
            svg = _pxls(colors);
        } else if (styleId == 2) {
            svg = _dots(colors);
        } else if (styleId == 3) {
            svg = _angles(colors);
        }

        return string(abi.encodePacked(_svgPrefix, svg, _svgSuffix));
    }

    function _pxls(ColorMetaData[] memory colors) internal view returns(string memory) {
        string memory result = "<symbol id=\\\"pxl\\\"><rect stroke=\\\"none\\\" width=\\\"160\\\" height=\\\"160\\\"/></symbol>";

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                result = string(abi.encodePacked(result, "<use href=\\\"%23pxl\\\" fill=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\"/>"));
            }
        }

        return result;
    }

    function _dots(ColorMetaData[] memory colors) internal view returns(string memory) {
        string memory result = "<symbol id=\\\"dot\\\"><circle stroke=\\\"none\\\" cx=\\\"80\\\" cy=\\\"80\\\" r=\\\"60\\\" width=\\\"160\\\" height=\\\"160\\\"/></symbol>";

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                result = string(abi.encodePacked(result, "<use href=\\\"%23dot\\\" fill=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\"/>"));
            }
        }

        return result;
    }

    function _angles(ColorMetaData[] memory colors) internal view returns(string memory) {
        string memory result = "<symbol id=\\\"pxl\\\"><rect stroke=\\\"none\\\" width=\\\"160\\\" height=\\\"160\\\"/></symbol><symbol id=\\\"tri\\\"><polygon stroke=\\\"none\\\" width=\\\"160\\\" height=\\\"160\\\" points=\\\"0,0 0,160 160,0\\\"/></symbol>";

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                uint shape = colors[index].decimal % 5;
                if (shape == 0) {
                    result = string(abi.encodePacked(result, "<use href=\\\"%23pxl\\\" fill=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\"/>"));
                } else {
                    if (shape == 1) {
                        result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" fill=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\" transform=\\\"rotate(90 ",_gridCentrePos[i], ",", _gridCentrePos[j],")\\\"/>"));
                    } else if (shape == 2) {
                        result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" fill=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\" transform=\\\"rotate(180 ",_gridCentrePos[i], ",", _gridCentrePos[j],")\\\"/>"));
                    } else if (shape == 3) {
                    result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" fill=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\" transform=\\\"rotate(270 ",_gridCentrePos[i], ",", _gridCentrePos[j],")\\\"/>"));
                    } else if (shape == 4) {
                    result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" fill=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\"/>"));
                    }
                }
            }
        }

        return result;
    }
}
