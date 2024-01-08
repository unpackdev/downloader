// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";

import "./IERC20Minimal.sol";
import "./IChainLinkFeedsRegistry.sol";
import "./BinaryExp.sol";

library PriceHelper {
    using SafeMath for uint256;

    function isReachMaxUSDLimit(
        address registry,
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        uint256 maxUSDLimit
    ) internal view returns (bool) {
        // maxUSDLimit 1e8 base
        if (maxUSDLimit == 0) {
            return false;
        } else {
            uint256 balance0 = IChainLinkFeedsRegistry(registry)
                .getUSDPrice(token0)
                .mul(amount0)
                .div(BinaryExp.pow(10, IERC20Minimal(token0).decimals()));
            uint256 balance1 = IChainLinkFeedsRegistry(registry)
                .getUSDPrice(token1)
                .mul(amount1)
                .div(BinaryExp.pow(10, IERC20Minimal(token1).decimals()));
            return balance0.add(balance1) >= maxUSDLimit ? true : false;
        }
    }
}
