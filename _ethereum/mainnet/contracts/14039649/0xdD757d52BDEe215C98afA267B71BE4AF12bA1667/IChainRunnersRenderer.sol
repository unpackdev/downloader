// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ChainRunnersTypes.sol";

interface IChainRunnersRenderer {
    struct Layer {
        string name;
        bytes hexString;
    }
    
    struct Color {
        string hexString;
        uint alpha;
        uint red;
        uint green;
        uint blue;
    }

    struct SVGCursor {
        uint8 x;
        uint8 y;
        string color1;
        string color2;
        string color3;
        string color4;
    }

    struct Buffer {
        string one;
        string two;
        string three;
        string four;
        string five;
        string six;
        string seven;
        string eight;
    }

    function tokenURI(uint256 tokenId, ChainRunnersTypes.ChainRunner memory runnerData) external view returns (string memory);
    function byteToHexString(bytes1 b) external pure returns (string memory);
    function byteToUint(bytes1 b) external pure returns (uint);
    function uintToHexString6(uint a) external pure returns (string memory);
    function getRaceIndex(uint16 _dna) external view returns (uint8);
    function getLayer(uint8 layerIndex, uint8 itemIndex) external view returns (Layer memory);
    function getLayerIndex(uint16 _dna, uint8 _index, uint16 _raceIndex) external view returns (uint);
    function tokenSVGBuffer(Layer [13] memory tokenLayers, Color [8][13] memory tokenPalettes, uint8 numTokenLayers) external pure returns (string[4] memory);
}
