// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "./IUniswapV3Pool.sol";
import "./INonfungiblePositionManager.sol";

function _collect(
    INonfungiblePositionManager nftPositionManager_,
    uint256 tokenId_,
    uint128 liquidity_,
    address recipient_
) returns (uint256 amount0, uint256 amount1) {
    nftPositionManager_.decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId_,
            liquidity: liquidity_,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp // solhint-disable-line not-rely-on-time
        })
    );
    (amount0, amount1) = nftPositionManager_.collect(
        INonfungiblePositionManager.CollectParams({
            tokenId: tokenId_,
            recipient: recipient_,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        })
    );
}

function _pool(
    address factory_,
    address tokenIn_,
    address tokenOut_,
    uint24 fee_
) pure returns (IUniswapV3Pool) {
    return
        IUniswapV3Pool(
            PoolAddress.computeAddress(
                factory_,
                PoolAddress.PoolKey({
                    token0: tokenIn_ < tokenOut_ ? tokenIn_ : tokenOut_,
                    token1: tokenIn_ < tokenOut_ ? tokenOut_ : tokenIn_,
                    fee: fee_
                })
            )
        );
}
