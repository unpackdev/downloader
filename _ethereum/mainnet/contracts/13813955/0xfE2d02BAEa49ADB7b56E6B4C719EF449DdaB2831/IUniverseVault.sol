// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import "./IVaultOwnerActions.sol";
import "./IVaultOperatorActions.sol";
import "./IVaultEvents.sol";
import "./IERC20Detail.sol";
import "./UToken.sol";

/// @title The interface for a Universe Vault
/// @notice A UniswapV3 optimizer with smart rebalance strategy
interface IUniverseVault is IVaultOwnerActions, IVaultOperatorActions, IVaultEvents {

    /// @notice The Share token of Token0
    /// @return The share token0 contract
    function uToken0() external view returns (UToken);

    /// @notice The Share token of Token1
    /// @return The share token1 contract
    function uToken1() external view returns (UToken);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (IERC20Detail);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (IERC20Detail);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 fee0, uint128 fee1);

    /// @notice The max share of token0 and token1 that are allowed to deposit
    /// Returns maxShare0 The max share of token0
    /// Returns maxShare1 The max share of token1
    /// Returns maxPersonShare0 The max person share of token0
    /// Returns maxPersonShare1 The max person share of token1
    function maxShares() external view returns (uint256 maxShare0, uint256 maxShare1, uint256 maxPersonShare0, uint256 maxPersonShare1);

    /// @notice The Safety Param for deposit
    /// Returns positionTick The deposit in Tick when last reBalance
    /// Returns depositMaxOffsetTick When tick offset bigger the value not allow to deposit
    /// Returns tickBias0 Safety bias for deposit
    /// Returns tickBias1 Safety bias for small deposit
    /// Returns pct0 Safety Pct for deposit
    /// Returns pct1 Safety Pct for deposit
    function safeAddLiq() external view returns (int24 positionTick, int24 depositMaxOffsetTick, int24 tickBias0, int24 tickBias1, uint24 pct0, uint24 pct1);

    /// @notice Returns data about a specific position index
    /// @return principal0 The principal of token0,
    /// Returns principal1 The principal of token1,
    /// Returns poolAddress The uniV3 pool address of the position,
    /// Returns lowerTick The lower tick of the position,
    /// Returns upperTick The upper tick of the position,
    /// Returns tickSpacing The uniV3 pool tickSpacing,
    /// Returns status The status of the position
    function position() external view returns (
        uint128 principal0,
        uint128 principal1,
        address poolAddress,
        int24 lowerTick,
        int24 upperTick,
        int24 tickSpacing,
        bool status
    );

    /// @notice The shares of token0 and token1 that are owed to address
    /// @return share0 The share amount of token0,
    /// Returns share1 The share amount of token1,
    function getUserShares(address user) external view returns (uint256 share0, uint256 share1);

    /// @notice The Token Amount that are owed to address
    /// @return amount0 The amount of token0,
    /// Returns amount1 The amount of token1,
    function getUserBals(address user) external view returns (uint256 amount0, uint256 amount1);

    /// @notice The total Share Amount of token0
    /// @return Share Amount
    function totalShare0() external view returns (uint256);

    /// @notice The total Share Amount of token1
    /// @return Share Amount
    function totalShare1() external view returns (uint256);

    /// @notice Get the vault's total balance of token0 and token1
    /// @return The amount of token0 and token1
    function getTotalAmounts() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /// @notice Get Current Pnl of position in uniswapV3
    /// @return rate PNL
    /// @return param safety Param prevent arbitrage
    function getPNL() external view returns (uint256 rate, uint256 param);

    /// @notice Get the share\amount0\amount1 info based of quantity of deposit amounts
    /// @param amount0Desired The amount of token0 want to deposit
    /// @param amount1Desired The amount of token1 want to deposit
    /// @return The share0\share1 corresponding to the investment amount
    function getShares(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256, uint256);

    /// @notice Get the amount of token0 and token1 corresponding to specific share amount
    /// @param share0 The share amount
    /// @param share1 The share amount
    /// @return The amount of token0 and token1 corresponding to specific share amount
    function getBals(uint256 share0, uint256 share1) external view returns (uint256, uint256);

    /// @notice Deposit token into this contract
    /// @param amount0Desired The amount of token0 want to deposit
    /// @param amount1Desired The amount of token1 want to deposit
    /// @return The share corresponding to the investment amount
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns(uint256, uint256) ;

    /// @notice Deposit token into this contract
    /// @param amount0Desired The amount of token0 want to deposit
    /// @param amount1Desired The amount of token1 want to deposit
    /// @param to who will get The share
    /// @return The share corresponding to the investment amount
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        address to
    ) external returns(uint256, uint256) ;

    /// @notice Withdraw token by user
    /// @param share0 The share amount of token0
    /// @param share1 The share amount of token1
    function withdraw(uint256 share0, uint256 share1) external returns(uint256, uint256);

    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;

    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @param amount0 The amount of token0 due to the pool for the minted liquidity
    /// @param amount1 The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

}
