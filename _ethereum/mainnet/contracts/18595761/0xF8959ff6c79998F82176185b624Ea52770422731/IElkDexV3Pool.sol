// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./IElkDexV3PoolImmutables.sol";
import "./IElkDexV3PoolState.sol";
import "./IElkDexV3PoolDerivedState.sol";
import "./IElkDexV3PoolActions.sol";
import "./IElkDexV3PoolOwnerActions.sol";
import "./IElkDexV3PoolEvents.sol";

/// @title The interface for a ElkDex V3 Pool
/// @notice A ElkDex pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IElkDexV3Pool is
    IElkDexV3PoolImmutables,
    IElkDexV3PoolState,
    IElkDexV3PoolDerivedState,
    IElkDexV3PoolActions,
    IElkDexV3PoolOwnerActions,
    IElkDexV3PoolEvents
{

}
