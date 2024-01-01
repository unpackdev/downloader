// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IAdapter.sol";
import "./DystopiaUniswapV2Fork.sol";
import "./SwaapV2.sol";
import "./Maverick.sol";
import "./TraderJoeV21.sol";
import "./PolygonMigrator.sol";

/**
 * @dev This contract will route call to:
 * 1 - DystopiaUniswapV2Fork
 * 2 - Maverick
 * 3 - SwaapV2
 * 4 - PolygonMigrator
 * 5 - TraderJoeV21
 * The above are the indexes
 */
contract Adapter04 is IAdapter, DystopiaUniswapV2Fork, Maverick, SwaapV2, PolygonMigrator, TraderJoeV21 {
    using SafeMath for uint256;

    /* solhint-disable no-empty-blocks */
    constructor(
        address weth,
        address matic,
        address pol
    ) public WethProvider(weth) PolygonMigrator(matic, pol) {}

    /* solhint-disable no-empty-blocks */

    function initialize(bytes calldata) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256,
        Utils.Route[] calldata route
    ) external payable override {
        for (uint256 i = 0; i < route.length; i++) {
            if (route[i].index == 1) {
                swapOnDystopiaUniswapV2Fork(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].payload
                );
            } else if (route[i].index == 2) {
                swapOnMaverick(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 3) {
                swapOnSwaapV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 4) {
                swapOnPolygonMigrator(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange
                );
            } else if (route[i].index == 5) {
                swapOnTraderJoeV21(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else {
                revert("Index not supported");
            }
        }
    }
}
