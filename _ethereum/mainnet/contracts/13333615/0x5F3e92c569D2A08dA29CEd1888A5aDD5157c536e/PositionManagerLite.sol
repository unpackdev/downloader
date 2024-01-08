// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;
pragma abicoder v2;

struct Position {
    uint96 nonce;
    address operator;
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    uint128 tokensOwed0;
    uint128 tokensOwed1;
}

interface PositionManagerLite {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @dev The interface is the same as Uniswap's but with returned values wrapped in a struct.
    /// @param tokenId The ID of the token that represents the position
    /// @return position Position struct with the position information
    function positions(uint256 tokenId) external view returns (Position memory position);

    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);
}