// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the Gauge Factory
interface IGaugeFactory {
    /// @notice Mints a gauge token
    /// @param _gauge The address of the gauge to be minted
    function mint(address _gauge) external;
}
