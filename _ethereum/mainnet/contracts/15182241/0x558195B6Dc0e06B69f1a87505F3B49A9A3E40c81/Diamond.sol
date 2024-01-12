// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDiamond.sol";
import "./DiamondController.sol";
import "./DiamondReadable.sol";
import "./DiamondWritable.sol";

/**
 * @title Diamond read and write operations implementation
 */
contract Diamond is IDiamond, DiamondReadable, DiamondWritable, DiamondController {}
