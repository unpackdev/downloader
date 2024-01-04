// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

interface IInstaPoolResolver {
    struct RouteData {
        uint256 dydx;
        uint256 maker;
        uint256 compound;
        uint256 aave;
    }

    function getTokenLimit(address token)
        external
        view
        returns (RouteData memory);
}
