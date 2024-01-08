// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AbstractSignature.sol";

contract SignatureAlternates is AbstractSignature {

    string constant _svgTrianglePrefix = "<svg viewBox=\\\"-1 -1 962 962\\\" style=\\\"max-width:100vmin;max-height:100vmin;\\\" xmlns=\\\"http://www.w3.org/2000/svg\\\">";

    constructor() AbstractSignature("Signature Alternates", "signature-alternates", "Alternate interpretations of the minting address", "SIGA") {
        _styles[0] = "Terrazzo";
        _styles[1] = "Bubbles";
        _styles[2] = "Edges";
    }

    function _draw(uint256 styleId, ColorMetaData[] memory colors) internal view override returns(string memory) {
        string memory svg;
        if (styleId == 1) {
            svg = _terrazzo(colors);
        } else if (styleId == 2) {
            svg = _bubbles(colors);
        } else if (styleId == 3) {
            svg = _edges(colors);
        }

        return string(abi.encodePacked(styleId == 3 ? _svgTrianglePrefix : _svgPrefix, svg, _svgSuffix));
    }

    function _terrazzo(ColorMetaData[] memory colors) internal pure returns(string memory) {
        string memory result;

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                uint256 posX = _gridSize * i;
                uint256 posY = _gridSize * j;
                bytes memory color = colors[index].color;
                uint decimalColor = colors[index].decimal;
                uint256[8] memory offsets;
                uint mask = 0xFFFF;
                for (uint p=0;p<8;p++) {
                    uint c = (decimalColor >> 1 * p) & mask;
                    offsets[p] = 55 * _gridSize * c / 6553500;
                }

                string memory points = string(abi.encodePacked(_uintToString(posX + offsets[0]), ",", _uintToString(posY + offsets[1]), " ", _uintToString(posX + _gridSize - offsets[2]), ",", _uintToString(posY + offsets[3]), " ", _uintToString(posX + _gridSize - offsets[4]), ",", _uintToString(posY + _gridSize - offsets[5]), " ", _uintToString(posX + offsets[6]), ",", _uintToString(posY + _gridSize - offsets[7])));
                string memory rand = _uintToString(360 * decimalColor / 16777215);
                string memory g = string(abi.encodePacked("<g transform=\\\"rotate(", rand, " ", _uintToString(posX + (5 * _gridSize / 10)), " ", _uintToString(posY + (5 * _gridSize) / 10), "\\\">"));

                result = string(abi.encodePacked(result, g, "<polygon points=\\\"", points, "\\\" fill=\\\"%23", color, "\\\" /></g>"));
            }
        }

        return result;
    }

    function _bubbles(ColorMetaData[] memory colors) internal pure returns(string memory) {
        string memory result;

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                string memory r = _uintToString(colors[index].decimal * _gridSize / 16777215);
                result = string(abi.encodePacked(result, "<circle fill=\\\"%23", colors[index].color, "A0\\\" cx=\\\"", _uintToString(_gridSize * (10 * i + 5) / 10),"\\\" cy=\\\"", _uintToString(_gridSize * (10 * j + 5) / 10), "\\\" r=\\\"", r, "\\\"/>"));
            }
        }

        return result;
    }

    function _edges(ColorMetaData[] memory colors) internal view returns(string memory) {
        string memory result = "<symbol id=\\\"pxl\\\" viewPort=\\\"0 0 160 160\\\" overflow=\\\"visible\\\" style=\\\"overflow: visible;\\\"><rect stroke-width=\\\"2\\\" fill=\\\"none\\\" width=\\\"160\\\" height=\\\"160\\\"/></symbol><symbol id=\\\"tri\\\" viewPort=\\\"0 0 160 160\\\" overflow=\\\"visible\\\" style=\\\"overflow: visible;\\\"><polygon stroke-width=\\\"2\\\" fill=\\\"none\\\" width=\\\"160\\\" height=\\\"160\\\" points=\\\"0,0 0,160 160,0\\\"/></symbol>";

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                uint shape = colors[index].decimal % 5;
                if (shape == 0) {
                    result = string(abi.encodePacked(result, "<use href=\\\"%23pxl\\\" stroke=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\"/>"));
                } else {
                    if (shape == 1) {
                        result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" stroke=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\" transform=\\\"rotate(90 ",_gridCentrePos[i], ",", _gridCentrePos[j],")\\\"/>"));
                    } else if (shape == 2) {
                    result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" stroke=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\" transform=\\\"rotate(180 ",_gridCentrePos[i], ",", _gridCentrePos[j],")\\\"/>"));
                    } else if (shape == 3) {
                    result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" stroke=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\" transform=\\\"rotate(270 ",_gridCentrePos[i], ",", _gridCentrePos[j],")\\\"/>"));
                    } else if (shape == 4) {
                    result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" stroke=\\\"%23", colors[index].color ,"\\\" x=\\\"", _gridPos[i], "\\\" y=\\\"", _gridPos[j],"\\\"/>"));
                    }
                }
            }
        }

        return result;
    }
}
