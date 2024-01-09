// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the vault operator
interface IPairVaultOperatorActions {

    function initPosition(address, int24, int24) external;

    /// @notice Set the available uniV3 pool address
    /// @param _poolFee The uniV3 pool fee
    function addPool(uint24 _poolFee) external;

    /// @notice Set the core params of the vault
    /// @param _swapPool Set the uniV3 pool address for trading
    /// @param _performanceFee Set new protocol fee
    /// @param _diffTick Set max rebalance tick bias
    /// @param _minSwapToken1 Set swap limit
    function changeConfig(
        address _swapPool,
        uint8 _performanceFee,
        uint24 _diffTick,
        uint256 _minSwapToken1
    ) external;

    /// @notice Prepares the position array to store up a new position
    /// @param poolAddress The uniV3 pool address of the new position
    function addPosition(address poolAddress) external;

    /// @notice Stop mining of specified positions
    /// @param idx The position index array to stop mining
    /// @param r0 The mocked token0 amount using to calculate token1/token0 after trim
    /// @param r1 The mocked token1 amount using to calculate token1/token0 after trim
    function avoidRisk(
        uint256[] calldata idx,
        uint256 r0,
        uint256 r1
    ) external;

    /// @notice Add liquidity to one position after remove some liquidity from one position
    /// @param fromIdx The position to remove liquidity
    /// @param liq The liquidity amount to remove
    /// @param toIdx The position to add liquidity
    /// @param lowerTick The lower tick for the position
    /// @param upperTick The upper tick for the position
    /// @param _tick The desire middle tick in the target position
    function adjustMining(
        uint256 fromIdx,
        uint128 liq,
        uint256 toIdx,
        int24 lowerTick,
        int24 upperTick,
        int24 _tick
    ) external;

    /// @notice Reinvest the main position
    function reInvest() external;

    /// @notice Change a position's uniV3 pool address
    /// @param idx The position index
    /// @param newPoolAddress The the new uniV3 pool address
    /// @param _lowerTick The lower tick for the position
    /// @param _upperTick The upper tick for the position
    /// @param _tick The desire middle tick in the new pool
    function changePool(
        uint256 idx,
        address newPoolAddress,
        int24 _lowerTick,
        int24 _upperTick,
        int24 _tick
    ) external;

    /// @notice Do rebalance of one position
    /// @param idx The position index
    /// @param _lowerTick The lower tick for the position after rebalance
    /// @param _upperTick The upper tick for the position after rebalance
    /// @param _tick The current tick for ready rebalance
    function forceReBalance(
        uint256 idx,
        int24 _lowerTick,
        int24 _upperTick,
        int24 _tick
    ) external;

    /// @notice Do rebalance of one position
    /// @param idx The position index
    /// @param reBalanceThreshold The minimum tick bias to do rebalance
    /// @param band The new price range band param
    /// @param _tick The current tick for ready rebalance
    function reBalance(
        uint256 idx,
        int24 reBalanceThreshold,
        int24 band,
        int24 _tick
    ) external;

}
