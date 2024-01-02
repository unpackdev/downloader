// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC1155PriceOracle.sol";
import "./IERC1155UniswapV3Wrapper.sol";
import "./IPoolAddressesProvider.sol";
import "./IUniswapV3Factory.sol";
import "./IYLDROracle.sol";
import "./INonfungiblePositionManager.sol";
import "./UniswapV3Position.sol";
import "./Math.sol";
import "./IERC20Metadata.sol";
import "./LiquidityAmounts.sol";
import "./TickMath.sol";

contract ERC1155UniswapV3Oracle is IERC1155PriceOracle {
    using UniswapV3Position for UniswapV3Position.UniswapV3PositionData;

    IPoolAddressesProvider public immutable addressesProvider;
    IERC1155UniswapV3Wrapper public immutable wrapper;
    INonfungiblePositionManager public immutable positionManager;
    IUniswapV3Factory public immutable factory;

    constructor(IPoolAddressesProvider _addressesProvider, IERC1155UniswapV3Wrapper _wrapper) {
        addressesProvider = _addressesProvider;
        wrapper = _wrapper;
        positionManager = _wrapper.positionManager();
        factory = _wrapper.factory();
    }

    function _calculateSqrtPriceX96(uint256 token0Rate, uint256 token1Rate, uint8 token0Decimals, uint8 token1Decimals)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        // price = (10 ** token1Decimals) * token0Rate / ((10 ** token0Decimals) * token1Rate)
        // sqrtPriceX96 = sqrt(price * 2^192)

        // overflows only if token0 is 2**160 times more expensive than token1 (considered non-likely)
        uint256 factor1 = Math.mulDiv(token0Rate, 2 ** 96, token1Rate);

        // Cannot overflow if token1Decimals <= 18 and token0Decimals <= 18
        uint256 factor2 = Math.mulDiv(10 ** token1Decimals, 2 ** 96, 10 ** token0Decimals);

        uint128 factor1Sqrt = uint128(Math.sqrt(factor1));
        uint128 factor2Sqrt = uint128(Math.sqrt(factor2));

        sqrtPriceX96 = factor1Sqrt * factor2Sqrt;
    }

    function getAssetPrice(uint256 tokenId) external view returns (uint256 value) {
        UniswapV3Position.UniswapV3PositionData memory position =
            UniswapV3Position.get(positionManager, factory, tokenId);
        (uint256 fees0, uint256 fees1) = position.getPendingFees();

        IYLDROracle oracle = IYLDROracle(addressesProvider.getPriceOracle());

        uint256 token0Price = oracle.getAssetPrice(position.token0);
        uint256 token1Price = oracle.getAssetPrice(position.token1);

        uint8 token0Decimals = IERC20Metadata(position.token0).decimals();
        uint8 token1Decimals = IERC20Metadata(position.token1).decimals();

        uint160 sqrtPriceX96 = _calculateSqrtPriceX96(token0Price, token1Price, token0Decimals, token1Decimals);

        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(position.tickLower),
            TickMath.getSqrtRatioAtTick(position.tickUpper),
            position.liquidity
        );

        amount0 += fees0;
        amount1 += fees1;

        value = amount0 * token0Price / (10 ** token0Decimals) + amount1 * token1Price / (10 ** token1Decimals);
    }
}
