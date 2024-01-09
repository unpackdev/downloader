// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./two_bit.sol";
import "./base64.sol";

pragma solidity 0.8.10;
pragma abicoder v2;

contract TwoBitClickRenderer is Ownable {
  using Strings for uint16;
  using Strings for uint8;
  using Strings for uint256;

  string[10] public _traits = [
    "Bit One RGB",
    "Bit Two RGB",
    "Bit One Level",
    "Bit Two Level",
    "Bit One X Coordinate",
    "Bit Two X Coordinate",
    "Degrees",
    "Background Color",
    "Total Level",
    "Rebirth Count"
  ];

  // Levels as keys, RGBs as lists
  mapping(uint8 => mapping(uint8 => string)) public bitRGBs;

  function uploadRGBs(
    uint8 level,
    uint8[] calldata rgbIds,
    string[] calldata rgbs
  ) external onlyOwner {
    require(rgbIds.length == rgbs.length, "Mismatched inputs");
    for (uint i = 0; i < rgbIds.length; i++) {
      bitRGBs[level][rgbIds[i]] = rgbs[i];
    }
  }

  function tokenURI(uint256 tokenId, TwoBit memory tbh) external view returns (string memory) {
    string memory image = Base64.encode(bytes(generateSVGImage(tbh)));

    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name":"',
              'Two Bit',
              ' #',
              tokenId.toString(),
              '", ',
              '"attributes": ',
              compileAttributes(tbh),
              ', "image": "',
              "data:image/svg+xml;base64,",
              image,
              '"}'
            )
          )
        )
      )
    );
  }

  function generateSVGImage(TwoBit memory params) internal view returns (string memory) {
    return string(
      abi.encodePacked(
        generateSVGHeader(),
        generateBackground(params.backgroundRandomLevel, params.background),
        generateRGB(params.degrees, params.bitOneRGB, params.bitOneLevel, 160, params.bitOneXCoordinate),
        generateRGB(params.degrees, params.bitTwoRGB, params.bitTwoLevel, 360, params.bitTwoXCoordinate),
        "</svg>"
      )
    );
  }

  function generateSVGHeader() private pure returns (string memory) {
    return
    string(
      abi.encodePacked(
        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px"',
        ' viewBox="0 0 720 720" style="enable-background:new 0 0 720 720;" xml:space="preserve">'
      )
    );
  }

  function generateBackground(uint8 level, uint8 rgbInt) internal view returns (string memory) {
    bytes memory svgString = abi.encodePacked(
      '<rect x="0" y="0" fill="rgb(',
      bitRGBs[level][rgbInt],
      ')" width="720" height="720"></rect>'
    );

    return string(svgString);
  }

  function generateRGB(uint16 degrees, uint8 rgbInt, uint8 level, uint16 yCoord, uint16 xCoord) internal view returns (string memory) {
    bytes memory svgString = abi.encodePacked(
      '<rect x="', xCoord.toString(), '" y="', yCoord.toString(),'" width="200" height="200" fill="rgb(',
      bitRGBs[level][rgbInt],
      ')" transform="rotate(',
      degrees.toString(),
      ', 360, 360',
      ')">'
      '</rect>'
    );
    return string(svgString);
  }

  function compileAttributes(TwoBit memory tbh) public view returns (string memory) {
    string memory traits;
    traits = string(abi.encodePacked(
      attributeForTypeAndValue(_traits[0], bitRGBs[tbh.bitOneLevel][tbh.bitOneRGB]),',',
      attributeForTypeAndValue(_traits[1], bitRGBs[tbh.bitTwoLevel][tbh.bitTwoRGB]),',',
      attributeForTypeAndValue(_traits[2], (tbh.bitOneLevel + 1).toString()),',',
      attributeForTypeAndValue(_traits[3], (tbh.bitTwoLevel+ 1).toString()),',',
      attributeForTypeAndValue(_traits[4], tbh.bitOneXCoordinate.toString()),',',
      attributeForTypeAndValue(_traits[5], tbh.bitTwoXCoordinate.toString()),',',
      attributeForTypeAndValue(_traits[6], tbh.degrees.toString()),',',
      attributeForTypeAndValue(_traits[7], bitRGBs[tbh.backgroundRandomLevel][tbh.background]),',',
      attributeForTypeAndValue(_traits[8], (tbh.bitOneLevel + tbh.bitTwoLevel + 2).toString()),',',
      attributeForNumberAndValue(_traits[2], tbh.bitOneLevel + 1),',',
      attributeForNumberAndValue(_traits[3], tbh.bitTwoLevel + 1),',',
      attributeForNumberAndValue(_traits[9], tbh.rebirth)
    ));
    return string(abi.encodePacked(
      '[',
      traits,
      ']'
    ));
  }

  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  function attributeForNumberAndValue(string memory traitType, uint8 value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"display_type":"number","trait_type":"',
      traitType,
      '","value": ',
      value.toString(),
      '}'
    ));
  }
}