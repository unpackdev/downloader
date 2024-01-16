pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import "./StakeHouseUniverse.sol";

contract savETHRegistry {
    function init(StakeHouseUniverse, address, address) external {}
    function createIndex(address) external returns (uint256) {}
    function mintSaveETHBatchAndDETHReserves(address, bytes calldata, uint256) external {}
}