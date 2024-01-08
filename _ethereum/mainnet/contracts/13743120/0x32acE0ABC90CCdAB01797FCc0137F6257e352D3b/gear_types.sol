// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface GearTypes {
  struct Gear {
    uint8 background;
    uint8 armament;
    uint8 class;
    uint8 rarity;
    uint8 meansOfAcquisition;
    uint8 faction;
    uint8 powerLevel;
  }
}