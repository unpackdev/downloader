//	SPDX-License-Identifier: MIT
/// @notice Helper to build svg elements
pragma solidity ^0.8.0;

import "./LogoHelper.sol";

library SvgHeader {
  function getHeader(uint16 width, uint16 height) public pure returns (string memory) {
    string memory svg = '<svg version="2.0" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 ';
    if (width != 0 && height != 0) {
      svg = string(abi.encodePacked(svg, LogoHelper.toString(width), ' ', LogoHelper.toString(height), '">'));
    } else {
      svg = string(abi.encodePacked(svg, '300 300">'));
    }
    return svg;
  }

  function getTransform(uint8 translateXDirection, uint16 translateX, uint8 translateYDirection, uint16 translateY, uint8 scaleDirection, uint8 scaleMagnitude) public pure returns (string memory) {
    string memory translateXStr = translateXDirection == 0 ? string(abi.encodePacked('-', LogoHelper.toString(translateX))) : LogoHelper.toString(translateX);
    string memory translateYStr = translateYDirection == 0 ? string(abi.encodePacked('-', LogoHelper.toString(translateY))) : LogoHelper.toString(translateY);

    string memory scale = '1';
    if (scaleMagnitude != 0) {
      if (scaleDirection == 0) { 
        scale = string(abi.encodePacked('0.', scaleMagnitude < 10 ? LogoHelper.toString(scaleMagnitude): LogoHelper.toString(scaleMagnitude % 10)));
      } else {
        scale = string(abi.encodePacked(LogoHelper.toString((scaleMagnitude / 10) + 1), '.', LogoHelper.toString(scaleMagnitude % 10)));
      }
    }

    return string(abi.encodePacked('translate(', translateXStr, ', ', translateYStr, ') ', 'scale(', scale, ')'));
  }

}