// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ICToken {
    function underlying() external;

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}
