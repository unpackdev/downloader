// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./FeeControllerI.sol";

interface FeeControllerV2I is FeeControllerI {
    function getFeeSplitToCreator(address collection, uint256 fee) external view returns (uint256);
}