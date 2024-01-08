// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./PoolAddress.sol";

/// @author Ganesh Gautham Elango
/// @title Compound collateral swap contract interface
interface ICTokenSwap {
    /// @dev Collateral swap params
    /// @param token0Amount Amount of token0 to swap from
    /// @param cToken0Amount Amount of cToken0 to transfer
    /// @param token0 Underlying token of cToken0
    /// address(0) if Ether and collateralSwap, weth if Ether and collateralSwapFlash
    /// @param token1 Underlying token of cToken1 (address(0) if Ether)
    /// @param cToken0 cToken to swap from
    /// @param cToken1 cToken to swap to
    /// @param exchange Exchange address to swap on
    /// @param data Calldata to call exchange with
    struct CollateralSwapParams {
        uint256 token0Amount;
        uint256 cToken0Amount;
        address token0;
        address token1;
        address cToken0;
        address cToken1;
        address exchange;
        bytes data;
    }

    /// @notice Emitted on each collateral swap
    /// @param sender msg.sender
    /// @param cToken0 Token to swap from
    /// @param cToken1 Token to swap to
    /// @param amount Amount of token0 swapped
    event CollateralSwap(address sender, address cToken0, address cToken1, uint256 amount);

    /// @notice Performs collateral swap of 2 cTokens
    /// @dev This may put the sender at liquidation risk if they have debt
    /// @param params Collateral swap params
    /// @return Amount of cToken1 minted and received
    function collateralSwap(CollateralSwapParams calldata params) external returns (uint256);

    /// @notice Performs collateral swap of 2 cTokens using a Uniswap V3 flash loan
    /// @dev This reduces the senders liquidation risk if they have debt
    /// @param amount0 Amount of token0 in pool to flash loan (must be 0 if not being flash loaned)
    /// @param amount0 Amount of token1 in pool to flash loan (must be 0 if not being flash loaned)
    /// @param pool Uniswap V3 pool address containing token to be flash loaned
    /// @param poolKey The identifying key of the Uniswap V3 pool
    /// @param params Collateral swap params
    function collateralSwapFlash(
        uint256 amount0,
        uint256 amount1,
        address pool,
        PoolAddress.PoolKey calldata poolKey,
        CollateralSwapParams calldata params
    ) external;

    /// @notice Transfer a tokens balance left on this contract to the owner
    /// @dev Can only be called by owner
    /// @param token Address of token to transfer the balance of
    function transferToken(address token) external;
}
