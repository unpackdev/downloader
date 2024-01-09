// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC20.sol";
import "./IVaultOwnerActions.sol";
import "./IPairVaultOperatorActions.sol";
import "./IVaultEvents.sol";

/// @title The interface for a Universe Vault
/// @notice A UniswapV3 optimizer with smart rebalance strategy
interface IUniversePairVault is IERC20, IVaultOwnerActions, IPairVaultOperatorActions, IVaultEvents{

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (IERC20);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (IERC20);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 fee0, uint128 fee1);

    /// @notice Returns data about a specific position index
    /// @param index The element of the positions array to fetch
    /// @return principal0 not used,
    /// Returns principal1 not used,
    /// Returns poolAddress The uniV3 pool address of the position,
    /// Returns lowerTick The lower tick of the position,
    /// Returns upperTick The upper tick of the position,
    /// Returns tickSpacing The uniV3 pool tickSpacing,
    /// Returns status The status of the position
    function positionList(uint256 index) external view returns (
        uint128 principal0,
        uint128 principal1,
        address poolAddress,
        int24 lowerTick,
        int24 upperTick,
        int24 tickSpacing,
        bool status
    );

    /// @notice Get the vault's total balance of token0 and token1
    /// @return The amount of token0 and token1
    function getTotalAmounts() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    /// @notice Get the amount0\amount1 info based of quantity of deposit amounts
    /// @param amount0Desired The amount of token0 want to deposit
    /// @param amount1Desired The amount of token1 want to deposit
    /// @return The share\0 corresponding to the investment amount
    function getShares(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256, uint256);

    /// @notice Get the amount of token0 and token1 corresponding to specific share amount
    /// @param share The share amount
    /// @return The amount of token0 and token1 corresponding to specific share amount
    function getBals(uint256 share, uint256) external view returns (uint256, uint256);

    /// @notice The shares of user
    /// @return share The share amount of token0,
    function getUserShares(address user) external view returns (uint256 share, uint256);

    /// @notice Get the share\amount0\amount1 info based of quantity of deposit amounts
    /// @param amount0Desired The amount of token0 want to deposit
    /// @param amount1Desired The amount of token1 want to deposit
    /// @return The share\amount0\amount1 corresponding to the investment amount
    function getBalancedAmount(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256, uint256, uint256);

    /// @notice Get the amount of token0 and token1 corresponding to specific share amount
    /// @param share The share amount
    /// @return The amount of token0 and token1 corresponding to specific share amount
    function calBalance(uint256 share) external view returns (uint256, uint256);

    /// @notice Get the uniV3 pool address of the main position
    /// @return The uniV3 pool contract address
    function defaultPoolAddress() external view returns(address);

    /// @notice Deposit token into this contract
    /// @param amount0Desired The amount of token0 want to deposit
    /// @param amount1Desired The amount of token1 want to deposit
    /// @return The share corresponding to the investment amount
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns(uint256, uint256);

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
    /// @param share The share amount
    /// @return The amount of token0 and token1 withdraw by user
    function withdraw(uint256 share) external returns (uint256, uint256);


    /// @notice Withdraw token by user
    /// @param share0 The share amount
    /// @param share1 not used
    /// @return The amount of token0 and token1 withdraw by user
    function withdraw(uint256 share0, uint256 share1) external returns (uint256, uint256);

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
