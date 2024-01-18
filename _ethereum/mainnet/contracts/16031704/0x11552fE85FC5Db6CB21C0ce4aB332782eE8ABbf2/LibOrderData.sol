// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./LibPart.sol";
import "./LibOrder.sol";

library LibOrderData {
    bytes4 public constant V1 = bytes4(keccak256("V1"));
    bytes4 public constant V2 = bytes4(keccak256("V2"));

    struct Data {
        LibPart.Part[] originFees;
        address recipient;
        bool isMakeFill;
    }
}
