// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title An interface for PairReserves contract
/// @author Phuture Finance team
/// @notice Provides a method for mapping pairs to their reserves
interface IPairReserves {
    struct Reserves {
        address token0;
        uint112 reserve0;
        uint112 reserve1;
    }

    /// @notice Map pairs array to their reserves
    /// @dev Every pair contract must be already deployed
    /// @param _pairs UniswapV2Pair addresses array
    /// @return reserves Array of reserves and token0s
    function getReserves(address[] calldata _pairs) external view returns (Reserves[] memory reserves);
}
