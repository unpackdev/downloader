// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IChainLinkFeedsRegistry {
    struct Registry {
        address index;
        uint256 decimals;
    }

    struct InputInitParam {
        address asset;
        bool isUSD;
        address registry;
        uint256 decimals;
    }

    function getUSDPrice(address asset) external view returns (uint256);

    function getETHPrice(address asset) external view returns (uint256);

    function addUSDFeed(
        address asset,
        address index,
        uint256 decimals
    ) external;

    function addETHFeed(
        address asset,
        address index,
        uint256 decimals
    ) external;

    function removeUSDFeed(address asset) external;

    function removeETHFeed(address asset) external;
}
