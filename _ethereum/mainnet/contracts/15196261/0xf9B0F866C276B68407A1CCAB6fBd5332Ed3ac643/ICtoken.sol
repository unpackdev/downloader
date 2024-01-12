/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface ICtoken {
    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);
}
