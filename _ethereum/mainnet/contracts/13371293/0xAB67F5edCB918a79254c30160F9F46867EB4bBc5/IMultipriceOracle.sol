// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultipriceOracle {
    function uniV3TwapAssetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) external view returns (uint256 amountOut);
}
