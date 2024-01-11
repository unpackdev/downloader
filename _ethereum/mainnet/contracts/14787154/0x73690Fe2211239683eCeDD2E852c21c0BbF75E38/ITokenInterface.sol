// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenInterface {
    function underlying() external view returns (address);

    function supplyRatePerBlock() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);
}
