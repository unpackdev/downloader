// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the vault operator
interface IVaultOperatorActionsV3 {

    function initPosition(address, int24, int24) external;

    /// @notice Set the available uniV3 pool address
    /// @param _poolFee The uniV3 pool fee
    function addPool(uint24 _poolFee) external;

    /// @notice Set the core params of the vault
    /// @param _swapPool Set the uniV3 pool address for trading
    /// @param _performanceFee Set new protocol fee
    /// @param _diffTick Set max rebalance tick bias
    /// @param _safetyParam The safety param
    function changeConfig(
        address _swapPool,
        uint8 _performanceFee,
        uint24 _diffTick,
        uint32 _safetyParam
    ) external;

    /// @notice Set the max share params of the vault
    /// @param _maxShare0 Set max token0 share
    /// @param _maxShare1 Set max token1 share
    /// @param _maxPersonShare0 Set one person max token0 share
    /// @param _maxPersonShare1 Set one person max token1 share
    function changeMaxShare(
        uint256 _maxShare0,
        uint256 _maxShare1,
        uint256 _maxPersonShare0,
        uint256 _maxPersonShare1
    ) external;

    /// @notice Stop mining of specified positions
    /// @param _profitScale The profit distribution param
    function avoidRisk(uint8 _profitScale) external;

//    /// @notice Reinvest the main position
//    /// @param minSwapToken1 The minimum swap amount of token1
//    function reInvest() external;

    /// @notice Change a position's uniV3 pool address
    /// @param newPoolAddress The the new uniV3 pool address
    /// @param _lowerTick The lower tick for the position
    /// @param _upperTick The upper tick for the position
    /// @param _spotTick The desire middle tick in the new pool
    /// @param _profitScale The profit distribution param
    function changePool(
        address newPoolAddress,
        int24 _lowerTick,
        int24 _upperTick,
        int24 _spotTick,
        uint8 _profitScale
    ) external;

    /// @notice Do rebalance of one position
    /// @param _lowerTick The lower tick for the position after rebalance
    /// @param _upperTick The upper tick for the position after rebalance
    /// @param _spotTick The current tick for ready rebalance
    /// @param _profitScale The profit distribution param
    function forceReBalance(
        int24 _lowerTick,
        int24 _upperTick,
        int24 _spotTick,
        uint8 _profitScale
    ) external;

    /// @notice Do rebalance of one position
    /// @param reBalanceThreshold The minimum tick bias to do rebalance
    /// @param band The new price range band param
    /// @param _spotTick The current tick for ready rebalance
    /// @param _profitScale The profit distribution param
    function reBalance(
        int24 reBalanceThreshold,
        int24 band,
        int24 _spotTick,
        uint8 _profitScale
    ) external;

}
