// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IYieldProxy {
    function updateReward(
        address,
        address,
        uint256
    ) external;

    function updateRewardonMint(address, uint256) external;

    function claimReward(address) external;
}
