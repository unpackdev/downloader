// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library DynaModel {
    struct DynaParams {
        uint24 randomSeed;
        uint8 zoom; // 0 - 100
        uint8 tintRed; // 0 - 255
        uint8 tintGreen; // 0 - 255
        uint8 tintBlue; // 0 - 255
        uint8 tintAlpha; // 0 - 255
        uint8 rotationMin; // 0 - 180
        uint8 rotationMax; // 0 - 180
        uint8 stripeWidthMin; // 25 - 250
        uint8 stripeWidthMax; // 25 - 250
        uint8 speedMin; // 25 - 250 
        uint8 speedMax; // 25 - 250
    }
}