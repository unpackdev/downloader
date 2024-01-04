// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IStaking {
    function externalStake(
        uint256 amount,
        uint256 stakingDays,
        address staker
    ) external;

    function updateTokenPricePerShare(
        address payable bidderAddress,
        address payable originAddress,
        address tokenAddress,
        uint256 amountBought
    ) external payable;

    function addDivToken(address tokenAddress) external;
}
