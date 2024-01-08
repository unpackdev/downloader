// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AbstractSignature.sol";

contract SignatureLineations is AbstractSignature {

    constructor() AbstractSignature("Signature Lineations", "signature-lineations", "Lineated interpretations of the minting address", "SIGL") {
        _styles[0] = "Pathways";
        _styles[1] = "Hatchings";
        _styles[2] = "Shutters";
    }

    function _draw(uint256 styleId, ColorMetaData[] memory colors) internal view override returns(string memory) {
        string memory svg;
        if (styleId == 1) {
            svg = _pathways(colors);
        } else if (styleId == 2) {
            svg = _hatchings(colors);
        } else if (styleId == 3) {
            svg = _shutters(colors);
        }

        return string(abi.encodePacked(_svgPrefix, svg, _svgSuffix));
    }

    function _pathways(ColorMetaData[] memory colors) internal view returns(string memory) {
        string memory result = "<symbol id=\\\"lines\\\" viewPort=\\\"0 0 160 160\\\"><line x1=\\\"0\\\" y1=\\\"35\\\" x2=\\\"35\\\" y2=\\\"0\\\" stroke-width=\\\"4\\\"/><line x1=\\\"0\\\" y1=\\\"65\\\" x2=\\\"65\\\" y2=\\\"0\\\" stroke-width=\\\"4\\\"/><line x1=\\\"0\\\" y1=\\\"95\\\" x2=\\\"95\\\" y2=\\\"0\\\" stroke-width=\\\"4\\\"/><line x1=\\\"0\\\" y1=\\\"125\\\" x2=\\\"125\\\" y2=\\\"0\\\" stroke-width=\\\"4\\\"/><line x1=\\\"35\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"35\\\" stroke-width=\\\"4\\\"/><line x1=\\\"65\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"65\\\" stroke-width=\\\"4\\\"/><line x1=\\\"95\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"95\\\" stroke-width=\\\"4\\\"/><line x1=\\\"125\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"125\\\" stroke-width=\\\"4\\\"/></symbol>";

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                string memory rotation = _uintToString(90 * (colors[index].decimal % 2));
                result = string(abi.encodePacked(result, "<use href=\\\"%23lines\\\" stroke=\\\"%23", colors[index].color, "\\\" transform=\\\"rotate(", rotation, " ", _gridCentrePos[i], " ", _gridCentrePos[j], ")\\\" x=\\\"", _gridPos[i],"\\\" y=\\\"", _gridPos[j],"\\\"/>"));
            }
        }

        return result;
    }

    function _hatchings(ColorMetaData[] memory colors) internal view returns(string memory) {
        string memory result = "<symbol id=\\\"tri\\\" viewPort=\\\"0 0 160 160\\\"><line x1=\\\"10\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"10\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.96;\\\"/><line x1=\\\"30\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"30\\\" stroke-width=\\\"4\\\" /><line x1=\\\"50\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"50\\\" stroke-width=\\\"4\\\" /><line x1=\\\"70\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"70\\\" stroke-width=\\\"4\\\" /><line x1=\\\"90\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"90\\\" stroke-width=\\\"4\\\" /><line x1=\\\"110\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"110\\\" stroke-width=\\\"4\\\" /><line x1=\\\"130\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"130\\\" stroke-width=\\\"4\\\" /><line x1=\\\"150\\\" y1=\\\"160\\\" x2=\\\"160\\\" y2=\\\"150\\\" stroke-width=\\\"4\\\" /></symbol>";

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                string memory rotation = _uintToString(90 * (colors[index].decimal % 4));
                result = string(abi.encodePacked(result, "<use href=\\\"%23tri\\\" stroke=\\\"%23", colors[index].color, "\\\" transform=\\\"rotate(", rotation, " ", _gridCentrePos[i], " ", _gridCentrePos[j], ")\\\" x=\\\"", _gridPos[i],"\\\" y=\\\"", _gridPos[j],"\\\"/>"));
            }
        }

        return result;
    }

    function _shutters(ColorMetaData[] memory colors) internal view returns(string memory) {
        string memory result = "<symbol id=\\\"dot\\\" viewPort=\\\"0 0 160 160\\\"><line y1=\\\"0\\\" x1=\\\"16\\\" y2=\\\"160\\\" x2=\\\"16\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.96;\\\"/><line y1=\\\"0\\\" x1=\\\"32\\\" y2=\\\"160\\\" x2=\\\"32\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.87;\\\"/><line y1=\\\"0\\\" x1=\\\"48\\\" y2=\\\"160\\\" x2=\\\"48\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.79;\\\"/><line y1=\\\"0\\\" x1=\\\"64\\\" y2=\\\"160\\\" x2=\\\"64\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.7;\\\"/><line y1=\\\"0\\\" x1=\\\"80\\\" y2=\\\"160\\\" x2=\\\"80\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.61;\\\"/><line y1=\\\"0\\\" x1=\\\"96\\\" y2=\\\"160\\\" x2=\\\"96\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.52;\\\"/><line y1=\\\"0\\\" x1=\\\"112\\\" y2=\\\"160\\\" x2=\\\"112\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.43;\\\"/><line y1=\\\"0\\\" x1=\\\"128\\\" y2=\\\"160\\\" x2=\\\"128\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.34;\\\"/><line y1=\\\"0\\\" x1=\\\"144\\\" y2=\\\"160\\\" x2=\\\"144\\\" stroke-width=\\\"4\\\" style=\\\"opacity: 0.25;\\\"/></symbol>";

        for (uint8 i = 0; i < _gridCount; i++) {
            for (uint8 j = 0; j < _gridCount; j++) {
                uint8 index = i * _gridCount + j;
                uint decimalColor = colors[index].decimal;
                string memory rand = _uintToString(360 * decimalColor / 16777215);
                result = string(abi.encodePacked(result, "<use href=\\\"%23dot\\\" stroke=\\\"%23", colors[index].color, "\\\" transform=\\\"rotate(", rand, " ", _gridCentrePos[i], " ", _gridCentrePos[j], ")\\\" x=\\\"", _gridPos[i],"\\\" y=\\\"", _gridPos[j],"\\\"/>"));
            }
        }

        return result;
    }
}
