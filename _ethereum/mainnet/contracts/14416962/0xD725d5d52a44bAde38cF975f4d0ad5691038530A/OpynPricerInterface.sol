// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface OpynPricerInterface {
    function getPrice(address _asset) external view returns (uint256);

    function getHistoricalPrice(address _asset, uint80 _roundId) external view returns (uint256, uint256);
}
