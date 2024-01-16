pragma solidity 0.8.13;

// SPDX-License-Identifier: BUSL-1.1

import "./StakeHouseUniverse.sol";

contract SlotSettlementRegistry {
    function init(StakeHouseUniverse, address) external {}
    function stakeHouseShareTokens(address) external view returns (address) {}
    function mintSLOTAndSharesBatch(address, bytes calldata, address) external {}
    function deployStakeHouseShareToken(address) external {}
    function rageQuitKnotOnBehalfOf(
        address,
        bytes calldata,
        address,
        address[] memory,
        address,
        address,
        uint256
    ) external {}
}