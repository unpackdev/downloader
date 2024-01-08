// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./IMintyswapV3PoolImmutables.sol";
import "./IMintyswapV3PoolState.sol";
import "./IMintyswapV3PoolDerivedState.sol";
import "./IMintyswapV3PoolActions.sol";
import "./IMintyswapV3PoolOwnerActions.sol";
import "./IMintyswapV3PoolEvents.sol";

/// @title The interface for a Mintyswap V3 Pool
/// @notice A Mintyswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IMintyswapV3Pool is
    IMintyswapV3PoolImmutables,
    IMintyswapV3PoolState,
    IMintyswapV3PoolDerivedState,
    IMintyswapV3PoolActions,
    IMintyswapV3PoolOwnerActions,
    IMintyswapV3PoolEvents
{

}
