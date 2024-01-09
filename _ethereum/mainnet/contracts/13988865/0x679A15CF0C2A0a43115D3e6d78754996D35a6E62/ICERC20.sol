// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface ICERC20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}
