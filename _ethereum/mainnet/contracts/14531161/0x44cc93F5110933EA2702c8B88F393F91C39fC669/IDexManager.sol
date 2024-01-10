// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for the DEX manager
/// @author Cosmin Grigore (@gcosmintech)
interface IDexManager {
    /// @notice Event emitted when a new AMM wrapper has been registered
    event AMMRegistered(
        address indexed owner,
        address indexed ammWrapper,
        uint256 id
    );
    /// @notice Event emitted when a registered AMM is paused
    event AMMPaused(address indexed owner);
    /// @notice Event emitted when a registered AMM is unpaused
    event AMMUnpaused(address indexed owner);
    /// @notice Event emitted when a swap has been performed
    event SwapPerformed(
        address sender,
        address indexed tokenA,
        address indexed tokenB,
        uint256 ammId,
        uint256 amountIn,
        uint256 amountOutObtained
    );
    event AddLiquidityPerformed(
        address indexed tokenA,
        address indexed tokenB,
        uint256 ammId,
        uint256 amountAIn,
        uint256 amountBIn,
        uint256 usedA,
        uint256 usedB,
        uint256 liquidityObtained
    );
    event RemovedLiquidityPerformed(
        address sender,
        uint256 lpAmount,
        uint256 obtainedA,
        uint256 obtainedB
    );

    /// @notice Amount data needed for an add liquidity operation
    struct AddLiquidityParams {
        uint256 _amountADesired;
        uint256 _amountBDesired;
        uint256 _amountAMin;
        uint256 _amountBMin;
    }
    /// @notice Amount data needed for a remove liquidity operation
    struct RemoveLiquidityData {
        uint256 _amountAMin;
        uint256 _amountBMin;
        uint256 _lpAmount;
    }

    /// @notice Internal data used only in the add liquidity method
    struct AddLiquidityTemporaryData {
        uint256 lpBalanceBefore;
        uint256 lpBalanceAfter;
        uint256 usedA;
        uint256 usedB;
        uint256 obtainedLP;
    }

    function AMMs(uint256 id) external view returns (address);

    function isAMMPaused(uint256 id) external view returns (bool);

    /// @notice View method to return the next id in line
    function getNextId() external view returns (uint256);

    /// @notice Returns the amount one would obtain from a swap
    /// @param _ammId AMM id
    /// @param _tokenIn Token in address
    /// @param _tokenOut Token to be ontained from swap address
    /// @param _amountIn Amount to be used for swap
    /// @return Token out amount
    function getAmountsOut(
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes calldata data
    ) external payable returns (uint256);

    /// @notice Removes liquidity and sends obtained tokens to sender
    /// @param _ammId AMM id
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param amountParams Amount info (Min amount for token A, Min amount for token B, LP amount to be burnt)
    /// @param _data AMM specific data
    function removeLiquidity(
        uint256 _ammId,
        address _tokenA,
        address _tokenB,
        RemoveLiquidityData calldata amountParams,
        bytes calldata _data
    ) external returns (uint256, uint256);

    /// @notice Adds liquidity and sends obtained LP & leftovers to sender
    /// @param _ammId AMM id
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param amountParams Amount info (Desired amount for token A, Desired amount for token B, Min amount for token A, Min amount for token B)
    /// @param _data AMM specific data
    function addLiquidity(
        uint256 _ammId,
        address _tokenA,
        address _tokenB,
        AddLiquidityParams calldata amountParams,
        bytes calldata _data
    )
        external
        returns (
            uint256, //amountADesired-usedA
            uint256, //amountBDesired-usedB
            uint256 //amountLP
        );

    /// @notice Performs a swap
    /// @param _ammId AMM id
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param _amountIn Token A amount
    /// @param _amountOutMin Min amount for Token B
    /// @param _data AMM specific data
    function swap(
        uint256 _ammId,
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external returns (uint256);
}
