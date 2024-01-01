// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPancakeV3PoolImmutables.sol";
import "./IPancakeV3PoolState.sol";
import "./IPancakeV3PoolDerivedState.sol";
import "./IPancakeV3PoolActions.sol";
import "./IPancakeV3PoolOwnerActions.sol";
import "./IPancakeV3PoolEvents.sol";

/// @title The interface for a PancakeSwap V3 Pool
/// @notice A PancakeSwap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IPancakeV3Pool is
    IPancakeV3PoolImmutables,
    IPancakeV3PoolState,
    IPancakeV3PoolDerivedState,
    IPancakeV3PoolActions,
    IPancakeV3PoolOwnerActions,
    IPancakeV3PoolEvents
{
    function lmPool() external view returns (address);
}
