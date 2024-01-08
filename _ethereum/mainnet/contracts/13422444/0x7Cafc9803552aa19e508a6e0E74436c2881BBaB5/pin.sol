// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WithPin {
    struct Pin {
        uint32 lat;
        uint32 lng;
        uint8 resolution;
        string message;
        string image;
        string video;
        uint256 valueAmount;
    }
}