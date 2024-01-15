// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IWahICO {
    function firstRangeTokenPrice() external view returns (uint256);

    function secondRangeTokenPrice() external view returns (uint256);

    function firstRangeLimit() external view returns (uint128);

    function secondRangeLimit() external view returns (uint128);

    function thirdRangeTokenPrice() external view returns (uint256);

    function tokenDecimals() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function buyToken(uint8, uint256) external payable;

     function calculateTokens(uint8 _type, uint256 _amount)
        external
        returns (uint256, uint256);
}
