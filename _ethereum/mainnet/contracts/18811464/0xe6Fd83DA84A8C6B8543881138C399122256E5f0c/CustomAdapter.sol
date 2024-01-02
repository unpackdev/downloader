//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./UniswapV2.sol";
import "./Curve.sol";
import "./UniswapV3.sol";
import "./IAdapter.sol";
import "./GenericErrors.sol";

/**
 * @dev This contract will route call to:
 * 1 - Uniswap V2
 * 2 - Curve
 * 3 - PancakeSwap V3
 */
contract CustomAdapter is IAdapter, UniswapV2, Curve, UniswapV3 {
    /* solhint-disable code-complexity */
    function swap(
        address fromToken,
        address,
        uint256 fromAmount,
        Route calldata route
    ) external override payable {
        if (route.index == 1) {
            swapOnUniswapV2(
                address(fromToken),
                fromAmount,
                route.targetExchange,
                route.payload
            );
        } 
        else if (route.index == 2) {
            //swap on curve
            swapOnCurve(
                fromToken,
                fromAmount,
                route.targetExchange,
                route.payload
            );
        }
        else if (route.index == 3) {
            //swap on uniswapv3
            swapOnUniswapV3(
                fromToken,
                fromAmount,
                route.targetExchange,
                route.payload
            );
        }
        else {
            revert InvalidIndex();
        }
    }

    function quote(
        address fromToken,
        address,
        uint256 fromAmount,
        Route calldata route
    ) external override returns(uint256) {
        if (route.index == 1) {
            return quoteOnUniswapV2(
                address(fromToken),
                fromAmount,
                route.targetExchange,
                route.payload
            );
        } 
        else if (route.index == 2) {
            //quote on curve
            return quoteOnCurve(
                fromToken,
                fromAmount,
                route.targetExchange,
                route.payload
            );
        }
        else if (route.index == 3) {
            //quote on uniswapv3
            return quoteOnUniswapV3(
                fromToken,
                fromAmount,
                route.targetExchange,
                route.payload
            );
        }
        else {
            revert InvalidIndex();
        }
    }
}