// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

// Interface to use 3rd party Uniswap V3 oracle utility contract deployed at https://etherscan.io/address/0x0f1f5a87f99f0918e6c81f16e59f3518698221ff#code

/// @title UniswapV3 oracle with ability to query across an intermediate liquidity pool
interface IUniswapV3Oracle {
    function assetToEth(
        address _tokenIn,
        uint256 _amountIn,
        uint32 _twapPeriod
    ) external view returns (uint256 ethAmountOut);

    function ethToAsset(
        uint256 _ethAmountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) external view returns (uint256 amountOut);

    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) external view returns (uint256 amountOut);

    function assetToAssetThruRoute(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod,
        address _routeThruToken,
        uint24[2] memory _poolFees
    ) external view returns (uint256 amountOut);
}
