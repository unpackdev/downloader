// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityAmounts.sol";
import "./TickMath.sol";

interface INftPositionManager {
    function positions(uint256 nftId) external view returns (uint96, address, address, address, uint24, int24, int24, uint128, uint256, uint256, uint128, uint128);
    function balanceOf(address user) external view returns (uint256);   
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function factory() external view returns (address);
}

interface Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface ILpToken {
    function slot0() external view returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
}

contract BeefyUniV3BIFIHolders {
    using TickMath for int24;
    INftPositionManager private nftManager;
    address private bifi;
    address private factory;

    constructor (INftPositionManager _nftManager, address _bifi) {
        nftManager = _nftManager;
        bifi = _bifi;
        factory = _nftManager.factory();
    }

    function balanceOf(address _user) external view returns (uint256 _bifiAmount) {
        uint256 nftCount = nftManager.balanceOf(_user);
        for (uint256 i = 0; i < nftCount; i++) {
            uint256 nftId = nftManager.tokenOfOwnerByIndex(_user, i);
            (,,address token0, address token1, uint24 fee, int24 lowerTick, int24 upperTick, uint128 liquidity,,,,) = nftManager.positions(nftId);
            address pool = Factory(factory).getPool(token0, token1, fee);
            _bifiAmount += getPositionTokens(token0, token1, lowerTick, upperTick, liquidity, pool);
        }
    }


    function getPositionTokens(
        address token0, 
        address token1, 
        int24 lowerTick, 
        int24 upperTick, 
        uint128 liquidity, 
        address lpToken
    ) private view returns (uint256) {
        (, int24 currentTick,,,,,) = ILpToken(lpToken).slot0();

        (uint256 amountToken0, uint256 amountToken1) = LiquidityAmounts.getAmountsForLiquidity(
            TickMath.getSqrtRatioAtTick(currentTick),
            TickMath.getSqrtRatioAtTick(lowerTick),
            TickMath.getSqrtRatioAtTick(upperTick),
            liquidity
        );

        bool isBifiToken0 = token0 == bifi;
        bool isBifiToken1 = token1 == bifi;

        return isBifiToken0 ? amountToken0 : isBifiToken1 ? amountToken1 : 0;
    }
}