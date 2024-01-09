// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IQuoter.sol";
import "./PoolAddress.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV3Factory.sol";
import "./TickMath.sol";
import "./LiquidityAmounts.sol";

interface IUniswapUtils {

    function calculateLimitTicks(
        IUniswapV3Pool _pool,
        uint160 _sqrtPriceX96,
        uint256 _amount0,
        uint256 _amount1
    ) external
    returns (
        int24 _lowerTick,
        int24 _upperTick,
        uint128 _liquidity,
        uint128 _orderType
    );

    function _amountsForLiquidity(
        IUniswapV3Pool pool,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external view returns (uint256, uint256);


    function quoteKROM(IUniswapV3Factory factory, address WETH, address KROM, uint256 _weiAmount)
    external returns (uint256 quote);
}