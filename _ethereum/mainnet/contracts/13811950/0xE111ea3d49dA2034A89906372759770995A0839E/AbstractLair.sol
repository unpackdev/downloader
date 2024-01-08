// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ILair.sol";

/// @notice holds info about a staked Vampire
struct VampireStake {
    /// @notice address of the token owner
    address owner;
    /// @notice id of the token. uint16 cuz max token id = 50k
    uint16 tokenId;
    /// @notice the bloodbagPerPredatorScore of the Lair when the vampire joined
    uint80 bloodbagPerPredatorScoreWhenStaked;
}

abstract contract AbstractLair is ILair {
    mapping(uint8 => VampireStake[]) public scoreStakingMap;
    mapping(uint16 => uint256) public stakeIndices;
}
