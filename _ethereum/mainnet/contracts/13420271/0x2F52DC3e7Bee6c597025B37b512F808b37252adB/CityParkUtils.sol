// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Strings.sol";
import "./SafeMath.sol";

library CityParkUtils {

    using SafeMath for uint16;
    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint16;

    struct Art {
        uint8 numTrees;
        bool hasUFO;
        bool hasSun;
        bool hasFence;
        bool hasBricks;
        bool overrideWhite;
        uint48 randomTimestamp;
        uint128 randomDifficulty;
        uint256 randomSeed;
    }

    struct ColorXY {
        uint16 x;
        uint16 y;
        string color;
    }

    string public constant _imageFooter = "</svg>";
    string public constant _borderRect = "<rect width='100%' height='166%' y='-33%' rx='20' style='fill:none;stroke:black;stroke-width:20'></rect>";

    function getColor(uint seed, Art memory artData) public pure returns(string memory) {
        return ['%23a85dee', '%2323cd73', '%23ef2839', '%230bd2fa', '%23fdd131'][seededRandom(0,5,seed,artData)];
    }

    function getBWColor(uint seed, Art memory artData) public pure returns(string memory) {
        return ['white', '%23e8e8e8', '%23e0e0e0', '%23aeaeae', '%236e6e6e'][seededRandom(0,5,seed,artData)];
    }

    function _generateHeader(uint seed, Art memory artData) public pure returns (string memory) {
        string memory header = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='300' height='500' viewBox='0 0 1000 1000' style='background-color:";
        return string(abi.encodePacked(
            header,
            getColor(seed, artData),
            "'><!--You are loved.-->"
        ));
    }

    function _boolToString(bool value) public pure returns (string memory) {
        if (value) {
            return "True";
        } else {
            return "False";
        }
    }

    function seededRandom(uint low, uint high, uint seed, Art memory artData) public pure returns (uint16) {
        return uint16(uint(uint256(keccak256(abi.encodePacked(seed, uint256(keccak256(abi.encodePacked(artData.randomDifficulty, artData.randomTimestamp, artData.randomSeed)))))))%high + low);
    }

    function _wrapTrait(string memory trait, string memory value) public pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }
}
