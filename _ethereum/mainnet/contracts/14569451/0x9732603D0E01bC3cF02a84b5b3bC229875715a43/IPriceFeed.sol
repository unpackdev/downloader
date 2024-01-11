// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IPriceFeed {
    function getUniswapRouter() external view returns (address);

    function chainlinkAggregators(address _token)
        external
        view
        returns (address);

    function internalPriceFeed(address _token) external view returns (uint256);

    function howManyTokensAinB(
        address tokenA,
        address tokenB,
        address via,
        uint256 amount,
        bool viewOnly
    ) external view returns (uint256);
}
