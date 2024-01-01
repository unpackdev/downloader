// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IRateProvider {
    function getAmountForUSD(address token, uint256 usd) external view returns (uint256);

    function tokens() external view returns (address[] memory);
}