//	SPDX-License-Identifier: MIT
/// @notice Helper to pick the logo types based on seed
pragma solidity ^0.8.0;

import "./Color.sol";

library LogoType {
  function getPalette(uint256 seed) public pure returns (Color.Palette memory) {
    Color.Palette[] memory palettes = Color.getPalettes();
    return palettes[seed % palettes.length];
  }

  function getBackgroundType(uint256 seed) public pure returns (string memory) {
    string[7] memory backgroundTypes = ['Box', 'Pattern A', 'Pattern B', 'Pattern AX2', 'Pattern BX2', 'Pattern AB', 'GM'];
    uint256 index = random(seed) % 100;
    uint8[7] memory distribution = [8, 26, 39, 52, 65, 78, 100];
    for (uint8 i = 0; i < backgroundTypes.length; i++) {
      if (index < distribution[i]) {
        return backgroundTypes[i];
      }
    }
    return backgroundTypes[6];
  }

  function getEmoticonType(uint256 seed) public pure returns (string memory) {
    string[3] memory emoticonTypes = ['The Flippening', 'Probably Nothing', 'Fren'];
    return emoticonTypes[seed % emoticonTypes.length];
  }

  function getTextType(uint256 seed) public pure returns (string memory) {
    string[5] memory textTypes = ['Plain', 'Rug Pull', 'Mailbox', 'Warped Mailbox', 'NGMI'];
    uint256 index = random(seed) % 1000;
    uint16[5] memory distribution = [250, 350, 550, 750, 1000];
    for (uint8 i = 0; i < textTypes.length; i++) {
      if (index < distribution[i]) {
        return textTypes[i];
      }
    }
    return textTypes[0];
  }
  function getFillType(uint256 seed) public pure returns (string memory) {
    string[5] memory fillTypes = ['Solid', 'Linear Gradient', 'Radial Gradient', 'Blocked Linear Gradient', 'Blocked Radial Gradient'];
    return fillTypes[seed % fillTypes.length];
  }

  function getFillTypeAlt(uint256 seed) public pure returns (string memory) {
    string[4] memory fillTypes = ['Linear Gradient', 'Radial Gradient', 'Blocked Linear Gradient', 'Blocked Radial Gradient'];
    return fillTypes[seed % fillTypes.length];
  }

  function getFillColor(uint256 seed, string[] memory palette) public pure returns (string memory) {
    return palette[seed % palette.length];
  }

  function getFilterType(uint256 seed) public pure returns (string memory) {
    string[2] memory filterTypes = ['None', 'A'];
    return filterTypes[seed % filterTypes.length];
  }

  function getAnimationType(uint256 seed) public pure returns (bool) {
    bool[2] memory animationTypes = [true, false];
    return animationTypes[seed % animationTypes.length];
  }

  function random(uint256 input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
  
  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
}