// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library RewardType {
    uint public constant REWARD_TYPE_HOLOSPEC = 1;
    uint public constant REWARD_TYPE_BOX = 2;
    uint public constant REWARD_TYPE_PART = 3;
}

interface IWLMint {
    function mint(address to, uint256 quantity) external returns (uint256, uint256);
}