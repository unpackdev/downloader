// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface AaveIncentivesInterface {
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);
}
