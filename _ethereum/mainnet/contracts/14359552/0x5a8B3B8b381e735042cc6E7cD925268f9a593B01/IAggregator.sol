//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IAggregator {

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

    function decimals() external view returns (uint8);

    function version() external view returns (uint256);

    function getAssetPrice(address _asset) external returns (uint256, uint8);
}