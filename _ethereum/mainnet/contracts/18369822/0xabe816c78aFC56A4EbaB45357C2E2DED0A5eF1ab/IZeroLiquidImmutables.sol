// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

/// @title  IZeroLiquidImmutables
/// @author ZeroLiquid
interface IZeroLiquidImmutables {
    /// @notice Returns the version of the zeroliquid.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Returns the address of the debt token used by the system.
    ///
    /// @return The address of the debt token.
    function debtToken() external view returns (address);
}
