// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v2;

struct TwoBit {
  uint8 backgroundRandomLevel;
  uint8 background;
  uint8 bitOneRGB;
  uint8 bitTwoRGB;
  uint8 bitOneLevel;
  uint8 bitTwoLevel;
  uint16 bitOneXCoordinate;
  uint16 bitTwoXCoordinate;
  uint16 degrees;
  uint8 rebirth;
}