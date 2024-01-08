// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IArchRouterImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function uniV3Factory() external view returns (address);

    /// @return Returns the address of WETH
    function WETH() external view returns (address);
}
