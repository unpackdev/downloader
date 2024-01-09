// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the vault owner
interface IVaultOwnerActions {

    /// @notice Set new operator address
    /// @param _operator Operator address
    function changeManager(address _operator) external;

    /// @notice Update address in the whitelist
    /// @param _address Address add to whitelist
    /// @param status Add or Remove from whitelist
    function updateWhiteList(address _address, bool status) external;

    /// @notice Collect the protocol fee to a address
    /// @param to The address where the fee collected to
    function withdrawPerformanceFee(address to) external;

}
