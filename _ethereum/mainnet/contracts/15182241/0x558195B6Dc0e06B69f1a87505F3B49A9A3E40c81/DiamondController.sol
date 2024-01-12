// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DiamondReadableController.sol";
import "./DiamondWritableController.sol";

abstract contract DiamondController is
    DiamondReadableController,
    DiamondWritableController
{}
