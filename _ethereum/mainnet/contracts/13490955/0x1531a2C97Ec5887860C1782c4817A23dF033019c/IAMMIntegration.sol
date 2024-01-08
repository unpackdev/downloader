// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

interface IAMMIntegration {
    /// @dev IMPORTANT: poolID starts at 1 for all amm integrations. A poolID of 0 is used to designate a non amm integration.
    /// For UniswapV2 and Sushiswap, retrieve the pool address by calling the Router.
    struct Pool {
        address tokenA;
        address tokenB;
        uint256 positionID; // Used for Uniswap V3
    }

    /// @param token The address of the deposited token
    /// @param amount The amount of token being deposited
    /// @param poolID  The id of the pool to deposit into
    function deposit(
        address token,
        uint256 amount,
        uint32 poolID
    ) external;

    /// @param token  the token to withdraw
    /// @param amount The amount of token in the pool to withdraw
    /// @param poolID  the pool to withdraw from
    function withdraw(
        address token,
        uint256 amount,
        uint32 poolID
    ) external;

    /// @dev Deploys all the tokens for the specified pools
    function deploy(uint32 poolID) external;

    /// @notice Returns the balance of a specific pool
    /// @param poolID  the id of the pool to return balances from
    function getPoolBalance(uint32 poolID)
        external
        view
        returns (uint256 tokenA, uint256 tokenB);

    /// @notice returns the details of an amm pool
    /// @dev This should throw if poolID is == 0
    /// @param poolID  the ID of the pool to retrieve details for
    function getPool(uint32 poolID) external view returns (Pool memory pool);

    /// @notice Adds an existing position to the integration for use in a strategy
    /// @dev Should be restricted to admin accounts
    /// @param tokenA  The first token in the position
    /// @param tokenB the second token in the position
    /// @param positionID  The position id if required (uniswap v3)
    function createPool(
        address tokenA,
        address tokenB,
        uint256 positionID
    ) external;
}
