//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SvgElement.sol";
import "./LogoHelper.sol";
import "./InlineSvgElement.sol";

library SvgPattern {
  function getADef(string memory seed, string memory backgroundId, string memory fillType, string memory fillZeroClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 140, 10);
    // pattern should end in frame
    for (uint i = 0; i < 150; i++) {
      if (300 % (patternSize + i) == 0) {
        patternSize = patternSize + i;
        break;
      } 
    }
    uint squareSize = randomInRange(string(abi.encodePacked(seed, 'b')), LogoHelper.equal(fillType, 'Solid') ? patternSize - (patternSize / 6) : patternSize + (patternSize / 2), patternSize / 6);
    string memory element = SvgElement.getRect(SvgElement.Rect(fillZeroClass, '0', '0', LogoHelper.toString(squareSize), LogoHelper.toString(squareSize), '', '', ''));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }

  function getBDef(string memory seed, string memory backgroundId, string memory fillZeroClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 200, 10);
    for (uint i = 0; i < 150; i++) {
      if (300 % (patternSize + i) == 0) {
        patternSize = patternSize + i;
        break;
      }  
    }
    uint circleRadius = randomInRange(string(abi.encodePacked(seed, 'b')), patternSize - (patternSize / 4), patternSize / 12);
    string memory center = LogoHelper.toString(randomInRange(string(abi.encodePacked(seed, 'c')), patternSize, patternSize / 4));
    string memory element = SvgElement.getCircle(SvgElement.Circle(fillZeroClass, center, center, LogoHelper.toString(circleRadius), ''));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }
  
  function getAX2Def(string memory seed, string memory backgroundId, string memory fillZeroClass, string memory fillType, string memory fillOneClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 200, 2);
    for (uint i = 0; i < 150; i++) {
      if (300 % (patternSize + i) == 0) {
        patternSize = patternSize + i;
        break;
      } 
    }
    uint squareSize1 = randomInRange(string(abi.encodePacked(seed, 'b')), LogoHelper.equal(fillType, 'Solid') ? patternSize : patternSize + (patternSize / 2), patternSize / 6);
    uint squareSize2 = randomInRange(string(abi.encodePacked(seed, 'c')), LogoHelper.equal(fillType, 'Solid') ? patternSize : patternSize + (patternSize / 2), patternSize / 6);

    uint offset = randomInRange(string(abi.encodePacked(seed, 'd')), patternSize - (squareSize2 / 2) , 0);
    string memory opactiy = LogoHelper.decimalInRange(seed, 8, 10);
    string memory element = SvgElement.getRect(SvgElement.Rect(fillZeroClass, '0', '0', LogoHelper.toString(squareSize1), LogoHelper.toString(squareSize1), '', '', ''));
    element = string(abi.encodePacked(element, SvgElement.getRect(SvgElement.Rect(fillOneClass, LogoHelper.toString(offset), LogoHelper.toString(offset), LogoHelper.toString(squareSize2), LogoHelper.toString(squareSize2), opactiy, '', ''))));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }

  function getBX2Def(string memory seed, string memory backgroundId, string memory fillZeroClass, string memory fillOneClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 200, 20);
    for (uint i = 0; i < 150; i++) {
      if (300 % (patternSize + i) == 0) {
        patternSize = patternSize + i;
        break;
      } 
    }
    uint circleRadius = randomInRange(string(abi.encodePacked(seed, 'b')), patternSize - (patternSize / 4), patternSize / 6);

    string memory center = LogoHelper.toString(randomInRange(string(abi.encodePacked(seed, 'c')), patternSize, patternSize / 4));
    string memory element = SvgElement.getCircle(SvgElement.Circle(fillZeroClass, center, center, LogoHelper.toString(circleRadius), ''));

    circleRadius = randomInRange(string(abi.encodePacked(seed, 'e')), patternSize, patternSize / 6);
    center = LogoHelper.toString(randomInRange(string(abi.encodePacked(seed, 'f')), patternSize, patternSize / 4));
    string memory opactiy = LogoHelper.decimalInRange(seed, 8, 10);
    element = string(abi.encodePacked(element, SvgElement.getCircle(SvgElement.Circle(fillOneClass, center, center, LogoHelper.toString(circleRadius), opactiy))));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }

  function getABDef(string memory seed, string memory backgroundId, string memory fillType, string memory fillZeroClass, string memory fillOneClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 200, 20);
    for (uint i = 0; i < 150; i++) {
      if ((patternSize + i) % 300 == 0) {
        patternSize = patternSize + i;
        break;
      } 
    }
    uint squareSize1 = randomInRange(string(abi.encodePacked(seed, 'b')), LogoHelper.equal(fillType, 'Solid') ? patternSize : patternSize + (patternSize / 2), patternSize / 6);
    string memory element = SvgElement.getRect(SvgElement.Rect(fillZeroClass, '0', '0', LogoHelper.toString(squareSize1), LogoHelper.toString(squareSize1), '', '', ''));

    uint circleRadius = randomInRange(string(abi.encodePacked(seed, 'b')), patternSize - (patternSize / 4), patternSize / 6);
    string memory center = LogoHelper.toString(randomInRange(string(abi.encodePacked(seed, 'c')), patternSize, patternSize / 4));
    element = string(abi.encodePacked(element, SvgElement.getCircle(SvgElement.Circle(fillOneClass, center, center, LogoHelper.toString(circleRadius), ''))));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }

  function getGMDef(string memory seed, string memory backgroundId, string memory fillZeroClass, string memory fillOneClass, string memory fillTwoClass, string memory fillThreeClass) public pure returns (string memory) {
    // sky
    uint patternSizeX = randomInRange(string(abi.encodePacked(seed, 'a')), 300, 6);
    uint patternSizeY = randomInRange(string(abi.encodePacked(seed, 'b')), 300, 6);
    uint squareSize2 = randomInRange(seed, patternSizeX / 2, patternSizeX / 6);

    uint offset = randomInRange(seed, patternSizeX - (squareSize2 / 2) , 0);

    string memory element = SvgElement.getRect(SvgElement.Rect(fillZeroClass, '0', '0', LogoHelper.toString(patternSizeX), LogoHelper.toString(patternSizeX), '', '', ''));
    element = string(abi.encodePacked(element, SvgElement.getRect(SvgElement.Rect(fillOneClass, LogoHelper.toString(offset), LogoHelper.toString(offset), LogoHelper.toString(squareSize2), LogoHelper.toString(squareSize2), '0.8', '', ''))));
    SvgElement.Pattern memory pattern = SvgElement.Pattern(string(abi.encodePacked(backgroundId, '-1')), '0', '0', LogoHelper.toString(patternSizeX), LogoHelper.toString(patternSizeY), 'userSpaceOnUse', element);
    string memory defs = SvgElement.getPattern(pattern);

    // ocean
    patternSizeX = 300;
    patternSizeY = randomInRange(string(abi.encodePacked(seed, 'c')), 30, 0);
    squareSize2 = randomInRange(seed, patternSizeX, patternSizeX / 4);
    offset = 230 - (squareSize2 / 2);
    backgroundId = string(abi.encodePacked(backgroundId, '-2'));

    element = SvgElement.getRect(SvgElement.Rect(fillTwoClass, '0', '0', LogoHelper.toString(patternSizeX), LogoHelper.toString(squareSize2), '', '', ''));
    // element = string(abi.encodePacked(element, SvgElement.getRect(SvgElement.Rect(fillThreeClass, LogoHelper.toString(offset), '5', LogoHelper.toString(squareSize2), '10', '0.8', '', ''))));
    element = string(abi.encodePacked(element, SvgElement.getRect(SvgElement.Rect(fillThreeClass, LogoHelper.toString(offset), LogoHelper.toString(patternSizeY), LogoHelper.toString(squareSize2), LogoHelper.toString(patternSizeY), '0.8', '', ''))));
    patternSizeY = randomInRange(string(abi.encodePacked(seed, 'd')), 100, 0);
    pattern = SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSizeX), LogoHelper.toString(patternSizeY), 'userSpaceOnUse', element);
    return string(abi.encodePacked(defs, SvgElement.getPattern(pattern)));
  }

  function randomInRange(string memory input, uint max, uint offset) public pure returns (uint256) {
    max = max - offset;
    return (random(input) % max) + offset;
  }

  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
}